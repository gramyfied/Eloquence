"""
Agent multi-agents LiveKit simplifié
"""
import os
import asyncio
import logging
from dataclasses import dataclass
from typing import Optional, Dict, Any, List
import json
import redis.asyncio as redis
from aiohttp import web
import aiohttp

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class AgentConfig:
    """Configuration pour un agent LiveKit"""
    agent_id: str
    livekit_url: str
    api_key: Optional[str] = None
    api_secret: Optional[str] = None
    redis_url: str = "redis://redis:6379/0"
    max_concurrent_sessions: int = 3
    port: int = 8080
    metrics_port: int = 9091

class MultiAgent:
    """Agent multi-agents simplifié pour LiveKit"""
    
    def __init__(self, config: AgentConfig):
        self.config = config
        self.redis_client = None
        self.sessions: Dict[str, Any] = {}
        self.app = web.Application()
        self.setup_routes()
        
    def setup_routes(self):
        """Configure les routes HTTP"""
        self.app.router.add_get('/health', self.health_check)
        self.app.router.add_get('/metrics', self.metrics)
        self.app.router.add_post('/api/agent/session', self.create_session)
        self.app.router.add_delete('/api/agent/session/{session_id}', self.end_session)
        
    async def health_check(self, request):
        """Endpoint de health check pour HAProxy"""
        health_status = {
            "status": "healthy",
            "agent_id": self.config.agent_id,
            "active_sessions": len(self.sessions),
            "max_sessions": self.config.max_concurrent_sessions
        }
        return web.json_response(health_status)
    
    async def metrics(self, request):
        """Endpoint de métriques pour Prometheus"""
        metrics = [
            f'# HELP agent_sessions_active Number of active sessions',
            f'# TYPE agent_sessions_active gauge',
            f'agent_sessions_active{{agent_id="{self.config.agent_id}"}} {len(self.sessions)}',
            f'# HELP agent_sessions_max Maximum concurrent sessions',
            f'# TYPE agent_sessions_max gauge',
            f'agent_sessions_max{{agent_id="{self.config.agent_id}"}} {self.config.max_concurrent_sessions}'
        ]
        return web.Response(text='\n'.join(metrics), content_type='text/plain')
    
    async def create_session(self, request):
        """Crée une nouvelle session"""
        try:
            data = await request.json()
            session_id = data.get('session_id', f'{self.config.agent_id}_{len(self.sessions)}')
            
            if len(self.sessions) >= self.config.max_concurrent_sessions:
                return web.json_response(
                    {"error": "Max concurrent sessions reached"},
                    status=503
                )
            
            self.sessions[session_id] = {
                "id": session_id,
                "agent_id": self.config.agent_id,
                "created_at": asyncio.get_event_loop().time(),
                "data": data
            }
            
            logger.info(f"Session créée: {session_id}")
            return web.json_response({"session_id": session_id, "status": "created"})
        except Exception as e:
            logger.error(f"Erreur création session: {e}")
            return web.json_response({"error": str(e)}, status=500)
    
    async def end_session(self, request):
        """Termine une session"""
        session_id = request.match_info['session_id']
        if session_id in self.sessions:
            del self.sessions[session_id]
            logger.info(f"Session terminée: {session_id}")
            return web.json_response({"status": "ended"})
        return web.json_response({"error": "Session not found"}, status=404)
    
    async def connect_redis(self):
        """Connexion à Redis"""
        try:
            self.redis_client = await redis.from_url(self.config.redis_url)
            await self.redis_client.ping()
            logger.info("Connecté à Redis")
        except Exception as e:
            logger.error(f"Erreur connexion Redis: {e}")
    
    async def start(self):
        """Démarre l'agent"""
        logger.info(f"Initialisation de l'agent {self.config.agent_id}")
        
        # Connexion Redis
        await self.connect_redis()
        
        # Démarrage du serveur HTTP
        runner = web.AppRunner(self.app)
        await runner.setup()
        site = web.TCPSite(runner, '0.0.0.0', self.config.port)
        await site.start()
        
        logger.info(f"Agent {self.config.agent_id} démarré sur port {self.config.port}")
        
        # Boucle principale
        try:
            while True:
                # Simulation d'activité
                await asyncio.sleep(10)
                if self.redis_client:
                    await self.redis_client.set(
                        f"agent:{self.config.agent_id}:heartbeat",
                        json.dumps({
                            "timestamp": asyncio.get_event_loop().time(),
                            "sessions": len(self.sessions)
                        }),
                        ex=30
                    )
        except asyncio.CancelledError:
            logger.info(f"Agent {self.config.agent_id} arrêté")
            if self.redis_client:
                await self.redis_client.close()

async def main():
    """Point d'entrée principal"""
    # Configuration depuis les variables d'environnement
    config = AgentConfig(
        agent_id=os.environ.get("AGENT_ID", "agent_default"),
        livekit_url=os.environ.get("LIVEKIT_URL", "ws://localhost:7880"),
        api_key=os.environ.get("LIVEKIT_API_KEY"),
        api_secret=os.environ.get("LIVEKIT_API_SECRET"),
        redis_url=os.environ.get("REDIS_URL", "redis://redis:6379/0"),
        max_concurrent_sessions=int(os.environ.get("MAX_CONCURRENT_SESSIONS", "3")),
        port=int(os.environ.get("PORT", "8080")),
        metrics_port=int(os.environ.get("METRICS_PORT", "9091"))
    )
    
    logger.info(f"Configuration de l'agent: {config.agent_id}")
    logger.info(f"LiveKit URL: {config.livekit_url}")
    logger.info(f"Redis URL: {config.redis_url}")
    logger.info(f"Max agents concurrents: {config.max_concurrent_sessions}")
    
    agent = MultiAgent(config)
    await agent.start()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Arrêt demandé")