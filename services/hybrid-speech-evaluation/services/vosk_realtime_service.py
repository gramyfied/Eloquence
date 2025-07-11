#!/usr/bin/env python3
"""
Service VOSK Temps Réel
=======================

Service de reconnaissance vocale temps réel utilisant VOSK
Fournit un feedback immédiat pendant l'enregistrement via WebSocket
"""

import asyncio
import json
import logging
import time
import wave
import tempfile
import os
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
import numpy as np

# Import VOSK (à installer via pip install vosk)
try:
    import vosk
except ImportError:
    vosk = None
    logging.warning("VOSK non installé - pip install vosk requis")

logger = logging.getLogger(__name__)

@dataclass
class VoskSession:
    """Session VOSK pour une connexion WebSocket"""
    session_id: str
    recognizer: Any  # vosk.KaldiRecognizer
    model_info: Dict[str, Any]
    start_time: float
    audio_chunks: List[bytes]
    partial_results: List[str]
    confidence_scores: List[float]
    total_audio_duration: float = 0.0
    is_recording: bool = False

@dataclass
class ProsodyMetrics:
    """Métriques prosodiques calculées en temps réel"""
    words_per_minute: float
    pause_count: int
    average_pause_duration: float
    confidence_score: float
    speech_ratio: float  # Ratio parole/silence
    timestamp: float

