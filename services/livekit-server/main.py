import os
import time
import jwt
import uuid
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, List
import logging
from datetime import datetime, timedelta

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LiveKit Token Service")

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration LiveKit depuis les variables d'environnement
LIVEKIT_API_KEY = os.getenv("LIVEKIT_API_KEY", "devkey")
LIVEKIT_API_SECRET = os.getenv("LIVEKIT_API_SECRET", "secret")
LIVEKIT_URL = os.getenv("LIVEKIT_URL", "ws://localhost:7880")

# Cache de tokens actifs (en production, utiliser Redis)
active_tokens: Dict[str, Dict] = {}

class TokenRequest(BaseModel):
    """Requête de génération de token"""
    room_name: str
    participant_name: str
    participant_identity: Optional[str] = None
    grants: Optional[Dict] = None
    metadata: Optional[Dict] = None
    validity_hours: Optional[int] = 24

class TokenResponse(BaseModel):
    """Réponse avec token JWT"""
    token: str
    expires_at: str
    room_name: str
    participant_identity: str
    livekit_url: str

class RoomInfo(BaseModel):
    """Informations sur une room"""
    room_name: str
    participant_count: int
    created_at: str
    scenario_type: Optional[str] = None

@app.get("/health")
def health_check():
    """Vérification de santé du service"""
    return {
        "status": "healthy",
        "service": "livekit-token-service",
        "timestamp": datetime.now().isoformat(),
        "livekit_url": LIVEKIT_URL
    }

@app.post("/generate-token", response_model=TokenResponse)
async def generate_token(request: TokenRequest):
    """
    Génère un token JWT pour LiveKit
    
    Le token contient :
    - Identité du participant
    - Permissions (publish, subscribe, etc.)
    - Métadonnées personnalisées
    - Durée de validité
    """
    try:
        logger.info(f"Génération token pour {request.participant_name} dans {request.room_name}")
        
        # Générer une identité unique si non fournie
        participant_identity = request.participant_identity or f"{request.participant_name}_{uuid.uuid4().hex[:8]}"
        
        # Calculer l'expiration
        now = datetime.now()
        expires_at = now + timedelta(hours=request.validity_hours or 24)
        exp_timestamp = int(expires_at.timestamp())
        
        # Permissions par défaut
        default_grants = {
            "roomJoin": True,
            "room": request.room_name,
            "canPublish": True,
            "canSubscribe": True,
            "canPublishData": True,
            "canUpdateOwnMetadata": True,
        }
        
        # Fusionner avec les permissions personnalisées
        video_grants = {**default_grants, **(request.grants or {})}
        
        # Créer les claims JWT
        claims = {
            "exp": exp_timestamp,
            "iss": LIVEKIT_API_KEY,
            "sub": participant_identity,
            "name": request.participant_name,
            "video": video_grants,
            "metadata": request.metadata or {},
        }
        
        # Encoder le token
        token = jwt.encode(
            claims,
            LIVEKIT_API_SECRET,
            algorithm="HS256",
            headers={"typ": "JWT", "alg": "HS256"}
        )
        
        # Stocker dans le cache
        active_tokens[participant_identity] = {
            "token": token,
            "room_name": request.room_name,
            "expires_at": expires_at.isoformat(),
            "created_at": now.isoformat(),
            "metadata": request.metadata
        }
        
        logger.info(f"Token généré avec succès pour {participant_identity}")
        
        return TokenResponse(
            token=token,
            expires_at=expires_at.isoformat(),
            room_name=request.room_name,
            participant_identity=participant_identity,
            livekit_url=LIVEKIT_URL
        )
        
    except Exception as e:
        logger.error(f"Erreur génération token: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur génération token: {str(e)}")

@app.post("/refresh-token")
async def refresh_token(old_token: str):
    """
    Renouvelle un token existant
    
    Décode le token expiré et génère un nouveau avec les mêmes permissions
    """
    try:
        # Décoder sans vérifier l'expiration
        decoded = jwt.decode(old_token, LIVEKIT_API_SECRET, algorithms=["HS256"], options={"verify_exp": False})
        
        # Créer une nouvelle requête avec les mêmes informations
        request = TokenRequest(
            room_name=decoded["video"]["room"],
            participant_name=decoded["name"],
            participant_identity=decoded["sub"],
            grants=decoded["video"],
            metadata=decoded.get("metadata", {})
        )
        
        # Générer un nouveau token
        return await generate_token(request)
        
    except jwt.InvalidTokenError as e:
        logger.error(f"Token invalide: {str(e)}")
        raise HTTPException(status_code=401, detail="Token invalide")
    except Exception as e:
        logger.error(f"Erreur renouvellement token: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur renouvellement: {str(e)}")

