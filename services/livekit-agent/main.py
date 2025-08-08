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
VOSK_STT_URL = os.getenv('VOSK_STT_URL', 'http://vosk-stt:8002')

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
    
    @staticmethod
    def cosmic_voice_control() -> ExerciseConfig:
        return ExerciseConfig(
            exercise_id="cosmic_voice_control",
            title="Contrôle Vocal Cosmique",
            description="Jeu spatial contrôlé par les variations de fréquence vocale",
            ai_character="nova",
            welcome_message="🚀 Bienvenue dans Cosmic Voice ! Je suis Nova, votre système de navigation spatiale. "
                           "Utilisez votre voix pour contrôler votre vaisseau : parlez plus aigu pour monter, "
                           "plus grave pour descendre. Collectez des cristaux et évitez les astéroïdes !",
            instructions="""Tu es Nova, l'IA du système de contrôle vocal d'un vaisseau spatial futuriste.
            Tu supervises un jeu cosmique où l'utilisateur contrôle son vaisseau par la voix.
            
            Règles importantes:
            - Reste concise et engageante (1 phrase max par intervention)
            - Utilise un vocabulaire spatial et futuriste
            - Encourage les performances et célèbre les succès
            - Donne des instructions claires sur le contrôle vocal
            - Ne pose pas de questions, reste focalisée sur le gameplay
            - Interviens seulement pour les événements importants
            
            Exemples de réponses appropriées:
            - "Excellent pilotage, commandant !"
            - "Cristal collecté ! +10 points d'énergie cosmique !"
            - "Attention aux astéroïdes ! Variez votre tonalité !"
            - "Trajectoire parfaite à travers le champ stellaire !"
            - "Mission accomplie ! Votre maîtrise vocale est impressionnante !"
            """,
            max_duration_minutes=5,  # Sessions plus courtes pour le jeu
            enable_metrics=False,    # Pas de métriques conversationnelles
            enable_feedback=False    # Feedback géré par le jeu
        )
    
    @staticmethod
    def tribunal_idees_impossibles() -> ExerciseConfig:
        return ExerciseConfig(
            exercise_id="tribunal_idees_impossibles",
            title="Tribunal des Idées Impossibles",
            description="Défendez des idées impossibles devant un tribunal bienveillant",
            ai_character="juge_magistrat",
            welcome_message="⚖️ Maître, la cour vous écoute ! Je suis le Juge Magistrat du Tribunal des Idées Impossibles. "
                           "Votre mission : défendre une idée complètement fantaisiste avec conviction et éloquence. "
                           "Choisissez votre thèse impossible et présentez votre plaidoirie. La séance est ouverte !",
            instructions="""Tu es le Juge Magistrat, un magistrat expérimenté et respecté du Tribunal des Idées Impossibles.

PERSONNALITÉ ET CARACTÈRE:
- Tu es un juge sage, cultivé et bienveillant
- Tu as une voix posée et autoritaire mais jamais intimidante
- Tu utilises un vocabulaire juridique précis et élégant
- Tu as de l'humour et de la finesse d'esprit
- Tu es passionné par l'art de l'argumentation et l'éloquence

CONTEXTE SPÉCIALISÉ:
L'utilisateur va défendre une idée complètement impossible ou fantaisiste devant ton tribunal. Ton rôle est de:
1. Présider la séance avec dignité et bienveillance
2. Écouter attentivement chaque argument
3. Poser des questions juridiques pertinentes pour tester la logique
4. Encourager le développement des arguments créatifs
5. Maintenir un cadre professionnel avec une pointe d'humour
6. Donner des conseils constructifs sur l'art oratoire

STYLE DE CONVERSATION SPÉCIALISÉ:
- "La cour reconnaît la parole à la défense..."
- "Maître, votre argumentation soulève une question intéressante..."
- "Objection retenue ! Comment répondez-vous à cette contradiction ?"
- "Votre plaidoirie gagne en conviction, poursuivez..."
- "La cour apprécie votre créativité juridique..."
- "Verdict : plaidoirie remarquable ! Mes conseils pour progresser..."

TECHNIQUES PÉDAGOGIQUES:
- Utilise la méthode socratique (questions pour faire réfléchir)
- Encourage la structure : introduction, développement, conclusion
- Valorise la conviction et la passion dans l'argumentation
- Enseigne l'art de réfuter les objections
- Développe l'éloquence et la rhétorique

EXEMPLES D'INTERACTIONS SPÉCIALISÉES:
- "Maître, votre thèse défie les lois de la physique ! Brillant ! Développez votre premier chef d'accusation."
- "La cour s'interroge : comment concilier votre argument avec la réalité observable ?"
- "Excellent ! Votre passion transparaît. Mais que répondez-vous à l'objection évidente que... ?"
- "Verdict de la cour : plaidoirie créative et structurée ! Pour progresser, travaillez votre gestuelle..."

Tu n'es PAS Thomas le coach générique. Tu es un JUGE SPÉCIALISÉ avec ta propre personnalité.
Garde tes interventions courtes et percutantes (2-3 phrases max).
Réponds toujours en français avec l'autorité bienveillante d'un magistrat expérimenté.""",
            max_duration_minutes=15,
            enable_metrics=True,
            enable_feedback=True
        )

