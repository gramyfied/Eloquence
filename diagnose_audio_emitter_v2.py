#!/usr/bin/env python3
"""
Diagnostic approfondi de l'API AudioEmitter pour comprendre son utilisation correcte
"""

import asyncio
import logging
from livekit.agents.tts import AudioEmitter

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

async def test_audio_emitter():
    """Test l'API AudioEmitter pour comprendre son utilisation"""
    
    # D'abord, examiner la signature du constructeur
    import inspect
    logger.info("=== Signature AudioEmitter ===")
    sig = inspect.signature(AudioEmitter)
    logger.info(f"AudioEmitter signature: {sig}")
    
    # Créer une instance AudioEmitter sans paramètres
    emitter = AudioEmitter()
    
    # Examiner les attributs et méthodes
    logger.info("=== AudioEmitter API ===")
    logger.info(f"Type: {type(emitter)}")
    logger.info(f"Attributs publics: {[attr for attr in dir(emitter) if not attr.startswith('_')]}")
    
    # Vérifier les propriétés
    logger.info(f"\n=== Propriétés ===")
    if hasattr(emitter, 'started'):
        logger.info(f"started: {emitter.started}")
    if hasattr(emitter, 'initialized'):
        logger.info(f"initialized: {emitter.initialized}")
    if hasattr(emitter, 'streaming'):
        logger.info(f"streaming: {emitter.streaming}")
    
    # Test 1: Essayer d'utiliser push sans initialisation
    logger.info("\n=== Test 1: push sans initialisation ===")
    try:
        test_data = b'\x00' * 1024
        await emitter.push(test_data)
        logger.info("✅ push() fonctionne sans initialisation")
    except Exception as e:
        logger.error(f"❌ Erreur avec push(): {e}")
    
    # Test 2: Essayer avec initialize()
    logger.info("\n=== Test 2: Avec initialize() ===")
    try:
        # Vérifier si initialize existe et ses paramètres
        if hasattr(emitter, 'initialize'):
            import inspect
            sig = inspect.signature(emitter.initialize)
            logger.info(f"Signature de initialize: {sig}")
            
            # Essayer d'appeler initialize
            result = emitter.initialize()
            if asyncio.iscoroutine(result):
                logger.info("initialize() retourne une coroutine, await nécessaire")
                await result
            else:
                logger.info("initialize() est synchrone")
            
            logger.info("✅ initialize() appelé avec succès")
            
            # Vérifier l'état après initialize
            if hasattr(emitter, 'started'):
                logger.info(f"started après initialize: {emitter.started}")
    except Exception as e:
        logger.error(f"❌ Erreur avec initialize(): {e}")
    
    # Test 3: Essayer push après initialize
    logger.info("\n=== Test 3: push après initialize ===")
    try:
        test_data = b'\x00' * 1024
        await emitter.push(test_data)
        logger.info("✅ push() fonctionne après initialize")
    except Exception as e:
        logger.error(f"❌ Erreur avec push() après initialize: {e}")
    
    # Test 4: Vérifier start() si elle existe
    logger.info("\n=== Test 4: Vérifier start() ===")
    if hasattr(emitter, 'start'):
        try:
            import inspect
            sig = inspect.signature(emitter.start)
            logger.info(f"Signature de start: {sig}")
            
            result = emitter.start()
            if asyncio.iscoroutine(result):
                logger.info("start() retourne une coroutine, await nécessaire")
                await result
            else:
                logger.info("start() est synchrone")
                
            logger.info("✅ start() appelé avec succès")
            
            # Vérifier l'état après start
            if hasattr(emitter, 'started'):
                logger.info(f"started après start: {emitter.started}")
        except Exception as e:
            logger.error(f"❌ Erreur avec start(): {e}")
    
    # Test 5: Essayer push après start
    logger.info("\n=== Test 5: push après start ===")
    try:
        test_data = b'\x00' * 1024
        await emitter.push(test_data)
        logger.info("✅ push() fonctionne après start")
    except Exception as e:
        logger.error(f"❌ Erreur avec push() après start: {e}")
    
    # Test 6: Vérifier end_input
    logger.info("\n=== Test 6: Vérifier end_input ===")
    if hasattr(emitter, 'end_input'):
        try:
            emitter.end_input()
            logger.info("✅ end_input() appelé avec succès")
        except Exception as e:
            logger.error(f"❌ Erreur avec end_input(): {e}")
    
    # Test 7: Vérifier flush
    logger.info("\n=== Test 7: Vérifier flush ===")
    if hasattr(emitter, 'flush'):
        try:
            result = emitter.flush()
            if asyncio.iscoroutine(result):
                await result
                logger.info("✅ flush() (async) appelé avec succès")
            else:
                logger.info("✅ flush() (sync) appelé avec succès")
        except Exception as e:
            logger.error(f"❌ Erreur avec flush(): {e}")

if __name__ == "__main__":
    asyncio.run(test_audio_emitter())