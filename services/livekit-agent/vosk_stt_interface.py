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
    
    async def start(self, conn_options: Optional[object] = None) -> None:
        """Démarre le service STT - requis par l'interface LiveKit"""
        await self._ensure_session()
        logger.info("✅ VoskSTT service démarré")
    
    async def aclose(self) -> None:
        """Ferme proprement le service STT"""
        await self._close_session()
        logger.info("🔴 VoskSTT service fermé")
    
    @property
    def vosk_url(self) -> str:
        """URL du service Vosk STT"""
        return self._vosk_url
    
    @property
    def ws_url(self) -> str:
        """URL WebSocket du service Vosk STT"""
        return f"{self._vosk_url.replace('http', 'ws')}/websocket"
    
    @property
    def sample_rate(self) -> int:
        """Taux d'échantillonnage audio"""
        return self._sample_rate
    
    @property
    def encoding(self) -> str:
        """Format d'encodage audio"""
        return "wav"
    
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
    
    async def _recognize_impl(
        self,
        buffer: utils.AudioBuffer,
        *,
        language: Optional[str] = None,
        conn_options: Optional[object] = None,
    ) -> stt.SpeechEvent:
        """Implémentation de la reconnaissance vocale requise par LiveKit agents 1.0.x"""
        
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
                
                # Structure compatible avec livekit-agents 1.0.x
                # Pas besoin de SpeechEventAlternative, utiliser directement le texte
                text = result.get('text', '').strip()
                confidence = result.get('confidence', 0.0)
                
                logger.info(f"🔍 DIAGNOSTIC: Création SpeechEvent avec text='{text}', confidence={confidence}")
                
                # Dans livekit-agents 1.0.x, SpeechEvent prend des alternatives directement
                # Vérifier d'abord la structure disponible
                try:
                    # Tentative 1: Avec alternatives comme liste de dictionnaires
                    speech_event = stt.SpeechEvent(
                        type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                        alternatives=[{
                            'text': text,
                            'confidence': confidence
                        }]
                    )
                    logger.info("✅ SpeechEvent créé avec structure dict")
                    return speech_event
                except Exception as e1:
                    logger.warning(f"⚠️  Structure dict échouée: {e1}")
                    
                    try:
                        # Tentative 2: Directement avec text (API simplifiée)
                        speech_event = stt.SpeechEvent(
                            type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                            text=text,
                            confidence=confidence
                        )
                        logger.info("✅ SpeechEvent créé avec text direct")
                        return speech_event
                    except Exception as e2:
                        logger.warning(f"⚠️  Structure text directe échouée: {e2}")
                        
                        try:
                            # Tentative 3: Minimal avec juste le type
                            speech_event = stt.SpeechEvent(
                                type=stt.SpeechEventType.FINAL_TRANSCRIPT
                            )
                            # Ajouter le texte en attribut après création
                            if hasattr(speech_event, 'text'):
                                speech_event.text = text
                            if hasattr(speech_event, 'confidence'):
                                speech_event.confidence = confidence
                            logger.info("✅ SpeechEvent créé avec structure minimale")
                            return speech_event
                        except Exception as e3:
                            logger.error(f"❌ Toutes les structures échouées: {e3}")
                            raise e3
                
        except Exception as e:
            processing_time = asyncio.get_event_loop().time() - start_time
            logger.error(f"❌ Erreur VoskSTT après {processing_time:.3f}s: {e}")
            
            # Retourner un événement vide en cas d'erreur
            try:
                return stt.SpeechEvent(
                    type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                    text="",
                    confidence=0.0
                )
            except:
                # Fallback ultime
                return stt.SpeechEvent(type=stt.SpeechEventType.FINAL_TRANSCRIPT)

    async def recognize(
        self,
        buffer: utils.AudioBuffer,
        *,
        language: Optional[str] = None,
        conn_options: Optional[object] = None,
    ) -> stt.SpeechEvent:
        """Reconnaissance vocale via le service Vosk (compatible livekit-agents 1.0.x)"""
        return await self._recognize_impl(buffer, language=language, conn_options=conn_options)
    
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