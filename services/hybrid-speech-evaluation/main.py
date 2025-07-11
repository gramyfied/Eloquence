#!/usr/bin/env python3
"""
Service d'Évaluation Hybride VOSK + Whisper Large-v3-Turbo
============================================================

Ce service combine la reconnaissance vocale temps réel de VOSK avec l'analyse
de précision élevée de Whisper large-v3-turbo pour offrir une évaluation complète de la parole.

Fonctionnalités:
- Feedback temps réel via VOSK et WebSocket
- Analyse finale précise via Whisper large-v3-turbo (service Docker existant)
- Métriques prosodiques avancées (WPM, pauses, hésitations)
- API REST pour l'intégration Flutter

Architecture:
- VOSK: Reconnaissance temps réel (feedback immédiat)
- Whisper: Transcription finale précise (service existant port 8001)
- Orchestrateur: Coordination et analyse prosodique
"""

import asyncio
import logging
import json
import uuid
from contextlib import asynccontextmanager
from typing import Dict, Any, Optional
from fastapi import FastAPI, WebSocket, HTTPException, UploadFile, File, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

# Configuration des logs
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Services modulaires (à implémenter)
from services.vosk_realtime_service import VoskRealtimeService
from services.whisper_client_service import WhisperClientService  
from services.hybrid_orchestrator import HybridOrchestrator

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application"""
    logger.info("🚀 Démarrage du Service d'Évaluation Hybride VOSK + Whisper")
    
    try:
        # Initialisation des services
        logger.info("Initialisation du service VOSK temps réel...")
        app.state.vosk_service = VoskRealtimeService()
        await app.state.vosk_service.initialize()
        
        logger.info("Initialisation du client Whisper...")
        app.state.whisper_client = WhisperClientService(
            whisper_url="http://whisper-stt:8001"  # Service Docker existant
        )
        await app.state.whisper_client.initialize()
        
        logger.info("Initialisation de l'orchestrateur hybride...")
        app.state.orchestrator = HybridOrchestrator(
            vosk_service=app.state.vosk_service,
            whisper_client=app.state.whisper_client
        )
        
        logger.info("✅ Services hybrides initialisés avec succès")
        yield
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'initialisation des services: {e}")
        raise
    finally:
        # Nettoyage
        logger.info("🔄 Arrêt des services hybrides...")
        if hasattr(app.state, 'vosk_service'):
            await app.state.vosk_service.cleanup()
        if hasattr(app.state, 'whisper_client'):
            await app.state.whisper_client.cleanup()
        logger.info("✅ Services hybrides arrêtés proprement")

# Application FastAPI
app = FastAPI(
    title="Service d'Évaluation Hybride VOSK + Whisper",
    description="Architecture moderne combinant reconnaissance temps réel (VOSK) et analyse précise (Whisper Large-v3-Turbo)",
    version="1.0.0",
    lifespan=lifespan
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Gestionnaire de connexions WebSocket actives
active_connections: Dict[str, WebSocket] = {}

@app.get("/")
async def root():
    """Endpoint racine avec informations du service"""
    return {
        "service": "Service d'Évaluation Hybride VOSK + Whisper",
        "version": "1.0.0",
        "architecture": "Temps réel (VOSK) + Analyse finale (Whisper Large-v3-Turbo)",
        "whisper_integration": "Service Docker existant (port 8001)",
        "endpoints": {
            "realtime": "/ws/realtime/{session_id}",
            "analysis": "/analyze",
            "health": "/health"
        },
        "status": "ready"
    }

@app.get("/health")
async def health():
    """Health check endpoint avec vérification des services"""
    health_status = {
        "status": "healthy",
        "services": {},
        "connections": {
            "active_websockets": len(active_connections)
        }
    }
    
    try:
        # Vérification VOSK
        if hasattr(app.state, 'vosk_service'):
            vosk_status = await app.state.vosk_service.health_check()
            health_status["services"]["vosk"] = vosk_status
        else:
            health_status["services"]["vosk"] = {"status": "not_initialized"}
            
        # Vérification Whisper (service existant)
        if hasattr(app.state, 'whisper_client'):
            whisper_status = await app.state.whisper_client.health_check()
            health_status["services"]["whisper"] = whisper_status
        else:
            health_status["services"]["whisper"] = {"status": "not_initialized"}
            
        # Vérification orchestrateur
        if hasattr(app.state, 'orchestrator'):
            health_status["services"]["orchestrator"] = {"status": "ready"}
        else:
            health_status["services"]["orchestrator"] = {"status": "not_initialized"}
            
        # Déterminer le statut global
        all_services_ready = all(
            service.get("status") == "ready" 
            for service in health_status["services"].values()
        )
        
        if not all_services_ready:
            health_status["status"] = "degraded"
            return JSONResponse(content=health_status, status_code=503)
            
    except Exception as e:
        logger.error(f"Erreur lors du health check: {e}")
        health_status["status"] = "error"
        health_status["error"] = str(e)
        return JSONResponse(content=health_status, status_code=503)
    
    return health_status

@app.websocket("/ws/realtime/{session_id}")
async def websocket_realtime_analysis(websocket: WebSocket, session_id: str):
    """
    WebSocket pour analyse temps réel avec VOSK
    Fournit un feedback immédiat pendant l'enregistrement
    """
    await websocket.accept()
    active_connections[session_id] = websocket
    
    logger.info(f"📡 Nouvelle connexion WebSocket pour session: {session_id}")
    
    try:
        # Initialiser la session VOSK pour cette connexion
        session_data = await app.state.vosk_service.create_session(session_id)
        
        await websocket.send_json({
            "type": "session_initialized",
            "session_id": session_id,
            "vosk_model": session_data["model_info"],
            "status": "ready_for_audio"
        })
        
        while True:
            # Recevoir les données audio du client
            data = await websocket.receive()
            
            if data["type"] == "websocket.receive":
                if "bytes" in data:
                    # Données audio binaires
                    audio_data = data["bytes"]
                    
                    # Traitement temps réel avec VOSK
                    result = await app.state.vosk_service.process_audio_chunk(
                        session_id=session_id,
                        audio_data=audio_data
                    )
                    
                    # Envoyer le feedback temps réel
                    await websocket.send_json({
                        "type": "realtime_result",
                        "session_id": session_id,
                        "partial": result.get("partial", ""),
                        "confidence": result.get("confidence", 0.0),
                        "timestamp": result.get("timestamp"),
                        "prosody_metrics": result.get("prosody_metrics", {})
                    })
                    
                elif "text" in data:
                    # Commandes textuelles
                    message = json.loads(data["text"])
                    
                    if message.get("command") == "finalize_recording":
                        # Finaliser l'enregistrement et obtenir le résultat final
                        final_result = await app.state.vosk_service.finalize_session(session_id)
                        
                        await websocket.send_json({
                            "type": "recording_finalized", 
                            "session_id": session_id,
                            "final_transcript": final_result["transcript"],
                            "total_duration": final_result["duration"],
                            "vosk_metrics": final_result["metrics"]
                        })
                        
                    elif message.get("command") == "start_recording":
                        # Démarrer l'enregistrement
                        await app.state.vosk_service.start_recording(session_id)
                        
                        await websocket.send_json({
                            "type": "recording_started",
                            "session_id": session_id,
                            "status": "listening"
                        })
                        
    except WebSocketDisconnect:
        logger.info(f"📡 Connexion WebSocket fermée pour session: {session_id}")
    except Exception as e:
        logger.error(f"❌ Erreur WebSocket pour session {session_id}: {e}")
        await websocket.send_json({
            "type": "error",
            "session_id": session_id,
            "error": str(e)
        })
    finally:
        # Nettoyage de la session
        if session_id in active_connections:
            del active_connections[session_id]
        
        if hasattr(app.state, 'vosk_service'):
            await app.state.vosk_service.cleanup_session(session_id)

@app.post("/analyze")
async def analyze_complete_recording(audio_file: UploadFile = File(...)):
    """
    Endpoint pour analyse complète d'un enregistrement avec Whisper Large-v3-Turbo
    Utilise le service Docker existant pour une transcription de haute précision
    """
    try:
        logger.info(f"📁 Nouvelle demande d'analyse complète: {audio_file.filename}")
        
        # Lire le fichier audio
        audio_content = await audio_file.read()
        
        # Analyse avec Whisper via le service existant
        whisper_result = await app.state.whisper_client.transcribe_audio(
            audio_data=audio_content,
            filename=audio_file.filename
        )
        
        # Analyse prosodique et métriques avancées
        prosody_analysis = await app.state.orchestrator.analyze_prosody(
            audio_data=audio_content,
            whisper_transcript=whisper_result["text"]
        )
        
        # Combiner tous les résultats
        complete_analysis = {
            "analysis_id": str(uuid.uuid4()),
            "filename": audio_file.filename,
            "whisper_transcription": whisper_result,
            "prosody_analysis": prosody_analysis,
            "hybrid_metrics": {
                "confidence_score": prosody_analysis.get("confidence_score", 0.0),
                "speaking_rate_wpm": prosody_analysis.get("wpm", 0),
                "pause_analysis": prosody_analysis.get("pauses", {}),
                "articulation_score": prosody_analysis.get("articulation", 0.0)
            },
            "recommendations": await app.state.orchestrator.generate_recommendations(
                whisper_result, prosody_analysis
            )
        }
        
        logger.info(f"✅ Analyse complète terminée pour: {audio_file.filename}")
        return complete_analysis
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'analyse complète: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse: {str(e)}")

@app.post("/hybrid-session")
async def create_hybrid_session():
    """
    Créer une nouvelle session d'évaluation hybride
    Combine feedback temps réel (VOSK) + analyse finale (Whisper)
    """
    try:
        session_id = str(uuid.uuid4())
        
        # Préparer la session hybride
        session_config = await app.state.orchestrator.create_hybrid_session(session_id)
        
        return {
            "session_id": session_id,
            "websocket_url": f"/ws/realtime/{session_id}",
            "analysis_endpoint": "/analyze",
            "session_config": session_config,
            "status": "ready"
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la création de session hybride: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur de création de session: {str(e)}")

@app.get("/metrics")
async def get_system_metrics():
    """Métriques système du service hybride"""
    try:
        metrics = {
            "active_sessions": len(active_connections),
            "vosk_metrics": await app.state.vosk_service.get_metrics() if hasattr(app.state, 'vosk_service') else {},
            "whisper_metrics": await app.state.whisper_client.get_metrics() if hasattr(app.state, 'whisper_client') else {},
            "system_status": "operational"
        }
        
        return metrics
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la récupération des métriques: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur de métriques: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8002,
        reload=True,
        log_level="info"
    )
