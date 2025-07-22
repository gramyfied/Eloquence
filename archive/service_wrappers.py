#!/usr/bin/env python3
"""
Wrappers des Services Existants avec Timeouts Adaptatifs
Encapsule VOSK, TTS et LiveKit pour le système de test
"""

import asyncio
import aiohttp
import requests
import tempfile
import wave
import numpy as np
import time
import json
import logging
from typing import Dict, Any, Optional, List, Union, Tuple
from dataclasses import dataclass
from pathlib import Path
import subprocess
from livekit import rtc, api
import io

logger = logging.getLogger(__name__)

@dataclass
class ServiceHealth:
    """État de santé d'un service"""
    service_name: str
    is_healthy: bool
    response_time: float
    last_check: float
    error_message: Optional[str] = None
    consecutive_failures: int = 0

@dataclass
class AdaptiveTimeout:
    """Configuration de timeout adaptatif"""
    base_timeout: float
    current_timeout: float
    max_timeout: float
    multiplier: float
    failure_count: int
    success_count: int

class RealTTSService:
    """Wrapper pour le service TTS existant avec timeouts adaptatifs"""
    
    def __init__(self, base_url: str = None):
        # Utiliser directement l'API OpenAI si une clé API est disponible
        import os
        self.api_key = os.getenv("OPENAI_API_KEY")
        if self.api_key:
            self.base_url = "https://api.openai.com"
            self.use_openai_direct = True
        else:
            self.base_url = base_url or "http://localhost:5002"
            self.use_openai_direct = False
            
        self.timeout_config = AdaptiveTimeout(
            base_timeout=5.0,
            current_timeout=5.0,
            max_timeout=30.0,
            multiplier=1.5,
            failure_count=0,
            success_count=0
        )
        self.health_status = ServiceHealth(
            service_name="OpenAI-TTS",
            is_healthy=True,
            response_time=0.0,
            last_check=0.0
        )
        self.performance_history = []
    
    async def synthesize_speech(self, text: str, voice: str = "alloy") -> Dict[str, Any]:
        """Synthétise la parole avec gestion adaptive des timeouts"""
        
        start_time = time.time()
        
        try:
            # Validation préalable
            if not text or not text.strip():
                raise ValueError("Texte vide fourni pour la synthèse")
            
            # Vérification de santé si nécessaire
            if not self.health_status.is_healthy:
                await self._check_health()
                if not self.health_status.is_healthy:
                    raise RuntimeError(f"Service TTS non disponible: {self.health_status.error_message}")
            
            # Préparer la requête
            payload = {
                "model": "tts-1",
                "input": text,
                "voice": voice,
                "response_format": "wav"
            }
            
            headers = {
                "Content-Type": "application/json"
            }
            
            # Ajouter l'autorisation seulement pour l'API OpenAI directe
            if self.use_openai_direct:
                headers["Authorization"] = f"Bearer {self.api_key}"
            
            # Exécuter la requête avec timeout adaptatif
            timeout = aiohttp.ClientTimeout(total=self.timeout_config.current_timeout)
            
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.post(
                    f"{self.base_url}/v1/audio/speech",
                    json=payload,
                    headers=headers
                ) as response:
                    
                    if response.status == 200:
                        audio_data = await response.read()
                        processing_time = time.time() - start_time
                        
                        # Analyser la qualité audio
                        quality_metrics = self._analyze_audio_quality(audio_data, text)
                        
                        # Enregistrer le succès
                        self._record_success(processing_time)
                        
                        result = {
                            'audio_data': audio_data,
                            'audio_duration': self._calculate_audio_duration(audio_data),
                            'quality_score': quality_metrics['quality_score'],
                            'synthesis_time': processing_time,
                            'text_length': len(text),
                            'voice_used': voice,
                            'signal_to_noise_ratio': quality_metrics['snr'],
                            'clarity_score': quality_metrics['clarity'],
                            'naturalness_score': quality_metrics['naturalness']
                        }
                        
                        logger.info(f"TTS synthèse réussie: {len(text)} chars -> {len(audio_data)} bytes en {processing_time:.2f}s")
                        return result
                    
                    else:
                        error_text = await response.text()
                        raise aiohttp.ClientResponseError(
                            request_info=response.request_info,
                            history=response.history,
                            status=response.status,
                            message=error_text
                        )
        
        except asyncio.TimeoutError:
            processing_time = time.time() - start_time
            self._record_failure("timeout", processing_time)
            raise RuntimeError(f"Timeout TTS après {processing_time:.1f}s")
        
        except aiohttp.ClientResponseError as e:
            processing_time = time.time() - start_time
            self._record_failure(f"http_{e.status}", processing_time)
            raise RuntimeError(f"Erreur HTTP TTS {e.status}: {e.message}")
        
        except Exception as e:
            processing_time = time.time() - start_time
            self._record_failure("unexpected", processing_time)
            raise RuntimeError(f"Erreur TTS inattendue: {str(e)}")
    
    def _get_api_key(self) -> str:
        """Récupère la clé API OpenAI"""
        return self.api_key or "fake-key-for-local-service"
    
    def _analyze_audio_quality(self, audio_data: bytes, original_text: str) -> Dict[str, float]:
        """Analyse la qualité de l'audio synthétisé"""
        
        try:
            # Analyser le format WAV
            with io.BytesIO(audio_data) as audio_stream:
                with wave.open(audio_stream, 'rb') as wav_file:
                    frames = wav_file.readframes(wav_file.getnframes())
                    sample_rate = wav_file.getframerate()
                    channels = wav_file.getnchannels()
                    sample_width = wav_file.getsampwidth()
            
            # Convertir en numpy array pour analyse
            if sample_width == 2:  # 16-bit
                audio_array = np.frombuffer(frames, dtype=np.int16)
            else:
                audio_array = np.frombuffer(frames, dtype=np.float32)
            
            # Calculer des métriques de qualité
            rms = np.sqrt(np.mean(audio_array.astype(float) ** 2))
            peak = np.max(np.abs(audio_array))
            
            # Signal to noise ratio estimé
            signal_power = np.mean(audio_array.astype(float) ** 2)
            noise_estimate = np.var(audio_array[:min(1000, len(audio_array))])  # Estimation du bruit initial
            snr = 10 * np.log10(signal_power / (noise_estimate + 1e-10)) if noise_estimate > 0 else 50.0
            
            # Score de qualité basé sur plusieurs facteurs
            quality_score = min(1.0, (rms / (peak + 1e-10)) * 2.0)  # Ratio RMS/Peak
            
            # Score de clarté basé sur la distribution d'énergie
            clarity_score = min(1.0, snr / 20.0)  # SNR normalisé
            
            # Score de naturel basé sur la longueur attendue vs réelle
            expected_duration = len(original_text) * 0.1  # ~100ms par caractère
            actual_duration = len(audio_array) / sample_rate
            naturalness_score = 1.0 - min(1.0, abs(actual_duration - expected_duration) / expected_duration)
            
            return {
                'quality_score': quality_score,
                'snr': max(0.0, min(snr, 50.0)),  # Cap SNR entre 0 et 50
                'clarity': clarity_score,
                'naturalness': naturalness_score,
                'rms_level': float(rms),
                'peak_level': float(peak),
                'sample_rate': sample_rate,
                'channels': channels
            }
        
        except Exception as e:
            logger.warning(f"Erreur analyse qualité audio: {e}")
            return {
                'quality_score': 0.5,
                'snr': 20.0,
                'clarity': 0.5,
                'naturalness': 0.5,
                'rms_level': 0.0,
                'peak_level': 0.0,
                'sample_rate': 22050,
                'channels': 1
            }
    
    def _calculate_audio_duration(self, audio_data: bytes) -> float:
        """Calcule la durée de l'audio en secondes"""
        
        try:
            with io.BytesIO(audio_data) as audio_stream:
                with wave.open(audio_stream, 'rb') as wav_file:
                    frames = wav_file.getnframes()
                    sample_rate = wav_file.getframerate()
                    return frames / sample_rate
        except:
            # Estimation fallback basée sur la taille
            return len(audio_data) / (22050 * 2)  # Estimation 22kHz, 16-bit
    
    async def _check_health(self) -> bool:
        """Vérifie la santé du service TTS"""
        
        start_time = time.time()
        
        try:
            timeout = aiohttp.ClientTimeout(total=5.0)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(f"{self.base_url}/health") as response:
                    response_time = time.time() - start_time
                    
                    if response.status == 200:
                        self.health_status.is_healthy = True
                        self.health_status.response_time = response_time
                        self.health_status.last_check = time.time()
                        self.health_status.error_message = None
                        self.health_status.consecutive_failures = 0
                        logger.info(f"Service TTS sain: {response_time:.2f}s")
                        return True
                    else:
                        raise aiohttp.ClientResponseError(
                            request_info=response.request_info,
                            history=response.history,
                            status=response.status
                        )
        
        except Exception as e:
            response_time = time.time() - start_time
            self.health_status.is_healthy = False
            self.health_status.response_time = response_time
            self.health_status.last_check = time.time()
            self.health_status.error_message = str(e)
            self.health_status.consecutive_failures += 1
            logger.error(f"Service TTS non sain: {e}")
            return False
    
    def _record_success(self, processing_time: float):
        """Enregistre un succès et ajuste les timeouts"""
        
        self.timeout_config.success_count += 1
        self.timeout_config.failure_count = 0
        
        # Réduire progressivement le timeout si performance stable
        if self.timeout_config.success_count >= 3:
            new_timeout = max(
                self.timeout_config.base_timeout,
                self.timeout_config.current_timeout * 0.9
            )
            self.timeout_config.current_timeout = new_timeout
            self.timeout_config.success_count = 0
        
        # Enregistrer les performances
        self.performance_history.append({
            'timestamp': time.time(),
            'processing_time': processing_time,
            'success': True,
            'timeout_used': self.timeout_config.current_timeout
        })
        
        # Garder seulement les 100 derniers enregistrements
        self.performance_history = self.performance_history[-100:]
    
    def _record_failure(self, error_type: str, processing_time: float):
        """Enregistre un échec et ajuste les timeouts"""
        
        self.timeout_config.failure_count += 1
        self.timeout_config.success_count = 0
        
        # Augmenter le timeout après échec
        if error_type == "timeout":
            new_timeout = min(
                self.timeout_config.max_timeout,
                self.timeout_config.current_timeout * self.timeout_config.multiplier
            )
            self.timeout_config.current_timeout = new_timeout
            logger.warning(f"Timeout TTS augmenté à {new_timeout:.1f}s après échec")
        
        # Marquer le service comme non sain après plusieurs échecs
        if self.timeout_config.failure_count >= 3:
            self.health_status.is_healthy = False
            self.health_status.error_message = f"Échecs répétés: {error_type}"
        
        # Enregistrer les performances
        self.performance_history.append({
            'timestamp': time.time(),
            'processing_time': processing_time,
            'success': False,
            'error_type': error_type,
            'timeout_used': self.timeout_config.current_timeout
        })
        
        self.performance_history = self.performance_history[-100:]
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """Retourne les statistiques de performance"""
        
        if not self.performance_history:
            return {'no_data': True}
        
        recent_history = self.performance_history[-20:]  # 20 derniers
        
        successes = [h for h in recent_history if h['success']]
        failures = [h for h in recent_history if not h['success']]
        
        return {
            'health_status': {
                'is_healthy': self.health_status.is_healthy,
                'consecutive_failures': self.health_status.consecutive_failures,
                'last_response_time': self.health_status.response_time
            },
            'timeout_config': {
                'current_timeout': self.timeout_config.current_timeout,
                'base_timeout': self.timeout_config.base_timeout,
                'max_timeout': self.timeout_config.max_timeout
            },
            'performance_metrics': {
                'total_requests': len(recent_history),
                'success_rate': len(successes) / len(recent_history) if recent_history else 0,
                'avg_response_time': sum(h['processing_time'] for h in successes) / len(successes) if successes else 0,
                'error_types': list(set(h.get('error_type', 'unknown') for h in failures))
            }
        }

