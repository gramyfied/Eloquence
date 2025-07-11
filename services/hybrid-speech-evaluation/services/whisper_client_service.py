#!/usr/bin/env python3
"""
Service Client Whisper Large-v3-Turbo
=====================================

Client pour communiquer avec le service Whisper Docker existant (port 8001)
Intègre la transcription de haute précision dans l'architecture hybride
"""

import aiohttp
import asyncio
import logging
import tempfile
import os
from typing import Dict, Any, Optional, BinaryIO
from dataclasses import dataclass
import time

logger = logging.getLogger(__name__)

@dataclass
class WhisperResult:
    """Résultat d'une transcription Whisper"""
    text: str
    language: str
    language_probability: float
    duration: float
    transcription_time: float
    model: str
    metrics: Dict[str, Any]

class WhisperClientService:
    """
    Client pour le service Whisper Large-v3-Turbo existant
    Communique avec le Docker Whisper sur le port 8001
    """
    
    def __init__(self, whisper_url: str = "http://whisper-stt:8001"):
        self.whisper_url = whisper_url
        self.session: Optional[aiohttp.ClientSession] = None
        self.is_initialized = False
        self.metrics = {
            "total_requests": 0,
            "successful_transcriptions": 0,
            "failed_transcriptions": 0,
            "avg_transcription_time": 0.0,
            "total_audio_duration": 0.0
        }
        
    async def initialize(self):
        """Initialise le client HTTP et teste la connexion"""
        try:
            logger.info(f"🔗 Initialisation du client Whisper: {self.whisper_url}")
            
            # Créer la session HTTP avec timeout approprié
            timeout = aiohttp.ClientTimeout(total=300)  # 5 minutes pour les gros fichiers
            self.session = aiohttp.ClientSession(timeout=timeout)
            
            # Test de connexion au service Whisper
            await self._test_connection()
            
            self.is_initialized = True
            logger.info("✅ Client Whisper initialisé avec succès")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de l'initialisation du client Whisper: {e}")
            raise
    
    async def _test_connection(self):
        """Teste la connexion au service Whisper"""
        try:
            async with self.session.get(f"{self.whisper_url}/health") as response:
                if response.status == 200:
                    health_data = await response.json()
                    logger.info(f"🎯 Service Whisper détecté: {health_data}")
                    return True
                else:
                    raise Exception(f"Service Whisper non accessible, status: {response.status}")
                    
        except Exception as e:
            logger.error(f"❌ Impossible de se connecter au service Whisper: {e}")
            raise
    
    async def transcribe_audio(self, audio_data: bytes, filename: str = "audio.wav") -> WhisperResult:
        """
        Transcrit un fichier audio via le service Whisper existant
        
        Args:
            audio_data: Données audio en bytes
            filename: Nom du fichier (pour le debug)
            
        Returns:
            WhisperResult: Résultat de la transcription
        """
        if not self.is_initialized:
            raise Exception("Client Whisper non initialisé")
            
        start_time = time.time()
        self.metrics["total_requests"] += 1
        
        try:
            logger.info(f"🎤 Transcription Whisper démarrée pour: {filename}")
            
            # Préparer les données multipart
            data = aiohttp.FormData()
            data.add_field(
                'audio',
                audio_data,
                filename=filename,
                content_type='audio/wav'
            )
            
            # Envoyer la requête au service Whisper existant
            async with self.session.post(
                f"{self.whisper_url}/transcribe",
                data=data
            ) as response:
                
                if response.status == 200:
                    result_json = await response.json()
                    transcription_time = time.time() - start_time
                    
                    # Convertir la réponse en WhisperResult
                    whisper_result = WhisperResult(
                        text=result_json.get("text", ""),
                        language=result_json.get("language", "fr"),
                        language_probability=result_json.get("language_probability", 0.0),
                        duration=result_json.get("duration", 0.0),
                        transcription_time=result_json.get("transcription_time", transcription_time),
                        model=result_json.get("model", "whisper-large-v3-turbo"),
                        metrics=result_json.get("metrics", {})
                    )
                    
                    # Mettre à jour les métriques
                    self._update_metrics(whisper_result, success=True)
                    
                    logger.info(f"✅ Transcription réussie en {transcription_time:.2f}s: '{whisper_result.text[:50]}...'")
                    return whisper_result
                    
                else:
                    error_text = await response.text()
                    raise Exception(f"Erreur Whisper HTTP {response.status}: {error_text}")
                    
        except Exception as e:
            self.metrics["failed_transcriptions"] += 1
            logger.error(f"❌ Erreur lors de la transcription Whisper: {e}")
            raise
    
    async def transcribe_audio_file(self, file_path: str) -> WhisperResult:
        """
        Transcrit un fichier audio depuis le système de fichiers
        
        Args:
            file_path: Chemin vers le fichier audio
            
        Returns:
            WhisperResult: Résultat de la transcription
        """
        try:
            with open(file_path, 'rb') as audio_file:
                audio_data = audio_file.read()
                
            filename = os.path.basename(file_path)
            return await self.transcribe_audio(audio_data, filename)
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la lecture du fichier audio {file_path}: {e}")
            raise
    
    async def transcribe_audio_stream(self, audio_stream: BinaryIO, filename: str = "stream.wav") -> WhisperResult:
        """
        Transcrit un flux audio
        
        Args:
            audio_stream: Flux audio binaire
            filename: Nom du fichier pour le debug
            
        Returns:
            WhisperResult: Résultat de la transcription
        """
        try:
            audio_data = audio_stream.read()
            return await self.transcribe_audio(audio_data, filename)
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la transcription du flux audio: {e}")
            raise
    
    def _update_metrics(self, result: WhisperResult, success: bool):
        """Met à jour les métriques internes"""
        if success:
            self.metrics["successful_transcriptions"] += 1
            self.metrics["total_audio_duration"] += result.duration
            
            # Calcul de la moyenne mobile du temps de transcription
            total_success = self.metrics["successful_transcriptions"]
            current_avg = self.metrics["avg_transcription_time"]
            
            self.metrics["avg_transcription_time"] = (
                (current_avg * (total_success - 1) + result.transcription_time) / total_success
            )
    
    async def health_check(self) -> Dict[str, Any]:
        """Vérifie la santé du service Whisper"""
        try:
            if not self.session:
                return {"status": "not_initialized", "error": "Session non créée"}
                
            async with self.session.get(f"{self.whisper_url}/health") as response:
                if response.status == 200:
                    service_health = await response.json()
                    return {
                        "status": "ready",
                        "whisper_service": service_health,
                        "client_metrics": self.metrics
                    }
                else:
                    return {
                        "status": "error",
                        "error": f"Service Whisper HTTP {response.status}"
                    }
                    
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }
    
    async def get_metrics(self) -> Dict[str, Any]:
        """Retourne les métriques du client"""
        return {
            "client_metrics": self.metrics,
            "whisper_url": self.whisper_url,
            "is_initialized": self.is_initialized,
            "success_rate": (
                self.metrics["successful_transcriptions"] / max(1, self.metrics["total_requests"]) * 100
            )
        }
    
    async def cleanup(self):
        """Nettoie les ressources du client"""
        try:
            if self.session:
                await self.session.close()
                logger.info("🔄 Session HTTP Whisper fermée")
                
            self.is_initialized = False
            logger.info("✅ Client Whisper nettoyé")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors du nettoyage du client Whisper: {e}")