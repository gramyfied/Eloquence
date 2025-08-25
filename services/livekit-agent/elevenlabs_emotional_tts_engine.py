import asyncio
import aiohttp
import json
import random
import logging
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime

logger = logging.getLogger(__name__)

class ElevenLabsEmotionalTTSEngine:
    """Moteur TTS émotionnel complet pour ElevenLabs v2.5 Flash"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        
        # Configuration base ElevenLabs v2.5 Flash
        self.base_config = {
            "model_id": "eleven_flash_v2_5",  # v2.5 Flash optimisé
            "optimize_streaming_latency": 3,  # Optimisation latence maximale
            "output_format": "mp3_44100_128"  # Qualité optimale
        }
        
        # Composants émotionnels
        self.text_preprocessor = EmotionalTextPreprocessor()
        self.voice_parameterizer = EmotionalVoiceParameterizer()
        self.voice_selector = EmotionalVoiceSelector()
        self.emotion_detector = ConversationEmotionDetector()
    
    async def generate_emotional_speech(
        self,
        text: str,
        agent_id: str,
        conversation_context: Dict[str, Any] = None,
        user_message: str = "",
        conversation_history: List[str] = None
    ) -> Tuple[bytes, Dict[str, Any]]:
        """
        Génère speech émotionnel avec ElevenLabs v2.5 Flash
        
        INNOVATION MAJEURE : Émotions complètes sans API native v3
        """
        
        try:
            # 1. Analyse émotionnelle contexte complet
            emotional_context = await self.emotion_detector.analyze_conversation_emotion(
                agent_id=agent_id,
                agent_response=text,
                user_message=user_message,
                conversation_history=conversation_history or []
            )
            
            target_emotion = emotional_context["primary_emotion"]
            emotion_intensity = emotional_context["intensity"]
            
            # 2. Préprocessing textuel émotionnel
            emotional_text = self.text_preprocessor.apply_emotional_preprocessing(
                text, target_emotion, emotion_intensity
            )
            
            # 3. Sélection voix optimale
            optimal_voice_id = self.voice_selector.select_optimal_voice(
                agent_id, target_emotion, emotional_context
            )
            
            # 4. Paramètres émotionnels adaptatifs
            emotional_params = self.voice_parameterizer.get_emotional_parameters(
                target_emotion, emotion_intensity, optimal_voice_id
            )
            
            # 5. Configuration finale ElevenLabs
            final_config = {
                **self.base_config,
                "voice_id": optimal_voice_id,
                "voice_settings": {
                    "stability": emotional_params["stability"],
                    "similarity_boost": emotional_params["similarity_boost"],
                    "style": emotional_params["style"],
                    "use_speaker_boost": emotional_params["use_speaker_boost"]
                }
            }
            
            # 6. Génération audio émotionnel
            audio_data = await self._call_elevenlabs_api(emotional_text, final_config)
            
            logger.info(f"🎭 Audio émotionnel généré: {target_emotion} (intensité: {emotion_intensity:.1f}) - Agent: {agent_id}")
            
            return audio_data, emotional_context
            
        except Exception as e:
            logger.error(f"❌ Erreur génération émotionnelle: {e}")
            # Fallback voix neutre
            fallback_audio = await self._generate_neutral_fallback(text, agent_id)
            return fallback_audio, {"primary_emotion": "neutre", "intensity": 0.5}
    
    async def _call_elevenlabs_api(
        self,
        text: str,
        config: Dict[str, Any]
    ) -> bytes:
        """Appel API ElevenLabs avec configuration émotionnelle"""
        
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{config['voice_id']}"
        
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": self.api_key
        }
        
        payload = {
            "text": text,
            "model_id": config["model_id"],
            "voice_settings": config["voice_settings"],
            "optimize_streaming_latency": config["optimize_streaming_latency"],
            "output_format": config["output_format"]
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, headers=headers) as response:
                if response.status == 200:
                    return await response.read()
                else:
                    error_text = await response.text()
                    raise Exception(f"ElevenLabs API error {response.status}: {error_text}")
    
    async def _generate_neutral_fallback(self, text: str, agent_id: str) -> bytes:
        """Génère audio neutre en cas d'erreur"""
        
        fallback_voice = self.voice_selector.select_optimal_voice(agent_id, "neutre", {})
        neutral_params = self.voice_parameterizer.get_emotional_parameters("neutre")
        
        config = {
            **self.base_config,
            "voice_id": fallback_voice,
            "voice_settings": {
                "stability": neutral_params["stability"],
                "similarity_boost": neutral_params["similarity_boost"],
                "style": neutral_params["style"],
                "use_speaker_boost": neutral_params["use_speaker_boost"]
            }
        }
        
        return await self._call_elevenlabs_api(text, config)