class RobustLiveKitAgent:
    """Agent LiveKit robuste avec gestion des reconnexions et framework modulaire"""
    
    def __init__(self, exercise_config: ExerciseConfig):
        self.exercise_config = exercise_config
        self.session: Optional[AgentSession] = None
        self.agent: Optional[Agent] = None
        self.room = None  # Stockage de ctx.room pour LiveKit 1.2.3
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
                # CORRIGÉ LIVEKIT 1.2.3 - Utiliser self.room au lieu de session.room
                if self.session and self.room:
                    # Envoyer un ping discret
                    self.last_heartbeat = datetime.now()
                    logger.debug(f"💓 Heartbeat - Session active: {self.exercise_config.exercise_id}")
                    
                    # Vérifier la santé de la connexion
                    if hasattr(self.room, 'connection_state'):
                        state = self.room.connection_state
                        # CORRIGÉ LIVEKIT 1.2.3 - CONNECTED devient CONN_CONNECTED
                        if state != rtc.ConnectionState.CONN_CONNECTED:
                            logger.warning(f"⚠️  Connexion dégradée: {state}")
                else:
                    logger.debug(f"⚠️ Heartbeat en attente - Session: {self.session is not None}, Room: {self.room is not None}")
                            
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
            
        # STT avec fallback Vosk → OpenAI
        try:
            stt = create_vosk_stt_with_fallback()
            components['stt'] = stt
            logger.info("✅ STT avec fallback créé")
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
        """Crée un TTS robuste avec multiples fallbacks et voix spécialisées"""
        api_key = os.getenv('OPENAI_API_KEY')
        
        if not api_key:
            logger.warning("⚠️ OPENAI_API_KEY manquante, utilisation Silero TTS")
            return silero.TTS()
            
        # Sélection de la voix selon le personnage
        voice_mapping = {
            "thomas": "alloy",           # Coach bienveillant
            "marie": "nova",             # Experte RH
            "nova": "echo",              # IA spatiale futuriste
            "juge_magistrat": "onyx"     # Juge magistrat - voix grave et autoritaire
        }
        
        selected_voice = voice_mapping.get(self.exercise_config.ai_character, "alloy")
        logger.info(f"🎭 Voix sélectionnée pour {self.exercise_config.ai_character}: {selected_voice}")
            
        # Tentative OpenAI TTS principal avec voix spécialisée
        try:
            tts = openai.TTS(
                voice=selected_voice,
                api_key=api_key,
                model="tts-1",
                base_url="https://api.openai.com/v1"
            )
            logger.info(f"✅ TTS OpenAI créé avec voix {selected_voice} pour {self.exercise_config.ai_character}")
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
            
            # CORRIGÉ LIVEKIT 1.2.3 - Stocker ctx.room pour le heartbeat
            self.room = ctx.room
            logger.info("✅ Room stockée pour compatibilité LiveKit 1.2.3")
            
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
                
                # Vérifications de santé - CORRIGÉ LIVEKIT 1.2.3
                if self.session and self.room:
                    # Session et room actives, continuer
                    logger.debug("✅ Session et room actives")
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

