import asyncio
import logging
import os
from dotenv import load_dotenv

from livekit import agents, rtc
from livekit.agents import JobContext, WorkerOptions, cli
from livekit.agents.voice import Agent, AgentSession
from livekit.plugins import openai, silero

# Charger les variables d'environnement
load_dotenv()

# Configuration du logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Récupérer les variables d'environnement
LIVEKIT_URL = os.getenv("LIVEKIT_URL", "ws://localhost:7880")
LIVEKIT_API_KEY = os.getenv("LIVEKIT_API_KEY")
LIVEKIT_API_SECRET = os.getenv("LIVEKIT_API_SECRET")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

logger.info(f"🔧 [CONFIG] LiveKit URL: {LIVEKIT_URL}")
logger.info(f"🔧 [CONFIG] LiveKit API Key: {LIVEKIT_API_KEY}")
logger.info(f"🔧 [CONFIG] LiveKit API Secret: {'*' * 10 if LIVEKIT_API_SECRET else 'NOT SET'}")
logger.info(f"🔧 [CONFIG] OpenAI API Key: {'sk-proj-...' + OPENAI_API_KEY[-4:] if OPENAI_API_KEY else 'NOT SET'}")

async def entrypoint(ctx: JobContext):
    """
    Point d'entrée minimal pour tester le TTS
    """
    logger.info("🚀 [ENTRYPOINT] Démarrage minimal")

    # Connexion à la room
    await ctx.connect()
    logger.info(f"✅ [ROOM] Connecté à: {ctx.room.name}")

    # Configuration minimale avec l'API v1.1.5
    initial_ctx = agents.llm.ChatContext()
    
    # Utiliser la nouvelle API pour ajouter des messages
    if hasattr(initial_ctx, 'add_message'):
        # Nouvelle API v1.1.5
        initial_ctx.add_message(
            role="system",
            content="Tu es un assistant vocal simple. Réponds brièvement."
        )
    elif hasattr(initial_ctx, 'append'):
        # Ancienne API (fallback)
        initial_ctx.append(
            role="system",
            text="Tu es un assistant vocal simple. Réponds brièvement."
        )
    else:
        # Si aucune méthode n'est disponible, créer avec messages
        from livekit.agents.llm import ChatMessage, ChatRole
        initial_ctx = agents.llm.ChatContext(messages=[
            ChatMessage(
                role=ChatRole.SYSTEM,
                content="Tu es un assistant vocal simple. Réponds brièvement."
            )
        ])

    # Créer l'agent avec la nouvelle API v1.1.5
    agent = Agent(
        instructions="Tu es un assistant vocal simple. Réponds brièvement.",
        chat_ctx=initial_ctx,
        stt=openai.STT(),
        vad=silero.VAD.load(),
        llm=openai.LLM(),
        tts=openai.TTS(
            model="tts-1",
            voice="shimmer"
        ),
    )
    
    # Créer une session d'agent
    session = AgentSession()
    logger.info("🔧 [SESSION] Session créée")
    
    # Démarrer l'agent avec la session
    await session.start(agent, room=ctx.room)
    logger.info("✅ [AGENT] Agent démarré avec succès")
    
    # Message de bienvenue
    await session.say("Bonjour ! Je suis votre assistant vocal. Comment puis-je vous aider ?")
    logger.info("🎤 [TTS] Message de bienvenue envoyé")

if __name__ == "__main__":
    # Configurer les options du worker avec les paramètres de connexion
    worker_options = WorkerOptions(
        entrypoint_fnc=entrypoint,
        api_key=LIVEKIT_API_KEY,
        api_secret=LIVEKIT_API_SECRET,
        ws_url=LIVEKIT_URL
    )
    
    logger.info("🚀 [MAIN] Démarrage du worker avec les options configurées")
    cli.run_app(worker_options)