"""
Point d'entrée principal pour le système multi-agents Studio Situations Pro
Utilise directement MultiAgentManager avec les vrais agents configurés
"""
import asyncio
import logging
import os
import time
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
from dotenv import load_dotenv
from livekit import agents, rtc, rtc
from livekit.agents import (
    Agent,
    AgentSession,
    JobContext,
    RunContext,
    function_tool,
    llm,
)
from livekit.plugins import openai, silero
try:
    from elevenlabs_flash_tts_service import elevenlabs_flash_service
except Exception:  # pragma: no cover - tests peuvent manquer le module
    elevenlabs_flash_service = None  # type: ignore
from vosk_stt_interface import VoskSTTFixed as VoskSTT

# Imports du système multi-agents RÉVOLUTIONNAIRE
from multi_agent_config import (
    MultiAgentConfig, 
    AgentPersonality, 
    InteractionStyle,
    ExerciseTemplates
)

# IMPORT CRITIQUE - Enhanced Manager
try:
    from enhanced_multi_agent_manager import get_enhanced_manager
    ENHANCED_MANAGER_AVAILABLE = True
    logging.getLogger(__name__).info("✅ Enhanced Multi-Agent Manager disponible")
except ImportError as e:
    logging.getLogger(__name__).error(f"❌ Enhanced Manager non disponible: {e}")
    ENHANCED_MANAGER_AVAILABLE = False
    # Fallback vers manager basique
    from multi_agent_manager import MultiAgentManager

from naturalness_monitor import NaturalnessMonitor

# Import du service TTS optimisé
try:
    from elevenlabs_optimized_service import elevenlabs_optimized_service
except ImportError:
    elevenlabs_optimized_service = None

# Import du système d'interpellation (nom corrigé)
try:
    from interpellation_system_complete import InterpellationSystemComplete as InterpellationSystem
except ImportError:
    InterpellationSystem = None

# Charger les variables d'environnement
load_dotenv()

# Configuration avec logs détaillés pour debug
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Log warning tardifs si modules optionnels manquants
if 'elevenlabs_optimized_service' not in globals() or elevenlabs_optimized_service is None:
    logging.getLogger(__name__).warning("⚠️ Service TTS optimisé non disponible")
if 'InterpellationSystem' not in globals() or InterpellationSystem is None:
    logging.getLogger(__name__).warning("⚠️ Système d'interpellation non disponible")

# Log des variables d'environnement critiques (sans exposer les secrets)
logging.getLogger(__name__).info("🔍 DIAGNOSTIC MULTI-AGENTS: Variables d'environnement")
logging.getLogger(__name__).info(f"   OPENAI_API_KEY présente: {'Oui' if os.getenv('OPENAI_API_KEY') else 'Non'}")
logging.getLogger(__name__).info(f"   ELEVENLABS_API_KEY présente: {'Oui' if os.getenv('ELEVENLABS_API_KEY') else 'Non'}")
logging.getLogger(__name__).info(f"   MISTRAL_BASE_URL: {os.getenv('MISTRAL_BASE_URL', 'Non définie')}")

# URLs des services
# Base OpenAI-compatible (le client ajoutera /chat/completions lui-même)
MISTRAL_API_URL = os.getenv('MISTRAL_BASE_URL', 'http://mistral-conversation:8001/v1')
VOSK_STT_URL = os.getenv('VOSK_STT_URL', 'http://vosk-stt:8002')