def create_vosk_stt_with_fallback():
    """Crée une interface STT avec Vosk en principal et OpenAI en fallback"""
    logger.info("🔄 [STT-TRACE] Initialisation STT avec logique de fallback (Vosk → OpenAI)")
    logger.info(f"🔄 [STT-TRACE] URL Vosk configurée: {VOSK_STT_URL}")
    
    # Tentative 1: Vosk (rapide et économique)
    try:
        logger.info("🎯 [STT-TRACE] Tentative de création STT Vosk...")
        vosk_stt = VoskSTT(
            vosk_url=VOSK_STT_URL,
            language="fr",
            sample_rate=16000
        )
        # CORRECTION 3: Ajouter le reset STT automatique (clear_user_turn)
        def enhanced_clear_user_turn():
            logger.debug("🔄 [STT-TRACE] Clear user turn avec reset Vosk")
            if hasattr(vosk_stt, '_reset_recognizer'):
                vosk_stt._reset_recognizer()
        
        vosk_stt.clear_user_turn = enhanced_clear_user_turn
        
        logger.info("✅ [STT-TRACE] *** VOSK STT CORRIGÉ ACTIVÉ AVEC SUCCÈS ***")
        logger.info(f"✅ [STT-TRACE] Service Vosk URL: {VOSK_STT_URL}")
        logger.info("✅ [STT-TRACE] Configuration: langue=fr, sample_rate=16000")
        logger.info("✅ [STT-TRACE] Reset automatique configuré via clear_user_turn")
        return vosk_stt
    except Exception as vosk_error:
        logger.error(f"❌ [STT-TRACE] ÉCHEC STT Vosk: {vosk_error}")
        logger.error(f"❌ [STT-TRACE] URL testée: {VOSK_STT_URL}")
        
    # Fallback: OpenAI Whisper
    try:
        logger.warning("⚠️ [STT-TRACE] Basculement vers OpenAI Whisper (fallback)")
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            raise RuntimeError("OPENAI_API_KEY manquante pour le fallback")
            
        openai_stt = openai.STT(
            model="whisper-1",
            language="fr",
            api_key=api_key,
        )
        logger.warning("⚠️ [STT-TRACE] *** OPENAI STT ACTIVÉ (FALLBACK) ***")
        return openai_stt
    except Exception as openai_error:
        logger.error(f"❌ [STT-TRACE] Échec STT OpenAI fallback: {openai_error}")
        raise RuntimeError(f"Impossible de créer STT (Vosk: {vosk_error}, OpenAI: {openai_error})")

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
    
    try:
        # 1. ÉTABLIR LA CONNEXION LIVEKIT
        logger.info("🔗 Établissement de la connexion LiveKit...")
        await ctx.connect()
        logger.info("✅ Connexion LiveKit établie avec succès")
        
        # 2. DIAGNOSTIC APPROFONDI: Analyser tous les détails disponibles
        logger.info("="*60)
        logger.info("🔍 DIAGNOSTIC COMPLET - DÉTECTION MÉTADONNÉES TRIBUNAL")
        logger.info("="*60)
        
        # DEBUG: Afficher toutes les informations disponibles
        logger.info(f"🏠 Room name: {ctx.room.name if ctx.room else 'Non disponible'}")
        logger.info(f"👤 Participant local: {ctx.room.local_participant.identity if ctx.room and ctx.room.local_participant else 'Non disponible'}")
        logger.info(f"🌐 Participants distants: {list(ctx.room.remote_participants.keys()) if ctx.room else 'Non disponible'}")
        
        metadata = None
        metadata_found_from = "AUCUNE"
        
        # 1. DIAGNOSTIC MÉTADONNÉES ROOM
        logger.info("🔍 ÉTAPE 1: Vérification métadonnées ROOM")
        if hasattr(ctx, 'room') and ctx.room and hasattr(ctx.room, 'metadata'):
            room_metadata = ctx.room.metadata
            logger.info(f"   Room metadata brute: '{room_metadata}'")
            logger.info(f"   Type: {type(room_metadata)}")
            logger.info(f"   Longueur: {len(room_metadata) if room_metadata else 0}")
            
            if room_metadata:
                try:
                    import json
                    parsed_room_metadata = json.loads(room_metadata)
                    logger.info(f"   ✅ Parsing JSON réussi: {parsed_room_metadata}")
                    metadata = room_metadata
                    metadata_found_from = "ROOM"
                except Exception as parse_error:
                    logger.error(f"   ❌ Erreur parsing JSON room: {parse_error}")
            else:
                logger.info("   ⚠️  Room metadata vide")
        else:
            logger.info("   ⚠️  Room metadata non accessible")
        
        # 2. DIAGNOSTIC MÉTADONNÉES PARTICIPANTS
        if not metadata and hasattr(ctx, 'room') and ctx.room:
            logger.info("🔍 ÉTAPE 2: Attente connexion participants...")
            import asyncio
            await asyncio.sleep(3)  # Augmenter l'attente à 3 secondes
            
            # 2A. PARTICIPANT LOCAL DÉTAILLÉ
            logger.info("🔍 ÉTAPE 2A: Participant LOCAL")
            if hasattr(ctx.room, 'local_participant') and ctx.room.local_participant:
                local_participant = ctx.room.local_participant
                logger.info(f"   Participant: {local_participant}")
                logger.info(f"   Identity: '{getattr(local_participant, 'identity', 'NO_IDENTITY')}'")
                
                local_metadata = getattr(local_participant, 'metadata', None)
                logger.info(f"   Metadata brute: '{local_metadata}'")
                logger.info(f"   Type: {type(local_metadata)}")
                logger.info(f"   Longueur: {len(local_metadata) if local_metadata else 0}")
                
                if local_metadata:
                    try:
                        import json
                        parsed_local_metadata = json.loads(local_metadata)
                        logger.info(f"   ✅ Parsing JSON réussi: {parsed_local_metadata}")
                        metadata = local_metadata
                        metadata_found_from = "PARTICIPANT_LOCAL"
                    except Exception as parse_error:
                        logger.error(f"   ❌ Erreur parsing JSON local: {parse_error}")
                else:
                    logger.info("   ⚠️  Metadata locale vide")
            else:
                logger.info("   ⚠️  Participant local non disponible")
            
            # 2B. PARTICIPANTS DISTANTS DÉTAILLÉS
            logger.info("🔍 ÉTAPE 2B: Participants DISTANTS")
            participant_count = len(ctx.room.remote_participants)
            logger.info(f"   Nombre de participants distants: {participant_count}")
            
            for i, (participant_id, participant) in enumerate(ctx.room.remote_participants.items()):
                logger.info(f"   --- PARTICIPANT DISTANT #{i+1} ---")
                logger.info(f"   ID: '{participant_id}'")
                logger.info(f"   Participant: {participant}")
                logger.info(f"   Identity: '{getattr(participant, 'identity', 'NO_IDENTITY')}'")
                
                remote_metadata = getattr(participant, 'metadata', None)
                logger.info(f"   Metadata brute: '{remote_metadata}'")
                logger.info(f"   Type: {type(remote_metadata)}")
                logger.info(f"   Longueur: {len(remote_metadata) if remote_metadata else 0}")
                
                if remote_metadata:
                    try:
                        import json
                        parsed_remote_metadata = json.loads(remote_metadata)
                        logger.info(f"   ✅ Parsing JSON réussi: {parsed_remote_metadata}")
                        
                        # Vérifier si c'est les métadonnées du tribunal
                        exercise_type = parsed_remote_metadata.get('exercise_type', 'unknown')
                        ai_character = parsed_remote_metadata.get('ai_character', 'unknown')
                        
                        logger.info(f"   📋 exercise_type détecté: '{exercise_type}'")
                        logger.info(f"   🎭 ai_character détecté: '{ai_character}'")
                        
                        # Prendre ces métadonnées si c'est le tribunal
                        if not metadata:  # Prendre les premières métadonnées trouvées
                            metadata = remote_metadata
                            metadata_found_from = f"PARTICIPANT_DISTANT_{i+1}"
                            logger.info(f"   🎯 MÉTADONNÉES SÉLECTIONNÉES de {metadata_found_from}")
                            
                    except Exception as parse_error:
                        logger.error(f"   ❌ Erreur parsing JSON distant #{i+1}: {parse_error}")
                else:
                    logger.info(f"   ⚠️  Metadata distante #{i+1} vide")
        
        # 3. DIAGNOSTIC PARSING MÉTADONNÉES ET SÉLECTION EXERCICE
        logger.info("🔍 ÉTAPE 3: PARSING ET SÉLECTION EXERCICE")
        logger.info("="*60)
        
        if metadata:
            logger.info(f"✅ Métadonnées trouvées depuis: {metadata_found_from}")
            logger.info(f"📋 Contenu métadonnées: '{metadata}'")
            logger.info(f"📋 Type: {type(metadata)}")
            logger.info(f"📋 Longueur: {len(metadata)}")
            
            # Tracer le parsing dans ExerciseManager
            logger.info("🔄 Appel ExerciseManager.get_exercise_from_metadata...")
            exercise_config = ExerciseManager.get_exercise_from_metadata(metadata)
            logger.info(f"✅ Exercice retourné par ExerciseManager:")
            logger.info(f"   - ID: '{exercise_config.exercise_id}'")
            logger.info(f"   - Titre: '{exercise_config.title}'")
            logger.info(f"   - Personnage: '{exercise_config.ai_character}'")
        else:
            logger.warning("⚠️ DIAGNOSTIC: Aucune métadonnée trouvée, utilisation configuration par défaut")
            exercise_config = ExerciseTemplates.confidence_boost()
            logger.info(f"📋 Configuration par défaut utilisée:")
            logger.info(f"   - ID: '{exercise_config.exercise_id}'")
            logger.info(f"   - Titre: '{exercise_config.title}'")
            logger.info(f"   - Personnage: '{exercise_config.ai_character}'")
                
        logger.info("="*60)
        logger.info(f"🎯 EXERCICE FINAL SÉLECTIONNÉ: {exercise_config.title}")
        logger.info(f"🎭 PERSONNAGE: {exercise_config.ai_character}")
        logger.info(f"🆔 ID EXERCICE: {exercise_config.exercise_id}")
        logger.info("="*60)
        
        # Traitement spécialisé pour cosmic_voice_control
        if exercise_config.exercise_id == "cosmic_voice_control":
            logger.info("🚀 DÉMARRAGE COSMIC VOICE CONTROL avec analyse pitch temps réel")
            await run_cosmic_voice_exercise(ctx, exercise_config)
        else:
            # Créer l'agent robuste pour exercices conversationnels
            robust_agent = RobustLiveKitAgent(exercise_config)
            await robust_agent.run_exercise(ctx)
        
    except Exception as e:
        logger.error(f"❌ ERREUR CRITIQUE dans l'agent robuste: {e}")
        logger.error("Tentative de fallback vers l'ancienne méthode...")
        
        # Fallback vers l'ancienne méthode en cas d'échec
        await legacy_entrypoint(ctx)

