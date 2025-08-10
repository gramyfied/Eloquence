"""
Wrapper pour Edge TTS - Alternative gratuite à OpenAI TTS
Utilise edge-tts de Microsoft pour la synthèse vocale
"""
import asyncio
import edge_tts
import io
import logging
from typing import AsyncIterator, Optional
from livekit.agents import tts

logger = logging.getLogger(__name__)

# Voix Edge TTS disponibles en français
EDGE_VOICES = {
    'confidence_boost': {
        'voice': 'fr-FR-HenriNeural',      # Voix masculine chaleureuse
        'rate': '+0%',                     # Vitesse normale
        'pitch': '+0Hz'                    # Ton normal
    },
    'tribunal_idees_impossibles': {
        'voice': 'fr-FR-DeniseNeural',     # Voix féminine énergique
        'rate': '+10%',                    # Légèrement plus rapide
        'pitch': '+5Hz'                    # Ton légèrement plus aigu (théâtral)
    },
    'studio_situations_pro': {
        'voice': 'fr-FR-YvesNeural',       # Voix masculine professionnelle
        'rate': '+0%',                     # Vitesse normale
        'pitch': '-2Hz'                    # Ton légèrement plus grave
    },
    'default': {
        'voice': 'fr-FR-JulieNeural',      # Voix féminine neutre
        'rate': '+0%',
        'pitch': '+0Hz'
    }
}

class EdgeTTS(tts.TTS):
    """Implémentation Edge TTS pour LiveKit"""
    
    def __init__(self, exercise_type: str = 'default'):
        super().__init__()
        self.config = EDGE_VOICES.get(exercise_type, EDGE_VOICES['default'])
        self.voice = self.config['voice']
        self.rate = self.config['rate']
        self.pitch = self.config['pitch']
        logger.info(f"🎙️ Edge TTS initialisé: {self.voice} (rate: {self.rate}, pitch: {self.pitch})")
    
    async def synthesize(self, text: str) -> AsyncIterator[tts.SynthesizedAudio]:
        """Synthétise le texte en audio"""
        try:
            # Créer le communicator Edge TTS
            communicate = edge_tts.Communicate(
                text=text,
                voice=self.voice,
                rate=self.rate,
                pitch=self.pitch
            )
            
            # Buffer pour accumuler l'audio
            audio_buffer = io.BytesIO()
            
            # Générer l'audio
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    audio_buffer.write(chunk["data"])
            
            # Retourner l'audio synthétisé
            audio_data = audio_buffer.getvalue()
            if audio_data:
                yield tts.SynthesizedAudio(
                    data=audio_data,
                    sample_rate=24000  # Edge TTS utilise 24kHz par défaut
                )
                logger.debug(f"✅ Synthèse réussie: {len(text)} caractères -> {len(audio_data)} octets")
            
        except Exception as e:
            logger.error(f"❌ Erreur Edge TTS: {e}")
            # En cas d'erreur, on retourne un audio vide
            yield tts.SynthesizedAudio(
                data=b'',
                sample_rate=24000
            )


def create_edge_tts(exercise_type: str = 'default') -> EdgeTTS:
    """Crée une instance Edge TTS configurée"""
    return EdgeTTS(exercise_type)


# Liste des voix disponibles pour référence
AVAILABLE_VOICES = {
    'fr-FR': [
        'fr-FR-HenriNeural',       # Homme
        'fr-FR-YvesNeural',        # Homme
        'fr-FR-AlainNeural',       # Homme 
        'fr-FR-DeniseNeural',      # Femme
        'fr-FR-JulieNeural',       # Femme
        'fr-FR-SylvieNeural',      # Femme
        'fr-FR-EloiseNeural',      # Enfant (femme)
        'fr-FR-RemyMultilingualNeural',  # Multilingue
        'fr-FR-VivienneMultilingualNeural'  # Multilingue
    ]
}