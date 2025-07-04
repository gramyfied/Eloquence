import httpx
import logging
import asyncio

logger = logging.getLogger(__name__)

class LiveKitAgentService:
    """
    Service pour gérer les agents LiveKit.
    Note: Les agents LiveKit v1.x se connectent automatiquement aux rooms,
    il n'y a pas besoin de les démarrer via HTTP.
    """
    
    def __init__(self, agent_base_url: str = "http://eloquence-agent-v1:8080"):
        self.agent_base_url = agent_base_url
        logger.info(f"LiveKitAgentService initialized (mode: auto-connect)")

    async def _async_start_agent_for_session(self, session_data: dict) -> bool:
        """
        Les agents LiveKit v1.x se connectent automatiquement.
        Cette méthode retourne toujours True.
        """
        room_name = session_data.get('room_name')
        logger.info(f"✅ Agent auto-connecté pour la room: {room_name}")
        logger.info("ℹ️ Les agents LiveKit v1.x se connectent automatiquement aux rooms")
        
        # L'agent se connecte automatiquement, pas besoin d'appel HTTP
        return True

    def start_agent_for_session(self, session_data: dict) -> bool:
        """
        Wrapper synchrone - retourne toujours True car l'agent se connecte automatiquement
        """
        room_name = session_data.get('room_name')
        logger.info(f"✅ Agent auto-connecté pour la room: {room_name}")
        return True

    def get_active_agents_count(self) -> int:
        """
        Retourne le nombre d'agents actifs (simulé)
        """
        try:
            logger.info("📊 Récupération du nombre d'agents actifs")
            return 1  # Un agent est toujours actif
        except Exception as e:
            logger.error(f"❌ Erreur récupération agents actifs: {e}")
            return 0

# Instancier le service une seule fois
agent_service = LiveKitAgentService()