class EmotionalTextPreprocessor:
    """Préprocesseur textuel pour émotions vocales ElevenLabs v2.5"""
    
    def __init__(self):
        # Marqueurs émotionnels par émotion
        self.emotional_markers = {
            "enthousiasme": {
                "prefixes": ["*avec enthousiasme*", "*ton passionné*", "*énergie contagieuse*"],
                "suffixes": ["!", " C'est fantastique !", " Quelle énergie !"],
                "replacements": {
                    ".": "!",
                    "c'est": "c'est vraiment",
                    "bien": "excellent",
                    "intéressant": "absolument fascinant"
                },
                "emphasis_words": ["vraiment", "absolument", "fantastique", "excellent"]
            },
            
            "empathie": {
                "prefixes": ["*avec bienveillance*", "*ton chaleureux*", "*voix douce*"],
                "suffixes": ["...", " Je comprends.", " C'est tout à fait normal."],
                "replacements": {
                    "je pense": "je ressens",
                    "c'est": "c'est tout à fait",
                    "normal": "compréhensible"
                },
                "emphasis_words": ["comprends", "ressens", "bienveillant", "chaleureux"]
            },
            
            "curiosite": {
                "prefixes": ["*avec curiosité*", "*ton intrigué*", "*intérêt piqué*"],
                "suffixes": ["?", " Dites-moi en plus !", " Cela m'intrigue !"],
                "replacements": {
                    ".": "?",
                    "comment": "comment exactement",
                    "pourquoi": "mais pourquoi donc",
                    "que": "qu'est-ce que"
                },
                "emphasis_words": ["exactement", "précisément", "fascinant", "intriguant"]
            },
            
            "determination": {
                "prefixes": ["*avec détermination*", "*ton résolu*", "*voix ferme*"],
                "suffixes": [".", " C'est décidé !", " Allons-y !"],
                "replacements": {
                    "je vais": "je vais absolument",
                    "nous devons": "nous devons impérativement",
                    "il faut": "il est essentiel de"
                },
                "emphasis_words": ["absolument", "impérativement", "essentiel", "crucial"]
            },
            
            "surprise": {
                "prefixes": ["*avec surprise*", "*ton étonné*", "*voix surprise*"],
                "suffixes": ["!", " Incroyable !", " Qui l'eût cru !"],
                "replacements": {
                    "ah": "oh là là",
                    "vraiment": "vraiment ?!",
                    "c'est": "c'est incroyable, c'est"
                },
                "emphasis_words": ["incroyable", "étonnant", "surprenant", "inattendu"]
            },
            
            "reflexion": {
                "prefixes": ["*ton pensif*", "*voix réfléchie*", "*pause contemplative*"],
                "suffixes": ["...", " Laissez-moi réfléchir.", " Hmm, intéressant."],
                "replacements": {
                    "je pense": "il me semble",
                    "peut-être": "peut-être bien",
                    "probablement": "très probablement"
                },
                "emphasis_words": ["réfléchir", "contempler", "méditer", "analyser"]
            },
            
            "challenge": {
                "prefixes": ["*ton provocateur*", "*voix challengeante*", "*énergie de défi*"],
                "suffixes": ["!", " Qu'en dites-vous ?", " Relevez le défi !"],
                "replacements": {
                    "mais": "mais attendez",
                    "non": "absolument pas",
                    "vraiment": "vraiment ?!"
                },
                "emphasis_words": ["challenge", "défi", "provocation", "confrontation"]
            }
        }
    
    def apply_emotional_preprocessing(
        self,
        text: str,
        target_emotion: str,
        intensity: float = 0.7
    ) -> str:
        """Applique préprocessing émotionnel au texte"""
        
        if target_emotion not in self.emotional_markers:
            return text
        
        markers = self.emotional_markers[target_emotion]
        processed_text = text
        
        # 1. Ajout préfixe émotionnel (selon intensité)
        if intensity > 0.5 and random.random() < intensity:
            prefix = random.choice(markers["prefixes"])
            processed_text = f"{prefix} {processed_text}"
        
        # 2. Remplacements contextuels
        for original, replacement in markers["replacements"].items():
            if original in processed_text.lower():
                processed_text = processed_text.replace(original, replacement)
        
        # 3. Emphase mots-clés
        for emphasis_word in markers["emphasis_words"]:
            if emphasis_word in processed_text.lower():
                if intensity > 0.8:
                    processed_text = processed_text.replace(
                        emphasis_word, 
                        f"*{emphasis_word}*"  # Marqueur emphase ElevenLabs
                    )
        
        # 4. Ajout suffixe émotionnel (selon intensité)
        if intensity > 0.6 and random.random() < (intensity - 0.3):
            suffix = random.choice(markers["suffixes"])
            processed_text = f"{processed_text} {suffix}"
        
        # 5. Ajustement ponctuation finale
        processed_text = self._adjust_final_punctuation(processed_text, target_emotion)
        
        return processed_text.strip()
    
    def _adjust_final_punctuation(self, text: str, emotion: str) -> str:
        """Ajuste ponctuation finale selon émotion"""
        
        punctuation_map = {
            "enthousiasme": "!",
            "surprise": "!",
            "challenge": "!",
            "curiosite": "?",
            "empathie": ".",
            "reflexion": "...",
            "determination": "."
        }
        
        target_punct = punctuation_map.get(emotion, ".")
        
        # Remplacement ponctuation finale
        if text.endswith(('.', '!', '?')):
            text = text[:-1] + target_punct
        else:
            text += target_punct
        
        return text

