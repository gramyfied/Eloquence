"""
Service ElevenLabs Flash v2.5 pour synthèse vocale faible latence.

Notes:
- Utilise ELEVENLABS_API_KEY via variables d'environnement
- Supporte un cache Redis optionnel (REDIS_URL), sinon mémoire locale
- Fournit une API non-streaming immédiate (REST) et une API streaming (WS) en brouillon

Cette implémentation est conçue pour être intégrée ensuite dans LiveKit.
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import time
import io
from dataclasses import dataclass
import sys as _sys  # Fix dataclass processing in dynamic import contexts
from typing import Any, AsyncGenerator, Dict, Optional, Set

try:
    import aiohttp
except Exception:  # pragma: no cover - tests peuvent mocker
    aiohttp = None  # type: ignore

try:
    import websockets
except Exception:  # pragma: no cover - chemin non utilisé en tests
    websockets = None  # type: ignore

try:
    import redis
except Exception:  # pragma: no cover
    redis = None  # type: ignore

try:
    import av  # PyAV for robust audio decoding/resampling
except Exception:  # pragma: no cover
    av = None  # type: ignore


logger = logging.getLogger(__name__)


# Mapping voix neutres SANS accent pour coaching vocal professionnel
VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL: Dict[str, Dict[str, Any]] = {
    # Animateur TV - Voix masculine neutre SANS accent
    "michel_dubois_animateur": {
        "voice_id": "JBFqnCBsd6RMkjVDRZzb",  # George - Voix masculine neutre sans accent
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.75,
            "similarity_boost": 0.85,
            "style": 0.4,
            "use_speaker_boost": True,
        },
    },

    # Journaliste - Voix féminine neutre SANS accent professionnelle  
    "sarah_johnson_journaliste": {
        "voice_id": "EXAVITQu4vr4xnSDxMaL",  # Bella - Voix féminine neutre sans accent
        "model": "eleven_flash_v2_5", 
        "settings": {
            "stability": 0.6,
            "similarity_boost": 0.8,
            "style": 0.5,
            "use_speaker_boost": True,
        },
    },

    # Expert - Voix masculine mesurée SANS accent académique
    "marcus_thompson_expert": {
        "voice_id": "VR6AewLTigWG4xSOukaG",  # Arnold - Voix masculine mesurée sans accent
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.8,
            "similarity_boost": 0.75,
            "style": 0.3,
            "use_speaker_boost": True,
        },
    }
}

# Compatibilité ascendante pour les tests et intégrations existants
VOICE_MAPPING_NEUTRAL_PROFESSIONAL: Dict[str, Dict[str, Any]] = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL

# Système d'émotions vocales ElevenLabs v2.5 Flash
EMOTION_VOICE_MAPPING: Dict[str, Dict[str, float]] = {
    "enthousiasme": {"stability": 0.6, "similarity_boost": 0.9, "style": 0.6},
    "autorité": {"stability": 0.8, "similarity_boost": 0.8, "style": 0.4},
    "bienveillance": {"stability": 0.7, "similarity_boost": 0.85, "style": 0.35},
    "curiosité": {"stability": 0.5, "similarity_boost": 0.8, "style": 0.7},
    "challenge": {"stability": 0.6, "similarity_boost": 0.75, "style": 0.6},
    "analyse": {"stability": 0.75, "similarity_boost": 0.8, "style": 0.3},
    "réflexion": {"stability": 0.8, "similarity_boost": 0.75, "style": 0.25},
    "expertise": {"stability": 0.75, "similarity_boost": 0.8, "style": 0.35},
    "pédagogie": {"stability": 0.7, "similarity_boost": 0.85, "style": 0.4},
    "neutre": {"stability": 0.7, "similarity_boost": 0.8, "style": 0.4}
}

def apply_emotional_preprocessing(text: str, emotion: str, intensity: float) -> str:
    """Applique le préprocessing émotionnel SILENCIEUX pour ElevenLabs v2.5
    
    CORRECTION CRITIQUE : Les émotions sont exprimées UNIQUEMENT via les paramètres TTS,
    JAMAIS via des marqueurs textuels audibles.
    """
    
    if not text or not emotion:
        return text
    
    # CORRECTION CRITIQUE : Pas de marqueurs audibles !
    # Les émotions sont gérées UNIQUEMENT par les paramètres TTS
    
    # Nettoyage du texte pour éliminer tout marqueur existant
    cleaned_text = text
    
    # Suppression de TOUS les marqueurs émotionnels audibles
    emotion_markers = [
        "*avec enthousiasme*", "*avec autorité*", "*avec curiosité*",
        "*avec fermeté*", "*de manière réfléchie*", "*avec bienveillance*",
        "*de manière analytique*", "*avec expertise*", "*de manière pédagogique*",
        "*enthousiasme*", "*autorité*", "*curiosité*", "*fermeté*",
        "*réfléchie*", "*bienveillance*", "*analytique*", "*expertise*",
        "*pédagogique*", "*avec*", "*de manière*"
    ]
    
    for marker in emotion_markers:
        cleaned_text = cleaned_text.replace(marker, "").strip()
    
    # Nettoyage des patterns avec astérisques
    import re
    cleaned_text = re.sub(r'\*[^*]*\*', '', cleaned_text)
    
    # Nettoyage des espaces multiples et normalisation
    cleaned_text = re.sub(r'\s+', ' ', cleaned_text).strip()
    
    # Nettoyage des ponctuations doubles
    cleaned_text = re.sub(r'[.]{2,}', '.', cleaned_text)
    cleaned_text = re.sub(r'[!]{2,}', '!', cleaned_text)
    cleaned_text = re.sub(r'[?]{2,}', '?', cleaned_text)
    
    logger.debug(f"🎭 Préprocessing émotionnel SILENCIEUX: {emotion} ({intensity})")
    logger.debug(f"   Texte original: {text[:50]}...")
    logger.debug(f"   Texte nettoyé: {cleaned_text[:50]}...")
    
    return cleaned_text

def validate_emotion_silence(text: str) -> bool:
    """Valide qu'aucun marqueur émotionnel n'est audible dans le texte"""
    
    # Patterns à détecter
    emotion_patterns = [
        r'\*[^*]*\*',  # Tout texte entre astérisques
        r'avec\s+(enthousiasme|autorité|curiosité|fermeté|bienveillance)',
        r'de\s+manière\s+(réfléchie|analytique|pédagogique)',
        r'\b(enthousiasme|autorité|curiosité|fermeté|bienveillance|réflexion)\b'
    ]
    
    import re
    for pattern in emotion_patterns:
        if re.search(pattern, text, re.IGNORECASE):
            logger.warning(f"⚠️ Marqueur émotionnel détecté: {pattern} dans '{text[:50]}...'")
            return False
    
    return True

def clean_text_for_tts(text: str) -> str:
    """Nettoie complètement un texte pour TTS sans marqueurs émotionnels"""
    
    # Étape 1: Suppression marqueurs émotionnels
    cleaned = apply_emotional_preprocessing(text, "neutre", 0.5)
    
    # Étape 2: Validation
    if not validate_emotion_silence(cleaned):
        logger.error(f"❌ Texte contient encore des marqueurs: {cleaned}")
        # Nettoyage agressif en dernier recours
        import re
        cleaned = re.sub(r'\*.*?\*', '', cleaned)
        cleaned = re.sub(r'\b(avec|de manière)\s+\w+', '', cleaned)
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    
    return cleaned

def get_emotional_voice_settings(agent_id: str, emotion: str = "neutre") -> Dict[str, Any]:
    """Récupère les paramètres vocaux avec émotion pour un agent"""
    
    # LOG DIAGNOSTIC CRITIQUE
    logger.info(f"🔍 RECHERCHE VOIX: agent_id='{agent_id}', emotion='{emotion}'")
    
    original_agent_id = agent_id
    if agent_id not in VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL:
        logger.warning(f"❌ Agent {agent_id} non trouvé dans mapping")
        logger.info(f"🔧 Agents disponibles: {list(VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL.keys())}")
        agent_id = "michel_dubois_animateur"
        logger.info(f"🔧 Fallback vers: {agent_id}")
    
    # Configuration de base de l'agent
    base_config = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL[agent_id]
    voice_id = base_config["voice_id"]
    
    # LOG MAPPING TROUVÉ
    logger.info(f"✅ MAPPING TROUVÉ: {original_agent_id} → {agent_id} → voix {voice_id}")
    
    # Configuration émotionnelle
    emotion_config = EMOTION_VOICE_MAPPING.get(emotion, EMOTION_VOICE_MAPPING["neutre"])
    
    # Fusion des paramètres
    final_settings = {**base_config["settings"], **emotion_config}
    
    result = {
        "voice_id": base_config["voice_id"],
        "model": base_config["model"],
        "settings": final_settings
    }
    
    # LOG FINAL
    logger.info(f"🎭 CONFIG FINALE: voix={result['voice_id']}, model={result['model']}")
    
    return result


class ElevenLabsFlashConfig:  # pragma: no cover - utilitaire, non utilisé par les tests
    def __init__(
        self,
        api_key: str,
        voice_id: str,
        model_id: str = "eleven_flash_v2_5",
        output_format: str = "pcm_16000",
        stability: float = 0.5,
        similarity_boost: float = 0.75,
        style: float = 0.5,
        use_speaker_boost: bool = True,
    ) -> None:
        self.api_key = api_key
        self.voice_id = voice_id
        self.model_id = model_id
        self.output_format = output_format
        self.stability = stability
        self.similarity_boost = similarity_boost
        self.style = style
        self.use_speaker_boost = use_speaker_boost


class _Cache:
    def __init__(self) -> None:
        self.mem: Dict[str, bytes] = {}
        self.redis = None
        url = os.getenv("REDIS_URL")
        if url and redis is not None:
            try:
                self.redis = redis.Redis.from_url(url)
                self.redis.ping()
                logger.info("✅ Cache Redis actif pour ElevenLabs TTS")
            except Exception as e:  # pragma: no cover - dépendant env
                logger.warning(f"⚠️ Redis indisponible ({e}), fallback mémoire")

    def get(self, key: str) -> Optional[bytes]:
        if key in self.mem:
            return self.mem[key]
        if self.redis is not None:
            try:
                val = self.redis.get(f"elevenlabs_flash_audio:{key}")
                if val:
                    self.mem[key] = val
                    return val
            except Exception:
                return None
        return None

    def put(self, key: str, value: bytes, ttl: int = 3600) -> None:
        self.mem[key] = value
        if self.redis is not None:
            try:
                self.redis.setex(f"elevenlabs_flash_audio:{key}", ttl, value)
            except Exception:
                pass


class ElevenLabsFlashTTSService:
    def __init__(self, api_key: Optional[str] = None) -> None:
        self.api_key = api_key or os.getenv("ELEVENLABS_API_KEY", "")
        self.base_url = "https://api.elevenlabs.io/v1"
        self.ws_base = "wss://api.elevenlabs.io/v1"
        self.cache = _Cache()
        # Cache de résolution nom → voice_id
        self._voice_name_to_id: Dict[str, str] = {}
        self._known_voice_ids: Set[str] = set()
        self._voices_last_load: float = 0.0
        try:
            self._voices_ttl: float = float(os.getenv("ELEVENLABS_VOICES_TTL", "1800"))  # 30 min
        except Exception:
            self._voices_ttl = 1800.0

    async def synthesize_with_emotion(self, text: str, agent_id: str, 
                                     emotion: str = "neutre", intensity: float = 0.5) -> bytes:
        """Synthèse vocale avec émotion ElevenLabs v2.5 - ÉMOTIONS SILENCIEUSES"""
        
        # LOG DIAGNOSTIC AJOUTÉ
        logger.info(f"🎵 TTS DÉBUT: {agent_id} - {emotion} - {text[:30]}...")
        
        try:
            # CORRECTION CRITIQUE : Préprocessing émotionnel SILENCIEUX
            processed_text = clean_text_for_tts(text)
            
            # Validation finale obligatoire
            if not validate_emotion_silence(processed_text):
                logger.error(f"❌ ÉCHEC validation silence émotionnel: {processed_text}")
                # Fallback : texte brut sans traitement
                processed_text = text.replace("*", "").strip()
            
            # Configuration voix + émotion (paramètres TTS uniquement)
            voice_config = get_emotional_voice_settings(agent_id, emotion)
            
            logger.info(f"🎭 Synthèse émotionnelle SILENCIEUSE: {agent_id} - {emotion} ({intensity})")
            logger.info(f"   Texte final: {processed_text[:50]}...")
            
            # Appel ElevenLabs avec paramètres émotionnels UNIQUEMENT
            return await self._call_elevenlabs_api(
                processed_text,
                voice_config["voice_id"],
                voice_config["settings"]
            )
            
        except Exception as e:
            logger.error(f"❌ Erreur synthèse émotionnelle {agent_id}: {e}")
            # Fallback sans émotion
            return await self.synthesize(text, agent_id)

    async def synthesize(self, text: str, agent_id: str) -> bytes:
        """Méthode de synthèse standard (compatibilité)"""
        return await self.synthesize_with_emotion(text, agent_id, "neutre", 0.5)

    async def _call_elevenlabs_api(self, text: str, voice_id: str, settings: Dict[str, Any]) -> bytes:
        """Appel API ElevenLabs avec paramètres personnalisés"""
        
        # LOGS AJOUTÉS POUR DIAGNOSTIC
        logger.info(f"🌐 APPEL TTS: voix {voice_id} - {text[:30]}...")
        
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
        
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": self.api_key
        }
        
        data = {
            "text": text,
            "model_id": "eleven_flash_v2_5",
            "voice_settings": {
                "stability": settings.get("stability", 0.7),
                "similarity_boost": settings.get("similarity_boost", 0.8),
                "style": settings.get("style", 0.4),
                "use_speaker_boost": settings.get("use_speaker_boost", True)
            }
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=data, headers=headers) as response:
                if response.status == 200:
                    return await response.read()
                else:
                    error_text = await response.text()
                    raise Exception(f"ElevenLabs API error {response.status}: {error_text}")

    async def synthesize_speech_flash_v25(
        self,
        *,
        text: str,
        agent_id: str,
        emotional_context: Optional[Dict[str, Any]] = None,
    ) -> Optional[bytes]:
        """Synthèse REST optimisée. Retourne des bytes audio.

        Remarque: En tests, cette méthode peut être mockée pour éviter l'appel réseau.
        """
        if not self.api_key:
            logger.warning("⚠️ ELEVENLABS_API_KEY manquante")
            return None

        voice_cfg = self._get_voice_config(agent_id, emotional_context)
        cache_key = self._make_cache_key(text, voice_cfg)
        cached = self.cache.get(cache_key)
        if cached:
            logger.debug("ElevenLabs cache hit")
            return cached

        if aiohttp is None:  # pragma: no cover
            logger.error("aiohttp indisponible")
            return None

        timeout = aiohttp.ClientTimeout(total=5)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            # Résoudre un éventuel nom de voix en voice_id réel
            resolved_voice_id = await self._resolve_voice_id(session, voice_cfg["voice_id"])  # type: ignore
            if not resolved_voice_id:
                # Fallback ultime vers une voix connue pour éviter les erreurs fatales
                fallback_id = "pNInz6obpgDQGcFmaJgB"
                logger.error(
                    f"❌ Voice '{voice_cfg['voice_id']}' introuvable dans ElevenLabs. Fallback -> {fallback_id}"
                )
                resolved_voice_id = fallback_id

            url = f"{self.base_url}/text-to-speech/{resolved_voice_id}"
            payload = {
                "text": text,
                "model_id": voice_cfg["model_id"],
                "voice_settings": voice_cfg["settings"],
                "output_format": voice_cfg["output_format"],
            }
            headers = {"xi-api-key": self.api_key, "Content-Type": "application/json", "Accept": "application/octet-stream"}

            t0 = time.time()
            try:
                # Point d'extension test: permet de monkeypatcher cette logique réseau
                _network_coro = self._perform_post(session, url, headers, payload)
                async with await _network_coro as resp:
                    if resp.status == 200:
                        audio = await resp.read()
                        # Detect content-type; decode non-PCM (e.g., MP3/WAV) to PCM16 16k mono
                        ct = (resp.headers.get('content-type') or resp.headers.get('Content-Type') or '').lower()
                        try:
                            if av is not None:
                                is_mp3 = ('mpeg' in ct or 'mp3' in ct or audio[:3] == b'ID3' or audio[:2] == b'\xff\xfb')
                                is_wav = ('wav' in ct or audio[:4] == b'RIFF')
                                if is_mp3 or is_wav:
                                    with av.open(io.BytesIO(audio), 'r') as container:
                                        # Décoder et resampler en PCM16 16 kHz mono (laisser LiveKit upsampler)
                                        resampler = av.audio.resampler.AudioResampler(format='s16', layout='mono', rate=16000)
                                        pcm_chunks: list[bytes] = []
                                        for frame in container.decode(audio=0):
                                            res = resampler.resample(frame)
                                            frames = res if isinstance(res, list) else [res]
                                            for f in frames:
                                                try:
                                                    # Convertir l'audio mono s16 en bytes de manière robuste
                                                    arr = f.to_ndarray()
                                                    pcm_chunks.append(arr.tobytes())
                                                except Exception:
                                                    # Fallback: utiliser le buffer brut du premier plane si dispo
                                                    try:
                                                        pcm_chunks.append(bytes(f.planes[0]))
                                                    except Exception:
                                                        pass
                                        audio = b''.join(pcm_chunks)
                        except Exception as dec_err:
                            logger.warning(f"⚠️ Décodage audio non-PCM échoué ({ct}): {dec_err}")
                        self.cache.put(cache_key, audio)
                        latency = time.time() - t0
                        logger.info(f"🎙️ ElevenLabs Flash v2.5: {latency:.3f}s, bytes={len(audio)}")
                        return audio
                    else:
                        err = await resp.text()
                        logger.error(f"❌ ElevenLabs Flash v2.5 {resp.status}: {err}")
                        return None
            except Exception as e:  # pragma: no cover - réseau
                logger.error(f"❌ Exception ElevenLabs: {e}")
                return None

    async def _perform_post(self, session, url: str, headers: Dict[str, Any], payload: Dict[str, Any]):
        """Séparé pour faciliter les tests via monkeypatch."""
        return session.post(url, headers=headers, json=payload)

    async def stream_speech_websocket_flash(
        self,
        *,
        text_stream: AsyncGenerator[str, None],
        agent_id: str,
        emotional_context: Optional[Dict[str, Any]] = None,
    ) -> AsyncGenerator[bytes, None]:  # pragma: no cover - non testé ici
        """Brouillon streaming WS (à finaliser lors de l'intégration LiveKit)."""
        if websockets is None:
            logger.error("websockets indisponible")
            return
        if not self.api_key:
            logger.warning("ELEVENLABS_API_KEY manquante")
            return

        voice_cfg = self._get_voice_config(agent_id, emotional_context)
        # Résoudre le voice_id si un nom a été fourni
        resolved_id = voice_cfg.get('voice_id')
        if aiohttp is not None:
            try:
                timeout = aiohttp.ClientTimeout(total=5)
                async with aiohttp.ClientSession(timeout=timeout) as session:
                    rid = await self._resolve_voice_id(session, str(resolved_id))
                    if rid:
                        resolved_id = rid
            except Exception:
                pass
        ws_url = (
            f"{self.ws_base}/text-to-speech/{resolved_id}/stream-input"
        )
        headers = {"xi-api-key": self.api_key}
        qs = {
            "model_id": voice_cfg["model_id"],
            "output_format": voice_cfg["output_format"],
            "auto_mode": "true",
            "sync_alignment": "true",
        }
        qs_str = "&".join(f"{k}={v}" for k, v in qs.items())
        uri = f"{ws_url}?{qs_str}"

        async with websockets.connect(uri, extra_headers=headers) as websocket:
            init_msg = {
                "text": " ",
                "voice_settings": voice_cfg["settings"],
                "generation_config": {"chunk_length_schedule": [50, 80, 120, 150]},
            }
            await websocket.send(json.dumps(init_msg))

            async def _send():
                async for chunk in text_stream:
                    if chunk.strip():
                        await websocket.send(json.dumps({"text": chunk, "try_trigger_generation": True}))
                await websocket.send(json.dumps({"text": ""}))

            async def _recv():
                async for msg in websocket:
                    data = json.loads(msg)
                    if "audio" in data:
                        import base64

                        yield base64.b64decode(data["audio"])  # type: ignore

            await asyncio.gather(_send(), _recv())

    def _get_voice_config(
        self, agent_id: str, emotional_context: Optional[Dict[str, Any]]
    ) -> Dict[str, Any]:
        base = VOICE_MAPPING_NEUTRAL_PROFESSIONAL.get(
            agent_id,
            {
                "voice_id": "pNInz6obpgDQGcFmaJgB",
                "model": "eleven_flash_v2_5",
                "settings": {
                    "stability": 0.5,
                    "similarity_boost": 0.75,
                    "style": 0.5,
                    "use_speaker_boost": True,
                },
            },
        )

        settings = dict(base["settings"])  # copy
        if emotional_context:
            emotion = str(emotional_context.get("emotion", "neutral"))
            intensity = float(emotional_context.get("intensity", 0.5))
            intensity = max(0.0, min(1.0, intensity))

            if emotion == "excited":
                settings["stability"] *= 1 - (0.2 * intensity)
                settings["style"] *= 1 + (0.3 * intensity)
            elif emotion == "calm":
                settings["stability"] *= 1 + (0.15 * intensity)
                settings["style"] *= 1 - (0.2 * intensity)
            elif emotion == "challenging":
                settings["similarity_boost"] *= 1 + (0.15 * intensity)
                settings["style"] *= 1 + (0.4 * intensity)
            elif emotion == "laughing":
                settings["stability"] *= 0.3
                settings["style"] *= 1.5
            elif emotion == "sighing":
                settings["stability"] *= 1.2
                settings["style"] *= 0.7

        return {
            "voice_id": base["voice_id"],
            "model_id": base["model"],
            "output_format": "pcm_16000",
            "settings": settings,
        }

    def _make_cache_key(self, text: str, voice_cfg: Dict[str, Any]) -> str:
        import hashlib

        payload = {
            "text": text,
            "voice_id": voice_cfg["voice_id"],
            "model_id": voice_cfg["model_id"],
            "settings": voice_cfg["settings"],
            # versionner le format pour invalider les caches anciens
            "format_version": "pcm16le_16000_mono_v2",
        }
        raw = json.dumps(payload, sort_keys=True).encode()
        return hashlib.md5(raw).hexdigest()

    async def _resolve_voice_id(self, session, label: str) -> Optional[str]:
        """Résout un label de voix (nom ou id) vers un voice_id valide.

        - Si `label` est déjà un voice_id connu, le retourne tel quel
        - Sinon, charge (avec TTL) l'annuaire des voix et tente une résolution par nom exact (sensible à la casse)
        """
        if not label:
            return None
        # Déjà connu comme id
        if label in self._known_voice_ids:
            return label
        # Déjà résolu comme nom
        if label in self._voice_name_to_id:
            return self._voice_name_to_id[label]

        now = time.time()
        need_reload = (now - self._voices_last_load) > self._voices_ttl
        if need_reload or not self._voice_name_to_id:
            try:
                headers = {"xi-api-key": self.api_key, "Accept": "application/json"}
                url = f"{self.base_url}/voices"
                async with session.get(url, headers=headers) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        voices = data.get("voices", [])
                        self._voice_name_to_id.clear()
                        self._known_voice_ids.clear()
                        for v in voices:
                            vid = v.get("voice_id") or v.get("voiceId")
                            vname = v.get("name") or v.get("voice_name")
                            if vid:
                                self._known_voice_ids.add(vid)
                            if vname and vid:
                                self._voice_name_to_id[vname] = vid
                        self._voices_last_load = now
                        logger.info(
                            f"📚 Annuaire ElevenLabs chargé: {len(self._voice_name_to_id)} voix"
                        )
                    else:
                        txt = await resp.text()
                        logger.warning(
                            f"⚠️ Impossible de charger /voices ({resp.status}): {txt}"
                        )
            except Exception as e:  # pragma: no cover
                logger.warning(f"⚠️ Erreur chargement annuaire ElevenLabs: {e}")

        # Après (ré)chargement, re-tenter
        if label in self._known_voice_ids:
            return label
        if label in self._voice_name_to_id:
            resolved = self._voice_name_to_id[label]
            logger.info(f"🔗 Résolution nom→id ElevenLabs: '{label}' → '{resolved}'")
            return resolved
        # Essai insensible à la casse
        for name, vid in self._voice_name_to_id.items():
            if name.lower() == label.lower():
                logger.info(f"🔗 Résolution nom (case-insensitive)→id: '{label}' → '{vid}'")
                return vid
        return None


# Instance globale optionnelle (sans clé si non configurée)
elevenlabs_flash_service = ElevenLabsFlashTTSService()


