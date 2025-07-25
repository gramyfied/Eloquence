#!/usr/bin/env python3
"""
Interface STT personnalisée pour LiveKit utilisant le service Vosk
Optimise la latence en utilisant le traitement local
"""

import asyncio
import aiohttp
import logging
import tempfile
import wave
from typing import AsyncIterator, Optional
from livekit.agents import stt, utils
from livekit import rtc
import numpy as np

logger = logging.getLogger(__name__)

class VoskSTT(stt.STT):
    """Interface STT personnalisée utilisant le service Vosk local"""
    
    def __init__(
        self,
        vosk_url: str = "http://vosk-stt:8002",
        language: str = "fr",
        sample_rate: int = 16000,
    ):
        super().__init__(
            capabilities=stt.STTCapabilities(
                streaming=False,  # Notre service Vosk ne fait pas de streaming pour l'instant
                interim_results=False,
            )
        )
        self._vosk_url = vosk_url
        self._language = language
        self._sample_rate = sample_rate
        self._session: Optional[aiohttp.ClientSession] = None
        
        logger.info(f"🔧 VoskSTT initialisé - URL: {vosk_url}, Langue: {language}")
    
    async def _ensure_session(self):
        """Assure qu'une session HTTP est disponible"""
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=30)
            )
    
    async def _close_session(self):
        """Ferme la session HTTP"""
        if self._session and not self._session.closed:
            await self._session.close()
    
    def _audio_to_wav_bytes(self, audio: rtc.AudioFrame) -> bytes:
        """Convertit AudioFrame en bytes WAV"""
        # Conversion en format WAV compatible avec Vosk
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
            with wave.open(tmp.name, 'wb') as wav_file:
                wav_file.setnchannels(1)  # Mono
                wav_file.setsampwidth(2)  # 16-bit
                wav_file.setframerate(self._sample_rate)
                
                # Conversion des samples audio depuis rtc.AudioFrame
                # Les données audio sont dans audio.data comme numpy array
                audio_data = np.frombuffer(audio.data, dtype=np.int16)
                
                # Assurer que c'est mono (prendre le premier channel si stéréo)
                if len(audio_data.shape) > 1:
                    audio_data = audio_data[:, 0]
                
                wav_file.writeframes(audio_data.tobytes())
            
            # Lecture du fichier WAV créé
            with open(tmp.name, 'rb') as f:
                wav_bytes = f.read()
            
            return wav_bytes
    
    async def recognize(
        self,
        buffer: utils.AudioBuffer,
        *,
        language: Optional[str] = None,
    ) -> stt.SpeechEvent:
        """Reconnaissance vocale via le service Vosk"""
        
        start_time = asyncio.get_event_loop().time()
        
        try:
            await self._ensure_session()
            
            # Combiner tous les frames audio du buffer
            merged_frame = utils.merge_frames(buffer)
            
            # Conversion en WAV
            wav_bytes = self._audio_to_wav_bytes(merged_frame)
            
            # Envoi au service Vosk
            data = aiohttp.FormData()
            data.add_field('audio', wav_bytes, filename='audio.wav', content_type='audio/wav')
            
            logger.debug(f"📤 Envoi audio au service Vosk ({len(wav_bytes)} bytes)")
            
            async with self._session.post(
                f"{self._vosk_url}/transcribe",
                data=data
            ) as response:
                
                if response.status != 200:
                    error_text = await response.text()
                    logger.error(f"❌ Erreur service Vosk HTTP {response.status}: {error_text}")
                    raise Exception(f"Erreur service Vosk: HTTP {response.status}")
                
                result = await response.json()
                
                processing_time = asyncio.get_event_loop().time() - start_time
                logger.info(f"✅ Vosk STT - {processing_time:.3f}s - '{result.get('text', '')}'")
                
                # Création de l'événement STT
                alternatives = [
                    stt.SpeechEventAlternative(
                        text=result.get('text', ''),
                        confidence=result.get('confidence', 0.0)
                    )
                ]
                
                return stt.SpeechEvent(
                    type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                    alternatives=alternatives
                )
                
        except Exception as e:
            processing_time = asyncio.get_event_loop().time() - start_time
            logger.error(f"❌ Erreur VoskSTT après {processing_time:.3f}s: {e}")
            
            # Retourner un événement vide en cas d'erreur
            return stt.SpeechEvent(
                type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                alternatives=[
                    stt.SpeechEventAlternative(text="", confidence=0.0)
                ]
            )
    
    async def stream(self) -> "SpeechStream":
        """
        Stream STT - Non implémenté pour Vosk
        Notre service Vosk actuel ne supporte pas le streaming
        """
        raise NotImplementedError("Le streaming STT n'est pas encore implémenté pour Vosk")


class SpeechStream(stt.SpeechStream):
    """Stream de reconnaissance vocale - stub pour l'interface"""
    
    def __init__(self, vosk_stt: VoskSTT):
        super().__init__()
        self._vosk_stt = vosk_stt
    
    async def aclose(self) -> None:
        """Fermeture du stream"""
        await self._vosk_stt._close_session()
    
    def push_frame(self, frame: rtc.AudioFrame) -> None:
        """Push d'un frame audio - non implémenté"""
        pass
    
    async def __anext__(self) -> stt.SpeechEvent:
        """Itérateur async - non implémenté"""
        raise StopAsyncIteration