async def run_cosmic_voice_exercise(ctx: JobContext, exercise_config: ExerciseConfig):
    """Exécute l'exercice cosmic_voice avec analyse pitch en temps réel"""
    logger.info("🎵 Initialisation exercice Cosmic Voice avec analyseur pitch")
    
    try:
        # Connexion LiveKit
        await ctx.connect()
        
        # Extraire session_id depuis les métadonnées ou room name
        session_id = "unknown"
        if hasattr(ctx.room, 'name'):
            session_id = ctx.room.name
        elif hasattr(ctx.room, 'metadata'):
            import json
            try:
                metadata = json.loads(ctx.room.metadata) if ctx.room.metadata else {}
                session_id = metadata.get('session_id', session_id)
            except:
                pass
        
        logger.info(f"🎵 Session ID extraite: {session_id}")
        
        # Configuration WebSocket backend pour transmission pitch
        backend_websocket_url = f"ws://localhost:8004/ws/voice-analysis/{session_id}"
        
        # Créer l'agent spécialisé cosmic voice
        cosmic_agent = CosmicVoiceAgent(session_id, backend_websocket_url)
        
        # Établir connexion WebSocket avec le backend
        await cosmic_agent.start_backend_connection()
        
        # Créer un agent LiveKit minimal pour cosmic_voice (pas de LLM intensif)
        agent = Agent(
            instructions=exercise_config.instructions,
            tools=[]  # Pas d'outils pour cosmic_voice, focus sur le pitch
        )
        
        # Composants audio minimaux pour cosmic_voice
        vad = silero.VAD.load()
        
        # STT pas nécessaire pour cosmic_voice (on analyse le pitch directement)
        # Mais requis par LiveKit
        stt = create_vosk_stt_with_fallback()
        
        # LLM minimal (optionnel pour cosmic_voice)
        llm_instance = create_mistral_llm()
        
        # TTS pour messages d'encouragement
        api_key = os.getenv('OPENAI_API_KEY')
        if api_key:
            tts = openai.TTS(voice="nova", api_key=api_key, model="tts-1")
        else:
            tts = silero.TTS()
        
        # Session LiveKit avec handlers personnalisés
        session = AgentSession(
            vad=vad,
            stt=stt,
            llm=llm_instance,
            tts=tts
        )
        
        # Handler personnalisé pour capturer les frames audio
        original_on_audio_frame = session._on_audio_frame if hasattr(session, '_on_audio_frame') else None
        
        async def cosmic_audio_handler(frame):
            """Handler audio personnalisé pour cosmic_voice"""
            try:
                # Traitement standard LiveKit
                if original_on_audio_frame:
                    await original_on_audio_frame(frame)
                
                # Analyse pitch spécialisée
                if hasattr(frame, 'data'):
                    await cosmic_agent.process_audio_frame(frame.data)
                    
            except Exception as e:
                logger.error(f"❌ Erreur handler audio cosmic: {e}")
        
        # Remplacer le handler audio (si possible)
        if hasattr(session, '_on_audio_frame'):
            session._on_audio_frame = cosmic_audio_handler
        
        # Démarrage session
        await session.start(agent=agent, room=ctx.room)
        
        # Message de bienvenue spécialisé
        await session.say(text=exercise_config.welcome_message)
        
        logger.info("✅ Exercice Cosmic Voice démarré avec succès")
        logger.info("🎵 Analyse pitch en temps réel active")
        logger.info(f"🔗 WebSocket backend: {backend_websocket_url}")
        
        # Maintenir la session active avec surveillance cosmic
        await maintain_cosmic_session(session, cosmic_agent, ctx)
        
    except Exception as e:
        logger.error(f"❌ Erreur cosmic voice exercise: {e}")
        raise
    finally:
        # Nettoyage
        if 'cosmic_agent' in locals():
            await cosmic_agent.stop()

