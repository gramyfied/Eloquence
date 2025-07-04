#!/usr/bin/env python3
"""
Fix pour forcer la publication d'audio au démarrage de l'agent LiveKit
"""

import asyncio
import logging
import os
import aiohttp
from livekit import rtc
from livekit.agents import JobContext
import numpy as np

logger = logging.getLogger(__name__)

async def force_audio_publication_on_startup(ctx: JobContext):
    """Force la publication d'un audio track au démarrage de l'agent"""
    try:
        logger.info("🔊 [FORCE AUDIO] Démarrage de la publication forcée d'audio")
        
        # 1. Créer une source audio
        audio_source = rtc.AudioSource(sample_rate=48000, num_channels=1)
        logger.info("✅ [FORCE AUDIO] AudioSource créée")
        
        # 2. Créer un track audio local
        audio_track = rtc.LocalAudioTrack.create_audio_track(
            "eloquence-agent-audio",
            audio_source
        )
        logger.info("✅ [FORCE AUDIO] LocalAudioTrack créé")
        
        # 3. Publier le track immédiatement
        publish_options = rtc.TrackPublishOptions(
            source=rtc.TrackSource.SOURCE_MICROPHONE,
            stereo=False,
            dtx=False,
            red=True
        )
        
        publication = await ctx.room.local_participant.publish_track(
            audio_track,
            publish_options
        )
        
        logger.info(f"📡 [FORCE AUDIO] Track publié avec succès! SID: {publication.sid}")
        
        # 4. Générer et diffuser un message de bienvenue
        welcome_text = "Bonjour ! Je suis votre coach d'éloquence. Comment puis-je vous aider aujourd'hui ?"
        
        # Appeler le service TTS
        tts_audio = await generate_welcome_audio(welcome_text)
        
        if tts_audio:
            logger.info(f"🔊 [FORCE AUDIO] Audio de bienvenue généré: {len(tts_audio)} bytes")
            
            # Diffuser l'audio
            await stream_audio_to_track(audio_source, tts_audio)
            logger.info("✅ [FORCE AUDIO] Audio de bienvenue diffusé")
        else:
            logger.warning("⚠️ [FORCE AUDIO] Impossible de générer l'audio de bienvenue")
        
        return audio_source, audio_track, publication
        
    except Exception as e:
        logger.error(f"❌ [FORCE AUDIO] Erreur lors de la publication forcée: {e}", exc_info=True)
        return None, None, None

async def generate_welcome_audio(text: str) -> bytes:
    """Générer l'audio de bienvenue via le service TTS"""
    try:
        logger.info("🎯 [TTS] Génération audio de bienvenue")
        
        openai_api_key = os.environ.get("OPENAI_API_KEY")
        if not openai_api_key:
            logger.error("❌ [TTS] OPENAI_API_KEY non configurée")
            return b""
        
        headers = {
            "Authorization": f"Bearer {openai_api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": "tts-1",
            "input": text,
            "voice": "alloy",
            "response_format": "pcm"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                "https://api.openai.com/v1/audio/speech",
                headers=headers,
                json=data,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                if response.status == 200:
                    audio_data = await response.read()
                    logger.info(f"✅ [TTS] Audio généré: {len(audio_data)} bytes")
                    return audio_data
                else:
                    error_text = await response.text()
                    logger.error(f"❌ [TTS] Erreur API {response.status}: {error_text}")
                    return b""
                    
    except Exception as e:
        logger.error(f"❌ [TTS] Erreur génération audio: {e}", exc_info=True)
        return b""

async def stream_audio_to_track(audio_source: rtc.AudioSource, audio_data: bytes):
    """Diffuser les données audio vers le track LiveKit"""
    try:
        logger.info("📡 [STREAM] Début de la diffusion audio")
        
        # Convertir en numpy array int16
        audio_array = np.frombuffer(audio_data, dtype=np.int16)
        
        # Rééchantillonner de 24kHz à 48kHz si nécessaire
        original_sample_rate = 24000
        target_sample_rate = 48000
        
        if original_sample_rate != target_sample_rate:
            from scipy.signal import resample
            num_samples_resampled = int(len(audio_array) * (target_sample_rate / original_sample_rate))
            audio_array = resample(audio_array, num_samples_resampled).astype(np.int16)
        
        # Envoyer par chunks de 10ms
        chunk_size_samples = int(target_sample_rate * 0.01)  # 10ms à 48kHz = 480 samples
        
        for i in range(0, len(audio_array), chunk_size_samples):
            chunk = audio_array[i:i+chunk_size_samples]
            
            # Padding si nécessaire
            if len(chunk) < chunk_size_samples:
                chunk = np.pad(chunk, (0, chunk_size_samples - len(chunk)), 'constant', constant_values=0)
            
            # Créer la frame audio
            frame = rtc.AudioFrame(
                data=chunk.tobytes(),
                sample_rate=target_sample_rate,
                num_channels=1,
                samples_per_channel=chunk_size_samples
            )
            
            # Envoyer la frame
            await audio_source.capture_frame(frame)
            
            # Délai pour un streaming fluide
            await asyncio.sleep(chunk_size_samples / target_sample_rate)
        
        logger.info("✅ [STREAM] Diffusion audio terminée")
        
    except Exception as e:
        logger.error(f"❌ [STREAM] Erreur diffusion audio: {e}", exc_info=True)

async def test_audio_publication():
    """Test de la publication audio"""
    logger.info("🧪 [TEST] Test de publication audio")
    
    # Simuler un contexte minimal
    class MockRoom:
        class MockParticipant:
            async def publish_track(self, track, options):
                logger.info("🧪 [MOCK] Track publié (simulation)")
                return type('Publication', (), {'sid': 'test-sid'})()
        
        local_participant = MockParticipant()
    
    class MockContext:
        room = MockRoom()
    
    ctx = MockContext()
    
    # Tester la publication
    audio_source, audio_track, publication = await force_audio_publication_on_startup(ctx)
    
    if audio_source and audio_track and publication:
        logger.info("✅ [TEST] Publication audio réussie")
        return True
    else:
        logger.error("❌ [TEST] Échec de la publication audio")
        return False

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(test_audio_publication())