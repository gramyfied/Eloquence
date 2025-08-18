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
from dataclasses import dataclass
import sys as _sys  # Fix dataclass processing in dynamic import contexts
from typing import Any, AsyncGenerator, Dict, Optional

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


logger = logging.getLogger(__name__)


# Mapping voix neutres / professionnelles
VOICE_MAPPING_NEUTRAL_PROFESSIONAL: Dict[str, Dict[str, Any]] = {
    "michel_dubois_animateur": {
        "voice_id": "pNInz6obpgDQGcFmaJgB",  # Adam
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.7,
            "similarity_boost": 0.8,
            "style": 0.4,
            "use_speaker_boost": True,
        },
    },
    "sarah_johnson_journaliste": {
        "voice_id": "21m00Tcm4TlvDq8ikWAM",  # Rachel
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.5,
            "similarity_boost": 0.85,
            "style": 0.6,
            "use_speaker_boost": True,
        },
    },
    "marcus_thompson_expert": {
        "voice_id": "29vD33N1CtxCmqQRPOHJ",  # Drew
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.8,
            "similarity_boost": 0.75,
            "style": 0.2,
            "use_speaker_boost": True,
        },
    },
    "emma_wilson_coach": {
        "voice_id": "MF3mGyEYCl7XYWbV9V6O",  # Elli
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.6,
            "similarity_boost": 0.75,
            "style": 0.3,
            "use_speaker_boost": True,
        },
    },
    "david_chen_challenger": {
        "voice_id": "TxGEqnHWrfWFTfGW9XjX",  # Josh
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.4,
            "similarity_boost": 0.9,
            "style": 0.7,
            "use_speaker_boost": True,
        },
    },
    "sophie_martin_diplomate": {
        "voice_id": "AZnzlk1XvdvUeBnXmlld",  # Domi
        "model": "eleven_flash_v2_5",
        "settings": {
            "stability": 0.7,
            "similarity_boost": 0.7,
            "style": 0.2,
            "use_speaker_boost": True,
        },
    },
}


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

        url = f"{self.base_url}/text-to-speech/{voice_cfg['voice_id']}"
        payload = {
            "text": text,
            "model_id": voice_cfg["model_id"],
            "voice_settings": voice_cfg["settings"],
            "output_format": voice_cfg["output_format"],
        }
        headers = {"xi-api-key": self.api_key, "Content-Type": "application/json"}

        t0 = time.time()
        try:
            timeout = aiohttp.ClientTimeout(total=5)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                # Point d'extension test: permet de monkeypatcher cette logique réseau
                _network_coro = self._perform_post(session, url, headers, payload)
                async with await _network_coro as resp:
                    if resp.status == 200:
                        audio = await resp.read()
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
        ws_url = (
            f"{self.ws_base}/text-to-speech/{voice_cfg['voice_id']}/stream-input"
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
        }
        raw = json.dumps(payload, sort_keys=True).encode()
        return hashlib.md5(raw).hexdigest()


# Instance globale optionnelle (sans clé si non configurée)
elevenlabs_flash_service = ElevenLabsFlashTTSService()


