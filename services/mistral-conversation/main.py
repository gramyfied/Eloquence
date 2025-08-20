#!/usr/bin/env python3
"""
Service Mistral Scaleway API
Wrapper pour l'API Mistral hébergée sur Scaleway
"""

import os
import json
import logging
import asyncio
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, asdict
import time

import aiohttp
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration
SCALEWAY_MISTRAL_URL = os.getenv("SCALEWAY_MISTRAL_URL", "https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1")
MISTRAL_API_KEY = os.getenv("MISTRAL_API_KEY")
MISTRAL_MODEL = os.getenv("MISTRAL_MODEL", "mistral-nemo-instruct-2407")

# Modèles Pydantic
class ChatMessage(BaseModel):
    role: str
    content: str

class ChatCompletionRequest(BaseModel):
    model: Optional[str] = None
    messages: List[ChatMessage]
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 500
    stream: Optional[bool] = False
    # Champs optionnels OpenAI‑compat (outils, options de stream, etc.)
    tools: Optional[Any] = None
    stream_options: Optional[Dict[str, Any]] = None

    class Config:
        extra = "allow"  # tolérer d'autres champs pour compatibilité

class UsageInfo(BaseModel):
    prompt_tokens: Optional[int] = 0
    completion_tokens: Optional[int] = 0
    total_tokens: Optional[int] = 0
    prompt_tokens_details: Optional[int] = None
    
    class Config:
        extra = "allow"  # Permet des champs supplémentaires

class ChatCompletionResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: List[Dict[str, Any]]
    usage: UsageInfo
    
    class Config:
        extra = "allow"  # Permet des champs supplémentaires

@dataclass
class ServiceHealth:
    is_healthy: bool
    last_check: float
    response_time: float
    error_message: Optional[str] = None
    consecutive_failures: int = 0

