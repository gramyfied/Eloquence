from enum import Enum
from dataclasses import dataclass
from typing import Any, Dict, Optional


class ResponseType(Enum):
    """Types de réponses possibles produits par l'IA.

    Définition minimale pour satisfaire les vérifications structurelles.
    """

    TEXT = "text"
    QUESTION = "question"
    SUMMARY = "summary"
    MODERATION = "moderation"
    EXPERTISE = "expertise"


class ArgumentativeStrategy(Enum):
    """Stratégies argumentatives pour les agents dans les débats"""

    SUPPORT = "support"  # Soutenir une position
    OPPOSE = "oppose"  # S'opposer à une position
    NUANCE = "nuance"  # Nuancer/modérer une position
    CHALLENGE = "challenge"  # Défier/questionner une position
    EXPERTISE = "expertise"  # Apporter une expertise technique
    MODERATION = "moderation"  # Modérer le débat


# Compatibilité ascendante: certains modules peuvent utiliser encore ArgumentStrategy
# Assure que les deux noms pointent vers la même Enum
ArgumentStrategy = ArgumentativeStrategy


@dataclass
class ConversationContext:
    """Contexte minimal d'une conversation de débat."""

    topic: str
    user_name: Optional[str] = None
    user_subject: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class AdvancedConversationAI:
    """Moteur de conversation avancé (squelette minimal).

    Cette classe est volontairement simple pour répondre aux exigences
    de validation structurelle sans présumer de la logique métier.
    """

    def __init__(self) -> None:
        pass

    def decide_response(
        self,
        context: ConversationContext,
        strategy: ArgumentativeStrategy,
        response_type: ResponseType = ResponseType.TEXT,
    ) -> Dict[str, Any]:
        """Retourne une structure de réponse minimale conforme aux types définis."""

        return {
            "type": response_type.value,
            "strategy": strategy.value,
            "text": "",
            "meta": {"topic": context.topic},
        }