class RealVoskService:
    """Wrapper pour le service VOSK existant avec timeouts adaptatifs"""
    
    def __init__(self, base_url: str = "http://localhost:2700"):
        self.base_url = base_url
        self.timeout_config = AdaptiveTimeout(
            base_timeout=10.0,
            current_timeout=10.0,
            max_timeout=60.0,
            multiplier=1.5,
            failure_count=0,
            success_count=0
        )
        self.health_status = ServiceHealth(
            service_name="VOSK-STT",
            is_healthy=True,
            response_time=0.0,
            last_check=0.0
        )
        self.confidence_threshold = 0.7
        self.performance_history = []
    
    async def transcribe_audio(self, audio_data: bytes, scenario_context: Optional[Dict] = None) -> Dict[str, Any]:
        """Transcrit l'audio avec analyse prosodique complète"""
        
        start_time = time.time()
        
        try:
            # Validation préalable
            if not audio_data:
                raise ValueError("Données audio vides")
            
            # Vérification de santé si nécessaire
            if not self.health_status.is_healthy:
                await self._check_health()
                if not self.health_status.is_healthy:
                    raise RuntimeError(f"Service VOSK non disponible: {self.health_status.error_message}")
            
            # Préparer les données pour VOSK
            audio_file_path = await self._prepare_audio_file(audio_data)
            
            try:
                # Exécuter la transcription avec timeout adaptatif
                timeout = aiohttp.ClientTimeout(total=self.timeout_config.current_timeout)
                
                async with aiohttp.ClientSession(timeout=timeout) as session:
                    
                    # Préparer les données multipart
                    data = aiohttp.FormData()
                    data.add_field('audio', open(audio_file_path, 'rb'), filename='audio.wav', content_type='audio/wav')
                    
                    if scenario_context:
                        data.add_field('scenario_type', scenario_context.get('type', ''))
                        data.add_field('scenario_context', json.dumps(scenario_context))
                    
                    async with session.post(f"{self.base_url}/analyze", data=data) as response:
                        
                        if response.status == 200:
                            result_data = await response.json()
                            processing_time = time.time() - start_time
                            
                            # Enrichir les résultats avec des métriques additionnelles
                            enriched_result = self._enrich_transcription_result(
                                result_data, audio_data, processing_time
                            )
                            
                            # Enregistrer le succès
                            confidence = enriched_result.get('confidence_score', 0.0)
                            self._record_success(processing_time, confidence)
                            
                            logger.info(f"VOSK transcription réussie: conf={confidence:.2f}, temps={processing_time:.2f}s")
                            return enriched_result
                        
                        else:
                            error_text = await response.text()
                            raise aiohttp.ClientResponseError(
                                request_info=response.request_info,
                                history=response.history,
                                status=response.status,
                                message=error_text
                            )
            
            finally:
                # Nettoyer le fichier temporaire
                Path(audio_file_path).unlink(missing_ok=True)
        
        except asyncio.TimeoutError:
            processing_time = time.time() - start_time
            self._record_failure("timeout", processing_time)
            raise RuntimeError(f"Timeout VOSK après {processing_time:.1f}s")
        
        except aiohttp.ClientResponseError as e:
            processing_time = time.time() - start_time
            self._record_failure(f"http_{e.status}", processing_time)
            raise RuntimeError(f"Erreur HTTP VOSK {e.status}: {e.message}")
        
        except Exception as e:
            processing_time = time.time() - start_time
            self._record_failure("unexpected", processing_time)
            raise RuntimeError(f"Erreur VOSK inattendue: {str(e)}")
    
    async def _prepare_audio_file(self, audio_data: bytes) -> str:
        """Prépare un fichier audio temporaire pour VOSK"""
        
        temp_file = tempfile.NamedTemporaryFile(suffix='.wav', delete=False)
        temp_file.write(audio_data)
        temp_file.close()
        
        return temp_file.name
    
    def _enrich_transcription_result(self, vosk_result: Dict, audio_data: bytes, processing_time: float) -> Dict[str, Any]:
        """Enrichit les résultats VOSK avec des métriques additionnelles"""
        
        # Récupérer les données de base de VOSK
        transcription = vosk_result.get('transcription', {})
        prosody = vosk_result.get('prosody', {})
        
        # Calculer des métriques additionnelles
        text = transcription.get('text', '')
        confidence = vosk_result.get('confidence_score', 0.0)
        
        # Métriques de qualité de transcription
        quality_metrics = self._calculate_transcription_quality(text, confidence, prosody)
        
        # Métriques de performance
        performance_metrics = {
            'processing_time': processing_time,
            'audio_size_mb': len(audio_data) / (1024 * 1024),
            'processing_rate': len(audio_data) / processing_time if processing_time > 0 else 0,
            'efficiency_score': self._calculate_efficiency_score(len(audio_data), processing_time)
        }
        
        return {
            # Données VOSK originales
            'text': text,
            'confidence': confidence,
            'words': transcription.get('words', []),
            'language': transcription.get('language', 'fr'),
            'duration': transcription.get('duration', 0.0),
            
            # Analyse prosodique
            'prosody_analysis': prosody,
            
            # Métriques enrichies
            'quality_metrics': quality_metrics,
            'performance_metrics': performance_metrics,
            
            # Scores calculés
            'confidence_score': confidence,
            'fluency_score': vosk_result.get('fluency_score', 0.0),
            'clarity_score': vosk_result.get('clarity_score', 0.0),
            'energy_score': vosk_result.get('energy_score', 0.0),
            'overall_score': vosk_result.get('overall_score', 0.0),
            
            # Méta-données
            'processing_time': processing_time,
            'service_health': self.health_status.is_healthy,
            'timeout_used': self.timeout_config.current_timeout
        }
    
    def _calculate_transcription_quality(self, text: str, confidence: float, prosody: Dict) -> Dict[str, float]:
        """Calcule des métriques de qualité de transcription"""
        
        # Qualité basée sur la longueur et cohérence du texte
        word_count = len(text.split()) if text else 0
        
        # Score de complétude
        completeness_score = min(1.0, word_count / 10.0)  # Normalisé pour ~10 mots
        
        # Score de cohérence (basé sur la présence de mots de liaison)
        coherence_indicators = ['et', 'mais', 'donc', 'car', 'parce', 'pour', 'avec']
        coherence_count = sum(1 for indicator in coherence_indicators if indicator in text.lower())
        coherence_score = min(1.0, coherence_count / 3.0)
        
        # Score de naturel (pas trop de répétitions)
        if word_count > 0:
            unique_words = len(set(text.lower().split()))
            variety_score = unique_words / word_count
        else:
            variety_score = 0.0
        
        return {
            'text_completeness': completeness_score,
            'text_coherence': coherence_score,
            'vocabulary_variety': variety_score,
            'confidence_reliability': confidence,
            'prosody_consistency': prosody.get('voice_quality', 0.0) if prosody else 0.0
        }
    
    def _calculate_efficiency_score(self, audio_size: int, processing_time: float) -> float:
        """Calcule un score d'efficacité du traitement"""
        
        # Taille de référence : 1MB par seconde d'audio
        expected_time = audio_size / (1024 * 1024)  # 1MB/s de référence
        
        if processing_time > 0:
            efficiency = expected_time / processing_time
            return min(1.0, efficiency)
        else:
            return 0.0
    
    async def _check_health(self) -> bool:
        """Vérifie la santé du service VOSK"""
        
        start_time = time.time()
        
        try:
            timeout = aiohttp.ClientTimeout(total=5.0)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(f"{self.base_url}/health") as response:
                    response_time = time.time() - start_time
                    
                    if response.status == 200:
                        self.health_status.is_healthy = True
                        self.health_status.response_time = response_time
                        self.health_status.last_check = time.time()
                        self.health_status.error_message = None
                        self.health_status.consecutive_failures = 0
                        logger.info(f"Service VOSK sain: {response_time:.2f}s")
                        return True
                    else:
                        raise aiohttp.ClientResponseError(
                            request_info=response.request_info,
                            history=response.history,
                            status=response.status
                        )
        
        except Exception as e:
            response_time = time.time() - start_time
            self.health_status.is_healthy = False
            self.health_status.response_time = response_time
            self.health_status.last_check = time.time()
            self.health_status.error_message = str(e)
            self.health_status.consecutive_failures += 1
            logger.error(f"Service VOSK non sain: {e}")
            return False
    
    def _record_success(self, processing_time: float, confidence: float):
        """Enregistre un succès et ajuste les timeouts"""
        
        self.timeout_config.success_count += 1
        self.timeout_config.failure_count = 0
        
        # Réduire le timeout si performance stable et bonne confiance
        if self.timeout_config.success_count >= 3 and confidence > self.confidence_threshold:
            new_timeout = max(
                self.timeout_config.base_timeout,
                self.timeout_config.current_timeout * 0.9
            )
            self.timeout_config.current_timeout = new_timeout
            self.timeout_config.success_count = 0
        
        # Enregistrer les performances
        self.performance_history.append({
            'timestamp': time.time(),
            'processing_time': processing_time,
            'confidence': confidence,
            'success': True,
            'timeout_used': self.timeout_config.current_timeout
        })
        
        self.performance_history = self.performance_history[-100:]
    
    def _record_failure(self, error_type: str, processing_time: float):
        """Enregistre un échec et ajuste les timeouts"""
        
        self.timeout_config.failure_count += 1
        self.timeout_config.success_count = 0
        
        # Augmenter le timeout après échec
        if error_type == "timeout":
            new_timeout = min(
                self.timeout_config.max_timeout,
                self.timeout_config.current_timeout * self.timeout_config.multiplier
            )
            self.timeout_config.current_timeout = new_timeout
            logger.warning(f"Timeout VOSK augmenté à {new_timeout:.1f}s après échec")
        
        # Marquer le service comme non sain après plusieurs échecs
        if self.timeout_config.failure_count >= 3:
            self.health_status.is_healthy = False
            self.health_status.error_message = f"Échecs répétés: {error_type}"
        
        # Enregistrer les performances
        self.performance_history.append({
            'timestamp': time.time(),
            'processing_time': processing_time,
            'success': False,
            'error_type': error_type,
            'timeout_used': self.timeout_config.current_timeout
        })
        
        self.performance_history = self.performance_history[-100:]
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """Retourne les statistiques de performance"""
        
        if not self.performance_history:
            return {'no_data': True}
        
        recent_history = self.performance_history[-20:]
        
        successes = [h for h in recent_history if h['success']]
        failures = [h for h in recent_history if not h['success']]
        
        avg_confidence = sum(h.get('confidence', 0) for h in successes) / len(successes) if successes else 0
        
        return {
            'health_status': {
                'is_healthy': self.health_status.is_healthy,
                'consecutive_failures': self.health_status.consecutive_failures,
                'last_response_time': self.health_status.response_time
            },
            'timeout_config': {
                'current_timeout': self.timeout_config.current_timeout,
                'base_timeout': self.timeout_config.base_timeout,
                'max_timeout': self.timeout_config.max_timeout
            },
            'performance_metrics': {
                'total_requests': len(recent_history),
                'success_rate': len(successes) / len(recent_history) if recent_history else 0,
                'avg_response_time': sum(h['processing_time'] for h in successes) / len(successes) if successes else 0,
                'avg_confidence': avg_confidence,
                'low_confidence_rate': sum(1 for h in successes if h.get('confidence', 0) < self.confidence_threshold) / len(successes) if successes else 0,
                'error_types': list(set(h.get('error_type', 'unknown') for h in failures))
            }
        }

