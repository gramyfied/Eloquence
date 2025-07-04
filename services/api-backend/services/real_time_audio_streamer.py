import asyncio
import logging
import time
from livekit import rtc # Assurez-vous que livekit est installé
from .real_time_streaming_tts import RealTimeStreamingTTS # Import local

logger = logging.getLogger(__name__)
# Augmenter le niveau de log pour le débogage de ce module
logging.getLogger(__name__).setLevel(logging.DEBUG)

class RealTimeAudioStreamer:
    def __init__(self, livekit_room: rtc.Room):
        self.room = livekit_room
        self.tts_service = RealTimeStreamingTTS()
        self.audio_source: rtc.AudioSource = None
        self.audio_track: rtc.LocalAudioTrack = None
        self.is_streaming = False
        
        # Récupérer le sample_rate depuis le service TTS initialisé
        initial_sample_rate = self.tts_service.get_sample_rate()
        logger.info(f"🔍 Sample rate initial du TTS: {initial_sample_rate}")
        
        # Forcer l'initialisation du modèle TTS si pas encore fait
        if not hasattr(self.tts_service, 'piper_voice') or self.tts_service.piper_voice is None:
            logger.info("🔄 Modèle TTS pas encore chargé, initialisation forcée...")
            self.tts_service._load_piper_model()
        
        # Récupérer le sample rate après initialisation
        self.sample_rate = self.tts_service.get_sample_rate()
        self.num_channels = 1
        
        logger.info(f"RealTimeAudioStreamer initialisé avec sample_rate: {self.sample_rate}.")

    async def initialize_audio_source(self):
        """Initialise la source audio pour streaming continu"""
        if self.audio_source and self.audio_track:
            logger.info("Source audio déjà initialisée.")
            return

        try:
            logger.info(f"Création AudioSource avec sample_rate={self.sample_rate}, num_channels={self.num_channels}")
            self.audio_source = rtc.AudioSource(
                sample_rate=self.sample_rate,
                num_channels=self.num_channels
            )
            
            track_name = "ai_voice_stream_realtime" # Nom de piste unique
            logger.info(f"Création LocalAudioTrack nommé: {track_name}")
            self.audio_track = rtc.LocalAudioTrack.create_audio_track(
                track_name, 
                self.audio_source
            )
            
            publish_options = rtc.TrackPublishOptions(
                source=rtc.TrackSource.SOURCE_MICROPHONE # Simule un microphone
            )
            
            logger.info(f"Publication de la piste audio '{track_name}' vers LiveKit...")
            await self.room.local_participant.publish_track(
                self.audio_track,
                publish_options
            )
            
            logger.info("✅ Source audio pour streaming temps réel initialisée et piste publiée.")
            
        except Exception as e:
            logger.error(f"ÉCHEC INIT STREAMING AUDIO SOURCE: {e}", exc_info=True)
            # Ne pas lever d'exception ici pour permettre des tentatives ultérieures ou un mode dégradé
            self.audio_source = None
            self.audio_track = None
            # raise Exception(f"ÉCHEC INIT STREAMING: {e}") # Original

    async def stream_text_to_audio(self, text: str):
        """Stream texte vers audio en temps réel"""
        stream_start_time = time.time()
        logger.info(f"STREAM_DEBUG: Début stream_text_to_audio pour: '{text[:50]}...' à {stream_start_time}")
        
        try:
            if not self.audio_source or not self.audio_track:
                logger.warning("STREAM_DEBUG: Source audio non initialisée. Tentative d'initialisation...")
                await self.initialize_audio_source()
                if not self.audio_source or not self.audio_track:
                    logger.error("STREAM_DEBUG: Impossible d'initialiser la source audio. Streaming annulé.")
                    return
            
            if self.is_streaming:
                logger.warning("STREAM_DEBUG: Un streaming est déjà en cours. Veuillez attendre la fin.")
                # Optionnel: mettre en file d'attente ou annuler la nouvelle requête
                return

            self.is_streaming = True
            logger.info(f"STREAM_DEBUG: Flag is_streaming défini à True. Début du streaming audio pour: '{text[:50]}...'")
            
            chunk_count = 0
            last_chunk_time = time.time()
            
            logger.debug(f"STREAM_DEBUG: Début de la boucle async for sur tts_service.stream_generate_audio")
            async for audio_chunk in self.tts_service.stream_generate_audio(text):
                current_time = time.time()
                time_since_start = current_time - stream_start_time
                time_since_last_chunk = current_time - last_chunk_time
                
                logger.debug(f"STREAM_DEBUG: Chunk #{chunk_count+1} reçu après {time_since_start:.2f}s (delta: {time_since_last_chunk:.2f}s)")
                
                if not self.is_streaming:
                    logger.warning(f"STREAM_DEBUG: is_streaming=False détecté après {time_since_start:.2f}s. Arrêt prématuré.")
                    break
                
                if audio_chunk: # S'assurer que le chunk n'est pas vide
                    logger.debug(f"STREAM_DEBUG: Envoi chunk #{chunk_count+1} de {len(audio_chunk)} bytes")
                    await self._send_audio_chunk(audio_chunk)
                    chunk_count += 1
                    last_chunk_time = current_time
                else:
                    logger.warning(f"STREAM_DEBUG: Chunk audio vide reçu du TTS après {time_since_start:.2f}s, ignoré.")
            
            total_time = time.time() - stream_start_time
            if chunk_count > 0:
                logger.info(f"STREAM_DEBUG: ✅ Streaming terminé pour: '{text[:50]}...'. {chunk_count} chunks envoyés en {total_time:.2f}s.")
            else:
                logger.warning(f"STREAM_DEBUG: ⚠️ Aucun chunk audio n'a été envoyé pour: '{text[:50]}...' en {total_time:.2f}s. Vérifier TTS.")

        except Exception as e:
            total_time = time.time() - stream_start_time
            logger.error(f"STREAM_DEBUG: ÉCHEC STREAMING AUDIO après {total_time:.2f}s: {e}", exc_info=True)
        finally:
            self.is_streaming = False
            final_time = time.time() - stream_start_time
            logger.info(f"STREAM_DEBUG: Flag is_streaming défini à False. Durée totale: {final_time:.2f}s")
            # Ne pas arrêter la piste ici pour la réutiliser pour de futurs messages.
            # La piste sera arrêtée lors de la déconnexion de l'agent.
            
    async def _send_audio_chunk(self, audio_chunk: bytes):
        """Envoie un chunk audio vers LiveKit"""
        try:
            # La conversion en AudioFrame est cruciale
            # samples_per_channel = nombre d'échantillons (pas d'octets)
            # Pour PCM 16-bit (2 octets par échantillon)
            samples_per_channel = len(audio_chunk) // (2 * self.num_channels)

            if samples_per_channel == 0:
                logger.warning("SEND_CHUNK_DEBUG: Chunk audio vide ou trop petit, ignoré.")
                return

            logger.debug(f"SEND_CHUNK_DEBUG: Création AudioFrame - {len(audio_chunk)} bytes, {samples_per_channel} samples, SR: {self.sample_rate}Hz")
            
            audio_frame = rtc.AudioFrame(
                data=audio_chunk,
                sample_rate=self.sample_rate,
                num_channels=self.num_channels,
                samples_per_channel=samples_per_channel
            )
            
            # Envoi immédiat vers LiveKit via la source audio
            logger.debug(f"SEND_CHUNK_DEBUG: Envoi vers audio_source.capture_frame...")
            await self.audio_source.capture_frame(audio_frame)
            logger.debug(f"SEND_CHUNK_DEBUG: ✅ Chunk audio de {len(audio_chunk)} bytes ({samples_per_channel} samples) envoyé à LiveKit.")
            
        except Exception as e:
            logger.error(f"SEND_CHUNK_DEBUG: ⚠️ Erreur envoi chunk audio vers LiveKit: {e}", exc_info=True)
            
    async def stop_streaming(self):
        """Arrête le streaming audio en cours et nettoie la piste."""
        logger.info("STOP_STREAM_DEBUG: Arrêt du streaming audio demandé.")
        self.is_streaming = False
        logger.info("STOP_STREAM_DEBUG: Flag is_streaming défini à False.")
        
        if self.audio_track and self.room.local_participant:
            try:
                logger.info(f"STOP_STREAM_DEBUG: Dépublication de la piste audio: {self.audio_track.name}")
                await self.room.local_participant.unpublish_track(self.audio_track.sid)
                logger.info(f"STOP_STREAM_DEBUG: ✅ Piste audio dépubliée avec succès.")
            except Exception as e:
                logger.error(f"STOP_STREAM_DEBUG: Erreur lors de la dépublication de la piste: {e}", exc_info=True)
        
        # Réinitialiser pour permettre une nouvelle initialisation si nécessaire
        self.audio_source = None
        self.audio_track = None
        logger.info("STOP_STREAM_DEBUG: 🛑 Streaming audio arrêté et piste nettoyée.")