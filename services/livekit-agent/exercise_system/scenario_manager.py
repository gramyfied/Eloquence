import asyncio
import json
import os
from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Tuple


class SkillLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class ExerciseCategory(str, Enum):
    PRESENTATION = "presentation_skills"
    DEBATE = "debate_skills"
    NEGOTIATION = "negotiation_skills"
    CRISIS_COMM = "crisis_communication"


@dataclass
class UserProfile:
    user_id: str
    skill_level: SkillLevel
    professional_sector: Optional[str]
    interests: List[str]
    recent_exercises: List[str]
    performance_history: Dict[str, float]


@dataclass
class Scenario:
    id: str
    category: ExerciseCategory
    level: SkillLevel
    title: str
    description: str
    duration_minutes: int
    objectives: List[str]
    context: Dict
    agent_roles: Dict[str, Dict]
    variation_parameters: Dict
    success_criteria: Dict[str, float]


class PerformanceTracker:
    """Suivi très simple des performances utilisateur pour le scoring.

    Cette implémentation est volontairement minimale pour permettre
    l'itération. Elle pourra être remplacée par une version
    instrumentée et persistée ultérieurement.
    """

    def get_category_score(self, user_profile: UserProfile, category: ExerciseCategory) -> float:
        return user_profile.performance_history.get(category.value, 0.0)