class ScalewayMistralService:
    """Service wrapper pour l'API Mistral Scaleway"""
    
    def __init__(self):
        self.base_url = SCALEWAY_MISTRAL_URL
        self.api_key = MISTRAL_API_KEY
        self.model = MISTRAL_MODEL
        
        if not self.api_key:
            raise ValueError("MISTRAL_API_KEY est requis")
        
        self.health_status = ServiceHealth(
            is_healthy=True,
            last_check=time.time(),
            response_time=0.0
        )
        
        logger.info(f"🚀 Service Mistral Scaleway initialisé")
        logger.info(f"📍 Base URL: {self.base_url}")
        logger.info(f"🤖 Modèle: {self.model}")
    
    def _normalize_messages(self, msgs: List[ChatMessage]) -> List[ChatMessage]:
        """Assure l'alternance system/(user|assistant) en fusionnant les rôles consécutifs
        et en supprimant un éventuel assistant en tête après system.
        """
        if not msgs:
            return []
        # Copie profonde simple
        norm: List[ChatMessage] = []
        for m in msgs:
            if not norm:
                norm.append(ChatMessage(role=m.role, content=m.content))
                continue
            last = norm[-1]
            if m.role == last.role:
                # Fusionner le contenu des messages consécutifs de même rôle
                sep = "\n\n---\n"
                norm[-1] = ChatMessage(role=last.role, content=f"{last.content}{sep}{m.content}")
            else:
                norm.append(ChatMessage(role=m.role, content=m.content))

        # Si on a system puis assistant en tête → intégrer l'assistant dans system
        if len(norm) >= 2 and norm[0].role == "system" and norm[1].role == "assistant":
            merged = ChatMessage(
                role="system",
                content=f"{norm[0].content}\n\n[Note: assistant prefill supprimé] {norm[1].content}"
            )
            norm = [merged] + norm[2:]

        # Vérifier alternance stricte après system (si présent)
        start_idx = 1 if norm and norm[0].role == "system" else 0
        fixed: List[ChatMessage] = norm[:start_idx]
        expected = "user"
        for i in range(start_idx, len(norm)):
            m = norm[i]
            if m.role != expected:
                # Convertir en rôle attendu en conservant le contenu
                fixed.append(ChatMessage(role=expected, content=m.content))
            else:
                fixed.append(m)
            # alterner
            expected = "assistant" if expected == "user" else "user"

        return fixed

    async def chat_completion(self, request: ChatCompletionRequest) -> ChatCompletionResponse:
        """Génère une réponse via l'API Scaleway Mistral"""
        
        start_time = time.time()
        
        try:
            # Utiliser le modèle configuré si non spécifié
            model = request.model or self.model
            
            # Normaliser les messages pour respecter l'alternance stricte
            normalized_msgs = self._normalize_messages(request.messages)

            # Préparer la requête pour Scaleway
            payload: Dict[str, Any] = {
                "model": model,
                "messages": [{"role": msg.role, "content": msg.content} for msg in normalized_msgs],
                "temperature": request.temperature,
                "max_tokens": request.max_tokens,
                # On traitera le streaming ci-dessous (FastAPI StreamingResponse)
                "stream": bool(request.stream),
            }
            # Transférer les champs OpenAI‑compat si présents
            if request.tools is not None:
                payload["tools"] = request.tools
            if request.stream_options is not None:
                payload["stream_options"] = request.stream_options
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            logger.info(f"🔵 [SCALEWAY] Envoi requête - Modèle: {model}, Messages: {len(payload['messages'])}, stream={payload['stream']}")
            logger.debug(f"🔍 [SCALEWAY] Payload: {payload}")
            
            # Appel à l'API Scaleway
            # Important: pour le streaming SSE, ne pas imposer de timeout total afin d'éviter
            # une fermeture prématurée du flux (qui provoque des incomplete chunked read côté client).
            # On protège uniquement la connexion; la lecture du socket est illimitée.
            timeout = aiohttp.ClientTimeout(total=None, connect=10, sock_connect=10, sock_read=None)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                if payload["stream"]:
                    # Compatibilité LiveKit/OpenAI: certaines combinaisons (tools, stream_options)
                    # ne sont pas supportées en stream côté Scaleway. On appelle en non-stream,
                    # puis on renvoie un flux SSE synthétique conforme OpenAI.
                    synth_start = time.time()
                    non_stream_payload = dict(payload)
                    non_stream_payload["stream"] = False
                    # Supprimer stream_options non supporté côté Scaleway en non-stream
                    non_stream_payload.pop("stream_options", None)
                    async with session.post(
                        f"{self.base_url}/chat/completions",
                        json=non_stream_payload,
                        headers=headers
                    ) as response:
                        processing_time = time.time() - start_time
                        if response.status != 200:
                            error_text = await response.text()
                            self._record_failure(f"http_{response.status}", processing_time)
                            logger.error(f"❌ [SCALEWAY] Erreur HTTP {response.status} (compat-stream): {error_text}")
                            raise HTTPException(status_code=response.status, detail=error_text)

                        data = await response.json()
                        self._record_success(processing_time)
                        logger.info(f"✅ [SCALEWAY] Réponse non-stream en {processing_time:.2f}s → renvoi SSE synthétique")

                        # Extraire le contenu assistant
                        choice = (data.get("choices") or [{}])[0]
                        message = choice.get("message") or {}
                        full_content = message.get("content", "")
                        created_ts = int(time.time())

                        # Générateur SSE synthétique minimalement compatible OpenAI
                        async def synth_sse():
                            try:
                                # 1) Premier chunk avec delta role + contenu complet (acceptable pour la plupart des clients)
                                chunk_1 = {
                                    "id": data.get("id", f"chatcmpl-{created_ts}"),
                                    "object": "chat.completion.chunk",
                                    "created": created_ts,
                                    "model": model,
                                    "choices": [
                                        {
                                            "index": 0,
                                            "delta": {"role": "assistant", "content": full_content},
                                            "finish_reason": None,
                                        }
                                    ],
                                }
                                yield (f"data: {json.dumps(chunk_1, ensure_ascii=False)}\n\n").encode("utf-8")

                                # 2) Chunk de fin
                                chunk_2 = {
                                    "id": data.get("id", f"chatcmpl-{created_ts}"),
                                    "object": "chat.completion.chunk",
                                    "created": created_ts,
                                    "model": model,
                                    "choices": [
                                        {
                                            "index": 0,
                                            "delta": {},
                                            "finish_reason": "stop",
                                        }
                                    ],
                                }
                                yield (f"data: {json.dumps(chunk_2, ensure_ascii=False)}\n\n").encode("utf-8")

                                # 3) Fin officielle du flux SSE
                                yield b"data: [DONE]\n\n"
                            except asyncio.CancelledError:
                                raise
                            except Exception as e:
                                logger.warning(f"⚠️ [SSE-SYNTH] Relais synthétique interrompu: {e}")
                                return

                        return StreamingResponse(
                            synth_sse(),
                            media_type="text/event-stream",
                            headers={
                                "Cache-Control": "no-cache",
                                "Connection": "keep-alive",
                                "X-Accel-Buffering": "no",
                            },
                        )
                else:
                    # Assainir : si non-stream, retirer d'éventuelles stream_options envoyées par le client
                    if not payload.get("stream"):
                        payload.pop("stream_options", None)
                    # Mode non-streaming: réponse JSON classique
                    async with session.post(
                        f"{self.base_url}/chat/completions",
                        json=payload,
                        headers=headers
                    ) as response:
                        processing_time = time.time() - start_time
                        if response.status == 200:
                            result_data = await response.json()
                            self._record_success(processing_time)
                            logger.info(f"✅ [SCALEWAY] Réponse reçue en {processing_time:.2f}s")

                            usage_data = result_data.get("usage", {})
                            usage_info = UsageInfo(
                                prompt_tokens=usage_data.get("prompt_tokens", 0),
                                completion_tokens=usage_data.get("completion_tokens", 0),
                                total_tokens=usage_data.get("total_tokens", 0),
                                prompt_tokens_details=usage_data.get("prompt_tokens_details")
                            )
                            chat_response = ChatCompletionResponse(
                                id=result_data.get("id", f"chat-{int(time.time())}"),
                                created=int(time.time()),
                                model=model,
                                choices=result_data.get("choices", []),
                                usage=usage_info
                            )
                            return chat_response
                        else:
                            error_text = await response.text()
                            self._record_failure(f"http_{response.status}", processing_time)
                            logger.error(f"❌ [SCALEWAY] Erreur HTTP {response.status}: {error_text}")
                            raise HTTPException(status_code=response.status, detail=f"Erreur API Scaleway: {error_text}")
        
        except aiohttp.ClientError as e:
            processing_time = time.time() - start_time
            self._record_failure("network_error", processing_time)
            logger.error(f"❌ [SCALEWAY] Erreur réseau: {e}")
            raise HTTPException(status_code=502, detail=f"Erreur réseau: {str(e)}")
        except HTTPException as e:
            # Propager les erreurs HTTP (ex: 400 en compat‑stream) sans les convertir en 500
            raise e
        except Exception as e:
            processing_time = time.time() - start_time
            self._record_failure("unexpected_error", processing_time)
            logger.error(f"❌ [SCALEWAY] Erreur inattendue: {e}")
            raise HTTPException(status_code=500, detail=f"Erreur interne: {str(e)}")
    
    async def health_check(self) -> Dict[str, Any]:
        """Vérifie la santé du service"""
        
        start_time = time.time()
        
        try:
            # Test simple avec un message minimal
            test_messages = [
                ChatMessage(role="system", content="Tu es un assistant IA."),
                ChatMessage(role="user", content="Dis juste 'OK'")
            ]
            
            test_request = ChatCompletionRequest(
                messages=test_messages,
                max_tokens=10,
                temperature=0.1
            )
            
            response = await self.chat_completion(test_request)
            processing_time = time.time() - start_time
            
            return {
                "status": "healthy",
                "response_time": processing_time,
                "model": self.model,
                "base_url": self.base_url,
                "test_response_length": len(response.choices[0]["message"]["content"]) if response.choices else 0
            }
        
        except Exception as e:
            processing_time = time.time() - start_time
            logger.error(f"❌ [HEALTH] Check échoué: {e}")
            
            return {
                "status": "unhealthy",
                "error": str(e),
                "response_time": processing_time,
                "model": self.model,
                "base_url": self.base_url
            }
    
    def _record_success(self, processing_time: float):
        """Enregistre un succès"""
        self.health_status.is_healthy = True
        self.health_status.last_check = time.time()
        self.health_status.response_time = processing_time
        self.health_status.error_message = None
        self.health_status.consecutive_failures = 0
    
    def _record_failure(self, error_type: str, processing_time: float):
        """Enregistre un échec"""
        self.health_status.consecutive_failures += 1
        self.health_status.last_check = time.time()
        self.health_status.response_time = processing_time
        self.health_status.error_message = error_type
        
        # Marquer comme non sain après 3 échecs consécutifs
        if self.health_status.consecutive_failures >= 3:
            self.health_status.is_healthy = False
            logger.warning(f"⚠️ [HEALTH] Service marqué non sain après {self.health_status.consecutive_failures} échecs")
    
    def get_status(self) -> Dict[str, Any]:
        """Retourne le statut du service"""
        return {
            "service_name": "Scaleway Mistral API",
            "health": asdict(self.health_status),
            "config": {
                "base_url": self.base_url,
                "model": self.model,
                "has_api_key": bool(self.api_key)
            }
        }

