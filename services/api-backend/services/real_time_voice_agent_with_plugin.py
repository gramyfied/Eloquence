import asyncio
import logging
import os
from dotenv import load_dotenv

from livekit import agents
from livekit.agents import AgentSession, Agent, JobContext
from livekit.plugins import openai as openai_plugin
from livekit.plugins import silero

# Charger les variables d'environnement
load_dotenv()

# Configuration du logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Import de notre LLM personnalisé
from real_time_voice_agent_force_audio_fixed import MistralLLM, EloquenceCoach

async def entrypoint(ctx: agents.JobContext):
    """
    Point d'entrée utilisant le plugin OpenAI officiel pour TTS
    """
    logger.info("🚀 [ENTRYPOINT] Démarrage avec plugin OpenAI officiel")

    # Vérifier la clé API OpenAI
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if not openai_api_key:
        logger.error("❌ OPENAI_API_KEY non définie!")
        return

    # Utilisation du plugin OpenAI officiel pour TTS
    tts = openai_plugin.TTS(
        api_key=openai_api_key,
        model="tts-1",
        voice="alloy"
    )

    # Créer la session avec le plugin officiel
    session = AgentSession(
        llm=MistralLLM(),
        tts=tts,  # Plugin officiel
        vad=silero.VAD.load(),
    )

    # L'agent personnalisé
    agent = EloquenceCoach()

    # Démarrer la session
    logger.info("🔧 [SESSION] Démarrage de la session avec plugin OpenAI...")
    await session.start(
        room=ctx.room,
        agent=agent,
    )
    logger.info("✅ [SESSION] Session démarrée avec succès")

    # Connexion à la room
    await ctx.connect()
    logger.info(f"✅ [ROOM] Agent connecté à la room: {ctx.room.name}")

    # Message de bienvenue
    logger.info("🎙️ [WELCOME] Envoi du message de bienvenue...")
    try:
        await session.generate_reply(
            instructions="Bonjour ! Je suis votre coach d'éloquence IA. Je suis maintenant connecté et prêt à vous aider. Parlez-moi pour commencer notre session."
        )
        logger.info("✅ [WELCOME] Message de bienvenue envoyé")
    except Exception as e:
        logger.error(f"❌ [WELCOME] Erreur: {e}")

    # Boucle d'événements
    try:
        async for e in session.events():
            if isinstance(e, agents.Agent.AgentSpeechEvent):
                if e.type == agents.Agent.AgentSpeechEventTypes.STARTED:
                    logger.info("🔊 [SPEECH] L'agent commence à parler")
                elif e.type == agents.Agent.AgentSpeechEventTypes.FINISHED:
                    logger.info("🔊 [SPEECH] L'agent a fini de parler")
            elif isinstance(e, agents.Agent.AgentUserSpeechEvent):
                logger.info(f"🗣️ [USER_SPEECH] Utilisateur: {e.text}")
                if e.text:
                    agent.error_count = 0
            elif isinstance(e, agents.Agent.AgentChatMessageEvent):
                logger.info(f"💬 [CHAT] Message: {e.message.body}")
                agent.error_count = 0
    except Exception as e:
        logger.error(f"❌ [EVENTS] Erreur: {e}")
        agent.error_count += 1
        
        if agent.error_count >= agent.max_errors:
            logger.warning("⚠️ [AGENT] Réinitialisation du contexte")
            try:
                if hasattr(session, '_chat_ctx'):
                    session._chat_ctx.clear()
                    logger.info("✅ [AGENT] Contexte réinitialisé")
                agent.error_count = 0
            except Exception as reset_e:
                logger.error(f"❌ [AGENT] Erreur réinitialisation: {reset_e}")

if __name__ == "__main__":
    print("[MAIN] Démarrage avec plugin OpenAI officiel...", flush=True)
    agents.cli.run_app(agents.WorkerOptions(entrypoint_fnc=entrypoint))