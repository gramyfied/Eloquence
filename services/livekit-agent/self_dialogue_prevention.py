"""
Système de prévention de l'auto-dialogue pour débats TV naturels
"""
import logging
import re
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

        # NOUVEAU: Détection de questions dans le contexte
        is_question = self._is_question_context(context)
        if is_question:
            logger.info(f"❓ QUESTION DÉTECTÉE - Autorisation spéciale pour {agent_id}")
            # Pour les questions, on est moins restrictif
            return self._can_respond_to_question(agent_id)

        # Règle 1 : Pas deux fois de suite (sauf si plus de 20 secondes au lieu de 30)
        if self.recent_speakers and self.recent_speakers[-1] == agent_id:
            last_time = self.last_speaker_time.get(agent_id, datetime.min)
            if datetime.now() - last_time < timedelta(seconds=20):  # Réduit de 30 à 20 secondes
                logger.info(f"❌ {agent_id} a parlé en dernier, refus auto-dialogue")
                return False

        # Règle 2 : Pas de monopolisation (max 50% au lieu de 40% des 5 dernières interventions)
        recent_count = list(self.recent_speakers).count(agent_id)
        if len(self.recent_speakers) >= 3 and (recent_count / max(1, len(self.recent_speakers))) > 0.5:  # Augmenté de 0.4 à 0.5
            logger.info(f"❌ {agent_id} monopolise ({recent_count}/{len(self.recent_speakers)})")
            return False

        # Règle 3 : Pertinence contextuelle minimale (réduite de 0.3 à 0.2)
        relevance = self.calculate_contextual_relevance(agent_id, context)
        if relevance < 0.2:  # Réduit de 0.3 à 0.2
            logger.info(f"❌ {agent_id} pertinence trop faible ({relevance:.2f})")
            return False

        logger.info(f"✅ {agent_id} autorisé à répondre (pertinence: {relevance:.2f})")
        return True

    def _is_question_context(self, context: str) -> bool:
        """Détecte si le contexte contient une question"""
        if not context:
            return False
            
        context_lower = context.lower()
        
        # Patterns de questions
        question_patterns = [
            r'\?$',  # Se termine par un point d'interrogation
            r'que\s+pensez-vous',
            r'comment\s+réagissez-vous',
            r'qu\'en\s+dites-vous',
            r'votre\s+avis',
            r'votre\s+opinion',
            r'pouvez-vous',
            r'pourriez-vous',
            r'avez-vous',
            r'que\s+répondez-vous',
            r'comment\s+expliquez-vous',
            r'qu\'est-ce\s+que\s+vous\s+en\s+pensez',
            r'que\s+diriez-vous',
            r'comment\s+analysez-vous',
            r'votre\s+réaction',
            r'votre\s+position',
        ]
        
        for pattern in question_patterns:
            if re.search(pattern, context_lower):
                return True
                
        return False

    def _can_respond_to_question(self, agent_id: str) -> bool:
        """Logique spéciale pour répondre aux questions"""
        
        # Si l'agent n'a pas parlé dans les 2 dernières interventions, autoriser
        if len(self.recent_speakers) < 2:
            return True
            
        recent_speakers = list(self.recent_speakers)[-2:]
        if agent_id not in recent_speakers:
            return True
            
        # Si l'agent a parlé récemment mais il y a plus de 10 secondes, autoriser
        last_time = self.last_speaker_time.get(agent_id, datetime.min)
        if datetime.now() - last_time > timedelta(seconds=10):
            return True
            
        return False

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

        # NOUVEAU: Bonus pour questions
        if self._is_question_context(context):
            base_relevance += 0.2

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