class ScenarioManager:
    """Gestionnaire principal des scénarios d'exercices.

    - Chargement depuis un fichier JSON
    - Filtrage par niveau/catégorie
    - Évitement de répétition immédiate
    - Scoring simple basé sur l'historique et la variété
    """

    def __init__(self, scenario_config_path: Optional[str] = None):
        self.scenarios: Dict[str, Scenario] = {}
        self.scenario_config_path = scenario_config_path or os.path.join(
            os.path.dirname(__file__), "config", "scenarios.json"
        )
        self.performance_tracker = PerformanceTracker()

    async def initialize(self) -> None:
        await self._load_scenarios()
        await self._validate_scenarios()

    async def _load_scenarios(self) -> None:
        if not os.path.isabs(self.scenario_config_path):
            config_path = self.scenario_config_path
        else:
            config_path = self.scenario_config_path

        try:
            with open(config_path, "r", encoding="utf-8") as f:
                scenarios_data = json.load(f)

            for scenario_data in scenarios_data.get("scenarios", []):
                scenario = Scenario(
                    id=scenario_data["id"],
                    category=ExerciseCategory(scenario_data["category"]),
                    level=SkillLevel(scenario_data["level"]),
                    title=scenario_data["title"],
                    description=scenario_data["description"],
                    duration_minutes=int(scenario_data["duration_minutes"]),
                    objectives=list(scenario_data["objectives"]),
                    context=dict(scenario_data["context"]),
                    agent_roles=dict(scenario_data["agent_roles"]),
                    variation_parameters=dict(scenario_data["variation_parameters"]),
                    success_criteria=dict(scenario_data["success_criteria"]),
                )
                self.scenarios[scenario.id] = scenario
        except Exception as exc:  # pragma: no cover - re-raise with context
            raise RuntimeError(f"Erreur lors du chargement des scénarios: {exc}")

    async def _validate_scenarios(self) -> None:
        if not self.scenarios:
            raise ValueError("Aucun scénario chargé")

    async def select_optimal_scenario(
        self, user_profile: UserProfile, preferences: Optional[Dict] = None
    ) -> Scenario:
        candidates = self._filter_by_level_and_category(user_profile, preferences)
        candidates = self._avoid_recent_repetition(candidates, user_profile)
        scored = await self._score_scenarios(candidates, user_profile)
        if not scored:
            return await self._get_fallback_scenario(user_profile)
        best = max(scored, key=lambda x: x[1])
        return best[0]

    def _filter_by_level_and_category(
        self, user_profile: UserProfile, preferences: Optional[Dict]
    ) -> List[Scenario]:
        preferred_categories = None
        max_duration = None
        preferred_ids = None
        if preferences:
            preferred_categories = set(preferences.get("preferred_categories", []) or [])
            max_duration = preferences.get("max_duration")
            # Support ciblage direct de scénarios
            if preferences.get("preferred_scenario_id"):
                preferred_ids = {preferences.get("preferred_scenario_id")}
            ids_list = preferences.get("preferred_scenario_ids") or []
            if ids_list:
                preferred_ids = set(ids_list) if preferred_ids is None else (preferred_ids | set(ids_list))

        result: List[Scenario] = []
        for scenario in self.scenarios.values():
            if not self._is_level_compatible(scenario.level, user_profile):
                continue
            if preferred_categories and scenario.category.value not in preferred_categories:
                continue
            if max_duration is not None and scenario.duration_minutes > int(max_duration):
                continue
            if preferred_ids and scenario.id not in preferred_ids:
                continue
            result.append(scenario)
        return result

    def _is_level_compatible(self, scenario_level: SkillLevel, user_profile: UserProfile) -> bool:
        if scenario_level == user_profile.skill_level:
            return True
        # Autoriser un niveau adjacent si score historique élevé
        adjacent: Dict[SkillLevel, Tuple[SkillLevel, Optional[SkillLevel]]] = {
            SkillLevel.BEGINNER: (SkillLevel.INTERMEDIATE, None),
            SkillLevel.INTERMEDIATE: (SkillLevel.BEGINNER, SkillLevel.ADVANCED),
            SkillLevel.ADVANCED: (SkillLevel.INTERMEDIATE, None),
        }
        lower, upper = adjacent[user_profile.skill_level]
        historical = self.performance_tracker.get_category_score(
            user_profile, ExerciseCategory.PRESENTATION
        )
        if scenario_level in {lvl for lvl in (lower, upper) if lvl is not None} and historical >= 0.75:
            return True
        return False

    def _avoid_recent_repetition(self, scenarios: List[Scenario], user_profile: UserProfile) -> List[Scenario]:
        if not user_profile.recent_exercises:
            return scenarios
        recent_set = set(user_profile.recent_exercises[-5:])
        filtered = [s for s in scenarios if s.id not in recent_set]
        return filtered or scenarios  # si tout filtré, on garde la liste initiale

    async def _score_scenarios(self, scenarios: List[Scenario], user_profile: UserProfile) -> List[Tuple[Scenario, float]]:
        scored: List[Tuple[Scenario, float]] = []
        for scenario in scenarios:
            score = 0.0
            # Historique (catégorie)
            historical = self.performance_tracker.get_category_score(user_profile, scenario.category)
            score += 0.4 * historical
            # Objectifs (alignement simple via mots-clés intérêts)
            interest_overlap = self._compute_interest_overlap(scenario, user_profile)
            score += 0.3 * interest_overlap
            # Variété (pénaliser redites de catégorie immédiate)
            variety_bonus = 0.2 if scenario.id not in set(user_profile.recent_exercises[-3:]) else 0.05
            score += variety_bonus
            # Engagement (heuristique simple durée moyenne acceptable)
            engagement = 0.1 if 5 <= scenario.duration_minutes <= 15 else 0.05
            score += engagement
            scored.append((scenario, score))
        # Simulation d'opérations async
        await asyncio.sleep(0)
        return scored

    def _compute_interest_overlap(self, scenario: Scenario, user_profile: UserProfile) -> float:
        if not user_profile.interests:
            return 0.0
        objectives_text = " ".join(scenario.objectives).lower()
        hits = sum(1 for kw in user_profile.interests if kw.lower() in objectives_text)
        return min(1.0, hits / max(1, len(user_profile.interests)))

    async def _get_fallback_scenario(self, user_profile: UserProfile) -> Scenario:
        # Essayer d'abord le même niveau
        same_level = [s for s in self.scenarios.values() if s.level == user_profile.skill_level]
        if same_level:
            return same_level[0]
        # Sinon n'importe lequel (déterministe via tri id)
        return sorted(self.scenarios.values(), key=lambda s: s.id)[0]


