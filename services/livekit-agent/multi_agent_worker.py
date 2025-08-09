#!/usr/bin/env python3
"""
Worker multi-agent avec serveur HTTP pour health checks et métriques
"""

import os
import asyncio
import logging
from aiohttp import web
from livekit import agents
from livekit.agents import WorkerOptions, cli
from unified_entrypoint import unified_entrypoint, request_fnc

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("multi_agent_worker")

# Variables d'environnement
AGENT_ID = os.getenv("AGENT_ID", "agent_1")
AGENT_PORT = int(os.getenv("AGENT_PORT", "8080"))
METRICS_PORT = int(os.getenv("METRICS_PORT", "9091"))
LIVEKIT_URL = os.getenv("LIVEKIT_URL", "ws://localhost:7880")
API_KEY = os.getenv("LIVEKIT_API_KEY", "devkey")
API_SECRET = os.getenv("LIVEKIT_API_SECRET", "devsecret123456789abcdef0123456789abcdef")

# Serveur HTTP pour health checks et métriques
async def health_handler(request):
    return web.json_response({
        "status": "healthy",
        "agent_id": AGENT_ID,
        "livekit_connected": True,
        "timestamp": asyncio.get_event_loop().time()
    })

async def metrics_handler(request):
    return web.json_response({
        "agent_id": AGENT_ID,
        "status": "running",
        "livekit_url": LIVEKIT_URL,
        "uptime": asyncio.get_event_loop().time()
    })

async def start_http_server():
    app = web.Application()
    app.router.add_get("/health", health_handler)
    app.router.add_get("/metrics", metrics_handler)
    
    runner = web.AppRunner(app)
    await runner.setup()
    
    site = web.TCPSite(runner, "0.0.0.0", AGENT_PORT)
    await site.start()
    
    logger.info(f"🚀 HTTP server started on port {AGENT_PORT}")
    return runner

async def main():
    logger.info(f"🚀 === MULTI-AGENT WORKER STARTING === {AGENT_ID}")
    logger.info(f"🔗 LiveKit URL: {LIVEKIT_URL}")
    logger.info(f"🌐 HTTP Port: {AGENT_PORT}")
    logger.info(f"📊 Metrics Port: {METRICS_PORT}")
    
    # Démarrer le serveur HTTP
    http_runner = await start_http_server()
    
    try:
        # Démarrer le worker LiveKit
        cli.run_app(
            WorkerOptions(
                entrypoint_fnc=unified_entrypoint,
                request_fnc=request_fnc,
                ws_url=LIVEKIT_URL,
                api_key=API_KEY,
                api_secret=API_SECRET,
            )
        )
    except KeyboardInterrupt:
        logger.info("🛑 Shutting down...")
    finally:
        await http_runner.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
