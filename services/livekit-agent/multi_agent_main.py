"""
Point d'entrée principal pour le système multi-agents Studio Situations Pro
Utilise directement MultiAgentManager avec les vrais agents configurés
"""
import asyncio
import logging
import os
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
from multi_agent_manager import MultiAgentManager

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
        self.manager = MultiAgentManager(multi_agent_config)
        self.session: Optional[AgentSession] = None
        self.room = None
        self.is_running = False
        self.user_data = user_data or {'user_name': 'Participant', 'user_subject': 'votre présentation'}
        
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
                model="tts-1",
                base_url="https://api.openai.com/v1"
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
            
            # Instructions système intégrées (forcer l'usage de l'outil d'orchestration)
            system_instructions = f"""Tu es {moderator.name}, {moderator.role} dans une simulation multi-agents Studio Situations Pro.

            🎯 AGENTS PRÉSENTS DANS LA SIMULATION:
            {chr(10).join([f"• {agent.name}: {agent.role} ({agent.interaction_style.value})" for agent in self.config.agents])}

            🎯 TON RÔLE EN TANT QUE {moderator.name}:
            {moderator.system_prompt}

            📋 CONTEXTE SIMULATION: {self.config.exercise_id}
            - Gestion des tours: {self.config.turn_management}
            - Durée maximale: {self.config.max_duration_minutes} minutes
            - Règles d'interaction: {self.config.interaction_rules}

            🔧 INSTRUCTIONS SPÉCIALES MULTI-AGENTS:
            - Présente-toi TOUJOURS avec ton vrai nom: {moderator.name}
            - Tu représentes l'agent principal mais coordonnes avec les autres
            - Adapte ton style: {moderator.interaction_style.value}
            - Mentionne les autres participants selon le contexte
            - Utilise un style professionnel adapté à la situation
            - Garde tes réponses courtes et engageantes (2-3 phrases max)
            - Identifie-toi clairement dans chaque message

            🛠️ OUTILS DISPONIBLES:
            - generate_multiagent_response(user_message: str): orchestre la réponse multi-agents (Michel + Sarah + Marcus) et génère les réactions secondaires.

            🚨 RÈGLE CRITIQUE D'ORCHESTRATION:
            - À CHAQUE message utilisateur, APPELLE TOUJOURS l'outil generate_multiagent_response avec le message exact de l'utilisateur.
            - Ne réponds JAMAIS directement sans utiliser cet outil.
            - Utilise la sortie de l'outil comme contenu final, sans la paraphraser.

            🎪 EXEMPLE DE RÉPONSE:
            "Bonjour ! Je suis {moderator.name}, votre {moderator.role}. [Ta réponse professionnelle ici]"

            IMPORTANT: Dans chaque message, commence par ton nom réel pour une identification claire."""

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
            logger.info(f"🎭 Orchestration multi-agents pour: {user_message[:50]}...")
            
            # Utiliser le MultiAgentManager pour orchestrer la réponse
            response_data = await self.manager.handle_user_input(user_message)
            
            # Récupérer l'agent principal qui répond
            primary_agent_id = response_data.get('primary_speaker')
            primary_response = response_data.get('primary_response', '')
            
            # Identifier l'agent et préparer les réponses vocales
            responses_to_speak = []
            
            if primary_agent_id and primary_agent_id in self.manager.agents:
                agent = self.manager.agents[primary_agent_id]
                logger.info(f"🗣️ {agent.name} ({agent.role}) répond")
                
                # Ajouter la réponse principale
                responses_to_speak.append({
                    'agent': agent,
                    'text': primary_response,
                    'delay': 0
                })
                
                # Ajouter les réponses secondaires si présentes
                secondary_responses = response_data.get('secondary_responses', [])
                for sec_resp in secondary_responses:
                    sec_agent_id = sec_resp.get('agent_id')
                    if sec_agent_id in self.manager.agents:
                        sec_agent = self.manager.agents[sec_agent_id]
                        responses_to_speak.append({
                            'agent': sec_agent,
                            'text': sec_resp.get('reaction', ''),
                            'delay': sec_resp.get('delay_ms', 1500)
                        })
            
            # Faire parler chaque agent avec sa propre voix
            if hasattr(self, 'session') and self.session and responses_to_speak:
                await self.speak_multiple_agents_robust(responses_to_speak)
            
            # Retourner un texte formaté pour le log/display
            formatted_text = f"[{responses_to_speak[0]['agent'].name}]: {responses_to_speak[0]['text']}"
            for resp in responses_to_speak[1:]:
                formatted_text += f"\n[{resp['agent'].name}]: {resp['text']}"
            
            return formatted_text
            
        except Exception as e:
            logger.error(f"❌ Erreur orchestration multi-agents: {e}")
            return "[Système]: Je rencontre un problème technique. Pouvez-vous reformuler ?"
    
    async def speak_multiple_agents_robust(self, responses_to_speak: list):
        """Version robuste avec retry et fallbacks multiples"""
        for resp_data in responses_to_speak:
            agent = resp_data['agent']
            text = resp_data['text']
            delay = resp_data['delay']

            # Attendre le délai
            if delay and delay > 0:
                await asyncio.sleep(delay / 1000.0)

            # Nettoyer un éventuel préfixe "Nom: " pour éviter doublons au TTS
            sanitized_text = self._strip_name_prefix(agent, text)

            # Retry avec fallbacks progressifs
            success = False
            for attempt in range(3):
                try:
                    if attempt == 0:
                        # Tentative 1: TTS avec voix spécifique
                        voice_dbg = agent.voice_config.get('voice', 'alloy')
                        logger.info(f"🔊 {agent.name} parle avec voix {voice_dbg} (tentative {attempt+1})")
                        await self._speak_with_agent_voice_safe(agent, sanitized_text)
                    elif attempt == 1:
                        # Tentative 2: TTS par défaut avec nom
                        await self.session.say(text=f"{agent.name}: {sanitized_text}")
                    else:
                        # Tentative 3: Fallback minimal
                        await self.session.say(text=sanitized_text)

                    success = True
                    logger.info(f"✅ {agent.name} a parlé (tentative {attempt+1})")
                    break

                except Exception as e:
                    logger.warning(f"⚠️ Tentative {attempt+1} échouée pour {agent.name}: {e}")
                    if attempt < 2:
                        await asyncio.sleep(0.2)  # Pause avant retry

            if not success:
                logger.error(f"❌ Impossible de faire parler {agent.name}")

    async def _speak_with_agent_voice_safe(self, agent: AgentPersonality, text: str):
        """Méthode sécurisée pour parler avec la voix de l'agent via session.say avec TTS temporaire"""

        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            raise Exception("Pas de clé OpenAI")

        voice = agent.voice_config.get('voice', 'alloy')
        speed = agent.voice_config.get('speed', 1.0)

        # Créer temporairement un TTS avec la bonne voix et l'injecter le temps d'un say
        temp_tts = openai.TTS(
            voice=voice,
            api_key=api_key,
            model="tts-1",
            speed=speed
        )

        original_tts = getattr(self.session, '_tts', None)
        try:
            self.session._tts = temp_tts
            await self.session.say(text=f"{agent.name}: {text}")
        finally:
            if original_tts is not None:
                self.session._tts = original_tts

    def _strip_name_prefix(self, agent: AgentPersonality, text: str) -> str:
        """Supprime un éventuel préfixe "Nom:" pour éviter double annonce au TTS."""
        if not text:
            return text
        first_name = agent.name.split()[0]
        candidates = [agent.name, first_name]
        cleaned = text
        for cand in candidates:
            for sep in [":", "-", "—"]:
                prefix = f"{cand}{sep}"
                if cleaned.strip().lower().startswith(prefix.lower()):
                    cleaned = cleaned.strip()[len(prefix):].lstrip()
        return cleaned
    
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

    async def run_session(self, ctx: JobContext):
        """Execute la session multi-agents avec gestion robuste"""
        self.is_running = True
        
        try:
            logger.info(f"🚀 Démarrage session multi-agents: {self.config.exercise_id}")
            
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
            
            # Initialisation du manager multi-agents
            self.manager.initialize_session()
            
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

