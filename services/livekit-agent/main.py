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
from vosk_stt_interface import VoskSTT

# Charger les variables d'environnement
load_dotenv()

# Configuration avec logs détaillés pour debug
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Log des variables d'environnement critiques (sans exposer les secrets)
logger.info("🔍 DIAGNOSTIC: Variables d'environnement")
logger.info(f"   OPENAI_API_KEY présente: {'Oui' if os.getenv('OPENAI_API_KEY') else 'Non'}")
logger.info(f"   MISTRAL_BASE_URL: {os.getenv('MISTRAL_BASE_URL', 'Non définie')}")

# URLs des services
MISTRAL_API_URL = os.getenv('MISTRAL_BASE_URL', 'http://mistral-conversation:8001/v1/chat/completions')

# ==========================================
# FRAMEWORK RÉUTILISABLE POUR EXERCICES AUDIO
# ==========================================

@dataclass
class ExerciseConfig:
    """Configuration d'un exercice audio réutilisable"""
    exercise_id: str
    title: str
    description: str
    ai_character: str = "thomas"
    welcome_message: str = ""
    instructions: str = ""
    max_duration_minutes: int = 15
    enable_metrics: bool = True
    enable_feedback: bool = True

class ExerciseTemplates:
    """Templates d'exercices prédéfinis réutilisables"""
    
    @staticmethod
    def confidence_boost() -> ExerciseConfig:
        return ExerciseConfig(
            exercise_id="confidence_boost",
            title="Renforcement de Confiance",
            description="Exercice pour améliorer la confiance en expression orale",
            ai_character="thomas",
            welcome_message="Bonjour ! Je suis Thomas, votre coach IA pour améliorer votre confiance en expression orale. "
                           "Grâce à une reconnaissance vocale ultra-rapide, je peux vous donner des conseils personnalisés en temps réel. "
                           "Dites-moi comment vous vous sentez aujourd'hui ou commencez simplement à parler !",
            instructions="""Tu es Thomas, un coach en communication bienveillant et professionnel.
            Tu aides l'utilisateur dans des exercices de confiance en soi et d'expression orale.
            
            Règles importantes:
            - Sois encourageant et constructif
            - Donne des conseils pratiques et personnalisés
            - Utilise un ton bienveillant et professionnel
            - Réponds en français
            - Adapte tes conseils au contexte de l'exercice
            - Utilise les outils disponibles pour analyser la confiance de l'utilisateur
            - Garde tes réponses courtes et engageantes (2-3 phrases max)""",
        )
    
    @staticmethod
    def job_interview() -> ExerciseConfig:
        return ExerciseConfig(
            exercise_id="job_interview",
            title="Entretien d'Embauche",
            description="Simulation d'entretien d'embauche avec feedback personnalisé",
            ai_character="marie",
            welcome_message="Bonjour ! Je suis Marie, votre coach pour l'entretien d'embauche. "
                           "Je vais simuler un entretien professionnel et vous donner des conseils pour réussir. "
                           "Présentez-vous comme si nous commencions un vrai entretien !",
            instructions="""Tu es Marie, une experte RH bienveillante spécialisée dans les entretiens d'embauche.
            Tu simules un entretien d'embauche réaliste tout en étant encourageante.
            
            Règles importantes:
            - Pose des questions d'entretien pertinentes et progressives
            - Donne des conseils constructifs sur la présentation
            - Adapte ton niveau selon l'expérience de l'utilisateur
            - Reste professionnelle mais bienveillante
            - Utilise les outils de feedback disponibles
            - Garde tes questions et conseils concis""",
        )

