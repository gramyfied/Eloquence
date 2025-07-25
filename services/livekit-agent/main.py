import asyncio
import json
import logging
import os
from typing import Dict, Any, List
import aiohttp
from dotenv import load_dotenv
from livekit import agents
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

# Configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# URLs des services
MISTRAL_API_URL = os.getenv('MISTRAL_BASE_URL', 'http://mistral-conversation:8001/v1/chat/completions')
VOSK_SERVICE_URL = os.getenv('VOSK_SERVICE_URL', 'http://vosk-stt:8002')

@function_tool
async def generate_confidence_metrics(
    context: RunContext,
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
    context: RunContext,
    metrics: Dict[str, float],
    user_message: str,
) -> str:
    """Envoie des feedbacks personnalisés basés sur les métriques de confiance"""
    try:
        confidence = metrics.get('confidence_level', 0.7)
        clarity = metrics.get('voice_clarity', 0.8)
        
        if confidence > 0.8 and clarity > 0.8:
            return "Excellent ! Votre confiance transparaît clairement dans votre discours. Continuez ainsi !"
        elif confidence > 0.6:
            return "Très bien ! Je sens une belle assurance dans vos mots. Vous progressez remarquablement."
        else:
            return "C'est un bon début ! Prenez votre temps, respirez profondément et exprimez-vous librement."
            
    except Exception as e:
        logger.error(f"❌ Erreur feedback: {e}")
        return "Continuez à vous exprimer, vous faites du très bon travail !"

# Configuration simple en utilisant OpenAI LLM
def create_vosk_stt():
    """Crée une interface STT utilisant notre service Vosk local (latence optimisée)"""
    return VoskSTT(
        vosk_url=VOSK_SERVICE_URL,
        language="fr",
        sample_rate=16000
    )

def create_mistral_llm():
    """Crée un LLM configuré pour utiliser OpenAI (plus stable)"""
    return openai.LLM(
        model="gpt-4o-mini",
        api_key=os.getenv('OPENAI_API_KEY'),
    )

async def entrypoint(ctx: JobContext):
    """Point d'entrée principal de l'agent LiveKit officiel"""
    logger.info("🎯 DIAGNOSTIC: Fonction entrypoint appelée!")
    logger.info(f"🎯 DIAGNOSTIC: JobContext - Room: {ctx.room.name if ctx.room else 'None'}")
    
    try:
        await ctx.connect()
        logger.info("🎯 DIAGNOSTIC: Connexion ctx réussie")
        
        # Configuration de l'agent selon les bonnes pratiques LiveKit
        agent = Agent(
            instructions="""Tu es Thomas, un coach en communication bienveillant et professionnel.
            Tu aides l'utilisateur dans des exercices de confiance en soi et d'expression orale.
            
            Règles importantes:
            - Sois encourageant et constructif
            - Donne des conseils pratiques et personnalisés
            - Utilise un ton bienveillant et professionnel
            - Réponds en français
            - Adapte tes conseils au contexte de l'exercice
            - Utilise les outils disponibles pour analyser la confiance de l'utilisateur""",
            tools=[generate_confidence_metrics, send_confidence_feedback],
        )
        logger.info("🎯 DIAGNOSTIC: Agent créé")
        
        # Configuration de la session avec Vosk STT optimisé + OpenAI pour LLM/TTS
        session = AgentSession(
            vad=silero.VAD.load(),  # Détection d'activité vocale
            stt=create_vosk_stt(),  # Speech-to-Text Vosk local (~0.5s)
            llm=create_mistral_llm(),  # LLM OpenAI
            tts=openai.TTS(voice="alloy"),  # Text-to-Speech OpenAI
        )
        logger.info("🎯 DIAGNOSTIC: AgentSession créée")
        
        logger.info("🚀 Agent LiveKit Confidence Boost démarré avec l'architecture officielle")
        
        # Démarrer la session dans la room
        await session.start(agent=agent, room=ctx.room)
        logger.info("🎯 DIAGNOSTIC: Session.start() appelée avec succès")
        
        # Message de bienvenue initial
        await session.generate_reply(
            instructions="Salue chaleureusement l'utilisateur en tant que Thomas, son coach IA. "
                       "Explique que tu es là pour l'aider à améliorer sa confiance en expression orale. "
                       "Mentionne que tu utilises une technologie de reconnaissance vocale ultra-rapide. "
                       "Invite-le à commencer l'exercice quand il est prêt."
        )
        logger.info("🎯 DIAGNOSTIC: Message de bienvenue généré")
        
        logger.info("✅ Session agent démarrée avec succès")
        
    except Exception as e:
        logger.error(f"❌ ERREUR dans entrypoint: {e}")
        raise

if __name__ == "__main__":
    """Point d'entrée principal selon la documentation officielle LiveKit"""
    logger.info("🎯 DIAGNOSTIC: Démarrage du worker LiveKit selon pattern officiel")
    
    # Configuration WorkerOptions selon la documentation officielle (sans auto_subscribe)
    worker_options = agents.WorkerOptions(
        entrypoint_fnc=entrypoint
    )
    
    logger.info("🎯 DIAGNOSTIC: WorkerOptions configuré selon documentation officielle")
    logger.info(f"🎯 DIAGNOSTIC: entrypoint_fnc = {entrypoint}")
    
    # Point d'entrée officiel avec CLI LiveKit selon la documentation
    agents.cli.run_app(worker_options)