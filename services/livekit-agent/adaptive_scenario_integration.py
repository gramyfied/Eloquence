from __future__ import annotations

import asyncio
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime
from dataclasses import dataclass

import sys
import os

# Assurer que le répertoire courant est importable pour les modules locaux
_CUR_DIR = os.path.dirname(os.path.abspath(__file__))
if _CUR_DIR not in sys.path:
    sys.path.insert(0, _CUR_DIR)

from exercise_system.scenario_manager import ScenarioManager, UserProfile, SkillLevel
from exercise_system.variation_engine import AIVariationEngine, VariationContext
from multi_agent_manager import MultiAgentManager

logger = logging.getLogger(__name__)


@dataclass
class AdaptiveSession:
    session_id: str
    user_profile: UserProfile
    active_scenario: Any
    variations: Dict[str, Any]
    start_time: datetime
    performance_metrics: Dict[str, float]
    adaptation_history: List[Dict]


class AdaptiveScenarioIntegration:
    """Intégration complète des scénarios adaptatifs dans le pipeline principal."""

    def __init__(self, multi_agent_manager: MultiAgentManager):
        self.manager = multi_agent_manager
        self.scenario_manager = ScenarioManager()
        self.variation_engine = AIVariationEngine()
        self.active_session: Optional[AdaptiveSession] = None
        self.performance_history: Dict[str, List[float]] = {}

    async def initialize(self):
        await self.scenario_manager.initialize()
        logger.info("🎭 Système scénarios adaptatifs initialisé")

    async def start_adaptive_exercise(
        self,
        *,
        user_id: str,
        skill_level: str = "intermediate",
        preferences: Optional[Dict] = None,
        subject: Optional[str] = None,
    ) -> bool:
        try:
            profile = UserProfile(
                user_id=user_id,
                skill_level=SkillLevel(skill_level),
                professional_sector=preferences.get('sector', 'general') if preferences else 'general',
                interests=preferences.get('interests', []) if preferences else [],
                recent_exercises=self.performance_history.get(user_id, []),
                performance_history={},
            )
            scen_prefs = dict(preferences or {})
            if subject:
                scen_prefs['subject_focus'] = subject
            scenario = await self.scenario_manager.select_optimal_scenario(profile, scen_prefs)

            vctx = VariationContext(
                user_profile=profile,
                scenario=scenario,
                session_history=[],
                current_performance={},
                environmental_factors={'time_of_day': datetime.now().hour},
            )
            variations = await self.variation_engine.generate_scenario_variations(vctx)

            await self._apply_variations_to_agents(variations)
            await self._configure_manager_for_scenario(scenario, variations)

            self.active_session = AdaptiveSession(
                session_id=f"{user_id}_{datetime.now().timestamp()}",
                user_profile=profile,
                active_scenario=scenario,
                variations=variations,
                start_time=datetime.now(),
                performance_metrics={},
                adaptation_history=[],
            )
            logger.info(f"🚀 Exercice adaptatif démarré: {scenario.title}")
            return True
        except Exception as e:
            logger.error(f"❌ Erreur démarrage exercice adaptatif: {e}")
            return False

    async def _apply_variations_to_agents(self, variations: Dict[str, Any]):
        personality_variations = (variations or {}).get('personality')
        if not personality_variations:
            return
        content = getattr(personality_variations, 'content', {}) or {}
        for agent_id, agent in self.manager.agents.items():
            if agent_id in content:
                var = content[agent_id]
                agent.dynamic_personality = {
                    'base_style': var.get('style', 'balanced'),
                    'adaptation_level': var.get('adaptation', 0.5),
                    'challenge_intensity': var.get('intensity', 0.5),
                    'emotional_range': var.get('emotional_range', 'moderate'),
                    'interaction_frequency': var.get('frequency', 'normal'),
                }
                await self._update_agent_system_prompt(agent, var)

    async def _update_agent_system_prompt(self, agent, variation):
        style = variation.get('style', 'balanced')
        intensity = variation.get('intensity', 0.5)
        prompts = {
            'supportive': f"""
Tu es {agent.name}, un coach bienveillant et encourageant.
Intensité de support: {intensity:.1f}/1.0
- Utilise des encouragements fréquents
- Pose des questions ouvertes pour guider
- Célèbre les progrès même minimes
""",
            'challenging': f"""
Tu es {agent.name}, un interlocuteur exigeant qui pousse à l'excellence.
Intensité de challenge: {intensity:.1f}/1.0
- Pose des questions difficiles
- Remets en question les réponses faciles
- Maintiens une pression constructive
""",
            'balanced': f"""
Tu es {agent.name}, un interlocuteur équilibré et professionnel.
Niveau d'adaptation: {intensity:.1f}/1.0
- Alterne entre support et challenge
- Observe les réactions pour ajuster
- Maintiens un dialogue constructif
""",
        }
        agent.adaptive_system_prompt = prompts.get(style, prompts['balanced'])

    async def _configure_manager_for_scenario(self, scenario, variations):
        context = {
            'scenario_id': scenario.id,
            'scenario_title': scenario.title,
            'objectives': scenario.objectives,
            'duration_minutes': scenario.duration_minutes,
            'success_criteria': scenario.success_criteria,
        }
        self.manager.apply_exercise_context(context)

    async def adapt_during_session(self, user_input: str, performance_metrics: Dict[str, float]):
        if not self.active_session:
            return
        self.active_session.performance_metrics.update(performance_metrics or {})
        # Heuristique simple: si engagement < 0.6 ou répétition > 0.7 → regénérer des variations
        engagement = float(performance_metrics.get('engagement', 1.0))
        repetition = float(performance_metrics.get('repetition_score', 0.0))
        need = engagement < 0.6 or repetition > 0.7
        if not need:
            return
        vctx = VariationContext(
            user_profile=self.active_session.user_profile,
            scenario=self.active_session.active_scenario,
            session_history=[user_input],
            current_performance=performance_metrics,
            environmental_factors={'session_duration': (datetime.now() - self.active_session.start_time).seconds},
        )
        new_vars = await self.variation_engine.generate_scenario_variations(vctx)
        await self._apply_variations_to_agents(new_vars)
        self.active_session.adaptation_history.append({
            'timestamp': datetime.now(),
            'trigger_metrics': performance_metrics,
            'applied_variations': list(new_vars.keys()),
        })

    def get_session_metrics(self) -> Dict[str, Any]:
        if not self.active_session:
            return {'status': 'no_active_session'}
        duration = (datetime.now() - self.active_session.start_time).seconds
        uniqueness = min(1.0, len(self.active_session.adaptation_history) * 0.2 + len(self.active_session.variations) * 0.1)
        engagement = float(self.active_session.performance_metrics.get('engagement', 0.5))
        trend = 'excellent' if engagement > 0.8 else 'good' if engagement > 0.6 else 'moderate' if engagement > 0.4 else 'needs_improvement'
        return {
            'session_id': self.active_session.session_id,
            'scenario_title': self.active_session.active_scenario.title,
            'duration_seconds': duration,
            'adaptations_count': len(self.active_session.adaptation_history),
            'current_performance': self.active_session.performance_metrics,
            'uniqueness_score': uniqueness,
            'engagement_trend': trend,
        }


# Factory globale
_global_integration: Optional[AdaptiveScenarioIntegration] = None


def get_adaptive_integration(manager: MultiAgentManager) -> AdaptiveScenarioIntegration:
    global _global_integration
    if _global_integration is None:
        _global_integration = AdaptiveScenarioIntegration(manager)
    return _global_integration


