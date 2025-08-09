"""
Service de génération de tokens JWT pour LiveKit
"""
import os
import time
import jwt
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, Union
import uvicorn
import logging

# Configuration
API_KEY = os.getenv("LIVEKIT_API_KEY", "devkey")
API_SECRET = os.getenv("LIVEKIT_API_SECRET", "devsecret123456789abcdef0123456789abcdef")
LIVEKIT_URL = os.getenv("LIVEKIT_URL", "ws://livekit-server:7880")

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

class TokenRequest(BaseModel):
    # Support ancien format (pour compatibilité)
    room: Optional[str] = None
    identity: Optional[str] = None
    
    # Support nouveau format Flutter
    room_name: Optional[str] = None
    participant_name: Optional[str] = None
    grants: Optional[Dict[str, Any]] = None
    
    # Metadata peut être string ou objet
    metadata: Union[str, Dict[str, Any]] = "{}"

class TokenResponse(BaseModel):
    token: str
    url: str

def generate_token(room: str, identity: str, metadata: str = "{}") -> str:
    """
    Génère un token JWT valide pour LiveKit
    """
    # Structure du token LiveKit
    claims = {
        "iss": API_KEY,  # Issuer
        "sub": identity,  # Subject (identity)
        "iat": int(time.time()),  # Issued at
        "exp": int(time.time()) + 86400,  # Expiration (24h)
        "nbf": int(time.time()),  # Not before
        "jti": f"{identity}-{int(time.time())}",  # JWT ID
        "video": {
            "room": room,
            "roomJoin": True,
            "canPublish": True,
            "canSubscribe": True,
            "canPublishData": True,
            "canPublishSources": ["camera", "microphone", "screen_share"],
            "hidden": False,
            "recorder": False
        },
        "metadata": metadata
    }
    
    # Générer le token JWT avec le secret
    token = jwt.encode(claims, API_SECRET, algorithm="HS256")
    
    return token

@app.get("/health")
async def health():
    """Endpoint de santé"""
    return {"status": "healthy", "service": "livekit-token-service"}

@app.post("/token", response_model=TokenResponse)
async def create_token(request: TokenRequest):
    """
    Génère un token d'accès pour LiveKit
    Supporte l'ancien et le nouveau format
    """
    try:
        # Déterminer room et identity selon le format
        room = request.room or request.room_name
        identity = request.identity or request.participant_name
        
        # Validation
        if not room or not identity:
            raise HTTPException(
                status_code=422,
                detail="room/room_name et identity/participant_name sont requis"
            )
        
        # Gérer metadata (string ou dict)
        if isinstance(request.metadata, dict):
            metadata_str = json.dumps(request.metadata)
        else:
            metadata_str = request.metadata
        
        logger.info(f"Generating token for room: {room}, identity: {identity}")
        
        token = generate_token(
            room=room,
            identity=identity,
            metadata=metadata_str
        )
        
        return TokenResponse(
            token=token,
            url=LIVEKIT_URL
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating token: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/token", response_model=TokenResponse)
async def create_token_api(request: TokenRequest):
    """
    Alias pour l'endpoint /token (compatibilité)
    """
    return await create_token(request)

@app.post("/generate-token", response_model=TokenResponse)
async def generate_token_endpoint(request: TokenRequest):
    """
    Endpoint /generate-token pour compatibilité avec le frontend Flutter
    """
    return await create_token(request)

@app.get("/")
async def root():
    """Endpoint racine"""
    return {
        "service": "LiveKit Token Service",
        "version": "1.0.0",
        "endpoints": [
            "/health",
            "/token",
            "/api/token",
            "/generate-token"
        ]
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8004"))
    uvicorn.run(app, host="0.0.0.0", port=port)