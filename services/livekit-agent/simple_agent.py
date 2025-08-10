"""
Agent LiveKit simple pour tester la configuration Scaleway
"""
import os
import logging
import asyncio
from datetime import datetime

# Configuration des logs
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Variables d'environnement
LIVEKIT_URL = os.getenv('LIVEKIT_URL', 'ws://livekit-server:7880')
LIVEKIT_API_KEY = os.getenv('LIVEKIT_API_KEY', 'devkey')
LIVEKIT_API_SECRET = os.getenv('LIVEKIT_API_SECRET', 'devsecret123456789abcdef0123456789abcdef')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
SCALEWAY_API_KEY = os.getenv('SCALEWAY_API_KEY')
SCALEWAY_PROJECT_ID = os.getenv('SCALEWAY_PROJECT_ID')
SCALEWAY_MODEL = os.getenv('SCALEWAY_MODEL', 'mistral-nemo-instruct-2407')

def test_configuration():
    """Teste la configuration des variables d'environnement"""
    logger.info("=" * 60)
    logger.info("🎙️ TEST DE CONFIGURATION LIVEKIT AGENT")
    logger.info("=" * 60)
    
    # Test OpenAI
    if OPENAI_API_KEY and OPENAI_API_KEY.startswith('sk-'):
        logger.info("✅ OpenAI API Key configurée")
    else:
        logger.warning("⚠️ OpenAI API Key manquante ou invalide")
    
    # Test Scaleway
    if SCALEWAY_API_KEY and SCALEWAY_PROJECT_ID:
        logger.info("✅ Scaleway configuré")
        logger.info(f"   - Project ID: {SCALEWAY_PROJECT_ID}")
        logger.info(f"   - Model: {SCALEWAY_MODEL}")
        logger.info(f"   - API Key: {SCALEWAY_API_KEY[:8]}...")
    else:
        logger.warning("⚠️ Scaleway non configuré")
    
    # Test LiveKit
    logger.info(f"📍 LiveKit URL: {LIVEKIT_URL}")
    logger.info(f"🔑 LiveKit API Key: {LIVEKIT_API_KEY}")
    
    logger.info("=" * 60)

def test_scaleway_connection():
    """Teste la connexion à Scaleway"""
    if not (SCALEWAY_API_KEY and SCALEWAY_PROJECT_ID):
        logger.error("❌ Scaleway non configuré")
        return False
    
    try:
        from openai import OpenAI
        
        # Configuration Scaleway
        scaleway_base_url = f"https://api.scaleway.ai/{SCALEWAY_PROJECT_ID}/v1"
        logger.info(f"🔌 Test de connexion à Scaleway: {scaleway_base_url}")
        
        client = OpenAI(
            base_url=scaleway_base_url,
            api_key=SCALEWAY_API_KEY
        )
        
        # Test simple
        response = client.chat.completions.create(
            model=SCALEWAY_MODEL,
            messages=[
                {"role": "system", "content": "Tu es un assistant."},
                {"role": "user", "content": "Dis 'Bonjour' en un mot."}
            ],
            max_tokens=10,
            temperature=0.3
        )
        
        result = response.choices[0].message.content
        logger.info(f"✅ Scaleway répond: {result}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur Scaleway: {e}")
        return False

def test_openai_connection():
    """Teste la connexion à OpenAI"""
    if not OPENAI_API_KEY:
        logger.warning("⚠️ OpenAI non configuré")
        return False
    
    try:
        from openai import OpenAI
        
        logger.info("🔌 Test de connexion à OpenAI...")
        
        client = OpenAI(api_key=OPENAI_API_KEY)
        
        # Test simple
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Tu es un assistant."},
                {"role": "user", "content": "Dis 'Bonjour' en un mot."}
            ],
            max_tokens=10,
            temperature=0.3
        )
        
        result = response.choices[0].message.content
        logger.info(f"✅ OpenAI répond: {result}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur OpenAI: {e}")
        return False

async def simple_http_server():
    """Serveur HTTP simple pour le health check"""
    from aiohttp import web
    
    async def health(request):
        return web.json_response({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "openai_configured": bool(OPENAI_API_KEY),
            "scaleway_configured": bool(SCALEWAY_API_KEY and SCALEWAY_PROJECT_ID),
            "livekit_url": LIVEKIT_URL
        })
    
    app = web.Application()
    app.router.add_get('/health', health)
    
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', 8080)
    
    logger.info("🌐 Serveur HTTP démarré sur le port 8080")
    await site.start()

async def main():
    """Point d'entrée principal"""
    # Test de configuration
    test_configuration()
    
    # Test des connexions
    openai_ok = test_openai_connection()
    scaleway_ok = test_scaleway_connection()
    
    if not openai_ok and not scaleway_ok:
        logger.error("❌ Aucun LLM disponible!")
    elif openai_ok and not scaleway_ok:
        logger.info("✅ OpenAI disponible (Scaleway non configuré)")
    elif not openai_ok and scaleway_ok:
        logger.info("✅ Scaleway disponible (OpenAI non configuré)")
    else:
        logger.info("✅ OpenAI et Scaleway disponibles")
    
    # Démarrer le serveur HTTP
    await simple_http_server()
    
    # Garder le service actif
    logger.info("✅ Agent prêt et en attente...")
    while True:
        await asyncio.sleep(60)
        logger.debug("💓 Heartbeat...")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("🛑 Arrêt demandé")
    except Exception as e:
        logger.error(f"❌ Erreur fatale: {e}")
        import traceback
        traceback.print_exc()