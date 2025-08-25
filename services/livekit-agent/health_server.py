import asyncio
import os
import logging
from aiohttp import web


async def health(_: web.Request) -> web.Response:
    return web.json_response({"status": "ok"})

async def metrics(_: web.Request) -> web.Response:
    try:
        from elevenlabs_optimized_service import elevenlabs_optimized_service
        from interpellation_system_complete import _global_system as inter_sys
        tts_metrics = elevenlabs_optimized_service.get_performance_metrics() if elevenlabs_optimized_service else {}
        inter_metrics = inter_sys.get_performance_metrics() if inter_sys else {}
        return web.json_response({
            "tts": tts_metrics,
            "interpellation": inter_metrics
        })
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)


async def main() -> None:
    # Logs serveur aiohttp (access log activé pour Docker)
    access_log = logging.getLogger("aiohttp.access")
    access_log.setLevel(getattr(logging, os.getenv("LOG_LEVEL", "INFO").upper(), logging.INFO))

    app = web.Application()
    app.router.add_get('/health', health)
    app.router.add_get('/metrics-lite', metrics)
    runner = web.AppRunner(app)
    await runner.setup()
    port = int(os.environ.get('PORT', '8080'))
    site = web.TCPSite(runner, '0.0.0.0', port)
    await site.start()
    try:
        while True:
            await asyncio.sleep(3600)
    except asyncio.CancelledError:
        pass


if __name__ == '__main__':
    asyncio.run(main())