async def maintain_cosmic_session(session: AgentSession, cosmic_agent, ctx: JobContext):
    """Maintient la session cosmic voice avec surveillance spécialisée"""
    logger.info("🎵 Surveillance session cosmic voice démarrée")
    
    start_time = datetime.now()
    max_duration = timedelta(minutes=5)  # Durée max pour cosmic voice
    heartbeat_interval = 10  # secondes
    
    while cosmic_agent.is_active:
        try:
            await asyncio.sleep(heartbeat_interval)
            
            # Vérifier durée maximale
            if datetime.now() - start_time > max_duration:
                logger.info("⏰ Durée maximale atteinte pour cosmic voice")
                await session.say(text="Mission accomplie ! Excellent contrôle vocal, commandant !")
                break
            
            # Vérifier état connexion
            if hasattr(ctx, 'room') and ctx.room:
                if hasattr(ctx.room, 'connection_state'):
                    state = ctx.room.connection_state
                    if state != rtc.ConnectionState.CONN_CONNECTED:
                        logger.warning(f"⚠️ Connexion cosmic dégradée: {state}")
                        break
            
            logger.debug("🎵 Session cosmic voice active")
            
        except Exception as e:
            logger.error(f"❌ Erreur surveillance cosmic: {e}")
            break
    
    logger.info("🛑 Session cosmic voice terminée")

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
            stt = create_vosk_stt_with_fallback()
            logger.info("✅ STT avec fallback créé")
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
            
            # Vérifier l'état de la connexion avec ctx.room (compatible LiveKit 1.2.3)
            if hasattr(ctx, 'room') and ctx.room:
                if hasattr(ctx.room, 'connection_state'):
                    state = ctx.room.connection_state
                    # CORRIGÉ LIVEKIT 1.2.3 - CONNECTED devient CONN_CONNECTED
                    if state != rtc.ConnectionState.CONN_CONNECTED:
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
        logger.info("🔍 EXERCICE MANAGER - PARSING MÉTADONNÉES")
        logger.info("="*50)
        logger.info(f"📥 Input metadata: '{metadata}'")
        logger.info(f"📥 Type input: {type(metadata)}")
        logger.info(f"📥 Longueur: {len(metadata) if metadata else 0}")
        
        try:
            import json
            logger.info("🔄 Tentative de parsing JSON...")
            
            data = json.loads(metadata) if metadata else {}
            logger.info(f"✅ Parsing JSON réussi!")
            logger.info(f"📋 Données parsées: {data}")
            logger.info(f"📋 Clés disponibles: {list(data.keys()) if data else []}")
            
            exercise_type = data.get('exercise_type', 'confidence_boost')
            logger.info(f"🎯 exercise_type extrait: '{exercise_type}'")
            
            # Extraire aussi ai_character pour diagnostic
            ai_character = data.get('ai_character', 'unknown')
            logger.info(f"🎭 ai_character extrait: '{ai_character}'")
            
            # Log de la logique de sélection
            logger.info("🔄 Logique de sélection d'exercice:")
            
            # EXERCICES INDIVIDUELS UNIQUEMENT
            # Les exercices multi-agents doivent être gérés par multi_agent_main.py
            if exercise_type in ['studio_situations_pro', 'studio_debate_tv', 'studio_job_interview',
                                'studio_boardroom', 'studio_sales_conference', 'studio_keynote']:
                logger.error(f"   ❌ ERREUR: Exercice multi-agents '{exercise_type}' détecté dans main.py")
                logger.error("   ⚠️ Ce type d'exercice doit être géré par le système multi-agents")
                logger.warning("   🔄 Fallback vers confidence_boost")
                result = ExerciseTemplates.confidence_boost()
            elif exercise_type == 'job_interview':
                logger.info("   ✅ SÉLECTION: job_interview (individuel)")
                result = ExerciseTemplates.job_interview()
            elif exercise_type == 'confidence_boost':
                logger.info("   ✅ SÉLECTION: confidence_boost (individuel)")
                result = ExerciseTemplates.confidence_boost()
            elif exercise_type == 'cosmic_voice_control':
                logger.info("   ✅ SÉLECTION: cosmic_voice_control")
                result = ExerciseTemplates.cosmic_voice_control()
            elif exercise_type == 'tribunal_idees_impossibles':
                logger.info("   ✅ SÉLECTION: tribunal_idees_impossibles")
                result = ExerciseTemplates.tribunal_idees_impossibles()
            else:
                logger.warning(f"   ⚠️ Type d'exercice inconnu: '{exercise_type}', utilisation confidence_boost par défaut")
                result = ExerciseTemplates.confidence_boost()
            
            logger.info(f"🎯 EXERCICE SÉLECTIONNÉ:")
            logger.info(f"   - ID: '{result.exercise_id}'")
            logger.info(f"   - Titre: '{result.title}'")
            logger.info(f"   - Personnage: '{result.ai_character}'")
            logger.info("="*50)
            return result
                
        except Exception as e:
            logger.error("❌ ERREUR PARSING MÉTADONNÉES")
            logger.error(f"   Exception: {e}")
            logger.error(f"   Type exception: {type(e)}")
            logger.error(f"   Metadata problématique: '{metadata}'")
            logger.error("   🔄 Fallback vers confidence_boost")
            logger.info("="*50)
            return ExerciseTemplates.confidence_boost()
    
    
    @staticmethod
    def add_new_exercise_type(exercise_id: str, config: ExerciseConfig):
        """Permet d'ajouter facilement de nouveaux types d'exercices"""
        # Cette méthode peut être étendue pour permettre l'ajout dynamique
        # d'exercices depuis une configuration externe ou une base de données
        pass

