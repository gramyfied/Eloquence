"""Instrumentation Prometheus optionnelle (no-op si non installée)."""
from __future__ import annotations

import time
from typing import Optional

try:
    from prometheus_client import Counter, Histogram  # type: ignore
except Exception:  # pragma: no cover - prometheus optionnel
    Counter = None  # type: ignore
    Histogram = None  # type: ignore


if Counter and Histogram:
    try:
        EX_VARIATION_COUNT = Counter("exercise_variations_total", "Nombre de variations générées", ["type"])  # type: ignore
    except Exception:
        EX_VARIATION_COUNT = None  # type: ignore
    try:
        EX_VARIATION_LATENCY = Histogram("exercise_variation_latency_seconds", "Latence variations", ["type"])  # type: ignore
    except Exception:
        EX_VARIATION_LATENCY = None  # type: ignore
    try:
        EX_CACHE_HITS = Counter("exercise_cache_hits_total", "Hits cache", ["level"])  # type: ignore
    except Exception:
        EX_CACHE_HITS = None  # type: ignore
    try:
        EX_CACHE_MISSES = Counter("exercise_cache_misses_total", "Misses cache", ["level"])  # type: ignore
    except Exception:
        EX_CACHE_MISSES = None  # type: ignore
else:
    EX_VARIATION_COUNT = None
    EX_VARIATION_LATENCY = None
    EX_CACHE_HITS = None
    EX_CACHE_MISSES = None


class _Timer:
    def __init__(self) -> None:
        self.start = time.perf_counter()
    def observe(self, hist) -> None:
        if hist is None:
            return
        elapsed = time.perf_counter() - self.start
        hist.observe(elapsed)


def start_timer() -> _Timer:
    return _Timer()


def inc_variation(type_name: str) -> None:
    if EX_VARIATION_COUNT is not None:
        EX_VARIATION_COUNT.labels(type_name).inc()


def record_cache_hit(level: str) -> None:
    if EX_CACHE_HITS is not None:
        EX_CACHE_HITS.labels(level).inc()


def record_cache_miss(level: str) -> None:
    if EX_CACHE_MISSES is not None:
        EX_CACHE_MISSES.labels(level).inc()


def get_histogram_for(type_name: str):  # returns a labeled histogram or None
    if EX_VARIATION_LATENCY is None:
        return None
    return EX_VARIATION_LATENCY.labels(type_name)


