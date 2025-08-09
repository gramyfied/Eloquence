"""
Point d'entrée principal pour le système multi-agents Studio Situations Pro
Utilise directement MultiAgentManager avec les vrais agents configurés
"""
import asyncio
import logging
import os
import json
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
from dotenv import load_dotenv
from livekit import agents, rtc
from livekit.agents import (
    Agent,
    AgentSession,
    JobContext,
    RunContext,
    function_tool,
    llm,
)
from livekit.plugins import openai, silero
from vosk_stt_interface import VoskSTTFixed as VoskSTT

# Imports du système multi-agents
from multi_agent_config import (
    MultiAgentConfig,
    AgentPersonality,
    InteractionStyle,
    ExerciseTemplates
)
# from multi_agent_manager import MultiAgentManager # Remplacé par l'orchestrateur
from exercise_router import ExerciseRouter, ExerciseType
from agent_communication_enhancer import AgentCommunicationEnhancer, create_communication_enhancer
from agent_interaction_orchestrator import AgentInteractionOrchestrator, create_interaction_orchestrator

# Charger les variables d'environnement
load_dotenv()

# Configuration avec logs détaillés pour debug
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Log des variables d'environnement critiques (sans exposer les secrets)
logger.info("🔍 DIAGNOSTIC MULTI-AGENTS: Variables d'environnement")
logger.info(f"   OPENAI_API_KEY présente: {'Oui' if os.getenv('OPENAI_API_KEY') else 'Non'}")
logger.info(f"   MISTRAL_BASE_URL: {os.getenv('MISTRAL_BASE_URL', 'Non définie')}")

# URLs des services
MISTRAL_API_URL = os.getenv('MISTRAL_BASE_URL', 'http://mistral-conversation:8001/v1/chat/completions')
VOSK_STT_URL = os.getenv('VOSK_STT_URL', 'http://vosk-stt:8002')