def detect_exercise_from_metadata(metadata: str) -> tuple[MultiAgentConfig, dict]:
    """Détecte automatiquement le type d'exercice et extrait les données utilisateur"""
    logger.info("🔍 DÉTECTION AUTOMATIQUE EXERCICE MULTI-AGENTS")
    logger.info("="*60)
    logger.info(f"📥 Métadonnées reçues: '{metadata}'")
    
    try:
        import json
        data = json.loads(metadata) if metadata else {}
        exercise_type = data.get('exercise_type', 'studio_debate_tv')
        
        # Extraire les données utilisateur
        user_data = {
            'user_name': data.get('user_name', 'Participant'),
            'user_subject': data.get('user_subject', 'votre présentation'),
        }
        
        logger.info(f"🎯 Type détecté: '{exercise_type}'")
        logger.info(f"👤 Utilisateur: {user_data['user_name']}")
        logger.info(f"📋 Sujet: {user_data['user_subject']}")
        
        # Mapping des types d'exercices vers les configurations multi-agents
        exercise_mapping = {
            'studio_situations_pro': ExerciseTemplates.studio_debate_tv,
            'studio_debate_tv': ExerciseTemplates.studio_debate_tv,
            'studio_debatPlateau': ExerciseTemplates.studio_debate_tv,
            'studio_job_interview': ExerciseTemplates.studio_job_interview,
            'studio_entretienEmbauche': ExerciseTemplates.studio_job_interview,
            'studio_boardroom': ExerciseTemplates.studio_boardroom,
            'studio_reunionDirection': ExerciseTemplates.studio_boardroom,
            'studio_sales_conference': ExerciseTemplates.studio_sales_conference,
            'studio_conferenceVente': ExerciseTemplates.studio_sales_conference,
            'studio_keynote': ExerciseTemplates.studio_keynote,
            'studio_conferencePublique': ExerciseTemplates.studio_keynote,
        }
        
        if exercise_type in exercise_mapping:
            config = exercise_mapping[exercise_type]()
            logger.info(f"✅ Configuration multi-agents sélectionnée: {config.exercise_id}")
            logger.info(f"   Agents: {[agent.name for agent in config.agents]}")
            return config, user_data
        else:
            logger.warning(f"⚠️ Type inconnu '{exercise_type}', utilisation débat TV par défaut")
            return ExerciseTemplates.studio_debate_tv(), user_data
            
    except Exception as e:
        logger.error(f"❌ Erreur détection exercice: {e}")
        logger.info("🔄 Fallback vers débat TV")
        return ExerciseTemplates.studio_debate_tv(), {'user_name': 'Participant', 'user_subject': 'votre présentation'}


