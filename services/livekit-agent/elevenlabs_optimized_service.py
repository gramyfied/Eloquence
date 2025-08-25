"""
Service ElevenLabs optimisé pour latence minimale et continuité audio.

Objectifs:
- Latence cible < 75ms (objectif 50ms)
- Fallbacks robustes (OpenAI TTS)
- Métriques temps réel
"""
from __future__ import annotations

import asyncio
import aiohttp
import logging
import os
import time
from typing import Optional, Dict, Any
from collections import deque

try:
    import av  # type: ignore
except Exception:  # pragma: no cover
    av = None  # type: ignore


logger = logging.getLogger(__name__)


class ElevenLabsOptimizedService:
    """Service ElevenLabs optimisé pour éliminer coupures et latence."""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.elevenlabs.io/v1"

        # Pool et session créés lors de initialize() (éviter création hors boucle event)
        self._connector: Optional[aiohttp.TCPConnector] = None
        self._session: Optional[aiohttp.ClientSession] = None

        # Cache pré-chauffé simple (clé md5)
        self._preload_cache: Dict[str, bytes] = {}
        self._cache_hits = 0
        self._cache_misses = 0

        # Métriques performance
        self._latency_history = deque(maxlen=100)
        self._success_history = deque(maxlen=100)

    async def initialize(self):
        if self._session is None:
            if self._connector is None:
                self._connector = aiohttp.TCPConnector(
                    limit=20,
                    limit_per_host=10,
                    keepalive_timeout=60,
                    enable_cleanup_closed=True,
                    use_dns_cache=True,
                    ttl_dns_cache=300,
                )
            timeout = aiohttp.ClientTimeout(total=5, connect=1.5, sock_read=3)
            self._session = aiohttp.ClientSession(
                connector=self._connector,
                timeout=timeout,
                headers={
                    "xi-api-key": self.api_key,
                    "Content-Type": "application/json",
                    "Accept": "application/octet-stream",
                    "User-Agent": "Eloquence-Optimized/1.0",
                },
            )
            logger.info("🚀 Service ElevenLabs optimisé initialisé")

    async def synthesize_with_zero_latency(
        self,
        *,
        text: str,
        agent_id: str,
        emotional_context: Optional[Dict[str, Any]] = None,
    ) -> Optional[bytes]:
        """Synthèse optimisée avec cache et retry intelligent."""
        start = time.time()
        try:
            cache_key = self._generate_cache_key(text, agent_id, emotional_context)
            if cache_key in self._preload_cache:
                self._cache_hits += 1
                audio = self._preload_cache[cache_key]
                latency = time.time() - start
                self._latency_history.append(latency)
                logger.debug(f"🚀 CACHE HIT: {latency*1000:.1f}ms")
                return audio
            self._cache_misses += 1

            # Génération avec retry + fallback
            audio_data = await self._generate_with_retry(text, agent_id, emotional_context)
            if audio_data:
                self._preload_cache[cache_key] = audio_data

            latency = time.time() - start
            self._latency_history.append(latency)
            self._success_history.append(1.0 if audio_data else 0.0)

            if latency > 0.075:
                logger.warning(f"⚠️ LATENCE ÉLEVÉE: {latency*1000:.1f}ms > 75ms")
            else:
                logger.info(f"✅ Synthèse optimisée: {latency*1000:.1f}ms, bytes={len(audio_data) if audio_data else 0}")
            return audio_data
        except Exception as e:  # pragma: no cover - erreurs réseau
            logger.error(f"❌ Erreur synthèse optimisée: {e}")
            self._success_history.append(0.0)
            return None

    async def _generate_with_retry(
        self, text: str, agent_id: str, emotional_context: Optional[Dict[str, Any]]
    ) -> Optional[bytes]:
        voice_config = self._get_french_voice_config(agent_id, emotional_context)
        for attempt in range(4):
            try:
                audio = await self._call_elevenlabs_api(text, voice_config, timeout_multiplier=(1 + attempt * 0.5))
                if audio:
                    if attempt > 0:
                        logger.info(f"✅ Succès tentative {attempt + 1}")
                    return audio
            except asyncio.TimeoutError:
                logger.warning(f"⏱️ Timeout tentative {attempt + 1}")
            except Exception as e:
                logger.warning(f"⚠️ Erreur tentative {attempt + 1}: {e}")
            if attempt < 3:
                await asyncio.sleep(0.1 * (2 ** attempt))

        logger.warning("🔄 Fallback OpenAI TTS")
        return await self._openai_fallback(text)

    async def _call_elevenlabs_api(
        self, text: str, voice_config: Dict[str, Any], timeout_multiplier: float = 1.0
    ) -> Optional[bytes]:
        if self._session is None:
            await self.initialize()

        assert self._session is not None
        url = f"{self.base_url}/text-to-speech/{voice_config['voice_id']}"
        payload = {
            "text": text,
            "model_id": voice_config["model_id"],
            "voice_settings": voice_config["settings"],
            "output_format": voice_config["output_format"],
        }
        timeout = aiohttp.ClientTimeout(
            total=3 * timeout_multiplier,
            connect=1 * timeout_multiplier,
            sock_read=2 * timeout_multiplier,
        )
        async with self._session.post(url, json=payload, timeout=timeout) as resp:
            if resp.status != 200:
                try:
                    err = await resp.text()
                except Exception:
                    err = str(resp.status)
                logger.error(f"❌ ElevenLabs API {resp.status}: {err}")
                return None
            raw = await resp.read()
            ct = (resp.headers.get('content-type') or '').lower()
            return await self._process_audio_format(raw, ct)

    async def _process_audio_format(self, audio_data: bytes, content_type: str) -> bytes:
        # Si déjà PCM
        if 'pcm' in content_type:
            return audio_data
        # MP3/WAV → PCM16 16k mono
        if av is None:
            return audio_data
        try:
            import io
            with av.open(io.BytesIO(audio_data), 'r') as container:
                resampler = av.audio.resampler.AudioResampler(format='s16', layout='mono', rate=16000)
                pcm_chunks: list[bytes] = []
                for frame in container.decode(audio=0):
                    res = resampler.resample(frame)
                    frames = res if isinstance(res, list) else [res]
                    for f in frames:
                        try:
                            arr = f.to_ndarray()
                            pcm_chunks.append(arr.tobytes())
                        except Exception:
                            try:
                                pcm_chunks.append(bytes(f.planes[0]))
                            except Exception:
                                pass
                return b''.join(pcm_chunks) or audio_data
        except Exception as e:
            logger.warning(f"⚠️ Décodage audio échoué: {e}")
            return audio_data

    async def _openai_fallback(self, text: str) -> Optional[bytes]:
        try:
            from openai import AsyncOpenAI  # type: ignore
            client = AsyncOpenAI()
            # API tts (nouvelle lib) — utiliser audio.speech
            resp = await client.audio.speech.create(
                model="tts-1-hd",
                voice="alloy",
                input=text,
                response_format="pcm",
            )
            return getattr(resp, 'content', None)
        except Exception as e:  # pragma: no cover
            logger.error(f"❌ Fallback OpenAI échoué: {e}")
            return None

    def _get_french_voice_config(self, agent_id: str, emotional_context: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        # Importer le mapping français depuis le service principal
        try:
            from elevenlabs_flash_tts_service import VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL as MAP
        except Exception:  # pragma: no cover
            MAP = {}
        
        # Récupérer la configuration de voix pour l'agent
        base = MAP.get(agent_id, {})
        
        return {
            "voice_id": base.get("voice_id", "Daniel"),  # Voix française par défaut
            "model_id": base.get("model", "eleven_flash_v2_5"),
            "output_format": "pcm_16000",
            "settings": base.get("settings", {
                "stability": 0.75,
                "similarity_boost": 0.85,
                "style": 0.4,
                "use_speaker_boost": True
            })
        }

    def _generate_cache_key(self, text: str, agent_id: str, emotional_context: Optional[Dict[str, Any]]) -> str:
        import hashlib, json
        data = {
            "text": text,
            "agent_id": agent_id,
            "emotional_context": emotional_context or {},
            "version": "french_v1",
        }
        raw = json.dumps(data, sort_keys=True, ensure_ascii=False).encode("utf-8")
        return hashlib.md5(raw).hexdigest()

    def get_performance_metrics(self) -> Dict[str, Any]:
        if not self._latency_history:
            return {"status": "no_data"}
        avg_latency = sum(self._latency_history) / len(self._latency_history)
        success_rate = sum(self._success_history) / len(self._success_history) if self._success_history else 0.0
        total = len(self._latency_history)
        cache_hit_rate = self._cache_hits / max(1, (self._cache_hits + self._cache_misses))
        return {
            "avg_latency_ms": avg_latency * 1000,
            "success_rate": success_rate,
            "cache_hit_rate": cache_hit_rate,
            "total_requests": total,
            "cache_size": len(self._preload_cache),
        }

    async def cleanup(self):
        try:
            if self._session:
                await self._session.close()
                self._session = None
            if self._connector:
                self._connector.close()
                self._connector = None
        except Exception:
            pass


# Instance globale
elevenlabs_optimized_service = ElevenLabsOptimizedService(
    api_key=os.getenv("ELEVENLABS_API_KEY", "")
)