class EmotionalVoiceParameterizer:
    """Paramétrage adaptatif ElevenLabs selon émotion cible"""
    
    def __init__(self):
        # Configurations optimales par émotion
        self.emotion_parameters = {
            "enthousiasme": {
                "stability": 0.3,      # Faible = plus d'expressivité
                "similarity_boost": 0.8, # Élevé = fidélité voix
                "style": 0.7,          # Élevé = plus de style
                "use_speaker_boost": True
            },
            
            "empathie": {
                "stability": 0.6,      # Moyen = douceur contrôlée
                "similarity_boost": 0.9, # Très élevé = voix douce
                "style": 0.4,          # Modéré = naturel
                "use_speaker_boost": True
            },
            
            "curiosite": {
                "stability": 0.4,      # Faible-moyen = intonations variées
                "similarity_boost": 0.75, # Élevé = clarté questions
                "style": 0.6,          # Élevé = expressivité
                "use_speaker_boost": True
            },
            
            "determination": {
                "stability": 0.7,      # Élevé = fermeté, constance
                "similarity_boost": 0.85, # Très élevé = autorité
                "style": 0.5,          # Modéré = sérieux
                "use_speaker_boost": True
            },
            
            "surprise": {
                "stability": 0.2,      # Très faible = maximum expressivité
                "similarity_boost": 0.7, # Moyen = permet variations
                "style": 0.8,          # Très élevé = dramatique
                "use_speaker_boost": True
            },
            
            "reflexion": {
                "stability": 0.8,      # Très élevé = calme, posé
                "similarity_boost": 0.9, # Très élevé = consistance
                "style": 0.3,          # Faible = naturel, pensif
                "use_speaker_boost": False
            },
            
            "challenge": {
                "stability": 0.35,     # Faible = énergie variable
                "similarity_boost": 0.8, # Élevé = force voix
                "style": 0.75,         # Élevé = intensité
                "use_speaker_boost": True
            },
            
            "neutre": {
                "stability": 0.5,      # Équilibré
                "similarity_boost": 0.8, # Standard
                "style": 0.5,          # Standard
                "use_speaker_boost": True
            }
        }
    
    def get_emotional_parameters(
        self,
        emotion: str,
        intensity: float = 0.7,
        agent_voice_id: str = None
    ) -> Dict[str, Any]:
        """Retourne paramètres ElevenLabs optimisés pour émotion"""
        
        base_params = self.emotion_parameters.get(emotion, self.emotion_parameters["neutre"])
        
        # Adaptation selon intensité
        adapted_params = base_params.copy()
        
        if intensity > 0.8:
            # Intensité élevée → plus d'expressivité
            adapted_params["stability"] = max(0.1, adapted_params["stability"] - 0.1)
            adapted_params["style"] = min(1.0, adapted_params["style"] + 0.1)
        elif intensity < 0.4:
            # Intensité faible → plus de contrôle
            adapted_params["stability"] = min(0.9, adapted_params["stability"] + 0.2)
            adapted_params["style"] = max(0.1, adapted_params["style"] - 0.1)
        
        return adapted_params