# ==========================================
# POINT D'ENTRÉE PRINCIPAL MULTI-AGENTS
# ==========================================

async def multiagent_entrypoint(ctx: JobContext):
    """Point d'entrée principal pour le système multi-agents Studio Situations Pro"""
    logger.info("🎭 DÉMARRAGE SYSTÈME MULTI-AGENTS STUDIO SITUATIONS PRO")
    logger.info("="*70)
    
    try:
        # 1. ÉTABLIR LA CONNEXION LIVEKIT
        logger.info("🔗 Établissement de la connexion LiveKit multi-agents...")
        await ctx.connect()
        logger.info("✅ Connexion LiveKit multi-agents établie avec succès")
        
        # 2. DIAGNOSTIC ET DÉTECTION DU TYPE D'EXERCICE
        logger.info("🔍 DIAGNOSTIC COMPLET - DÉTECTION EXERCICE MULTI-AGENTS")
        logger.info("="*60)
        
        # Analyser les métadonnées pour détecter le type d'exercice
        metadata = None
        metadata_found_from = "AUCUNE"
        
        # Vérification métadonnées room
        if hasattr(ctx, 'room') and ctx.room and hasattr(ctx.room, 'metadata'):
            room_metadata = ctx.room.metadata
            if room_metadata:
                metadata = room_metadata
                metadata_found_from = "ROOM"
                logger.info(f"✅ Métadonnées trouvées depuis: {metadata_found_from}")
        
        # Vérification métadonnées participants si pas trouvées dans room
        if not metadata and hasattr(ctx, 'room') and ctx.room:
            await asyncio.sleep(2)  # Attendre les participants
            
            for participant_id, participant in ctx.room.remote_participants.items():
                participant_metadata = getattr(participant, 'metadata', None)
                if participant_metadata:
                    metadata = participant_metadata
                    metadata_found_from = f"PARTICIPANT_{participant_id}"
                    logger.info(f"✅ Métadonnées trouvées depuis: {metadata_found_from}")
                    break
        
        # 3. SÉLECTION ET INITIALISATION DE LA CONFIGURATION MULTI-AGENTS
        logger.info("🎯 SÉLECTION CONFIGURATION MULTI-AGENTS")
        
        if metadata:
            logger.info(f"📋 Utilisation métadonnées: {metadata}")
            config, user_data = detect_exercise_from_metadata(metadata)
        else:
            logger.warning("⚠️ Aucune métadonnée trouvée, utilisation configuration par défaut")
            config = ExerciseTemplates.studio_debate_tv()
            user_data = {'user_name': 'Participant', 'user_subject': 'votre présentation'}
        
        logger.info("="*60)
        logger.info(f"🎭 CONFIGURATION MULTI-AGENTS SÉLECTIONNÉE:")
        logger.info(f"   ID: {config.exercise_id}")
        logger.info(f"   Utilisateur: {user_data['user_name']}")
        logger.info(f"   Sujet: {user_data['user_subject']}")
        logger.info(f"   Gestion tours: {config.turn_management}")
        logger.info(f"   Durée max: {config.max_duration_minutes} min")
        logger.info(f"   Nombre d'agents: {len(config.agents)}")
        
        for i, agent in enumerate(config.agents, 1):
            logger.info(f"   Agent {i}: {agent.name} ({agent.role}) - {agent.interaction_style.value}")
            logger.info(f"            Voix: {agent.voice_config}")
        
        logger.info("="*60)
        
        # 4. DÉMARRAGE DU SERVICE MULTI-AGENTS
        logger.info(f"🚀 Démarrage service multi-agents: {config.exercise_id}")
        
        service = MultiAgentLiveKitService(config, user_data)
        await service.run_session(ctx)
        
    except Exception as e:
        logger.error(f"❌ ERREUR CRITIQUE dans le système multi-agents: {e}")
        logger.error("Détails de l'erreur:", exc_info=True)
        
        # Fallback vers le système simple si échec
        logger.info("🔄 Tentative de fallback vers système simple...")
        try:
            from main import legacy_entrypoint
            await legacy_entrypoint(ctx)
        except Exception as fallback_error:
            logger.error(f"❌ Même le fallback échoue: {fallback_error}")
            raise


if __name__ == "__main__":
    """Point d'entrée principal du worker LiveKit multi-agents"""
    logger.info("🎯 DÉMARRAGE WORKER LIVEKIT MULTI-AGENTS STUDIO SITUATIONS PRO")
    
    # Configuration WorkerOptions avec l'entrypoint multi-agents
    worker_options = agents.WorkerOptions(
        entrypoint_fnc=multiagent_entrypoint
    )
    
    logger.info("🎯 WorkerOptions configuré avec système multi-agents")
    logger.info(f"   - Système multi-agents: ✅")
    logger.info(f"   - Agents configurés: Michel Dubois, Sarah Johnson, Marcus Thompson, etc.")
    logger.info(f"   - Gestion des personnalités: ✅")
    logger.info(f"   - Voix distinctes: ✅")
    logger.info(f"   - Identification correcte: ✅")
    
    # Point d'entrée officiel avec CLI LiveKit
    agents.cli.run_app(worker_options)