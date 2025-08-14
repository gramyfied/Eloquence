"""
Monitoring de la naturalité des débats en temps réel
"""
import logging
from typing import Dict, List

logger = logging.getLogger(__name__)


class NaturalnessMonitor:
    """Monitore la naturalité des débats en temps réel"""

    def __init__(self) -> None:
        self.metrics = {
            'total_interactions': 0,
            'direct_addresses': 0,
            'successful_responses': 0,
            'emergency_responses': 0,
            'auto_dialogue_prevented': 0,
            'response_times': [],
            'participation_balance': {},
        }

    def log_interaction(self, interaction_type: str, agent_id: str,
                        response_time: float | None = None, success: bool = True) -> None:
        """Enregistre une interaction pour monitoring"""

        self.metrics['total_interactions'] += 1

        if interaction_type == 'direct_address':
            self.metrics['direct_addresses'] += 1

        if success:
            self.metrics['successful_responses'] += 1

        if interaction_type == 'emergency_response':
            self.metrics['emergency_responses'] += 1

        if interaction_type == 'auto_dialogue_prevented':
            self.metrics['auto_dialogue_prevented'] += 1

        if response_time:
            self.metrics['response_times'].append(response_time)

        # Participation
        if agent_id not in self.metrics['participation_balance']:
            self.metrics['participation_balance'][agent_id] = 0
        self.metrics['participation_balance'][agent_id] += 1

        logger.info(f"📊 MÉTRIQUE: {interaction_type} pour {agent_id}")

    def get_naturalness_score(self) -> float:
        """Calcule un score de naturalité (0-100)"""
        if self.metrics['total_interactions'] == 0:
            return 100.0

        # Facteurs de naturalité
        success_rate = self.metrics['successful_responses'] / max(1, self.metrics['total_interactions'])
        emergency_rate = self.metrics['emergency_responses'] / max(1, self.metrics['direct_addresses'])

        # Score de base sur le taux de succès
        base_score = success_rate * 70

        # Pénalité pour trop de réponses d'urgence
        emergency_penalty = emergency_rate * 20

        # Bonus pour équilibre de participation
        balance_bonus = self._calculate_balance_bonus()

        final_score = max(0.0, min(100.0, base_score - emergency_penalty + balance_bonus))

        return final_score

    def _calculate_balance_bonus(self) -> float:
        """Calcule le bonus d'équilibre de participation"""
        if not self.metrics['participation_balance']:
            return 0.0

        participations = list(self.metrics['participation_balance'].values())
        if len(participations) < 2:
            return 0.0

        mean_participation = sum(participations) / len(participations)
        variance = sum((p - mean_participation) ** 2 for p in participations) / len(participations)
        std_dev = variance ** 0.5

        # Bonus inversement proportionnel à l'écart-type
        max_bonus = 30.0
        normalized_std = std_dev / (mean_participation + 1.0)
        bonus = max(0.0, max_bonus * (1.0 - normalized_std))

        return bonus

    def get_report(self) -> Dict:
        """Génère un rapport complet de naturalité"""
        avg_response_time = (sum(self.metrics['response_times']) /
                             len(self.metrics['response_times'])) if self.metrics['response_times'] else 0.0

        return {
            'naturalness_score': self.get_naturalness_score(),
            'total_interactions': self.metrics['total_interactions'],
            'success_rate': (self.metrics['successful_responses'] /
                             max(1, self.metrics['total_interactions'])) * 100.0,
            'direct_address_rate': (self.metrics['direct_addresses'] /
                                    max(1, self.metrics['total_interactions'])) * 100.0,
            'emergency_response_rate': (self.metrics['emergency_responses'] /
                                        max(1, self.metrics['direct_addresses'])) * 100.0,
            'auto_dialogue_prevented': self.metrics['auto_dialogue_prevented'],
            'avg_response_time': avg_response_time,
            'participation_balance': self.metrics['participation_balance'],
        }


