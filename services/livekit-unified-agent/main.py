import asyncio
import logging
import json
import requests
import time
import numpy as np
from typing import Dict, List, Optional
from dataclasses import dataclass
from livekit import rtc, api
from livekit.agents import AutoSubscribe, JobContext, WorkerOptions, cli, llm
from livekit.agents.voice_assistant import VoiceAssistant
from livekit.plugins import openai, silero

@dataclass
class ConfidenceMetrics:
    """Métriques de confiance en temps réel"""
    confidence_score: float = 0.0
    clarity_score: float = 0.0
    pace_score: float = 0.0
    energy_score: float = 0.0
    fluency_score: float = 0.0
    timestamp: float = 0.0

@dataclass
class ScenarioContext:
    """Contexte du scénario Confidence Boost"""
    scenario_type: str = "interview"  # interview, presentation, negotiation
    difficulty: str = "facile"
    character_name: str = "Thomas"  # Thomas (recruteur), Marie (cliente)
    phase: str = "introduction"  # introduction, development, conclusion

class UnifiedConfidenceAgent:
    """Agent LiveKit unifié pour l'exercice Confidence Boost"""
    
    def __init__(self):
        self.room: Optional[rtc.Room] = None
        self.vosk_url = "http://localhost:8002"
        self.mistral_url = "http://localhost:8001"
        self.current_scenario: Optional[ScenarioContext] = None
        self.metrics_history: List[ConfidenceMetrics] = []
        self.conversation_context: List[str] = []
        self.session_start_time = time.time()
        
        # Configuration logging avancé
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger("UnifiedConfidenceAgent")
        
    async def initialize_scenario(self, scenario_data: Dict):
        """Initialise le contexte du scénario"""
        self.current_scenario = ScenarioContext(
            scenario_type=scenario_data.get("type", "interview"),
            difficulty=scenario_data.get("difficulty", "facile"),
            character_name=scenario_data.get("character", "Thomas"),
            phase="introduction"
        )
        self.logger.info(f"Scénario initialisé: {self.current_scenario}")
        
    async def connect_to_room(self, room_name: str, token: str, scenario_data: Dict = None):
        """Connexion avancée à la room LiveKit avec configuration scénario"""
        try:
            self.room = rtc.Room()
            
            # Initialiser le scénario si fourni
            if scenario_data:
                await self.initialize_scenario(scenario_data)
            
            @self.room.on("participant_connected")
            def on_participant_connected(participant):
                self.logger.info(f"✅ Participant connecté: {participant.identity}")
                # Envoyer message de bienvenue adapté au scénario
                asyncio.create_task(self.send_welcome_message())
                
            @self.room.on("participant_disconnected")
            def on_participant_disconnected(participant):
                self.logger.info(f"❌ Participant déconnecté: {participant.identity}")
                asyncio.create_task(self.finalize_session())
                
            @self.room.on("track_subscribed")
            def on_track_subscribed(track, publication, participant):
                if isinstance(track, rtc.AudioTrack):
                    self.logger.info(f"🎤 Track audio reçu de {participant.identity}")
                    asyncio.create_task(self.process_audio_stream(track, participant))
            
            # Connexion avec retry automatique
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    await self.room.connect("ws://localhost:7880", token)
                    self.logger.info(f"🚀 Connecté à la room: {room_name}")
                    break
                except Exception as e:
                    if attempt < max_retries - 1:
                        self.logger.warning(f"Tentative {attempt + 1} échouée, retry: {e}")
                        await asyncio.sleep(2)
                    else:
                        raise e
                        
        except Exception as e:
            self.logger.error(f"❌ Erreur connexion LiveKit: {e}")
            raise
        
    async def process_audio_stream(self, audio_track, participant):
        """Pipeline unifié de traitement audio en temps réel"""
        frame_buffer = []
        buffer_duration = 0.5  # 500ms de buffer pour l'analyse
        
        async for frame in audio_track:
            try:
                frame_buffer.append(frame.data)
                
                # Traitement par chunks pour optimiser les performances
                if len(frame_buffer) >= int(buffer_duration * 16000 / 1024):  # ~8 frames à 16kHz
                    # Combiner les frames audio
                    combined_audio = b''.join(frame_buffer)
                    frame_buffer.clear()
                    
                    # 1. Transcription en streaming
                    transcription = await self.transcribe_audio_streaming(combined_audio)
                    
                    if transcription.strip():
                        self.logger.info(f"🎯 Transcription: '{transcription}'")
                        self.conversation_context.append(f"USER: {transcription}")
                        
                        # 2. Analyse comportementale temps réel
                        metrics = await self.analyze_confidence_realtime(combined_audio, transcription)
                        self.metrics_history.append(metrics)
                        
                        # 3. Envoi métriques temps réel au client
                        await self.send_realtime_metrics(metrics)
                        
                        # 4. Génération réponse IA contextuelle (phrases complètes)
                        if self.is_complete_sentence(transcription):
                            await self.handle_complete_sentence(transcription)
                            
                        # 5. Mise à jour phase conversation
                        await self.update_conversation_phase()
                
            except Exception as e:
                self.logger.error(f"❌ Erreur traitement audio: {e}")
                continue
                
    async def handle_complete_sentence(self, transcription: str):
        """Gère une phrase complète de l'utilisateur"""
        try:
            # Générer réponse IA adaptée au scénario
            ai_response = await self.generate_contextual_ai_response(transcription)
            
            if ai_response:
                self.conversation_context.append(f"AI: {ai_response}")
                self.logger.info(f"🤖 Réponse IA: '{ai_response}'")
                
                # Synthèse vocale et envoi audio
                ai_audio = await self.synthesize_speech(ai_response)
                await self.send_ai_audio_to_room(ai_audio)
                
                # Envoi transcription pour l'interface
                await self.send_conversation_update(transcription, ai_response)
                
        except Exception as e:
            self.logger.error(f"❌ Erreur génération réponse: {e}")
    
    async def transcribe_audio_streaming(self, audio_data: bytes) -> str:
        """Transcription en streaming optimisée via Vosk"""
        try:
            # Envoi optimisé avec timeout
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    requests.post,
                    f"{self.vosk_url}/transcribe",
                    data=audio_data,
                    headers={"Content-Type": "audio/wav"}
                ),
                timeout=2.0
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("text", "").strip()
            else:
                self.logger.warning(f"Vosk erreur HTTP {response.status_code}")
                return ""
                
        except asyncio.TimeoutError:
            self.logger.warning("Timeout transcription Vosk")
            return ""
        except Exception as e:
            self.logger.error(f"Erreur transcription: {e}")
            return ""
    
    async def analyze_confidence_realtime(self, audio_data: bytes, transcription: str) -> ConfidenceMetrics:
        """Analyse comportementale avancée temps réel"""
        try:
            # Analyse audio (volume, débit, pauses)
            audio_features = await self.extract_audio_features(audio_data)
            
            # Analyse textuelle (hésitations, mots de remplissage)
            text_features = self.analyze_text_features(transcription)
            
            # Calcul scores composites
            confidence_score = self.calculate_confidence_score(audio_features, text_features)
            clarity_score = self.calculate_clarity_score(audio_features, text_features)
            pace_score = self.calculate_pace_score(audio_features)
            energy_score = self.calculate_energy_score(audio_features)
            fluency_score = self.calculate_fluency_score(text_features)
            
            metrics = ConfidenceMetrics(
                confidence_score=confidence_score,
                clarity_score=clarity_score,
                pace_score=pace_score,
                energy_score=energy_score,
                fluency_score=fluency_score,
                timestamp=time.time() - self.session_start_time
            )
            
            return metrics
            
        except Exception as e:
            self.logger.error(f"Erreur analyse confiance: {e}")
            return ConfidenceMetrics(timestamp=time.time() - self.session_start_time)
    
    async def generate_contextual_ai_response(self, transcription: str) -> str:
        """Génération réponse IA contextuelle selon le scénario"""
        try:
            # Construction du prompt contextuel
            context_prompt = self.build_scenario_prompt(transcription)
            
            # Appel service Mistral avec contexte
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    requests.post,
                    f"{self.mistral_url}/generate",
                    json={
                        "prompt": context_prompt,
                        "max_tokens": 150,
                        "temperature": 0.7,
                        "scenario": self.current_scenario.__dict__ if self.current_scenario else {}
                    }
                ),
                timeout=5.0
            )
            
            if response.status_code == 200:
                result = response.json()
                ai_text = result.get("response", "").strip()
                
                # Filtrer les réponses inappropriées
                if self.is_appropriate_response(ai_text):
                    return ai_text
                else:
                    return self.get_fallback_response()
            else:
                return self.get_fallback_response()
                
        except Exception as e:
            self.logger.error(f"Erreur génération IA: {e}")
            return self.get_fallback_response()
    
    def build_scenario_prompt(self, user_input: str) -> str:
        """Construit le prompt contextuel selon le scénario"""
        if not self.current_scenario:
            return f"Répondez naturellement à: {user_input}"
            
        character_prompts = {
            "Thomas": f"""Tu es Thomas, un recruteur bienveillant mais exigeant.
                         Contexte: entretien d'embauche de niveau {self.current_scenario.difficulty}.
                         Le candidat dit: "{user_input}"
                         Réponds comme un recruteur professionnel, pose des questions pertinentes.""",
            
            "Marie": f"""Tu es Marie, une cliente intéressée mais critique.
                        Contexte: présentation de niveau {self.current_scenario.difficulty}.
                        Le présentateur dit: "{user_input}"
                        Réponds comme une cliente exigeante, demande des précisions."""
        }
        
        return character_prompts.get(
            self.current_scenario.character_name,
            f"Répondez professionnellement à: {user_input}"
        )
    
    # === MÉTHODES D'ANALYSE AUDIO AVANCÉES ===
    
    async def extract_audio_features(self, audio_data: bytes) -> Dict:
        """Extraction features audio basiques"""
        try:
            # Simulation d'analyse audio (à remplacer par librairie audio réelle)
            volume = len(audio_data) / 1000.0  # Approximation volume
            return {
                "volume": min(volume, 1.0),
                "duration": len(audio_data) / 16000.0,  # Estimation durée
                "silence_ratio": 0.1,  # À calculer réellement
                "pace": 1.0  # Mots par seconde estimé
            }
        except:
            return {"volume": 0.5, "duration": 0.5, "silence_ratio": 0.2, "pace": 1.0}
    
    def analyze_text_features(self, text: str) -> Dict:
        """Analyse features textuelles"""
        hesitations = len([w for w in text.lower().split() if w in ["euh", "hm", "ben", "donc", "en fait"]])
        word_count = len(text.split())
        
        return {
            "hesitation_count": hesitations,
            "word_count": word_count,
            "hesitation_ratio": hesitations / max(word_count, 1),
            "sentence_length": word_count
        }
    
    def calculate_confidence_score(self, audio_features: Dict, text_features: Dict) -> float:
        """Calcul score de confiance composite"""
        # Score basé sur volume, hésitations, débit
        volume_score = min(audio_features["volume"] * 2, 1.0)
        hesitation_penalty = text_features["hesitation_ratio"] * 0.5
        pace_score = min(audio_features["pace"], 1.0)
        
        final_score = (volume_score + pace_score) / 2 - hesitation_penalty
        return max(0.0, min(1.0, final_score))
    
    def calculate_clarity_score(self, audio_features: Dict, text_features: Dict) -> float:
        """Score de clarté"""
        return max(0.3, min(1.0, 1.0 - text_features["hesitation_ratio"]))
    
    def calculate_pace_score(self, audio_features: Dict) -> float:
        """Score de débit"""
        ideal_pace = 1.5  # mots/seconde idéal
        pace_diff = abs(audio_features["pace"] - ideal_pace)
        return max(0.2, 1.0 - pace_diff)
    
    def calculate_energy_score(self, audio_features: Dict) -> float:
        """Score d'énergie"""
        return min(1.0, audio_features["volume"] * 1.2)
    
    def calculate_fluency_score(self, text_features: Dict) -> float:
        """Score de fluidité"""
        return max(0.1, 1.0 - text_features["hesitation_ratio"] * 2)
    
    # === MÉTHODES DE COMMUNICATION ===
    
    async def send_realtime_metrics(self, metrics: ConfidenceMetrics):
        """Envoi métriques temps réel au client"""
        try:
            if self.room:
                metrics_data = {
                    "type": "confidence_metrics",
                    "data": {
                        "confidence": metrics.confidence_score,
                        "clarity": metrics.clarity_score,
                        "pace": metrics.pace_score,
                        "energy": metrics.energy_score,
                        "fluency": metrics.fluency_score,
                        "timestamp": metrics.timestamp
                    }
                }
                
                # Envoi via DataChannel LiveKit
                await self.room.local_participant.publish_data(
                    json.dumps(metrics_data).encode(),
                    reliable=True
                )
                
        except Exception as e:
            self.logger.error(f"Erreur envoi métriques: {e}")
    
    async def send_conversation_update(self, user_text: str, ai_response: str):
        """Envoi mise à jour conversation"""
        try:
            if self.room:
                conversation_data = {
                    "type": "conversation_update",
                    "data": {
                        "user_message": user_text,
                        "ai_response": ai_response,
                        "timestamp": time.time(),
                        "character": self.current_scenario.character_name if self.current_scenario else "AI"
                    }
                }
                
                await self.room.local_participant.publish_data(
                    json.dumps(conversation_data).encode(),
                    reliable=True
                )
                
        except Exception as e:
            self.logger.error(f"Erreur envoi conversation: {e}")
    
    async def send_welcome_message(self):
        """Envoie message de bienvenue adapté au scénario"""
        if not self.current_scenario:
            return
            
        welcome_messages = {
            "Thomas": "Bonjour ! Je suis Thomas, votre recruteur. Présentez-vous et expliquez-moi pourquoi vous souhaitez rejoindre notre équipe.",
            "Marie": "Bonjour ! Je suis Marie, votre cliente. Je suis curieuse de découvrir votre présentation. Commencez quand vous êtes prêt !"
        }
        
        welcome_text = welcome_messages.get(
            self.current_scenario.character_name,
            "Bonjour ! Commençons cet exercice ensemble."
        )
        
        # Envoi message de bienvenue
        await self.send_conversation_update("", welcome_text)
        
        # Synthèse vocale du message de bienvenue
        welcome_audio = await self.synthesize_speech(welcome_text)
        await self.send_ai_audio_to_room(welcome_audio)
    
    async def synthesize_speech(self, text: str) -> bytes:
        """Synthèse vocale du texte"""
        try:
            # TODO: Intégrer service TTS réel (Azure, Google, etc.)
            # Pour l'instant, retourne données audio simulées
            self.logger.info(f"🔊 Synthèse: '{text[:50]}...'")
            return b"audio_data_placeholder"
        except Exception as e:
            self.logger.error(f"Erreur synthèse vocale: {e}")
            return b""
    
    async def send_ai_audio_to_room(self, audio_data: bytes):
        """Envoi audio IA dans la room"""
        try:
            if self.room and audio_data:
                # TODO: Créer track audio et publier
                # audio_source = rtc.AudioSource(sample_rate=16000, num_channels=1)
                # track = rtc.LocalAudioTrack.create_audio_track("ai-voice", audio_source)
                # await self.room.local_participant.publish_track(track)
                self.logger.info("🔊 Audio IA envoyé")
        except Exception as e:
            self.logger.error(f"Erreur envoi audio: {e}")
    
    # === MÉTHODES UTILITAIRES ===
    
    def is_complete_sentence(self, text: str) -> bool:
        """Détecte si la phrase est complète"""
        text = text.strip()
        return (len(text) > 5 and
                (text.endswith(('.', '!', '?')) or
                 len(text.split()) >= 4))  # ou phrase de 4+ mots
    
    def is_appropriate_response(self, response: str) -> bool:
        """Vérifie si la réponse IA est appropriée"""
        inappropriate_keywords = ["inapproprié", "offensant", "erreur"]
        return not any(keyword in response.lower() for keyword in inappropriate_keywords)
    
    def get_fallback_response(self) -> str:
        """Réponse de fallback selon le scénario"""
        if not self.current_scenario:
            return "Je vous écoute, continuez..."
            
        fallback_responses = {
            "Thomas": "Très intéressant. Pouvez-vous me donner plus de détails ?",
            "Marie": "C'est un bon point. Comment comptez-vous concrètement procéder ?"
        }
        
        return fallback_responses.get(
            self.current_scenario.character_name,
            "Je vous écoute, continuez..."
        )
    
    async def update_conversation_phase(self):
        """Met à jour la phase de conversation"""
        if not self.current_scenario:
            return
            
        conversation_length = len(self.conversation_context)
        
        if conversation_length <= 4:
            self.current_scenario.phase = "introduction"
        elif conversation_length <= 12:
            self.current_scenario.phase = "development"
        else:
            self.current_scenario.phase = "conclusion"
    
    async def finalize_session(self):
        """Finalise la session et génère le rapport"""
        try:
            session_duration = time.time() - self.session_start_time
            
            # Calcul scores finaux
            avg_metrics = self.calculate_average_metrics()
            
            # Génération rapport final
            final_report = {
                "type": "session_complete",
                "data": {
                    "duration": session_duration,
                    "metrics": avg_metrics,
                    "conversation_length": len(self.conversation_context),
                    "scenario": self.current_scenario.__dict__ if self.current_scenario else {},
                    "timestamp": time.time()
                }
            }
            
            if self.room:
                await self.room.local_participant.publish_data(
                    json.dumps(final_report).encode(),
                    reliable=True
                )
                
            self.logger.info(f"✅ Session finalisée: {session_duration:.1f}s")
            
        except Exception as e:
            self.logger.error(f"Erreur finalisation: {e}")
    
    def calculate_average_metrics(self) -> Dict:
        """Calcule les métriques moyennes de la session"""
        if not self.metrics_history:
            return {"confidence": 0.5, "clarity": 0.5, "pace": 0.5, "energy": 0.5, "fluency": 0.5}
        
        avg_confidence = sum(m.confidence_score for m in self.metrics_history) / len(self.metrics_history)
        avg_clarity = sum(m.clarity_score for m in self.metrics_history) / len(self.metrics_history)
        avg_pace = sum(m.pace_score for m in self.metrics_history) / len(self.metrics_history)
        avg_energy = sum(m.energy_score for m in self.metrics_history) / len(self.metrics_history)
        avg_fluency = sum(m.fluency_score for m in self.metrics_history) / len(self.metrics_history)
        
        return {
            "confidence": round(avg_confidence, 2),
            "clarity": round(avg_clarity, 2),
            "pace": round(avg_pace, 2),
            "energy": round(avg_energy, 2),
            "fluency": round(avg_fluency, 2)
        }

