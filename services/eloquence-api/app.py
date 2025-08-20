from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import redis
import json
import uuid
from datetime import datetime
from typing import Dict, List, Optional, Any
import logging
import asyncio
import httpx
import os

# Configuration
LOG_LEVEL = os.getenv("LOG_LEVEL", "DEBUG").upper()
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.DEBUG),
    format='%(asctime)s.%(msecs)03d %(levelname)s [%(name)s] %(filename)s:%(lineno)d - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

app = FastAPI(
    title="Eloquence API",
    description="API unifiée pour tous les exercices vocaux Eloquence",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Redis
redis_client = redis.Redis.from_url("redis://redis:6379/0", decode_responses=True)

# Configuration des services
SERVICES = {
    "vosk": "http://vosk-stt:8002",
    "mistral": "http://mistral:8001",
    "livekit": "ws://livekit:7880",
    "livekit_token": "http://livekit-token-service:8004"
}

# === ENDPOINTS SANTÉ ===

@app.get("/health")
async def health_check():
    """Santé de l'API"""
    return {
        "status": "healthy",
        "service": "eloquence-api",
        "version": "2.0.0",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/diagnostics/logs")
async def diagnostics_logs():
    return {
        "log_level": LOG_LEVEL,
        "time": datetime.now().isoformat(),
        "service": "eloquence-api"
    }

@app.get("/health/services")
async def services_health():
    """Santé de tous les services connectés"""
    health_status = {}
    
    async with httpx.AsyncClient() as client:
        for service, url in SERVICES.items():
            if service == "livekit":
                continue  # Skip WebSocket service for HTTP health check
            try:
                response = await client.get(f"{url}/health", timeout=5.0)
                health_status[service] = {
                    "status": "healthy" if response.status_code == 200 else "unhealthy",
                    "url": url,
                    "response_time": response.elapsed.total_seconds()
                }
            except Exception as e:
                health_status[service] = {
                    "status": "unhealthy",
                    "url": url,
                    "error": str(e)
                }
    
    return {
        "services": health_status,
        "overall_status": "healthy" if all(s["status"] == "healthy" for s in health_status.values()) else "degraded"
    }

# === TEMPLATES D'EXERCICES ===

@app.get("/api/v1/exercises/templates")
async def list_exercise_templates():
    """Liste tous les templates d'exercices"""
    templates = [
        {
            "id": "confidence_boost",
            "title": "Boost de Confiance",
            "description": "Exercice conversationnel pour développer l'assurance",
            "type": "conversation",
            "duration": 600,
            "difficulty": "intermediate",
            "focus_areas": ["confiance", "expression", "spontanéité"],
            "settings": {
                "ai_personality": "encouraging",
                "feedback_frequency": "continuous"
            }
        },
        {
            "id": "tongue_twister",
            "title": "Roulette des Virelangues",
            "description": "Améliorer articulation avec virelangues",
            "type": "articulation", 
            "duration": 180,
            "difficulty": "all",
            "focus_areas": ["articulation", "diction", "vitesse"],
            "settings": {
                "progressive_difficulty": True,
                "repetition_count": 3
            }
        },
        {
            "id": "impromptu_speaking",
            "title": "Prise de Parole Improvisée",
            "description": "Développer spontanéité et structure",
            "type": "speaking",
            "duration": 300,
            "difficulty": "advanced",
            "focus_areas": ["structure", "spontanéité", "persuasion"],
            "settings": {
                "topics": ["startup", "personnel", "produit"],
                "time_limit": 60
            }
        },
        {
            "id": "dragon_breath",
            "title": "Respiration du Dragon",
            "description": "Exercice de respiration pour la relaxation",
            "type": "breathing",
            "duration": 240,
            "difficulty": "beginner",
            "focus_areas": ["respiration", "relaxation", "contrôle"],
            "settings": {
                "breath_pattern": "4-7-8",
                "cycles": 4
            }
        }
    ]
    return {"templates": templates, "total": len(templates)}

@app.get("/api/v1/exercises/templates/{template_id}")
async def get_exercise_template(template_id: str):
    """Détail d'un template d'exercice"""
    templates = await list_exercise_templates()
    template = next((t for t in templates["templates"] if t["id"] == template_id), None)
    
    if not template:
        raise HTTPException(status_code=404, detail="Template non trouvé")
    
    return template

# === SESSIONS D'EXERCICES ===

@app.post("/api/v1/exercises/sessions")
async def create_exercise_session(session_data: Dict[str, Any]):
    """Créer une nouvelle session d'exercice"""
    template_id = session_data.get("template_id")
    user_id = session_data.get("user_id", "anonymous")
    
    if not template_id:
        raise HTTPException(status_code=400, detail="template_id requis")
    
    # Vérifier que le template existe
    try:
        template = await get_exercise_template(template_id)
    except HTTPException:
        raise HTTPException(status_code=400, detail="Template invalide")
    
    session_id = f"session_{uuid.uuid4().hex[:10]}"
    livekit_room = f"exercise_{session_id}"
    
    # Générer token LiveKit via le service dédié
    try:
        token_payload = {
            "room_name": livekit_room,
            "participant_name": user_id,
            "grants": {
                "roomJoin": True,
                "canPublish": True,
                "canSubscribe": True,
                "canPublishData": True,
            },
            "metadata": {
                "exercise_type": template_id,
                "user_id": user_id
            }
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            token_resp = await client.post(f"{SERVICES['livekit_token']}/generate-token", json=token_payload)
            token_resp.raise_for_status()
            livekit_token = token_resp.json().get("token")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Token LiveKit indisponible: {e}")
    
    session = {
        "session_id": session_id,
        "template_id": template_id,
        "user_id": user_id,
        "livekit_room": livekit_room,
        "livekit_token": livekit_token,
        "status": "created",
        "created_at": datetime.now().isoformat(),
        "settings": session_data.get("settings", {}),
        "metrics": {}
    }
    
    # Stocker en Redis
    redis_client.setex(f"session:{session_id}", 3600, json.dumps(session))
    
    return {
        "session_id": session_id,
        "livekit_room": livekit_room,
        "livekit_url": SERVICES["livekit"],
        "token": livekit_token,
        "status": "created",
        "template": template
    }

@app.get("/api/v1/exercises/sessions/{session_id}")
async def get_exercise_session(session_id: str):
    """État d'une session d'exercice"""
    session_data = redis_client.get(f"session:{session_id}")
    
    if not session_data:
        raise HTTPException(status_code=404, detail="Session non trouvée")
    
    return json.loads(session_data)

@app.put("/api/v1/exercises/sessions/{session_id}")
async def update_exercise_session(session_id: str, update_data: Dict[str, Any]):
    """Mettre à jour une session"""
    session_data = redis_client.get(f"session:{session_id}")
    
    if not session_data:
        raise HTTPException(status_code=404, detail="Session non trouvée")
    
    session = json.loads(session_data)
    
    # Mettre à jour les champs autorisés
    allowed_fields = ["status", "metrics", "settings"]
    for field in allowed_fields:
        if field in update_data:
            session[field] = update_data[field]
    
    session["updated_at"] = datetime.now().isoformat()
    
    # Sauvegarder
    redis_client.setex(f"session:{session_id}", 3600, json.dumps(session))
    
    return session

@app.delete("/api/v1/exercises/sessions/{session_id}")
async def end_exercise_session(session_id: str):
    """Terminer une session d'exercice"""
    session_data = redis_client.get(f"session:{session_id}")
    
    if not session_data:
        raise HTTPException(status_code=404, detail="Session non trouvée")
    
    session = json.loads(session_data)
    session["status"] = "completed"
    session["completed_at"] = datetime.now().isoformat()
    
    # Sauvegarder état final
    redis_client.setex(f"session:{session_id}", 86400, json.dumps(session))  # 24h
    
    return {"message": "Session terminée", "session": session}

# === ANALYSE AUDIO ===

@app.post("/api/v1/exercises/audio/analyze")
async def analyze_audio_chunk(audio_data: Dict[str, Any]):
    """Analyse ponctuelle d'un chunk audio"""
    session_id = audio_data.get("session_id")
    audio_base64 = audio_data.get("audio_data")
    
    if not session_id or not audio_base64:
        raise HTTPException(status_code=400, detail="session_id et audio_data requis")
    
    # Récupérer session
    session_data = redis_client.get(f"session:{session_id}")
    if not session_data:
        raise HTTPException(status_code=404, detail="Session non trouvée")
    
    session = json.loads(session_data)
    
    try:
        # Analyser avec Vosk
        async with httpx.AsyncClient() as client:
            vosk_response = await client.post(
                f"{SERVICES['vosk']}/transcribe",
                json={"audio_data": audio_base64},
                timeout=10.0
            )
            
            if vosk_response.status_code != 200:
                raise HTTPException(status_code=500, detail="Erreur analyse Vosk")
            
            vosk_result = vosk_response.json()
            
        # Calculer métriques basiques
        transcription = vosk_result.get("transcription", "")
        confidence = vosk_result.get("confidence", 0.0)
        
        metrics = {
            "transcription": transcription,
            "confidence": confidence,
            "clarity": min(confidence * 100, 100),
            "fluency": len(transcription.split()) * 10,  # Métrique simple
            "timestamp": datetime.now().isoformat()
        }
        
        return {
            "session_id": session_id,
            "metrics": metrics,
            "processing_time": 0.5  # Placeholder
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur analyse: {str(e)}")

# === WEBSOCKET TEMPS RÉEL ===

@app.websocket("/api/v1/exercises/realtime/{session_id}")
async def websocket_realtime_analysis(websocket: WebSocket, session_id: str):
    """WebSocket pour analyse vocale temps réel"""
    await websocket.accept()
    
    # Vérifier session
    session_data = redis_client.get(f"session:{session_id}")
    if not session_data:
        await websocket.send_json({"error": "Session non trouvée"})
        await websocket.close()
        return
    
    session = json.loads(session_data)
    
    # Marquer session comme active
    session["status"] = "active"
    redis_client.setex(f"session:{session_id}", 3600, json.dumps(session))
    
    try:
        await websocket.send_json({
            "type": "session_started",
            "session_id": session_id,
            "template": session["template_id"]
        })
        
        while True:
            # Recevoir données audio
            data = await websocket.receive_json()
            
            if data.get("type") == "audio_chunk":
                # Analyser audio
                try:
                    analysis_result = await analyze_audio_chunk({
                        "session_id": session_id,
                        "audio_data": data.get("audio_data")
                    })
                    
                    # Envoyer résultats
                    await websocket.send_json({
                        "type": "metrics_update",
                        "session_id": session_id,
                        "metrics": analysis_result["metrics"]
                    })
                    
                except Exception as e:
                    await websocket.send_json({
                        "type": "error",
                        "message": f"Erreur analyse: {str(e)}"
                    })
            
            elif data.get("type") == "end_session":
                break
                
    except WebSocketDisconnect:
        pass
    finally:
        # Marquer session comme terminée
        session["status"] = "completed"
        session["completed_at"] = datetime.now().isoformat()
        redis_client.setex(f"session:{session_id}", 86400, json.dumps(session))

# === ANALYTICS ===

@app.get("/api/v1/exercises/analytics/user/{user_id}")
async def get_user_analytics(user_id: str):
    """Historique et statistiques utilisateur"""
    # Rechercher toutes les sessions de l'utilisateur
    sessions = []
    for key in redis_client.scan_iter(match="session:*"):
        session_data = redis_client.get(key)
        if session_data:
            session = json.loads(session_data)
            if session.get("user_id") == user_id:
                sessions.append(session)
    
    # Calculer statistiques
    total_sessions = len(sessions)
    completed_sessions = len([s for s in sessions if s.get("status") == "completed"])
    
    exercise_types = {}
    for session in sessions:
        template_id = session.get("template_id", "unknown")
        exercise_types[template_id] = exercise_types.get(template_id, 0) + 1
    
    return {
        "user_id": user_id,
        "total_sessions": total_sessions,
        "completed_sessions": completed_sessions,
        "completion_rate": (completed_sessions / total_sessions * 100) if total_sessions > 0 else 0,
        "exercise_types": exercise_types,
        "recent_sessions": sorted(sessions, key=lambda x: x.get("created_at", ""), reverse=True)[:5]
    }

@app.get("/api/v1/exercises/analytics/global")
async def get_global_analytics():
    """Statistiques globales de l'application"""
    all_sessions = []
    for key in redis_client.scan_iter(match="session:*"):
        session_data = redis_client.get(key)
        if session_data:
            all_sessions.append(json.loads(session_data))
    
    total_sessions = len(all_sessions)
    active_sessions = len([s for s in all_sessions if s.get("status") == "active"])
    
    return {
        "total_sessions": total_sessions,
        "active_sessions": active_sessions,
        "total_users": len(set(s.get("user_id") for s in all_sessions if s.get("user_id"))),
        "popular_exercises": {},  # À implémenter
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
