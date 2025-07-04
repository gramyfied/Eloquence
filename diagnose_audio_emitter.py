import logging
import asyncio
from livekit.agents.tts import AudioEmitter
from livekit.agents import tts
import inspect

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

async def diagnose_audio_emitter():
    """Diagnostic de l'objet AudioEmitter pour comprendre son API"""
    
    logger.info("=== DIAGNOSTIC AudioEmitter ===")
    
    # Examiner la classe AudioEmitter
    logger.info(f"AudioEmitter class: {AudioEmitter}")
    logger.info(f"AudioEmitter MRO: {AudioEmitter.__mro__}")
    
    # Lister tous les attributs et méthodes
    logger.info("\nAttributs et méthodes de AudioEmitter:")
    for name in dir(AudioEmitter):
        if not name.startswith('_'):
            attr = getattr(AudioEmitter, name, None)
            logger.info(f"  - {name}: {type(attr)} - {attr}")
    
    # Examiner les méthodes spécifiquement
    logger.info("\nMéthodes publiques de AudioEmitter:")
    for name, method in inspect.getmembers(AudioEmitter, predicate=inspect.ismethod):
        if not name.startswith('_'):
            sig = inspect.signature(method)
            logger.info(f"  - {name}{sig}")
    
    # Vérifier si AudioEmitter a une méthode emit ou send
    if hasattr(AudioEmitter, 'emit'):
        logger.info("\n✅ AudioEmitter a une méthode 'emit'")
        sig = inspect.signature(AudioEmitter.emit)
        logger.info(f"   Signature: emit{sig}")
    
    if hasattr(AudioEmitter, 'send'):
        logger.info("\n✅ AudioEmitter a une méthode 'send'")
        sig = inspect.signature(AudioEmitter.send)
        logger.info(f"   Signature: send{sig}")
    
    if hasattr(AudioEmitter, 'write'):
        logger.info("\n✅ AudioEmitter a une méthode 'write'")
        sig = inspect.signature(AudioEmitter.write)
        logger.info(f"   Signature: write{sig}")
    
    # Vérifier si c'est un callable
    logger.info(f"\nAudioEmitter est-il callable? {callable(AudioEmitter)}")
    
    # Examiner la documentation
    logger.info(f"\nDocumentation AudioEmitter: {AudioEmitter.__doc__}")
    
    # Examiner le module tts pour comprendre l'API
    logger.info("\n=== Examen du module tts ===")
    logger.info(f"Module tts: {tts}")
    
    # Chercher des exemples d'utilisation dans le code source
    if hasattr(tts, 'SynthesizeStream'):
        logger.info("\nExamen de SynthesizeStream:")
        logger.info(f"SynthesizeStream: {tts.SynthesizeStream}")
        
        # Examiner la méthode _run de la classe parent
        if hasattr(tts.SynthesizeStream, '_run'):
            logger.info("\nSignature de SynthesizeStream._run:")
            try:
                sig = inspect.signature(tts.SynthesizeStream._run)
                logger.info(f"  _run{sig}")
                
                # Obtenir le code source si possible
                source = inspect.getsource(tts.SynthesizeStream._run)
                logger.info(f"\nCode source de SynthesizeStream._run:\n{source}")
            except Exception as e:
                logger.error(f"Impossible d'obtenir le code source: {e}")

if __name__ == "__main__":
    asyncio.run(diagnose_audio_emitter())