# === POINT D'ENTRÉE PRINCIPAL ===

async def main():
    """Point d'entrée principal de l'agent unifié"""
    import os
    
    # Configuration depuis variables d'environnement
    room_name = os.getenv("LIVEKIT_ROOM", "confidence-boost")
    livekit_url = os.getenv("LIVEKIT_URL", "ws://localhost:7880")
    livekit_token = os.getenv("LIVEKIT_TOKEN", "token-placeholder")
    
    # Scénario par défaut (peut être overridé par l'API)
    default_scenario = {
        "type": "interview",
        "difficulty": "facile",
        "character": "Thomas"
    }
    
    print("🚀 Démarrage UnifiedConfidenceAgent...")
    print(f"   Room: {room_name}")
    print(f"   URL LiveKit: {livekit_url}")
    print(f"   Scénario: {default_scenario}")
    
    try:
        # Initialisation agent
        agent = UnifiedConfidenceAgent()
        
        # Connexion à la room avec scénario
        await agent.connect_to_room(room_name, livekit_token, default_scenario)
        
        print("✅ Agent connecté avec succès !")
        print("🎯 En attente des participants...")
        
        # Maintenir la connexion active
        while True:
            await asyncio.sleep(1)
            
    except KeyboardInterrupt:
        print("\n⏹️  Arrêt de l'agent...")
    except Exception as e:
        print(f"❌ Erreur critique: {e}")
        raise

if __name__ == "__main__":
    # Configuration logging pour production
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler('/tmp/livekit-agent.log') if os.path.exists('/tmp') else logging.NullHandler()
        ]
    )
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Au revoir !")
    except Exception as e:
        print(f"💥 Erreur fatale: {e}")
        exit(1)