class EmotionalVoiceSelector:
    """Sélecteur de voix selon contexte émotionnel"""
    
    def __init__(self):
        # Mapping voix neutres françaises par agent et émotion
        self.agent_emotional_voices = {
            "michel_dubois_animateur": {
                "primary": "pNInz6obpgDQGcFmaJgB",    # Adam - Voix principale
                "enthousiasme": "pNInz6obpgDQGcFmaJgB", # Adam - Énergique
                "empathie": "29vD33N1CtxCmqQRPOHJ",     # Drew - Plus doux
                "reflexion": "29vD33N1CtxCmqQRPOHJ",    # Drew - Posé
                "challenge": "pNInz6obpgDQGcFmaJgB",    # Adam - Dynamique
                "curiosite": "pNInz6obpgDQGcFmaJgB",    # Adam - Expressif
                "determination": "pNInz6obpgDQGcFmaJgB", # Adam - Ferme
                "surprise": "pNInz6obpgDQGcFmaJgB"      # Adam - Réactif
            },
            
            "sarah_johnson_journaliste": {
                "primary": "21m00Tcm4TlvDq8ikWAM",      # Rachel - Voix principale
                "curiosite": "21m00Tcm4TlvDq8ikWAM",    # Rachel - Investigatrice
                "determination": "MF3mGyEYCl7XYWbV9V6O", # Elli - Plus ferme
                "surprise": "21m00Tcm4TlvDq8ikWAM",     # Rachel - Expressive
                "reflexion": "AZnzlk1XvdvUeBnXmlld",    # Domi - Analytique
                "enthousiasme": "21m00Tcm4TlvDq8ikWAM", # Rachel - Énergique
                "empathie": "MF3mGyEYCl7XYWbV9V6O",     # Elli - Bienveillante
                "challenge": "21m00Tcm4TlvDq8ikWAM"     # Rachel - Incisive
            },
            
            "emma_wilson_coach": {
                "primary": "MF3mGyEYCl7XYWbV9V6O",      # Elli - Voix principale
                "empathie": "MF3mGyEYCl7XYWbV9V6O",      # Elli - Bienveillante
                "enthousiasme": "21m00Tcm4TlvDq8ikWAM",  # Rachel - Énergique
                "determination": "AZnzlk1XvdvUeBnXmlld", # Domi - Ferme
                "reflexion": "MF3mGyEYCl7XYWbV9V6O",     # Elli - Douce
                "curiosite": "MF3mGyEYCl7XYWbV9V6O",     # Elli - Curieuse
                "surprise": "21m00Tcm4TlvDq8ikWAM",      # Rachel - Expressive
                "challenge": "AZnzlk1XvdvUeBnXmlld"      # Domi - Motivante
            },
            
            "david_chen_challenger": {
                "primary": "TxGEqnHWrfWFTfGW9XjX",      # Josh - Voix principale
                "challenge": "TxGEqnHWrfWFTfGW9XjX",     # Josh - Provocateur
                "determination": "TxGEqnHWrfWFTfGW9XjX",  # Josh - Ferme
                "surprise": "pNInz6obpgDQGcFmaJgB",      # Adam - Réactif
                "enthousiasme": "pNInz6obpgDQGcFmaJgB",   # Adam - Énergique
                "reflexion": "29vD33N1CtxCmqQRPOHJ",     # Drew - Posé
                "curiosite": "TxGEqnHWrfWFTfGW9XjX",     # Josh - Investigateur
                "empathie": "29vD33N1CtxCmqQRPOHJ"       # Drew - Bienveillant
            },
            
            "sophie_martin_diplomate": {
                "primary": "AZnzlk1XvdvUeBnXmlld",       # Domi - Voix principale
                "reflexion": "AZnzlk1XvdvUeBnXmlld",     # Domi - Sage
                "empathie": "MF3mGyEYCl7XYWbV9V6O",      # Elli - Bienveillante
                "determination": "AZnzlk1XvdvUeBnXmlld",  # Domi - Ferme
                "curiosite": "21m00Tcm4TlvDq8ikWAM",     # Rachel - Curieuse
                "enthousiasme": "21m00Tcm4TlvDq8ikWAM",   # Rachel - Inspirante
                "surprise": "MF3mGyEYCl7XYWbV9V6O",      # Elli - Expressive
                "challenge": "AZnzlk1XvdvUeBnXmlld"      # Domi - Diplomatique
            }
        }
    
    def select_optimal_voice(
        self,
        agent_id: str,
        emotion: str,
        conversation_context: Dict[str, Any]
    ) -> str:
        """Sélectionne voix optimale selon émotion et contexte"""
        
        agent_voices = self.agent_emotional_voices.get(agent_id, {})
        
        # Voix spécifique à l'émotion
        if emotion in agent_voices:
            return agent_voices[emotion]
        
        # Voix primaire par défaut
        return agent_voices.get("primary", "pNInz6obpgDQGcFmaJgB")

