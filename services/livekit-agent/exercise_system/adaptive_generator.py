import asyncio
import json
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple
import logging


# Imports locaux par chargement dynamique pour compatibilité du dossier avec tiret
import importlib.util
from pathlib import Path

_BASE_DIR = Path(__file__).resolve().parent

_SCEN_PATH = _BASE_DIR / "scenario_manager.py"
_SCEN_SPEC = importlib.util.spec_from_file_location("_scen_mod", str(_SCEN_PATH))
_SCEN = importlib.util.module_from_spec(_SCEN_SPEC)  # type: ignore[arg-type]
assert _SCEN_SPEC and _SCEN_SPEC.loader
_SCEN_SPEC.loader.exec_module(_SCEN)

_VAR_PATH = _BASE_DIR / "variation_engine.py"
_VAR_SPEC = importlib.util.spec_from_file_location("_var_mod", str(_VAR_PATH))
_VAR = importlib.util.module_from_spec(_VAR_SPEC)  # type: ignore[arg-type]
assert _VAR_SPEC and _VAR_SPEC.loader
_VAR_SPEC.loader.exec_module(_VAR)


@dataclass
class AdaptiveScenarioPlan:
    scenario_id: str
    title: str
    description: str
    agents: List[Dict[str, Any]]
    dynamic_events: List[Dict[str, Any]]
    adaptation_triggers: List[Dict[str, Any]]
    estimated_difficulty: float
    uniqueness_score: float
    latency_ms: float


class DualCache:
    """Cache intelligent combinant mémoire + Redis (optionnel).

    - Si un client Redis est fourni, les écritures sont répliquées dans Redis.
    - Les lectures consultent d'abord la mémoire locale (latence minimale), puis Redis en fallback.
    - TTL géré côté Redis uniquement.
    """

    def __init__(self, redis_client: Optional[Any] = None, namespace: str = "ex_scen", default_ttl_seconds: int = 600) -> None:
        self._mem: Dict[str, Any] = {}
        self.redis = redis_client
        self.ns = namespace
        self.ttl = default_ttl_seconds

    def _k(self, key: str) -> str:
        return f"{self.ns}:{key}"

    def get(self, key: str) -> Optional[Any]:
        if key in self._mem:
            return self._mem[key]
        if self.redis is None:
            return None
        try:
            v = self.redis.get(self._k(key))
            if v is None:
                return None
            try:
                obj = json.loads(v)
            except Exception:
                obj = v
            # Hydrater mémoire
            self._mem[key] = obj
            return obj
        except Exception:
            return None

    def put(self, key: str, value: Any) -> None:
        self._mem[key] = value
        if self.redis is None:
            return
        try:
            payload = json.dumps(value, default=str)
        except Exception:
            payload = str(value)
        try:
            self.redis.setex(self._k(key), self.ttl, payload)
        except Exception:
            pass

    def lpush_trim(self, list_key: str, value: Any, keep_last: int = 10) -> None:
        if self.redis is None:
            # Réplique en mémoire: liste simple
            arr = self._mem.get(list_key) or []
            arr.insert(0, value)
            self._mem[list_key] = arr[:keep_last]
            return
        try:
            payload = json.dumps(value, default=str)
        except Exception:
            payload = str(value)
        try:
            self.redis.lpush(self._k(list_key), payload)
            self.redis.ltrim(self._k(list_key), 0, keep_last - 1)
        except Exception:
            pass

    def lrange(self, list_key: str, start: int, end: int) -> List[Any]:
        if self.redis is None:
            arr = self._mem.get(list_key) or []
            return arr[start : end + 1 if end >= 0 else None]
        try:
            raw = self.redis.lrange(self._k(list_key), start, end)
            out: List[Any] = []
            for item in raw:
                try:
                    out.append(json.loads(item))
                except Exception:
                    out.append(item)
            return out
        except Exception:
            return []