@app.delete("/revoke-token/{participant_identity}")
async def revoke_token(participant_identity: str):
    """
    Révoque un token pour un participant
    
    Note: Cela ne déconnecte pas immédiatement le participant de LiveKit,
    mais empêche la réutilisation du token
    """
    if participant_identity in active_tokens:
        del active_tokens[participant_identity]
        logger.info(f"Token révoqué pour {participant_identity}")
        return {"status": "revoked", "participant_identity": participant_identity}
    else:
        raise HTTPException(status_code=404, detail="Token non trouvé")

@app.get("/active-rooms", response_model=List[RoomInfo])
async def get_active_rooms():
    """
    Liste les rooms actives basées sur les tokens générés
    
    Note: En production, cette information devrait venir directement de l'API LiveKit
    """
    rooms = {}
    
    for identity, token_info in active_tokens.items():
        room_name = token_info["room_name"]
        if room_name not in rooms:
            rooms[room_name] = {
                "room_name": room_name,
                "participant_count": 0,
                "created_at": token_info["created_at"],
                "scenario_type": token_info.get("metadata", {}).get("scenario")
            }
        rooms[room_name]["participant_count"] += 1
    
    return list(rooms.values())

@app.get("/room/{room_name}/participants")
async def get_room_participants(room_name: str):
    """
    Liste les participants d'une room
    """
    participants = []
    
    for identity, token_info in active_tokens.items():
        if token_info["room_name"] == room_name:
            participants.append({
                "identity": identity,
                "joined_at": token_info["created_at"],
                "metadata": token_info.get("metadata", {})
            })
    
    if not participants:
        raise HTTPException(status_code=404, detail="Room non trouvée")
    
    return {
        "room_name": room_name,
        "participant_count": len(participants),
        "participants": participants
    }

@app.post("/cleanup-expired")
async def cleanup_expired_tokens():
    """
    Nettoie les tokens expirés du cache
    """
    now = datetime.now()
    expired = []
    
    for identity, token_info in list(active_tokens.items()):
        expires_at = datetime.fromisoformat(token_info["expires_at"])
        if expires_at < now:
            expired.append(identity)
            del active_tokens[identity]
    
    logger.info(f"Nettoyage: {len(expired)} tokens expirés supprimés")
    
    return {
        "cleaned": len(expired),
        "remaining": len(active_tokens)
    }

# Configuration spécifique pour les scénarios Eloquence
@app.post("/confidence-boost/token")
async def generate_confidence_boost_token(
    scenario_id: str,
    scenario_title: str,
    user_id: str,
    session_id: str,
    ai_character: Optional[str] = "thomas"
):
    """
    Génère un token spécialement configuré pour Confidence Boost
    """
    request = TokenRequest(
        room_name=f"confidence_boost_{scenario_id}_{session_id}",
        participant_name=f"user_{user_id}",
        grants={
            "roomJoin": True,
            "canPublish": True,
            "canSubscribe": True,
            "canPublishData": True,
            "roomRecord": False,  # Enregistrement géré côté VOSK
        },
        metadata={
            "scenario": scenario_title,
            "scenario_id": scenario_id,
            "session_id": session_id,
            "ai_character": ai_character,
            "timestamp": datetime.now().isoformat()
        }
    )
    
    return await generate_token(request)

# Webhook pour les événements LiveKit (optionnel)
@app.post("/webhook/livekit")
async def livekit_webhook(event: Dict):
    """
    Reçoit les événements de LiveKit (participant joined, left, etc.)
    
    Nécessite la configuration du webhook dans LiveKit
    """
    logger.info(f"Événement LiveKit reçu: {event.get('event')}")
    
    # Traiter selon le type d'événement
    event_type = event.get("event")
    
    if event_type == "participant_joined":
        logger.info(f"Participant rejoint: {event.get('participant', {}).get('identity')}")
    elif event_type == "participant_left":
        logger.info(f"Participant parti: {event.get('participant', {}).get('identity')}")
    elif event_type == "room_started":
        logger.info(f"Room démarrée: {event.get('room', {}).get('name')}")
    elif event_type == "room_finished":
        logger.info(f"Room terminée: {event.get('room', {}).get('name')}")
    
    return {"status": "received"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)