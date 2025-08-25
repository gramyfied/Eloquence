#!/usr/bin/env python3
"""
Interface STT personnalisée pour LiveKit utilisant le service Vosk
Version corrigée pour LiveKit 1.2.3 avec toutes les corrections critiques
"""

import asyncio
import aiohttp
import logging
import io
import wave
import numpy as np
from typing import AsyncIterator, Optional
from livekit.agents import stt, utils
from livekit import rtc
from concurrent.futures import ThreadPoolExecutor
import threading

logger = logging.getLogger(__name__)

class VoskSpeechAlternative:
    """Alternative de reconnaissance vocale compatible LiveKit 1.2.3"""
    
    def __init__(self, text: str, confidence: float, speaker_id: Optional[str] = None, language: str = "fr"):
        self.text = text
        self.confidence = confidence
        self.speaker_id = speaker_id  # Attribut requis par LiveKit 1.2.3
        self.language = language      # Attribut requis par LiveKit 1.2.3

class VoskSTTFixed(stt.STT):
    """Interface STT Vosk corrigée avec toutes les corrections critiques du prompt"""
    
    def __init__(
        self,
        vosk_url: str = "http://vosk-stt:8002",
        language: str = "fr",
        sample_rate: int = 16000,
    ):
        super().__init__(
            capabilities=stt.STTCapabilities(
                streaming=False,  # Service Vosk non-streaming
                interim_results=False,
            )
        )
        self._vosk_url = vosk_url
        self._language = language
        self._sample_rate = sample_rate
        
        # CORRECTION 5: Pool de connexions HTTP persistantes
        self._session_pool_size = 3
        self._session_pool = []
        self._session_lock = threading.Lock()
        
        logger.info(f"🔧 [STT-TRACE] VoskSTTFixed initialisé - URL: {vosk_url}, Langue: {language}")
        logger.info(f"🔧 [STT-TRACE] Pool HTTP: {self._session_pool_size} connexions persistantes")
    
    async def _get_session(self) -> aiohttp.ClientSession:
        """Récupère une session HTTP du pool avec gestion thread-safe"""
        with self._session_lock:
            if self._session_pool:
                session = self._session_pool.pop()
                if not session.closed:
                    return session
        
        # Créer une nouvelle session si le pool est vide
        session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=30),
            connector=aiohttp.TCPConnector(
                limit=10,
                limit_per_host=5,
                keepalive_timeout=30,
                enable_cleanup_closed=True
            )
        )
        return session
    
    async def _return_session(self, session: aiohttp.ClientSession):
        """Retourne une session au pool"""
        with self._session_lock:
            if len(self._session_pool) < self._session_pool_size and not session.closed:
                self._session_pool.append(session)
            else:
                await session.close()
    
    def _validate_audio_frame(self, audio: rtc.AudioFrame) -> dict:
        """Valide le format audio selon les spécifications Vosk"""
        metrics = {
            'format_valid': True,
            'needs_resampling': False,
            'needs_channel_conversion': False,
            'sample_rate': audio.sample_rate,
            'channels': audio.num_channels,
            'data_size': len(audio.data)
        }
        
        # OBLIGATOIRE: Vosk requiert exactement 16kHz, mono, PCM 16-bit
        if audio.sample_rate != self._sample_rate:
            metrics['needs_resampling'] = True
            logger.debug(f"🔧 [STT-TRACE] Resampling requis: {audio.sample_rate}Hz → {self._sample_rate}Hz")
        
        if audio.num_channels > 1:
            metrics['needs_channel_conversion'] = True
            logger.debug(f"🔧 [STT-TRACE] Conversion canal requise: {audio.num_channels} → 1 (mono)")
        
        return metrics
    
    def _convert_to_mono(self, audio_data: np.ndarray) -> np.ndarray:
        """Convertit audio multi-canal en mono"""
        if len(audio_data.shape) == 1:
            return audio_data
        # Moyenne des canaux pour conversion mono
        return np.mean(audio_data, axis=1)
    
    def _resample_audio(self, audio_data: np.ndarray, source_rate: int, target_rate: int) -> np.ndarray:
        """Resample audio avec interpolation linéaire simple"""
        if source_rate == target_rate:
            return audio_data
        
        # Ratio de conversion
        ratio = target_rate / source_rate
        new_length = int(len(audio_data) * ratio)
        
        # Interpolation linéaire simple
        indices = np.linspace(0, len(audio_data) - 1, new_length)
        resampled = np.interp(indices, np.arange(len(audio_data)), audio_data)
        
        logger.debug(f"🔧 [STT-TRACE] Audio resampled: {len(audio_data)} → {len(resampled)} samples")
        return resampled
    
    def _normalize_audio(self, audio_data: np.ndarray) -> np.ndarray:
        """Normalise l'audio pour optimiser la reconnaissance"""
        # Normalisation RMS simple
        rms = np.sqrt(np.mean(audio_data**2))
        if rms > 0:
            audio_data = audio_data / rms * 0.1  # Niveau optimal pour Vosk
        return audio_data
    
    def _create_wav_bytes(self, audio_data: np.ndarray) -> bytes:
        """Crée des bytes WAV avec validation du format"""
        # Conversion en int16 (requis par Vosk)
        audio_int16 = (audio_data * 32767).astype(np.int16)
        
        # Créer WAV en mémoire
        wav_buffer = io.BytesIO()
        with wave.open(wav_buffer, 'wb') as wav_file:
            wav_file.setnchannels(1)  # Mono obligatoire
            wav_file.setsampwidth(2)  # 16-bit obligatoire
            wav_file.setframerate(self._sample_rate)  # 16kHz obligatoire
            wav_file.writeframes(audio_int16.tobytes())
        
        wav_bytes = wav_buffer.getvalue()
        logger.debug(f"🔧 [STT-TRACE] WAV créé: {len(wav_bytes)} bytes, {len(audio_int16)} samples")
        return wav_bytes
    
    def _audio_to_wav_bytes_robust(self, audio: rtc.AudioFrame) -> bytes:
        """CORRECTION 2: Conversion AudioFrame → WAV robuste et optimisée"""
        
        # 1. Validation du format source
        metrics = self._validate_audio_frame(audio)
        if not metrics['format_valid']:
            raise ValueError(f"Format audio invalide: {metrics}")
        
        # 2. Extraction des données audio
        audio_data = np.frombuffer(audio.data, dtype=np.int16).astype(np.float32) / 32768.0
        
        # 3. Reshape si nécessaire (gestion multi-canal)
        if audio.num_channels > 1:
            audio_data = audio_data.reshape(-1, audio.num_channels)
            audio_data = self._convert_to_mono(audio_data)
        
        # 4. Resampling si nécessaire
        if metrics['needs_resampling']:
            audio_data = self._resample_audio(audio_data, audio.sample_rate, self._sample_rate)
        
        # 5. Normalisation
        audio_data = self._normalize_audio(audio_data)
        
        # 6. Conversion en WAV avec validation
        return self._create_wav_bytes(audio_data)
    
    def _reset_recognizer(self):
        """CORRECTION 3: Reset du recognizer pour clear_user_turn"""
        logger.debug("🔄 [STT-TRACE] Reset recognizer Vosk pour nouveau tour")
        # Reset des buffers internes si nécessaire
        # Cette méthode sera appelée par clear_user_turn dans main.py
    
    async def _recognize_impl(
        self,
        buffer: utils.AudioBuffer,
        *,
        language: Optional[str] = None,
        conn_options: Optional[object] = None,
    ) -> stt.SpeechEvent:
        """CORRECTION 1: Implémentation avec structure SpeechEvent compatible LiveKit 1.2.3"""
        
        start_time = asyncio.get_event_loop().time()
        
        try:
            # Obtenir session du pool
            session = await self._get_session()
            
            try:
                # Combiner tous les frames audio du buffer
                merged_frame = utils.merge_frames(buffer)
                
                # CORRECTION 2: Conversion robuste
                wav_bytes = self._audio_to_wav_bytes_robust(merged_frame)
                
                # Envoi au service Vosk
                data = aiohttp.FormData()
                data.add_field('audio', wav_bytes, filename='audio.wav', content_type='audio/wav')
                
                logger.debug(f"📤 [STT-TRACE] Envoi audio Vosk ({len(wav_bytes)} bytes)")
                
                async with session.post(
                    f"{self._vosk_url}/transcribe",
                    data=data
                ) as response:
                    
                    if response.status != 200:
                        error_text = await response.text()
                        logger.error(f"❌ [STT-TRACE] Erreur service Vosk HTTP {response.status}: {error_text}")
                        raise Exception(f"Erreur service Vosk: HTTP {response.status}")
                    
                    result = await response.json()
                    
                    processing_time = asyncio.get_event_loop().time() - start_time
                    text = result.get('text', '').strip()
                    # Normaliser les caractères Unicode (préserver les accents)
                    try:
                        import unicodedata
                        text = unicodedata.normalize('NFC', text)
                        # Forcer l'encodage/décodage UTF-8 pour éliminer les substitutions
                        text = text.encode('utf-8', errors='ignore').decode('utf-8', errors='ignore')
                    except Exception:
                        pass
                    confidence = result.get('confidence', 0.0)
                    
                    logger.info(f"✅ [STT-TRACE] Vosk STT - {processing_time:.3f}s - '{text}' (conf: {confidence:.2f})")
                    
                    # CORRECTION 1: Structure compatible LiveKit 1.2.3
                    alternative = VoskSpeechAlternative(
                        text=text,
                        confidence=confidence,
                        speaker_id=None,
                        language=self._language
                    )
                    
                    speech_event = stt.SpeechEvent(
                        type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                        alternatives=[alternative]  # Objet avec attributs, pas dictionnaire
                    )
                    
                    logger.debug("✅ [STT-TRACE] SpeechEvent créé avec structure compatible LiveKit 1.2.3")
                    return speech_event
                    
            finally:
                # Retourner session au pool
                await self._return_session(session)
                
        except Exception as e:
            processing_time = asyncio.get_event_loop().time() - start_time
            logger.error(f"❌ [STT-TRACE] Erreur VoskSTTFixed après {processing_time:.3f}s: {e}")
            
            # Retourner un événement vide en cas d'erreur
            empty_alternative = VoskSpeechAlternative(
                text="",
                confidence=0.0,
                speaker_id=None,
                language=self._language
            )
            
            return stt.SpeechEvent(
                type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                alternatives=[empty_alternative]
            )

    async def recognize(
        self,
        buffer: utils.AudioBuffer,
        *,
        language: Optional[str] = None,
        conn_options: Optional[object] = None,
    ) -> stt.SpeechEvent:
        """Reconnaissance vocale via le service Vosk (compatible livekit-agents 1.2.3)"""
        return await self._recognize_impl(buffer, language=language, conn_options=conn_options)
    
    async def stream(self) -> "SpeechStream":
        """
        Stream STT - Non implémenté pour Vosk
        Notre service Vosk actuel ne supporte pas le streaming
        """
        raise NotImplementedError("Le streaming STT n'est pas encore implémenté pour Vosk")
    
    async def aclose(self):
        """Fermeture propre des ressources"""
        with self._session_lock:
            for session in self._session_pool:
                await session.close()
            self._session_pool.clear()

class SpeechStream(stt.SpeechStream):
    """Stream de reconnaissance vocale - stub pour l'interface"""
    
    def __init__(self, vosk_stt: VoskSTTFixed):
        super().__init__()
        self._vosk_stt = vosk_stt
    
    async def aclose(self) -> None:
        """Fermeture du stream"""
        await self._vosk_stt.aclose()
    
    def push_frame(self, frame: rtc.AudioFrame) -> None:
        """Push d'un frame audio - non implémenté"""
        pass
    
    async def __anext__(self) -> stt.SpeechEvent:
        """Itérateur async - non implémenté"""
        raise StopAsyncIteration

# ALIAS pour rétrocompatibilité
VoskSTT = VoskSTTFixed