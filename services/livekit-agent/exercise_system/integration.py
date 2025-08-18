import asyncio
from dataclasses import dataclass
from typing import Any, Dict, List, Optional


@dataclass
class ExerciseRequest:
    category: Optional[str] = None
    preferences: Optional[Dict[str, Any]] = None


@dataclass
class EnhancedSession:
    session_id: str
    scenario: Any
    enhanced_agents: List[Any]


class ExerciseSystemIntegration:
    """Pont d'intégration avec un gestionnaire multi-agents existant.

    Cette classe ne connaît pas les détails de LiveKit et n'altère aucune URL/port.
    Elle orchestre simplement la sélection du scénario, la génération des variations
    et l'adaptation des agents existants.
    """

    def __init__(
        self,
        multi_agent_manager: Any,
        *,
        scenario_manager: Any,
        variation_engine: Any,
        cache_system: Any,
        orchestrator: Any,
    ) -> None:
        self.multi_agent_manager = multi_agent_manager
        self.scenario_manager = scenario_manager
        self.variation_engine = variation_engine
        self.cache_system = cache_system
        self.orchestrator = orchestrator

    async def enhance_existing_session(self, session_id: str, exercise_request: ExerciseRequest) -> EnhancedSession:
        existing_context = await self.multi_agent_manager.get_session_context(session_id)

        scenario = await self.scenario_manager.select_optimal_scenario(
            existing_context.user_profile, (exercise_request.preferences or {})
        )

        # Import local par recherche dynamique (évite les problèmes de package avec tiret)
        import importlib.util
        from pathlib import Path
        base_dir = Path(__file__).resolve().parent
        var_path = base_dir / "variation_engine.py"
        spec = importlib.util.spec_from_file_location("_var_mod", str(var_path))
        mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
        assert spec and spec.loader
        spec.loader.exec_module(mod)
        VariationContext = mod.VariationContext

        variation_context = VariationContext(
            user_profile=existing_context.user_profile,
            scenario=scenario,
            session_history=getattr(existing_context, "history", []),
            current_performance={},
            environmental_factors={},
        )

        variations = await self.variation_engine.generate_scenario_variations(variation_context)
        personality_content = variations.get("personality").content if variations.get("personality") else {}

        enhanced_agents = await self.orchestrator.configure_agents_for_scenario(
            existing_context.agents, scenario, personality_content
        )

        # Génération du plan adaptatif (événements, triggers, scores)
        try:
            import importlib.util as _il
            from pathlib import Path as _Path
            import os as _os
            import logging as _logging
            _ad_path = _Path(__file__).resolve().parent / "adaptive_generator.py"
            _ad_spec = _il.spec_from_file_location("_ad_mod", str(_ad_path))
            _ad_mod = _il.module_from_spec(_ad_spec)  # type: ignore[arg-type]
            assert _ad_spec and _ad_spec.loader
            _ad_spec.loader.exec_module(_ad_mod)
            AdaptiveScenarioGenerator = _ad_mod.AdaptiveScenarioGenerator
            # Client Redis réel si disponible
            _redis_client = None
            try:
                import redis as _redis
                _url = _os.getenv("REDIS_URL", "redis://redis:6379/0")
                _redis_client = _redis.Redis.from_url(_url, decode_responses=True)
            except Exception:
                _redis_client = None
            gen = AdaptiveScenarioGenerator(redis_client=_redis_client)
            adaptive_plan = await gen.generate_plan(scenario, existing_context.user_profile)
            try:
                _logging.getLogger(__name__).info(
                    "🔗 INTEGRATION | session=%s | adaptive_plan=%s | diff=%.2f | events=%d | triggers=%d",
                    session_id,
                    adaptive_plan.scenario_id if adaptive_plan else "None",
                    getattr(adaptive_plan, 'estimated_difficulty', -1.0) if adaptive_plan else -1.0,
                    len(getattr(adaptive_plan, 'dynamic_events', []) or []),
                    len(getattr(adaptive_plan, 'adaptation_triggers', []) or []),
                )
            except Exception:
                pass
        except Exception:
            adaptive_plan = None

        # Propager les adaptations au gestionnaire multi-agents lorsque possible
        try:
            # Appliquer le contexte du scénario + plan adaptatif
            if hasattr(self.multi_agent_manager, 'mam') and hasattr(self.multi_agent_manager.mam, 'apply_exercise_context'):
                ctx_payload = getattr(scenario, "context", {}).copy()
                if adaptive_plan:
                    ctx_payload.update({
                        "dynamic_events": adaptive_plan.dynamic_events,
                        "adaptation_triggers": adaptive_plan.adaptation_triggers,
                        "estimated_difficulty": adaptive_plan.estimated_difficulty,
                    })
                self.multi_agent_manager.mam.apply_exercise_context(ctx_payload)
            elif hasattr(self.multi_agent_manager, 'apply_exercise_context'):
                ctx_payload = getattr(scenario, "context", {}).copy()
                if adaptive_plan:
                    ctx_payload.update({
                        "dynamic_events": adaptive_plan.dynamic_events,
                        "adaptation_triggers": adaptive_plan.adaptation_triggers,
                        "estimated_difficulty": adaptive_plan.estimated_difficulty,
                    })
                self.multi_agent_manager.apply_exercise_context(ctx_payload)
        except Exception as _e:
            import logging as _logging
            _logging.getLogger(__name__).warning(f"⚠️ INTEGRATION | apply_exercise_context échoué: {_e}")

        try:
            # Appliquer les variations de personnalité
            if hasattr(self.multi_agent_manager, 'mam') and hasattr(self.multi_agent_manager.mam, 'override_agent_personalities'):
                self.multi_agent_manager.mam.override_agent_personalities(personality_content)
            elif hasattr(self.multi_agent_manager, 'override_agent_personalities'):
                self.multi_agent_manager.override_agent_personalities(personality_content)
        except Exception:
            pass

        await self.multi_agent_manager.update_session_configuration(
            session_id=session_id,
            new_agents=enhanced_agents,
            scenario_context=getattr(scenario, "context", {}),
        )

        return EnhancedSession(session_id=session_id, scenario=scenario, enhanced_agents=enhanced_agents)


