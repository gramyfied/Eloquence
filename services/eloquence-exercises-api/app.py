from fastapi import FastAPI, HTTPException, Depends, File, UploadFile, Form, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import redis
import json
import os
from typing import Dict, List, Any, Optional
import httpx
import logging
import os
import uuid
from datetime import datetime
import asyncio
import base64
import numpy as np
import io

from models.exercise_models import (
    ExerciseTemplate, ExerciseConfig, SessionConfig, SessionData,
    ExerciseEvaluation, LiveKitSessionInfo, ExerciseResponse, SessionResponse,
    RealTimeMessageType, RealTimeAudioChunk, RealTimeSessionStart,
    RealTimePartialResult, RealTimeMetricsUpdate, RealTimeFinalResult, RealTimeError
)

# Configuration des logs
LOG_LEVEL = os.getenv("LOG_LEVEL", "DEBUG").upper()
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.DEBUG),
    format='%(asctime)s.%(msecs)03d %(levelname)s [%(name)s] %(filename)s:%(lineno)d - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def safe_get(obj, key, default=None, context="unknown"):
    """
    Wrapper sécurisé pour .get() qui gère les cas où obj n'est pas un dict
    """
    try:
        if isinstance(obj, dict):
            return obj.get(key, default)
        else:
            logger.error(f"❌ SAFE_GET ERROR [{context}]: Tentative .get() sur {type(obj)}")
            logger.error(f"❌ SAFE_GET ERROR [{context}]: Contenu = {obj}")
            logger.error(f"❌ SAFE_GET ERROR [{context}]: Key demandée = '{key}'")
            return default
    except Exception as e:
        logger.error(f"❌ SAFE_GET EXCEPTION [{context}]: {e}")
        return default