# Initialisation du service
try:
    mistral_service = ScalewayMistralService()
    logger.info("✅ Service Mistral Scaleway prêt")
except Exception as e:
    logger.error(f"❌ Échec initialisation service Mistral: {e}")
    mistral_service = None

# API FastAPI
app = FastAPI(
    title="Scaleway Mistral API Service",
    description="Service wrapper pour l'API Mistral hébergée sur Scaleway",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_endpoint():
    """Endpoint de santé"""
    if not mistral_service:
        raise HTTPException(status_code=503, detail="Service non initialisé")
    
    return await mistral_service.health_check()

@app.get("/status")
async def status_endpoint():
    """Endpoint de statut du service"""
    if not mistral_service:
        raise HTTPException(status_code=503, detail="Service non initialisé")
    
    return mistral_service.get_status()

@app.post("/v1/chat/completions")
async def chat_completions(request: ChatCompletionRequest):
    """Endpoint principal pour les completions de chat"""
    if not mistral_service:
        raise HTTPException(status_code=503, detail="Service non initialisé")
    
    try:
        # Si stream demandé, la méthode retournera une StreamingResponse
        response = await mistral_service.chat_completion(request)
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur dans chat_completions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """Endpoint racine avec informations du service"""
    return {
        "service": "Scaleway Mistral API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "status": "/status",
            "chat_completions": "/v1/chat/completions"
        }
    }

if __name__ == "__main__":
    logger.info("🚀 Démarrage du service Mistral Scaleway")
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        log_level="info"
    )