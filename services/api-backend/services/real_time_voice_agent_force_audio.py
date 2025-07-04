import asyncio
import json
import logging
import os
import time
import io
from dataclasses import dataclass
from typing import Any, AsyncIterator, Callable, Dict, List, Optional

import numpy as np
from livekit import rtc
from livekit import agents
from livekit.agents import JobContext, stt, tts, Agent, AgentSession
from livekit.agents.llm import ChatMessage, ChatContext
from livekit.plugins import silero
# from livekit.plugins.turn_detector.english import EnglishModel  # Désactivé temporairement
from datetime import datetime
import aiohttp
import tempfile
import wave
import base64
from scipy.signal import resample
from unittest.mock import AsyncMock

import uuid

# Initialiser le logger AVANT de l'utiliser avec un handler
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Registre global des sessions HTTP pour fermeture propre
_global_http_sessions = set()

def register_http_session(session):
    """Enregistrer une session HTTP pour fermeture propre"""
    _global_http_sessions.add(session)
    logger.info(f"📝 [GLOBAL REGISTRY] Session HTTP enregistrée: {session} (Total: {len(_global_http_sessions)})")

def unregister_http_session(session):
    """Désenregistrer une session HTTP"""
    _global_http_sessions.discard(session)
    logger.info(f"🗑️ [GLOBAL REGISTRY] Session HTTP désenregistrée: {session} (Total: {len(_global_http_sessions)})")

async def close_all_http_sessions():
    """Fermer toutes les sessions HTTP enregistrées"""
    sessions_to_close = list(_global_http_sessions)
    for session in sessions_to_close:
        if not session.closed:
            try:
                await session.close()
                logger.debug(f"✅ [GLOBAL CLEANUP] Session HTTP fermée: {session}")
            except Exception as e:
                logger.warning(f"⚠️ [GLOBAL CLEANUP] Erreur fermeture session: {e}")
        unregister_http_session(session)
    logger.info(f"✅ [GLOBAL CLEANUP] {len(sessions_to_close)} sessions HTTP fermées")

# CORRECTION: Charger les variables d'environnement depuis le fichier .env
try:
    from dotenv import load_dotenv
    load_dotenv()
    logger.info("[OK] [ENV] Variables d'environnement chargees depuis .env")
except ImportError:
    logger.warning("[WARN] [ENV] python-dotenv non installe - chargement manuel des variables")
    # Chargement manuel du fichier .env
    env_file = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()
        logger.info("[OK] [ENV] Variables d'environnement chargees manuellement depuis .env")
    else:
        logger.warning("[WARN] [ENV] Fichier .env non trouve")

# Configuration détaillée - API Mistral via Scaleway
MISTRAL_BASE_URL = os.environ.get("MISTRAL_BASE_URL")
MISTRAL_API_KEY = os.environ.get("MISTRAL_API_KEY")
MISTRAL_MODEL = os.environ.get("MISTRAL_MODEL", "mistral-nemo-instruct-2407")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

# Paramètres de gestion du VAD et Whisper
MIN_CHUNK_SIZE = 6000
MAX_CHUNK_SIZE = 48000

# AUDIO_INTERVAL_MS contrôle le temps d'attente
AUDIO_INTERVAL_MS = 1000  # Réduit de 3000ms à 1000ms pour une réponse plus rapide

class CustomSTT(agents.stt.STT):
    """Service STT personnalisé utilisant l'API Whisper avec mode continu"""
    
    def __init__(self):
        super().__init__(
            capabilities=agents.stt.STTCapabilities(
                streaming=True,
                interim_results=True
            )
        )
        logger.info("🎤 CustomSTT initialisé")
        logger.info("🔍 DIAGNOSTIC: Méthodes requises par agents.stt.STT")
        logger.info(f"🔍 DIAGNOSTIC: Type de la classe parente: {type(agents.stt.STT)}")
        
        # Vérifier les méthodes abstraites
        try:
            import inspect
            abstract_methods = getattr(agents.stt.STT, '__abstractmethods__', set())
            logger.info(f"🔍 DIAGNOSTIC: Méthodes abstraites trouvées: {abstract_methods}")
        except Exception as e:
            logger.warning(f"⚠️ DIAGNOSTIC: Impossible de lister les méthodes abstraites: {e}")
    
    async def recognize(
        self,
        *,
        buffer: "agents.utils.AudioBuffer",
        language: Optional[str] = None,
    ) -> agents.stt.SpeechEvent:
        """Ne devrait pas être appelé dans ce contexte"""
        logger.warning("⚠️ CustomSTT.recognize() appelé - redirection vers _recognize_impl")
        return await self._recognize_impl(buffer=buffer, language=language)
    
    async def _recognize_impl(
        self,
        *,
        buffer: "agents.utils.AudioBuffer",
        language: Optional[str] = None,
    ) -> agents.stt.SpeechEvent:
        """Implémentation de la méthode abstraite requise"""
        logger.info("🎤 DIAGNOSTIC: CustomSTT._recognize_impl() appelé")
        
        # Cette méthode ne devrait pas être utilisée dans notre contexte de streaming
        # mais elle est requise par la classe abstraite
        logger.warning("⚠️ _recognize_impl appelé mais nous utilisons stream()")
        
        # Retourner un événement vide pour satisfaire l'interface
        return agents.stt.SpeechEvent(
            type=agents.stt.SpeechEventType.END_OF_SPEECH
        )
    
    def stream(
        self,
        *,
        language: Optional[str] = None,
        conn_options: Optional[Any] = None,
    ) -> "agents.stt.SpeechStream":
        """Créer un flux de reconnaissance vocale"""
        logger.info("🎤 CustomSTT: Création d'un nouveau SpeechStream")
        # Ignorer conn_options pour notre implémentation
        return CustomSpeechStream(language=language or "fr")

class CustomSpeechStream(agents.stt.SpeechStream):
    """Flux personnalisé qui simule un VAD manuel"""
    
    def __init__(self, *, language: str = "fr", stt: Optional[Any] = None, conn_options: Optional[Any] = None):
        # Créer un objet conn_options par défaut si None
        if conn_options is None:
            from types import SimpleNamespace
            conn_options = SimpleNamespace()
            conn_options.max_retry = 3
            conn_options.retry_interval = 1.0
        
        super().__init__(stt=stt, conn_options=conn_options)
        self._language = language
        self._closed = False
        logger.info(f"🎤 CustomSpeechStream initialisé (langue: {language})")
    
    def push_frame(self, frame: Optional[rtc.AudioFrame]) -> None:
        """Recevoir les frames audio - traité par StreamAdapter"""
        if frame is None:
            logger.debug("🔧 CustomSpeechStream: Frame None reçue (fin de flux)")
            return
        # Les frames sont gérées par StreamAdapterContext
        logger.debug(f"🔧 CustomSpeechStream.push_frame() appelé - frame: {frame}. Samples: {frame.samples_per_channel}, Rate: {frame.sample_rate}")
        # Vérifiez ici si le frame contient des données audio significatives
        if frame.data:
            audio_data_np = np.frombuffer(frame.data, dtype=np.int16)
            if audio_data_np.size > 0:
                # Calcul de l'énergie (RMS)
                rms = np.sqrt(np.mean(audio_data_np.astype(np.float64)**2))
                logger.debug(f"🔊 CustomSpeechStream: RMS de la frame: {rms:.2f}")
                if rms < 100: # Un seuil arbitraire pour "silence" à revoir
                    logger.debug("⚠️ CustomSpeechStream: Frame potentiellement silencieuse ou très faible.")
            else:
                logger.debug("⚠️ CustomSpeechStream: Frame audio data vide (après conversion np).")
        else:
            logger.debug("⚠️ CustomSpeechStream: Frame audio data est None ou vide.")
    
    async def _run(self) -> None:
        """Méthode abstraite requise par SpeechStream dans LiveKit v1.x"""
        logger.info("🎤 CustomSpeechStream._run() démarré")
        try:
            # Attendre que le flux soit fermé
            while not self._closed:
                await asyncio.sleep(0.1)
        except asyncio.CancelledError:
            logger.info("🎤 CustomSpeechStream._run() annulé")
        finally:
            logger.info("🎤 CustomSpeechStream._run() terminé")
    
    async def aclose(self, *, wait: bool = True) -> None:
        """Fermer le flux"""
        self._closed = True
        logger.info("🎤 CustomSpeechStream fermé")


