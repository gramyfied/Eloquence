from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import uvloop  # Performance boost Scaleway
from core.vosk_engine import VoskEngine
from analyzers.analyzer_factory import AnalyzerFactory
from api.models import AnalysisRequest, AnalysisResponse
import logging

# Configuration ultra-performance
asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

app = FastAPI(
    title="Eloquence Vosk STT-Analysis Service",
    description="Service unifié STT + Analyse vocale modulaire ultra-performant",
    version="2.0.0"
)

# CORS pour Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Instances globales optimisées
vosk_engine = VoskEngine()
analyzer_factory = AnalyzerFactory()
logger = logging.getLogger(__name__)

@app.on_event("startup")
async def startup_event():
    """Initialisation optimisée au démarrage"""
    await vosk_engine.initialize_all_models()
    logger.info("🚀 Vosk Engine initialisé avec tous les modèles")

@app.post("/api/analyze", response_model=AnalysisResponse)
async def analyze_speech(
    audio_file: UploadFile,
    exercise_type: str,
    exercise_config: str = None,  # JSON config
    language: str = "fr"
):
    """
    Endpoint universel pour tous types d'exercices
    
    exercise_type: confidence, pronunciation, fluency, debate, etc.
    exercise_config: Configuration spécifique à l'exercice (JSON)
    language: Langue d'analyse (fr, en, etc.)
    """
    try:
        # 1. STT + Reconnaissance Vosk ultra-rapide
        recognition_result = await vosk_engine.recognize_audio(
            audio_data=await audio_file.read(),
            language=language,
            model_size="large"  # Modèle le plus puissant
        )
        
        # 2. Analyse modulaire selon le type d'exercice
        analyzer = analyzer_factory.get_analyzer(exercise_type)
        analysis_result = await analyzer.analyze(
            recognition_result=recognition_result,
            config=exercise_config
        )
        
        return AnalysisResponse(
            exercise_type=exercise_type,
            transcription=recognition_result['text'],
            recognition_details=recognition_result,
            analysis=analysis_result,
            processing_time_ms=analysis_result.processing_time
        )
        
    except Exception as e:
        logger.error(f"Erreur analyse {exercise_type}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    """Endpoint santé optimisé"""
    return {
        "status": "healthy",
        "service": "vosk-stt-analysis",
        "vosk_models_loaded": vosk_engine.get_loaded_models(),
        "available_analyzers": analyzer_factory.get_available_analyzers(),
        "version": "2.0.0"
    }

# Endpoint compatibilité (remplace whisper-stt)
@app.post("/api/transcribe")
async def transcribe_compatibility(audio_file: UploadFile):
    """Endpoint de compatibilité pour migration progressive"""
    try:
        recognition_result = await vosk_engine.recognize_audio(
            audio_data=await audio_file.read(),
            language="fr",
            model_size="large"
        )
        
        # Format compatible avec ancien whisper-stt
        return {
            "text": recognition_result['text'],
            "confidence": recognition_result['confidence'],
            "processing_time": recognition_result.get('processing_time', 0)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))