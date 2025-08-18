import asyncio
import hashlib
import json
from dataclasses import dataclass
from typing import Any, Dict
try:
    from .metrics import inc_variation, start_timer, get_histogram_for  # type: ignore
except Exception:  # pragma: no cover - chargement direct si pas de package
    import importlib.util
    from pathlib import Path
    _base_dir = Path(__file__).resolve().parent
    _spec = importlib.util.spec_from_file_location("_ex_metrics", str(_base_dir / "metrics.py"))
    _mod = importlib.util.module_from_spec(_spec)  # type: ignore[arg-type]
    assert _spec and _spec.loader
    _spec.loader.exec_module(_mod)
    inc_variation = _mod.inc_variation
    start_timer = _mod.start_timer
    get_histogram_for = _mod.get_histogram_for


@dataclass
class VariationContext:
    """Contexte minimal pour générer des variations.

    Le moteur ne dépend d'aucun service externe et fonctionne en mémoire,
    afin d'être testable rapidement (latence quasi nulle).
    """

    user_profile: Any
    scenario: Any
    session_history: Any
    current_performance: Dict[str, float]
    environmental_factors: Dict[str, Any]


@dataclass
class GeneratedVariation:
    variation_type: str
    content: Dict[str, Any]
    confidence_score: float
    cache_key: str
    metadata: Dict[str, Any]


class AIVariationEngine:
    """Moteur de variations IA (version locale, sans appels réseau).

    - Génération déterministe basée sur le contexte
    - Cache en mémoire par clé sémantique
    - API async pour s'intégrer dans le pipeline asynchrone
    """

    def __init__(self) -> None:
        self.variation_cache: Dict[str, GeneratedVariation] = {}

    async def generate_scenario_variations(self, context: VariationContext) -> Dict[str, GeneratedVariation]:
        tasks = [
            self._generate_contextual_variation(context),
            self._generate_personality_variations(context),
            self._generate_dialogue_variations(context),
            self._generate_challenge_variations(context),
        ]
        results = await asyncio.gather(*tasks)
        return {v.variation_type: v for v in results}

    # -- Variations spécifiques --
    async def _generate_contextual_variation(self, context: VariationContext) -> GeneratedVariation:
        cache_key = self._generate_cache_key("contextual", context)
        if cache_key in self.variation_cache:
            return self.variation_cache[cache_key]

        # Construction d'une réponse déterministe simple
        timer = start_timer()
        objectives = getattr(context.scenario, "objectives", []) or []
        interests = getattr(context.user_profile, "interests", []) or []
        adapted = {
            "adapted_context": f"{getattr(context.scenario, 'title', 'scenario')} adapté au secteur: {getattr(context.user_profile, 'professional_sector', 'general')}",
            "vocabulary_adaptations": [kw for kw in interests if any(kw.lower() in o.lower() for o in objectives)],
            "complexity_adjustments": getattr(context.scenario, "level", "intermediate"),
        }

        variation = GeneratedVariation(
            variation_type="contextual",
            content=adapted,
            confidence_score=0.85,
            cache_key=cache_key,
            metadata={"generator": "local", "version": 1},
        )
        self.variation_cache[cache_key] = variation
        inc_variation("contextual")
        timer.observe(get_histogram_for("contextual"))
        await asyncio.sleep(0)
        return variation

    async def _generate_personality_variations(self, context: VariationContext) -> GeneratedVariation:
        cache_key = self._generate_cache_key("personality", context)
        if cache_key in self.variation_cache:
            return self.variation_cache[cache_key]

        timer = start_timer()
        roles = getattr(context.scenario, "agent_roles", {}) or {}
        personalities: Dict[str, Any] = {}
        user_level = getattr(context.user_profile, "skill_level", None)
        for agent_id, role_cfg in roles.items():
            base = role_cfg.get("personality", "neutral")
            if str(getattr(user_level, "value", user_level)) == "beginner":
                personalities[agent_id] = {"persona": base, "style": "supportive"}
            elif str(getattr(user_level, "value", user_level)) == "advanced":
                personalities[agent_id] = {"persona": base, "style": "challenging"}
            else:
                personalities[agent_id] = {"persona": base, "style": "balanced"}

        variation = GeneratedVariation(
            variation_type="personality",
            content=personalities,
            confidence_score=0.8,
            cache_key=cache_key,
            metadata={"generator": "local", "version": 1},
        )
        self.variation_cache[cache_key] = variation
        inc_variation("personality")
        timer.observe(get_histogram_for("personality"))
        await asyncio.sleep(0)
        return variation

    async def _generate_dialogue_variations(self, context: VariationContext) -> GeneratedVariation:
        cache_key = self._generate_cache_key("dialogue", context)
        if cache_key in self.variation_cache:
            return self.variation_cache[cache_key]

        timer = start_timer()
        variation = GeneratedVariation(
            variation_type="dialogue",
            content={
                "openers": [f"Parlons de {getattr(context.scenario, 'title', 'votre sujet')}"],
                "followups": ["Pouvez-vous préciser ?", "Un exemple concret ?"],
            },
            confidence_score=0.75,
            cache_key=cache_key,
            metadata={"generator": "local", "version": 1},
        )
        self.variation_cache[cache_key] = variation
        inc_variation("dialogue")
        timer.observe(get_histogram_for("dialogue"))
        await asyncio.sleep(0)
        return variation

    async def _generate_challenge_variations(self, context: VariationContext) -> GeneratedVariation:
        cache_key = self._generate_cache_key("challenge", context)
        if cache_key in self.variation_cache:
            return self.variation_cache[cache_key]

        timer = start_timer()
        variation = GeneratedVariation(
            variation_type="challenge",
            content={
                "pressure": "medium",
                "techniques": ["question répétée", "changement de sujet"],
            },
            confidence_score=0.7,
            cache_key=cache_key,
            metadata={"generator": "local", "version": 1},
        )
        self.variation_cache[cache_key] = variation
        inc_variation("challenge")
        timer.observe(get_histogram_for("challenge"))
        await asyncio.sleep(0)
        return variation

    # -- Cache --
    def _generate_cache_key(self, variation_type: str, context: VariationContext) -> str:
        base = {
            "type": variation_type,
            "user": getattr(context.user_profile, "user_id", "anon"),
            "scenario": getattr(context.scenario, "id", getattr(context.scenario, "title", "unknown")),
            "level": str(getattr(getattr(context.user_profile, "skill_level", None), "value", "")),
            "interests": sorted(list(getattr(context.user_profile, "interests", []) or [])),
        }
        payload = json.dumps(base, ensure_ascii=False, sort_keys=True).encode("utf-8")
        digest = hashlib.sha256(payload).hexdigest()
        return f"var:{digest}"