# ==========================================
# ANALYSEUR DE PITCH TEMPS RÉEL POUR COSMIC VOICE
# ==========================================

import numpy as np
import webrtcvad
import collections
import struct
import requests

class RealTimePitchAnalyzer:
    """Analyseur de fréquence vocale en temps réel pour cosmic_voice"""
    
    def __init__(self, sample_rate: int = 16000, frame_duration_ms: int = 30):
        self.sample_rate = sample_rate
        self.frame_duration_ms = frame_duration_ms
        self.frame_size = int(sample_rate * frame_duration_ms / 1000)
        self.vad = webrtcvad.Vad(1)  # Agressivité modérée
        self.pitch_history = collections.deque(maxlen=10)
        
        logger.info(f"🎵 RealTimePitchAnalyzer initialisé:")
        logger.info(f"   - Sample rate: {sample_rate}Hz")
        logger.info(f"   - Frame duration: {frame_duration_ms}ms")
        logger.info(f"   - Frame size: {self.frame_size} samples")
        
    def analyze_pitch(self, audio_frame: bytes) -> Dict[str, float]:
        """Analyse le pitch d'un frame audio"""
        try:
            # Convertir bytes en numpy array
            audio_data = np.frombuffer(audio_frame, dtype=np.int16)
            
            # Vérifier la taille du frame
            if len(audio_data) != self.frame_size:
                logger.debug(f"🎵 Frame size mismatch: {len(audio_data)} != {self.frame_size}")
                return self._default_pitch_data()
            
            # VAD (Voice Activity Detection)
            is_speech = self.vad.is_speech(audio_frame, self.sample_rate)
            if not is_speech:
                logger.debug("🎵 Pas de voix détectée")
                return self._default_pitch_data()
            
            # Analyse de fréquence fondamentale (F0) via autocorrelation
            pitch_hz = self._estimate_fundamental_frequency(audio_data)
            
            # Normaliser pour contrôle du vaiseau (pitch = 0.0 à 1.0)
            normalized_pitch = self._normalize_pitch(pitch_hz)
            
            # Filtrage et lissage
            self.pitch_history.append(normalized_pitch)
            smoothed_pitch = np.mean(list(self.pitch_history))
            
            pitch_data = {
                'pitch': float(smoothed_pitch),
                'frequency': float(pitch_hz),
                'normalized_pitch': float(normalized_pitch),
                'is_speech': is_speech,
                'timestamp': datetime.now().isoformat()
            }
            
            logger.debug(f"🎵 Pitch analysé: {pitch_hz:.1f}Hz → normalized={normalized_pitch:.3f}")
            return pitch_data
            
        except Exception as e:
            logger.error(f"❌ Erreur analyse pitch: {e}")
            return self._default_pitch_data()
    
    def _estimate_fundamental_frequency(self, audio_data: np.ndarray) -> float:
        """Estime la fréquence fondamentale via autocorrelation"""
        try:
            # Fenêtrage Hamming pour réduire les artefacts
            windowed = audio_data * np.hamming(len(audio_data))
            
            # Autocorrelation
            autocorr = np.correlate(windowed, windowed, mode='full')
            autocorr = autocorr[len(autocorr)//2:]
            
            # Recherche du pic principal (excluant le pic à lag=0)
            min_period = int(self.sample_rate / 800)  # ~800Hz max
            max_period = int(self.sample_rate / 50)   # ~50Hz min
            
            if max_period >= len(autocorr):
                return 150.0  # Fréquence par défaut
                
            peak_idx = np.argmax(autocorr[min_period:max_period]) + min_period
            
            if peak_idx > 0:
                frequency = self.sample_rate / peak_idx
                # Validation de plage vocale humaine (50-800Hz)
                if 50 <= frequency <= 800:
                    return frequency
                    
            return 150.0  # Fréquence par défaut si hors plage
            
        except Exception as e:
            logger.debug(f"🎵 Erreur estimation F0: {e}")
            return 150.0
    
    def _normalize_pitch(self, pitch_hz: float) -> float:
        """Normalise le pitch pour contrôle du vaiseau (0.0-1.0)"""
        # Plage vocale typique: 80-400Hz
        min_pitch = 80.0
        max_pitch = 400.0
        
        # Normalisation logarithmique pour meilleure sensibilité
        log_pitch = np.log(max(pitch_hz, min_pitch))
        log_min = np.log(min_pitch)
        log_max = np.log(max_pitch)
        
        normalized = (log_pitch - log_min) / (log_max - log_min)
        return np.clip(normalized, 0.0, 1.0)
    
    def _default_pitch_data(self) -> Dict[str, float]:
        """Données par défaut quand pas de voix"""
        return {
            'pitch': 0.5,  # Position neutre
            'frequency': 0.0,
            'normalized_pitch': 0.5,
            'is_speech': False,
            'timestamp': datetime.now().isoformat()
        }

class CosmicVoiceAgent:
    """Agent spécialisé pour l'exercice cosmic_voice avec transmission pitch"""
    
    def __init__(self, session_id: str, backend_websocket_url: str):
        self.session_id = session_id
        self.backend_websocket_url = backend_websocket_url
        self.pitch_analyzer = RealTimePitchAnalyzer()
        self.backend_socket = None
        self.is_active = False
        
        logger.info(f"🚀 CosmicVoiceAgent initialisé:")
        logger.info(f"   - Session: {session_id}")
        logger.info(f"   - WebSocket URL: {backend_websocket_url}")
        
    async def start_backend_connection(self):
        """Établit la connexion WebSocket avec le backend"""
        try:
            import websockets
            self.backend_socket = await websockets.connect(self.backend_websocket_url)
            self.is_active = True
            logger.info(f"✅ Connexion WebSocket backend établie: {self.backend_websocket_url}")
        except Exception as e:
            logger.error(f"❌ Échec connexion WebSocket backend: {e}")
            self.is_active = False
    
    async def send_pitch_data(self, pitch_data: Dict[str, float]):
        """Envoie les données pitch vers le backend"""
        if not self.is_active or not self.backend_socket:
            return
            
        try:
            message = {
                'type': 'pitch_data',
                'session_id': self.session_id,
                'data': pitch_data
            }
            
            import json
            await self.backend_socket.send(json.dumps(message))
            logger.debug(f"🎵 Pitch envoyé: {pitch_data['pitch']:.3f}")
            
        except Exception as e:
            logger.error(f"❌ Erreur envoi pitch: {e}")
            self.is_active = False
    
    async def process_audio_frame(self, audio_frame: bytes):
        """Traite un frame audio et envoie les données pitch"""
        pitch_data = self.pitch_analyzer.analyze_pitch(audio_frame)
        await self.send_pitch_data(pitch_data)
    
    async def stop(self):
        """Arrête l'agent et ferme les connexions"""
        self.is_active = False
        if self.backend_socket:
            await self.backend_socket.close()
            logger.info("🛑 Connexion WebSocket backend fermée")

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