class VoskRealtimeService:
    """
    Service de reconnaissance vocale temps réel avec VOSK
    Optimisé pour le feedback instantané en français
    """
    
    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or "/app/models/vosk-model-fr-0.22"
        self.model: Optional[vosk.Model] = None
        self.is_initialized = False
        self.active_sessions: Dict[str, VoskSession] = {}
        self.metrics = {
            "total_sessions": 0,
            "active_sessions": 0,
            "total_audio_processed": 0.0,
            "avg_confidence": 0.0,
            "recognition_errors": 0
        }
        
    async def initialize(self):
        """Initialise le modèle VOSK français"""
        try:
            if not vosk:
                raise Exception("VOSK non installé - exécutez: pip install vosk")
                
            logger.info(f"🤖 Chargement du modèle VOSK français: {self.model_path}")
            
            # Vérifier si le modèle existe
            if not os.path.exists(self.model_path):
                # Télécharger le modèle français si nécessaire
                await self._download_french_model()
            
            # Charger le modèle VOSK
            self.model = vosk.Model(self.model_path)
            
            # Test rapide du modèle
            test_recognizer = vosk.KaldiRecognizer(self.model, 16000)
            test_result = test_recognizer.AcceptWaveform(b'\x00' * 3200)  # Test avec du silence
            
            self.is_initialized = True
            logger.info("✅ Service VOSK initialisé avec succès")
            logger.info(f"🎯 Modèle français prêt pour reconnaissance temps réel")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de l'initialisation VOSK: {e}")
            raise
    
    async def _download_french_model(self):
        """Télécharge le modèle VOSK français si nécessaire"""
        try:
            import urllib.request
            import zipfile
            
            model_url = "https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip"
            model_dir = os.path.dirname(self.model_path)
            
            logger.info(f"📥 Téléchargement du modèle VOSK français...")
            
            # Créer le répertoire des modèles
            os.makedirs(model_dir, exist_ok=True)
            
            # Télécharger et extraire
            with tempfile.NamedTemporaryFile(suffix='.zip') as tmp_file:
                urllib.request.urlretrieve(model_url, tmp_file.name)
                
                with zipfile.ZipFile(tmp_file.name, 'r') as zip_file:
                    zip_file.extractall(model_dir)
                    
            logger.info("✅ Modèle VOSK français téléchargé avec succès")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors du téléchargement du modèle: {e}")
            raise
    
    async def create_session(self, session_id: str) -> Dict[str, Any]:
        """Crée une nouvelle session VOSK"""
        try:
            if not self.is_initialized:
                raise Exception("Service VOSK non initialisé")
                
            logger.info(f"📱 Création session VOSK: {session_id}")
            
            # Créer le reconnaisseur avec taux d'échantillonnage 16kHz
            recognizer = vosk.KaldiRecognizer(self.model, 16000)
            
            # Configuration pour les résultats partiels
            recognizer.SetWords(True)
            recognizer.SetPartialWords(True)
            
            # Créer la session
            session = VoskSession(
                session_id=session_id,
                recognizer=recognizer,
                model_info={
                    "model_name": "vosk-model-fr-0.22",
                    "language": "fr",
                    "sample_rate": 16000,
                    "features": ["partial_results", "word_timestamps", "confidence_scores"]
                },
                start_time=time.time(),
                audio_chunks=[],
                partial_results=[],
                confidence_scores=[]
            )
            
            self.active_sessions[session_id] = session
            self.metrics["total_sessions"] += 1
            self.metrics["active_sessions"] = len(self.active_sessions)
            
            logger.info(f"✅ Session VOSK créée: {session_id}")
            
            return {
                "session_id": session_id,
                "model_info": session.model_info,
                "status": "ready"
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur création session VOSK {session_id}: {e}")
            raise
    
    async def process_audio_chunk(self, session_id: str, audio_data: bytes) -> Dict[str, Any]:
        """
        Traite un chunk audio en temps réel avec VOSK
        
        Args:
            session_id: ID de la session
            audio_data: Données audio brutes (16kHz, mono, 16-bit)
            
        Returns:
            Dict contenant les résultats partiels et métriques
        """
        try:
            if session_id not in self.active_sessions:
                raise Exception(f"Session {session_id} introuvable")
                
            session = self.active_sessions[session_id]
            chunk_start_time = time.time()
            
            # Stocker le chunk audio
            session.audio_chunks.append(audio_data)
            
            # Calculer la durée du chunk (16kHz, mono, 16-bit = 2 bytes par échantillon)
            chunk_duration = len(audio_data) / (16000 * 2)
            session.total_audio_duration += chunk_duration
            
            # Traitement VOSK en temps réel
            try:
                # AcceptWaveform retourne True si une phrase complète est détectée
                is_final = session.recognizer.AcceptWaveform(audio_data)
                
                # Obtenir le résultat partiel
                if is_final:
                    # Résultat final pour cette phrase
                    result_json = session.recognizer.Result()
                    result = json.loads(result_json)
                    final_text = result.get("text", "")
                    confidence = self._calculate_confidence(result)
                    
                    logger.info(f"🎯 VOSK phrase finale: '{final_text}' (conf: {confidence:.2f})")
                    
                    return {
                        "type": "final",
                        "text": final_text,
                        "partial": "",
                        "confidence": confidence,
                        "timestamp": chunk_start_time,
                        "prosody_metrics": await self._calculate_prosody_metrics(session),
                        "session_duration": time.time() - session.start_time
                    }
                else:
                    # Résultat partiel en cours
                    partial_json = session.recognizer.PartialResult()
                    partial = json.loads(partial_json)
                    partial_text = partial.get("partial", "")
                    
                    if partial_text:  # Ne retourner que si du texte est détecté
                        session.partial_results.append(partial_text)
                        confidence = 0.8  # Confiance par défaut pour résultats partiels
                        
                        return {
                            "type": "partial",
                            "text": "",
                            "partial": partial_text,
                            "confidence": confidence,
                            "timestamp": chunk_start_time,
                            "prosody_metrics": await self._calculate_prosody_metrics(session),
                            "session_duration": time.time() - session.start_time
                        }
                    else:
                        # Silence ou bruit - retourner métriques de base
                        return {
                            "type": "silence",
                            "text": "",
                            "partial": "",
                            "confidence": 0.0,
                            "timestamp": chunk_start_time,
                            "prosody_metrics": await self._calculate_prosody_metrics(session),
                            "session_duration": time.time() - session.start_time
                        }
                        
            except Exception as vosk_error:
                logger.error(f"❌ Erreur traitement VOSK: {vosk_error}")
                self.metrics["recognition_errors"] += 1
                
                return {
                    "type": "error",
                    "text": "",
                    "partial": "",
                    "confidence": 0.0,
                    "timestamp": chunk_start_time,
                    "error": str(vosk_error),
                    "prosody_metrics": {},
                    "session_duration": time.time() - session.start_time
                }
                
        except Exception as e:
            logger.error(f"❌ Erreur process_audio_chunk {session_id}: {e}")
            raise
    
    def _calculate_confidence(self, vosk_result: Dict[str, Any]) -> float:
        """Calcule le score de confiance à partir du résultat VOSK"""
        try:
            if "result" in vosk_result and vosk_result["result"]:
                # Moyenne des confidences des mots individuels
                word_confidences = [word.get("conf", 0.0) for word in vosk_result["result"]]
                if word_confidences:
                    return sum(word_confidences) / len(word_confidences)
                    
            return 0.5  # Confiance par défaut
            
        except Exception:
            return 0.5
    
    async def _calculate_prosody_metrics(self, session: VoskSession) -> Dict[str, Any]:
        """Calcule les métriques prosodiques en temps réel"""
        try:
            current_time = time.time()
            session_duration = current_time - session.start_time
            
            # Calculer WPM basé sur les résultats partiels
            total_words = sum(len(result.split()) for result in session.partial_results)
            wpm = (total_words / (session_duration / 60)) if session_duration > 0 else 0
            
            # Estimation du ratio parole/silence
            speech_ratio = min(1.0, session.total_audio_duration / session_duration) if session_duration > 0 else 0
            
            # Nombre de pauses estimées (basé sur les gaps dans les résultats partiels)
            pause_count = max(0, len(session.partial_results) - 1)
            avg_pause_duration = (session_duration - session.total_audio_duration) / max(1, pause_count)
            
            # Score de confiance moyen
            avg_confidence = sum(session.confidence_scores) / max(1, len(session.confidence_scores))
            
            return {
                "words_per_minute": round(wpm, 1),
                "pause_count": pause_count,
                "average_pause_duration": round(avg_pause_duration, 2),
                "confidence_score": round(avg_confidence, 2),
                "speech_ratio": round(speech_ratio, 2),
                "session_duration": round(session_duration, 1),
                "total_words": total_words,
                "timestamp": current_time
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur calcul métriques prosodiques: {e}")
            return {}
    
    async def start_recording(self, session_id: str):
        """Démarre l'enregistrement pour une session"""
        if session_id in self.active_sessions:
            self.active_sessions[session_id].is_recording = True
            logger.info(f"🎙️ Enregistrement démarré pour session: {session_id}")
    
    async def finalize_session(self, session_id: str) -> Dict[str, Any]:
        """Finalise une session et retourne le résultat complet"""
        try:
            if session_id not in self.active_sessions:
                raise Exception(f"Session {session_id} introuvable")
                
            session = self.active_sessions[session_id]
            session.is_recording = False
            
            # Obtenir le résultat final de VOSK
            final_result_json = session.recognizer.FinalResult()
            final_result = json.loads(final_result_json)
            final_text = final_result.get("text", "")
            
            # Calculer les métriques finales
            final_prosody = await self._calculate_prosody_metrics(session)
            
            result = {
                "session_id": session_id,
                "transcript": final_text,
                "duration": time.time() - session.start_time,
                "audio_duration": session.total_audio_duration,
                "partial_results_count": len(session.partial_results),
                "metrics": final_prosody,
                "model_info": session.model_info
            }
            
            logger.info(f"✅ Session VOSK finalisée: {session_id} - '{final_text[:50]}...'")
            return result
            
        except Exception as e:
            logger.error(f"❌ Erreur finalisation session {session_id}: {e}")
            raise
    
    async def cleanup_session(self, session_id: str):
        """Nettoie une session VOSK"""
        try:
            if session_id in self.active_sessions:
                del self.active_sessions[session_id]
                self.metrics["active_sessions"] = len(self.active_sessions)
                logger.info(f"🔄 Session VOSK nettoyée: {session_id}")
                
        except Exception as e:
            logger.error(f"❌ Erreur nettoyage session {session_id}: {e}")
    
    async def health_check(self) -> Dict[str, Any]:
        """Vérifie la santé du service VOSK"""
        return {
            "status": "ready" if self.is_initialized else "not_initialized",
            "model_path": self.model_path,
            "active_sessions": len(self.active_sessions),
            "metrics": self.metrics
        }
    
    async def get_metrics(self) -> Dict[str, Any]:
        """Retourne les métriques du service"""
        return {
            "service_metrics": self.metrics,
            "active_sessions": list(self.active_sessions.keys()),
            "model_info": {
                "path": self.model_path,
                "is_loaded": self.model is not None
            }
        }
    
    async def cleanup(self):
        """Nettoie toutes les ressources du service"""
        try:
            # Nettoyer toutes les sessions actives
            for session_id in list(self.active_sessions.keys()):
                await self.cleanup_session(session_id)
                
            self.is_initialized = False
            logger.info("✅ Service VOSK nettoyé")
            
        except Exception as e:
            logger.error(f"❌ Erreur nettoyage service VOSK: {e}")