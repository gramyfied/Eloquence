import time
from dataclasses import dataclass
from typing import Any, Dict, Optional


@dataclass
class CachedItem:
    value: Any
    metadata: Dict[str, Any]
    stored_at: float


@dataclass
class CacheStats:
    hits: int = 0
    misses: int = 0

    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return (self.hits / total) if total else 0.0


class ExerciseCacheSystem:
    """Cache simple pour exercices/variations/scénarios.

    - LRU simplifié (par écrasement) et TTL optionnel
    - Statistiques de hit/miss
    """

    def __init__(self, default_ttl_seconds: Optional[int] = 600) -> None:
        self._store: Dict[str, CachedItem] = {}
        self._ttl = default_ttl_seconds
        self._stats = CacheStats()

    def _is_valid(self, item: CachedItem) -> bool:
        if self._ttl is None:
            return True
        return (time.time() - item.stored_at) <= self._ttl

    def get(self, key: str) -> Optional[Any]:
        item = self._store.get(key)
        if item and self._is_valid(item):
            self._stats.hits += 1
            return item.value
        if item and not self._is_valid(item):
            # Expiration
            self._store.pop(key, None)
        self._stats.misses += 1
        return None

    def put(self, key: str, value: Any, metadata: Optional[Dict[str, Any]] = None) -> None:
        self._store[key] = CachedItem(value=value, metadata=metadata or {}, stored_at=time.time())

    def get_cache_statistics(self) -> CacheStats:
        return self._stats


