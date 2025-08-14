"""
Système de prévention de l'auto-dialogue pour débats TV naturels
"""
import logging
from collections import deque
from typing import Dict, List, Optional
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class SelfDialoguePrevention:
    """Empêche les agents de se parler à eux-mêmes"""

    def __init__(self, max_recent_speakers: int = 5):
        self.recent_speakers: deque[str] = deque(maxlen=max_recent_speakers)
        self.topic_ownership: Dict[str, str] = {}
        self.agent_participation: Dict[str, int] = {}
        self.last_speaker_time: Dict[str, datetime] = {}

    def can_agent_respond(self, agent_id: str, context: str, force_response: bool = False) -> bool:
        """Détermine si un agent peut répondre selon les règles de naturalité"""

        # Exception : Réponse forcée (interpellation directe)
        if force_response:
            logger.info(f"🎯 RÉPONSE FORCÉE autorisée pour {agent_id}")
            return True

        # Règle 1 : Pas deux fois de suite (sauf si plus de 30 secondes)
        if self.recent_speakers and self.recent_speakers[-1] == agent_id:
            last_time = self.last_speaker_time.get(agent_id, datetime.min)
            if datetime.now() - last_time < timedelta(seconds=30):
                logger.info(f"❌ {agent_id} a parlé en dernier, refus auto-dialogue")
                return False

        # Règle 2 : Pas de monopolisation (max 40% des 5 dernières interventions)
        recent_count = list(self.recent_speakers).count(agent_id)
        if len(self.recent_speakers) >= 3 and (recent_count / max(1, len(self.recent_speakers))) > 0.4:
            logger.info(f"❌ {agent_id} monopolise ({recent_count}/{len(self.recent_speakers)})")
            return False

        # Règle 3 : Pertinence contextuelle minimale
        relevance = self.calculate_contextual_relevance(agent_id, context)
        if relevance < 0.3:
            logger.info(f"❌ {agent_id} pertinence trop faible ({relevance:.2f})")
            return False

        logger.info(f"✅ {agent_id} autorisé à répondre (pertinence: {relevance:.2f})")
        return True

    def register_speaker(self, agent_id: str, topic: Optional[str] = None) -> None:
        """Enregistre qu'un agent a parlé"""
        self.recent_speakers.append(agent_id)
        self.last_speaker_time[agent_id] = datetime.now()

        if topic:
            self.topic_ownership[topic] = agent_id

        # Incrémenter participation
        self.agent_participation[agent_id] = self.agent_participation.get(agent_id, 0) + 1

        logger.info(f"📝 {agent_id} enregistré comme dernier intervenant")

    def calculate_contextual_relevance(self, agent_id: str, context: str) -> float:
        """Calcule la pertinence contextuelle d'un agent pour le contexte

        Note: Implémentation simple à raffiner avec analyse sémantique.
        """
        base_relevance = 0.5

        # Bonus si l'agent n'a pas beaucoup parlé récemment
        participation = self.agent_participation.get(agent_id, 0)
        total_participation = sum(self.agent_participation.values()) or 1
        participation_ratio = participation / total_participation

        if participation_ratio < 0.3:
            base_relevance += 0.3  # Bonus pour agents moins actifs

        return min(1.0, base_relevance)

    def get_participation_stats(self) -> Dict[str, int]:
        """Retourne les statistiques de participation"""
        return dict(self.agent_participation)

    def reset_session(self) -> None:
        """Remet à zéro pour une nouvelle session"""
        self.recent_speakers.clear()
        self.topic_ownership.clear()
        self.agent_participation.clear()
        self.last_speaker_time.clear()
        logger.info("🔄 Session de prévention auto-dialogue réinitialisée")