class AdaptiveScenarioGenerator:
    """Générateur de scénario adaptatif (sans appels externes) avec cache Redis optionnel.

    Conçu pour latence < 300 ms en local.
    """

    def __init__(self, redis_client: Optional[Any] = None) -> None:
        self.cache = DualCache(redis_client=redis_client)
        self.var_engine = _VAR.AIVariationEngine()
        self._logger = logging.getLogger(__name__)

    async def generate_plan(
        self,
        scenario: Any,
        user_profile: Any,
        *,
        session_history: Optional[List[Dict[str, Any]]] = None,
        current_performance: Optional[Dict[str, float]] = None,
    ) -> AdaptiveScenarioPlan:
        t0 = time.perf_counter()

        # Contexte variations
        VariationContext = _VAR.VariationContext
        ctx = VariationContext(
            user_profile=user_profile,
            scenario=scenario,
            session_history=session_history or [],
            current_performance=current_performance or {},
            environmental_factors={},
        )

        # Variations (personnalités, dialogues, etc.)
        variations = await self.var_engine.generate_scenario_variations(ctx)
        personalities = (variations.get("personality").content if variations.get("personality") else {})

        # Agents enrichis (structure légère)
        agents = self._build_adaptive_agents(scenario, personalities)

        # Evénements dynamiques + déclencheurs d'adaptation
        dynamic_events = self._generate_dynamic_events(scenario, user_profile, current_performance or {})
        adaptation_triggers = self._generate_adaptation_triggers()

        # Scores
        estimated_difficulty = self._estimate_difficulty(scenario, personalities, dynamic_events)
        uniqueness_score = self._compute_uniqueness(scenario)

        # Titre/description
        title, description = self._generate_title_description(scenario, dynamic_events)

        plan = AdaptiveScenarioPlan(
            scenario_id=f"adaptive_{getattr(scenario, 'id', 'unknown')}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            title=title,
            description=description,
            agents=agents,
            dynamic_events=dynamic_events,
            adaptation_triggers=adaptation_triggers,
            estimated_difficulty=estimated_difficulty,
            uniqueness_score=uniqueness_score,
            latency_ms=(time.perf_counter() - t0) * 1000.0,
        )

        # Sauvegarde récente pour score d'unicité
        self._persist_recent_scenario(scenario, plan)

        # LOG VISUALISATION (niveau INFO): résumé du plan adaptatif
        try:
            self._logger.info(
                "📊 ADAPTIVE_PLAN | id=%s | title='%s' | latency_ms=%.1f | uniq=%.2f | diff=%.2f | agents=%d | events=%d | triggers=%d",
                plan.scenario_id,
                plan.title,
                plan.latency_ms,
                plan.uniqueness_score,
                plan.estimated_difficulty,
                len(plan.agents),
                len(plan.dynamic_events),
                len(plan.adaptation_triggers),
            )
            # Aperçu types d'événements/triggers (pour diagnostic rapide)
            ev_types = ",".join(e.get("type", "evt") for e in plan.dynamic_events[:5]) or "-"
            trig_types = ",".join(t.get("trigger", "t") for t in plan.adaptation_triggers[:5]) or "-"
            self._logger.debug("🧩 ADAPTIVE_PLAN_DETAILS | events=%s | triggers=%s", ev_types, trig_types)
        except Exception:
            pass

        return plan

    def _build_adaptive_agents(self, scenario: Any, personalities: Dict[str, Any]) -> List[Dict[str, Any]]:
        roles: Dict[str, Dict[str, Any]] = getattr(scenario, "agent_roles", {}) or {}
        agents: List[Dict[str, Any]] = []
        for agent_id, role in roles.items():
            agents.append({
                "id": agent_id,
                "role": role.get("role", role.get("personality", "agent")),
                "persona": personalities.get(agent_id, {}).get("persona", role.get("personality", "neutral")),
                "style": personalities.get(agent_id, {}).get("style", "balanced"),
            })
        return agents

    def _generate_dynamic_events(self, scenario: Any, user_profile: Any, perf: Dict[str, float]) -> List[Dict[str, Any]]:
        duration = int(getattr(scenario, "duration_minutes", 10))
        base: List[Dict[str, Any]] = []
        # Interruptions légères
        base.append({
            "type": "clarifying_question",
            "when_min": max(1, duration // 4),
            "impact": "attention_shift",
        })
        # Escalade si performance élevée
        if perf.get("overall_score", 0.5) > 0.8:
            base.append({
                "type": "fact_challenge",
                "when_min": max(2, duration // 3),
                "impact": "precision_demand",
            })
        # Moments de soutien si difficulté
        if perf.get("overall_score", 0.5) < 0.4:
            base.append({
                "type": "encouraging_nod",
                "when_min": max(1, duration // 5),
                "impact": "confidence_boost",
            })
        return base

    def _generate_adaptation_triggers(self) -> List[Dict[str, Any]]:
        return [
            {
                "trigger": "performance_drop",
                "condition": {"metric": "overall_score", "lt": 0.4},
                "action": {"increase_support": True, "reduce_interruptions": True},
            },
            {
                "trigger": "performance_peak",
                "condition": {"metric": "overall_score", "gt": 0.8},
                "action": {"increase_challenge": True, "add_interruptions": True},
            },
            {
                "trigger": "long_silence",
                "condition": {"metric": "silence_seconds", "gt": 10},
                "action": {"provide_prompt": True},
            },
        ]

    def _estimate_difficulty(self, scenario: Any, personalities: Dict[str, Any], events: List[Dict[str, Any]]) -> float:
        level = str(getattr(getattr(scenario, "level", "intermediate"), "value", getattr(scenario, "level", "intermediate")))
        base = {"beginner": 0.3, "intermediate": 0.5, "advanced": 0.7}.get(level, 0.5)
        aggr = 0.0
        for p in personalities.values():
            style = p.get("style", "balanced")
            aggr += 0.2 if style == "challenging" else (0.05 if style == "balanced" else 0.0)
        aggr /= max(1, len(personalities))
        ev = sum(0.05 for e in events if e.get("impact") in {"attention_shift", "precision_demand"})
        return min(1.0, max(0.0, base + aggr + ev))

    def _recent_key(self, scenario: Any) -> str:
        sid = getattr(scenario, "id", "unknown")
        topic = getattr(scenario, "title", sid)
        return f"recent:{sid}:{topic}"

    def _compute_uniqueness(self, scenario: Any, lookback: int = 10) -> float:
        key = self._recent_key(scenario)
        recent = self.cache.lrange(key, 0, lookback - 1)
        if not recent:
            return 1.0
        # Similarité simplifiée sur titre et durée
        title = getattr(scenario, "title", "")
        duration = int(getattr(scenario, "duration_minutes", 10))
        sims: List[float] = []
        for item in recent:
            try:
                it = item if isinstance(item, dict) else json.loads(item)
            except Exception:
                continue
            sim = 0.0
            if it.get("title") == title:
                sim += 0.6
            if int(it.get("duration", duration)) == duration:
                sim += 0.2
            sims.append(min(1.0, sim))
        avg = (sum(sims) / len(sims)) if sims else 0.0
        return max(0.0, 1.0 - avg)

    def _persist_recent_scenario(self, scenario: Any, plan: AdaptiveScenarioPlan) -> None:
        key = self._recent_key(scenario)
        self.cache.lpush_trim(
            key,
            {"title": getattr(scenario, "title", ""), "duration": int(getattr(scenario, "duration_minutes", 10)), "ts": datetime.now().isoformat(), "uniq": plan.uniqueness_score},
            keep_last=10,
        )

    def _generate_title_description(self, scenario: Any, events: List[Dict[str, Any]]) -> Tuple[str, str]:
        title = f"{getattr(scenario, 'title', 'Scénario')} (adaptatif)"
        ev_text = ", ".join(e.get("type", "evt") for e in events) or "aucun"
        desc = (
            f"Scénario adaptatif généré automatiquement.\n"
            f"Événements dynamiques prévus: {ev_text}.\n"
            f"Le déroulé s'ajuste en fonction de vos performances en temps réel."
        )
        return title, desc