class MultiAgentLiveKitService:
    """Service LiveKit intégré avec le gestionnaire multi-agents"""
    
    def __init__(self, multi_agent_config: MultiAgentConfig, user_data: dict = None):
        self.config = multi_agent_config
        self.user_data = user_data or {'user_name': 'Participant', 'user_subject': 'votre présentation'}
        
        # Initialisation des nouveaux composants
        agents_map = {agent.agent_id: agent for agent in multi_agent_config.agents}
        self.enhancer = create_communication_enhancer(agents_map)
        self.orchestrator = create_interaction_orchestrator(agents_map, self.enhancer)
        
        self.session: Optional[AgentSession] = None
        self.room = None
        self.is_running = False
        
        logger.info(f"🎭 MultiAgentLiveKitService initialisé pour: {multi_agent_config.exercise_id}")
        logger.info(f"👤 Utilisateur: {self.user_data['user_name']}, Sujet: {self.user_data['user_subject']}")
        logger.info(f"   Nombre d'agents: {len(multi_agent_config.agents)}")
        for agent in multi_agent_config.agents:
            logger.info(f"   - {agent.name} ({agent.role}) - Style: {agent.interaction_style.value}")
        
    async def initialize_components(self):
        """Initialise les composants LiveKit avec fallbacks robustes"""
        components = {}
        
        # VAD avec fallback
        try:
            vad = silero.VAD.load()
            components['vad'] = vad
            logger.info("✅ VAD Silero chargé")
        except Exception as e:
            logger.error(f"❌ Erreur VAD: {e}")
            raise
            
        # STT avec fallback Vosk → OpenAI
        try:
            stt = self.create_vosk_stt_with_fallback()
            components['stt'] = stt
            logger.info("✅ STT avec fallback créé")
        except Exception as e:
            logger.error(f"❌ Erreur STT: {e}")
            raise
            
        # LLM avec fallback
        try:
            llm_instance = self.create_mistral_llm()
            components['llm'] = llm_instance
            logger.info("✅ LLM OpenAI créé")
        except Exception as e:
            logger.error(f"❌ Erreur LLM: {e}")
            raise
            
        # TTS spécialisé pour multi-agents
        try:
            tts = await self.create_multiagent_tts()
            components['tts'] = tts
            logger.info("✅ TTS multi-agents créé")
        except Exception as e:
            logger.error(f"❌ Erreur TTS: {e}")
            raise
            
        return components
    
    def create_vosk_stt_with_fallback(self):
        """Crée une interface STT avec Vosk en principal et OpenAI en fallback"""
        logger.info("🔄 [STT-MULTI-AGENTS] Initialisation STT avec logique de fallback (Vosk → OpenAI)")
        
        # Tentative 1: Vosk (rapide et économique)
        try:
            vosk_stt = VoskSTT(
                vosk_url=VOSK_STT_URL,
                language="fr",
                sample_rate=16000
            )
            
            # Reset automatique
            def enhanced_clear_user_turn():
                logger.debug("🔄 [STT-MULTI-AGENTS] Clear user turn avec reset Vosk")
                if hasattr(vosk_stt, '_reset_recognizer'):
                    vosk_stt._reset_recognizer()
            
            vosk_stt.clear_user_turn = enhanced_clear_user_turn
            
            logger.info("✅ [STT-MULTI-AGENTS] VOSK STT ACTIVÉ AVEC SUCCÈS")
            return vosk_stt
        except Exception as vosk_error:
            logger.error(f"❌ [STT-MULTI-AGENTS] ÉCHEC STT Vosk: {vosk_error}")
            
        # Fallback: OpenAI Whisper
        try:
            logger.warning("⚠️ [STT-MULTI-AGENTS] Basculement vers OpenAI Whisper (fallback)")
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                raise RuntimeError("OPENAI_API_KEY manquante pour le fallback")
                
            openai_stt = openai.STT(
                model="whisper-1",
                language="fr",
                api_key=api_key,
            )
            logger.warning("⚠️ [STT-MULTI-AGENTS] OPENAI STT ACTIVÉ (FALLBACK)")
            return openai_stt
        except Exception as openai_error:
            logger.error(f"❌ [STT-MULTI-AGENTS] Échec STT OpenAI fallback: {openai_error}")
            raise RuntimeError(f"Impossible de créer STT (Vosk: {vosk_error}, OpenAI: {openai_error})")

    def create_mistral_llm(self):
        """Crée un LLM configuré pour utiliser OpenAI (plus stable)"""
        api_key = os.getenv('OPENAI_API_KEY')
        logger.info(f"🔍 Configuration OpenAI LLM Multi-Agents - Modèle: gpt-4o-mini")
        
        return openai.LLM(
            model="gpt-4o-mini",
            api_key=api_key,
        )

    async def create_multiagent_tts(self):
        """Crée un système TTS dynamique qui peut changer de voix selon l'agent"""
        api_key = os.getenv('OPENAI_API_KEY')
        
        if not api_key:
            logger.warning("⚠️ OPENAI_API_KEY manquante, utilisation Silero TTS")
            return silero.TTS()
        
        # Stocker les configurations de voix pour chaque agent
        self.voice_configs = {}
        for agent in self.config.agents:
            voice = agent.voice_config.get('voice', 'alloy')
            speed = agent.voice_config.get('speed', 1.0)
            self.voice_configs[agent.agent_id] = {
                'voice': voice,
                'speed': speed,
                'name': agent.name
            }
            logger.info(f"🎭 Configuration voix pour {agent.name}: {voice} (vitesse: {speed})")
        
        # Créer un TTS par défaut avec la voix du modérateur
        moderator = None
        for agent in self.config.agents:
            if agent.interaction_style == InteractionStyle.MODERATOR:
                moderator = agent
                break
        
        if not moderator:
            moderator = self.config.agents[0]
            
        default_voice = moderator.voice_config.get('voice', 'alloy')
        
        try:
            tts = openai.TTS(
                voice=default_voice,
                api_key=api_key,
                model="tts-1"
            )
            logger.info(f"✅ TTS OpenAI créé avec voix par défaut: {default_voice}")
            return tts
        except Exception as e:
            logger.warning(f"⚠️ OpenAI TTS échoué: {e}, utilisation Silero")
            return silero.TTS()

    def create_multiagent_agent(self) -> Agent:
        """Crée un agent LiveKit configuré pour le système multi-agents"""
        try:
            # Instructions combinées pour tous les agents
            primary_agent = self.config.agents[0]
            
            # Trouver le modérateur ou utiliser le premier agent
            moderator = None
            for agent in self.config.agents:
                if agent.interaction_style == InteractionStyle.MODERATOR:
                    moderator = agent
                    break
            
            if not moderator:
                moderator = primary_agent
            
            # Instructions système génériques pour le contexte global
            system_instructions = f"""Tu es un assistant IA orchestrant une simulation de conversation multi-agents.

 AGENTS PRÉSENTS DANS LA SIMULATION:
{chr(10).join([f"• {agent.name}: {agent.role} ({agent.interaction_style.value})" for agent in self.config.agents])}

📋 CONTEXTE SIMULATION: {self.config.exercise_id}
- Gestion des tours: {self.config.turn_management}
- Durée maximale: {self.config.max_duration_minutes} minutes
- Règles d'interaction: {self.config.interaction_rules}

La logique de l'application te fournira le rôle spécifique à jouer pour chaque réponse.
"""

            agent = Agent(
                instructions=system_instructions,
                tools=[self.generate_multiagent_response],
            )
            
            logger.info(f"🎯 Agent multi-agents créé: {moderator.name} ({moderator.role})")
            return agent
        except Exception as e:
            logger.error(f"❌ Erreur création agent multi-agents: {e}")
            raise

    @function_tool
    async def generate_multiagent_response(self, user_message: str) -> str:
        """Génère une réponse orchestrée du système multi-agents avec voix appropriée"""
        try:
            logger.info(f"🎶 Orchestration pour: {user_message[:50]}...")
            
            # 1. Utiliser l'Orchestrateur pour déterminer qui doit parler
            orchestration_plan = await self.orchestrator.orchestrate_interaction(
                user_message, self.config.exercise_id
            )
            
            primary_agent_id = orchestration_plan['primary_agent_id']
            agent = self.orchestrator.agents[primary_agent_id]
            
            # 2. Générer la réponse de l'agent principal via LLM
            try:
                with open("services/livekit-agent/PROMPT_SYSTEME_IA_COMPLET.md", "r", encoding="utf-8") as f:
                    base_prompt = f.read()
            except FileNotFoundError:
                logger.error("PROMPT_SYSTEME_IA_COMPLET.md non trouvé! Utilisation d'un prompt par défaut.")
                base_prompt = "Tu es un assistant IA."

            agent_prompt = f"""{base_prompt}

Tu es MAINTENANT l'agent {agent.name} avec le rôle de {agent.role}.
Ton style d'interaction est : {agent.interaction_style.value}.
Tes instructions spécifiques sont :
---
{agent.system_prompt}
---

Le dernier message de l'utilisateur est : "{user_message}".
Formule une réponse pertinente, courte (2-3 phrases) et dans ton style, en respectant tes instructions.
Commence IMPÉRATIVEMENT par "[{agent.name}]: ".
"""
            
            llm_instance = self.session.llm
            chat_stream = await llm_instance.chat.completions.create(
                messages=[
                    {"role": "system", "content": agent_prompt},
                    {"role": "user", "content": user_message}
                ],
                stream=True,
            )
            
            primary_response = ""
            async for chunk in chat_stream:
                content = chunk.choices[0].delta.content
                if content:
                    primary_response += content

            logger.info(f"🗣️ {agent.name} ({agent.role}) répond: {primary_response[:80]}...")

            responses_to_speak = [{'agent': agent, 'text': primary_response, 'delay': 0}]

            # 3. Ajouter les interventions forcées par l'orchestrateur
            for forced in orchestration_plan.get('forced_interactions', []):
                forced_agent = self.orchestrator.agents[forced['agent_id']]
                responses_to_speak.append({
                    'agent': forced_agent,
                    'text': forced['message'],
                    'delay': 1000
                })

            # 4. Faire parler les agents
            if hasattr(self, 'session') and self.session and responses_to_speak:
                await self.speak_multiple_agents(responses_to_speak)
            
            # 5. Ne rien retourner, la parole est gérée par speak_multiple_agents
            return ""

        except Exception as e:
            logger.error(f"❌ Erreur orchestration multi-agents: {e}", exc_info=True)
            return "[Système]: Je rencontre un problème technique. Pouvez-vous reformuler ?"
    
    async def speak_multiple_agents(self, responses_to_speak: list):
        """Fait parler plusieurs agents avec leurs voix distinctes. Le texte doit déjà contenir le nom de l'agent."""
        try:
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                logger.warning("⚠️ Pas de clé OpenAI, utilisation d'une voix unique")
                full_text = " ".join([r['text'] for r in responses_to_speak])
                await self.session.say(text=full_text)
                return
            
            for i, resp_data in enumerate(responses_to_speak):
                agent = resp_data['agent']
                text = resp_data['text']
                delay = resp_data['delay']
                
                if i > 0 and delay > 0:
                    await asyncio.sleep(delay / 1000.0)
                
                voice = agent.voice_config.get('voice', 'alloy')
                speed = agent.voice_config.get('speed', 1.0)
                
                logger.info(f"🔊 {agent.name} parle avec la voix: {voice} (vitesse: {speed})")
                
                try:
                    temp_tts = openai.TTS(voice=voice, api_key=api_key, model="tts-1", speed=speed)
                    
                    # On utilise toujours session.say() pour garantir que chaque agent
                    # parle avec sa propre voix, sans modifier le TTS global de la session.
                    await self.session.say(text=text, tts=temp_tts)
                        
                except Exception as tts_error:
                    logger.warning(f"⚠️ Erreur TTS pour {agent.name}: {tts_error}, fallback voix par défaut")
                    await self.session.say(text=text)
                    
        except Exception as e:
            logger.error(f"❌ Erreur speak_multiple_agents: {e}", exc_info=True)
            full_text = " ".join([r['text'] for r in responses_to_speak])
            await self.session.say(text=full_text)
    
    async def update_tts_voice(self, agent: AgentPersonality):
        """Met à jour dynamiquement la voix TTS pour correspondre à l'agent"""
        try:
            if not hasattr(self, 'voice_configs'):
                return
                
            voice_config = self.voice_configs.get(agent.agent_id)
            if not voice_config:
                return
            
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                return
                
            # Créer un nouveau TTS avec la voix de l'agent
            new_voice = voice_config['voice']
            new_speed = voice_config['speed']
            
            logger.info(f"🔄 Changement voix TTS: {new_voice} pour {agent.name}")
            
            # Note: Dans une vraie implémentation, on devrait pouvoir changer
            # dynamiquement la voix de la session, mais LiveKit ne le supporte
            # pas encore directement. Pour l'instant, on log juste le changement.
            
        except Exception as e:
            logger.warning(f"⚠️ Impossible de changer la voix TTS: {e}")
    
    async def generate_orchestrated_welcome(self) -> str:
        """Génère un message de bienvenue orchestré avec toutes les personnalités"""
        try:
            # Récupérer les données utilisateur
            user_name = self.user_data.get('user_name', 'Participant')
            user_subject = self.user_data.get('user_subject', 'votre présentation')
            
            # Trouver le modérateur pour l'introduction
            moderator = None
            for agent in self.config.agents:
                if agent.interaction_style == InteractionStyle.MODERATOR:
                    moderator = agent
                    break
            
            if not moderator:
                moderator = self.config.agents[0]
            
            # Construire le message de bienvenue personnalisé
            welcome_parts = []
            
            # Introduction personnalisée du modérateur
            welcome_parts.append(f"[{moderator.name}]: Bonjour {user_name} et bienvenue dans Studio Situations Pro !")
            
            # Présentation du contexte selon l'exercice avec mention du sujet
            if "debate" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Nous sommes ici pour débattre de {user_subject}.")
            elif "interview" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Nous allons discuter de votre candidature concernant {user_subject}.")
            elif "boardroom" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Bienvenue dans notre conseil pour présenter {user_subject}.")
            elif "sales" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Nous sommes prêts à entendre votre présentation sur {user_subject}.")
            elif "keynote" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Bienvenue pour votre keynote sur {user_subject}.")
            
            # Présentation des autres participants (rapide)
            other_agents = [a for a in self.config.agents if a.agent_id != moderator.agent_id]
            if other_agents:
                participants = ", ".join([a.name for a in other_agents[:2]])  # Max 2 pour rester court
                welcome_parts.append(f"[{moderator.name}]: Avec nous aujourd'hui : {participants}.")
            
            # Invitation personnalisée à commencer
            welcome_parts.append(f"[{moderator.name}]: {user_name}, quand vous êtes prêt(e), commencez votre présentation sur {user_subject}.")
            
            welcome_message = " ".join(welcome_parts)
            logger.info(f"📢 Message de bienvenue personnalisé: {welcome_message[:100]}...")
            
            return welcome_message
            
        except Exception as e:
            logger.error(f"❌ Erreur génération message bienvenue: {e}")
            return f"[Système]: Bienvenue {self.user_data.get('user_name', 'Participant')} dans Studio Situations Pro."

    async def run_session(self, ctx: JobContext, connect: bool = True):
        """Execute la session multi-agents avec gestion robuste"""
        self.is_running = True
        
        try:
            logger.info(f"🚀 Démarrage session multi-agents: {self.config.exercise_id}")
            
            if connect:
                # Connexion avec retry
                await self.connect_with_retry(ctx)
            
            # Stocker ctx.room pour compatibilité LiveKit 1.2.3
            self.room = ctx.room
            logger.info("✅ Room stockée pour compatibilité LiveKit 1.2.3")
            
            # Initialisation des composants
            components = await self.initialize_components()
            
            # Création de l'agent multi-agents
            agent = self.create_multiagent_agent()
            
            # Création de la session
            self.session = AgentSession(**components)
            
            # Le manager est remplacé par l'orchestrateur, pas d'initialisation spécifique requise ici.
            
            # Démarrage de la session
            await self.session.start(agent=agent, room=ctx.room)
            
            # Message de bienvenue orchestré
            welcome_message = await self.generate_orchestrated_welcome()
            await self.session.say(text=welcome_message)
                
            logger.info(f"✅ Session multi-agents {self.config.exercise_id} démarrée avec succès")
            
            # Maintenir la session active
            await self.maintain_session()
            
        except Exception as e:
            logger.error(f"❌ Erreur session multi-agents: {e}")
            raise
        finally:
            self.is_running = False
            
    async def connect_with_retry(self, ctx: JobContext, max_retries: int = 3):
        """Connexion avec retry automatique"""
        for attempt in range(max_retries):
            try:
                await ctx.connect()
                logger.info(f"✅ Connexion multi-agents réussie (tentative {attempt + 1})")
                return
            except Exception as e:
                logger.warning(f"⚠️ Échec connexion multi-agents tentative {attempt + 1}: {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(2 ** attempt)
                else:
                    raise
                    
    async def maintain_session(self):
        """Maintient la session active avec surveillance"""
        heartbeat_interval = 30  # secondes
        max_silent_duration = 300  # 5 minutes sans activité
        last_activity = datetime.now()
        
        while self.is_running:
            try:
                await asyncio.sleep(heartbeat_interval)
                
                # Vérifier l'état de la connexion
                if hasattr(self, 'room') and self.room:
                    if hasattr(self.room, 'connection_state'):
                        state = self.room.connection_state
                        if state != rtc.ConnectionState.CONN_CONNECTED:
                            logger.warning(f"⚠️ État de connexion multi-agents dégradé: {state}")
                            
                    # Vérifier l'activité récente
                    current_time = datetime.now()
                    if (current_time - last_activity).seconds > max_silent_duration:
                        logger.info("📢 Envoi d'un message de maintien multi-agents")
                        
                        # Utiliser le modérateur pour maintenir l'engagement
                        moderator = None
                        for agent in self.config.agents:
                            if agent.interaction_style == InteractionStyle.MODERATOR:
                                moderator = agent
                                break
                        
                        if moderator and self.session:
                            await self.session.say(
                                text=f"Je suis {moderator.name}, je suis toujours là pour vous accompagner. N'hésitez pas à continuer notre simulation !"
                            )
                        last_activity = current_time
                    
                    logger.debug(f"💓 Heartbeat multi-agents OK - Session active depuis {(current_time - last_activity).seconds}s")
                else:
                    logger.warning("⚠️ Room multi-agents non disponible, arrêt de la surveillance")
                    break
                    
            except Exception as e:
                logger.error(f"❌ Erreur dans la surveillance multi-agents: {e}")
                await asyncio.sleep(5)  # Attendre avant de retry


# ==========================================
# DÉTECTION AUTOMATIQUE DU TYPE D'EXERCICE
# ==========================================

def detect_exercise_from_metadata(metadata: str) -> tuple[Optional[MultiAgentConfig], dict]:
    """Détecte le type d'exercice et les données utilisateur via le Router."""
    logger.info("... ROUTAGE EXERCICE via ExerciseRouter ...")
    logger.info(f"📥 Métadonnées reçues: '{metadata}'")
    
    try:
        import json
        data = json.loads(metadata) if metadata else {}
        exercise_id = data.get('exercise_type', 'studio_debate_tv')
        
        user_data = {
            'user_name': data.get('user_name', 'Participant'),
            'user_subject': data.get('user_subject', 'votre présentation'),
        }
        
        # Utilisation du Router pour obtenir la configuration
        route, _ = ExerciseRouter.route_exercise(exercise_id, user_data)
        
        if route.exercise_type != ExerciseType.MULTI_AGENT:
            logger.warning(f"⚠️ Tentative de lancer un exercice INDIVIDUEL ({exercise_id}) dans le main multi-agents.")
            return None, user_data

        # Mapping des exercices multi-agents vers les templates de configuration
        exercise_mapping = {
            'studio_debate_tv': ExerciseTemplates.studio_debate_tv,
            'studio_job_interview': ExerciseTemplates.studio_job_interview,
            'studio_boardroom': ExerciseTemplates.studio_boardroom,
            'studio_sales_conference': ExerciseTemplates.studio_sales_conference,
            'studio_keynote': ExerciseTemplates.studio_keynote,
        }

        config_function = exercise_mapping.get(route.exercise_id)

        if config_function:
            config = config_function()
            logger.info(f"✅ Configuration multi-agents sélectionnée: {config.exercise_id}")
            return config, user_data
        else:
            logger.warning(f"⚠️ Pas de config pour '{route.exercise_id}', fallback débat TV")
            return ExerciseTemplates.studio_debate_tv(), user_data

    except Exception as e:
        logger.error(f"❌ Erreur détection exercice: {e}", exc_info=True)
        logger.info("🔄 Fallback vers débat TV par défaut")
        return ExerciseTemplates.studio_debate_tv(), {'user_name': 'Participant', 'user_subject': 'votre présentation'}


# ==========================================
# POINT D'ENTRÉE UNIFIÉ (SUPER-ROUTEUR)
# ==========================================
from main import robust_entrypoint as individual_entrypoint

async def unified_entrypoint(ctx: JobContext):
    """
    Point d'entrée unifié qui route les exercices vers le bon système
    (individuel ou multi-agents) en se basant sur les métadonnées.
    """
    logger.info("🚀 DÉMARRAGE POINT D'ENTRÉE UNIFIÉ")
    logger.info("="*70)

    try:
        # 1. Établir la connexion LiveKit une seule fois
        logger.info("🔗 Établissement de la connexion LiveKit...")
        await ctx.connect()
        logger.info("✅ Connexion LiveKit établie avec succès")

        # 2. Extraire les métadonnées
        metadata = await get_metadata(ctx)
        if not metadata:
            logger.error("❌ Impossible de trouver les métadonnées. Arrêt.")
            return

        # 3. Router l'exercice
        import json
        data = json.loads(metadata)
        exercise_id = data.get('exercise_type', 'confidence_boost')
        
        route, user_data = ExerciseRouter.route_exercise(exercise_id, data)
        logger.info(f"📍 ROUTAGE: Exercice '{exercise_id}' dirigé vers le handler '{route.handler_module}'")

        # 4. Lancer le bon handler
        if route.exercise_type == ExerciseType.INDIVIDUAL:
            logger.info("👤 Lancement du système pour exercice INDIVIDUEL...")
            # Le contexte `ctx` est déjà connecté, on peut le passer directement
            await individual_entrypoint(ctx)
        else:
            logger.info("👨‍👩‍👧‍👦 Lancement du système pour exercice MULTI-AGENTS...")
            await multiagent_entrypoint(ctx, route, user_data)

    except Exception as e:
        logger.error(f"❌ ERREUR CRITIQUE dans le point d'entrée unifié: {e}", exc_info=True)
        raise

async def get_metadata(ctx: JobContext) -> Optional[str]:
    """Extrait les métadonnées de la room ou des participants."""
    # Vérification métadonnées room
    if hasattr(ctx, 'room') and ctx.room and hasattr(ctx.room, 'metadata') and ctx.room.metadata:
        logger.info("✅ Métadonnées trouvées depuis: ROOM")
        return ctx.room.metadata

    # Vérification métadonnées participants
    if hasattr(ctx, 'room') and ctx.room:
        await asyncio.sleep(2)  # Attendre que les participants se connectent
        for participant in ctx.room.remote_participants.values():
            if participant.metadata:
                logger.info(f"✅ Métadonnées trouvées depuis: PARTICIPANT_{participant.identity}")
                return participant.metadata
    
    logger.warning("⚠️ Aucune métadonnée trouvée.")
    return None

async def multiagent_entrypoint(ctx: JobContext, route: 'ExerciseRoute', user_data: dict):
    """Point d'entrée pour les exercices multi-agents (appelé par le routeur unifié)."""
    logger.info(f"🎭 DÉMARRAGE SYSTÈME MULTI-AGENTS pour '{route.exercise_id}'")
    
    try:
        # La connexion est déjà établie par le routeur unifié
        config, _ = detect_exercise_from_metadata(json.dumps(user_data))
        if config is None:
             logger.error(f"❌ Configuration non trouvée pour l'exercice multi-agents {route.exercise_id}")
             return

        logger.info("="*60)
        logger.info(f"🎭 CONFIGURATION MULTI-AGENTS SÉLECTIONNÉE:")
        logger.info(f"   ID: {config.exercise_id}")
        # ... (autres logs de config)
        logger.info("="*60)
        
        service = MultiAgentLiveKitService(config, user_data)
        # Le run_session n'a plus besoin de se connecter, juste de démarrer la session
        await service.run_session(ctx, connect=False)
        
    except Exception as e:
        logger.error(f"❌ ERREUR CRITIQUE dans le système multi-agents: {e}", exc_info=True)
        raise


if __name__ == "__main__":
    """Point d'entrée principal du worker LiveKit unifié"""
    logger.info("🎯 DÉMARRAGE WORKER LIVEKIT UNIFIÉ (Individuel + Multi-Agents)")
    
    # Configuration WorkerOptions avec le nouveau point d'entrée unifié
    worker_options = agents.WorkerOptions(
        entrypoint_fnc=unified_entrypoint
    )
    
    logger.info("🎯 WorkerOptions configuré avec le routeur unifié")
    logger.info(f"   - Gère les exercices individuels: ✅")
    logger.info(f"   - Gère les exercices multi-agents: ✅")
    
    # Point d'entrée officiel avec CLI LiveKit
    agents.cli.run_app(worker_options)