app = FastAPI(
    title="Eloquence Exercises API",
    description="API légère pour la gestion des exercices vocaux avec LiveKit",
    version="1.0.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Connexion Redis
redis_client = redis.Redis.from_url(
    os.getenv("REDIS_URL", "redis://redis:6379/0"),
    decode_responses=True
)

# Configuration LiveKit
LIVEKIT_URL = os.getenv("LIVEKIT_URL", "ws://livekit:7880")
TOKEN_SERVICE_URL = os.getenv("TOKEN_SERVICE_URL", "http://livekit-token-service:8004")

# Configuration du service Vosk
VOSK_SERVICE_URL = os.getenv("VOSK_SERVICE_URL", "http://vosk-stt-analysis:8095")

# Configuration du service Mistral
MISTRAL_SERVICE_URL = os.getenv("MISTRAL_SERVICE_URL", "http://mistral-conversation:8001")

# Configuration HTTPX optimisée selon la documentation
httpx_timeout = httpx.Timeout(
    connect=10.0,  # Timeout de connexion
    read=60.0,     # Timeout de lecture
    write=30.0,    # Timeout d'écriture
    pool=5.0       # Timeout pour obtenir une connexion du pool
)

httpx_limits = httpx.Limits(
    max_keepalive_connections=5,
    max_connections=10,
    keepalive_expiry=5.0
)

httpx_transport = httpx.HTTPTransport(
    retries=2,  # Retry automatique en cas d'échec
    limits=httpx_limits
)

# Transport asynchrone (pour AsyncClient)
httpx_async_transport = httpx.AsyncHTTPTransport(
    retries=2,  # Retry automatique en cas d'échec
    limits=httpx_limits
)

# Préfixes Redis
EXERCISE_PREFIX = "eloquence:exercise:"
SESSION_PREFIX = "eloquence:session:"
TEMPLATE_PREFIX = "eloquence:template:"
REALTIME_SESSION_PREFIX = "eloquence:realtime:"

# Gestionnaire des connexions WebSocket actives
active_websocket_connections: Dict[str, WebSocket] = {}
realtime_sessions: Dict[str, Dict] = {}

# Templates d'exercices prédéfinis
PREDEFINED_TEMPLATES = [
    {
        "template_id": "power_posing",
        "title": "Power Posing Boost",
        "description": "Améliorez votre confiance avec des postures de pouvoir",
        "exercise_type": "posture",
        "default_duration_seconds": 180,
        "difficulty": "beginner",
        "focus_areas": ["confidence", "body_language"],
        "custom_settings": {
            "postures": ["wonder_woman", "victory_v", "ceo_lean"],
            "coaching_intensity": "high"
        }
    },
    {
        "template_id": "impromptu_speaking",
        "title": "Impromptu Speaking Master",
        "description": "Développez votre capacité à parler sans préparation",
        "exercise_type": "speaking",
        "default_duration_seconds": 300,
        "difficulty": "intermediate",
        "focus_areas": ["spontaneity", "structure", "creativity"],
        "custom_settings": {
            "topic_categories": ["objects", "concepts", "situations"],
            "prep_time_seconds": 30
        }
    },
    {
        "template_id": "tongue_twister",
        "title": "Tongue Twister Speedrun",
        "description": "Améliorez votre articulation et diction",
        "exercise_type": "articulation",
        "default_duration_seconds": 180,
        "difficulty": "all",
        "focus_areas": ["articulation", "speed", "precision"],
        "custom_settings": {
            "categories": ["sifflants", "durs", "liquides", "nasales"],
            "progressive_speed": True
        }
    },
    {
        "template_id": "confidence_conversation",
        "title": "Conversation Confiance",
        "description": "Exercice conversationnel pour développer l'assurance",
        "exercise_type": "conversation",
        "default_duration_seconds": 600,
        "difficulty": "intermediate",
        "focus_areas": ["confidence", "conversation", "spontaneity"],
        "custom_settings": {
            "scenarios": ["meeting", "presentation", "social"],
            "ai_coach_personality": "encouraging"
        }
    }
]

async def get_redis_client():
    """Dépendance pour obtenir le client Redis"""
    return redis_client

@app.on_event("startup")
async def startup_event():
    """Initialisation de l'application"""
    try:
        # Tester la connexion Redis
        redis_client.ping()
        logger.info("✅ Connexion Redis établie")
        
        # Initialiser les templates prédéfinis
        for template in PREDEFINED_TEMPLATES:
            redis_client.set(
                f"{TEMPLATE_PREFIX}{template['template_id']}",
                json.dumps(template)
            )
        logger.info(f"✅ {len(PREDEFINED_TEMPLATES)} templates initialisés")
        
    except Exception as e:
        logger.error(f"❌ Erreur initialisation: {str(e)}")

@app.get("/health")
async def health_check():
    """Vérification de santé de l'API"""
    try:
        # Tester Redis
        redis_client.ping()
        
        return {
            "status": "healthy",
            "service": "eloquence-exercises-api",
            "redis": "connected",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

@app.get("/diagnostics/logs")
async def diagnostics_logs():
    return {
        "log_level": LOG_LEVEL,
        "time": datetime.now().isoformat(),
        "service": "eloquence-exercises-api"
    }

@app.post("/api/exercises", response_model=ExerciseResponse)
async def create_exercise(exercise: Dict[str, Any]):
    """Crée un nouvel exercice"""
    try:
        exercise_id = exercise.get("exercise_id", f"ex_{uuid.uuid4().hex[:8]}")
        exercise["exercise_id"] = exercise_id
        exercise["created_at"] = datetime.now().isoformat()
        
        # Valider les données avec Pydantic
        exercise_config = ExerciseConfig(**exercise)
        
        # Stocker dans Redis
        redis_client.set(
            f"{EXERCISE_PREFIX}{exercise_id}",
            exercise_config.model_dump_json()
        )
        
        logger.info(f"✅ Exercice créé: {exercise_id}")
        
        return ExerciseResponse(
            exercise_id=exercise_id,
            title=exercise["title"],
            status="created"
        )
        
    except Exception as e:
        logger.error(f"❌ Erreur création exercice: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Erreur création exercice: {str(e)}")

@app.get("/api/exercises")
async def list_exercises():
    """Liste tous les exercices disponibles"""
    try:
        exercise_keys = redis_client.keys(f"{EXERCISE_PREFIX}*")
        exercises = []
        
        for key in exercise_keys:
            exercise_data = redis_client.get(key)
            if exercise_data:
                exercises.append(json.loads(exercise_data))
        
        logger.info(f"📋 {len(exercises)} exercices listés")
        return {"exercises": exercises, "total": len(exercises)}
        
    except Exception as e:
        logger.error(f"❌ Erreur listing exercices: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération exercices: {str(e)}")

@app.get("/api/exercises/{exercise_id}")
async def get_exercise(exercise_id: str):
    """Récupère un exercice spécifique"""
    try:
        exercise_data = redis_client.get(f"{EXERCISE_PREFIX}{exercise_id}")
        
        if not exercise_data:
            raise HTTPException(status_code=404, detail="Exercice non trouvé")
        
        exercise = json.loads(exercise_data)
        logger.info(f"📖 Exercice récupéré: {exercise_id}")
        
        return exercise
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération exercice {exercise_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération exercice: {str(e)}")

@app.post("/api/sessions/create", response_model=SessionResponse)
async def create_session(session_config: Dict[str, Any]):
    """Crée une nouvelle session d'exercice avec LiveKit"""
    try:
        exercise_id = session_config.get("exercise_id")
        if not exercise_id:
            raise HTTPException(status_code=400, detail="ID d'exercice requis")
        
        # Récupérer l'exercice
        exercise_data = redis_client.get(f"{EXERCISE_PREFIX}{exercise_id}")
        if not exercise_data:
            raise HTTPException(status_code=404, detail="Exercice non trouvé")
        
        exercise = json.loads(exercise_data)
        
        # Générer ID session
        session_id = session_config.get("session_id", f"session_{uuid.uuid4().hex[:10]}")
        
        # Créer room LiveKit
        livekit_room = f"{exercise.get('livekit_room_prefix', 'exercise_')}{session_id}"
        
        # Préparer les métadonnées
        metadata = {
            "session_id": session_id,
            "exercise_id": exercise_id,
            "exercise_type": exercise["exercise_type"],
            "language": session_config.get("language", "fr")
        }
        
        # Générer token LiveKit (même structure que confidence boost qui fonctionne)
        token_url = f"{TOKEN_SERVICE_URL}/generate-token"
        participant_name = session_config.get("participant_name", f"user_{session_id}")
        room_name = session_config.get("room_name", livekit_room)
        
        # Structure exacte utilisée par confidence boost
        token_request = {
            "participant_name": participant_name,
            "room_name": room_name,
            "grants": {
                "roomJoin": True,
                "canPublish": True,
                "canSubscribe": True,
                "canPublishData": True,
            },
            "metadata": metadata  # Objet direct, pas string JSON
        }
        
        logger.info(f"🔍 Token request: {token_request}")
        
        async with httpx.AsyncClient(
            timeout=httpx_timeout,
            transport=httpx_async_transport
        ) as client:
            token_response = await client.post(
                token_url,
                json=token_request
            )
            
            if token_response.status_code != 200:
                raise HTTPException(
                    status_code=500,
                    detail=f"Erreur génération token: {token_response.text}"
                )
            
            token_data = token_response.json()
            token = token_data.get("token")
            
            if not token:
                raise HTTPException(
                    status_code=500,
                    detail="Token LiveKit non reçu"
                )
        
        # Stocker la session
        session_data = SessionData(
            session_id=session_id,
            exercise_id=exercise_id,
            livekit_room=livekit_room,
            status="created",
            config=session_config
        )
        
        redis_client.set(
            f"{SESSION_PREFIX}{session_id}",
            session_data.model_dump_json()
        )
        
        logger.info(f"🎯 Session créée: {session_id} pour exercice {exercise_id}")
        
        return SessionResponse(
            session_id=session_id,
            exercise_id=exercise_id,
            livekit_room=livekit_room,
            livekit_url=LIVEKIT_URL,
            token=token,
            status="created",
            metadata=metadata
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur création session: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur création session: {str(e)}"
        )

@app.get("/api/sessions/{session_id}")
async def get_session(session_id: str):
    """Récupère une session d'exercice"""
    try:
        session_data = redis_client.get(f"{SESSION_PREFIX}{session_id}")
        
        if not session_data:
            raise HTTPException(status_code=404, detail="Session non trouvée")
        
        session = json.loads(session_data)
        logger.info(f"📖 Session récupérée: {session_id}")
        
        return session
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération session {session_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération session: {str(e)}")

@app.post("/api/sessions/{session_id}/complete")
async def complete_session(session_id: str, evaluation: Dict[str, Any]):
    """Termine une session d'exercice et enregistre l'évaluation"""
    try:
        session_data = redis_client.get(f"{SESSION_PREFIX}{session_id}")
        
        if not session_data:
            raise HTTPException(status_code=404, detail="Session non trouvée")
        
        session = json.loads(session_data)
        
        # Valider l'évaluation
        try:
            exercise_eval = ExerciseEvaluation(session_id=session_id, **evaluation)
        except Exception as e:
            logger.warning(f"⚠️  Évaluation invalide, utilisation des données brutes: {str(e)}")
            exercise_eval = evaluation
        
        # Mettre à jour le statut
        session["status"] = "completed"
        session["completed_at"] = datetime.now().isoformat()
        session["evaluation"] = exercise_eval.dict() if hasattr(exercise_eval, 'dict') else exercise_eval
        
        # Enregistrer les modifications
        redis_client.set(
            f"{SESSION_PREFIX}{session_id}",
            json.dumps(session)
        )
        
        logger.info(f"✅ Session terminée: {session_id}")
        
        return {
            "session_id": session_id,
            "status": "completed",
            "evaluation": session["evaluation"],
            "completed_at": session["completed_at"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur complétion session {session_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur complétion session: {str(e)}")

@app.get("/api/exercise-templates")
async def get_exercise_templates():
    """Récupère les templates d'exercices prédéfinis"""
    try:
        template_keys = redis_client.keys(f"{TEMPLATE_PREFIX}*")
        templates = []
        
        for key in template_keys:
            template_data = redis_client.get(key)
            if template_data:
                templates.append(json.loads(template_data))
        
        # Si aucun template en base, retourner les templates prédéfinis
        if not templates:
            templates = PREDEFINED_TEMPLATES
        
        logger.info(f"📋 {len(templates)} templates listés")
        return {"templates": templates, "total": len(templates)}
        
    except Exception as e:
        logger.error(f"❌ Erreur récupération templates: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération templates: {str(e)}")

@app.post("/api/exercise-templates")
async def create_exercise_template(template: Dict[str, Any]):
    """Crée un nouveau template d'exercice"""
    try:
        template_id = template.get("template_id", f"tpl_{uuid.uuid4().hex[:8]}")
        template["template_id"] = template_id
        
        # Valider avec Pydantic
        exercise_template = ExerciseTemplate(**template)
        
        # Stocker dans Redis
        redis_client.set(
            f"{TEMPLATE_PREFIX}{template_id}",
            exercise_template.model_dump_json()
        )
        
        logger.info(f"✅ Template créé: {template_id}")
        
        return {
            "template_id": template_id,
            "title": template["title"],
            "status": "created"
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur création template: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Erreur création template: {str(e)}")

@app.delete("/api/sessions/{session_id}")
async def delete_session(session_id: str):
    """Supprime une session d'exercice"""
    try:
        if redis_client.delete(f"{SESSION_PREFIX}{session_id}"):
            logger.info(f"🗑️ Session supprimée: {session_id}")
            return {"status": "deleted", "session_id": session_id}
        else:
            raise HTTPException(status_code=404, detail="Session non trouvée")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur suppression session {session_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur suppression session: {str(e)}")

@app.post("/api/voice-analysis")
async def analyze_voice(
    audio: UploadFile = File(...),
    session_id: Optional[str] = Form(None),
    exercise_type: Optional[str] = Form("general"),
    user_id: Optional[str] = Form("anonymous")
):
    """
    Endpoint d'analyse vocale qui utilise le service Vosk pour l'analyse audio
    """
    logger.info("🎯 Requête reçue sur /api/voice-analysis - utilisation de Vosk")
    
    try:
        # Générer un session_id si non fourni
        if not session_id:
            session_id = f"analysis_{uuid.uuid4().hex[:8]}"
        
        # Préparer les données pour l'envoi vers Vosk
        audio_content = await audio.read()
        
        # Créer les données multipart pour Vosk
        files = {"audio": (audio.filename, audio_content, audio.content_type)}
        data = {
            "scenario_type": exercise_type,
            "scenario_context": f"Analyse pour utilisateur {user_id}"
        }
        
        # Appeler le service Vosk
        async with httpx.AsyncClient(
            timeout=httpx_timeout,
            transport=httpx_async_transport
        ) as client:
            try:
                vosk_response = await client.post(
                    f"{VOSK_SERVICE_URL}/analyze",
                    files=files,
                    data=data
                )
            except httpx.ConnectError as e:
                logger.error(f"❌ Erreur de connexion vers Vosk ({VOSK_SERVICE_URL}): {e}")
                raise HTTPException(
                    status_code=503,
                    detail=f"Service Vosk non disponible: {str(e)}"
                )
            except httpx.TimeoutException as e:
                logger.error(f"❌ Timeout connexion Vosk: {e}")
                raise HTTPException(
                    status_code=504,
                    detail=f"Timeout service Vosk: {str(e)}"
                )
            except httpx.RequestError as e:
                logger.error(f"❌ Erreur requête Vosk: {e}")
                raise HTTPException(
                    status_code=502,
                    detail=f"Erreur communication Vosk: {str(e)}"
                )
            
            if vosk_response.status_code != 200:
                raise HTTPException(
                    status_code=500,
                    detail=f"Erreur service Vosk: {vosk_response.text}"
                )
            
            vosk_result = vosk_response.json()
        
        # Construire la réponse d'analyse
        analysis_result = {
            "session_id": session_id,
            "timestamp": datetime.now().isoformat(),
            "transcription": vosk_result.get("transcription", ""),
            "confidence_score": vosk_result.get("confidence_score", 0.0),
            "metrics": {
                "clarity": vosk_result.get("clarity_score", 0.0),
                "fluency": vosk_result.get("fluency_score", 0.0),
                "confidence": vosk_result.get("confidence_score", 0.0),
                "energy": vosk_result.get("energy_score", 0.0),
                "overall": vosk_result.get("overall_score", 0.0)
            },
            "prosody": vosk_result.get("prosody", {}),
            "feedback": vosk_result.get("feedback", ""),
            "strengths": vosk_result.get("strengths", []),
            "improvements": vosk_result.get("improvements", []),
            "exercise_type": exercise_type,
            "user_id": user_id,
            "processing_time": vosk_result.get("processing_time", 0.0)
        }
        
        # Sauvegarder le résultat dans Redis
        if session_id and redis_client:
            analysis_key = f"eloquence:voice_analysis:{session_id}"
            redis_client.set(analysis_key, json.dumps(analysis_result))
            redis_client.expire(analysis_key, 86400)  # Expire après 24h
        
        logger.info(f"✅ Analyse vocale réussie pour session {session_id}")
        return analysis_result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'analyse vocale: {e}")
        raise HTTPException(
            status_code=500,
            content=f"Erreur d'analyse: {str(e)}"
        )

@app.post("/api/voice-analysis/detailed")
async def analyze_voice_detailed(
    audio: UploadFile = File(...),
    session_id: Optional[str] = Form(None),
    exercise_type: Optional[str] = Form("general"),
    user_id: Optional[str] = Form("anonymous")
):
    """
    Endpoint d'analyse vocale avancée avec métriques détaillées et feedback personnalisé
    """
    logger.info("🎯 Requête reçue sur /api/voice-analysis/detailed")
    
    try:
        # Générer un session_id si non fourni
        if not session_id:
            session_id = f"detailed_analysis_{uuid.uuid4().hex[:8]}"
        
        # Préparer les données pour l'envoi vers Vosk
        audio_content = await audio.read()
        
        # Créer les données multipart pour Vosk
        files = {"audio": (audio.filename, audio_content, audio.content_type)}
        data = {
            "scenario_type": exercise_type,
            "scenario_context": f"Analyse détaillée pour utilisateur {user_id}"
        }
        
        # Appeler le service Vosk pour l'analyse complète
        async with httpx.AsyncClient(
            timeout=httpx_timeout,
            transport=httpx_async_transport
        ) as client:
            try:
                vosk_response = await client.post(
                    f"{VOSK_SERVICE_URL}/analyze",
                    files=files,
                    data=data
                )
            except httpx.ConnectError as e:
                logger.error(f"❌ Erreur de connexion vers Vosk (détaillée): {e}")
                raise HTTPException(
                    status_code=503,
                    detail=f"Service Vosk non disponible: {str(e)}"
                )
            except httpx.TimeoutException as e:
                logger.error(f"❌ Timeout connexion Vosk (détaillée): {e}")
                raise HTTPException(
                    status_code=504,
                    detail=f"Timeout service Vosk: {str(e)}"
                )
            except httpx.RequestError as e:
                logger.error(f"❌ Erreur requête Vosk (détaillée): {e}")
                raise HTTPException(
                    status_code=502,
                    detail=f"Erreur communication Vosk: {str(e)}"
                )
            
            if vosk_response.status_code != 200:
                raise HTTPException(
                    status_code=500,
                    detail=f"Erreur service Vosk: {vosk_response.text}"
                )
            
            vosk_result = vosk_response.json()
        
        # Générer feedback détaillé par métrique
        detailed_feedback = await _generate_detailed_feedback(vosk_result, exercise_type)
        
        # Construire la réponse d'analyse détaillée
        analysis_result = {
            "session_id": session_id,
            "timestamp": datetime.now().isoformat(),
            "transcription": vosk_result.get("transcription", ""),
            "confidence_score": vosk_result.get("confidence_score", 0.0),
            "metrics": {
                "clarity": vosk_result.get("clarity_score", 0.0),
                "fluency": vosk_result.get("fluency_score", 0.0),
                "confidence": vosk_result.get("confidence_score", 0.0),
                "energy": vosk_result.get("energy_score", 0.0),
                "overall": vosk_result.get("overall_score", 0.0),
                "vocabulary_richness": _calculate_vocabulary_richness(vosk_result),
                "hesitation_rate": _calculate_hesitation_rate(vosk_result),
                "articulation_score": vosk_result.get("confidence_score", 0.0)
            },
            "prosody": vosk_result.get("prosody", {}),
            "word_analysis": vosk_result.get("words", []),
            "feedback": vosk_result.get("feedback", ""),
            "detailed_feedback": detailed_feedback,
            "strengths": vosk_result.get("strengths", []),
            "improvements": vosk_result.get("improvements", []),
            "exercise_type": exercise_type,
            "user_id": user_id,
            "processing_time": vosk_result.get("processing_time", 0.0)
        }
        
        # Sauvegarder le résultat dans Redis
        if session_id and redis_client:
            analysis_key = f"eloquence:voice_analysis_detailed:{session_id}"
            redis_client.set(analysis_key, json.dumps(analysis_result))
            redis_client.expire(analysis_key, 86400)  # Expire après 24h
        
        logger.info(f"✅ Analyse vocale détaillée réussie pour session {session_id}")
        return analysis_result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'analyse vocale détaillée: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur d'analyse: {str(e)}"
        )

async def _generate_detailed_feedback(vosk_result: Dict[str, Any], exercise_type: str) -> Dict[str, str]:
    """Génère un feedback détaillé pour chaque métrique"""
    
    feedback = {}
    
    # Feedback sur la clarté
    clarity = vosk_result.get("clarity_score", 0.0)
    if clarity < 0.5:
        feedback["clarity"] = "Votre articulation pourrait être améliorée. Essayez de prononcer chaque mot plus distinctement."
    elif clarity < 0.7:
        feedback["clarity"] = "Votre articulation est correcte. Continuez à travailler sur la prononciation des mots difficiles."
    else:
        feedback["clarity"] = "Excellente articulation ! Votre discours est clair et bien prononcé."
    
    # Feedback sur la fluidité
    fluency = vosk_result.get("fluency_score", 0.0)
    if fluency < 0.5:
        feedback["fluency"] = "Votre discours contient des pauses fréquentes. Essayez de pratiquer pour un flux plus continu."
    elif fluency < 0.7:
        feedback["fluency"] = "Votre fluidité est correcte. Quelques pauses occasionnelles, mais le discours reste agréable."
    else:
        feedback["fluency"] = "Excellente fluidité ! Votre discours s'écoule naturellement."
    
    # Feedback sur le rythme
    energy = vosk_result.get("energy_score", 0.0)
    if energy < 0.5:
        feedback["energy"] = "Votre énergie vocale pourrait être augmentée. Essayez de varier davantage votre intonation."
    elif energy < 0.7:
        feedback["energy"] = "Votre niveau d'énergie est correct. Continuez à travailler sur l'expressivité."
    else:
        feedback["energy"] = "Excellente énergie vocale ! Votre intonation est variée et engageante."
    
    # Feedback spécifique au type d'exercice
    if exercise_type == "conversation":
        feedback["exercise_specific"] = "Pour les exercices conversationnels, maintenez un ton naturel et réactif."
    elif exercise_type == "presentation":
        feedback["exercise_specific"] = "Pour les présentations, portez attention à la projection de votre voix."
    elif exercise_type == "articulation":
        feedback["exercise_specific"] = "Pour les exercices d'articulation, concentrez-vous sur la précision de chaque syllabe."
    
    return feedback

def _calculate_vocabulary_richness(vosk_result: Dict[str, Any]) -> float:
    """Calcule la richesse du vocabulaire"""
    words = vosk_result.get("words", [])
    
    if not words:
        return 0.5
    
    # Extraire les mots uniques
    unique_words = set()
    total_words = 0
    
    for word_info in words:
        if isinstance(word_info, dict) and "word" in word_info:
            word = word_info["word"].lower().strip()
            if word and len(word) > 2:  # Ignorer les mots trop courts
                unique_words.add(word)
                total_words += 1
    
    if total_words == 0:
        return 0.5
    
    # Calculer le ratio de mots uniques
    richness = len(unique_words) / total_words
    return min(1.0, richness * 1.2)  # Normaliser le score

def _calculate_hesitation_rate(vosk_result: Dict[str, Any]) -> float:
    """Calcule le taux d'hésitation basé sur les pauses"""
    prosody = vosk_result.get("prosody", {})
    pause_ratio = prosody.get("pause_ratio", 0.0)
    
    # Le taux d'hésitation est basé sur le ratio de pauses
    # Plus de 30% de pauses est considéré comme beaucoup d'hésitations
    hesitation_rate = min(1.0, pause_ratio / 0.3)
    return hesitation_rate

@app.post("/analyze-virelangue")
async def analyze_virelangue_pronunciation(
    audio: UploadFile = File(...),
    target_text: str = Form(...),
    target_sounds: str = Form(...),
    session_id: Optional[str] = Form(None),
    analysis_focus: str = Form("pronunciation_accuracy"),
    enable_phoneme_analysis: str = Form("true"),
    enable_fluency_metrics: str = Form("true")
):
    """
    Endpoint spécialisé pour l'analyse de virelangues avec évaluation de prononciation
    """
    logger.info(f"🎭 Analyse virelangue reçue - texte cible: {target_text}")
    logger.info("🔍 DEBUG-VERY-EARLY: Fonction analyze_virelangue démarrée")
    
    try:
        logger.info("🔍 DEBUG-VERY-EARLY: Entrée dans le bloc try principal")
        # Générer un session_id si non fourni
        if not session_id:
            session_id = f"virelangue_{uuid.uuid4().hex[:8]}"
        
        # Parser les sons ciblés (envoyés en JSON string)
        try:
            target_sounds_list = json.loads(target_sounds) if isinstance(target_sounds, str) else target_sounds
        except json.JSONDecodeError:
            target_sounds_list = [target_sounds] if target_sounds else []
        
        logger.info(f"🔊 Sons ciblés: {target_sounds_list}")
        
        # Préparer les données pour l'envoi vers Vosk
        audio_content = await audio.read()
        
        # Créer les données multipart pour Vosk
        files = {"audio": (audio.filename, audio_content, audio.content_type)}
        data = {
            "scenario_type": "virelangue",
            "scenario_context": f"Analyse virelangue: {target_text}"
        }
        
        # Appeler le service Vosk
        async with httpx.AsyncClient(
            timeout=httpx_timeout,
            transport=httpx_async_transport
        ) as client:
            try:
                logger.info(f"🔗 Tentative connexion vers Vosk: {VOSK_SERVICE_URL}/analyze")
                vosk_response = await client.post(
                    f"{VOSK_SERVICE_URL}/analyze",
                    files=files,
                    data=data
                )
                logger.info(f"✅ Connexion Vosk réussie, status: {vosk_response.status_code}")
                
                # 🔍 DIAGNOSTIC IMMÉDIAT: Identifier exactement où et pourquoi vosk_result devient une string
                logger.info(f"🔍 DIAGNOSTIC IMMÉDIAT: vosk_response.status_code = {vosk_response.status_code}")
                logger.info(f"🔍 DIAGNOSTIC IMMÉDIAT: vosk_response.headers = {dict(vosk_response.headers)}")
                logger.info(f"🔍 DIAGNOSTIC IMMÉDIAT: vosk_response.text[:200] = '{vosk_response.text[:200]}'")
                logger.info(f"🔍 DIAGNOSTIC IMMÉDIAT: vosk_response.text type = {type(vosk_response.text)}")
                logger.info(f"🔍 DIAGNOSTIC IMMÉDIAT: vosk_response.text length = {len(vosk_response.text)}")
                
                # AVANT le parsing JSON
                logger.info("🔍 DIAGNOSTIC: About to parse JSON")
                
            except httpx.ConnectError as e:
                logger.error(f"❌ Erreur de connexion vers Vosk (virelangue): {e}")
                raise HTTPException(
                    status_code=503,
                    detail=f"Service Vosk non disponible: {str(e)}"
                )
            except httpx.TimeoutException as e:
                logger.error(f"❌ Timeout connexion Vosk (virelangue): {e}")
                raise HTTPException(
                    status_code=504,
                    detail=f"Timeout service Vosk: {str(e)}"
                )
            except httpx.RequestError as e:
                logger.error(f"❌ Erreur requête Vosk (virelangue): {e}")
                raise HTTPException(
                    status_code=502,
                    detail=f"Erreur communication Vosk: {str(e)}"
                )
            
            # ✅ VÉRIFICATION STATUS CODE (sans duplication)
            logger.info("🔍 ULTRA-DEBUG LINE 4: About to check status code")
            if vosk_response.status_code != 200:
                logger.error(f"❌ Vosk erreur HTTP {vosk_response.status_code}: {vosk_response.text}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Erreur service Vosk: {vosk_response.text}"
                )
            
            logger.info("🔍 ULTRA-DEBUG LINE 5: Status code check passed")
            
            # ✅ PARSING JSON ULTRA-SÉCURISÉ
            try:
                logger.info("🔍 PARSING: Début parsing JSON")
                
                # Vérification préalable du contenu
                response_text = vosk_response.text.strip()
                logger.info(f"🔍 PARSING: response_text length = {len(response_text)}")
                logger.info(f"🔍 PARSING: response_text[:100] = '{response_text[:100]}'")
                
                if not response_text:
                    logger.error("❌ ERREUR: Réponse Vosk vide")
                    raise HTTPException(status_code=502, detail="Réponse Vosk vide")
                
                # Vérification que ça commence par { ou [
                if not response_text.startswith(('{', '[')):
                    logger.error(f"❌ ERREUR: Réponse Vosk n'est pas du JSON: '{response_text[:100]}'")
                    raise HTTPException(status_code=502, detail=f"Réponse Vosk invalide: {response_text[:100]}")
                
                # Parsing JSON avec gestion d'erreur détaillée
                vosk_result = vosk_response.json()
                logger.info(f"✅ PARSING RÉUSSI: type = {type(vosk_result)}")
                logger.info(f"✅ PARSING RÉUSSI: content = {vosk_result}")
                
                # VALIDATION CRITIQUE IMMÉDIATE
                if not isinstance(vosk_result, dict):
                    logger.error(f"❌ ERREUR CRITIQUE: vosk_result n'est pas un dict")
                    logger.error(f"❌ Type reçu: {type(vosk_result)}")
                    logger.error(f"❌ Contenu: {vosk_result}")
                    
                    # Tentative de conversion si c'est une string JSON
                    if isinstance(vosk_result, str):
                        logger.info("🔄 TENTATIVE: Conversion string JSON vers dict")
                        try:
                            vosk_result = json.loads(vosk_result)
                            logger.info(f"✅ CONVERSION RÉUSSIE: {type(vosk_result)}")
                        except json.JSONDecodeError as e:
                            logger.error(f"❌ CONVERSION ÉCHOUÉE: {e}")
                            raise HTTPException(status_code=502, detail=f"Vosk string non-JSON: {vosk_result[:100]}")
                    else:
                        raise HTTPException(status_code=502, detail=f"Vosk result type invalide: {type(vosk_result)}")
                
                logger.info("✅ VALIDATION: vosk_result est un dictionnaire valide")
                
            except json.JSONDecodeError as e:
                logger.error(f"❌ ERREUR JSON DECODE: {e}")
                logger.error(f"❌ Contenu problématique: '{vosk_response.text}'")
                raise HTTPException(status_code=502, detail=f"JSON invalide de Vosk: {str(e)}")
                
            except httpx.ResponseNotRead as e:
                logger.error(f"❌ ERREUR HTTPX: {e}")
                raise HTTPException(status_code=502, detail=f"Erreur lecture réponse: {str(e)}")
                
            except Exception as e:
                logger.error(f"❌ ERREUR INATTENDUE PARSING: {e}")
                logger.error(f"❌ Type erreur: {type(e)}")
                import traceback
                logger.error(f"❌ Traceback: {traceback.format_exc()}")
                raise HTTPException(status_code=500, detail=f"Erreur parsing Vosk: {str(e)}")
        
        # ✅ Debugging granulaire pour identifier l'erreur exacte
        logger.info(f"🔍 STEP 1: About to access vosk_result")
        logger.info(f"🔍 DEBUG: vosk_result type = {type(vosk_result)}")
        logger.info(f"🔍 DEBUG: vosk_result content = {vosk_result}")
        
        # ✅ VALIDATION CRITIQUE: Vérifier que vosk_result est un dictionnaire
        if not isinstance(vosk_result, dict):
            logger.error(f"❌ ERREUR CRITIQUE: vosk_result n'est pas un dictionnaire")
            logger.error(f"❌ Type reçu: {type(vosk_result)}")
            logger.error(f"❌ Contenu: {vosk_result}")
            raise HTTPException(
                status_code=502,
                detail=f"Erreur: vosk_result invalide (type: {type(vosk_result)})"
            )
        
        # ✅ Debugging granulaire pour identifier l'erreur exacte
        logger.info(f"🔍 STEP 1: About to access vosk_result")
        logger.info(f"🔍 DEBUG: vosk_result type = {type(vosk_result)}")
        logger.info(f"🔍 DEBUG: vosk_result content = {vosk_result}")
        
        # Calculer score de prononciation spécifique aux virelangues
        logger.info(f"🔍 STEP 2: About to get transcription")
        transcribed_text = safe_get(vosk_result, "transcription", "", "transcription_extraction")
        logger.info(f"🔍 STEP 3: transcribed_text = '{transcribed_text}'")
        
        logger.info(f"🔍 STEP 4: About to get confidence_score")
        confidence_score = safe_get(vosk_result, "confidence_score", 0.0, "confidence_extraction")
        logger.info(f"🔍 STEP 5: confidence_score = {confidence_score}")
        
        logger.info(f"🔍 STEP 6: About to call _calculate_virelangue_pronunciation_score")
        pronunciation_score = _calculate_virelangue_pronunciation_score(
            target_text, transcribed_text, confidence_score
        )
        logger.info(f"🔍 STEP 7: pronunciation_score = {pronunciation_score}")
        
        # Analyser les sons difficiles
        logger.info(f"🔍 STEP 8: About to call _analyze_target_sounds")
        try:
            sound_analysis = _analyze_target_sounds(transcribed_text, target_sounds_list, vosk_result)
            # ✅ VALIDATION CRITIQUE: Vérifier que sound_analysis est un dictionnaire
            if not isinstance(sound_analysis, dict):
                logger.error(f"❌ _analyze_target_sounds a retourné un type invalide: {type(sound_analysis)}, contenu: {sound_analysis}")
                sound_analysis = {"precision_score": 0.5, "sound_details": [], "overall_sound_quality": "erreur"}
            logger.info(f"🔍 STEP 9: sound_analysis completed - Type: {type(sound_analysis)}")
        except Exception as e:
            logger.error(f"❌ Erreur dans _analyze_target_sounds: {e}")
            sound_analysis = {"precision_score": 0.5, "sound_details": [], "overall_sound_quality": "erreur"}
        
        # Construire la réponse spécialisée pour virelangues
        analysis_result = {
            "session_id": session_id,
            "timestamp": datetime.now().isoformat(),
            "target_text": target_text,
            "transcribed_text": transcribed_text,
            "target_sounds": target_sounds_list,
            "overall_score": pronunciation_score,
            "pronunciation_accuracy": pronunciation_score,
            "detailed_scores": {
                "accuracy": pronunciation_score,
                "clarity": safe_get(vosk_result, "clarity_score", 0.0, "clarity_score"),
                "fluency": safe_get(vosk_result, "fluency_score", 0.0, "fluency_score"),
                "confidence": safe_get(vosk_result, "confidence_score", 0.0, "confidence_score_2"),
                "sound_precision": safe_get(sound_analysis, "precision_score", 0.0, "sound_precision")
            },
            "sound_analysis": sound_analysis,
            "prosody_analysis": safe_get(vosk_result, "prosody", {}, "prosody_analysis"),
            "feedback": _generate_virelangue_feedback(pronunciation_score, sound_analysis),
            "strengths": _extract_virelangue_strengths(pronunciation_score, sound_analysis),
            "improvements": _extract_virelangue_improvements(pronunciation_score, sound_analysis),
            "phoneme_details": safe_get(vosk_result, "words", [], "phoneme_details"),
            "processing_time": safe_get(vosk_result, "processing_time", 0.0, "processing_time"),
            "exercise_type": "virelangue",
            "difficulty_assessment": _assess_virelangue_difficulty(target_text, pronunciation_score)
        }
        
        # Sauvegarder le résultat dans Redis
        if session_id and redis_client:
            analysis_key = f"eloquence:virelangue_analysis:{session_id}"
            redis_client.set(analysis_key, json.dumps(analysis_result))
            redis_client.expire(analysis_key, 86400)  # Expire après 24h
        
        logger.info(f"✅ Analyse virelangue réussie - Score: {pronunciation_score:.2f}")
        return analysis_result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'analyse virelangue: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur d'analyse virelangue: {str(e)}"
        )

def _calculate_virelangue_pronunciation_score(target_text: str, transcribed_text: str, base_confidence: float) -> float:
    """Calcule un score de prononciation spécifique aux virelangues"""
    try:
        target_words = target_text.lower().replace(",", "").replace("?", "").replace("!", "").split()
        transcribed_words = transcribed_text.lower().replace(",", "").replace("?", "").replace("!", "").split()
        
        if not target_words:
            return base_confidence
        
        # Calculer la similarité mot par mot
        correct_words = 0
        for target_word in target_words:
            # Chercher le mot le plus proche dans la transcription
            best_match = 0.0
            for transcribed_word in transcribed_words:
                # Similarité simple basée sur les caractères communs
                similarity = _calculate_word_similarity(target_word, transcribed_word)
                best_match = max(best_match, similarity)
            
            if best_match > 0.7:  # Seuil de correspondance
                correct_words += 1
        
        word_accuracy = correct_words / len(target_words)
        
        # Combiner avec la confiance Vosk
        final_score = (word_accuracy * 0.7) + (base_confidence * 0.3)
        return min(1.0, max(0.0, final_score))
        
    except Exception:
        return base_confidence

def _calculate_word_similarity(word1: str, word2: str) -> float:
    """Calcule la similarité entre deux mots"""
    if word1 == word2:
        return 1.0
    
    # Calculer la distance de Levenshtein simplifiée
    len1, len2 = len(word1), len(word2)
    if len1 == 0 or len2 == 0:
        return 0.0
    
    # Compter les caractères communs
    common_chars = 0
    for char in word1:
        if char in word2:
            common_chars += 1
    
    similarity = common_chars / max(len1, len2)
    return similarity

def _analyze_target_sounds(transcribed_text: str, target_sounds: List[str], vosk_result: Dict) -> Dict[str, Any]:
    """Analyse la prononciation des sons ciblés"""
    
    # ✅ VALIDATION CRITIQUE
    if not isinstance(vosk_result, dict):
        logger.error(f"❌ _analyze_target_sounds: vosk_result n'est pas un dict: {type(vosk_result)}")
        return {"precision_score": 0.5, "sound_details": [], "overall_sound_quality": "erreur_type"}
    
    if not target_sounds:
        return {"precision_score": 0.8, "sound_details": []}
    
    sound_details = []
    total_precision = 0.0
    
    for sound in target_sounds:
        sound_count_target = transcribed_text.lower().count(sound.lower())
        precision = min(1.0, sound_count_target / max(1, len(target_sounds)))
        
        sound_details.append({
            "sound": sound,
            "detected_count": sound_count_target,
            "precision": precision,
            "feedback": f"Son '{sound}' détecté {sound_count_target} fois"
        })
        
        total_precision += precision
    
    avg_precision = total_precision / len(target_sounds) if target_sounds else 0.8
    
    return {
        "precision_score": avg_precision,
        "sound_details": sound_details,
        "overall_sound_quality": "bon" if avg_precision > 0.7 else "à améliorer"
    }

def _generate_virelangue_feedback(pronunciation_score: float, sound_analysis: Dict) -> str:
    """Génère un feedback spécialisé pour les virelangues"""
    if pronunciation_score >= 0.8:
        return "Excellente prononciation du virelangue ! Votre articulation est claire et précise."
    elif pronunciation_score >= 0.6:
        return "Bonne tentative ! Continuez à travailler sur l'articulation des sons difficiles."
    else:
        return "Prenez votre temps pour bien articuler chaque son. Répétez lentement puis accélérez progressivement."

def _extract_virelangue_strengths(pronunciation_score: float, sound_analysis: Dict) -> List[str]:
    """Extrait les points forts de la prononciation"""
    strengths = []
    
    # ✅ VALIDATION CRITIQUE
    if not isinstance(sound_analysis, dict):
        logger.error(f"❌ _extract_virelangue_strengths: sound_analysis invalide: {type(sound_analysis)}")
        return ["Analyse en cours..."]
    
    if pronunciation_score >= 0.7:
        strengths.append("Bonne articulation générale")
    
    precision_score = safe_get(sound_analysis, "precision_score", 0.0, "strengths_precision")
    if precision_score >= 0.8:
        strengths.append("Excellente maîtrise des sons ciblés")
    elif precision_score >= 0.6:
        strengths.append("Bonne maîtrise des sons ciblés")
    
    if not strengths:
        strengths.append("Courage dans la tentative de prononciation")
    
    return strengths

def _extract_virelangue_improvements(pronunciation_score: float, sound_analysis: Dict) -> List[str]:
    """Extrait les axes d'amélioration"""
    improvements = []
    
    # ✅ VALIDATION CRITIQUE
    if not isinstance(sound_analysis, dict):
        logger.error(f"❌ _extract_virelangue_improvements: sound_analysis invalide: {type(sound_analysis)}")
        return ["Réessayer l'analyse"]
    
    if pronunciation_score < 0.6:
        improvements.append("Améliorer l'articulation générale")
    
    precision_score = safe_get(sound_analysis, "precision_score", 0.0, "improvements_precision")
    if precision_score < 0.7:
        improvements.append("Travailler spécifiquement les sons difficiles")
    
    if pronunciation_score < 0.8:
        improvements.append("Ralentir le débit pour une meilleure précision")
    
    return improvements

def _assess_virelangue_difficulty(target_text: str, pronunciation_score: float) -> str:
    """Évalue la difficulté du virelangue basée sur le texte et la performance"""
    text_length = len(target_text)
    
    if text_length > 60 and pronunciation_score < 0.5:
        return "expert"
    elif text_length > 40 and pronunciation_score < 0.7:
        return "difficile"
    elif text_length > 25:
        return "intermédiaire"
    else:
        return "facile"

@app.get("/api/statistics")
async def get_statistics():
    """Récupère les statistiques générales"""
    try:
        exercise_count = len(redis_client.keys(f"{EXERCISE_PREFIX}*"))
        session_count = len(redis_client.keys(f"{SESSION_PREFIX}*"))
        template_count = len(redis_client.keys(f"{TEMPLATE_PREFIX}*"))
        voice_analysis_count = len(redis_client.keys("eloquence:voice_analysis*"))
        realtime_session_count = len(redis_client.keys(f"{REALTIME_SESSION_PREFIX}*"))
        
        # Calculer les sessions complétées
        completed_sessions = 0
        session_keys = redis_client.keys(f"{SESSION_PREFIX}*")
        for key in session_keys:
            session_data = redis_client.get(key)
            if session_data:
                session = json.loads(session_data)
                if session.get("status") == "completed":
                    completed_sessions += 1
        
        return {
            "exercises_total": exercise_count,
            "sessions_total": session_count,
            "sessions_completed": completed_sessions,
            "templates_total": template_count,
            "voice_analyses_total": voice_analysis_count,
            "realtime_sessions_total": realtime_session_count,
            "active_websocket_connections": len(active_websocket_connections),
            "completion_rate": round((completed_sessions / session_count) * 100, 2) if session_count > 0 else 0
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur statistiques: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération statistiques: {str(e)}")

# ============================================
# Fonctions utilitaires pour l'analyse temps réel
# ============================================

async def send_error_to_websocket(websocket: WebSocket, session_id: str, error_code: str, error_message: str):
    """Envoie un message d'erreur via WebSocket"""
    try:
        error_msg = RealTimeError(
            session_id=session_id,
            error_code=error_code,
            error_message=error_message
        )
        await websocket.send_text(error_msg.model_dump_json())
    except Exception as e:
        logger.error(f"❌ Erreur envoi message d'erreur WebSocket: {e}")

async def process_audio_chunk_realtime(session_id: str, audio_data: str, chunk_id: int) -> Optional[Dict]:
    """Traite un chunk audio en temps réel avec Vosk"""
    try:
        # Décoder l'audio base64
        audio_bytes = base64.b64decode(audio_data)
        
        # Préparer les données pour Vosk
        files = {"audio": ("chunk.wav", audio_bytes, "audio/wav")}
        data = {
            "scenario_type": realtime_sessions.get(session_id, {}).get("exercise_type", "realtime"),
            "scenario_context": f"Analyse temps réel chunk {chunk_id}"
        }
        
        # Appeler Vosk (correction: utiliser endpoint /analyze)
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=5.0, read=10.0, write=5.0, pool=2.0),
            transport=httpx_async_transport
        ) as client:
            try:
                vosk_response = await client.post(
                    f"{VOSK_SERVICE_URL}/analyze",  # Endpoint correct pour Vosk
                    files=files,
                    data=data
                )
            except (httpx.ConnectError, httpx.TimeoutException, httpx.RequestError) as e:
                logger.warning(f"⚠️ Erreur Vosk chunk {chunk_id}: {e}")
                return None
            
            if vosk_response.status_code == 200:
                return vosk_response.json()
            else:
                logger.warning(f"⚠️ Vosk chunk {chunk_id}: {vosk_response.status_code}")
                return None
                
    except Exception as e:
        logger.error(f"❌ Erreur traitement chunk {chunk_id}: {e}")
        return None

def calculate_realtime_metrics(session_data: Dict) -> Dict[str, float]:
    """Calcule les métriques en temps réel"""
    try:
        chunks = session_data.get("chunks", [])
        if not chunks:
            return {
                "clarity_score": 0.0,
                "fluency_score": 0.0,
                "energy_score": 0.0,
                "speaking_rate": 0.0,
                "pause_ratio": 0.0,
                "cumulative_confidence": 0.0
            }
        
        # Calculer la confiance cumulative
        confidences = [chunk.get("confidence", 0.0) for chunk in chunks if chunk.get("confidence")]
        avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0
        
        # Estimer le débit (mots par minute)
        total_words = sum(len(chunk.get("text", "").split()) for chunk in chunks)
        elapsed_time = session_data.get("elapsed_time", 1.0)  # en secondes
        speaking_rate = (total_words / elapsed_time) * 60 if elapsed_time > 0 else 0.0
        
        # Estimer le ratio de pauses (basé sur les chunks sans transcription)
        silent_chunks = sum(1 for chunk in chunks if not chunk.get("text", "").strip())
        pause_ratio = silent_chunks / len(chunks) if chunks else 0.0
        
        return {
            "clarity_score": avg_confidence,
            "fluency_score": max(0.0, 1.0 - pause_ratio),
            "energy_score": min(1.0, speaking_rate / 150),  # Normalisé sur 150 mots/min
            "speaking_rate": speaking_rate,
            "pause_ratio": pause_ratio,
            "cumulative_confidence": avg_confidence
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur calcul métriques temps réel: {e}")
        return {
            "clarity_score": 0.0,
            "fluency_score": 0.0,
            "energy_score": 0.0,
            "speaking_rate": 0.0,
            "pause_ratio": 0.0,
            "cumulative_confidence": 0.0
        }

# ============================================
# Endpoint WebSocket pour analyse temps réel
# ============================================

@app.websocket("/ws/voice-analysis/{session_id}")
async def websocket_voice_analysis_realtime(websocket: WebSocket, session_id: str):
    """
    WebSocket endpoint pour analyse vocale en temps réel
    
    Protocole:
    1. Connexion et envoi de START_SESSION
    2. Envoi de chunks audio (AUDIO_CHUNK)
    3. Réception de résultats partiels (PARTIAL_RESULT, METRICS_UPDATE)
    4. Envoi de END_SESSION
    5. Réception de résultat final (FINAL_RESULT)
    """
    await websocket.accept()
    active_websocket_connections[session_id] = websocket
    logger.info(f"🔌 WebSocket connecté pour session {session_id}")
    
    try:
        # Initialiser la session temps réel
        realtime_sessions[session_id] = {
            "start_time": datetime.now(),
            "chunks": [],
            "chunk_counter": 0,
            "total_transcription": "",
            "metrics_history": []
        }
        
        while True:
            try:
                logger.info(f"🔄 Boucle WebSocket active pour session {session_id}")
                
                # Recevoir un message WebSocket
                data = await websocket.receive_text()
                logger.info(f"📨 Data brute reçue: {data}")
                
                message = json.loads(data)
                message_type = message.get("type")
                
                logger.info(f"📨 Message reçu type: {message_type}, contenu complet: {message}")
                
                if message_type == "START_SESSION":
                    # Démarrer la session
                    try:
                        realtime_sessions[session_id].update({
                            "exercise_type": message.get("exercise_type", "general"),
                            "user_id": message.get("user_id", "anonymous"),
                            "settings": message.get("settings", {})
                        })
                        
                        logger.info(f"🎯 Session temps réel démarrée: {session_id}")
                        
                        # Envoyer confirmation
                        await websocket.send_text(json.dumps({
                            "type": "session_started",
                            "session_id": session_id,
                            "timestamp": datetime.now().isoformat()
                        }))
                    except Exception as e:
                        logger.error(f"❌ Erreur démarrage session: {e}")
                        await send_error_to_websocket(websocket, session_id, "START_ERROR", str(e))
                    
                elif message_type == "AUDIO_CHUNK":
                    # Traiter chunk audio
                    try:
                        chunk_id = message.get("chunk_id", 0)
                        audio_data = message.get("audio_data", "")
                        timestamp = message.get("timestamp", datetime.now().isoformat())
                        
                        session_data = realtime_sessions[session_id]
                        
                        # Traiter avec Vosk (correction: utiliser endpoint /analyze au lieu de /transcribe)
                        vosk_result = await process_audio_chunk_realtime(
                            session_id,
                            audio_data,
                            chunk_id
                        )
                        
                        if vosk_result:
                            # Stocker le chunk (format correct basé sur la doc Vosk)
                            # Le service Vosk retourne directement: {"text": "...", "confidence": 0.x, "words": [...]}
                            text = vosk_result.get("text", "")
                            confidence = vosk_result.get("confidence", 0.0)
                            
                            chunk_data = {
                                "chunk_id": chunk_id,
                                "timestamp": timestamp,
                                "text": text,
                                "confidence": confidence
                            }
                            session_data["chunks"].append(chunk_data)
                            
                            # Mettre à jour la transcription totale
                            if chunk_data["text"].strip():
                                session_data["total_transcription"] += " " + chunk_data["text"].strip()
                            
                            # Calculer l'elapsed time
                            session_data["elapsed_time"] = (datetime.now() - session_data["start_time"]).total_seconds()
                            
                            # Envoyer résultat partiel
                            partial_result = {
                                "type": "PARTIAL_RESULT",
                                "session_id": session_id,
                                "chunk_id": chunk_id,
                                "transcription": chunk_data["text"],
                                "confidence": chunk_data["confidence"],
                                "timestamp": datetime.now().isoformat(),
                                "partial_metrics": {"chunk_confidence": chunk_data["confidence"]}
                            }
                            await websocket.send_text(json.dumps(partial_result))
                            
                            # Envoyer mise à jour des métriques toutes les 5 chunks
                            if len(session_data["chunks"]) % 5 == 0:
                                metrics = calculate_realtime_metrics(session_data)
                                metrics_update = {
                                    "type": "METRICS_UPDATE",
                                    "session_id": session_id,
                                    "timestamp": datetime.now().isoformat(),
                                    **metrics
                                }
                                await websocket.send_text(json.dumps(metrics_update))
                                session_data["metrics_history"].append(metrics)
                        else:
                            logger.warning(f"⚠️ Pas de résultat Vosk pour chunk {chunk_id}")
                    except Exception as e:
                        logger.error(f"❌ Erreur traitement chunk: {e}")
                        await send_error_to_websocket(websocket, session_id, "CHUNK_ERROR", str(e))
                    
                elif message_type == "END_SESSION":
                    # Terminer la session
                    try:
                        session_data = realtime_sessions[session_id]
                        total_duration = (datetime.now() - session_data["start_time"]).total_seconds()
                        
                        # Calculer métriques finales
                        final_metrics = calculate_realtime_metrics(session_data)
                        
                        # Générer feedback simple
                        transcription = session_data["total_transcription"].strip()
                        strengths = []
                        improvements = []
                        
                        if final_metrics["cumulative_confidence"] > 0.8:
                            strengths.append("Excellente clarté de prononciation")
                        if final_metrics["speaking_rate"] > 100 and final_metrics["speaking_rate"] < 180:
                            strengths.append("Débit de parole optimal")
                        if final_metrics["pause_ratio"] < 0.3:
                            strengths.append("Fluidité naturelle")
                        
                        if final_metrics["cumulative_confidence"] < 0.6:
                            improvements.append("Améliorer l'articulation")
                        if final_metrics["speaking_rate"] < 80:
                            improvements.append("Parler un peu plus rapidement")
                        elif final_metrics["speaking_rate"] > 200:
                            improvements.append("Ralentir légèrement le débit")
                        
                        feedback = f"Session de {total_duration:.1f}s avec {len(session_data['chunks'])} chunks analysés."
                        
                        # Envoyer résultat final
                        final_result = {
                            "type": "FINAL_RESULT",
                            "session_id": session_id,
                            "total_duration": total_duration,
                            "final_transcription": transcription,
                            "overall_metrics": final_metrics,
                            "strengths": strengths,
                            "improvements": improvements,
                            "feedback": feedback,
                            "processing_time": 0.0,
                            "timestamp": datetime.now().isoformat()
                        }
                        await websocket.send_text(json.dumps(final_result))
                        
                        # Sauvegarder dans Redis
                        redis_client.set(
                            f"{REALTIME_SESSION_PREFIX}{session_id}",
                            json.dumps({
                                "session_data": session_data,
                                "final_result": final_result,
                                "completed_at": datetime.now().isoformat()
                            }),
                            ex=86400  # 24h expiration
                        )
                        
                        logger.info(f"✅ Session temps réel terminée: {session_id}")
                        break
                    except Exception as e:
                        logger.error(f"❌ Erreur fin de session: {e}")
                        await send_error_to_websocket(websocket, session_id, "END_ERROR", str(e))
                        break
                
                else:
                    logger.warning(f"⚠️ Type de message non reconnu: {message_type}")
                    await send_error_to_websocket(websocket, session_id, "UNKNOWN_MESSAGE_TYPE", f"Type '{message_type}' non supporté")
                    
            except WebSocketDisconnect:
                logger.info(f"🔌 WebSocket déconnecté: {session_id}")
                break
            except json.JSONDecodeError:
                await send_error_to_websocket(websocket, session_id, "INVALID_JSON", "Format JSON invalide")
            except Exception as e:
                await send_error_to_websocket(websocket, session_id, "PROCESSING_ERROR", str(e))
                
    except WebSocketDisconnect:
        logger.info(f"🔌 WebSocket fermé: {session_id}")
    except Exception as e:
        logger.error(f"❌ Erreur WebSocket {session_id}: {e}")
    finally:
        # Cleanup
        if session_id in active_websocket_connections:
            del active_websocket_connections[session_id]
        if session_id in realtime_sessions:
            del realtime_sessions[session_id]
        logger.info(f"🧹 Cleanup session {session_id}")

# ============================================
# Endpoints pour l'analyse narrative d'histoires
# ============================================

async def call_mistral_with_retry(payload, max_retries=2):
    """Appel Mistral avec retry et fallback intelligent - Gère son propre client httpx"""
    
    for attempt in range(max_retries + 1):
        try:
            logger.info(f"🔄 Tentative Mistral {attempt + 1}/{max_retries + 1}")
            
            # ✅ CORRECTION CRITIQUE : Créer un nouveau client pour chaque tentative
            async with httpx.AsyncClient(
                timeout=httpx.Timeout(connect=5.0, read=15.0, write=10.0, pool=2.0),
                transport=httpx_async_transport
            ) as mistral_client:
                response = await mistral_client.post(
                    f"{MISTRAL_SERVICE_URL}/v1/chat/completions",
                    json=payload,
                    timeout=15.0
                )
                
                if response.status_code == 200:
                    logger.info(f"✅ Mistral réponse OK - Tentative {attempt + 1}")
                    return response
                else:
                    logger.warning(f"⚠️ Mistral HTTP {response.status_code} - Tentative {attempt + 1}")
                
        except httpx.ConnectError as e:
            logger.warning(f"⚠️ Mistral connexion échouée - Tentative {attempt + 1}: {e}")
            if attempt < max_retries:
                await asyncio.sleep(1)  # Attendre 1s avant retry
                continue
                
        except httpx.TimeoutException as e:
            logger.warning(f"⚠️ Mistral timeout - Tentative {attempt + 1}: {e}")
            if attempt < max_retries:
                await asyncio.sleep(0.5)  # Attendre 0.5s avant retry
                continue
        
        except Exception as e:
            logger.warning(f"⚠️ Mistral erreur inattendue - Tentative {attempt + 1}: {e}")
            if attempt < max_retries:
                await asyncio.sleep(1)
                continue
    
    # Si toutes les tentatives échouent
    logger.error("❌ Toutes les tentatives Mistral ont échoué")
    return None

def _generate_vosk_only_analysis(session_id, story_title, transcription, elements_list):
    """Génère une analyse basée uniquement sur Vosk quand Mistral échoue"""
    
    # Analyser la transcription avec des heuristiques simples
    words = transcription.lower().split() if transcription else []
    word_count = len(words)
    
    # Calculer des scores basés sur la longueur et le contenu
    length_score = min(1.0, word_count / 50) if word_count > 0 else 0.3
    
    # Détecter l'utilisation des éléments
    elements_used = 0
    if elements_list and transcription:
        for element in elements_list:
            if element.lower() in transcription.lower():
                elements_used += 1
    
    element_usage_score = elements_used / max(len(elements_list), 1) if elements_list else 0.7
    
    # Calculer un score global (légèrement pénalisé car pas d'IA)
    overall_score = (length_score * 0.4 + element_usage_score * 0.6) * 0.75
    
    logger.info(f"📊 Analyse Vosk-only - Mots: {word_count}, Éléments: {elements_used}/{len(elements_list)}, Score: {overall_score:.2f}")
    
    return {
        "success": True,
        "analysis": {
            "overall_score": overall_score,
            "creativity_score": overall_score + 0.05,
            "element_usage_score": element_usage_score,
            "plot_coherence_score": overall_score,
            "fluidity_score": 0.75,  # Score fixe pour la fluidité
            "genre_consistency_score": 0.7,
            "strengths": [
                f"Histoire de {word_count} mots détectés",
                f"Utilisation de {elements_used} éléments sur {len(elements_list)}" if elements_list else "Contenu détecté"
            ],
            "improvements": [
                "Développer davantage les détails" if word_count < 30 else "Bonne longueur d'histoire",
                "Utiliser tous les éléments imposés" if elements_used < len(elements_list) else "Bonne utilisation des éléments"
            ],
            "highlight_moments": ["Début de l'histoire", "Développement narratif"],
            "narrative_feedback": f"Histoire analysée avec Vosk (IA temporairement indisponible). {word_count} mots détectés.",
            "title_suggestion": story_title or "Histoire Créative",
            "detected_keywords": words[:5] if words else ["histoire", "créativité"]
        },
        "transcription": transcription or "Transcription indisponible",
        "session_id": session_id,
        "analysis_method": "vosk_only",  # Indiquer la méthode utilisée
        "timestamp": datetime.now().isoformat()
    }

@app.post("/api/story/analyze-narrative")
async def analyze_story_narrative(
    audio: UploadFile = File(...),
    session_id: str = Form(...),
    story_title: Optional[str] = Form("Histoire sans titre"),
    story_elements: Optional[str] = Form("[]"),
    genre: Optional[str] = Form("libre")
):
    """
    Endpoint d'analyse narrative pour le générateur d'histoires
    Flux: Audio → Vosk STT → Mistral AI → Analyse structurée
    """
    logger.info(f"🎭 Analyse narrative reçue - session: {session_id}, titre: {story_title}")
    
    try:
        # Préparer les données pour l'envoi vers Vosk STT
        audio_content = await audio.read()
        
        # ✅ VALIDATION LOG: Vérifier la taille du fichier audio
        audio_size = len(audio_content)
        logger.info(f"📊 VALIDATION AUDIO - Taille: {audio_size} bytes, Nom: {audio.filename}")
        
        # ✅ CORRECTION : Validation assouplie de la taille du fichier
        if audio_size < 100:  # Moins de 100 bytes = fichier invalide
            logger.error(f"❌ FICHIER AUDIO INVALIDE - Taille: {audio_size} bytes (minimum 100 bytes requis)")
            return {
                "success": False,
                "error": "INVALID_AUDIO_FILE",
                "details": f"Fichier audio trop petit: {audio_size} bytes. Minimum requis: 100 bytes",
                "session_id": session_id,
                "timestamp": datetime.now().isoformat()
            }
        elif audio_size < 1000:
            # ✅ NOUVEAU : Avertissement pour fichiers petits mais valides
            logger.warning(f"⚠️ FICHIER AUDIO PETIT - Taille: {audio_size} bytes - Analyse avec prudence")
        
        # Log des détails audio
        logger.info(f"✅ AUDIO VALIDE - Format: {audio.content_type}, Taille: {audio_size} bytes")
        
        # Étape 1: Transcription via Vosk
        files = {"audio": (audio.filename, audio_content, audio.content_type)}
        data = {
            "scenario_type": "story_narration",
            "scenario_context": f"Analyse narrative: {story_title}"
        }
        
        transcription = ""
        
        async with httpx.AsyncClient(
            timeout=httpx_timeout,
            transport=httpx_async_transport
        ) as client:
            try:
                logger.info(f"🔗 Envoi vers Vosk STT: {VOSK_SERVICE_URL}/analyze")
                vosk_response = await client.post(
                    f"{VOSK_SERVICE_URL}/analyze",
                    files=files,
                    data=data
                )
                
                if vosk_response.status_code == 200:
                    vosk_result = vosk_response.json()
                    transcription = vosk_result.get("transcription", "")
                    logger.info(f"✅ Transcription réussie: {transcription[:100]}...")
                else:
                    logger.warning(f"⚠️ Vosk STT erreur: {vosk_response.status_code}")
                    transcription = "Transcription indisponible"
                    
            except Exception as e:
                logger.error(f"❌ Erreur Vosk STT: {e}")
                transcription = "Transcription indisponible"
        
        # Étape 2: Analyse narrative via Mistral AI
        if transcription and transcription != "Transcription indisponible":
            try:
                # Parser les éléments d'histoire
                elements_list = json.loads(story_elements) if story_elements else []
                
                # Créer le prompt d'analyse narrative
                analysis_prompt = f"""Analysez cette histoire racontée oralement et retournez UNIQUEMENT un objet JSON valide avec cette structure exacte:

{{
    "overall_score": 0.8,
    "creativity_score": 0.85,
    "element_usage_score": 0.7,
    "plot_coherence_score": 0.75,
    "fluidity_score": 0.8,
    "genre_consistency_score": 0.7,
    "strengths": ["Point fort 1", "Point fort 2"],
    "improvements": ["Amélioration 1", "Amélioration 2"],
    "highlight_moments": ["Moment marquant 1", "Moment marquant 2"],
    "narrative_feedback": "Feedback général sur l'histoire",
    "title_suggestion": "Titre suggéré",
    "detected_keywords": ["mot-clé1", "mot-clé2", "mot-clé3"]
}}

HISTOIRE À ANALYSER:
Titre: {story_title}
Genre: {genre}
Éléments imposés: {', '.join(elements_list)}
Transcription: {transcription}

Analysez la créativité, l'utilisation des éléments, la cohérence narrative et la fluidité."""

                mistral_payload = {
                    "model": "mistral-nemo-instruct-2407",
                    "messages": [{"role": "user", "content": analysis_prompt}],
                    "temperature": 0.6,
                    "max_tokens": 1000
                }
                
                logger.info(f"🔗 Envoi vers Mistral AI: {MISTRAL_SERVICE_URL}/v1/chat/completions")
                
                # ✅ MONITORING CONNEXION MISTRAL
                mistral_start_time = datetime.now()
                logger.info(f"🔍 MISTRAL CONNEXION - Début: {mistral_start_time.isoformat()}")
                
                # ✅ UTILISATION DU SYSTÈME DE RETRY INTELLIGENT
                mistral_response = await call_mistral_with_retry(mistral_payload)
                
                if mistral_response is None:
                    logger.warning("⚠️ Mistral indisponible - Utilisation analyse Vosk seule")
                    return _generate_vosk_only_analysis(session_id, story_title, transcription, elements_list)
                
                mistral_duration = (datetime.now() - mistral_start_time).total_seconds()
                logger.info(f"⏱️ MISTRAL RESPONSE - Durée: {mistral_duration:.2f}s, Status: {mistral_response.status_code}")
                
                if mistral_response.status_code == 200:
                    mistral_result = mistral_response.json()
                    analysis_text = mistral_result.get("choices", [{}])[0].get("message", {}).get("content", "")
                    
                    # 🧠 SYSTÈME HYBRIDE INTELLIGENT : Analyse préliminaire du contenu
                    transcription_clean = transcription.lower().strip()
                    words = transcription_clean.split()
                    
                    # Détecter le contenu non significatif
                    nonsense_patterns = [
                        "bla", "blabla", "euh", "hum", "ah", "oh", "mmm",
                        "test", "testing", "allo", "hello", "bonjour"
                    ]
                    
                    nonsense_count = 0
                    for word in words:
                        if any(pattern in word for pattern in nonsense_patterns):
                            nonsense_count += 1
                    
                    nonsense_ratio = nonsense_count / max(len(words), 1)
                    
                    logger.info(f"🔍 ANALYSE HYBRIDE - Ratio charabia: {nonsense_ratio:.2f}, Mots: {len(words)}")
                    
                    # Si le contenu est de qualité, utiliser Mistral IA + ajustements intelligents
                    if len(words) >= 5 and nonsense_ratio < 0.3:
                        logger.info("✅ Contenu de qualité détecté - Utilisation Mistral + ajustements")
                        
                        # Parser le JSON de l'analyse Mistral
                        try:
                            # Nettoyer le texte pour extraire le JSON
                            if "```json" in analysis_text:
                                analysis_text = analysis_text.split("```json")[1].split("```")[0]
                            elif "```" in analysis_text:
                                analysis_text = analysis_text.split("```")[1]
                            
                            mistral_analysis = json.loads(analysis_text.strip())
                            
                            # Appliquer des ajustements intelligents aux scores Mistral
                            adjusted_analysis = _apply_intelligent_adjustments(
                                mistral_analysis, transcription, elements_list, nonsense_ratio
                            )
                            
                            logger.info("✅ Analyse Mistral + ajustements intelligents appliquée")
                            
                            # Construire la réponse finale avec Mistral amélioré
                            return {
                                "success": True,
                                "analysis": adjusted_analysis,
                                "transcription": transcription,
                                "session_id": session_id,
                                "story_title": story_title,
                                "genre": genre,
                                "elements": elements_list,
                                "analysis_method": "mistral_intelligent",
                                "content_quality": "good",
                                "timestamp": datetime.now().isoformat()
                            }
                            
                        except json.JSONDecodeError as e:
                            logger.error(f"❌ Erreur parsing JSON Mistral: {e}")
                            # Fallback vers analyse intelligente
                            return _generate_fallback_narrative_analysis(
                                session_id, story_title, transcription, elements_list
                            )
                    else:
                        # Contenu de mauvaise qualité ou charabia - utiliser analyse intelligente
                        logger.info(f"⚠️ Contenu de mauvaise qualité détecté (ratio: {nonsense_ratio:.2f}) - Utilisation analyse intelligente")
                        return _generate_fallback_narrative_analysis(
                            session_id, story_title, transcription, elements_list
                        )
                else:
                    logger.error(f"❌ Mistral AI erreur: {mistral_response.status_code}")
                    return _generate_fallback_narrative_analysis(
                        session_id, story_title, transcription, elements_list
                    )
                    
            except Exception as e:
                logger.error(f"❌ Erreur analyse Mistral: {e}")
                return _generate_fallback_narrative_analysis(
                    session_id, story_title, transcription, elements_list
                )
        else:
            # Pas de transcription, utiliser fallback
            elements_list = json.loads(story_elements) if story_elements else []
            return _generate_fallback_narrative_analysis(
                session_id, story_title, "Transcription indisponible", elements_list
            )
            
    except Exception as e:
        logger.error(f"❌ Erreur générale analyse narrative: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur d'analyse narrative: {str(e)}"
        )

@app.post("/api/story/generate-elements")
async def generate_story_elements(
    element_type: str = Form(...),
    theme: Optional[str] = Form("libre"),
    difficulty: Optional[str] = Form("facile"),
    count: Optional[int] = Form(3)
):
    """
    Endpoint de génération d'éléments narratifs
    """
    logger.info(f"🎭 Génération éléments - type: {element_type}, thème: {theme}")
    
    try:
        # Créer le prompt de génération
        generation_prompt = f"""Générez {count} {element_type}s pour une histoire.
        
Thème: {theme}
Difficulté: {difficulty}

Retournez UNIQUEMENT un objet JSON valide avec cette structure:
{{
    "elements": [
        {{
            "name": "Nom de l'élément",
            "emoji": "🎭",
            "description": "Description détaillée",
            "keywords": ["mot-clé1", "mot-clé2"]
        }}
    ]
}}

Adaptez le vocabulaire à la difficulté {difficulty}."""

        mistral_payload = {
            "model": "mistral-nemo-instruct-2407",
            "messages": [{"role": "user", "content": generation_prompt}],
            "temperature": 0.8,
            "max_tokens": 800
        }
        
        # ✅ CORRECTION CRITIQUE : Utiliser le système de retry intelligent
        mistral_response = await call_mistral_with_retry(mistral_payload)
        
        if mistral_response and mistral_response.status_code == 200:
            mistral_result = mistral_response.json()
            content = mistral_result.get("choices", [{}])[0].get("message", {}).get("content", "")
            
            # Parser le JSON
            try:
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0]
                elif "```" in content:
                    content = content.split("```")[1]
                
                elements_data = json.loads(content.strip())
                
                return {
                    "success": True,
                    "elements": elements_data.get("elements", []),
                    "element_type": element_type,
                    "theme": theme,
                    "difficulty": difficulty,
                    "timestamp": datetime.now().isoformat()
                }
                
            except json.JSONDecodeError:
                logger.error(f"❌ Erreur parsing JSON génération: {content}")
                return _generate_fallback_elements(element_type, count)
        else:
            logger.error(f"❌ Mistral génération erreur: {mistral_response.status_code if mistral_response else 'No response'}")
            return _generate_fallback_elements(element_type, count)
                
    except Exception as e:
        logger.error(f"❌ Erreur génération éléments: {e}")
        return _generate_fallback_elements(element_type, count)

def _apply_intelligent_adjustments(mistral_analysis: Dict[str, Any], transcription: str, elements: List[str], nonsense_ratio: float) -> Dict[str, Any]:
    """Applique des ajustements intelligents aux scores Mistral basés sur l'analyse réelle du contenu"""
    
    # Copier l'analyse Mistral pour modification
    adjusted_analysis = mistral_analysis.copy()
    
    # Analyse du contenu pour ajustements
    words = transcription.lower().strip().split()
    word_count = len(words)
    
    # Facteur d'ajustement basé sur la qualité du contenu
    content_quality_factor = 1.0 - (nonsense_ratio * 0.5)  # Réduction max de 50% pour 100% charabia
    length_factor = min(1.0, word_count / 15.0)  # Bonus pour contenu plus long
    
    # Analyse de l'utilisation des éléments
    element_usage_factor = 1.0
    if elements:
        elements_found = 0
        for element in elements:
            if element.lower() in transcription.lower():
                elements_found += 1
        element_usage_factor = 0.8 + (elements_found / len(elements)) * 0.4  # Entre 0.8 et 1.2
    
    # Appliquer les ajustements aux scores Mistral
    original_scores = {
        "overall_score": mistral_analysis.get("overall_score", 0.5),
        "creativity_score": mistral_analysis.get("creativity_score", 0.5),
        "element_usage_score": mistral_analysis.get("element_usage_score", 0.5),
        "plot_coherence_score": mistral_analysis.get("plot_coherence_score", 0.5),
        "fluidity_score": mistral_analysis.get("fluidity_score", 0.5),
        "genre_consistency_score": mistral_analysis.get("genre_consistency_score", 0.5)
    }
    
    # Ajuster chaque score
    adjusted_analysis["overall_score"] = min(1.0, max(0.0,
        original_scores["overall_score"] * content_quality_factor * length_factor))
    
    adjusted_analysis["creativity_score"] = min(1.0, max(0.0,
        original_scores["creativity_score"] * content_quality_factor))
    
    adjusted_analysis["element_usage_score"] = min(1.0, max(0.0,
        original_scores["element_usage_score"] * element_usage_factor))
    
    adjusted_analysis["plot_coherence_score"] = min(1.0, max(0.0,
        original_scores["plot_coherence_score"] * content_quality_factor * length_factor))
    
    adjusted_analysis["fluidity_score"] = min(1.0, max(0.0,
        original_scores["fluidity_score"] * content_quality_factor))
    
    adjusted_analysis["genre_consistency_score"] = min(1.0, max(0.0,
        original_scores["genre_consistency_score"] * content_quality_factor))
    
    # Ajouter des informations sur les ajustements
    if nonsense_ratio > 0.1:
        if "improvements" not in adjusted_analysis:
            adjusted_analysis["improvements"] = []
        adjusted_analysis["improvements"].append("Réduire les mots de remplissage et hésitations")
    
    if word_count < 10:
        if "improvements" not in adjusted_analysis:
            adjusted_analysis["improvements"] = []
        adjusted_analysis["improvements"].append("Développer davantage l'histoire")
    
    # Arrondir les scores
    for score_key in ["overall_score", "creativity_score", "element_usage_score",
                      "plot_coherence_score", "fluidity_score", "genre_consistency_score"]:
        if score_key in adjusted_analysis:
            adjusted_analysis[score_key] = round(adjusted_analysis[score_key], 2)
    
    logger.info(f"🔧 AJUSTEMENTS APPLIQUÉS - Facteur qualité: {content_quality_factor:.2f}, "
                f"Facteur longueur: {length_factor:.2f}, Score final: {adjusted_analysis.get('overall_score', 0):.2f}")
    
    return adjusted_analysis

def _generate_fallback_narrative_analysis(session_id: str, title: str, transcription: str, elements: List[str]) -> Dict[str, Any]:
    """Génère une analyse de fallback basée sur le contenu réel"""
    
    # ✅ ANALYSE RÉELLE DU CONTENU DE LA TRANSCRIPTION
    transcription_clean = transcription.lower().strip()
    words = transcription_clean.split()
    
    logger.info(f"🔍 ANALYSE CONTENU - Transcription: '{transcription_clean}', Mots: {len(words)}")
    
    # Détection de contenu non significatif
    nonsense_patterns = [
        "bla", "blabla", "euh", "hum", "ah", "oh", "mmm",
        "test", "testing", "allo", "hello", "bonjour"
    ]
    
    # Calculer le pourcentage de mots non significatifs
    nonsense_count = 0
    for word in words:
        if any(pattern in word for pattern in nonsense_patterns):
            nonsense_count += 1
    
    nonsense_ratio = nonsense_count / max(len(words), 1)
    meaningful_ratio = 1.0 - nonsense_ratio
    
    logger.info(f"📊 ANALYSE QUALITÉ - Mots non significatifs: {nonsense_count}/{len(words)} ({nonsense_ratio:.2f})")
    
    # Analyse de la longueur du contenu
    content_length_score = min(1.0, len(words) / 20.0)  # Score basé sur 20 mots minimum
    
    # Calcul des scores basés sur le contenu réel
    if len(words) < 3:
        # Très peu de contenu
        overall_score = 0.1
        creativity_score = 0.1
        plot_coherence_score = 0.0
        fluidity_score = 0.2
        strengths = ["Tentative d'expression"]
        improvements = ["Développer le contenu", "Raconter une véritable histoire", "Utiliser plus de mots"]
        feedback = "Il semble qu'il n'y ait pas assez de contenu pour évaluer l'histoire. Essayez de raconter une histoire plus développée."
        
    elif nonsense_ratio > 0.7:
        # Majoritairement du charabia
        overall_score = 0.15
        creativity_score = 0.2
        plot_coherence_score = 0.1
        fluidity_score = 0.3
        strengths = ["Expression orale tentée"]
        improvements = ["Raconter une vraie histoire", "Utiliser des mots significatifs", "Développer une intrigue"]
        feedback = "Le contenu semble principalement composé de sons ou mots non significatifs. Essayez de raconter une véritable histoire avec des personnages et une intrigue."
        
    elif nonsense_ratio > 0.4:
        # Partiellement intelligible
        overall_score = 0.35
        creativity_score = 0.4
        plot_coherence_score = 0.3
        fluidity_score = 0.5
        strengths = ["Quelques éléments narratifs identifiables"]
        improvements = ["Clarifier l'histoire", "Réduire les hésitations", "Développer les personnages"]
        feedback = "Il y a quelques éléments d'histoire, mais le contenu pourrait être plus clair et développé."
        
    else:
        # Contenu décent, scores basés sur la qualité
        base_score = meaningful_ratio * content_length_score
        overall_score = max(0.4, min(0.9, base_score))
        creativity_score = max(0.4, min(0.9, base_score + 0.1))
        plot_coherence_score = max(0.3, min(0.9, base_score - 0.1))
        fluidity_score = max(0.4, min(0.9, base_score))
        strengths = ["Histoire cohérente", "Bon niveau d'expression"]
        improvements = ["Développer davantage les détails", "Enrichir le vocabulaire"]
        feedback = "Belle tentative narrative ! Continuez à développer vos histoires."
    
    # Analyse de l'utilisation des éléments
    element_usage_score = 0.0
    if elements:
        elements_found = 0
        for element in elements:
            if element.lower() in transcription_clean:
                elements_found += 1
        element_usage_score = elements_found / len(elements)
    else:
        element_usage_score = overall_score  # Score par défaut si pas d'éléments
    
    # Score de consistance de genre (évaluation basique)
    genre_consistency_score = overall_score * 0.9  # Légèrement inférieur au score global
    
    logger.info(f"✅ SCORES CALCULÉS - Overall: {overall_score:.2f}, Creativity: {creativity_score:.2f}")
    
    return {
        "success": True,
        "analysis": {
            "overall_score": round(overall_score, 2),
            "creativity_score": round(creativity_score, 2),
            "element_usage_score": round(element_usage_score, 2),
            "plot_coherence_score": round(plot_coherence_score, 2),
            "fluidity_score": round(fluidity_score, 2),
            "genre_consistency_score": round(genre_consistency_score, 2),
            "strengths": strengths,
            "improvements": improvements,
            "highlight_moments": ["Début de l'histoire"] if overall_score > 0.3 else [],
            "narrative_feedback": feedback,
            "title_suggestion": title if title != "Histoire sans titre" else "Histoire à développer",
            "detected_keywords": elements[:3] if elements and overall_score > 0.3 else ["pratique", "expression", "développement"]
        },
        "transcription": transcription,
        "session_id": session_id,
        "story_title": title,
        "fallback": True,
        "content_analysis": {
            "word_count": len(words),
            "nonsense_ratio": round(nonsense_ratio, 2),
            "meaningful_content": round(meaningful_ratio, 2),
            "content_quality": "faible" if overall_score < 0.3 else "moyenne" if overall_score < 0.6 else "bonne"
        },
        "timestamp": datetime.now().isoformat()
    }

def _generate_fallback_elements(element_type: str, count: int) -> Dict[str, Any]:
    """Génère des éléments de fallback"""
    fallback_elements = {
        "character": [
            {"name": "Sorcier mystérieux", "emoji": "🧙‍♂️", "description": "Un magicien aux pouvoirs anciens", "keywords": ["magie", "mystère"]},
            {"name": "Princesse courageuse", "emoji": "👸", "description": "Une héroïne déterminée", "keywords": ["courage", "noblesse"]},
            {"name": "Dragon bienveillant", "emoji": "🐉", "description": "Un dragon protecteur", "keywords": ["force", "protection"]}
        ],
        "location": [
            {"name": "Forêt enchantée", "emoji": "🌲", "description": "Une forêt pleine de magie", "keywords": ["nature", "enchantement"]},
            {"name": "Château volant", "emoji": "🏰", "description": "Un château dans les nuages", "keywords": ["altitude", "majesté"]},
            {"name": "Grotte mystérieuse", "emoji": "🕳️", "description": "Une caverne aux secrets", "keywords": ["mystère", "exploration"]}
        ],
        "magicObject": [
            {"name": "Épée de lumière", "emoji": "⚔️", "description": "Une épée qui brille", "keywords": ["lumière", "combat"]},
            {"name": "Cristal de pouvoir", "emoji": "💎", "description": "Un cristal magique", "keywords": ["énergie", "magie"]},
            {"name": "Carte des mondes", "emoji": "🗺️", "description": "Une carte magique", "keywords": ["voyage", "découverte"]}
        ]
    }
    
    elements = fallback_elements.get(element_type, fallback_elements["character"])[:count]
    
    return {
        "success": True,
        "elements": elements,
        "element_type": element_type,
        "fallback": True,
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8005)