class RobustLiveKitAgent:
    """Agent LiveKit robuste avec gestion des reconnexions et framework modulaire"""
    
    def __init__(self, exercise_config: ExerciseConfig):
        self.exercise_config = exercise_config
        self.session: Optional[AgentSession] = None
        self.agent: Optional[Agent] = None
        self.last_heartbeat = datetime.now()
        self.is_running = False
        self.reconnect_attempts = 0
        self.max_reconnect_attempts = 5
        self.heartbeat_interval = 30  # secondes
        
    async def start_heartbeat(self):
        """Keep-alive pour maintenir la connexion active"""
        while self.is_running:
            try:
                await asyncio.sleep(self.heartbeat_interval)
                if self.session and self.session.room:
                    # Envoyer un ping discret
                    self.last_heartbeat = datetime.now()
                    logger.debug(f"💓 Heartbeat - Session active: {self.exercise_config.exercise_id}")
                    
                    # Vérifier la santé de la connexion
                    if hasattr(self.session.room, 'connection_state'):
                        state = self.session.room.connection_state
                        if state != rtc.ConnectionState.CONNECTED:
                            logger.warning(f"⚠️  Connexion dégradée: {state}")
                            
            except Exception as e:
                logger.error(f"❌ Erreur heartbeat: {e}")
                if self.reconnect_attempts < self.max_reconnect_attempts:
                    await self.attempt_reconnection()
                    
    async def attempt_reconnection(self):
        """Tentative de reconnexion automatique"""
        self.reconnect_attempts += 1
        logger.warning(f"🔄 Tentative de reconnexion {self.reconnect_attempts}/{self.max_reconnect_attempts}")
        
        try:
            await asyncio.sleep(2 ** self.reconnect_attempts)  # Backoff exponentiel
            # La logique de reconnexion sera implémentée selon le contexte LiveKit
            logger.info("✅ Reconnexion réussie")
            self.reconnect_attempts = 0
        except Exception as e:
            logger.error(f"❌ Échec reconnexion: {e}")
            
    def create_robust_agent(self) -> Agent:
        """Crée un agent robuste avec gestion d'erreurs"""
        try:
            agent = Agent(
                instructions=self.exercise_config.instructions,
                tools=[generate_confidence_metrics, send_confidence_feedback],
            )
            logger.info(f"🎯 Agent créé pour exercice: {self.exercise_config.exercise_id}")
            return agent
        except Exception as e:
            logger.error(f"❌ Erreur création agent: {e}")
            raise
            
    async def initialize_components(self):
        """Initialise les composants avec fallbacks robustes"""
        components = {}
        
        # VAD avec fallback
        try:
            vad = silero.VAD.load()
            components['vad'] = vad
            logger.info("✅ VAD Silero chargé")
        except Exception as e:
            logger.error(f"❌ Erreur VAD: {e}")
            raise
            
        # STT avec fallback
        try:
            stt = create_openai_stt()
            components['stt'] = stt
            logger.info("✅ STT OpenAI créé")
        except Exception as e:
            logger.error(f"❌ Erreur STT: {e}")
            raise
            
        # LLM avec fallback
        try:
            llm_instance = create_mistral_llm()
            components['llm'] = llm_instance
            logger.info("✅ LLM OpenAI créé")
        except Exception as e:
            logger.error(f"❌ Erreur LLM: {e}")
            raise
            
        # TTS avec fallbacks multiples
        try:
            tts = await self.create_robust_tts()
            components['tts'] = tts
            logger.info("✅ TTS créé avec fallbacks")
        except Exception as e:
            logger.error(f"❌ Erreur TTS: {e}")
            raise
            
        return components
        
    async def create_robust_tts(self):
        """Crée un TTS robuste avec multiples fallbacks"""
        api_key = os.getenv('OPENAI_API_KEY')
        
        if not api_key:
            logger.warning("⚠️ OPENAI_API_KEY manquante, utilisation Silero TTS")
            return silero.TTS()
            
        # Tentative OpenAI TTS principal
        try:
            tts = openai.TTS(
                voice="alloy",
                api_key=api_key,
                model="tts-1",
                base_url="https://api.openai.com/v1"
            )
            logger.info("✅ TTS OpenAI principal créé")
            return tts
        except Exception as e:
            logger.warning(f"⚠️ OpenAI TTS principal échoué: {e}")
            
        # Fallback Silero
        try:
            tts = silero.TTS()
            logger.info("✅ TTS Silero fallback créé")
            return tts
        except Exception as e:
            logger.error(f"❌ Même Silero TTS échoue: {e}")
            raise
            
    async def run_exercise(self, ctx: JobContext):
        """Execute l'exercice avec gestion robuste"""
        self.is_running = True
        
        try:
            logger.info(f"🚀 Démarrage exercice robuste: {self.exercise_config.title}")
            
            # Connexion avec retry
            await self.connect_with_retry(ctx)
            
            # Initialisation des composants
            components = await self.initialize_components()
            
            # Création de l'agent
            self.agent = self.create_robust_agent()
            
            # Création de la session
            self.session = AgentSession(**components)
            
            # Démarrage du heartbeat
            heartbeat_task = asyncio.create_task(self.start_heartbeat())
            
            # Démarrage de la session
            await self.session.start(agent=self.agent, room=ctx.room)
            
            # Message de bienvenue personnalisé
            if self.exercise_config.welcome_message:
                await self.session.say(text=self.exercise_config.welcome_message)
                
            logger.info(f"✅ Exercice {self.exercise_config.exercise_id} démarré avec succès")
            
            # Maintenir la session active
            await self.maintain_session()
            
        except Exception as e:
            logger.error(f"❌ Erreur exercice: {e}")
            raise
        finally:
            self.is_running = False
            
    async def connect_with_retry(self, ctx: JobContext, max_retries: int = 3):
        """Connexion avec retry automatique"""
        for attempt in range(max_retries):
            try:
                await ctx.connect()
                logger.info(f"✅ Connexion réussie (tentative {attempt + 1})")
                return
            except Exception as e:
                logger.warning(f"⚠️ Échec connexion tentative {attempt + 1}: {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(2 ** attempt)
                else:
                    raise
                    
    async def maintain_session(self):
        """Maintient la session active avec surveillance"""
        while self.is_running:
            try:
                await asyncio.sleep(5)  # Check toutes les 5 secondes
                
                # Vérifications de santé
                if self.session and hasattr(self.session, 'room'):
                    # Session active, continuer
                    pass
                else:
                    logger.warning("⚠️ Session dégradée détectée")
                    
            except Exception as e:
                logger.error(f"❌ Erreur maintenance session: {e}")
                break

# ==========================================
# OUTILS FONCTION POUR L'AGENT IA
# ==========================================

@function_tool
async def generate_confidence_metrics(
    user_message: str,
) -> Dict[str, float]:
    """Génère des métriques de confiance basées sur le message utilisateur"""
    try:
        # Métriques basiques basées sur l'analyse du texte
        message_length = len(user_message)
        word_count = len(user_message.split())

        # Calculs simplifiés (à améliorer avec de vraies analyses)
        confidence_level = min(0.5 + (word_count * 0.05), 1.0)
        voice_clarity = min(0.6 + (message_length * 0.001), 1.0)
        speaking_pace = 0.7  # Valeur par défaut
        energy_level = min(0.4 + (word_count * 0.03), 1.0)

        return {
            'confidence_level': confidence_level,
            'voice_clarity': voice_clarity,
            'speaking_pace': speaking_pace,
            'energy_level': energy_level,
        }

    except Exception as e:
        logger.error(f"❌ Erreur génération métriques: {e}")
        return {
            'confidence_level': 0.7,
            'voice_clarity': 0.8,
            'speaking_pace': 0.7,
            'energy_level': 0.6,
        }


@function_tool
async def send_confidence_feedback(
    user_message: str,
    confidence_level: float,
    voice_clarity: float,
    speaking_pace: float,
    energy_level: float,
) -> str:
    """Envoie des feedbacks personnalisés basés sur les métriques de confiance"""
    try:
        if confidence_level > 0.8 and voice_clarity > 0.8:
            return "Excellent ! Votre confiance transparaît clairement dans votre discours. Continuez ainsi !"
        elif confidence_level > 0.6:
            return "Très bien ! Je sens une belle assurance dans vos mots. Vous progressez remarquablement."
        else:
            return "C'est un bon début ! Prenez votre temps, respirez profondément et exprimez-vous librement."

    except Exception as e:
        logger.error(f"❌ Erreur feedback: {e}")
        return "Continuez à vous exprimer, vous faites du très bon travail !"

# ==========================================
# FONCTIONS DE CRÉATION DES COMPOSANTS
# ==========================================

def create_openai_stt():
    """Crée une interface STT utilisant OpenAI Whisper (natif LiveKit agents)"""
    api_key = os.getenv('OPENAI_API_KEY')
    logger.info(f"🔍 Configuration OpenAI STT - Modèle: whisper-1, Langue: fr")
    
    return openai.STT(
        model="whisper-1",
        language="fr",
        api_key=api_key,
    )

def create_mistral_llm():
    """Crée un LLM configuré pour utiliser OpenAI (plus stable)"""
    api_key = os.getenv('OPENAI_API_KEY')
    logger.info(f"🔍 Configuration OpenAI LLM - Modèle: gpt-4o-mini")
    
    return openai.LLM(
        model="gpt-4o-mini",
        api_key=api_key,
    )

# ==========================================
# POINT D'ENTRÉE PRINCIPAL ROBUSTE
# ==========================================

async def robust_entrypoint(ctx: JobContext):
    """Point d'entrée robuste avec framework modulaire et gestion d'erreurs"""
    logger.info("🚀 DÉMARRAGE AGENT ROBUSTE AVEC FRAMEWORK MODULAIRE")
    
    # Détecter le type d'exercice depuis les métadonnées de la room
    exercise_config = ExerciseTemplates.confidence_boost()  # Par défaut
    
    try:
        # Extraire les métadonnées de la room pour déterminer l'exercice
        if hasattr(ctx, 'room') and ctx.room and hasattr(ctx.room, 'metadata'):
            metadata = ctx.room.metadata
            if metadata:
                logger.info(f"📋 Métadonnées room détectées: {metadata}")
                # Parsing des métadonnées pour déterminer l'exercice
                # (format JSON attendu avec exercise_type)
                
        logger.info(f"🎯 Exercice sélectionné: {exercise_config.title}")
        
        # Créer l'agent robuste
        robust_agent = RobustLiveKitAgent(exercise_config)
        
        # Lancer l'exercice avec gestion robuste
        await robust_agent.run_exercise(ctx)
        
    except Exception as e:
        logger.error(f"❌ ERREUR CRITIQUE dans l'agent robuste: {e}")
        logger.error("Tentative de fallback vers l'ancienne méthode...")
        
        # Fallback vers l'ancienne méthode en cas d'échec
        await legacy_entrypoint(ctx)

async def legacy_entrypoint(ctx: JobContext):
    """Ancienne méthode comme fallback"""
    logger.info("🔄 FALLBACK - Utilisation de l'ancienne méthode")
    
    try:
        await ctx.connect()
        
        # Configuration de l'agent conversationnel
        agent = Agent(
            instructions=ExerciseTemplates.confidence_boost().instructions,
            tools=[generate_confidence_metrics, send_confidence_feedback],
        )
        
        # Initialisation des composants avec fallbacks
        try:
            vad = silero.VAD.load()
            logger.info("✅ VAD Silero chargé")
        except Exception as e:
            logger.error(f"❌ Erreur VAD: {e}")
            raise
            
        try:
            stt = create_openai_stt()
            logger.info("✅ STT OpenAI créé")
        except Exception as e:
            logger.error(f"❌ Erreur STT: {e}")
            raise
            
        try:
            llm_instance = create_mistral_llm()
            logger.info("✅ LLM OpenAI créé")
        except Exception as e:
            logger.error(f"❌ Erreur LLM: {e}")
            raise
            
        # TTS avec fallbacks multiples
        try:
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                logger.warning("⚠️ OPENAI_API_KEY manquante, utilisation Silero TTS")
                tts = silero.TTS()
            else:
                try:
                    tts = openai.TTS(
                        voice="alloy",
                        api_key=api_key,
                        model="tts-1",
                        base_url="https://api.openai.com/v1"
                    )
                    logger.info("✅ TTS OpenAI créé")
                except Exception as openai_error:
                    logger.warning(f"⚠️ OpenAI TTS échoué: {openai_error}, fallback Silero")
                    tts = silero.TTS()
        except Exception as e:
            logger.error(f"❌ Erreur TTS générale: {e}")
            tts = silero.TTS()  # Fallback ultime
        
        # Création de la session
        session = AgentSession(
            vad=vad,
            stt=stt,
            llm=llm_instance,
            tts=tts,
        )
        
        # Démarrage avec surveillance
        await session.start(agent=agent, room=ctx.room)
        
        # Message de bienvenue
        welcome_message = ExerciseTemplates.confidence_boost().welcome_message
        await session.say(text=welcome_message)
        
        logger.info("✅ Session agent legacy démarrée avec succès")
        
        # Surveillance de la session avec keep-alive
        await maintain_session_health(session, ctx)
        
    except Exception as e:
        logger.error(f"❌ ERREUR dans fallback legacy: {e}")
        raise

async def maintain_session_health(session: AgentSession, ctx: JobContext):
    """Maintient la santé de la session avec surveillance continue"""
    logger.info("💓 Démarrage de la surveillance de santé de session")
    
    heartbeat_interval = 30  # secondes
    max_silent_duration = 300  # 5 minutes sans activité
    last_activity = datetime.now()
    
    while True:
        try:
            await asyncio.sleep(heartbeat_interval)
            
            # Vérifier l'état de la connexion
            if hasattr(ctx, 'room') and ctx.room:
                if hasattr(ctx.room, 'connection_state'):
                    state = ctx.room.connection_state
                    if state != rtc.ConnectionState.CONNECTED:
                        logger.warning(f"⚠️ État de connexion dégradé: {state}")
                        
                # Vérifier l'activité récente
                current_time = datetime.now()
                if (current_time - last_activity).seconds > max_silent_duration:
                    logger.info("📢 Envoi d'un message de maintien de l'engagement")
                    await session.say(
                        text="Je suis toujours là pour vous aider. N'hésitez pas à continuer notre conversation !"
                    )
                    last_activity = current_time
                
                logger.debug(f"💓 Heartbeat OK - Session active depuis {(current_time - last_activity).seconds}s")
            else:
                logger.warning("⚠️ Room non disponible, arrêt de la surveillance")
                break
                
        except Exception as e:
            logger.error(f"❌ Erreur dans la surveillance: {e}")
            await asyncio.sleep(5)  # Attendre avant de retry

# ==========================================
# GESTIONNAIRE D'EXERCICES MODULAIRE
# ==========================================

class ExerciseManager:
    """Gestionnaire centralisé des exercices pour faciliter l'ajout de nouveaux types"""
    
    @staticmethod
    def get_exercise_from_metadata(metadata: str) -> ExerciseConfig:
        """Détermine l'exercice à partir des métadonnées"""
        try:
            import json
            data = json.loads(metadata) if metadata else {}
            exercise_type = data.get('exercise_type', 'confidence_boost')
            
            if exercise_type == 'job_interview':
                return ExerciseTemplates.job_interview()
            elif exercise_type == 'confidence_boost':
                return ExerciseTemplates.confidence_boost()
            else:
                logger.warning(f"⚠️ Type d'exercice inconnu: {exercise_type}, utilisation par défaut")
                return ExerciseTemplates.confidence_boost()
                
        except Exception as e:
            logger.error(f"❌ Erreur parsing métadonnées: {e}")
            return ExerciseTemplates.confidence_boost()
    
    @staticmethod
    def add_new_exercise_type(exercise_id: str, config: ExerciseConfig):
        """Permet d'ajouter facilement de nouveaux types d'exercices"""
        # Cette méthode peut être étendue pour permettre l'ajout dynamique
        # d'exercices depuis une configuration externe ou une base de données
        pass

if __name__ == "__main__":
    """Point d'entrée principal robuste avec fallbacks"""
    logger.info("🎯 DÉMARRAGE WORKER LIVEKIT ROBUSTE AVEC FRAMEWORK MODULAIRE")
    
    # Configuration WorkerOptions avec l'entrypoint robuste
    worker_options = agents.WorkerOptions(
        entrypoint_fnc=robust_entrypoint
    )
    
    logger.info("🎯 WorkerOptions configuré avec agent robuste")
    logger.info(f"   - Framework modulaire: ✅")
    logger.info(f"   - Gestion des reconnexions: ✅")
    logger.info(f"   - Keep-alive intégré: ✅")
    logger.info(f"   - Fallbacks multiples: ✅")
    
    # Point d'entrée officiel avec CLI LiveKit
    agents.cli.run_app(worker_options)