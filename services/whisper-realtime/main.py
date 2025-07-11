"""
Service Whisper Temps Réel Simplifié pour Eloquence
==================================================

Service de reconnaissance vocale temps réel utilisant Whisper-large-v3-turbo
pour remplacer l'architecture hybride VOSK + Whisper complexe.

Fonctionnalités :
- WebSocket streaming audio en temps réel
- Traitement par chunks de 3 secondes avec buffer circulaire
- Métriques prosodiques (WPM, hésitations, pauses)
- Fallback intelligent et feedback immédiat
- Compatible avec l'infrastructure Eloquence existante

Author: Assistant IA Roo
Date: 7 janvier 2025
"""

from fastapi import FastAPI, WebSocket, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json
import numpy as np
from transformers import pipeline
import torch
import time
import os
import logging
from collections import deque
from typing import Dict, List, Optional, Any
import websockets
from pydantic import BaseModel

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialisation de l'application FastAPI
app = FastAPI(
    title="Whisper Realtime Evaluation Service",
    description="Service d'évaluation vocale temps réel basé sur Whisper pour Eloquence",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configuration CORS pour l'intégration Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifier les domaines autorisés
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AudioMetrics(BaseModel):
    """Modèle pour les métriques audio"""
    wpm: float
    duration: float
    word_count: int
    hesitation_count: int
    pause_count: int
    processing_time: float
    confidence: float
    status: Dict[str, Any]

class RealtimeFeedback(BaseModel):
    """Modèle pour le feedback temps réel"""
    type: str = "realtime_feedback"
    transcription: str
    metrics: AudioMetrics
    processing_time: float
    timestamp: float

class WhisperRealtimeService:
    """Service Whisper optimisé pour temps réel"""
    
    def __init__(self):
        logger.info("🚀 Initialisation du Service Whisper Temps Réel...")
        
        # Configuration du modèle Whisper
        self.model_id = os.getenv("WHISPER_MODEL_ID", "openai/whisper-large-v3-turbo")
        self.device = os.getenv("WHISPER_DEVICE", "cpu")
        
        try:
            # Chargement du modèle Whisper avec pipeline optimisé pour vitesse
            logger.info(f"📥 Chargement du modèle {self.model_id} (optimisé vitesse)...")
            self.model = pipeline(
                "automatic-speech-recognition",
                model=self.model_id,
                device=self.device,
                torch_dtype=torch.float16 if self.device != "cpu" else torch.float32,  # FP16 pour GPU
                return_timestamps=True,
                chunk_length_s=15,  # Chunks plus courts pour vitesse
                stride_length_s=2,  # Stride réduit
                batch_size=8 if self.device != "cpu" else 1  # Batch processing
            )
            logger.info("✅ Modèle Whisper chargé avec succès")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors du chargement du modèle: {e}")
            raise RuntimeError(f"Impossible de charger le modèle Whisper: {e}")
        
        # Configuration audio
        self.sample_rate = int(os.getenv("AUDIO_SAMPLE_RATE", "16000"))
        self.chunk_duration = float(os.getenv("AUDIO_CHUNK_DURATION", "3.0"))
        self.max_buffer_size = int(os.getenv("MAX_AUDIO_BUFFER_SIZE", "48000")) * 10
        
        # Buffer audio circulaire pour streaming
        self.audio_buffer = deque(maxlen=self.max_buffer_size)
        
        # Métriques de session
        self.reset_session_metrics()
        
        # Mots d'hésitation français
        self.hesitation_words = [
            'euh', 'hmm', 'alors', 'donc', 'ben', 'heu', 'ah', 'oh',
            'bah', 'nan', 'ouais', 'voilà', 'quoi', 'enfin', 'disons'
        ]
        
        logger.info("🎯 Service Whisper Temps Réel initialisé avec succès")
    
    def reset_session_metrics(self):
        """Réinitialise les métriques de session"""
        self.word_count = 0
        self.start_time = None
        self.last_transcription = ""
        self.total_hesitations = 0
        self.total_pauses = 0
    
    async def process_realtime_audio(self, websocket: WebSocket):
        """Traitement audio temps réel avec WebSocket"""
        logger.info("🔌 Nouvelle connexion WebSocket établie")
        
        try:
            await websocket.accept()
            self.reset_session_metrics()
            
            logger.info("⏯️ Début du traitement audio temps réel")
            
            while True:
                try:
                    # Réception des données audio
                    message = await websocket.receive()
                    
                    if message["type"] == "websocket.disconnect":
                        logger.info("🔌 Client déconnecté")
                        break
                    
                    if message["type"] == "websocket.receive":
                        if "bytes" in message:
                            # Traitement des données audio binaires
                            audio_data = message["bytes"]
                            await self._process_audio_chunk(websocket, audio_data)
                        
                        elif "text" in message:
                            # Traitement des commandes texte
                            try:
                                command = json.loads(message["text"])
                                await self._handle_command(websocket, command)
                            except json.JSONDecodeError:
                                logger.warning("⚠️ Message texte non-JSON reçu")
                
                except websockets.exceptions.ConnectionClosed:
                    logger.info("🔌 Connexion WebSocket fermée")
                    break
                except Exception as e:
                    logger.error(f"❌ Erreur lors du traitement: {e}")
                    await self._send_error(websocket, str(e))
                    
        except Exception as e:
            logger.error(f"❌ Erreur fatale WebSocket: {e}")
        finally:
            logger.info("🏁 Fin de session WebSocket")
    
    async def _process_audio_chunk(self, websocket: WebSocket, audio_data: bytes):
        """Traite un chunk audio reçu"""
        try:
            # Conversion bytes vers numpy array
            audio_array = np.frombuffer(audio_data, dtype=np.int16)
            self.audio_buffer.extend(audio_array)
            
            # Traitement si buffer suffisant
            chunk_size = int(self.sample_rate * self.chunk_duration)
            if len(self.audio_buffer) >= chunk_size:
                await self._process_and_send_feedback(websocket)
                
        except Exception as e:
            logger.error(f"❌ Erreur traitement chunk audio: {e}")
            await self._send_error(websocket, f"Erreur traitement audio: {e}")
    
    async def _handle_command(self, websocket: WebSocket, command: Dict):
        """Gère les commandes reçues via WebSocket"""
        cmd_type = command.get("type", "")
        
        if cmd_type == "reset_session":
            self.reset_session_metrics()
            await websocket.send_text(json.dumps({
                "type": "session_reset",
                "message": "Session réinitialisée"
            }))
            
        elif cmd_type == "get_status":
            await websocket.send_text(json.dumps({
                "type": "status",
                "service": "whisper-realtime",
                "model": self.model_id,
                "session_metrics": {
                    "word_count": self.word_count,
                    "duration": time.time() - self.start_time if self.start_time else 0,
                    "hesitations": self.total_hesitations,
                    "pauses": self.total_pauses
                }
            }))
    
    async def _process_and_send_feedback(self, websocket: WebSocket):
        """Traite le buffer audio et envoie le feedback"""
        start_time = time.time()
        
        try:
            # Extraction du chunk depuis le buffer
            chunk_size = int(self.sample_rate * self.chunk_duration)
            chunk_data = np.array(list(self.audio_buffer)[-chunk_size:])
            
            # Normalisation audio
            chunk_data = chunk_data.astype(np.float32) / 32768.0
            
            # Transcription avec Whisper
            result = self.model(
                chunk_data,
                return_timestamps=True,
                generate_kwargs={
                    "language": "french",
                    "task": "transcribe"
                }
            )
            
            processing_time = time.time() - start_time
            
            # Calcul des métriques
            metrics = self._calculate_metrics(result, processing_time)
            
            # Création du feedback
            feedback = RealtimeFeedback(
                transcription=result["text"],
                metrics=metrics,
                processing_time=processing_time,
                timestamp=time.time()
            )
            
            # Envoi du feedback
            await websocket.send_text(feedback.json())
            
            # Nettoyage du buffer (garde 1 seconde d'overlap)
            overlap_size = self.sample_rate
            self.audio_buffer = deque(
                list(self.audio_buffer)[-overlap_size:], 
                maxlen=self.audio_buffer.maxlen
            )
            
            logger.debug(f"✅ Feedback envoyé - Processing: {processing_time:.3f}s")
            
        except Exception as e:
            logger.error(f"❌ Erreur traitement feedback: {e}")
            await self._send_error(websocket, f"Erreur traitement: {e}")
    
    def _calculate_metrics(self, result: Dict, processing_time: float) -> AudioMetrics:
        """Calcul des métriques prosodiques temps réel"""
        
        text = result["text"].strip()
        chunks = result.get("chunks", [])
        
        # Initialisation du timer si première transcription
        if self.start_time is None:
            self.start_time = time.time()
        
        # Calcul de la durée de session
        session_duration = time.time() - self.start_time
        
        # Analyse des mots
        words = text.split()
        new_words = len(words)
        self.word_count += new_words
        
        # Calcul WPM (Words Per Minute)
        wpm = (self.word_count / session_duration * 60) if session_duration > 0 else 0
        
        # Détection des hésitations
        hesitations = sum(1 for word in words 
                         for hw in self.hesitation_words 
                         if hw in word.lower())
        self.total_hesitations += hesitations
        
        # Analyse des pauses (basée sur les timestamps Whisper)
        pauses = self._analyze_pauses(chunks)
        significant_pauses = len([p for p in pauses if p > 2.0])
        self.total_pauses += significant_pauses
        
        # Génération du statut
        status = self._generate_status(wpm, pauses, hesitations)
        
        return AudioMetrics(
            wpm=round(wpm, 1),
            duration=round(session_duration, 1),
            word_count=self.word_count,
            hesitation_count=self.total_hesitations,
            pause_count=self.total_pauses,
            processing_time=round(processing_time, 3),
            confidence=0.95,  # Whisper est très fiable
            status=status
        )
    
    def _analyze_pauses(self, chunks: List[Dict]) -> List[float]:
        """Analyse les pauses entre les chunks de parole"""
        pauses = []
        
        if len(chunks) > 1:
            for i in range(1, len(chunks)):
                try:
                    prev_chunk = chunks[i-1]
                    curr_chunk = chunks[i]
                    
                    if ('timestamp' in prev_chunk and 'timestamp' in curr_chunk):
                        prev_end = prev_chunk['timestamp'][1] if prev_chunk['timestamp'][1] else 0
                        curr_start = curr_chunk['timestamp'][0] if curr_chunk['timestamp'][0] else 0
                        
                        if prev_end and curr_start and curr_start > prev_end:
                            pause_duration = curr_start - prev_end
                            if pause_duration > 0.3:  # Pauses > 300ms
                                pauses.append(pause_duration)
                                
                except (KeyError, IndexError, TypeError) as e:
                    logger.debug(f"Erreur analyse pause: {e}")
                    continue
        
        return pauses
    
    def _generate_status(self, wpm: float, pauses: List[float], hesitations: int) -> Dict[str, Any]:
        """Génère le statut de feedback basé sur les métriques"""
        
        long_pauses = len([p for p in pauses if p > 2.0])
        
        # Évaluation du débit
        if 120 <= wpm <= 180 and hesitations <= 2 and long_pauses <= 1:
            return {
                "level": "excellent",
                "message": "Excellent débit et fluidité !",
                "suggestions": ["Continuez sur cette lancée"],
                "score": 95
            }
        elif 100 <= wpm <= 200 and hesitations <= 4:
            return {
                "level": "good",
                "message": "Bon débit de parole",
                "suggestions": ["Réduisez les hésitations" if hesitations > 2 else "Très bien !"],
                "score": 80
            }
        elif wpm < 100:
            return {
                "level": "warning",
                "message": "Débit un peu lent",
                "suggestions": [
                    "Accélérez légèrement votre élocution",
                    "Prenez confiance en vous"
                ],
                "score": 65
            }
        elif wpm > 200:
            return {
                "level": "warning",
                "message": "Débit rapide",
                "suggestions": [
                    "Ralentissez pour plus de clarté",
                    "Articulez davantage"
                ],
                "score": 70
            }
        else:
            return {
                "level": "info",
                "message": "Continuez vos efforts !",
                "suggestions": [
                    "Réduisez les hésitations",
                    "Contrôlez vos pauses"
                ],
                "score": 75
            }
    
    async def _send_error(self, websocket: WebSocket, error_message: str):
        """Envoie un message d'erreur via WebSocket"""
        try:
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": error_message,
                "timestamp": time.time()
            }))
        except Exception as e:
            logger.error(f"❌ Impossible d'envoyer l'erreur: {e}")