class RealMistralService:
    """Wrapper pour l'appel direct à l'API Mistral avec timeouts adaptatifs"""
    
    def __init__(self, api_key: Optional[str] = None, model: str = "mistral-nemo-instruct-2407"):
        import os
        self.api_key = api_key or os.getenv("MISTRAL_API_KEY")
        self.model = model
        self.base_url = "http://localhost:8001/v1/chat/completions"
        
        self.timeout_config = AdaptiveTimeout(
            base_timeout=15.0,
            current_timeout=15.0,
            max_timeout=60.0,
            multiplier=1.5,
            failure_count=0,
            success_count=0
        )
        
        self.health_status = ServiceHealth(
            service_name="Mistral-API",
            is_healthy=True,
            response_time=0.0,
            last_check=0.0
        )
        
        self.conversation_context = []
        self.performance_history = []
    
    async def generate_response(self, user_input: str, scenario_type: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Génère une réponse via l'API Mistral avec contexte conversationnel"""
        
        start_time = time.time()
        
        try:
            if not self.api_key:
                raise ValueError("Clé API Mistral manquante")
            
            # Préparer les messages avec contexte
            messages = self._prepare_messages(user_input, scenario_type, context)
            
            # Préparer la requête
            payload = {
                "model": self.model,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": 500,
                "stream": False
            }
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            # Exécuter la requête avec timeout adaptatif
            timeout = aiohttp.ClientTimeout(total=self.timeout_config.current_timeout)
            
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.post(self.base_url, json=payload, headers=headers) as response:
                    
                    if response.status == 200:
                        result_data = await response.json()
                        processing_time = time.time() - start_time
                        
                        # Extraire la réponse
                        ai_response = result_data['choices'][0]['message']['content']
                        
                        # Mettre à jour le contexte conversationnel
                        self._update_conversation_context(user_input, ai_response)
                        
                        # Analyser la qualité de la réponse
                        quality_metrics = self._analyze_response_quality(ai_response, user_input, context)
                        
                        # Enregistrer le succès
                        self._record_success(processing_time, quality_metrics['overall_quality'])
                        
                        enriched_result = {
                            'response': ai_response,
                            'processing_time': processing_time,
                            'total_tokens': result_data.get('usage', {}).get('total_tokens', 0),
                            'prompt_tokens': result_data.get('usage', {}).get('prompt_tokens', 0),
                            'completion_tokens': result_data.get('usage', {}).get('completion_tokens', 0),
                            'cost_estimate': self._estimate_cost(result_data.get('usage', {})),
                            'quality_metrics': quality_metrics,
                            'model_used': self.model,
                            'api_latency': processing_time,
                            'conversation_length': len(self.conversation_context)
                        }
                        
                        logger.info(f"Mistral génération réussie: {len(ai_response)} chars en {processing_time:.2f}s")
                        return enriched_result
                    
                    else:
                        error_text = await response.text()
                        raise aiohttp.ClientResponseError(
                            request_info=response.request_info,
                            history=response.history,
                            status=response.status,
                            message=error_text
                        )
        
        except asyncio.TimeoutError:
            processing_time = time.time() - start_time
            self._record_failure("timeout", processing_time)
            raise RuntimeError(f"Timeout Mistral après {processing_time:.1f}s")
        
        except aiohttp.ClientResponseError as e:
            processing_time = time.time() - start_time
            self._record_failure(f"http_{e.status}", processing_time)
            raise RuntimeError(f"Erreur HTTP Mistral {e.status}: {e.message}")
        
        except Exception as e:
            processing_time = time.time() - start_time
            self._record_failure("unexpected", processing_time)
            raise RuntimeError(f"Erreur Mistral inattendue: {str(e)}")
    
    def _prepare_messages(self, user_input: str, scenario_type: str, context: Dict[str, Any]) -> List[Dict[str, str]]:
        """Prépare les messages pour l'API Mistral avec contexte"""
        
        # Message système adapté au scénario
        system_prompts = {
            "presentation_client": "Tu es Marie, une IA d'entraînement commercial. Tu écoutes une présentation commerciale et tu réagis comme un client potentiel intéressé mais exigeant. Pose des questions pertinentes et montre de l'intérêt.",
            "negotiation": "Tu es Marie, une IA d'entraînement commercial. Tu es dans une phase de négociation. Sois pragmatique sur les prix et les conditions, pose des questions sur la valeur ajoutée.",
            "customer_service": "Tu es Marie, une IA d'entraînement service client. Tu es un client avec une demande ou un problème. Sois réaliste dans tes attentes."
        }
        
        system_message = system_prompts.get(scenario_type, 
            "Tu es Marie, une IA d'entraînement conversationnel. Réponds de manière naturelle et engageante en français.")
        
        # Ajouter contexte spécifique si fourni
        if context.get('conversation_phase'):
            system_message += f" Contexte actuel: {context['conversation_phase']}."
        
        if context.get('personality'):
            system_message += f" Personnalité: {context['personality']}."
        
        messages = [{"role": "system", "content": system_message}]
        
        # Ajouter l'historique de conversation récent (derniers 5 échanges)
        recent_context = self.conversation_context[-10:] if self.conversation_context else []
        for ctx_msg in recent_context:
            messages.append(ctx_msg)
        
        # Ajouter le message utilisateur actuel
        messages.append({"role": "user", "content": user_input})
        
        return messages
    
    def _update_conversation_context(self, user_input: str, ai_response: str):
        """Met à jour le contexte conversationnel"""
        
        self.conversation_context.append({"role": "user", "content": user_input})
        self.conversation_context.append({"role": "assistant", "content": ai_response})
        
        # Garder seulement les 20 derniers messages pour éviter le contexte trop long
        self.conversation_context = self.conversation_context[-20:]
    
    def _analyze_response_quality(self, ai_response: str, user_input: str, context: Dict[str, Any]) -> Dict[str, float]:
        """Analyse la qualité de la réponse Mistral"""
        
        # Longueur et structure
        word_count = len(ai_response.split())
        sentence_count = ai_response.count('.') + ai_response.count('!') + ai_response.count('?')
        
        # Score de longueur appropriée
        length_score = 1.0 if 10 <= word_count <= 50 else max(0.3, 1.0 - abs(word_count - 30) / 30)
        
        # Score d'engagement (questions, exclamations)
        engagement_score = min(1.0, (ai_response.count('?') * 0.3 + ai_response.count('!') * 0.2))
        
        # Score de pertinence (mots-clés du contexte)
        user_words = set(user_input.lower().split())
        response_words = set(ai_response.lower().split())
        common_words = user_words & response_words
        relevance_score = len(common_words) / len(user_words) if user_words else 0.5
        
        # Score de naturel (contractions, expressions françaises)
        natural_indicators = ["c'est", "n'est", "qu'", "j'ai", "vous", "votre"]
        naturalness_score = sum(1 for indicator in natural_indicators if indicator in ai_response.lower()) / len(natural_indicators)
        
        # Score global
        overall_quality = (length_score * 0.25 + engagement_score * 0.25 + 
                          relevance_score * 0.25 + naturalness_score * 0.25)
        
        return {
            'length_appropriateness': length_score,
            'engagement_level': engagement_score,
            'relevance_score': relevance_score,
            'naturalness_score': naturalness_score,
            'overall_quality': overall_quality,
            'word_count': word_count,
            'sentence_count': sentence_count,
            'question_count': ai_response.count('?'),
            'exclamation_count': ai_response.count('!')
        }
    
    def _estimate_cost(self, usage: Dict[str, int]) -> float:
        """Estime le coût de l'appel API"""
        
        # Tarifs Mistral approximatifs (en euros pour 1M tokens)
        input_cost_per_million = 1.0  # ~1€ par million de tokens d'entrée
        output_cost_per_million = 3.0  # ~3€ par million de tokens de sortie
        
        prompt_tokens = usage.get('prompt_tokens', 0)
        completion_tokens = usage.get('completion_tokens', 0)
        
        input_cost = (prompt_tokens / 1_000_000) * input_cost_per_million
        output_cost = (completion_tokens / 1_000_000) * output_cost_per_million
        
        return input_cost + output_cost
    
    def _record_success(self, processing_time: float, quality_score: float):
        """Enregistre un succès et ajuste les timeouts"""
        
        self.timeout_config.success_count += 1
        self.timeout_config.failure_count = 0
        
        # Réduire le timeout si performance stable et bonne qualité
        if self.timeout_config.success_count >= 3 and quality_score > 0.7:
            new_timeout = max(
                self.timeout_config.base_timeout,
                self.timeout_config.current_timeout * 0.9
            )
            self.timeout_config.current_timeout = new_timeout
            self.timeout_config.success_count = 0
        
        # Enregistrer les performances
        self.performance_history.append({
            'timestamp': time.time(),
            'processing_time': processing_time,
            'quality_score': quality_score,
            'success': True,
            'timeout_used': self.timeout_config.current_timeout
        })
        
        self.performance_history = self.performance_history[-100:]
    
    def _record_failure(self, error_type: str, processing_time: float):
        """Enregistre un échec et ajuste les timeouts"""
        
        self.timeout_config.failure_count += 1
        self.timeout_config.success_count = 0
        
        # Augmenter le timeout après échec
        if error_type == "timeout":
            new_timeout = min(
                self.timeout_config.max_timeout,
                self.timeout_config.current_timeout * self.timeout_config.multiplier
            )
            self.timeout_config.current_timeout = new_timeout
            logger.warning(f"Timeout Mistral augmenté à {new_timeout:.1f}s après échec")
        
        # Marquer le service comme non sain après plusieurs échecs
        if self.timeout_config.failure_count >= 3:
            self.health_status.is_healthy = False
            self.health_status.error_message = f"Échecs répétés: {error_type}"
        
        # Enregistrer les performances
        self.performance_history.append({
            'timestamp': time.time(),
            'processing_time': processing_time,
            'success': False,
            'error_type': error_type,
            'timeout_used': self.timeout_config.current_timeout
        })
        
        self.performance_history = self.performance_history[-100:]
    
    def reset_conversation_context(self):
        """Remet à zéro le contexte conversationnel"""
        self.conversation_context = []
        logger.info("Contexte conversationnel Mistral réinitialisé")
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """Retourne les statistiques de performance"""
        
        if not self.performance_history:
            return {'no_data': True}
        
        recent_history = self.performance_history[-20:]
        
        successes = [h for h in recent_history if h['success']]
        failures = [h for h in recent_history if not h['success']]
        
        avg_quality = sum(h.get('quality_score', 0) for h in successes) / len(successes) if successes else 0
        
        return {
            'health_status': {
                'is_healthy': self.health_status.is_healthy,
                'consecutive_failures': self.health_status.consecutive_failures,
                'last_response_time': self.health_status.response_time
            },
            'timeout_config': {
                'current_timeout': self.timeout_config.current_timeout,
                'base_timeout': self.timeout_config.base_timeout,
                'max_timeout': self.timeout_config.max_timeout
            },
            'performance_metrics': {
                'total_requests': len(recent_history),
                'success_rate': len(successes) / len(recent_history) if recent_history else 0,
                'avg_response_time': sum(h['processing_time'] for h in successes) / len(successes) if successes else 0,
                'avg_quality_score': avg_quality,
                'conversation_context_length': len(self.conversation_context),
                'error_types': list(set(h.get('error_type', 'unknown') for h in failures))
            }
        }

if __name__ == "__main__":
    # Test des wrappers de services
    import asyncio
    
    async def test_service_wrappers():
        logger.info("Test des wrappers de services")
        
        # Test TTS Service
        print("=== Test TTS Service ===")
        tts_service = RealTTSService()
        
        try:
            tts_result = await tts_service.synthesize_speech("Bonjour, ceci est un test.")
            print(f"TTS réussi: {len(tts_result['audio_data'])} bytes, qualité: {tts_result['quality_score']:.2f}")
            print(f"Durée audio: {tts_result['audio_duration']:.2f}s")
        except Exception as e:
            print(f"TTS échoué: {e}")
        
        tts_stats = tts_service.get_performance_stats()
        print(f"Stats TTS: {tts_stats}")
        
        # Test VOSK Service
        print("\n=== Test VOSK Service ===")
        vosk_service = RealVoskService()
        
        # On ne peut pas tester VOSK sans audio réel, simulation
        try:
            print("VOSK service configuré, simulation d'utilisation")
            vosk_stats = vosk_service.get_performance_stats()
            print(f"Stats VOSK: {vosk_stats}")
        except Exception as e:
            print(f"VOSK test: {e}")
        
        # Test Mistral Service
        print("\n=== Test Mistral Service ===")
        mistral_service = RealMistralService()
        
        try:
            mistral_result = await mistral_service.generate_response(
                "Bonjour, comment allez-vous ?", 
                "presentation_client", 
                {"conversation_phase": "greeting"}
            )
            print(f"Mistral réussi: {len(mistral_result['response'])} chars")
            print(f"Réponse: {mistral_result['response'][:100]}...")
            print(f"Qualité: {mistral_result['quality_metrics']['overall_quality']:.2f}")
        except Exception as e:
            print(f"Mistral échoué: {e}")
        
        mistral_stats = mistral_service.get_performance_stats()
        print(f"Stats Mistral: {mistral_stats}")
        
        print("\nTest des wrappers terminé")
    
    asyncio.run(test_service_wrappers())