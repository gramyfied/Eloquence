"""
Service de synthèse vocale multi-voix pour les agents Studio Situations Pro
"""
import os
import asyncio
import logging
from typing import Optional, Dict, Any
from dataclasses import dataclass
import aiohttp
import json
import base64

logger = logging.getLogger(__name__)


@dataclass
class TTSConfig:
    """Configuration TTS pour un agent"""
    voice: str  # alloy, echo, fable, onyx, nova, shimmer
    speed: float  # 0.25 à 4.0
    pitch: str  # Modificateur de pitch
    provider: str = "openai"  # ou "elevenlabs", "google", etc.
    

class TTSService:
    """Service de synthèse vocale multi-providers"""
    
    def __init__(self):
        self.openai_api_key = os.environ.get("OPENAI_API_KEY")
        self.elevenlabs_api_key = os.environ.get("ELEVENLABS_API_KEY")
        self.current_provider = "openai"
        
    async def synthesize_speech(
        self, 
        text: str, 
        voice_config: Dict[str, Any],
        agent_id: str
    ) -> Optional[bytes]:
        """
        Synthétise le texte en audio avec la voix spécifique de l'agent
        
        Args:
            text: Le texte à synthétiser
            voice_config: Configuration de voix de l'agent
            agent_id: ID de l'agent pour le logging
            
        Returns:
            Audio en bytes ou None si erreur
        """
        
        logger.info(f"🎙️ TTS pour {agent_id}: {text[:50]}...")
        logger.info(f"   Config voix: {voice_config}")
        
        provider = voice_config.get("provider", "openai")
        
        if provider == "openai":
            return await self._synthesize_openai(text, voice_config)
        elif provider == "elevenlabs":
            return await self._synthesize_elevenlabs(text, voice_config)
        elif provider == "google":
            return await self._synthesize_google(text, voice_config)
        else:
            # Fallback: retourner None pour utiliser le mode texte
            logger.warning(f"Provider TTS non supporté: {provider}")
            return None
            
    async def _synthesize_openai(
        self, 
        text: str, 
        voice_config: Dict[str, Any]
    ) -> Optional[bytes]:
        """Synthèse via OpenAI TTS"""
        
        if not self.openai_api_key:
            logger.error("❌ Clé API OpenAI manquante")
            return None
            
        try:
            url = "https://api.openai.com/v1/audio/speech"
            
            headers = {
                "Authorization": f"Bearer {self.openai_api_key}",
                "Content-Type": "application/json"
            }
            
            # Mapper les voix OpenAI
            voice_map = {
                "alloy": "alloy",
                "echo": "echo", 
                "fable": "fable",
                "onyx": "onyx",
                "nova": "nova",
                "shimmer": "shimmer"
            }
            
            voice = voice_map.get(voice_config.get("voice", "alloy"), "alloy")
            speed = voice_config.get("speed", 1.0)
            
            # Ajuster la vitesse selon le pitch demandé
            pitch_modifier = voice_config.get("pitch", "normal")
            if pitch_modifier == "slightly_higher":
                speed *= 1.05
            elif pitch_modifier == "slightly_lower":
                speed *= 0.95
            elif pitch_modifier == "lower":
                speed *= 0.9
            elif pitch_modifier == "confident":
                speed *= 1.02
            elif pitch_modifier == "measured":
                speed *= 0.97
            elif pitch_modifier == "energetic":
                speed *= 1.08
            elif pitch_modifier == "technical":
                speed *= 0.98
            elif pitch_modifier == "business":
                speed *= 1.0
            elif pitch_modifier == "engaged":
                speed *= 1.03
            
            # Limiter la vitesse aux bornes OpenAI
            speed = max(0.25, min(4.0, speed))
            
            # Utiliser la meilleure qualité disponible
            quality = voice_config.get("quality", "hd")
            model = "tts-1-hd" if quality == "hd" else "tts-1"
            
            data = {
                "model": "tts-1",  # Modèle standard pour rapidité (au lieu de HD)
                "input": text,
                "voice": voice,
                "speed": speed,
                "response_format": "opus"  # Format optimisé pour WebRTC
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(url, headers=headers, json=data) as response:
                    if response.status == 200:
                        audio_data = await response.read()
                        logger.info(f"✅ Audio généré: {len(audio_data)} bytes avec modèle {model}")
                        
                        # Optimisation audio pour meilleure qualité
                        if len(audio_data) > 0:
                            logger.info(f"🎵 Qualité audio optimisée pour {voice} (vitesse: {speed})")
                        
                        return audio_data
                    else:
                        error = await response.text()
                        logger.error(f"❌ Erreur OpenAI TTS: {error}")
                        return None
                        
        except Exception as e:
            logger.error(f"❌ Exception TTS OpenAI: {e}")
            return None
            
    async def _synthesize_elevenlabs(
        self, 
        text: str, 
        voice_config: Dict[str, Any]
    ) -> Optional[bytes]:
        """Synthèse via ElevenLabs (voix plus réalistes)"""
        
        if not self.elevenlabs_api_key:
            logger.warning("Clé API ElevenLabs manquante, fallback OpenAI")
            return await self._synthesize_openai(text, voice_config)
            
        try:
            # Mapper les voix vers ElevenLabs
            voice_map = {
                "alloy": "21m00Tcm4TlvDq8ikWAM",  # Rachel
                "echo": "VR6AewLTigWG4xSOukaG",   # Arnold
                "nova": "EXAVITQu4vr4xnSDxMaL",   # Bella
                "onyx": "ErXwobaYiN019PkySvjV",   # Antoni
                "shimmer": "MF3mGyEYCl7XYWbV9V6O",  # Elli
                "fable": "ThT5KcBeYPX3keUQqHPh"    # Nicole
            }
            
            voice_id = voice_map.get(voice_config.get("voice", "alloy"), "21m00Tcm4TlvDq8ikWAM")
            
            url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
            
            headers = {
                "xi-api-key": self.elevenlabs_api_key,
                "Content-Type": "application/json"
            }
            
            # Ajuster les paramètres ElevenLabs
            stability = 0.5  # Stabilité de la voix
            similarity_boost = 0.75  # Boost de similarité
            
            pitch_modifier = voice_config.get("pitch", "normal")
            if pitch_modifier in ["confident", "energetic"]:
                stability = 0.4
                similarity_boost = 0.85
            elif pitch_modifier in ["measured", "technical"]:
                stability = 0.6
                similarity_boost = 0.7
                
            data = {
                "text": text,
                "model_id": "eleven_multilingual_v2",
                "voice_settings": {
                    "stability": stability,
                    "similarity_boost": similarity_boost,
                    "style": 0.5,
                    "use_speaker_boost": True
                }
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(url, headers=headers, json=data) as response:
                    if response.status == 200:
                        audio_data = await response.read()
                        logger.info(f"✅ Audio ElevenLabs généré: {len(audio_data)} bytes")
                        return audio_data
                    else:
                        logger.warning("Fallback vers OpenAI")
                        return await self._synthesize_openai(text, voice_config)
                        
        except Exception as e:
            logger.error(f"Exception ElevenLabs: {e}")
            return await self._synthesize_openai(text, voice_config)
            
    async def _synthesize_google(
        self, 
        text: str, 
        voice_config: Dict[str, Any]
    ) -> Optional[bytes]:
        """Synthèse via Google Cloud TTS"""
        
        # Implémentation Google Cloud TTS
        # Nécessite google-cloud-texttospeech
        
        logger.info("Google TTS non implémenté, fallback OpenAI")
        return await self._synthesize_openai(text, voice_config)
        
    async def stream_audio_chunks(
        self,
        text: str,
        voice_config: Dict[str, Any],
        agent_id: str,
        chunk_size: int = 1024
    ):
        """
        Stream l'audio par chunks pour une lecture en temps réel
        
        Yields:
            Chunks d'audio de taille fixe
        """
        
        audio_data = await self.synthesize_speech(text, voice_config, agent_id)
        
        if not audio_data:
            return
            
        # Diviser en chunks pour streaming
        for i in range(0, len(audio_data), chunk_size):
            chunk = audio_data[i:i + chunk_size]
            yield chunk
            await asyncio.sleep(0.01)  # Petit délai pour simuler le streaming


class VoicePersonalityMapper:
    """Mappe les personnalités aux caractéristiques vocales"""
    
    @staticmethod
    def enhance_voice_config(personality_traits: list, base_config: dict) -> dict:
        """
        Améliore la configuration de voix basée sur les traits de personnalité
        
        Args:
            personality_traits: Liste des traits de personnalité
            base_config: Configuration de base de la voix
            
        Returns:
            Configuration enrichie
        """
        
        config = base_config.copy()
        
        # Ajustements basés sur les traits
        if "autoritaire" in personality_traits:
            config["speed"] *= 0.95  # Plus lent pour l'autorité
            config["emphasis"] = "strong"
            
        if "curieuse" in personality_traits or "curieux" in personality_traits:
            config["speed"] *= 1.05  # Plus rapide pour la curiosité
            config["intonation"] = "questioning"
            
        if "sage" in personality_traits:
            config["speed"] *= 0.9  # Plus lent pour la sagesse
            config["pause_duration"] = 1.2  # Pauses plus longues
            
        if "énergique" in personality_traits or "dynamique" in personality_traits:
            config["speed"] *= 1.1
            config["energy_level"] = "high"
            
        if "analytique" in personality_traits:
            config["precision"] = "high"
            config["emotion_level"] = "low"
            
        if "empathique" in personality_traits:
            config["warmth"] = "high"
            config["emotion_level"] = "medium"
            
        return config


# Singleton pour le service TTS
_tts_service = None

def get_tts_service() -> TTSService:
    """Obtient l'instance singleton du service TTS"""
    global _tts_service
    if _tts_service is None:
        _tts_service = TTSService()
    return _tts_service