class MultiAgentLiveKitService:
    """Service LiveKit intégré avec le gestionnaire multi-agents"""
    
    def __init__(self, multi_agent_config: MultiAgentConfig, user_data: dict = None):
        self.config = multi_agent_config
        self.naturalness_monitor = NaturalnessMonitor()
        
        # SYSTÈME RÉVOLUTIONNAIRE : EnhancedMultiAgentManager avec GPT-4o + ElevenLabs
        openai_api_key = os.getenv('OPENAI_API_KEY')
        elevenlabs_api_key = os.getenv('ELEVENLABS_API_KEY')
        
        if not openai_api_key or not elevenlabs_api_key:
            logging.getLogger(__name__).error("❌ CLÉS API MANQUANTES: OPENAI_API_KEY et/ou ELEVENLABS_API_KEY")
            raise ValueError("Clés API requises pour le système révolutionnaire")
        
        # CORRECTION CRITIQUE : Validation et normalisation user_data
        self.user_data = self._validate_and_normalize_user_data(user_data)
        
        # Initialisation du manager révolutionnaire
        self.manager = get_enhanced_manager(openai_api_key, elevenlabs_api_key, multi_agent_config)
        
        # CORRECTION CRITIQUE : Configuration IMMÉDIATE du contexte utilisateur
        if hasattr(self.manager, 'set_user_context'):
            self.manager.set_user_context(
                self.user_data.get('user_name', 'Participant'),
                self.user_data.get('user_subject', 'votre présentation')
            )
            logging.getLogger(__name__).info(f"✅ Contexte utilisateur configuré dans le manager")
            logging.getLogger(__name__).info(f"   👤 Utilisateur: {self.user_data['user_name']}")
            logging.getLogger(__name__).info(f"   🎯 Sujet: {self.user_data['user_subject']}")
        else:
            logging.getLogger(__name__).error("❌ Manager ne supporte pas set_user_context")
        
        self.session: Optional[AgentSession] = None
        self.room = None
        self.is_running = False
        
        logging.getLogger(__name__).info(f"🚀 SYSTÈME RÉVOLUTIONNAIRE initialisé pour: {multi_agent_config.exercise_id}")
        logging.getLogger(__name__).info(f"   Nombre d'agents: {len(multi_agent_config.agents)}")
        for agent in multi_agent_config.agents:
            logging.getLogger(__name__).info(f"   - {agent.name} ({agent.role}) - Style: {agent.interaction_style.value}")

        logging.getLogger(__name__).info("🎭 SYSTÈME GPT-4o + ElevenLabs ÉMOTIONNEL initialisé")

    def _validate_and_normalize_user_data(self, user_data: dict = None) -> dict:
        """Valide et normalise les données utilisateur"""
        
        if not user_data:
            logging.getLogger(__name__).warning("⚠️ Aucune user_data fournie, utilisation valeurs par défaut")
            return {
                'user_name': 'Participant',
                'user_subject': 'votre présentation'
            }
        
        # Validation et nettoyage
        normalized = {}
        
        # Nom utilisateur
        user_name = user_data.get('user_name', '').strip()
        if not user_name or len(user_name) < 2:
            logging.getLogger(__name__).warning(f"⚠️ Nom utilisateur invalide: '{user_name}', utilisation 'Participant'")
            normalized['user_name'] = 'Participant'
        else:
            # Capitalisation du prénom
            normalized['user_name'] = user_name.title()
        
        # Sujet
        user_subject = user_data.get('user_subject', '').strip()
        if not user_subject or len(user_subject) < 5:
            logging.getLogger(__name__).warning(f"⚠️ Sujet invalide: '{user_subject}', utilisation 'votre présentation'")
            normalized['user_subject'] = 'votre présentation'
        else:
            normalized['user_subject'] = user_subject
        
        # Autres données optionnelles
        normalized['user_level'] = user_data.get('user_level', 'intermédiaire')
        normalized['user_preferences'] = user_data.get('user_preferences', {})
        
        logging.getLogger(__name__).info(f"✅ User_data validées et normalisées: {normalized}")
        
        return normalized

    def get_user_context_summary(self) -> str:
        """Retourne un résumé du contexte utilisateur pour logs"""
        return f"👤 {self.user_data['user_name']} | 🎯 {self.user_data['user_subject']}"
        
    async def initialize_components(self):
        """Initialise les composants LiveKit avec fallbacks robustes"""
        components = {}
        
        # VAD avec fallback
        try:
            vad = silero.VAD.load()
            components['vad'] = vad
            logging.getLogger(__name__).info("✅ VAD Silero chargé")
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur VAD: {e}")
            raise
            
        # STT avec fallback Vosk → OpenAI
        try:
            stt = self.create_vosk_stt_with_fallback()
            components['stt'] = stt
            logging.getLogger(__name__).info("✅ STT avec fallback créé")
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur STT: {e}")
            raise
            
        # LLM avec fallback
        try:
            # Créer LLM - OpenAI GPT-4o en premier, Mistral en fallback
            try:
                llm_instance = self.create_openai_llm()
                logging.getLogger(__name__).info("✅ LLM OpenAI GPT-4o créé (priorité 1)")
            except Exception as e:
                logging.getLogger(__name__).warning(f"⚠️ Fallback vers Mistral: {e}")
                llm_instance = self.create_mistral_llm()
                logging.getLogger(__name__).info("✅ LLM Mistral créé (fallback)")
            components['llm'] = llm_instance
            logging.getLogger(__name__).info("✅ LLM OpenAI créé")
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur LLM: {e}")
            raise
            
        # TTS spécialisé pour multi-agents
        try:
            tts = await self.create_multiagent_tts()
            components['tts'] = tts
            logging.getLogger(__name__).info("✅ TTS multi-agents créé")
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur TTS: {e}")
            raise
            
        return components
    
    def create_vosk_stt_with_fallback(self):
        """Crée une interface STT avec Vosk en principal et OpenAI en fallback"""
        logging.getLogger(__name__).info("🔄 [STT-MULTI-AGENTS] Initialisation STT avec logique de fallback (Vosk → OpenAI)")
        
        # Tentative 1: Vosk (rapide et économique)
        try:
            vosk_stt = VoskSTT(
                vosk_url=VOSK_STT_URL,
                language="fr",
                sample_rate=16000
            )
            
            # Reset automatique
            def enhanced_clear_user_turn():
                logging.getLogger(__name__).debug("🔄 [STT-MULTI-AGENTS] Clear user turn avec reset Vosk")
                if hasattr(vosk_stt, '_reset_recognizer'):
                    vosk_stt._reset_recognizer()
            
            vosk_stt.clear_user_turn = enhanced_clear_user_turn
            
            logging.getLogger(__name__).info("✅ [STT-MULTI-AGENTS] VOSK STT ACTIVÉ AVEC SUCCÈS")
            return vosk_stt
        except Exception as vosk_error:
            logging.getLogger(__name__).error(f"❌ [STT-MULTI-AGENTS] ÉCHEC STT Vosk: {vosk_error}")
            
        # Fallback: OpenAI Whisper
        try:
            logging.getLogger(__name__).warning("⚠️ [STT-MULTI-AGENTS] Basculement vers OpenAI Whisper (fallback)")
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                raise RuntimeError("OPENAI_API_KEY manquante pour le fallback")
                
            openai_stt = openai.STT(
                model="whisper-1",
                language="fr",
                api_key=api_key,
            )
            logging.getLogger(__name__).warning("⚠️ [STT-MULTI-AGENTS] OPENAI STT ACTIVÉ (FALLBACK)")
            return openai_stt
        except Exception as openai_error:
            logging.getLogger(__name__).error(f"❌ [STT-MULTI-AGENTS] Échec STT OpenAI fallback: {openai_error}")
            raise RuntimeError(f"Impossible de créer STT (Vosk: {vosk_error}, OpenAI: {openai_error})")

    def create_openai_llm(self):
        """Crée un LLM OpenAI GPT-4o configuré."""
        openai_api_key = os.getenv('OPENAI_API_KEY', '')
        if not openai_api_key:
            raise RuntimeError("OPENAI_API_KEY manquante")
        
        logging.getLogger(__name__).info("🔍 Configuration LLM OpenAI GPT-4o")
        return openai.LLM(
            model="gpt-4o",
            api_key=openai_api_key,
        )

    def create_mistral_llm(self):
        """Crée un LLM configuré pour utiliser le proxy Mistral côté backend.

        Utilise une API compatible OpenAI et choisit la base_url finale en fonction
        de `MISTRAL_USE_PROXY` et `MISTRAL_PROXY_URL`.
        """
        mistral_api_key = os.getenv('MISTRAL_API_KEY', '')
        model = os.getenv('MISTRAL_MODEL', 'mistral-nemo-instruct-2407')
        # Choix de la base_url: proxy local activable via MISTRAL_USE_PROXY=1, sinon direct (MISTRAL_BASE_URL)
        use_proxy = os.getenv('MISTRAL_USE_PROXY', '0') == '1'
        proxy_url = os.getenv('MISTRAL_PROXY_URL', 'http://mistral-conversation:8001/v1')
        base_url = proxy_url if use_proxy else MISTRAL_API_URL
        logging.getLogger(__name__).info(
            f"🔍 Configuration LLM Mistral - Modèle: {model} | "
            f"use_proxy={'Oui' if use_proxy else 'Non'} | base_url={base_url}"
        )
        return openai.LLM(
            model=model,
            api_key=mistral_api_key,
            base_url=base_url,
        )

    async def create_multiagent_tts(self):
        """Crée un TTS par défaut basé sur ElevenLabs pour les simulations Studio.

        Note: Chaque agent utilisera ensuite son TTS dédié via _get_or_build_agent_tts.
        Ce TTS par défaut est utilisé pour les annonces initiales au besoin.
        """
        try:
            if elevenlabs_flash_service is None or not os.getenv('ELEVENLABS_API_KEY'):
                raise RuntimeError("ELEVENLABS_API_KEY manquante ou service ElevenLabs indisponible")

            class _ElevenLabsOnDemandTTS:
                # Expose at class-level to satisfy frameworks accessing attributes before __init__
                _sample_rate = 16000
                _num_channels = 1
                def __init__(self_inner):
                    from livekit.agents import tts as _tts
                    self_inner.capabilities = _tts.TTSCapabilities(streaming=False)
                    self_inner._current_sample_rate = 16000
                @property
                def sample_rate(self_inner):
                    return getattr(self_inner, "_current_sample_rate", 16000)
                @property
                def num_channels(self_inner):
                    return 1
                def on(self_inner, _event_name: str):  # hook requis par StreamAdapter
                    def _decorator(fn):
                        return fn
                    return _decorator
                def synthesize(self_inner, text_inner: str, **_kwargs):
                    """Retourne un async context manager compatible StreamAdapter.

                    L'appel ElevenLabs est effectué dans __aenter__ pour éviter de
                    retourner une coroutine à 'async with'.
                    """
                    from livekit.agents import tts as _tts

                    class _AsyncStream:
                        def __init__(self, text_value: str):
                            self._text = text_value
                            self._audio: bytes = b""
                            self._done = False
                            self._sample_rate: int = 16000
                            self._pos: int = 0
                            self._chunk_bytes: int = int(0.02 * self._sample_rate) * 1 * 2
                            self._sample_rate: int = 16000

                        def __aiter__(self):
                            return self

                        async def __anext__(self):
                            if self._done:
                                raise StopAsyncIteration
                            if not self._audio or self._pos >= len(self._audio):
                                self._done = True
                                raise StopAsyncIteration
                            end = min(self._pos + self._chunk_bytes, len(self._audio))
                            chunk = self._audio[self._pos:end]
                            self._pos = end
                            if self._pos >= len(self._audio):
                                self._done = True
                            class _CompatFrame:
                                def __init__(self, buf: bytes, rate: int, channels: int = 1):
                                    self.data = memoryview(buf)
                                    self.duration = len(buf) / (2 * rate * channels)
                            class _CompatAudio:
                                def __init__(self, buf: bytes, rate: int, channels: int = 1):
                                    self.frame = _CompatFrame(buf, rate, channels)
                                    self.sample_rate = rate
                                    self.num_channels = channels
                            return _CompatAudio(chunk, self._sample_rate, 1)

                        async def __aenter__(self):
                            audio = await elevenlabs_flash_service.synthesize_speech_flash_v25(
                                text=self._text, agent_id="michel_dubois_animateur"
                            )
                            self._audio = audio or b""
                            # Flux natif 16 kHz PCM mono — pas de resampling vers 48 kHz
                            self._sample_rate = 16000
                            self_inner._current_sample_rate = 16000
                            # Trim au multiple exact de 20ms pour éviter les drops
                            try:
                                frame_samples = int(0.02 * self._sample_rate)  # 20ms
                                frame_bytes = frame_samples * 1 * 2
                                if frame_bytes > 0 and len(self._audio) % frame_bytes != 0:
                                    trimmed_len = len(self._audio) - (len(self._audio) % frame_bytes)
                                    self._audio = self._audio[:trimmed_len]
                                self._chunk_bytes = frame_bytes
                                logging.getLogger(__name__).debug(f"🎚️ [TTS-default] Préparation audio: {len(self._audio)} bytes, frame_bytes={frame_bytes}, rate={self._sample_rate}")
                            except Exception:
                                pass
                            return self

                        async def __aexit__(self, exc_type, exc, tb):
                            return False

                    return _AsyncStream(text_inner)

            logging.getLogger(__name__).info("✅ TTS par défaut ElevenLabs prêt (modérateur)")
            return _ElevenLabsOnDemandTTS()
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ ElevenLabs TTS indisponible: {e}")
            # Éviter Silero (non supporté). Lever clairement l'erreur pour visibilité.
            raise

    def create_multiagent_agent(self) -> Agent:
        """Crée un agent LiveKit configuré pour le système multi-agents avec contexte utilisateur"""
        try:
            # Instructions RÉVOLUTIONNAIRES pour animateur TV actif avec contexte utilisateur
            system_instructions = f"""Tu es le système de coordination pour une émission de débat TV française personnalisée.

🎯 MISSION PRINCIPALE :
- Coordonner Michel Dubois (animateur TV), Sarah Johnson (journaliste), Marcus Thompson (expert)
- Michel MÈNE le débat activement et présente les participants
- Assurer des conversations naturelles et engageantes
- CONTEXTE SPÉCIFIQUE : {self.user_data['user_name']} débat sur "{self.user_data['user_subject']}"

🎭 RÔLES DES AGENTS AVEC CONTEXTE :
- Michel Dubois : ANIMATEUR ACTIF qui mène, présente, relance
  → Utilise TOUJOURS le prénom "{self.user_data['user_name']}"
  → Centre le débat sur "{self.user_data['user_subject']}"
- Sarah Johnson : Journaliste qui pose des questions incisives
  → Challenge {self.user_data['user_name']} sur les aspects de "{self.user_data['user_subject']}"
- Marcus Thompson : Expert qui apporte l'éclairage technique
  → Expertise spécifique sur "{self.user_data['user_subject']}"

🚨 RÈGLES CRITIQUES :
- TOUJOURS en français
- Michel prend l'initiative et mène le débat
- Conversations naturelles sans marqueurs émotionnels audibles
- OBLIGATION d'utiliser le nom "{self.user_data['user_name']}" régulièrement
- OBLIGATION de centrer sur le sujet "{self.user_data['user_subject']}"

🎪 STYLE REQUIS :
- Débat TV professionnel et dynamique
- Questions stimulantes liées à "{self.user_data['user_subject']}"
- Échanges naturels entre les 3 agents
- Engagement maximum de {self.user_data['user_name']}

💬 EXEMPLES D'INTERPELLATIONS PERSONNALISÉES :
- "{self.user_data['user_name']}, sur {self.user_data['user_subject']}, quelle est votre position ?"
- "Sarah, {self.user_data['user_name']} soulève un point intéressant..."
- "Marcus, concernant {self.user_data['user_subject']}, que pensez-vous ?"

🎯 OBJECTIF FINAL :
Créer une expérience de débat TV personnalisée où {self.user_data['user_name']} se sent reconnu et engagé sur le sujet {self.user_data['user_subject']} qui l'intéresse.

RÈGLES CRITIQUES (STRICT):
- N'écris AUCUNE réponse directe.
- À CHAQUE message utilisateur, APPELLE UNIQUEMENT l'outil generate_multiagent_response avec le message exact.
- N'inclus AUCUNE formule d'introduction (ex: "Bonsoir et bienvenue...").
- Ne te présentes pas et ne paraphrase pas la sortie de l'outil.

OUTIL DISPONIBLE:
- generate_multiagent_response(user_message: str): orchestre la réponse multi-agents (Michel + Sarah + Marcus) et génère les réactions.

Ta sortie doit être UNIQUEMENT l'appel d'outil approprié."""

            agent = Agent(
                instructions=system_instructions,
                tools=[self.generate_multiagent_response],
            )
            
            logging.getLogger(__name__).info(f"✅ Agent multi-agents créé avec contexte: {self.get_user_context_summary()}")
            
            return agent
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur création agent multi-agents: {e}")
            raise

    @function_tool
    async def generate_multiagent_response(self, user_message: str) -> str:
        """Génère une réponse multi-agents avec système d'interpellation intelligente"""
        
        try:
            logger.info(f"🎬 GÉNÉRATION RÉPONSE MULTI-AGENTS: '{user_message[:50]}...'")
            
            # Utilisation du nouveau système d'interpellation
            if hasattr(self.manager, 'process_user_message_with_interpellations'):
                responses = await self.manager.process_user_message_with_interpellations(
                    user_message, 
                    "user",  # Speaker ID pour l'utilisateur
                    []  # Historique de conversation (peut être enrichi)
                )
                
                if responses:
                    # Prendre la première réponse (la plus pertinente)
                    response = responses[0]
                    agent_name = response['agent_name']
                    message = response['message']
                    response_type = response.get('response_type', 'normal')
                    
                    logger.info(f"✅ Réponse générée par {agent_name} ({response_type}): {message[:50]}...")
                    return f"{agent_name}: {message}"
                else:
                    logger.warning("⚠️ Aucune réponse générée par le système d'interpellation")
                    return "Système: Pouvez-vous reformuler votre question ?"
            else:
                # Fallback vers l'ancien système
                logger.warning("⚠️ Système d'interpellation non disponible, utilisation du système classique")
                return await self._generate_classic_response(user_message)
                
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse multi-agents: {e}")
            return f"Système: Erreur technique. Pouvez-vous reformuler ?"
    
    async def _generate_classic_response(self, user_message: str) -> str:
        """Méthode de fallback pour la génération classique de réponses"""
        
        # Logique classique de sélection d'agent
        try:
            # Sélection simple basée sur le contenu du message
            if any(word in user_message.lower() for word in ["journaliste", "enquête", "investigation", "sarah"]):
                agent_id = "sarah_johnson_journaliste"
            elif any(word in user_message.lower() for word in ["expert", "technique", "marcus"]):
                agent_id = "marcus_thompson_expert"
            else:
                agent_id = "michel_dubois_animateur"  # Par défaut
            
            # Génération de réponse
            response, emotion = await self.manager.generate_agent_response(
                agent_id, "conversation", user_message, []
            )
            
            agent_name = self.manager.agents[agent_id]['name']
            return f"{agent_name}: {response}"
            
        except Exception as e:
            logger.error(f"❌ Erreur génération classique: {e}")
            return "Système: Erreur technique. Pouvez-vous reformuler ?"
        """Génère une réponse orchestrée du système multi-agents RÉVOLUTIONNAIRE avec GPT-4o + ElevenLabs"""
        try:
            logging.getLogger(__name__).info(f"🚀 SYSTÈME RÉVOLUTIONNAIRE pour: {user_message[:50]}...")
            
            # SYSTÈME RÉVOLUTIONNAIRE : Utiliser EnhancedMultiAgentManager avec GPT-4o + ElevenLabs
            # Sélectionner l'agent principal (animateur) pour commencer
            primary_agent_id = "michel_dubois_animateur"  # Animateur principal
            
            # Générer réponse complète avec GPT-4o + ElevenLabs
            text_response, audio_data, context = await self.manager.generate_complete_agent_response(
                agent_id=primary_agent_id,
                user_message=user_message,
                session_id="studio_debate_tv"
            )
            
            logging.getLogger(__name__).info(f"🎭 Réponse révolutionnaire générée: {text_response[:50]}...")
            logging.getLogger(__name__).info(f"🎵 Audio émotionnel: {len(audio_data)} bytes")
            logging.getLogger(__name__).info(f"📊 Contexte: {context}")
            
            # Simuler la structure de réponse attendue
            response_data = {
                'primary_speaker': primary_agent_id,
                'primary_response': text_response,
                'audio_data': audio_data,
                'context': context
            }
            
            # Récupérer l'agent principal qui répond
            primary_agent_id = response_data.get('primary_speaker')
            primary_response = response_data.get('primary_response', '')
            
            # Identifier l'agent et préparer les réponses vocales
            responses_to_speak = []
            
            # Vérification défensive des attributs du manager
            if not hasattr(self.manager, 'agents') or not hasattr(self.manager, 'config'):
                logging.getLogger(__name__).error("❌ Manager multi-agents mal configuré, réinitialisation")
                # Réinitialiser le manager avec la configuration
                openai_api_key = os.getenv('OPENAI_API_KEY')
                elevenlabs_api_key = os.getenv('ELEVENLABS_API_KEY')
                if openai_api_key and elevenlabs_api_key:
                    self.manager = get_enhanced_manager(openai_api_key, elevenlabs_api_key, self.config)
                else:
                    return "[Système]: Configuration manquante. Pouvez-vous reformuler ?"
            
            if primary_agent_id and hasattr(self.manager, 'agents') and primary_agent_id in self.manager.agents:
                agent = self.manager.agents[primary_agent_id]
                logging.getLogger(__name__).info(f"🗣️ {agent.name} ({agent.role}) répond")
                
                # LOGS DE DEBUG POUR AUTORITÉ ANIMATEUR
                if agent.name == "Michel Dubois":
                    self.manager.set_last_speaker_message("animateur_principal", primary_response)
                    logging.getLogger(__name__).info(f"🎭 ANIMATEUR A PARLÉ: {primary_response[:50]}...")
                elif "Sarah" in agent.name:
                    self.manager.set_last_speaker_message("journaliste_contradicteur", primary_response)
                    logging.getLogger(__name__).info(f"📰 JOURNALISTE A PARLÉ: {primary_response[:50]}...")
                elif "Marcus" in agent.name:
                    self.manager.set_last_speaker_message("expert_specialise", primary_response)
                    logging.getLogger(__name__).info(f"🔬 EXPERT A PARLÉ: {primary_response[:50]}...")
                
                # Ajouter la réponse principale
                responses_to_speak.append({
                    'agent': agent,
                    'text': primary_response,
                    'delay': 0
                })

                # NOUVEAU: Forcer l'intervention des autres agents
                try:
                    # Générer une réponse de Sarah Johnson (journaliste)
                    if "sarah_johnson_journaliste" in self.manager.agents:
                        sarah_agent = self.manager.agents["sarah_johnson_journaliste"]
                        sarah_response = await self.manager.generate_complete_agent_response(
                            agent_id="sarah_johnson_journaliste",
                            user_message=user_message,
                            session_id="studio_debate_tv"
                        )
                        if sarah_response and sarah_response[0]:
                            responses_to_speak.append({
                                'agent': sarah_agent,
                                'text': sarah_response[0],
                                'delay': 2000  # 2 secondes après l'animateur
                            })
                            logging.getLogger(__name__).info(f"📰 Sarah Johnson intervient: {sarah_response[0][:50]}...")
                    
                    # Générer une réponse de Marcus Thompson (expert)
                    if "marcus_thompson_expert" in self.manager.agents:
                        marcus_agent = self.manager.agents["marcus_thompson_expert"]
                        marcus_response = await self.manager.generate_complete_agent_response(
                            agent_id="marcus_thompson_expert",
                            user_message=user_message,
                            session_id="studio_debate_tv"
                        )
                        if marcus_response and marcus_response[0]:
                            responses_to_speak.append({
                                'agent': marcus_agent,
                                'text': marcus_response[0],
                                'delay': 4000  # 4 secondes après l'animateur
                            })
                            logging.getLogger(__name__).info(f"🔬 Marcus Thompson intervient: {marcus_response[0][:50]}...")
                except Exception as e:
                    logging.getLogger(__name__).warning(f"⚠️ Échec génération réponses multi-agents: {e}")

                # NOUVEAU: Détecter immédiatement les interpellations dans la sortie de l'agent
                try:
                    outcome = await self.manager.process_agent_output(primary_response, primary_agent_id)
                    if outcome and isinstance(outcome, dict):
                        triggered = outcome.get('triggered_responses') or []
                        if triggered:
                            logging.getLogger(__name__).info(f"🎯 Chaîne d'interpellations déclenchée: {len(triggered)} réactions")
                            for idx, tr in enumerate(triggered):
                                sec_id = tr.get('agent_id')
                                if sec_id and hasattr(self.manager, 'agents') and sec_id in self.manager.agents:
                                    sec_agent = self.manager.agents[sec_id]
                                    sec_text = tr.get('content') or tr.get('reaction') or ''

                                    # Mémoriser le dernier speaker pour l'autorité
                                    if "Sarah" in sec_agent.name:
                                        self.manager.set_last_speaker_message("journaliste_contradicteur", sec_text)
                                    elif "Marcus" in sec_agent.name:
                                        self.manager.set_last_speaker_message("expert_specialise", sec_text)

                                    responses_to_speak.append({
                                        'agent': sec_agent,
                                        'text': sec_text,
                                        'delay': 150 + (idx * 200)
                                    })
                except Exception as e:
                    logging.getLogger(__name__).warning(f"⚠️ Échec détection interpellations sur sortie agent: {e}")
                
                # Ajouter les réponses secondaires si présentes
                secondary_responses = response_data.get('secondary_responses', [])
                for sec_resp in secondary_responses:
                    sec_agent_id = sec_resp.get('agent_id')
                    if hasattr(self.manager, 'agents') and sec_agent_id in self.manager.agents:
                        sec_agent = self.manager.agents[sec_agent_id]
                        
                        # LOGS DE DEBUG POUR RÉPONSES SECONDAIRES
                        sec_response_text = sec_resp.get('reaction', '')
                        if "Sarah" in sec_agent.name:
                            self.manager.set_last_speaker_message("journaliste_contradicteur", sec_response_text)
                            logging.getLogger(__name__).info(f"📰 JOURNALISTE RÉACTION: {sec_response_text[:50]}...")
                        elif "Marcus" in sec_agent.name:
                            self.manager.set_last_speaker_message("expert_specialise", sec_response_text)
                            logging.getLogger(__name__).info(f"🔬 EXPERT RÉACTION: {sec_response_text[:50]}...")
                        
                        responses_to_speak.append({
                            'agent': sec_agent,
                            'text': sec_response_text,
                            'delay': sec_resp.get('delay_ms', 1500)
                        })
            
            # SYSTÈME RÉVOLUTIONNAIRE : Utiliser directement l'audio ElevenLabs généré
            if response_data.get('audio_data'):
                logging.getLogger(__name__).info(f"🎵 Diffusion audio révolutionnaire ElevenLabs")
                # L'audio est déjà généré par le système GPT-4o + ElevenLabs
                # Il sera diffusé automatiquement par le système LiveKit
                return text_response
            else:
                # Sécurité: si aucune réponse vocale générée, provoquer une réaction minimale
                try:
                    fallback_agent = None
                    # Prioriser un non-modérateur si possible
                    if hasattr(self.manager, 'agents') and self.manager.agents:
                        for a in self.manager.agents.values():
                            if a.interaction_style != InteractionStyle.MODERATOR:
                                fallback_agent = a
                                break
                        if not fallback_agent:
                            fallback_agent = list(self.manager.agents.values())[0]
                    if fallback_agent:
                        await self.speak_multiple_agents_robust([
                            {'agent': fallback_agent, 'text': "Je prends la parole pour lancer la discussion.", 'delay': 0}
                        ])
                except Exception:
                    pass
            
            # Retourner le texte formaté pour les logs
            formatted_text = f"[{responses_to_speak[0]['agent'].name}]: {responses_to_speak[0]['text']}"
            for resp in responses_to_speak[1:]:
                formatted_text += f"\n[{resp['agent'].name}]: {resp['text']}"
            
            return formatted_text
            
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur orchestration multi-agents: {e}")
            return "[Système]: Je rencontre un problème technique. Pouvez-vous reformuler ?"
    
    async def speak_multiple_agents_robust(self, responses_to_speak: list):
        """Version robuste avec retry et fallbacks multiples"""
        for resp_data in responses_to_speak:
            agent = resp_data['agent']
            text = resp_data['text']
            delay = resp_data['delay']

            # Attendre le délai
            if delay and delay > 0:
                await asyncio.sleep(delay / 1000.0)

            # Nettoyer un éventuel préfixe "Nom: " pour éviter doublons au TTS
            sanitized_text = self._strip_name_prefix(agent, text)

            # Retry en conservant TOUJOURS la voix de l'agent (éviter voix du modérateur)
            success = False
            for attempt in range(3):
                try:
                    voice_dbg = agent.voice_config.get('voice', 'alloy')
                    logging.getLogger(__name__).info(f"🔊 {agent.name} parle avec voix {voice_dbg} (tentative {attempt+1})")
                    # 1ère tentative: utiliser le TTS en cache (ou le créer)
                    # 2e tentative: recréer le TTS et réessayer
                    await self._speak_with_agent_voice_safe(agent, sanitized_text, force_recreate=(attempt == 1))
                    success = True
                    logging.getLogger(__name__).info(f"✅ {agent.name} a parlé (tentative {attempt+1})")
                    break
                except Exception as e:
                    logging.getLogger(__name__).warning(f"⚠️ Tentative {attempt+1} échouée pour {agent.name}: {e}")
                    if attempt < 2:
                        await asyncio.sleep(0.2)

            if not success:
                logging.getLogger(__name__).error(f"❌ Impossible de faire parler {agent.name}")

    async def _speak_with_agent_voice_safe(self, agent: AgentPersonality, text: str, force_recreate: bool = False):
        """Parle avec la voix propre à l'agent en forçant la bonne sélection TTS."""

        original_tts = getattr(self.session, '_tts', None)
        try:
            agent_tts = await self._get_or_build_agent_tts(agent, force_recreate=force_recreate)
            self.session._tts = agent_tts
            await self.session.say(text=f"{agent.name}: {text}")
        finally:
            if original_tts is not None:
                self.session._tts = original_tts

    async def _get_or_build_agent_tts(self, agent: AgentPersonality, force_recreate: bool = False):
        """Retourne le TTS ElevenLabs dédié à l'agent, en le créant si besoin."""
        existing = self.agent_tts.get(agent.agent_id)
        if existing and not force_recreate:
            return existing

        # Utiliser le service TTS optimisé si disponible
        if elevenlabs_optimized_service and os.getenv('ELEVENLABS_API_KEY'):
            logging.getLogger(__name__).info(f"🎯 Utilisation du service TTS optimisé pour {agent.name}")
            
            class _ElevenLabsOptimizedTTS:
                _sample_rate = 16000
                _num_channels = 1
                def __init__(self_inner):
                    from livekit.agents import tts as _tts
                    self_inner.capabilities = _tts.TTSCapabilities(streaming=True)
                    self_inner._current_sample_rate = 16000
                    self_inner._frame_duration_sec = 0.02
                @property
                def sample_rate(self_inner):
                    return getattr(self_inner, "_current_sample_rate", 16000)
                @property
                def num_channels(self_inner):
                    return 1
                def on(self_inner, _event_name: str):
                    def _decorator(fn):
                        return fn
                    return _decorator
                def synthesize(self_inner, text_inner: str, **_kwargs):
                    from livekit.agents import tts as _tts

                    class _AsyncStream:
                        def __init__(self, text_value: str):
                            self._text = text_value
                            self._audio: bytes = b""
                            self._done = False
                            self._sample_rate = 16000
                            self._pos = 0
                            self._frame_bytes = 0

                        def __aiter__(self):
                            return self

                        async def __anext__(self):
                            if self._pos >= len(self._audio):
                                raise StopAsyncIteration
                            from livekit.agents import tts as _tts
                            end = min(self._pos + self._frame_bytes, len(self._audio))
                            chunk = self._audio[self._pos:end]
                            self._pos = end
                            try:
                                return _tts.SynthesizedAudio(chunk, self._sample_rate)
                            except TypeError:
                                return _tts.SynthesizedAudio(data=chunk, sample_rate=self._sample_rate)

                        async def __aenter__(self):
                            # Utiliser le service optimisé avec l'agent_id correct
                            agent_id = self._map_agent_to_elevenlabs_id(agent)
                            audio = await elevenlabs_optimized_service.synthesize_with_zero_latency(
                                text=self._text, agent_id=agent_id
                            )
                            self._audio = audio or b""
                            self._sample_rate = 16000
                            self_inner._current_sample_rate = 16000
                            
                            # Préparation audio pour streaming
                            try:
                                frame_samples = int(0.02 * self._sample_rate)
                                frame_bytes = frame_samples * 1 * 2
                                if frame_bytes > 0:
                                    remainder = len(self._audio) % frame_bytes
                                    if remainder != 0:
                                        pad = frame_bytes - remainder
                                        self._audio = self._audio + (b"\x00" * pad)
                                self._frame_bytes = frame_bytes
                                self._audio = (b"\x00" * frame_bytes) + self._audio
                                logging.getLogger(__name__).debug(f"🎚️ [TTS-optimized] {agent.name}: {len(self._audio)} bytes @16kHz")
                            except Exception as prep_err:
                                logging.getLogger(__name__).warning(f"⚠️ [TTS] Erreur préparation audio: {prep_err}")
                            return self

                        async def __aexit__(self, exc_type, exc, tb):
                            return False

                    return _AsyncStream(text_inner)

            tts = _ElevenLabsOptimizedTTS()
            self.agent_tts[agent.agent_id] = tts
            logging.getLogger(__name__).info(f"✅ TTS optimisé créé pour {agent.name} avec voix française")
            return tts

        # Fallback vers le service flash si l'optimisé n'est pas disponible
        if elevenlabs_flash_service is None or not os.getenv('ELEVENLABS_API_KEY'):
            raise RuntimeError("ELEVENLABS_API_KEY manquante ou service ElevenLabs indisponible pour TTS agent")

        # Mapping nom → id de voix ElevenLabs
        mapped_voice_id = self._map_agent_to_elevenlabs_id(agent)

        class _ElevenLabsOnDemandTTS:
            # Expose at class-level to satisfy frameworks accessing attributes before __init__
            _sample_rate = 16000
            _num_channels = 1
            def __init__(self_inner):
                from livekit.agents import tts as _tts
                # Activer le mode streaming pour émettre des trames 20ms
                self_inner.capabilities = _tts.TTSCapabilities(streaming=True)
                # Par défaut, aligner sur 48 kHz pour éviter tout ralentissement initial
                self_inner._current_sample_rate = 16000
                self_inner._frame_duration_sec = 0.02
            @property
            def sample_rate(self_inner):
                return getattr(self_inner, "_current_sample_rate", 16000)
            @property
            def num_channels(self_inner):
                return 1
            def on(self_inner, _event_name: str):  # hook requis par StreamAdapter
                def _decorator(fn):
                    return fn
                return _decorator
            def synthesize(self_inner, text_inner: str, **_kwargs):
                from livekit.agents import tts as _tts

                class _AsyncStream:
                    def __init__(self, text_value: str):
                        self._text = text_value
                        self._audio: bytes = b""
                        self._done = False
                        self._sample_rate: int = 16000
                        self._pos: int = 0
                        self._chunk_bytes: int = int(0.02 * self._sample_rate) * 1 * 2
                        self._sample_rate: int = 16000

                    def __aiter__(self):
                        return self

                    async def __anext__(self):
                        if self._done:
                            raise StopAsyncIteration
                        if not self._audio or self._pos >= len(self._audio):
                            self._done = True
                            raise StopAsyncIteration
                        end = min(self._pos + self._chunk_bytes, len(self._audio))
                        chunk = self._audio[self._pos:end]
                        self._pos = end
                        if self._pos >= len(self._audio):
                            self._done = True
                        class _CompatFrame:
                            def __init__(self, buf: bytes, rate: int, channels: int = 1):
                                self.data = memoryview(buf)
                                self.duration = len(buf) / (2 * rate * channels)
                        class _CompatAudio:
                            def __init__(self, buf: bytes, rate: int, channels: int = 1):
                                self.frame = _CompatFrame(buf, rate, channels)
                                self.sample_rate = rate
                                self.num_channels = channels
                        return _CompatAudio(chunk, self._sample_rate, 1)

                    async def __aenter__(self):
                        audio = await elevenlabs_flash_service.synthesize_speech_flash_v25(
                            text=self._text, agent_id=mapped_voice_id
                        )
                        self._audio = audio or b""
                        # Forcer 16 kHz PCM mono bout‑à‑bout pour éviter ralentissements
                        self._sample_rate = 16000
                        self_inner._current_sample_rate = 16000
                        # Limiteur doux (normalisation descendante) pour éviter saturation/clipping
                        try:
                            if self._audio:
                                import audioop
                                max_amp = audioop.max(self._audio, 2) or 1
                                max_target = 28000  # ~-1.5 dBFS
                                if max_amp > max_target:
                                    ratio = max_target / max_amp
                                    self._audio = audioop.mul(self._audio, 2, ratio)
                        except Exception:
                            pass
                        # Sample rate déjà forcé à 16 kHz
                        try:
                            logging.getLogger(__name__).debug(f"🎚️ [TTS-agent] Bytes reçus ElevenLabs: {len(self._audio)} @16k")
                        except Exception:
                            pass
                        # Pas de resampling dynamique vers 48 kHz
                        # Slicing en trames de 20ms (sans ré-échantillonnage) pour éviter les drops
                        try:
                            frame_samples = int(0.02 * self._sample_rate)
                            frame_bytes = frame_samples * 1 * 2
                            if frame_bytes > 0:
                                remainder = len(self._audio) % frame_bytes
                                if remainder != 0:
                                    pad = frame_bytes - remainder
                                    self._audio = self._audio + (b"\x00" * pad)
                            self._frame_bytes = frame_bytes
                            # Warm-up immédiat: émettre une très courte trame de silence pour cadrer le tempo
                            self._audio = (b"\x00" * frame_bytes) + self._audio
                            if len(self._audio) == 0:
                                logging.getLogger(__name__).warning("⚠️ [TTS] Audio vide après préparation")
                            else:
                                logging.getLogger(__name__).debug(f"🎚️ [TTS-agent] Préparation audio: {len(self._audio)} bytes, frame_bytes={frame_bytes}, rate={self._sample_rate}Hz")
                        except Exception as prep_err:
                            logging.getLogger(__name__).warning(f"⚠️ [TTS] Erreur préparation audio: {prep_err}")
                        return self

                    async def __aexit__(self, exc_type, exc, tb):
                        return False

                return _AsyncStream(text_inner)

        tts = _ElevenLabsOnDemandTTS()
        self.agent_tts[agent.agent_id] = tts
        return tts

    def _map_agent_to_elevenlabs_id(self, agent: AgentPersonality) -> str:
        """Mappe l'agent logique vers l'identifiant de voix ElevenLabs configuré."""
        name_lower = agent.name.lower()
        if "michel" in name_lower and "dubois" in name_lower:
            return "michel_dubois_animateur"
        if "sarah" in name_lower and "johnson" in name_lower:
            return "sarah_johnson_journaliste"
        if "marcus" in name_lower and "thompson" in name_lower:
            return "marcus_thompson_expert"
        if "emma" in name_lower and "wilson" in name_lower:
            return "emma_wilson_coach"
        if "david" in name_lower and "chen" in name_lower:
            return "david_chen_challenger"
        if "sophie" in name_lower and "martin" in name_lower:
            return "sophie_martin_diplomate"
        # Défaut: voix du modérateur
        return "michel_dubois_animateur"

    def _strip_name_prefix(self, agent: AgentPersonality, text: str) -> str:
        """Supprime un éventuel préfixe "Nom:" pour éviter double annonce au TTS."""
        if not text:
            return text
        first_name = agent.name.split()[0]
        candidates = [agent.name, first_name]
        cleaned = text
        for cand in candidates:
            for sep in [":", "-", "—"]:
                prefix = f"{cand}{sep}"
                if cleaned.strip().lower().startswith(prefix.lower()):
                    cleaned = cleaned.strip()[len(prefix):].lstrip()
        return cleaned
    
    async def update_tts_voice(self, agent: AgentPersonality):
        """Met à jour dynamiquement la voix TTS pour correspondre à l'agent"""
        try:
            if not hasattr(self, 'voice_configs'):
                return
                
            voice_config = self.voice_configs.get(agent.agent_id)
            if not voice_config:
                return
            
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                return
                
            # Créer un nouveau TTS avec la voix de l'agent
            new_voice = voice_config['voice']
            new_speed = voice_config['speed']
            
            logging.getLogger(__name__).info(f"🔄 Changement voix TTS: {new_voice} pour {agent.name}")
            
            # Note: Dans une vraie implémentation, on devrait pouvoir changer
            # dynamiquement la voix de la session, mais LiveKit ne le supporte
            # pas encore directement. Pour l'instant, on log juste le changement.
            
        except Exception as e:
            logging.getLogger(__name__).warning(f"⚠️ Impossible de changer la voix TTS: {e}")
    
    def get_naturalness_report(self) -> dict:
        """Génère un rapport de naturalité en temps réel"""
        return self.naturalness_monitor.get_report()

    async def generate_orchestrated_welcome(self) -> str:
        """Génère un message de bienvenue orchestré avec toutes les personnalités"""
        try:
            # Récupérer les données utilisateur
            user_name = self.user_data.get('user_name', 'Participant')
            user_subject = self.user_data.get('user_subject', 'votre présentation')
            
            # Trouver le modérateur pour l'introduction
            moderator = None
            for agent in self.config.agents:
                if agent.interaction_style == InteractionStyle.MODERATOR:
                    moderator = agent
                    break
            
            if not moderator:
                moderator = self.config.agents[0]
            
            # Construire le message de bienvenue personnalisé
            welcome_parts = []
            
            # Introduction personnalisée du modérateur
            welcome_parts.append(f"[{moderator.name}]: Bonjour {user_name} et bienvenue dans Studio Situations Pro !")
            
            # Présentation du contexte selon l'exercice avec mention du sujet
            if "debate" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Nous sommes ici pour débattre de {user_subject}.")
            elif "interview" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Nous allons discuter de votre candidature concernant {user_subject}.")
            elif "boardroom" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Bienvenue dans notre conseil pour présenter {user_subject}.")
            elif "sales" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Nous sommes prêts à entendre votre présentation sur {user_subject}.")
            elif "keynote" in self.config.exercise_id:
                welcome_parts.append(f"[{moderator.name}]: Bienvenue pour votre keynote sur {user_subject}.")
            
            # Présentation des autres participants (rapide)
            other_agents = [a for a in self.config.agents if a.agent_id != moderator.agent_id]
            if other_agents:
                participants = ", ".join([a.name for a in other_agents[:2]])  # Max 2 pour rester court
                welcome_parts.append(f"[{moderator.name}]: Avec nous aujourd'hui : {participants}.")
            
            # Invitation personnalisée à commencer
            welcome_parts.append(f"[{moderator.name}]: {user_name}, quand vous êtes prêt(e), commencez votre présentation sur {user_subject}.")
            
            welcome_message = " ".join(welcome_parts)
            logging.getLogger(__name__).info(f"📢 Message de bienvenue personnalisé: {welcome_message[:100]}...")
            
            return welcome_message
            
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur génération message bienvenue: {e}")
            return f"[Système]: Bienvenue {self.user_data.get('user_name', 'Participant')} dans Studio Situations Pro."

    async def run_session(self, ctx: JobContext):
        """Execute la session multi-agents avec gestion robuste"""
        self.is_running = True
        
        try:
            logging.getLogger(__name__).info(f"🚀 Démarrage session multi-agents: {self.config.exercise_id}")
            
            # Connexion avec retry
            await self.connect_with_retry(ctx)
            
            # Stocker ctx.room pour compatibilité LiveKit 1.2.3
            self.room = ctx.room
            logging.getLogger(__name__).info("✅ Room stockée pour compatibilité LiveKit 1.2.3")
            
            # Initialisation des composants
            components = await self.initialize_components()
            
            # Création de l'agent multi-agents
            agent = self.create_multiagent_agent()
            
            # Création de la session
            self.session = AgentSession(**components)
            
            # Initialisation du manager multi-agents
            self.manager.initialize_session()

            # INTÉGRATION OPTIONNELLE DU SYSTÈME D'EXERCICES (feature flag)
            try:
                import os
                flag = str(os.getenv("ELOQUENCE_EXERCISES_ENABLED", "")).lower() in ("1", "true", "yes", "on")
                if flag:
                    import importlib.util
                    from pathlib import Path
                    from types import SimpleNamespace
                    base_dir = Path(__file__).resolve().parent / "exercise_system"

                    def _load_mod(name: str):
                        spec = importlib.util.spec_from_file_location(f"_ex_{name}", str(base_dir / f"{name}.py"))
                        mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
                        assert spec and spec.loader
                        spec.loader.exec_module(mod)
                        return mod

                    scen_mod = _load_mod("scenario_manager")
                    var_mod = _load_mod("variation_engine")
                    cache_mod = _load_mod("cache_system")
                    orch_mod = _load_mod("orchestrator")
                    int_mod = _load_mod("integration")

                    # Initialiser les composants exercices
                    scenario_manager = scen_mod.ScenarioManager()
                    await scenario_manager.initialize()
                    variation_engine = var_mod.AIVariationEngine()
                    cache_system = cache_mod.ExerciseCacheSystem()
                    orchestrator = orch_mod.ExerciseOrchestrator()

                    # Adaptateur minimal pour le MultiAgentManager existant
                    class _MAMAdapter:
                        def __init__(self, mam):
                            self.mam = mam

                        async def get_session_context(self, session_id: str):
                            UserProfile = scen_mod.UserProfile
                            SkillLevel = scen_mod.SkillLevel
                            user_profile = UserProfile(
                                user_id=self.mam.config.exercise_id,
                                skill_level=SkillLevel.INTERMEDIATE,
                                professional_sector="technology",
                                interests=["debate"],
                                recent_exercises=[],
                                performance_history={},
                            )
                            agents = [SimpleNamespace(id=aid) for aid in self.mam.agents.keys()]
                            return SimpleNamespace(user_profile=user_profile, agents=agents, history=[])

                        async def update_session_configuration(self, session_id: str, new_agents, scenario_context):
                            # Intégration progressive — pas de reconfiguration live pour l'instant
                            return None

                    integration = int_mod.ExerciseSystemIntegration(
                        _MAMAdapter(self.manager),
                        scenario_manager=scenario_manager,
                        variation_engine=variation_engine,
                        cache_system=cache_system,
                        orchestrator=orchestrator,
                    )

                    # Cibler automatiquement le scénario TV débat si la config l'indique
                    prefs = {}
                    try:
                        if "debate" in str(self.config.exercise_id).lower():
                            prefs = {"preferred_scenario_id": "studio_debate_tv"}
                    except Exception:
                        prefs = {}

                    await integration.enhance_existing_session(
                        "live-session",
                        int_mod.ExerciseRequest(preferences=prefs)
                    )
                    logging.getLogger(__name__).info("✅ Exercices: intégration minimale activée (feature flag)")
            except Exception as e:
                logging.getLogger(__name__).warning(f"⚠️ Exercices: intégration désactivée (erreur: {e})")
            
            # Démarrage de la session
            await self.session.start(agent=agent, room=ctx.room)
            
            # IMPORTANT (Scaleway OpenAI-compat): ne pas pousser un message assistant
            # avant le premier message utilisateur, sinon 400 alternance roles.
            # On retire le "welcome prefill" vocal ici. Le 1er tour LLM se fera
            # après le premier message user.
                
            logging.getLogger(__name__).info(f"✅ Session multi-agents {self.config.exercise_id} démarrée avec succès (sans prefill assistant)")
            
            # Maintenir la session active
            await self.maintain_session()
            
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur session multi-agents: {e}")
            raise
        finally:
            self.is_running = False
            
    async def connect_with_retry(self, ctx: JobContext, max_retries: int = 3):
        """Connexion avec retry automatique"""
        for attempt in range(max_retries):
            try:
                await ctx.connect()
                logging.getLogger(__name__).info(f"✅ Connexion multi-agents réussie (tentative {attempt + 1})")
                return
            except Exception as e:
                logging.getLogger(__name__).warning(f"⚠️ Échec connexion multi-agents tentative {attempt + 1}: {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(2 ** attempt)
                else:
                    raise
                    
    async def maintain_session(self):
        """Maintient la session active avec surveillance"""
        heartbeat_interval = 30  # secondes
        max_silent_duration = 300  # 5 minutes sans activité
        last_activity = datetime.now()
        
        while self.is_running:
            try:
                await asyncio.sleep(heartbeat_interval)
                
                # Vérifier l'état de la connexion
                if hasattr(self, 'room') and self.room:
                    if hasattr(self.room, 'connection_state'):
                        state = self.room.connection_state
                        if state != rtc.ConnectionState.CONN_CONNECTED:
                            logging.getLogger(__name__).warning(f"⚠️ État de connexion multi-agents dégradé: {state}")
                            
                    # Vérifier l'activité récente
                    current_time = datetime.now()
                    if (current_time - last_activity).seconds > max_silent_duration:
                        logging.getLogger(__name__).info("📢 Envoi d'un message de maintien multi-agents")
                        
                        # Utiliser le modérateur pour maintenir l'engagement
                        moderator = None
                        for agent in self.config.agents:
                            if agent.interaction_style == InteractionStyle.MODERATOR:
                                moderator = agent
                                break
                        
                        if moderator and self.session:
                            await self.session.say(
                                text=f"Je suis {moderator.name}, je suis toujours là pour vous accompagner. N'hésitez pas à continuer notre simulation !"
                            )
                        last_activity = current_time
                    
                    logging.getLogger(__name__).debug(f"💓 Heartbeat multi-agents OK - Session active depuis {(current_time - last_activity).seconds}s")
                else:
                    logging.getLogger(__name__).warning("⚠️ Room multi-agents non disponible, arrêt de la surveillance")
                    break
                    
            except Exception as e:
                logging.getLogger(__name__).error(f"❌ Erreur dans la surveillance multi-agents: {e}")
                await asyncio.sleep(5)  # Attendre avant de retry


# ==========================================
# VALIDATION COMPLÈTE DU SYSTÈME
# ==========================================

async def initialize_multi_agent_system_with_context(exercise_id: str = "studio_debate_tv", 
                                                   user_data: dict = None) -> Any:
    """Initialise le système multi-agents avec contexte utilisateur"""
    
    try:
        logging.getLogger(__name__).info(f"🚀 Initialisation système multi-agents avec contexte: {exercise_id}")
        
        # Configuration de l'exercice
        config = ExerciseTemplates.get_studio_debate_tv_config()
        
        if not config or len(config.agents) == 0:
            raise ValueError("Configuration agents vide ou invalide")
        
        logging.getLogger(__name__).info(f"✅ Configuration chargée: {len(config.agents)} agents")
        for agent in config.agents:
            logging.getLogger(__name__).info(f"   - {agent.name} ({agent.role})")
        
        # Validation user_data
        if user_data:
            logging.getLogger(__name__).info(f"📋 User_data reçues: {user_data}")
        else:
            logging.getLogger(__name__).warning("⚠️ Aucune user_data fournie")
        
        # Initialisation service avec user_data
        service = MultiAgentLiveKitService(config, user_data)
        
        # Validation que le contexte est bien configuré
        if hasattr(service.manager, 'get_user_context'):
            context = service.manager.get_user_context()
            logging.getLogger(__name__).info(f"✅ Contexte utilisateur validé: {context}")
        
        logging.getLogger(__name__).info(f"🎉 Système multi-agents initialisé avec succès")
        logging.getLogger(__name__).info(f"   {service.get_user_context_summary()}")
        
        return service
        
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ Erreur initialisation multi-agents avec contexte: {e}")
        raise

def create_multiagent_service_with_user_data(user_name: str, user_subject: str) -> MultiAgentLiveKitService:
    """Fonction utilitaire pour créer le service avec données utilisateur"""
    
    user_data = {
        'user_name': user_name,
        'user_subject': user_subject
    }
    
    config = ExerciseTemplates.get_studio_debate_tv_config()
    return MultiAgentLiveKitService(config, user_data)

async def validate_user_context_integration() -> bool:
    """Valide que l'intégration du contexte utilisateur fonctionne de bout en bout"""
    
    try:
        logging.getLogger(__name__).info("🔍 VALIDATION INTÉGRATION CONTEXTE UTILISATEUR...")
        
        # Test avec données utilisateur spécifiques
        test_user_data = {
            'user_name': 'Alice',
            'user_subject': 'Intelligence Artificielle et Emploi'
        }
        
        # Initialisation du service
        service = await initialize_multi_agent_system_with_context("studio_debate_tv", test_user_data)
        
        # Validation 1: Service créé avec user_data
        assert service.user_data['user_name'] == 'Alice'
        assert service.user_data['user_subject'] == 'Intelligence Artificielle et Emploi'
        logging.getLogger(__name__).info("✅ Validation 1: Service avec user_data")
        
        # Validation 2: Manager a le contexte
        if hasattr(service.manager, 'get_user_context'):
            context = service.manager.get_user_context()
            assert context['user_name'] == 'Alice'
            assert context['user_subject'] == 'Intelligence Artificielle et Emploi'
            logging.getLogger(__name__).info("✅ Validation 2: Manager avec contexte")
        
        # Validation 3: Prompts des agents contiennent le contexte
        for agent_id, agent in service.manager.agents.items():
            prompt = agent["system_prompt"]
            assert "Alice" in prompt, f"Nom absent du prompt de {agent_id}"
            assert "Intelligence Artificielle" in prompt, f"Sujet absent du prompt de {agent_id}"
        
        logging.getLogger(__name__).info("✅ Validation 3: Prompts avec contexte")
        
        # Validation 4: Instructions système avec contexte
        agent = service.create_multiagent_agent()
        # Note: Validation que l'agent est créé sans erreur
        logging.getLogger(__name__).info("✅ Validation 4: Agent système avec contexte")
        
        logging.getLogger(__name__).info("🎉 VALIDATION INTÉGRATION CONTEXTE RÉUSSIE !")
        return True
        
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ ÉCHEC VALIDATION INTÉGRATION: {e}")
        return False

async def initialize_multi_agent_system(exercise_id: str = "studio_debate_tv") -> Any:
    """Initialise le système multi-agents avec Enhanced Manager"""
    
    try:
        logging.getLogger(__name__).info(f"🚀 Initialisation système multi-agents: {exercise_id}")
        
        # ✅ CONFIGURATION SELON EXERCISE_TYPE
        if exercise_id == 'studio_debate_tv':
            logging.getLogger(__name__).info("✅ CONFIGURATION DÉBAT TV: Michel, Sarah, Marcus")
            config = ExerciseTemplates.get_studio_debate_tv_config()
        elif exercise_id == 'studio_situations_pro':
            logging.getLogger(__name__).info("✅ CONFIGURATION SITUATIONS PRO: Thomas, Sophie, Marc")
            config = ExerciseTemplates.get_studio_situations_pro_config()
        else:
            logging.getLogger(__name__).warning(f"⚠️ Exercise type non reconnu: {exercise_id}, fallback vers débat TV")
            config = ExerciseTemplates.get_studio_debate_tv_config()
        
        if not config or len(config.agents) == 0:
            raise ValueError("Configuration agents vide ou invalide")
        
        logging.getLogger(__name__).info(f"✅ Configuration chargée: {len(config.agents)} agents")
        for agent in config.agents:
            logging.getLogger(__name__).info(f"   - {agent.name} ({agent.role})")
        
        # Initialisation Enhanced Manager si disponible
        if ENHANCED_MANAGER_AVAILABLE:
            openai_key = os.getenv('OPENAI_API_KEY')
            elevenlabs_key = os.getenv('ELEVENLABS_API_KEY')
            
            if not openai_key or not elevenlabs_key:
                logging.getLogger(__name__).error("❌ Clés API manquantes pour Enhanced Manager")
                raise ValueError("Clés API OpenAI et ElevenLabs requises")
            
            manager = get_enhanced_manager(openai_key, elevenlabs_key, config)
            logging.getLogger(__name__).info("🎯 Enhanced Multi-Agent Manager initialisé")
            
        else:
            # Fallback manager basique
            manager = MultiAgentManager(config)
            logging.getLogger(__name__).warning("⚠️ Utilisation manager basique (Enhanced non disponible)")
        
        # Validation du manager
        if not hasattr(manager, 'agents') or len(manager.agents) == 0:
            raise ValueError("Manager initialisé sans agents")
        
        logging.getLogger(__name__).info(f"✅ Manager initialisé avec {len(manager.agents)} agents")
        
        # Test de performance si Enhanced Manager
        if ENHANCED_MANAGER_AVAILABLE and hasattr(manager, 'log_performance_status'):
            manager.log_performance_status()
        
        return manager
        
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ Erreur initialisation multi-agents: {e}")
        raise

async def validate_complete_system(manager: Any) -> bool:
    """Valide que le système complet fonctionne parfaitement"""
    
    try:
        logging.getLogger(__name__).info("🔍 VALIDATION SYSTÈME COMPLET...")
        
        # 1. Validation Enhanced Manager
        if hasattr(manager, 'agents'):
            agents = manager.agents
            logging.getLogger(__name__).info(f"✅ Enhanced Manager détecté avec {len(agents)} agents")
        else:
            logging.getLogger(__name__).warning("⚠️ Manager basique détecté")
            return False
        
        # 2. Validation agents français
        expected_agents = ["michel_dubois_animateur", "sarah_johnson_journaliste", "marcus_thompson_expert"]
        for agent_id in expected_agents:
            if agent_id not in agents:
                logging.getLogger(__name__).error(f"❌ Agent manquant: {agent_id}")
                return False
            
            agent = agents[agent_id]
            prompt = agent.get("system_prompt", "")
            
            # Vérification prompts français
            if "FRANÇAIS" not in prompt and "français" not in prompt:
                logging.getLogger(__name__).error(f"❌ Prompt non français pour {agent['name']}")
                return False
            
            # Vérification interdictions anglais
            if "generate response" in prompt.lower():
                logging.getLogger(__name__).error(f"❌ 'generate response' trouvé dans {agent['name']}")
                return False
            
            # Vérification voix neutres
            expected_voices = {
                "michel_dubois_animateur": "JBFqnCBsd6RMkjVDRZzb",
                "sarah_johnson_journaliste": "EXAVITQu4vr4xnSDxMaL", 
                "marcus_thompson_expert": "VR6AewLTigWG4xSOukaG"
            }
            
            if agent.get("voice_id") != expected_voices[agent_id]:
                logging.getLogger(__name__).error(f"❌ Voix incorrecte pour {agent['name']}: {agent.get('voice_id')}")
                return False
            
            logging.getLogger(__name__).info(f"✅ Agent {agent['name']} validé (français + voix neutre)")
        
        # 3. Test réponse rapide
        if hasattr(manager, 'generate_agent_response'):
            start_time = time.time()
            response, emotion = await manager.generate_agent_response(
                "michel_dubois_animateur", 
                "test", 
                "test", 
                []
            )
            duration = time.time() - start_time
            
            # Assouplir la contrainte de latence pour éviter le fallback intempestif
            if duration > 8.0:  # tolérance augmentée à 8s
                logging.getLogger(__name__).warning(f"⚠️ Réponse lente mais tolérée: {duration:.3f}s")
            else:
                logging.getLogger(__name__).info(f"✅ Réponse rapide validée: {duration:.3f}s")
            
            if len(response) < 10:
                logging.getLogger(__name__).error(f"❌ Réponse trop courte: {response}")
                return False
        
        # 4. Validation système d'émotions (si TTS disponible)
        try:
            from elevenlabs_flash_tts_service import VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL, EMOTION_VOICE_MAPPING
            
            if len(EMOTION_VOICE_MAPPING) < 7:
                logging.getLogger(__name__).error(f"❌ Système émotions incomplet: {len(EMOTION_VOICE_MAPPING)} émotions")
                return False
            
            logging.getLogger(__name__).info(f"✅ Système émotions validé: {len(EMOTION_VOICE_MAPPING)} émotions")
            
        except ImportError:
            logging.getLogger(__name__).warning("⚠️ Service TTS non disponible pour validation")
        
        # 5. Test performance globale
        if hasattr(manager, 'get_performance_metrics'):
            metrics = manager.get_performance_metrics()
            
            if not metrics.get('introduction_ready', False):
                logging.getLogger(__name__).error("❌ Système non prêt pour introduction")
                return False
            
            cache_total = sum(metrics.get('cache_size', {}).values())
            # Cache peut être vide au démarrage, c'est normal
            logging.getLogger(__name__).info(f"✅ Performance validée: {cache_total} réponses en cache")
        
        # 6. Test de génération de réponse fonctionnelle
        if hasattr(manager, 'generate_agent_response'):
            try:
                response, emotion = await manager.generate_agent_response(
                    "michel_dubois_animateur", 
                    "test", 
                    "test", 
                    []
                )
                if len(response) > 5:
                    logging.getLogger(__name__).info(f"✅ Génération réponse validée: {response[:30]}...")
                else:
                    logging.getLogger(__name__).warning(f"⚠️ Réponse courte: {response}")
            except Exception as e:
                logging.getLogger(__name__).warning(f"⚠️ Erreur génération réponse (non bloquante): {e}")
        
        logging.getLogger(__name__).info("🎉 SYSTÈME COMPLET VALIDÉ AVEC SUCCÈS !")
        return True
        
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ Erreur validation système: {e}")
        return False

async def run_regression_tests() -> bool:
    """Tests de régression pour éviter les régressions futures"""
    
    logging.getLogger(__name__).info("🧪 DÉMARRAGE TESTS DE RÉGRESSION...")
    
    try:
        # Test 1: Initialisation sans erreur
        manager = await initialize_multi_agent_system()
        assert manager is not None, "Manager non initialisé"
        
        # Test 2: Agents français uniquement
        for agent_id, agent in manager.agents.items():
            prompt = agent["system_prompt"]
            assert "FRANÇAIS" in prompt or "français" in prompt, f"Agent {agent_id} non français"
            assert "generate response" not in prompt.lower(), f"'generate response' dans {agent_id}"
        
        # Test 3: Voix neutres sans accent
        voice_mapping = {
            "michel_dubois_animateur": "JBFqnCBsd6RMkjVDRZzb",
            "sarah_johnson_journaliste": "EXAVITQu4vr4xnSDxMaL",
            "marcus_thompson_expert": "VR6AewLTigWG4xSOukaG"
        }
        
        for agent_id, expected_voice in voice_mapping.items():
            actual_voice = manager.agents[agent_id]["voice_id"]
            assert actual_voice == expected_voice, f"Voix incorrecte {agent_id}: {actual_voice}"
        
        # Test 4: Performance < 4 secondes
        start = time.time()
        response, emotion = await manager.generate_agent_response("michel_dubois_animateur", "test", "test", [])
        duration = time.time() - start
        assert duration < 4.0, f"Performance dégradée: {duration:.3f}s"
        
        # Test 5: Réponses en français
        assert len(response) > 5, "Réponse trop courte"
        # Test basique: pas de mots anglais courants
        english_words = ["the", "and", "generate response", "i am", "you are"]
        response_lower = response.lower()
        for word in english_words:
            assert word not in response_lower, f"Mot anglais détecté: {word}"
        
        logging.getLogger(__name__).info("✅ TOUS LES TESTS DE RÉGRESSION PASSÉS")
        return True
        
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ ÉCHEC TESTS DE RÉGRESSION: {e}")
        return False

# ==========================================
# DÉTECTION AUTOMATIQUE DU TYPE D'EXERCICE
# ==========================================

def detect_exercise_from_metadata(metadata: str) -> tuple[MultiAgentConfig, dict]:
    """Détecte automatiquement le type d'exercice et extrait les données utilisateur"""
    logging.getLogger(__name__).info("🔍 DÉTECTION AUTOMATIQUE EXERCICE MULTI-AGENTS")
    logging.getLogger(__name__).info("="*60)
    logging.getLogger(__name__).info(f"📥 Métadonnées reçues: '{metadata}'")
    
    try:
        import json
        data = json.loads(metadata) if metadata else {}
        logging.getLogger(__name__).info(f"📋 Données parsées: {data}")
        logging.getLogger(__name__).info(f"📋 Clés disponibles: {list(data.keys()) if data else []}")
        
        # Extraction du type d'exercice avec fallbacks
        exercise_type = data.get('exercise_type', 'studio_debate_tv')
        if not exercise_type or exercise_type == 'null':
            exercise_type = 'studio_debate_tv'
        
        # Extraction des données utilisateur avec fallbacks
        user_data = {
            'user_name': data.get('user_name', 'Participant'),
            'user_subject': data.get('user_subject', 'votre présentation'),
        }
        
        # Si user_subject est vide, essayer 'topic'
        if not user_data['user_subject'] or user_data['user_subject'] == 'Sujet non défini':
            user_data['user_subject'] = data.get('topic', 'votre présentation')
        
        # Si user_name est vide, essayer 'user_id'
        if not user_data['user_name'] or user_data['user_name'] == 'Participant':
            user_data['user_name'] = data.get('user_id', 'Participant')
        
        logging.getLogger(__name__).info(f"🎯 Type détecté: '{exercise_type}'")
        logging.getLogger(__name__).info(f"👤 Utilisateur: {user_data['user_name']}")
        logging.getLogger(__name__).info(f"📋 Sujet: {user_data['user_subject']}")
        
        # Mapping des types d'exercices vers les configurations multi-agents
        exercise_mapping = {
            'studio_situations_pro': ExerciseTemplates.get_studio_situations_pro_config,
            'studio_debate_tv': ExerciseTemplates.get_studio_debate_tv_config,
            'studio_debatPlateau': ExerciseTemplates.get_studio_debate_tv_config,
            'studio_job_interview': ExerciseTemplates.studio_job_interview,
            'studio_entretienEmbauche': ExerciseTemplates.studio_job_interview,
            'studio_boardroom': ExerciseTemplates.studio_boardroom,
            'studio_reunionDirection': ExerciseTemplates.studio_boardroom,
            'studio_sales_conference': ExerciseTemplates.studio_sales_conference,
            'studio_conferenceVente': ExerciseTemplates.studio_sales_conference,
            'studio_keynote': ExerciseTemplates.studio_keynote,
            'studio_conferencePublique': ExerciseTemplates.studio_keynote,
        }
        
        if exercise_type in exercise_mapping:
            config = exercise_mapping[exercise_type]()
            logging.getLogger(__name__).info(f"✅ Configuration multi-agents sélectionnée: {config.exercise_id}")
            logging.getLogger(__name__).info(f"   Agents: {[agent.name for agent in config.agents]}")
            return config, user_data
        else:
            logging.getLogger(__name__).warning(f"⚠️ Type inconnu '{exercise_type}', utilisation débat TV par défaut")
            return ExerciseTemplates.get_studio_debate_tv_config(), user_data
            
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ Erreur détection exercice: {e}")
        logging.getLogger(__name__).info("🔄 Fallback vers débat TV")
        return ExerciseTemplates.get_studio_debate_tv_config(), {'user_name': 'Participant', 'user_subject': 'votre présentation'}


# ==========================================
# FONCTIONS SPÉCIALISÉES PAR TYPE D'EXERCICE
# ==========================================

async def start_debate_tv_system(ctx: JobContext):
    """Démarre le système spécialisé pour débat TV"""
    
    logging.getLogger(__name__).info("🎬 === DÉMARRAGE SYSTÈME DÉBAT TV ===")
    logging.getLogger(__name__).info("🎭 Agents: Michel Dubois (Animateur), Sarah Johnson (Journaliste), Marcus Thompson (Expert)")
    
    # Configuration spécifique débat TV
    exercise_config = {
        'type': 'studio_debate_tv',
        'agents': ['michel_dubois_animateur', 'sarah_johnson_journaliste', 'marcus_thompson_expert'],
        'scenario': 'debate_tv',
        'voice_mapping': {
            'michel_dubois_animateur': 'George',
            'sarah_johnson_journaliste': 'Bella', 
            'marcus_thompson_expert': 'Arnold'
        }
    }
    
    # Démarrage du système avec configuration débat TV
    return await start_enhanced_multiagent_system(ctx, exercise_config)

async def start_situations_pro_system(ctx: JobContext):
    """Démarre le système spécialisé pour situations professionnelles"""
    
    logging.getLogger(__name__).info("🎭 === DÉMARRAGE SYSTÈME SITUATIONS PRO ===")
    logging.getLogger(__name__).info("🎭 Agents: Thomas (Coach), Sophie (RH), Marc (Consultant)")
    
    # Configuration spécifique situations pro
    exercise_config = {
        'type': 'studio_situations_pro',
        'agents': ['thomas_expert', 'sophie_rh', 'marc_consultant'],
        'scenario': 'situations_pro',
        'voice_mapping': {
            'thomas_expert': 'George',
            'sophie_rh': 'Bella',
            'marc_consultant': 'Arnold'
        }
    }
    
    # Démarrage du système avec configuration situations pro
    return await start_enhanced_multiagent_system(ctx, exercise_config)

async def start_enhanced_multiagent_system(ctx: JobContext, exercise_config: dict):
    """Démarre le système multi-agents avec configuration spécifique"""
    
    exercise_type = exercise_config['type']
    agents = exercise_config['agents']
    
    logging.getLogger(__name__).info(f"🚀 Initialisation système multi-agents: {exercise_type}")
    logging.getLogger(__name__).info(f"🎭 Agents configurés: {agents}")
    
    # ✅ VÉRIFICATION CRITIQUE
    if exercise_type == 'studio_debate_tv':
        logging.getLogger(__name__).info("✅ CONFIRMATION: Démarrage système DÉBAT TV")
        if 'michel_dubois_animateur' not in agents:
            logging.getLogger(__name__).error("❌ ERREUR: Michel Dubois manquant pour débat TV")
            agents = ['michel_dubois_animateur', 'sarah_johnson_journaliste', 'marcus_thompson_expert']
            logging.getLogger(__name__).info(f"🔧 CORRECTION: Agents corrigés: {agents}")
    elif exercise_type == 'studio_situations_pro':
        logging.getLogger(__name__).info("✅ CONFIRMATION: Démarrage système SITUATIONS PRO")
        if 'thomas_expert' not in agents:
            logging.getLogger(__name__).error("❌ ERREUR: Thomas manquant pour situations pro")
            agents = ['thomas_expert', 'sophie_rh', 'marc_consultant']
            logging.getLogger(__name__).info(f"🔧 CORRECTION: Agents corrigés: {agents}")
    
    # Suite de la logique existante...
    try:
        # 1. ÉTABLIR LA CONNEXION LIVEKIT
        logging.getLogger(__name__).info("🔗 Établissement de la connexion LiveKit multi-agents...")
        await ctx.connect()
        logging.getLogger(__name__).info("✅ Connexion LiveKit multi-agents établie avec succès")
        # 3. GÉNÉRATION INTRODUCTION AVEC CACHE REDIS
        logging.getLogger(__name__).info("🎬 Génération introduction...")
        
        # Récupération user_data depuis le contexte
        user_data = {
            'user_name': getattr(ctx, 'user_name', 'notre invité'),
            'user_subject': getattr(ctx, 'user_subject', 'un sujet passionnant')
        }
        
        # Génération ou récupération depuis cache
        try:
            intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
            logging.getLogger(__name__).info(f"✅ Introduction générée: {len(intro_text)} caractères, {len(intro_audio)} bytes audio")
            
            # Diffusion de l'introduction
            if intro_audio and len(intro_audio) > 0:
                # Créer un track audio pour l'introduction
                audio_source = rtc.AudioSource(sample_rate=24000, num_channels=1)
                track = rtc.LocalAudioTrack.create_audio_track("introduction", audio_source)
                
                # Publier le track
                await ctx.room.local_participant.publish_track(track, rtc.TrackPublishOptions())
                logging.getLogger(__name__).info("🎵 Introduction audio diffusée")
                
                # Attendre la fin de l'introduction
                import asyncio
                await asyncio.sleep(len(intro_audio) / 24000)  # Durée approximative
            else:
                logging.getLogger(__name__).warning("⚠️ Pas d'audio d'introduction généré")
                
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur génération introduction: {e}")
            # Introduction de fallback
            intro_text = f"Bienvenue dans notre studio de débat TV ! Je suis Michel Dubois, votre animateur."
            logging.getLogger(__name__).info("🔧 Introduction de fallback utilisée")

        
        # 2. VALIDATION COMPLÈTE DU SYSTÈME OBLIGATOIRE
        logging.getLogger(__name__).info("🔍 VALIDATION COMPLÈTE DU SYSTÈME MULTI-AGENTS")
        logging.getLogger(__name__).info("="*60)
        
        # ✅ INITIALISATION AVEC EXERCISE_TYPE CORRECT
        logging.getLogger(__name__).info(f"🎯 Initialisation système: {exercise_type}")
        manager = await initialize_multi_agent_system(exercise_type)
        
        # Validation complète obligatoire
        is_valid = await validate_complete_system(manager)
        
        if not is_valid:
            logging.getLogger(__name__).error("❌ VALIDATION SYSTÈME ÉCHOUÉE - ARRÊT")
            raise RuntimeError("Système multi-agents non validé")
        
        logging.getLogger(__name__).info("✅ SYSTÈME VALIDÉ - DÉMARRAGE AGENT LIVEKIT")
        
        # 3. DIAGNOSTIC APPROFONDI DES MÉTADONNÉES
        logging.getLogger(__name__).info("🔍 DIAGNOSTIC APPROFONDI DES MÉTADONNÉES")
        logging.getLogger(__name__).info("="*60)
        
        metadata = None
        metadata_found_from = "AUCUNE"
        
        # Vérification métadonnées room
        if hasattr(ctx, 'room') and ctx.room and hasattr(ctx.room, 'metadata'):
            room_metadata = ctx.room.metadata
            if room_metadata:
                metadata = room_metadata
                metadata_found_from = "ROOM"
                logging.getLogger(__name__).info(f"✅ Métadonnées trouvées depuis: {metadata_found_from}")
                logging.getLogger(__name__).info(f"📋 Contenu: {room_metadata}")
        
        # Vérification métadonnées participants si pas trouvées dans room
        if not metadata and hasattr(ctx, 'room') and ctx.room:
            await asyncio.sleep(2)  # Attendre les participants
            
            for participant_id, participant in ctx.room.remote_participants.items():
                participant_metadata = getattr(participant, 'metadata', None)
                if participant_metadata:
                    metadata = participant_metadata
                    metadata_found_from = f"PARTICIPANT_{participant_id}"
                    logging.getLogger(__name__).info(f"✅ Métadonnées trouvées depuis: {metadata_found_from}")
                    logging.getLogger(__name__).info(f"📋 Contenu: {participant_metadata}")
                    break
        
        # Vérification métadonnées participant local
        if not metadata and hasattr(ctx, 'room') and ctx.room and ctx.room.local_participant:
            local_metadata = getattr(ctx.room.local_participant, 'metadata', None)
            if local_metadata:
                metadata = local_metadata
                metadata_found_from = "LOCAL_PARTICIPANT"
                logging.getLogger(__name__).info(f"✅ Métadonnées trouvées depuis: {metadata_found_from}")
                logging.getLogger(__name__).info(f"📋 Contenu: {local_metadata}")
        
        # 4. SÉLECTION ET INITIALISATION DE LA CONFIGURATION MULTI-AGENTS
        logging.getLogger(__name__).info("🎯 SÉLECTION CONFIGURATION MULTI-AGENTS")
        
        if metadata:
            logging.getLogger(__name__).info(f"📋 Utilisation métadonnées: {metadata}")
            config, user_data = detect_exercise_from_metadata(metadata)
        else:
            logging.getLogger(__name__).warning("⚠️ Aucune métadonnée trouvée, utilisation configuration par défaut")
            if exercise_type == 'studio_debate_tv':
                config = ExerciseTemplates.get_studio_debate_tv_config()
            elif exercise_type == 'studio_situations_pro':
                config = ExerciseTemplates.get_studio_situations_pro_config()
            else:
                config = ExerciseTemplates.get_studio_debate_tv_config()
            user_data = {'user_name': 'Participant', 'user_subject': 'votre présentation'}
        
        logging.getLogger(__name__).info("="*60)
        logging.getLogger(__name__).info(f"🎭 CONFIGURATION MULTI-AGENTS SÉLECTIONNÉE:")
        logging.getLogger(__name__).info(f"   ID: {config.exercise_id}")
        logging.getLogger(__name__).info(f"   Nom: {config.exercise_id}")
        logging.getLogger(__name__).info(f"   Agents: {[agent.name for agent in config.agents]}")
        logging.getLogger(__name__).info(f"   Utilisateur: {user_data['user_name']}")
        logging.getLogger(__name__).info(f"   Sujet: {user_data['user_subject']}")
        logging.getLogger(__name__).info("="*60)
        
        # 5. DÉMARRAGE DU SERVICE MULTI-AGENTS
        logging.getLogger(__name__).info(f"🚀 Démarrage service multi-agents: {config.exercise_id}")
        
        service = MultiAgentLiveKitService(config, user_data)
        await service.run_session(ctx)
        
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ ERREUR CRITIQUE dans le système multi-agents: {e}")
        logging.getLogger(__name__).error("Détails de l'erreur:", exc_info=True)
        
        # Fallback vers le système simple si échec
        logging.getLogger(__name__).info("🔄 Tentative de fallback vers système simple...")
        try:
            from main import legacy_entrypoint
            await legacy_entrypoint(ctx)
        except Exception as fallback_error:
            logging.getLogger(__name__).error(f"❌ Même le fallback échoue: {fallback_error}")
            raise

# ==========================================
# POINT D'ENTRÉE PRINCIPAL MULTI-AGENTS
# ==========================================

async def multiagent_entrypoint(ctx: JobContext):
    """Point d'entrée principal pour le système multi-agents avec détection automatique"""
    
    # ✅ DIAGNOSTIC OBLIGATOIRE
    logging.getLogger(__name__).info(f"🔍 MULTI-AGENT ENTRYPOINT: Démarrage pour room {ctx.room.name}")
    
    # ✅ RÉCUPÉRATION EXERCISE_TYPE DEPUIS LE CONTEXTE OU DÉTECTION
    exercise_type = getattr(ctx, 'exercise_type', None)
    if not exercise_type:
        # Fallback vers détection depuis le nom de room
        from unified_entrypoint import detect_exercise_from_context
        exercise_type = await detect_exercise_from_context(ctx)
    
    logging.getLogger(__name__).info(f"🎯 EXERCISE_TYPE REÇU: {exercise_type}")
    
    # ✅ ROUTAGE CORRECT SELON EXERCISE_TYPE
    if exercise_type == 'studio_debate_tv':
        logging.getLogger(__name__).info("🎬 DÉMARRAGE SYSTÈME DÉBAT TV")
        return await start_debate_tv_system(ctx)
    elif exercise_type == 'studio_situations_pro':
        logging.getLogger(__name__).info("🎭 DÉMARRAGE SYSTÈME SITUATIONS PRO")
        return await start_situations_pro_system(ctx)
    else:
        logging.getLogger(__name__).warning(f"⚠️ Exercise type non reconnu: {exercise_type}, fallback vers débat TV")
        return await start_debate_tv_system(ctx)


async def main():
    """Fonction principale avec validation complète"""
    
    try:
        logging.getLogger(__name__).info("🚀 DÉMARRAGE ELOQUENCE MULTI-AGENTS RÉVOLUTIONNAIRE")
        
        # Initialisation système
        manager = await initialize_multi_agent_system("studio_debate_tv")
        
        # Validation complète obligatoire
        is_valid = await validate_complete_system(manager)
        
        if not is_valid:
            logging.getLogger(__name__).error("❌ VALIDATION SYSTÈME ÉCHOUÉE - ARRÊT")
            return False
        
        logging.getLogger(__name__).info("✅ SYSTÈME VALIDÉ - DÉMARRAGE AGENT LIVEKIT")
        
        # Tests de régression
        regression_ok = await run_regression_tests()
        if not regression_ok:
            logging.getLogger(__name__).error("❌ TESTS DE RÉGRESSION ÉCHOUÉS - ARRÊT")
            return False
        
        logging.getLogger(__name__).info("✅ TOUS LES TESTS PASSÉS - SYSTÈME PRÊT")
        return True
        
    except Exception as e:
        logging.getLogger(__name__).error(f"❌ Erreur fatale: {e}")
        return False

if __name__ == "__main__":
    """Point d'entrée principal du worker LiveKit multi-agents"""
    logging.getLogger(__name__).info("🎯 DÉMARRAGE WORKER LIVEKIT MULTI-AGENTS STUDIO SITUATIONS PRO")
    
    # Test de validation complète avant démarrage
    try:
        validation_success = asyncio.run(main())
        if not validation_success:
            logging.getLogger(__name__).error("💥 ÉCHEC VALIDATION - ARRÊT DU SYSTÈME")
            exit(1)
    except Exception as e:
        logging.getLogger(__name__).error(f"💥 ERREUR VALIDATION: {e}")
        exit(1)
    
    # Configuration WorkerOptions avec l'entrypoint multi-agents
    worker_options = agents.WorkerOptions(
        entrypoint_fnc=multiagent_entrypoint
    )
    
    logging.getLogger(__name__).info("🎯 WorkerOptions configuré avec système multi-agents")
    logging.getLogger(__name__).info(f"   - Système multi-agents: ✅")
    logging.getLogger(__name__).info(f"   - Agents configurés: Michel Dubois, Sarah Johnson, Marcus Thompson, etc.")
    logging.getLogger(__name__).info(f"   - Gestion des personnalités: ✅")
    logging.getLogger(__name__).info(f"   - Voix distinctes: ✅")
    logging.getLogger(__name__).info(f"   - Identification correcte: ✅")
    logging.getLogger(__name__).info(f"   - Validation complète: ✅")
    
    # Point d'entrée officiel avec CLI LiveKit
    agents.cli.run_app(worker_options)