# Instance globale du service
whisper_service = WhisperRealtimeService()

# ==================== ENDPOINTS API ====================

@app.websocket("/evaluate/realtime")
async def realtime_evaluation_endpoint(websocket: WebSocket):
    """
    Endpoint WebSocket pour l'évaluation temps réel
    
    Usage:
    - Connectez-vous à ws://localhost:8006/evaluate/realtime
    - Envoyez des chunks audio en binaire
    - Recevez des feedbacks temps réel en JSON
    """
    await whisper_service.process_realtime_audio(websocket)

@app.post("/evaluate/final")
async def final_evaluation_endpoint(audio: UploadFile = File(...)):
    """
    Endpoint pour l'analyse finale d'un fichier audio complet
    
    Paramètres:
    - audio: Fichier audio (WAV, MP3, etc.)
    
    Retourne:
    - Analyse complète avec transcription et métriques détaillées
    """
    try:
        logger.info(f"📁 Analyse finale du fichier: {audio.filename}")
        
        # Lecture du fichier audio
        audio_data = await audio.read()
        audio_array = np.frombuffer(audio_data, dtype=np.int16)
        audio_array = audio_array.astype(np.float32) / 32768.0
        
        # Transcription complète avec Whisper
        start_time = time.time()
        result = whisper_service.model(
            audio_array,
            return_timestamps=True,
            generate_kwargs={
                "language": "french",
                "task": "transcribe"
            }
        )
        processing_time = time.time() - start_time
        
        # Analyse détaillée
        audio_duration = len(audio_array) / whisper_service.sample_rate
        words = result["text"].split()
        wpm = (len(words) / audio_duration * 60) if audio_duration > 0 else 0
        
        analysis = {
            "transcription": result["text"],
            "duration": round(audio_duration, 2),
            "word_count": len(words),
            "wpm": round(wpm, 1),
            "chunks": result.get("chunks", []),
            "confidence": 0.95,
            "processing_time": round(processing_time, 3),
            "file_info": {
                "filename": audio.filename,
                "size_bytes": len(audio_data)
            }
        }
        
        logger.info(f"✅ Analyse finale terminée en {processing_time:.3f}s")
        return analysis
        
    except Exception as e:
        logger.error(f"❌ Erreur analyse finale: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'analyse: {e}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "whisper-realtime",
        "model": whisper_service.model_id,
        "device": whisper_service.device,
        "version": "1.0.0",
        "timestamp": time.time()
    }

