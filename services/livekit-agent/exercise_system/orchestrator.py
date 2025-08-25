import asyncio
from dataclasses import dataclass
from typing import Any, Dict, List


@dataclass
class EnhancedAgent:
    base_agent: Any
    scenario_role: Dict[str, Any]
    adapted_personality: Dict[str, Any]
    scenario_context: Dict[str, Any]


class ExerciseOrchestrator:
    """Orchestrateur minimal reliant scénarios/variations à une session.

    Cette version ne dépend d'aucun composant externe.
    """

    def __init__(self) -> None:
        pass

    async def configure_agents_for_scenario(self, existing_agents: List[Any], scenario: Any, personality_content: Dict[str, Any]) -> List[EnhancedAgent]:
        enhanced: List[EnhancedAgent] = []
        roles: Dict[str, Dict[str, Any]] = getattr(scenario, "agent_roles", {}) or {}
        for agent in existing_agents:
            scenario_role = roles.get(getattr(agent, "id", "")) or next(iter(roles.values()), {})
            adapted_personality = personality_content.get(getattr(agent, "id", "default")) or {"persona": scenario_role.get("personality", "neutral"), "style": "balanced"}
            enhanced.append(
                EnhancedAgent(
                    base_agent=agent,
                    scenario_role=scenario_role,
                    adapted_personality=adapted_personality,
                    scenario_context=getattr(scenario, "context", {}),
                )
            )
        await asyncio.sleep(0)
        return enhanced