class ConversationEmotionDetector:
    """Détecteur émotionnel basé sur contexte conversationnel"""
    
    async def analyze_conversation_emotion(
        self,
        agent_id: str,
        agent_response: str,
        user_message: str,
        conversation_history: List[str]
    ) -> Dict[str, Any]:
        """Analyse émotion optimale selon contexte complet"""
        
        # Analyse sentiment utilisateur
        user_sentiment = self._analyze_user_sentiment(user_message)
        
        # Analyse contenu réponse agent
        response_emotion = self._detect_response_emotion(agent_response, agent_id)
        
        # Analyse dynamique conversation
        conversation_energy = self._analyze_conversation_energy(conversation_history)
        
        # Sélection émotion finale
        primary_emotion = self._select_optimal_emotion(
            agent_id, response_emotion, user_sentiment, conversation_energy
        )
        
        # Calcul intensité
        intensity = self._calculate_emotion_intensity(
            primary_emotion, user_sentiment, conversation_energy
        )
        
        return {
            "primary_emotion": primary_emotion,
            "intensity": intensity,
            "user_sentiment": user_sentiment,
            "conversation_energy": conversation_energy,
            "confidence": 0.85
        }
    
    def _analyze_user_sentiment(self, user_message: str) -> float:
        """Analyse sentiment utilisateur"""
        
        positive_words = ['excellent', 'génial', 'parfait', 'super', 'merci', 'bravo', 'intéressant']
        negative_words = ['nul', 'ennuyeux', 'difficile', 'problème', 'inquiet', 'stress', 'peur']
        
        message_lower = user_message.lower()
        positive_count = sum(1 for word in positive_words if word in message_lower)
        negative_count = sum(1 for word in negative_words if word in message_lower)
        
        if positive_count + negative_count == 0:
            return 0.5  # Neutre
        
        return positive_count / (positive_count + negative_count)
    
    def _detect_response_emotion(self, response: str, agent_id: str) -> str:
        """Détecte émotion dans la réponse de l'agent"""
        
        emotion_keywords = {
            "enthousiasme": ["fantastique", "excellent", "brillant", "formidable", "génial"],
            "empathie": ["comprends", "ressens", "difficile", "normal", "bienveillant"],
            "curiosite": ["pourquoi", "comment", "intéressant", "fascinant", "expliquez"],
            "challenge": ["mais", "cependant", "non", "faux", "questionner"],
            "surprise": ["incroyable", "étonnant", "wow", "ah", "vraiment"],
            "reflexion": ["réfléchir", "penser", "analyser", "peut-être", "probablement"],
            "determination": ["devons", "faut", "essentiel", "crucial", "absolument"]
        }
        
        response_lower = response.lower()
        emotion_scores = {}
        
        for emotion, keywords in emotion_keywords.items():
            score = sum(1 for keyword in keywords if keyword in response_lower)
            emotion_scores[emotion] = score
        
        # Retourne émotion avec score le plus élevé ou neutre
        if not any(emotion_scores.values()):
            return "neutre"
        
        return max(emotion_scores.items(), key=lambda x: x[1])[0]
    
    def _analyze_conversation_energy(self, history: List[str]) -> float:
        """Analyse énergie conversation"""
        
        if not history:
            return 0.5
        
        # Analyse longueur réponses récentes
        recent_lengths = [len(msg.split()) for msg in history[-3:]]
        avg_length = sum(recent_lengths) / len(recent_lengths)
        
        # Énergie basée sur longueur et ponctuation
        energy = min(1.0, avg_length / 20)
        
        # Bonus ponctuation expressive
        recent_text = ' '.join(history[-3:])
        if '!' in recent_text or '?' in recent_text:
            energy += 0.2
        
        return min(1.0, energy)
    
    def _select_optimal_emotion(
        self,
        agent_id: str,
        response_emotion: str,
        user_sentiment: float,
        conversation_energy: float
    ) -> str:
        """Sélectionne émotion optimale selon tous facteurs"""
        
        # Personnalité agent influence émotion
        agent_emotion_tendencies = {
            "michel_dubois_animateur": ["enthousiasme", "curiosite", "challenge"],
            "sarah_johnson_journaliste": ["curiosite", "determination", "surprise"],
            "emma_wilson_coach": ["empathie", "enthousiasme", "reflexion"],
            "david_chen_challenger": ["challenge", "determination", "surprise"],
            "sophie_martin_diplomate": ["reflexion", "empathie", "determination"]
        }
        
        preferred_emotions = agent_emotion_tendencies.get(agent_id, ["enthousiasme"])
        
        # Adaptation selon sentiment utilisateur
        if user_sentiment < 0.3:
            # Utilisateur négatif → empathie
            return "empathie"
        elif user_sentiment > 0.8:
            # Utilisateur très positif → enthousiasme
            return "enthousiasme"
        elif conversation_energy < 0.4:
            # Énergie faible → stimulation
            return random.choice(["enthousiasme", "curiosite", "challenge"])
        else:
            # Émotion selon personnalité agent
            return random.choice(preferred_emotions)
    
    def _calculate_emotion_intensity(
        self,
        emotion: str,
        user_sentiment: float,
        conversation_energy: float
    ) -> float:
        """Calcule intensité émotionnelle"""
        
        base_intensity = 0.7
        
        # Ajustements selon contexte
        if user_sentiment > 0.8 or user_sentiment < 0.2:
            # Sentiment extrême → intensité élevée
            base_intensity += 0.2
        
        if conversation_energy > 0.8:
            # Énergie élevée → intensité élevée
            base_intensity += 0.1
        elif conversation_energy < 0.3:
            # Énergie faible → intensité modérée pour stimuler
            base_intensity += 0.15
        
        return min(1.0, base_intensity)