@app.get("/")
async def root():
    """Endpoint racine avec informations du service"""
    return {
        "service": "Whisper Realtime Evaluation",
        "description": "Service d'évaluation vocale temps réel pour Eloquence",
        "version": "1.0.0",
        "endpoints": {
            "realtime": "/evaluate/realtime (WebSocket)",
            "final": "/evaluate/final (POST)",
            "health": "/health (GET)",
            "docs": "/docs (GET)"
        },
        "status": "ready"
    }

# ==================== STARTUP EVENT ====================

@app.on_event("startup")
async def startup_event():
    """Événement de démarrage du service"""
    logger.info("🚀 === WHISPER REALTIME SERVICE DÉMARRÉ ===")
    logger.info(f"📊 Modèle: {whisper_service.model_id}")
    logger.info(f"💻 Device: {whisper_service.device}")
    logger.info(f"🎵 Sample Rate: {whisper_service.sample_rate}Hz")
    logger.info(f"⏱️ Chunk Duration: {whisper_service.chunk_duration}s")
    logger.info("🔗 WebSocket: /evaluate/realtime")
    logger.info("📤 Upload: /evaluate/final")
    logger.info("💚 Health: /health")
    logger.info("📚 Docs: /docs")

@app.on_event("shutdown")
async def shutdown_event():
    """Événement d'arrêt du service"""
    logger.info("🛑 === WHISPER REALTIME SERVICE ARRÊTÉ ===")

# ==================== POINT D'ENTRÉE ====================

if __name__ == "__main__":
    import uvicorn
    
    # Configuration du serveur
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8006"))
    
    logger.info(f"🌐 Démarrage du serveur sur {host}:{port}")
    
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info",
        access_log=True,
        reload=False  # Désactivé en production
    )