class StreamAdapterContext:
    """Contexte pour adapter le flux STT"""
    
    def __init__(self, stt_stream: agents.stt.SpeechStream, room=None, llm_service=None, tts_service=None, audio_source=None, audio_track=None):
        self.stt_stream = stt_stream
        self._audio_buffer: List[np.ndarray] = []
        self._task: Optional[asyncio.Task] = None
        self._closed = False
        self._frame_count = 0
        self._last_process_time = time.time()
        self._http_session: Optional[aiohttp.ClientSession] = None
        
        # Services pour le pipeline complet
        self.room = room
        self.llm_service = llm_service
        self.tts_service = tts_service
        
        # OPTIMISATION MÉMOIRE: Objets audio persistants pour éviter les fuites
        self.audio_source = audio_source
        self.audio_track = audio_track
        self._publication = None  # Publication persistante
        
        # Configuration du traitement
        self.process_interval = AUDIO_INTERVAL_MS / 1000.0  # 1 seconde maintenant
        self.frames_per_chunk = 200  # Augmenté de 100 à 200 pour plus d'audio
        
        # Statistiques du pipeline
        self.pipeline_stats = {
            'stt_calls': 0,
            'stt_success': 0,
            'llm_calls': 0,
            'llm_success': 0,
            'tts_calls': 0,
            'tts_success': 0,
            'audio_published': 0
        }
        
        logger.info(f"🔧 StreamAdapterContext initialisé (interval: {self.process_interval}s)")
        logger.info(f"🔧 Pipeline configuré: STT→LLM→TTS→LiveKit")
        logger.info(f"🔧 OPTIMISATION: Audio objects persistants: source={self.audio_source is not None}, track={self.audio_track is not None}")
    
    async def __aenter__(self):
        """Démarrer le contexte et la tâche de traitement"""
        logger.info("🔧 StreamAdapterContext.__aenter__()")
        self._http_session = aiohttp.ClientSession()
        register_http_session(self._http_session)  # Enregistrer pour fermeture propre
        self._task = asyncio.create_task(self._process_audio_continuous())
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Nettoyer le contexte"""
        logger.info("🔧 OPTIMISATION MÉMOIRE: StreamAdapterContext.__aexit__()")
        self._closed = True
        
        # OPTIMISATION MÉMOIRE: Nettoyer les objets audio persistants
        await self._cleanup_audio_resources()
        
        # Nettoyer la session HTTP avec vérification d'état
        if self._http_session:
            logger.info(f"🧹 [HTTP SESSION CLEANUP] Vérification de l'état de la session HTTP: {self._http_session}")
            logger.info(f"🧹 [HTTP SESSION CLEANUP] Session fermée: {self._http_session.closed}")
            logger.info(f"🧹 [HTTP SESSION CLEANUP] Connecteur: {getattr(self._http_session, '_connector', 'N/A')}")
            
            # Désenregistrer du registre global
            unregister_http_session(self._http_session)
            
            if not self._http_session.closed:
                logger.info("🧹 [HTTP SESSION CLEANUP] Fermeture de la session HTTP active...")
                try:
                    await self._http_session.close()
                    logger.info("✅ [HTTP SESSION CLEANUP] Session HTTP fermée avec succès")
                except Exception as close_error:
                    logger.error(f"❌ [HTTP SESSION CLEANUP] Erreur lors de la fermeture: {close_error}")
            else:
                logger.info("ℹ️ [HTTP SESSION CLEANUP] Session HTTP déjà fermée - pas d'action nécessaire")
        
        # Annuler la tâche
        if self._task and not self._task.done():
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
    
    async def _cleanup_audio_resources(self):
        """Nettoyer les ressources audio persistantes pour éviter les fuites mémoire"""
        try:
            logger.info("🧹 [OPTIMISATION MÉMOIRE] Nettoyage des ressources audio...")
            
            # Dépublier le track si nécessaire
            if self._publication and self.room and self.room.local_participant:
                try:
                    logger.info("🧹 [OPTIMISATION MÉMOIRE] Dépublication du track persistant...")
                    await self.room.local_participant.unpublish_track(self._publication.sid)
                    logger.info("✅ [OPTIMISATION MÉMOIRE] Track dépublié avec succès")
                except Exception as e:
                    logger.warning(f"⚠️ [OPTIMISATION MÉMOIRE] Erreur lors de la dépublication: {e}")
            
            # Nettoyer les références
            if self.audio_source:
                logger.info("🧹 [OPTIMISATION MÉMOIRE] Nettoyage AudioSource...")
                self.audio_source = None
            
            if self.audio_track:
                logger.info("🧹 [OPTIMISATION MÉMOIRE] Nettoyage LocalAudioTrack...")
                self.audio_track = None
            
            if self._publication:
                logger.info("🧹 [OPTIMISATION MÉMOIRE] Nettoyage Publication...")
                self._publication = None
            
            logger.info("✅ [OPTIMISATION MÉMOIRE] Ressources audio nettoyées")
            
        except Exception as e:
            logger.error(f"❌ [OPTIMISATION MÉMOIRE] Erreur lors du nettoyage des ressources audio: {e}", exc_info=True)
    
    def push_frame(self, frame: rtc.AudioFrame) -> None:
        """Ajouter une frame au buffer"""
        if self._closed:
            return
        
        # Log détaillé toutes les 10 frames pour éviter le spam
        if self._frame_count % 10 == 0:
            logger.info(f"🔧 [AUDIO FLOW] Frame #{self._frame_count}: {frame.samples_per_channel} samples @ {frame.sample_rate}Hz")
            logger.info(f"🔧 [AUDIO FLOW] Buffer actuel: {len(self._audio_buffer)} frames accumulées")
        
        # Vérifier le taux d'échantillonnage
        if frame.sample_rate != 48000:
            logger.warning(f"⚠️ [AUDIO FLOW] Taux d'échantillonnage inattendu: {frame.sample_rate}Hz (attendu: 48000Hz)")
        
        # Convertir la frame en numpy array
        # Normalise les données audio de int16 (-32768 à 32767) à float32 (-1.0 à 1.0)
        audio_data = np.frombuffer(frame.data, dtype=np.int16).astype(np.float32) / 32768.0
        
        # Vérifier si l'audio contient du signal
        if self._frame_count % 50 == 0:  # Vérifier toutes les 50 frames
            energy = np.sqrt(np.mean(audio_data**2))
            logger.info(f"🔊 [AUDIO FLOW] Énergie audio frame #{self._frame_count}: {energy:.6f}")
        
        self._audio_buffer.append(audio_data)
        self._frame_count += 1
    
    async def _process_audio_continuous(self):
        """Traiter l'audio de manière continue toutes les X secondes"""
        logger.info("🔧 CORRECTION: Démarrage du traitement audio CONTINU")
        
        while not self._closed:
            try:
                # Attendre l'intervalle configuré
                await asyncio.sleep(self.process_interval)
                
                # CORRECTION: Réduire le seuil et forcer le traitement pour tester
                if len(self._audio_buffer) >= 200:  # Augmenté à 200 frames (4 secondes d'audio)
                    # Prendre les frames disponibles
                    frames_to_process = min(len(self._audio_buffer), self.frames_per_chunk)
                    audio_chunk = np.concatenate(self._audio_buffer[:frames_to_process])
                    
                    # Vider le buffer des frames traitées
                    self._audio_buffer = self._audio_buffer[frames_to_process:]
                    
                    logger.info(f"🔧 CORRECTION: Traitement FORCÉ de {frames_to_process} frames audio")
                    
                    # Calculer l'énergie pour diagnostic
                    energy = float(np.sqrt(np.mean(audio_chunk**2)))
                    min_val = np.min(audio_chunk)
                    max_val = np.max(audio_chunk)
                    mean_val = np.mean(audio_chunk)
                    
                    logger.info(f"🔊 DIAGNOSTIC AUDIO: énergie={energy:.8f}, min={min_val:.8f}, max={max_val:.8f}, mean={mean_val:.8f}")
                    
                    # FORCER le traitement même avec audio silencieux pour tester le pipeline
                    logger.info("🔧 CORRECTION: FORÇAGE du traitement STT→LLM→TTS (test pipeline)")
                    
                    # Toujours émettre START_OF_SPEECH
                    await self._emit_event(agents.stt.SpeechEvent(
                        type=agents.stt.SpeechEventType.START_OF_SPEECH
                    ))
                    logger.info("🔧 CORRECTION: START_OF_SPEECH émis (traitement forcé)")
                    
                    # TOUJOURS traiter l'audio pour tester le pipeline complet
                    await self._process_chunk_with_whisper(audio_chunk)
                    
                    # Émettre END_OF_SPEECH
                    await self._emit_event(agents.stt.SpeechEvent(
                        type=agents.stt.SpeechEventType.END_OF_SPEECH
                    ))
                    logger.info("🔧 CORRECTION: END_OF_SPEECH émis")
                else:
                    logger.debug(f"🔧 CORRECTION: Accumulation en cours ({len(self._audio_buffer)}/200 frames)")
                    
            except asyncio.CancelledError:
                logger.info("🔧 CORRECTION: StreamAdapter annulé")
                break
            except Exception as e:
                logger.error(f"❌ CORRECTION: Erreur dans _process_audio_continuous: {e}", exc_info=True)
                await asyncio.sleep(0.1)
        
        logger.info("🔧 CORRECTION: StreamAdapter terminé avec succès")
    
    async def _process_chunk_with_whisper(self, audio_chunk: np.ndarray):
        """Traiter un chunk audio avec Whisper et continuer le pipeline complet"""
        try:
            logger.info("=" * 80)
            logger.info("🎤 [PIPELINE] DÉBUT DU TRAITEMENT COMPLET STT→LLM→TTS")
            logger.info("=" * 80)
            
            # 1. DIAGNOSTIC STT
            logger.info("🎤 [DIAGNOSTIC PIPELINE] Étape 1: STT")
            self.pipeline_stats['stt_calls'] += 1
            
            # Calculer l'énergie audio pour debug
            energy = int(np.sqrt(np.mean(audio_chunk**2)) * 32768)
            logger.info(f"🎤 [DIAGNOSTIC STT] Audio stats: {len(audio_chunk)} échantillons, énergie: {energy}")
            
            # Convertir en int16 pour Whisper
            audio_int16 = (audio_chunk * 32768).astype(np.int16)
            
            # Créer un fichier WAV temporaire
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
                with wave.open(tmp_file.name, 'wb') as wav_file:
                    wav_file.setnchannels(1)
                    wav_file.setsampwidth(2)
                    wav_file.setframerate(24000)
                    wav_file.writeframes(audio_int16.tobytes())
                
                # Lire le fichier WAV pour l'envoyer à Whisper
                with open(tmp_file.name, 'rb') as audio_file:
                    wav_data = audio_file.read()
                
                # Appeler le service Whisper local
                whisper_url = "http://whisper-stt:8001/transcribe"
                logger.info(f"🎤 [STT] Envoi à Whisper: {len(wav_data)} bytes")
                
                # Utiliser la session HTTP existante
                if not self._http_session:
                    logger.error("❌ [STT] Pas de session HTTP disponible")
                    return
                
                # Préparer la requête multipart
                form = aiohttp.FormData()
                form.add_field('audio', wav_data, filename='audio.wav', content_type='audio/wav')
                form.add_field('language', 'fr')
                form.add_field('model', 'whisper-large-v3-turbo')
                
                # Envoyer à Whisper
                transcription = ""
                try:
                    async with self._http_session.post(
                        whisper_url,
                        data=form,
                        timeout=aiohttp.ClientTimeout(total=30)
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            transcription = data.get('text', '').strip()
                            
                            if transcription:
                                self.pipeline_stats['stt_success'] += 1
                                logger.info(f"✅ [STT] Transcription: '{transcription}'")
                                
                                # Émettre la transcription finale
                                await self._emit_event(agents.stt.SpeechEvent(
                                    type=agents.stt.SpeechEventType.FINAL_TRANSCRIPT,
                                    alternatives=[agents.stt.SpeechData(text=transcription, language="fr")]
                                ))
                            else:
                                logger.warning("⚠️ [STT] Transcription vide")
                                return
                        else:
                            error_text = await response.text()
                            logger.error(f"❌ [STT] Erreur Whisper {response.status}: {error_text}")
                            return
                            
                except (aiohttp.ClientError, asyncio.TimeoutError) as e:
                    logger.error(f"❌ [STT] Erreur réseau ou Timeout Whisper: {e}")
                    return # Pas de transcription en cas d'erreur réseau
                except Exception as e:
                    logger.error(f"❌ [STT] Erreur inattendue lors de la transcription Whisper: {e}", exc_info=True)
                    return
                finally:
                    # Nettoyer
                    if os.path.exists(tmp_file.name):
                        os.unlink(tmp_file.name)
                
                # 2. DIAGNOSTIC LLM
                try: # Ajout du try-except autour du bloc LLM
                    if transcription and self.llm_service:  # Conserver la vérification du service LLM
                        logger.info("🧠 [DIAGNOSTIC PIPELINE] Étape 2: LLM")
                        self.pipeline_stats['llm_calls'] += 1
                        
                        llm_response = await self._call_llm_service(transcription)
                        
                        if llm_response:
                            self.pipeline_stats['llm_success'] += 1
                            logger.info(f"✅ [DIAGNOSTIC LLM] Réponse: '{llm_response[:100]}...'")
                            
                            # 3. DIAGNOSTIC TTS
                            try: # Ajout du try-except autour du bloc TTS
                                if self.tts_service:
                                    logger.info("🔊 [DIAGNOSTIC PIPELINE] Étape 3: TTS")
                                    self.pipeline_stats['tts_calls'] += 1
                                    
                                    tts_audio = await self._call_tts_service(llm_response)
                                    
                                    if tts_audio and len(tts_audio) > 1000:
                                        self.pipeline_stats['tts_success'] += 1
                                        logger.info(f"✅ [DIAGNOSTIC TTS] Audio synthétisé: {len(tts_audio)} bytes")
                                        
                                        # 4. DIAGNOSTIC DIFFUSION
                                        try: # Ajout du try-except autour du bloc de diffusion
                                            logger.info("📡 [DIAGNOSTIC PIPELINE] Étape 4: Diffusion")
                                            await self._stream_tts_audio(tts_audio)
                                            self.pipeline_stats['audio_published'] += 1
                                            logger.info("✅ [DIAGNOSTIC DIFFUSION] Audio publié sur LiveKit")
                                        except Exception as e:
                                            logger.error(f"❌ [DIFFUSION] Erreur lors de la diffusion de l'audio: {e}", exc_info=True)
                                    else:
                                        logger.error(f"❌ [DIAGNOSTIC TTS] Audio vide ou trop petit. Taille: {len(tts_audio) if tts_audio else 0}")
                                else:
                                    logger.warning("⚠️ [DIAGNOSTIC TTS] Service TTS non configuré")
                            except Exception as e:
                                logger.error(f"❌ [TTS] Erreur lors de l'appel au service TTS: {e}", exc_info=True)
                        else:
                            logger.error("❌ [DIAGNOSTIC LLM] Aucune réponse générée")
                    else:
                        logger.warning("⚠️ [DIAGNOSTIC LLM] Service LLM non configuré ou transcription vide")
                except Exception as e:
                    logger.error(f"❌ [LLM] Erreur lors de l'appel au service LLM: {e}", exc_info=True)
                
                # Afficher les statistiques
                logger.info("=" * 80)
                logger.info("📊 [PIPELINE] Statistiques:")
                logger.info(f"  - STT: {self.pipeline_stats['stt_success']}/{self.pipeline_stats['stt_calls']}")
                logger.info(f"  - LLM: {self.pipeline_stats['llm_success']}/{self.pipeline_stats['llm_calls']}")
                logger.info(f"  - TTS: {self.pipeline_stats['tts_success']}/{self.pipeline_stats['tts_calls']}")
                logger.info(f"  - Audio publié: {self.pipeline_stats['audio_published']}")
                logger.info("=" * 80)
                
        except Exception as e:
            logger.error(f"❌ [PIPELINE] Erreur générale dans le traitement du chunk: {e}", exc_info=True)
    
    async def _call_llm_service(self, transcription: str) -> str:
        """Appeler le service LLM en utilisant l'API LiveKit Agents v1.x correctement."""
        try:
            if not self.llm_service:
                logger.error("❌ [LLM] Service non configuré")
                return "Service vocal non disponible."
    
            logger.info("🧠 [LLM] Utilisation de l'API LiveKit Agents pour le chat")
    
            # 1. Créer un ChatContext compatible avec le format liste requis
            chat_ctx = ChatContext()
            
            # CORRECTION: Créer les messages avec le format LISTE requis par Pydantic validation
            system_msg = ChatMessage(role="system", content=["Tu es un coach vocal expert. Sois concis et encourageant."])
            user_msg = ChatMessage(role="user", content=[transcription])
            
            # Ajouter les messages au contexte
            chat_ctx.messages = [system_msg, user_msg]
            logger.info(f"🧠 [LLM] ChatContext créé avec {len(chat_ctx.messages)} messages au format liste.")
    
            # 2. Appeler la méthode chat du service LLM
            llm_stream = await self.llm_service.chat(chat_ctx=chat_ctx)
            logger.info("🧠 [LLM] Stream de réponse LLM obtenu.")
    
            # CORRECTION: Forcer le démarrage du stream avec __aenter__
            logger.info("🧠 [LLM] Démarrage forcé du stream LLM...")
            async with llm_stream as active_stream:
                logger.info("🧠 [LLM] Stream LLM actif, collecte des chunks...")
                
                # 3. Collecter la réponse complète du stream
                response_text = ""
                chunk_count = 0
                async for chunk in active_stream:
                    chunk_count += 1
                    logger.info(f"🧠 [LLM] Chunk #{chunk_count} reçu (type: {type(chunk)}): {chunk}")
                    try:
                        if isinstance(chunk, dict) and chunk.get('choices'):
                            delta = chunk['choices'][0].get('delta', {})
                            content = delta.get('content')
                            if content:
                                response_text += content
                                logger.info(f"🧠 [LLM] Contenu ajouté: '{content}'")
                        elif hasattr(chunk, 'choices') and chunk.choices:
                            delta = chunk.choices[0].delta
                            if delta and delta.content:
                                response_text += delta.content
                                logger.info(f"🧠 [LLM] Contenu ajouté: '{delta.content}'")
                    except (KeyError, IndexError, AttributeError) as e:
                        logger.warning(f"⚠️ [LLM] Erreur de parsing du chunk: {e} - chunk: {chunk}")
                
                logger.info(f"🧠 [LLM] Total chunks reçus: {chunk_count}")
                
                if response_text:
                    logger.info(f"✅ [LLM] Réponse complète: '{response_text[:100]}...'")
                    return response_text
                else:
                    logger.error("❌ [LLM] Le stream n'a produit aucun contenu.")
                    return "Je n'ai pas de réponse pour le moment."
    
        except Exception as e:
            logger.error(f"❌ [LLM] Erreur critique dans _call_llm_service: {e}", exc_info=True)
            return "Une erreur interne est survenue dans le service de langage."
    
    async def _call_tts_service(self, text: str) -> bytes:
        """Appeler le service TTS - VERSION DIAGNOSTIC"""
        try:
            logger.info("🔊 [DIAGNOSTIC TTS SERVICE] Début appel TTS")
            
            if not self.tts_service:
                logger.error("❌ [DIAGNOSTIC TTS SERVICE] Service non configuré")
                return b""
            
            logger.info(f"🔊 [DIAGNOSTIC TTS SERVICE] Synthèse du texte: '{text[:50]}...'")
            
            # Synthétiser l'audio
            stream = await self.tts_service.synthesize(text)
            logger.info("🔊 [DIAGNOSTIC TTS SERVICE] Stream TTS créé")
            
            # Collecter les chunks audio
            audio_chunks = []
            chunk_count = 0
            total_bytes = 0
            
            async for chunk in stream:
                if hasattr(chunk, 'data'):
                    chunk_size = len(chunk.data)
                    audio_chunks.append(chunk.data)
                    chunk_count += 1
                    total_bytes += chunk_size
                    
                    if chunk_count <= 3:
                        logger.info(f"🔊 [DIAGNOSTIC TTS SERVICE] Chunk {chunk_count}: {chunk_size} bytes")
            
            logger.info(f"🔊 [DIAGNOSTIC TTS SERVICE] Total: {chunk_count} chunks, {total_bytes} bytes")
            
            # Combiner tous les chunks
            if audio_chunks:
                combined_audio = b''.join(audio_chunks)
                logger.info(f"✅ [DIAGNOSTIC TTS SERVICE] Audio PCM combiné: {len(combined_audio)} bytes")
                
                # L'audio est déjà en PCM grâce à response_format="pcm" !
                logger.info("✅ [DIAGNOSTIC TTS SERVICE] Audio déjà en PCM 16-bit 24kHz - prêt pour LiveKit!")
                return combined_audio
            else:
                logger.warning("⚠️ [DIAGNOSTIC TTS SERVICE] Aucune donnée audio reçue")
                return b""
                
        except (aiohttp.ClientError, asyncio.TimeoutError) as e:
            logger.error(f"❌ [DIAGNOSTIC TTS SERVICE] Erreur réseau/timeout: {e}")
            return b""
        except Exception as e:
            logger.error(f"❌ [DIAGNOSTIC TTS SERVICE] Erreur inattendue: {e}", exc_info=True)
            return b""
    
    async def _stream_tts_audio(self, audio_data: bytes):
        """Diffuser l'audio TTS vers LiveKit - VERSION OPTIMISÉE MÉMOIRE"""
        try:
            logger.info("🔊 [OPTIMISATION MÉMOIRE] DÉBUT DE LA DIFFUSION AUDIO")
            logger.info(f"🔊 [OPTIMISATION MÉMOIRE] Taille des données: {len(audio_data)} bytes")
            
            if not self.room:
                logger.error("❌ [OPTIMISATION MÉMOIRE] Room non configurée - IMPOSSIBLE DE DIFFUSER")
                return
            
            # Diagnostic de la room
            logger.info(f"🔊 [OPTIMISATION MÉMOIRE] Room configurée: {type(self.room)}")
            logger.info(f"🔊 [OPTIMISATION MÉMOIRE] Local participant: {self.room.local_participant}")
            
            # OPTIMISATION MÉMOIRE: Utiliser les objets audio persistants ou les créer une seule fois
            if self.audio_source is None or self.audio_track is None:
                logger.info("🔧 [OPTIMISATION MÉMOIRE] Création des objets audio persistants (première fois)")
                
                # Créer une source audio persistante
                self.audio_source = rtc.AudioSource(sample_rate=48000, num_channels=1)
                logger.info(f"🔧 [OPTIMISATION MÉMOIRE] AudioSource persistante créée: {self.audio_source}")
                
                # Créer un track audio local persistant
                self.audio_track = rtc.LocalAudioTrack.create_audio_track(
                    "eloquence_tts_response",
                    self.audio_source
                )
                logger.info(f"🔧 [OPTIMISATION MÉMOIRE] LocalAudioTrack persistant créé: {self.audio_track}")
                
                # Options de publication
                publish_options = rtc.TrackPublishOptions(
                    source=rtc.TrackSource.SOURCE_MICROPHONE,
                    dtx=False,
                    red=True
                )
                logger.info(f"🔧 [OPTIMISATION MÉMOIRE] Options de publication: source=MICROPHONE, stereo=False, dtx=False, red=True")
                
                # Publier le track une seule fois
                logger.info("🔧 [OPTIMISATION MÉMOIRE] Publication du track persistant...")
                self._publication = await self.room.local_participant.publish_track(
                    self.audio_track,
                    publish_options
                )
                
                logger.info(f"📡 [OPTIMISATION MÉMOIRE] Track persistant publié avec succès!")
                logger.info(f"📡 [OPTIMISATION MÉMOIRE] Publication SID: {self._publication.sid}")
                logger.info(f"📡 [OPTIMISATION MÉMOIRE] Publication kind: {self._publication.kind if hasattr(self._publication, 'kind') else 'N/A'}")
                logger.info(f"📡 [OPTIMISATION MÉMOIRE] Publication muted: {self._publication.muted if hasattr(self._publication, 'muted') else 'N/A'}")
            else:
                logger.info("✅ [OPTIMISATION MÉMOIRE] Réutilisation des objets audio persistants")
                logger.info(f"✅ [OPTIMISATION MÉMOIRE] AudioSource réutilisée: {self.audio_source}")
                logger.info(f"✅ [OPTIMISATION MÉMOIRE] LocalAudioTrack réutilisé: {self.audio_track}")
            
            # Convertir les données audio en frames
            logger.info("🔊 [DIAGNOSTIC AUDIO] Conversion et (si nécessaire) rééchantillonnage des données audio...")
            
            # Vérifier le format des données
            if len(audio_data) < 100:
                logger.error(f"❌ [DIAGNOSTIC AUDIO] Données audio trop petites: {len(audio_data)} bytes")
                return
            
            # Analyser les premières données
            first_bytes = audio_data[:20]
            logger.info(f"🔊 [DIAGNOSTIC AUDIO] Premiers bytes (RAW): {first_bytes.hex()}")
            
            # Convertir en numpy array int16
            try:
                audio_array_int16 = np.frombuffer(audio_data, dtype=np.int16)
                logger.info(f"🔊 [DIAGNOSTIC AUDIO] Array audio int16 créé: shape={audio_array_int16.shape}, dtype={audio_array_int16.dtype}")
                
                # Statistiques audio
                audio_min_int16 = np.min(audio_array_int16)
                audio_max_int16 = np.max(audio_array_int16)
                audio_mean_int16 = np.mean(audio_array_int16)
                audio_std_int16 = np.std(audio_array_int16)
                logger.info(f"🔊 [DIAGNOSTIC AUDIO] Stats RAW int16: min={audio_min_int16}, max={audio_max_int16}, mean={audio_mean_int16:.2f}, std={audio_std_int16:.2f}")
                
                # Vérifier si l'audio n'est pas silencieux (basé sur l'écart-type)
                if audio_std_int16 < 50: # Seuil si les valeurs sont très proches de zéro
                    logger.warning("⚠️ [DIAGNOSTIC AUDIO] L'audio RAW semble être silencieux (std très faible).")
                
                # Rééchantillonnage de 24kHz à 48kHz
                original_sample_rate = 24000
                target_sample_rate = 48000
                
                if original_sample_rate != target_sample_rate:
                    logger.info(f"🔊 [DIAGNOSTIC AUDIO] Rééchantillonnage de {original_sample_rate}Hz à {target_sample_rate}Hz...")
                    # Passer en float pour le rééchantillonnage
                    audio_array_float = audio_array_int16.astype(np.float32)
                    num_samples_resampled = int(len(audio_array_float) * (target_sample_rate / original_sample_rate))
                    audio_resampled_float = resample(audio_array_float, num_samples_resampled)
                    
                    # Revenir en int16 et normaliser
                    audio_resampled_int16 = (audio_resampled_float * (2**15 - 1) / np.max(np.abs(audio_resampled_float))).astype(np.int16)
                    logger.info(f"✅ [DIAGNOSTIC AUDIO] Audio rééchantillonné: shape={audio_resampled_int16.shape}, dtype={audio_resampled_int16.dtype}")
                    audio_to_stream = audio_resampled_int16
                    current_sample_rate = target_sample_rate
                else:
                    audio_to_stream = audio_array_int16
                    current_sample_rate = original_sample_rate
                
                # Vérifier l'audio après rééchantillonnage
                audio_stream_min_int16 = np.min(audio_to_stream)
                audio_stream_max_int16 = np.max(audio_to_stream)
                audio_stream_mean_int16 = np.mean(audio_to_stream)
                audio_stream_std_int16 = np.std(audio_to_stream)
                logger.info(f"🔊 [DIAGNOSTIC AUDIO] Stats STREAM int16: min={audio_stream_min_int16}, max={audio_stream_max_int16}, mean={audio_stream_mean_int16:.2f}, std={audio_stream_std_int16:.2f}")

                if audio_stream_std_int16 < 50:
                    logger.warning("⚠️ [DIAGNOSTIC AUDIO] L'audio streamé semble être silencieux après rééchantillonnage.")

            except Exception as conv_error:
                logger.error(f"❌ [DIAGNOSTIC AUDIO] Erreur conversion ou rééchantillonnage numpy: {conv_error}", exc_info=True)
                return
            
            # Envoyer par chunks
            # La taille de chunk recommandée pour LiveKit est 10ms d'audio
            # À 48kHz, 10ms = 480 échantillons
            chunk_size_samples = int(current_sample_rate * 0.01) # 10ms de samples
            
            total_chunks = len(audio_to_stream) // chunk_size_samples
            logger.info(f"🔊 [DIAGNOSTIC AUDIO] Envoi de {total_chunks} chunks de {chunk_size_samples} samples à {current_sample_rate}Hz")
            
            chunks_sent = 0
            for i in range(0, len(audio_to_stream), chunk_size_samples):
                chunk = audio_to_stream[i:i+chunk_size_samples]
                
                # Padding si le dernier chunk est plus petit
                if len(chunk) < chunk_size_samples:
                    chunk = np.pad(chunk, (0, chunk_size_samples - len(chunk)), 'constant', constant_values=0)
                
                chunk_bytes = chunk.tobytes()
                
                # Créer et envoyer la frame
                frame = rtc.AudioFrame(
                    data=chunk_bytes,
                    sample_rate=current_sample_rate,
                    num_channels=1,
                    samples_per_channel=chunk_size_samples
                )
                
                # Log détaillé pour les premiers chunks
                if chunks_sent < 5:
                    logger.info(f"🔊 [OPTIMISATION MÉMOIRE] Envoi chunk {chunks_sent}: {len(chunk_bytes)} bytes, SR={current_sample_rate}, SamplesPC={chunk_size_samples}")
                
                # OPTIMISATION MÉMOIRE: Utiliser l'AudioSource persistant
                await self.audio_source.capture_frame(frame)
                chunks_sent += 1
                
                # Petit délai pour éviter la surcharge
                # Ce délai est crucial pour un streaming fluide et éviter le blocage
                await asyncio.sleep(chunk_size_samples / current_sample_rate) # Dormir exact. la durée du chunk
            
            logger.info(f"✅ [OPTIMISATION MÉMOIRE] Audio complètement diffusé: {chunks_sent} chunks envoyés")
            
            # Vérifier l'état final avec la publication persistante
            if self._publication and hasattr(self._publication, 'track'):
                track_state = getattr(self._publication.track, 'state', 'unknown')
                logger.info(f"🔊 [OPTIMISATION MÉMOIRE] État final du track persistant: {track_state}")
            
            # Garder le track actif un peu plus longtemps pour s'assurer que le client a le temps de le jouer
            logger.info("🔊 [OPTIMISATION MÉMOIRE] Maintien du track persistant actif pendant 1 seconde après diffusion...")
            await asyncio.sleep(1.0)
            
            logger.info("✅ [OPTIMISATION MÉMOIRE] Diffusion terminée avec succès - objets audio réutilisables")
            
        except Exception as e:
            logger.error(f"❌ [DIAGNOSTIC AUDIO] ERREUR CRITIQUE lors de la diffusion: {e}", exc_info=True)
            logger.error(f"❌ [DIAGNOSTIC AUDIO] Type d'erreur: {type(e).__name__}")
            logger.error(f"❌ [DIAGNOSTIC AUDIO] Message d'erreur: {str(e)}")
    
    async def _emit_event(self, event: agents.stt.SpeechEvent):
        """Émettre un événement sur le flux STT - CORRECTION LIVEKIT V1.X"""
        try:
            # CORRECTION: Dans LiveKit v1.x, les événements STT sont gérés différemment
            # Nous devons créer notre propre système d'événements ou les ignorer
            
            if hasattr(self.stt_stream, '_event_queue') and self.stt_stream._event_queue:
                await self.stt_stream._event_queue.put(event)
                logger.debug(f"✅ CORRECTION: Événement émis via _event_queue: {event.type}")
            elif hasattr(self.stt_stream, 'emit') and callable(self.stt_stream.emit):
                # Essayer la méthode emit si disponible
                try:
                    await self.stt_stream.emit(event)
                    logger.debug(f"✅ CORRECTION: Événement émis via emit(): {event.type}")
                except Exception as emit_error:
                    logger.debug(f"⚠️ CORRECTION: emit() échoué: {emit_error}")
            else:
                # Dans LiveKit v1.x, les événements STT peuvent être optionnels
                # Log en debug au lieu de warning pour réduire le bruit
                logger.debug(f"🔧 CORRECTION: Événement STT ignoré (pas de queue): {event.type}")
                
                # Créer une queue temporaire si nécessaire
                if not hasattr(self.stt_stream, '_event_queue'):
                    self.stt_stream._event_queue = asyncio.Queue()
                    logger.info("🔧 CORRECTION: Event queue créée pour STT stream")
                    await self.stt_stream._event_queue.put(event)
                    
        except Exception as e:
            logger.debug(f"⚠️ CORRECTION: Erreur émission événement (non-critique): {e}")
            

class CustomLLM(agents.llm.LLM):
    """Service LLM personnalisé utilisant l'API Mistral"""
    
    def __init__(self, session: aiohttp.ClientSession):
        super().__init__()
        self._session = session
        logger.info("🧠 CustomLLM initialisé avec une session HTTP partagée")
    
    async def chat(
        self,
        *,
        chat_ctx: agents.llm.ChatContext,
        fnc_ctx: Optional[Any] = None,
        temperature: Optional[float] = None,
        n: Optional[int] = None,
        parallel_tool_calls: Optional[bool] = None,
    ) -> "agents.llm.LLMStream":
        """Créer un flux de chat avec le LLM."""
        logger.info("🧠 CustomLLM.chat() appelé")

        # Simplification: extraire directement les messages du contexte
        # LiveKit Agents v1.1.3 utilise chat_ctx.messages pour l'accès aux messages
        messages_from_ctx = []
        if hasattr(chat_ctx, 'messages'):
            for msg in chat_ctx.messages:
                # Vérifier si msg.content est une chaîne ou une liste de dictionnaires
                if isinstance(msg.content, str):
                    # Si c'est une chaîne, la transformer en format [{'type': 'text', 'text': '...'}]
                    processed_content = [{"type": "text", "text": msg.content}]
                elif isinstance(msg.content, list):
                    # Si c'est une liste, vérifier si les éléments sont des dictionnaires valides
                    # Pour simplifier, nous allons supposer que c'est le format correct désiré
                    processed_content = msg.content
                else:
                    # Gérer les cas inattendus, par exemple en retournant une chaîne vide ou en loggant une erreur
                    logger.warning(f"⚠️ Type de contenu inattendu pour ChatMessage: {type(msg.content)}")
                    processed_content = [{"type": "text", "text": str(msg.content)}] # Convertir en chaîne au cas où

                messages_from_ctx.append({"role": str(msg.role), "content": processed_content})
            logger.info(f"🧠 Messages extraits du contexte: {len(messages_from_ctx)}")
            for i, msg in enumerate(messages_from_ctx):
                logger.info(f"🧠 Message {i}: role='{msg.get('role', 'N/A')}', content='{msg.get('content', 'N/A')[:50]}...'")
        else:
            logger.warning("⚠️ ChatContext.messages n'est pas disponible. Utilisation des messages par défaut.")
            messages_from_ctx = [
                {"role": "system", "content": [{"type": "text", "text": "Tu es un coach vocal expert. Sois concis et encourageant."}]},
                {"role": "user", "content": [{"type": "text", "text": "Bonjour, je teste le système vocal."}]} # Message par défaut
            ]

        # Prioriser les messages du contexte, sinon utiliser les messages par défaut
        messages = messages_from_ctx if messages_from_ctx else [
            {"role": "system", "content": [{"type": "text", "text": "Tu es un coach vocal expert. Sois concis et encourageant."}]},
            {"role": "user", "content": [{"type": "text", "text": "Bonjour"}]}
        ]
        logger.info(f"🧠 Messages finaux pour LLM: {len(messages)}")

        return CustomLLMStream(
            llm_instance=self,
            session=self._session,
            messages=messages,
            temperature=temperature or 0.7,
            chat_ctx=chat_ctx,
            tools=[],
            conn_options=self._create_default_conn_options()
        )
    
    def _create_default_conn_options(self):
        """Créer des options de connexion par défaut pour éviter l'erreur NoneType"""
        from types import SimpleNamespace
        conn_options = SimpleNamespace()
        conn_options.max_retry = 3
        conn_options.retry_interval = 1.0
        return conn_options
    
    async def aclose(self):
        """Fermer les ressources (la session est gérée à l'extérieur maintenant)"""
        pass

class CustomLLMStream(agents.llm.LLMStream):
    """Stream personnalisé pour le LLM - Compatible LiveKit v1.x"""
    
    def __init__(self, llm_instance, session: aiohttp.ClientSession, messages: List[Dict[str, str]], temperature: float, chat_ctx, tools=None, conn_options=None):
        super().__init__(llm=llm_instance, chat_ctx=chat_ctx, tools=tools or [], conn_options=conn_options)
        
        self._session = session
        self._messages = messages
        self._temperature = temperature
        self._response_queue = asyncio.Queue()
        self._task: Optional[asyncio.Task] = None
        self._running = False
        self._closed = False
    
    async def __aenter__(self):
        """Démarrer le stream - CORRECTION v1.x"""
        logger.info("🧠 [V1.X] CustomLLMStream.__aenter__() - Démarrage du stream")
        # CORRECTION v1.x: Forcer le démarrage de _run() si nécessaire
        self._running = True
        
        # CORRECTION: Démarrer manuellement _run() car LiveKit v1.x ne le fait pas automatiquement
        logger.info("🧠 [V1.X] Démarrage manuel de _run()...")
        self._task = asyncio.create_task(self._run())
        logger.info("✅ [V1.X] Tâche _run() créée et démarrée")
        
        # Attendre un peu pour que la connexion s'établisse
        await asyncio.sleep(0.1)
        
        logger.info("✅ [V1.X] Stream marqué comme actif et _run() en cours")
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Fermer le stream - CORRECTION v1.x avec protection double fermeture"""
        if hasattr(self, '_closed') and self._closed:
            return  # Déjà fermé
            
        logger.info("🧠 [V1.X] CustomLLMStream.__aexit__() - Fermeture du stream")
        self._running = False
        self._closed = True
        
        # CORRECTION v1.x: Plus de tâche _fetch_response à annuler
        # La méthode _run() se termine automatiquement quand _running = False
        if self._task and not self._task.done():
            logger.info("🧠 [V1.X] Annulation de la tâche existante...")
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                logger.info("🧠 [V1.X] Tâche annulée avec succès")
        
        # Vider la queue pour éviter les blocages
        try:
            while not self._response_queue.empty():
                self._response_queue.get_nowait()
        except:
            pass
        
        logger.info("✅ [V1.X] Stream fermé")
    
    # CORRECTION v1.x: _fetch_response() supprimée - logique déplacée dans _run()
    
    async def _run(self):
        """Méthode abstraite requise par LLMStream dans LiveKit v1.x - CORRECTION COMPLÈTE"""
        logger.info("🧠 CustomLLMStream._run() démarré - IMPLÉMENTATION v1.x")
        self._running = True
        self._task = asyncio.current_task() # Initialiser _task pour le monitoring du SDK
        
        try:
            # CORRECTION v1.x: Cette méthode doit gérer le flux de données LLM
            # Elle remplace la logique de __aenter__ et _fetch_response
            
            logger.info("🧠 [V1.X] Démarrage de la récupération des données LLM...")
            
            headers = {
                "Authorization": f"Bearer {MISTRAL_API_KEY}",
                "Content-Type": "application/json"
            }
            
            data = {
                "model": MISTRAL_MODEL,
                "messages": self._messages,
                "temperature": self._temperature,
                "stream": True
            }
            
            logger.info(f"🧠 [V1.X] Appel API Mistral avec {len(self._messages)} messages")
            
            async with self._session.post(
                MISTRAL_BASE_URL,
                headers=headers,
                json=data,
                timeout=aiohttp.ClientTimeout(total=60)
            ) as response:
                if response.status == 200:
                    logger.info("✅ [V1.X] Connexion API Mistral établie")
                    
                    async for line in response.content:
                        if not self._running:
                            logger.info("🧠 [V1.X] Stream arrêté par signal externe")
                            break
                            
                        if line:
                            line_str = line.decode('utf-8').strip()
                            if line_str.startswith("data: "):
                                data_str = line_str[6:]
                                if data_str == "[DONE]":
                                    logger.info("✅ [V1.X] Stream terminé normalement")
                                    break
                                try:
                                    chunk_data = json.loads(data_str)
                                    await self._response_queue.put(chunk_data)
                                    logger.debug(f"🧠 [V1.X] Chunk traité: {chunk_data.get('choices', [{}])[0].get('delta', {}).get('content', '')[:50]}")
                                except json.JSONDecodeError:
                                    logger.warning(f"⚠️ [V1.X] Impossible de décoder: {data_str}")
                else:
                    error_text = await response.text()
                    logger.error(f"❌ [V1.X] Erreur Mistral API {response.status}: {error_text}")
                    
        except asyncio.CancelledError:
            logger.info("🧠 [V1.X] CustomLLMStream._run() annulé")
            self._running = False
        except Exception as e:
            logger.error(f"❌ [V1.X] Erreur dans _run(): {e}", exc_info=True)
            self._running = False
        finally:
            # Signal de fin pour les consommateurs
            await self._response_queue.put(None)
            logger.info("🧠 [V1.X] CustomLLMStream._run() terminé")
    
    async def __anext__(self):
        """Obtenir le prochain chunk avec protection contre fermeture"""
        if self._closed:
            raise StopAsyncIteration
            
        try:
            chunk = await self._response_queue.get()
            if chunk is None or self._closed:
                raise StopAsyncIteration
            return chunk
        except asyncio.CancelledError:
            raise StopAsyncIteration

class CustomTTS(agents.tts.TTS):
    """Service TTS personnalisé utilisant OpenAI"""
    
    def __init__(self, session: aiohttp.ClientSession):
        super().__init__(
            capabilities=agents.tts.TTSCapabilities(
                streaming=True
            ),
            sample_rate=24000,
            num_channels=1
        )
        self._session = session
        logger.info("🔊 CustomTTS initialisé avec une session HTTP partagée")
    
    async def synthesize(
        self,
        text: str,
        *,
        voice: Optional[str] = None,
    ) -> "agents.tts.ChunkedStream":
        """Synthétiser du texte en audio"""
        logger.info(f"🔊 CustomTTS.synthesize() appelé avec: '{text[:50]}...'")
        
        return CustomTTSStream(self._session, text)
    
    async def aclose(self):
        """Fermer les ressources (la session est gérée à l'extérieur maintenant)"""
        pass

class CustomTTSStream:
    """Stream personnalisé pour le TTS OpenAI"""
    
    def __init__(self, session: aiohttp.ClientSession, text: str):
        self._session = session
        self._text = text
        self._audio_queue = asyncio.Queue()
        self._task: Optional[asyncio.Task] = None
        self._closed = False
        self._running = False
    
    async def __aenter__(self):
        """Démarrer le stream avec protection contre double démarrage"""
        if self._running:
            return self
        
        self._running = True
        self._closed = False
        self._task = asyncio.create_task(self._generate_audio())
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Fermer le stream avec protection contre double fermeture"""
        if hasattr(self, '_closed') and self._closed:
            return  # Déjà fermé
        
        self._closed = True
        
        if self._task and not self._task.done():
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        
        # Vider la queue pour éviter les blocages
        try:
            while not self._audio_queue.empty():
                self._audio_queue.get_nowait()
        except:
            pass
    
    async def _generate_audio(self):
        """Générer l'audio avec OpenAI TTS - VERSION DIAGNOSTIC"""
        try:
            if self._closed:
                return
                
            logger.info("🎯 [DIAGNOSTIC TTS] DÉBUT GÉNÉRATION AUDIO OPENAI")
            logger.info(f"🎯 [DIAGNOSTIC TTS] Texte à synthétiser: '{self._text[:100]}...'")
            logger.info(f"🎯 [DIAGNOSTIC TTS] Longueur du texte: {len(self._text)} caractères")
            
            # Vérifier la clé API
            if not OPENAI_API_KEY:
                logger.error("❌ [DIAGNOSTIC TTS] OPENAI_API_KEY non configurée!")
                return
            
            logger.info(f"🎯 [DIAGNOSTIC TTS] Clé API OpenAI: {OPENAI_API_KEY[:10]}...")
            
            headers = {
                "Authorization": f"Bearer {OPENAI_API_KEY}",
                "Content-Type": "application/json"
            }
            
            # CORRECTION: Adapter le format pour le service TTS local
            data = {
                "text": self._text,
                "voice": "alloy"
            }
            
            logger.info(f"🎯 [DIAGNOSTIC TTS] Paramètres: text='{self._text[:50]}...', voice=alloy")
            logger.info("🎯 [DIAGNOSTIC TTS] Envoi de la requête au service TTS local...")
            
            # CORRECTION: Utiliser le service TTS local au lieu de l'API OpenAI externe
            tts_url = "http://openai-tts:5002/api/tts"
            logger.info(f"🎯 [DIAGNOSTIC TTS] CORRECTION: Appel du service TTS local: {tts_url}")

            async with self._session.post(
                tts_url,
                headers={"Content-Type": "application/json"},
                json=data,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                logger.info(f"🎯 [DIAGNOSTIC TTS] Réponse reçue: status={response.status}")
                
                if response.status == 200:
                    audio_data = await response.read()
                    logger.info(f"✅ [DIAGNOSTIC TTS] Audio WAV généré avec succès: {len(audio_data)} bytes")

                    # CORRECTION: Vérifier si les données commencent par l'en-tête WAV
                    if audio_data.startswith(b'RIFF'):
                        logger.info("✅ [DIAGNOSTIC TTS] Format WAV détecté - extraction des données PCM")
                        import io
                        import wave
                        
                        try:
                            # Extraire les données PCM du fichier WAV
                            with io.BytesIO(audio_data) as wav_buffer:
                                with wave.open(wav_buffer, 'rb') as wav_file:
                                    # Lire les paramètres WAV
                                    n_channels = wav_file.getnchannels()
                                    sampwidth = wav_file.getsampwidth()
                                    framerate = wav_file.getframerate()
                                    n_frames = wav_file.getnframes()
                                    
                                    logger.info(f"🎯 [DIAGNOSTIC TTS] Paramètres WAV: {n_channels}ch, {sampwidth}bytes/sample, {framerate}Hz, {n_frames} frames")
                                    
                                    # Extraire les données PCM brutes
                                    pcm_data = wav_file.readframes(n_frames)
                                    logger.info(f"✅ [DIAGNOSTIC TTS] Données PCM extraites: {len(pcm_data)} bytes")
                                    
                                    # Créer le chunk audio avec les données PCM
                                    chunk = type('AudioChunk', (), {
                                        'data': pcm_data
                                    })()
                                    
                                    logger.info("🎯 [DIAGNOSTIC TTS] Ajout du chunk audio PCM à la queue")
                                    await self._audio_queue.put(chunk)
                                    logger.info("✅ [DIAGNOSTIC TTS] Chunk audio PCM ajouté avec succès")
                                    
                        except Exception as wav_error:
                            logger.error(f"❌ [DIAGNOSTIC TTS] Erreur lors de l'extraction PCM du WAV: {wav_error}")
                            # Fallback: utiliser les données brutes comme PCM
                            chunk = type('AudioChunk', (), {
                                'data': audio_data
                            })()
                            await self._audio_queue.put(chunk)
                    else:
                        logger.info("✅ [DIAGNOSTIC TTS] Format PCM brut détecté - utilisation directe")
                        # Les données sont déjà en PCM brut
                        chunk = type('AudioChunk', (), {
                            'data': audio_data
                        })()
                        
                        logger.info("🎯 [DIAGNOSTIC TTS] Ajout du chunk audio PCM brut à la queue")
                        await self._audio_queue.put(chunk)
                        logger.info("✅ [DIAGNOSTIC TTS] Chunk audio PCM brut ajouté avec succès")
                    
                else:
                    error_text = await response.text()
                    logger.error(f"❌ [DIAGNOSTIC TTS] Erreur API OpenAI {response.status}")
                    logger.error(f"❌ [DIAGNOSTIC TTS] Détails: {error_text}")
                    
                    # Analyser l'erreur
                    if response.status == 401:
                        logger.error("❌ [DIAGNOSTIC TTS] Erreur d'authentification - vérifier OPENAI_API_KEY")
                    elif response.status == 429:
                        logger.error("❌ [DIAGNOSTIC TTS] Limite de taux dépassée")
                    elif response.status == 500:
                        logger.error("❌ [DIAGNOSTIC TTS] Erreur serveur OpenAI")
            
        except aiohttp.ClientError as e:
            logger.error(f"❌ [DIAGNOSTIC TTS] Erreur réseau: {type(e).__name__}: {e}")
        except asyncio.TimeoutError:
            logger.error("❌ [DIAGNOSTIC TTS] Timeout lors de la génération audio (30s)")
        except Exception as e:
            logger.error(f"❌ [DIAGNOSTIC TTS] Erreur inattendue: {type(e).__name__}: {e}", exc_info=True)
        finally:
            logger.info("🎯 [DIAGNOSTIC TTS] Ajout du signal de fin (None) à la queue")
            await self._audio_queue.put(None)
            logger.info("✅ [DIAGNOSTIC TTS] Génération audio terminée")
    
    def __aiter__(self):
        """Itérateur asynchrone"""
        return self
    
    async def __anext__(self):
        """Obtenir le prochain chunk audio avec protection contre fermeture"""
        if self._closed:
            raise StopAsyncIteration
            
        try:
            chunk = await self._audio_queue.get()
            if chunk is None or self._closed:
                raise StopAsyncIteration
            return chunk
        except asyncio.CancelledError:
            raise StopAsyncIteration

class EloquenceAgent(Agent):
    def __init__(self, stt_service, llm_service, tts_service):
        super().__init__(instructions="Je suis un agent vocal Eloquence IA, prêt à dialoguer en temps réel et à diffuser des réponses audio.")
        self.stt_service = stt_service
        self.llm_service = llm_service
        self.tts_service = tts_service
        self.audio_source = None
        self.audio_track = None
        self.publication = None
    
    async def on_connected(self, room: rtc.Room) -> None:
        """Handler déclenché lorsque l'agent est connecté à la room - SIGNATURE CORRIGÉE"""
        logger.debug("🔗 [DIAGNOSTIC] on_connected appelé - début de la fonction")
        logger.info(f"✅ [AGENT CONNECTED] Connexion établie pour Room: {room.name}")
        logger.info("--- DÉBUT: CONFIGURE AUDIO PUBLICATION EN ON_CONNECTED ---")

        try:
            # Attendre un peu pour s'assurer que la connexion est stable
            await asyncio.sleep(2)
            
            logger.info("🔊 [STARTUP] --- Début de la PUBLICATION AUDIO et envoi du MESSAGE DE BIENVENUE ---")
            
            logger.info("🔊 [STARTUP - ÉTAPE 1] Création de la source audio...")
            self.audio_source = rtc.AudioSource(sample_rate=48000, num_channels=1)
            logger.info(f"✅ [STARTUP - ÉTAPE 1] Source audio créée: {self.audio_source}")
            
            logger.info("🔊 [STARTUP - ÉTAPE 2] Création du track audio local...")
            track_name = f"agent-audio-{uuid.uuid4().hex[:8]}"
            self.audio_track = rtc.LocalAudioTrack.create_audio_track(track_name, self.audio_source)
            logger.info(f"✅ [STARTUP - ÉTAPE 2] Track audio local créé: {self.audio_track}")
            
            logger.info("🔊 [STARTUP - ÉTAPE 3] Publication du track audio sur la Room LiveKit...")
            options = rtc.TrackPublishOptions(
                source=rtc.TrackSource.SOURCE_MICROPHONE,
                dtx=False
            )
            
            self.publication = await room.local_participant.publish_track(self.audio_track, options)
            logger.info(f"✅ [STARTUP - ÉTAPE 3] Track publié avec succès. SID: {self.publication.sid}")
            logger.info("--- FIN: CONFIGURE AUDIO PUBLICATION EN ON_CONNECTED ---")
            
            logger.info("🔊 [STARTUP - ÉTAPE 4] Envoi du message de bienvenue...")
            try:
                await self.send_welcome_message()
                logger.info("✅ [STARTUP - ÉTAPE 4] Message de bienvenue envoyé avec succès.")
            except Exception as welcome_error:
                logger.error(f"❌ [STARTUP - ÉTAPE 4] Erreur lors de l'envoi du message de bienvenue: {welcome_error}", exc_info=True)
            
            # CORRECTION: Attendre un peu plus pour s'assurer que le TTS est terminé
            logger.info("🔊 [STARTUP - ÉTAPE 5] Attente de 10 secondes pour s'assurer que le TTS est terminé...")
            await asyncio.sleep(10)
            logger.info("✅ [STARTUP - ÉTAPE 5] Attente terminée.")

        except Exception as e:
            logger.error(f"❌ [ON_CONNECTED] Erreur critique lors de la configuration post-connexion: {e}", exc_info=True)
        finally:
            logger.info("--- Fin de la configuration 'on_connected' ---")

    async def on_track_subscribed(self, track: rtc.Track, publication: rtc.RemoteTrackPublication, participant: rtc.RemoteParticipant) -> None:
        """Handler pour les pistes audio entrantes - SIGNATURE CORRIGÉE"""
        logger.debug("🔗 [DIAGNOSTIC] on_track_subscribed appelé - début de la fonction")
        logger.debug(f"DEBUG: on_track_subscribed appelé pour track: {track.name}, kind: {track.kind}")
        if track.kind == rtc.TrackKind.KIND_AUDIO:
            logger.info(f"🎧 [TRACK SUBSCRIBED] Détection d'une piste AUDIO: {track.name}")
            logger.info(f"🎧 [TRACK SUBSCRIBED] Piste audio de {participant.identity} ({track.name}) reçue.")
            # Le traitement audio sera géré par le gestionnaire d'événements principal
        else:
            logger.info(f"ℹ️ [TRACK SUBSCRIBED] Piste non-audio ({track.kind}) de {participant.identity} ignorée.")
    
    async def send_welcome_message(self):
        """Envoie un message de bienvenue via TTS"""
        try:
            welcome_text = "Bonjour ! Je suis votre assistant vocal Eloquence. Je suis maintenant connecté et prêt à vous aider."
            
            # Utiliser le service TTS configuré
            if self.tts_service and self.audio_source:
                logger.info("🎵 [WELCOME] Génération du message de bienvenue via TTS...")
                
                # Synthétiser l'audio avec gestion complète du stream
                logger.info("🎵 [WELCOME] Démarrage de la synthèse TTS...")
                stream = await self.tts_service.synthesize(welcome_text)
                
                # Collecter les chunks audio avec diagnostic
                audio_chunks = []
                chunk_count = 0
                
                logger.info("🎵 [WELCOME] Collecte des chunks audio du stream TTS...")
                async with stream as active_stream:
                    async for chunk in active_stream:
                        if hasattr(chunk, 'data'):
                            audio_chunks.append(chunk.data)
                            chunk_count += 1
                            logger.info(f"🎵 [WELCOME] Chunk {chunk_count} reçu: {len(chunk.data)} bytes")
                
                logger.info(f"🎵 [WELCOME] Total chunks collectés: {chunk_count}")
                
                if audio_chunks:
                    combined_audio = b''.join(audio_chunks)
                    logger.info(f"✅ [WELCOME] Audio généré: {len(combined_audio)} bytes")
                    
                    # Diffuser l'audio et attendre que ce soit terminé
                    logger.info("🎵 [WELCOME] Début de la diffusion audio...")
                    await self.stream_audio_to_livekit(combined_audio)
                    logger.info("✅ [WELCOME] Message de bienvenue diffusé avec succès")
                else:
                    logger.warning("⚠️ [WELCOME] Aucune donnée audio générée")
            else:
                logger.warning("⚠️ [WELCOME] Service TTS ou AudioSource non disponible")
                
        except Exception as e:
            logger.error(f"❌ [WELCOME] Erreur lors de l'envoi du message de bienvenue: {e}", exc_info=True)
    
    async def stream_audio_to_livekit(self, audio_data: bytes):
        """Diffuse l'audio PCM vers LiveKit"""
        try:
            if not self.audio_source:
                logger.error("❌ [STREAM] AudioSource non disponible")
                return
            
            # Convertir en numpy array int16
            audio_array = np.frombuffer(audio_data, dtype=np.int16)
            
            # Rééchantillonner de 24kHz à 48kHz si nécessaire
            original_rate = 24000
            target_rate = 48000
            
            if original_rate != target_rate:
                audio_float = audio_array.astype(np.float32)
                num_samples = int(len(audio_float) * target_rate / original_rate)
                resampled = resample(audio_float, num_samples)
                
                # Normaliser et convertir en int16
                max_val = np.max(np.abs(resampled))
                if max_val > 0:
                    audio_array = (resampled * 32767 / max_val).astype(np.int16)
                else:
                    audio_array = np.zeros_like(resampled, dtype=np.int16)
            
            # Envoyer par chunks de 10ms
            chunk_size = int(target_rate * 0.01)  # 480 samples pour 10ms à 48kHz
            
            for i in range(0, len(audio_array), chunk_size):
                chunk = audio_array[i:i+chunk_size]
                
                # Padding si nécessaire
                if len(chunk) < chunk_size:
                    chunk = np.pad(chunk, (0, chunk_size - len(chunk)), 'constant')
                
                frame = rtc.AudioFrame(
                    data=chunk.tobytes(),
                    sample_rate=target_rate,
                    num_channels=1,
                    samples_per_channel=chunk_size
                )
                
                await self.audio_source.capture_frame(frame)
                await asyncio.sleep(0.01)  # 10ms delay
            
            logger.info("✅ [STREAM] Audio diffusé avec succès")
            
        except Exception as e:
            logger.error(f"❌ [STREAM] Erreur lors de la diffusion: {e}", exc_info=True)
    
    async def process_incoming_audio(self, track: rtc.Track, room: rtc.Room = None):
        """Traite l'audio entrant du client"""
        try:
            logger.info("🎤 [PROCESS] Démarrage du traitement audio entrant")
            
            stt_stream = self.stt_service.stream()
            
            # Créer le contexte de traitement avec la room
            async with StreamAdapterContext(
                stt_stream,
                room=room,  # Utiliser la room passée en paramètre
                llm_service=self.llm_service,
                tts_service=self.tts_service,
                audio_source=self.audio_source,
                audio_track=self.audio_track
            ) as context:
                
                audio_stream = rtc.AudioStream(track)
                async for audio_frame_event in audio_stream:
                    context.push_frame(audio_frame_event.frame)
                    
        except Exception as e:
            logger.error(f"❌ [PROCESS] Erreur lors du traitement audio: {e}", exc_info=True)


async def create_and_configure_agent(ctx: JobContext) -> None:
    """Créer et configurer l'agent vocal avec l'architecture manuelle qui fonctionne + VAD Silero."""
    print("=" * 80)
    print("🚀 [AGENT MANUEL + VAD] Agent vocal Eloquence avec architecture manuelle + VAD Silero")
    print(f"🚀 [AGENT MANUEL + VAD] Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)

    logger.info("--- ARCHITECTURE MANUELLE + VAD: Retour à l'architecture qui fonctionnait ---")
    
    http_session: Optional[aiohttp.ClientSession] = None
    try:
        http_session = aiohttp.ClientSession()
        register_http_session(http_session)  # Enregistrer pour fermeture propre
        logger.info("🔧 [AGENT MANUEL + VAD] Session HTTP partagée créée.")

        # Initialiser les services
        logger.info("🔧 [AGENT MANUEL + VAD] Initialisation des services...")
        custom_llm = CustomLLM(http_session)
        custom_tts = CustomTTS(http_session)
        custom_stt = CustomSTT()
        logger.info("✅ [AGENT MANUEL + VAD] Services initialisés.")

        # Charger VAD Silero pour améliorer la détection vocale
        logger.info("🎯 [VAD] Chargement de Silero VAD...")
        vad = silero.VAD.load()
        logger.info("✅ [VAD] Silero VAD chargé avec succès.")
        
        # DIAGNOSTIC VAD: Vérifier les méthodes disponibles
        logger.info(f"🔍 [VAD DIAGNOSTIC] Type de l'objet VAD: {type(vad)}")
        logger.info(f"🔍 [VAD DIAGNOSTIC] Méthodes disponibles: {[method for method in dir(vad) if not method.startswith('_')]}")
        logger.info(f"🔍 [VAD DIAGNOSTIC] VAD est callable: {callable(vad)}")
        
        # Tester si VAD a une méthode spécifique
        if hasattr(vad, '__call__'):
            logger.info("✅ [VAD DIAGNOSTIC] VAD a une méthode __call__")
        if hasattr(vad, 'detect'):
            logger.info("✅ [VAD DIAGNOSTIC] VAD a une méthode detect")
        if hasattr(vad, 'predict'):
            logger.info("✅ [VAD DIAGNOSTIC] VAD a une méthode predict")

        # Créer l'agent avec l'architecture manuelle qui fonctionnait
        logger.info("🔧 [AGENT MANUEL + VAD] Création de l'agent Eloquence...")
        agent = EloquenceAgent(custom_stt, custom_llm, custom_tts)
        logger.info("✅ [AGENT MANUEL + VAD] Agent Eloquence créé.")

        # Connecter à la room
        logger.info("🔗 [AGENT MANUEL + VAD] Connexion à la room...")
        await ctx.connect()
        logger.info("✅ [AGENT MANUEL + VAD] Room connectée avec succès.")

        # Configurer les gestionnaires d'événements manuellement
        logger.info("🔧 [AGENT MANUEL + VAD] Configuration des gestionnaires d'événements...")
        
        @ctx.room.on("participant_connected")
        def on_participant_connected(participant: rtc.RemoteParticipant):
            logger.info(f"🔗 [PARTICIPANT] Participant connecté: {participant.identity}")

        @ctx.room.on("track_subscribed")
        def on_track_subscribed(track: rtc.Track, publication: rtc.RemoteTrackPublication, participant: rtc.RemoteParticipant):
            logger.info(f"🎧 [TRACK] Track souscrit: {track.name} de {participant.identity}")
            if track.kind == rtc.TrackKind.KIND_AUDIO:
                logger.info("🎤 [AUDIO TRACK] Démarrage du traitement audio avec VAD...")
                # Créer une tâche pour traiter l'audio avec VAD
                asyncio.create_task(process_audio_with_vad(track, custom_stt, custom_llm, custom_tts, ctx.room, vad))

        logger.info("✅ [AGENT MANUEL + VAD] Gestionnaires d'événements configurés.")

        # Appeler on_connected pour initialiser l'agent
        logger.info("🔧 [AGENT MANUEL + VAD] Initialisation de l'agent...")
        await agent.on_connected(ctx.room)
        logger.info("✅ [AGENT MANUEL + VAD] Agent initialisé avec succès.")

        # Attendre les interactions
        logger.info("🔗 [AGENT MANUEL + VAD] Agent prêt - en attente d'interactions vocales...")
        logger.info("🎯 [VAD STATUS] VAD Silero actif - détection vocale améliorée...")
        
        try:
            # Attendre 10 minutes pour permettre les tests
            await asyncio.sleep(600)  # 10 minutes
            logger.info("🔗 [AGENT MANUEL + VAD] Timeout de 10 minutes atteint - arrêt de l'agent")
        except asyncio.CancelledError:
            logger.info("🔗 [AGENT MANUEL + VAD] Agent annulé par signal externe")
            raise
        
    except Exception as e:
        logger.error(f"❌ [AGENT MANUEL + VAD ERROR] Erreur fatale: {e}", exc_info=True)
        raise
    finally:
        logger.info("🧹 [AGENT MANUEL + VAD CLEANUP] Nettoyage des services...")
        if http_session and not http_session.closed:
            try:
                await http_session.close()
                logger.debug("✅ [AGENT] Session HTTP principale fermée proprement")
            except Exception as close_error:
                logger.warning(f"⚠️ [AGENT] Erreur fermeture session principale: {close_error}")
        logger.info("--- Fin de create_and_configure_agent MANUEL + VAD ---")


async def process_audio_with_vad(track: rtc.AudioTrack, stt: CustomSTT, llm: CustomLLM, tts: CustomTTS, room: rtc.Room, vad):
    """Traiter l'audio avec VAD Silero pour une meilleure détection vocale."""
    logger.info("🎤 [VAD AUDIO] Démarrage du traitement audio avec VAD Silero...")
    
    audio_buffer = []
    is_speaking = False
    speech_start_time = None
    silence_duration = 0
    SILENCE_THRESHOLD = 1.0  # 1 seconde de silence pour terminer
    
    audio_stream = rtc.AudioStream(track)
    
    async for audio_frame_event in audio_stream:
        try:
            # CORRECTION: Vérification de sécurité pour éviter l'erreur AttributeError
            if not hasattr(audio_frame_event, 'frame'):
                logger.warning("⚠️ [VAD FRAME] AudioFrameEvent sans attribut 'frame' - ignoré")
                continue
                
            if not hasattr(audio_frame_event.frame, 'data'):
                logger.warning("⚠️ [VAD FRAME] AudioFrame sans attribut 'data' - ignoré")
                continue
            
            # Convertir le frame audio en numpy array
            audio_data = np.frombuffer(audio_frame_event.frame.data, dtype=np.int16)
            frame = audio_frame_event.frame
            
            # Vérification supplémentaire des attributs du frame
            if not hasattr(frame, 'sample_rate') or not hasattr(frame, 'samples_per_channel'):
                logger.warning("⚠️ [VAD FRAME] Frame sans attributs sample_rate ou samples_per_channel - ignoré")
                continue
            
            # DIAGNOSTIC VAD: Analyser les données audio avant VAD
            logger.debug(f"🔍 [VAD DIAGNOSTIC] Audio data shape: {audio_data.shape}, dtype: {audio_data.dtype}")
            logger.debug(f"🔍 [VAD DIAGNOSTIC] Sample rate: {frame.sample_rate}, samples per channel: {frame.samples_per_channel}")
            logger.debug(f"🔍 [VAD DIAGNOSTIC] Audio data range: min={np.min(audio_data)}, max={np.max(audio_data)}")
            
            # Convertir les données audio au format attendu par VAD Silero (float32, normalisé -1 à 1)
            try:
                # VAD Silero attend des données float32 normalisées entre -1 et 1
                audio_data_float = audio_data.astype(np.float32) / 32768.0
                logger.debug(f"🔍 [VAD DIAGNOSTIC] Audio data converted to float32: shape={audio_data_float.shape}, range: min={np.min(audio_data_float):.6f}, max={np.max(audio_data_float):.6f}")
                
                # CORRECTION: Utiliser une heuristique basée sur l'énergie audio
                # Le VAD Silero dans LiveKit v1.x nécessite une approche différente
                logger.debug("🔍 [VAD CORRECTION] Utilisation d'une heuristique basée sur l'énergie audio")
                
                try:
                    # Calculer l'énergie RMS de l'audio
                    energy = np.sqrt(np.mean(audio_data_float**2))
                    
                    # Calculer la probabilité de parole basée sur l'énergie
                    # Seuils ajustables selon les besoins
                    MIN_ENERGY = 0.001  # Seuil minimum pour considérer comme du bruit
                    MAX_ENERGY = 0.1    # Seuil maximum pour normaliser
                    
                    if energy < MIN_ENERGY:
                        speech_prob = 0.0  # Silence
                    else:
                        # Normaliser l'énergie entre 0 et 1
                        normalized_energy = min(energy / MAX_ENERGY, 1.0)
                        speech_prob = normalized_energy
                    
                    logger.debug(f"🔍 [VAD HEURISTIQUE] Énergie: {energy:.6f}, Probabilité: {speech_prob:.3f}")
                    
                except Exception as energy_error:
                    logger.warning(f"⚠️ [VAD HEURISTIQUE] Erreur calcul énergie: {energy_error}")
                    # Valeur par défaut en cas d'erreur
                    speech_prob = 0.5
                    
                logger.debug(f"✅ [VAD DIAGNOSTIC] VAD appelé avec succès, résultat: {speech_prob}")
                
            except Exception as vad_error:
                logger.error(f"❌ [VAD DIAGNOSTIC] Erreur lors de l'appel VAD: {vad_error}")
                logger.error(f"❌ [VAD DIAGNOSTIC] Type d'erreur: {type(vad_error).__name__}")
                logger.error(f"❌ [VAD DIAGNOSTIC] Détails: {str(vad_error)}")
                # Utiliser une valeur par défaut en cas d'erreur
                speech_prob = 0.5
            
            logger.debug(f"🎯 [VAD] Probabilité de parole: {speech_prob:.3f}")
            
            # Seuil de détection vocale (ajustable)
            SPEECH_THRESHOLD = 0.5
            
            if speech_prob > SPEECH_THRESHOLD:
                if not is_speaking:
                    logger.info("🗣️ [VAD] Début de parole détecté")
                    is_speaking = True
                    speech_start_time = time.time()
                    audio_buffer = []
                
                # Ajouter l'audio au buffer
                audio_buffer.append(audio_data)
                silence_duration = 0
                
            else:
                if is_speaking:
                    silence_duration += frame.samples_per_channel / frame.sample_rate
                    audio_buffer.append(audio_data)
                    
                    if silence_duration >= SILENCE_THRESHOLD:
                        logger.info("🔇 [VAD] Fin de parole détectée - traitement STT...")
                        
                        # Concaténer tout l'audio du buffer
                        if audio_buffer:
                            full_audio = np.concatenate(audio_buffer)
                            
                            # Traiter avec STT
                            try:
                                # Convertir en WAV pour STT
                                wav_data = convert_audio_to_wav(full_audio, frame.sample_rate)
                                
                                # Transcription
                                transcription = await transcribe_audio_with_whisper(wav_data)
                                
                                if transcription and transcription.strip():
                                    logger.info(f"📝 [STT] Transcription: {transcription}")
                                    
                                    # Traitement LLM
                                    response = await process_with_llm(transcription, llm)
                                    logger.info(f"🤖 [LLM] Réponse: {response}")
                                    
                                    # Synthèse TTS
                                    audio_response = await synthesize_with_tts(response, tts)
                                    
                                    # Diffuser la réponse
                                    await stream_audio_to_room(audio_response, room)
                                    
                                else:
                                    logger.info("🔇 [STT] Aucune transcription détectée")
                                    
                            except Exception as e:
                                logger.error(f"❌ [VAD PROCESSING] Erreur traitement: {e}")
                        
                        # Reset
                        is_speaking = False
                        audio_buffer = []
                        silence_duration = 0
                        
        except Exception as e:
            logger.error(f"❌ [VAD FRAME] Erreur traitement frame: {e}")
            logger.error(f"❌ [VAD FRAME] Type de audio_frame_event: {type(audio_frame_event)}")
            logger.error(f"❌ [VAD FRAME] Attributs disponibles: {dir(audio_frame_event) if hasattr(audio_frame_event, '__dict__') else 'N/A'}")
            continue


def convert_audio_to_wav(audio_data: np.ndarray, sample_rate: int) -> bytes:
    """Convertir les données audio en format WAV."""
    try:
        # Créer un buffer en mémoire pour le WAV
        wav_buffer = io.BytesIO()
        
        with wave.open(wav_buffer, 'wb') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(audio_data.astype(np.int16).tobytes())
        
        wav_buffer.seek(0)
        return wav_buffer.read()
        
    except Exception as e:
        logger.error(f"❌ [WAV CONVERSION] Erreur: {e}")
        raise


async def transcribe_audio_with_whisper(wav_data: bytes) -> str:
    """Transcrire l'audio avec Whisper."""
    session = None
    try:
        whisper_url = "http://whisper-stt:8001/transcribe"
        
        session = aiohttp.ClientSession()
        register_http_session(session)  # Enregistrer pour fermeture propre
        form = aiohttp.FormData()
        form.add_field('audio', wav_data, filename='audio.wav', content_type='audio/wav')
        form.add_field('language', 'fr')
        form.add_field('model', 'whisper-large-v3-turbo')
        
        async with session.post(whisper_url, data=form, timeout=aiohttp.ClientTimeout(total=30)) as response:
            if response.status == 200:
                data = await response.json()
                return data.get('text', '').strip()
            else:
                logger.error(f"❌ [STT] Erreur Whisper {response.status}")
                return ""
                    
    except Exception as e:
        logger.error(f"❌ [STT] Erreur transcription: {e}")
        return ""
    finally:
        if session and not session.closed:
            try:
                await session.close()
                logger.debug("✅ [STT] Session HTTP fermée proprement")
            except Exception as close_error:
                logger.warning(f"⚠️ [STT] Erreur fermeture session: {close_error}")


async def process_with_llm(text: str, llm: CustomLLM) -> str:
    """Traiter le texte avec le LLM."""
    try:
        # Créer un contexte de chat simple
        chat_ctx = agents.llm.ChatContext()
        
        # CORRECTION: Créer les messages avec le format LISTE requis par Pydantic validation
        system_msg = ChatMessage(role="system", content=["Tu es un assistant vocal. Réponds de manière concise et naturelle."])
        user_msg = ChatMessage(role="user", content=[text])
        
        chat_ctx.messages = [system_msg, user_msg]
        
        # Appeler le LLM
        stream = await llm.chat(chat_ctx=chat_ctx)
        
        response_text = ""
        async with stream as active_stream:
            async for chunk in active_stream:
                if isinstance(chunk, dict) and chunk.get('choices'):
                    delta = chunk['choices'][0].get('delta', {})
                    content = delta.get('content')
                    if content:
                        response_text += content
        
        return response_text if response_text else "Je n'ai pas de réponse pour le moment."
        
    except Exception as e:
        logger.error(f"❌ [LLM] Erreur traitement: {e}")
        return "Une erreur est survenue."


async def synthesize_with_tts(text: str, tts: CustomTTS) -> bytes:
    """Synthétiser le texte avec TTS."""
    try:
        stream = await tts.synthesize(text)
        
        audio_chunks = []
        async with stream as active_stream:
            async for chunk in active_stream:
                if hasattr(chunk, 'data'):
                    audio_chunks.append(chunk.data)
        
        return b''.join(audio_chunks) if audio_chunks else b""
        
    except Exception as e:
        logger.error(f"❌ [TTS] Erreur synthèse: {e}")
        return b""


async def stream_audio_to_room(audio_data: bytes, room: rtc.Room):
    """Diffuser l'audio dans la room LiveKit."""
    try:
        logger.info("🎵 [AUDIO STREAM] Diffusion audio dans la room...")
        
        # Créer une source audio
        source = rtc.AudioSource(sample_rate=48000, num_channels=1)
        track = rtc.LocalAudioTrack.create_audio_track("agent-response", source)
        
        # Publier le track
        options = rtc.TrackPublishOptions()
        publication = await room.local_participant.publish_track(track, options)
        logger.info(f"✅ [AUDIO STREAM] Track publié: {publication.sid}")
        
        # Les données "audio_data" sont déjà en PCM brut (du CustomTTSStream)
        # Convertir en numpy array
        original_rate = 24000 # Le TTS génère 24kHz
        target_rate = 48000
        
        audio_array = np.frombuffer(audio_data, dtype=np.int16)
        
        # Rééchantillonner de 24kHz à 48kHz si nécessaire
        if len(audio_array) > 0 and original_rate != target_rate:
            logger.info(f"🎵 [AUDIO STREAM] Rééchantillonnage de {original_rate}Hz à {target_rate}Hz...")
            audio_float = audio_array.astype(np.float32)
            num_samples = int(len(audio_float) * target_rate / original_rate)
            resampled = resample(audio_float, num_samples)
            
            # Normaliser et convertir en int16
            max_val = np.max(np.abs(resampled))
            if max_val > 0:
                audio_array_to_stream = (resampled * 32767 / max_val).astype(np.int16)
            else:
                audio_array_to_stream = np.zeros_like(resampled, dtype=np.int16)
            logger.info(f"✅ [AUDIO STREAM] Rééchantillonnage terminé. Taille: {audio_array_to_stream.shape}")
        else:
            audio_array_to_stream = audio_array
            logger.info(f"🎵 [AUDIO STREAM] Pas de rééchantillonnage nécessaire. Taille: {audio_array_to_stream.shape}")
            
        # Envoyer par chunks de 10ms
        chunk_size = int(target_rate * 0.01)  # 480 samples pour 10ms à 48kHz

        if len(audio_array_to_stream) == 0:
            logger.warning("⚠️ [AUDIO STREAM] Aucune donnée audio à diffuser après traitement.")
            return
            
        logger.info(f"🎵 [AUDIO STREAM] Démarrage diffusion de {len(audio_array_to_stream)} samples à {target_rate}Hz...")
        
        for i in range(0, len(audio_array_to_stream), chunk_size):
            chunk = audio_array_to_stream[i:i+chunk_size]
            
            # Padding si nécessaire pour le dernier chunk
            if len(chunk) < chunk_size:
                chunk = np.pad(chunk, (0, chunk_size - len(chunk)), 'constant', constant_values=0)
            
            frame = rtc.AudioFrame(
                data=chunk.tobytes(), # PCM int16 bytes
                sample_rate=target_rate,
                num_channels=1,
                samples_per_channel=chunk_size
            )
            
            await source.capture_frame(frame)
            await asyncio.sleep(0.01)  # 10ms delay
        
        logger.info("✅ [AUDIO STREAM] Diffusion terminée")
        
    except Exception as e:
        logger.error(f"❌ [AUDIO STREAM] Erreur lors de la diffusion: {e}", exc_info=True)


async def process_audio_track(track: rtc.Track, stt: CustomSTT, llm: CustomLLM, tts: CustomTTS, room: rtc.Room):
    """Traiter une piste audio avec optimisation mémoire"""
    logger.info("🔧 [OPTIMISATION MÉMOIRE] Début du traitement d'une piste audio entrante.")
    logger.info("🔧 [OPTIMISATION MÉMOIRE] Tentative de création des objets audio persistants (pour réutilisation).")
    
    try:
        persistent_audio_source = rtc.AudioSource(sample_rate=48000, num_channels=1)
        logger.info(f"✅ [OPTIMISATION MÉMOIRE] AudioSource persistante créée: {persistent_audio_source}")
        
        persistent_audio_track = rtc.LocalAudioTrack.create_audio_track(
            "eloquence_tts_response_persistent",
            persistent_audio_source
        )
        logger.info(f"✅ [OPTIMISATION MÉMOIRE] LocalAudioTrack persistant créé: {persistent_audio_track}")
        
        stt_stream = stt.stream()
        
        async with StreamAdapterContext(
            stt_stream,
            room=room,
            llm_service=llm,
            tts_service=tts,
            audio_source=persistent_audio_source,
            audio_track=persistent_audio_track
        ) as context:
            logger.info("🔧 [OPTIMISATION MÉMOIRE] StreamAdapterContext créé avec objets audio persistants.")
            logger.debug(f"🎧 [AUDIO PROCESS] Traitement d'une frame audio entrante: {{audio_frame_event.frame.samples_per_channel}} samples")
            
            audio_stream = rtc.AudioStream(track)
            async for audio_frame_event in audio_stream:
                context.push_frame(audio_frame_event.frame)
                
    except Exception as e:
        logger.error(f"❌ [OPTIMISATION MÉMOIRE] Erreur lors de la création ou de l'utilisation des objets audio persistants durant le traitement de piste: {e}", exc_info=True)
        logger.info("🔄 [OPTIMISATION MÉMOIRE] Fallback vers la méthode sans objets audio persistants pour le traitement de piste.")
        stt_stream = stt.stream()
        async with StreamAdapterContext(stt_stream, room=room, llm_service=llm, tts_service=tts) as context:
            audio_stream = rtc.AudioStream(track)
            async for audio_frame_event in audio_stream:
                context.push_frame(audio_frame_event.frame)

async def send_welcome_message_immediate(audio_source):
    """Envoie un message de bienvenue immédiatement via l'AudioSource"""
    logger.info("🎵 [WELCOME] Début de la génération et envoi du message de bienvenue...")
    session = None
    try:
        welcome_text = "Bonjour ! Je suis votre assistant vocal Eloquence. Je suis maintenant connecté et prêt à vous aider. Vous pouvez commencer à me parler."
        
        tts_url = "http://openai-tts:8001/synthesize"
        tts_payload = {
            "text": welcome_text,
            "voice": "alloy",
            "response_format": "wav"
        }
        
        logger.info(f"🎵 [WELCOME] Appel de l'API TTS ({tts_url}) pour le message de bienvenue.")
        session = aiohttp.ClientSession()
        register_http_session(session)  # Enregistrer pour fermeture propre
        async with session.post(tts_url, json=tts_payload) as response:
            if response.status == 200:
                audio_data = await response.read()
                logger.info(f"✅ [WELCOME] Message de bienvenue généré avec succès: {len(audio_data)} bytes reçus du TTS.")
                
                logger.info("🎵 [WELCOME] Diffusion immédiate du message de bienvenue via AudioSource...")
                await stream_audio_to_source(audio_data, audio_source)
                logger.info("✅ [WELCOME] Message de bienvenue diffusé avec succès sur AudioSource.")
                
            else:
                error_text = await response.text()
                logger.error(f"❌ [WELCOME] Erreur de l'API TTS lors de la génération du message de bienvenue: HTTP {response.status} - {error_text}")
                    
    except Exception as e:
        logger.error(f"❌ [WELCOME] Erreur inattendue lors de l'envoi du message de bienvenue: {e}", exc_info=True)
    finally:
        if session and not session.closed:
            try:
                await session.close()
                logger.debug("✅ [WELCOME] Session HTTP fermée proprement")
            except Exception as close_error:
                logger.warning(f"⚠️ [WELCOME] Erreur fermeture session: {close_error}")

async def stream_audio_to_source(audio_data: bytes, audio_source):
    """Diffuse des données audio WAV vers une AudioSource, en gérant l'en-tête."""
    logger.info(f"🎵 [STREAM AUDIO] Début de la diffusion de {len(audio_data)} bytes vers AudioSource.")
    try:
        # Utiliser io.BytesIO pour traiter les données en mémoire comme un fichier
        with io.BytesIO(audio_data) as pcm_file:
            with wave.open(pcm_file, 'rb') as wav_file:
                n_channels = wav_file.getnchannels()
                sampwidth = wav_file.getsampwidth()
                framerate = wav_file.getframerate()
                n_frames = wav_file.getnframes()
                
                logger.info(f"🎵 [WAV PARAMS] Canaux: {n_channels}, Largeur d'échantillon: {sampwidth}, Taux: {framerate}, Frames: {n_frames}")

                # Lire les données audio brutes (PCM)
                pcm_data = wav_file.readframes(n_frames)

        logger.info("🎵 [STREAM AUDIO] Conversion des données PCM en numpy array (int16)...")
        audio_array = np.frombuffer(pcm_data, dtype=np.int16)
        logger.info(f"✅ [STREAM AUDIO - WELCOME] Numpy array créé à partir de WAV. Forme: {audio_array.shape}, Dtype: {audio_array.dtype}")
        
        # --- NOUVEL AJOUT DE DIAGNOSTIC ---
        if audio_array.size > 0:
            audio_min_raw = np.min(audio_array)
            audio_max_raw = np.max(audio_array)
            audio_mean_raw = np.mean(audio_array)
            audio_std_raw = np.std(audio_array)
            logger.info(f"🔊 [STREAM AUDIO - WELCOME - ETAPE 1] Stats RAW int16 (pré-resampling): min={audio_min_raw}, max={audio_max_raw}, mean={audio_mean_raw:.2f}, std={audio_std_raw:.2f}")
            if audio_std_raw < 50:
                logger.warning("⚠️ [STREAM AUDIO - WELCOME - ETAPE 1] L'audio int16 RAW (pré-resampling) semble être silencieux.")
        else:
            logger.warning("⚠️ [STREAM AUDIO - WELCOME - ETAPE 1] Audio array RAW est vide.")
        # --- FIN NOUVEL AJOUT ---

        if len(audio_array) > 0:
            from scipy.signal import resample
            
            target_sample_rate = 48000
            if framerate != target_sample_rate:
                logger.info(f"🎵 [STREAM AUDIO - WELCOME - ETAPE 2] Rééchantillonnage de {framerate}Hz à {target_sample_rate}Hz...")
                audio_array_float = audio_array.astype(np.float32)
                num_samples_resampled = int(len(audio_array_float) * target_sample_rate / framerate)
                resampled_float = resample(audio_array_float, num_samples_resampled)
 
                max_abs_resampled_float = np.max(np.abs(resampled_float))
                if max_abs_resampled_float > 0:
                    audio_to_stream = (resampled_float * 32767 / max_abs_resampled_float).astype(np.int16)
                else:
                    audio_to_stream = np.zeros_like(resampled_float, dtype=np.int16) # Toutes les valeurs à zéro si max_abs_val est nul
                logger.info(f"✅ [STREAM AUDIO - WELCOME - ETAPE 2] Audio rééchantillonné à {target_sample_rate}kHz. Forme: {audio_to_stream.shape}")
            else:
                audio_to_stream = audio_array
            
            # --- NOUVEL AJOUT DE DIAGNOSTIC ---
            if audio_to_stream.size > 0:
                audio_stream_min = np.min(audio_to_stream)
                audio_stream_max = np.max(audio_to_stream)
                audio_stream_mean = np.mean(audio_to_stream)
                audio_stream_std = np.std(audio_to_stream)
                logger.info(f"🔊 [STREAM AUDIO - WELCOME - ETAPE 3] Stats STREAM int16 (post-resampling): min={audio_stream_min}, max={audio_stream_max}, mean={audio_stream_mean:.2f}, std={audio_stream_std:.2f}")
                if audio_stream_std < 50:
                    logger.warning("⚠️ [STREAM AUDIO - WELCOME - ETAPE 3] L'audio streamé semble être silencieux APRÈS rééchantillonnage/normalisation.")
            # --- FIN NOUVEL AJOUT ---

            chunk_size = int(target_sample_rate * 0.01)  # 480 samples pour 10ms à 48kHz
            num_chunks = 0
            
            logger.info(f"🎵 [STREAM AUDIO - WELCOME] Envoi de l'audio par chunks de {chunk_size} samples (10ms)...")
            for i in range(0, len(audio_to_stream), chunk_size):
                chunk = audio_to_stream[i:i+chunk_size]
                
                if len(chunk) < chunk_size:
                    chunk = np.pad(chunk, (0, chunk_size - len(chunk)), 'constant', constant_values=0)
                
                frame = rtc.AudioFrame(
                    data=chunk.tobytes(),
                    sample_rate=target_sample_rate,
                    num_channels=1,
                    samples_per_channel=chunk_size
                )
                
                await audio_source.capture_frame(frame)
                num_chunks += 1
                if num_chunks % 50 == 0:
                     logger.info(f"🎵 [STREAM AUDIO - WELCOME] {num_chunks} chunks envoyés...")
                
                await asyncio.sleep(0.01)  # 10ms delay pour chaque frame
            
            logger.info(f"✅ [STREAM AUDIO] Diffusion terminée. Total {num_chunks} chunks envoyés.")
                
    except Exception as e:
        logger.error(f"❌ [STREAM AUDIO] Erreur lors de la diffusion des données audio vers la source: {e}", exc_info=True)

async def test_audio_publication_immediate(ctx):
    """Test de validation de la publication audio"""
    logger.info("🧪 [TEST] Démarrage du test de validation de la publication audio...")
    try:
        local_participant = ctx.room.local_participant
        if local_participant:
            publications = local_participant.track_publications.values()
            audio_tracks = [pub for pub in publications if pub.kind == rtc.TrackKind.KIND_AUDIO]
            
            logger.info(f"✅ [TEST] Trouvé {len(audio_tracks)} piste(s) audio publiée(s) par le participant local.")
            
            if audio_tracks:
                for track_pub in audio_tracks:
                    logger.info(f"  - Track publié: SID={track_pub.sid}, Name='{track_pub.name}', "
                                f"Kind={track_pub.kind}, Muted={track_pub.muted}, Source={track_pub.source}")
                logger.info("✅ [TEST] Au moins une piste audio est publiée.")
                return True
            else:
                logger.warning("⚠️ [TEST] Aucune piste audio trouvée ou publiée par le participant local.")
                return False
        else:
            logger.warning("⚠️ [TEST] Participant local non disponible pour le test de publication.")
            return False
        
    except Exception as e:
        logger.error(f"❌ [TEST] Erreur lors de la validation de la publication audio: {e}", exc_info=True)
        return False

# Point d'entrée principal
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, handlers=[logging.StreamHandler()])

    async def shutdown(loop: asyncio.AbstractEventLoop):
        """Nettoie les tâches avant de fermer la boucle."""
        logger.info("🔌 [SHUTDOWN] Annulation de toutes les tâches en cours...")
        tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
        [task.cancel() for task in tasks]

        logger.info(f"⏳ [SHUTDOWN] Attente de la fin des {len(tasks)} tâches...")
        await asyncio.gather(*tasks, return_exceptions=True)
        
        # CORRECTION: Fermer toutes les sessions HTTP AVANT loop.stop()
        logger.info("🌐 [SHUTDOWN] Fermeture de toutes les sessions HTTP...")
        await close_all_http_sessions()
        
        logger.info("🛑 [SHUTDOWN] Arrêt de la boucle d'événements.")
        loop.stop()

    async def main():
        """Crée et exécute le worker de l'agent."""
        worker_opts = agents.WorkerOptions(
            entrypoint_fnc=create_and_configure_agent,
            ws_url=os.environ.get("LIVEKIT_URL"),
            api_key=os.environ.get("LIVEKIT_API_KEY"),
            api_secret=os.environ.get("LIVEKIT_API_SECRET"),
        )
        worker = agents.Worker(worker_opts)
        logger.info("✅ [MAIN] Worker créé. Démarrage...")
        await worker.run()

    loop = asyncio.get_event_loop()
    try:
        logger.info("🚀 Démarrage de l'agent Eloquence (boucle infinie)...")
        loop.create_task(main())
        loop.run_forever()
    except KeyboardInterrupt:
        logger.info("🚨 [MAIN] Interruption clavier détectée.")
    finally:
        logger.info("🧹 [MAIN] Démarrage de la séquence d'arrêt propre...")
        loop.run_until_complete(shutdown(loop))
        loop.close()
        logger.info("✅ [MAIN] Agent arrêté proprement.")

# C'est le test final.
