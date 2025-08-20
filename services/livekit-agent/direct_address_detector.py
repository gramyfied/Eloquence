"""
Détecteur d'interpellations directes ultra-robuste
"""
import re
import logging
from typing import List, Dict

logger = logging.getLogger(__name__)


class DirectAddressDetector:
    """Détecte les interpellations directes avec précision maximale"""

    def __init__(self):
        self.agent_names = {
            'sarah': ['sarah', 'sarah johnson', 'mme johnson'],
            'marcus': ['marcus', 'marcus thompson', 'mr thompson', 'm. thompson'],
            'michel': ['michel', 'michel dubois', 'mr dubois', 'm. dubois'],
        }

    def detect_direct_addresses(self, text: str, available_agents: Dict[str, any]) -> List[str]:
        """Détecte TOUTES les interpellations directes dans un texte"""
        addressed_agents: List[str] = []
        if not text:
            return addressed_agents
        text_lower = text.lower().strip()

        logger.info(f"🔍 DÉTECTION INTERPELLATIONS dans: '{text[:100]}...'")

        for agent_id, agent in available_agents.items():
            if self._is_agent_addressed(text_lower, agent):
                addressed_agents.append(agent_id)
                try:
                    logger.info(f"✅ INTERPELLATION DÉTECTÉE: {agent.name}")
                except Exception:
                    logger.info(f"✅ INTERPELLATION DÉTECTÉE: {agent_id}")

        if not addressed_agents:
            logger.info("❌ AUCUNE INTERPELLATION détectée")

        return addressed_agents

    def _is_agent_addressed(self, text_lower: str, agent) -> bool:
        """Vérifie si un agent spécifique est interpellé"""
        try:
            agent_first_name = str(agent.name).split()[0].lower()
        except Exception:
            # fallback si l'agent n'a pas d'attribut name
            agent_first_name = str(agent).split()[0].lower()

        # Patterns d'interpellation ULTRA-COMPLETS
        patterns = [
            # Patterns directs
            f"{agent_first_name},",
            f"{agent_first_name} ",
            f"{agent_first_name}?",
            f"{agent_first_name}:",
            f"{agent_first_name}.",
            f"{agent_first_name}!",

            # Patterns avec questions
            f"{agent_first_name} que",
            f"{agent_first_name} comment",
            f"{agent_first_name} pouvez",
            f"{agent_first_name} qu'en",
            f"{agent_first_name} votre",
            f"{agent_first_name} avez-vous",
            f"{agent_first_name} pensez-vous",

            # Patterns avec prépositions
            f"à {agent_first_name}",
            f"pour {agent_first_name}",
            f"et vous {agent_first_name}",
            f"à vous {agent_first_name}",
            f"alors {agent_first_name}",
            f"donc {agent_first_name}",
            f"maintenant {agent_first_name}",

            # Patterns de sollicitation
            f"question pour {agent_first_name}",
            f"demande à {agent_first_name}",
            f"{agent_first_name} pourriez",
            f"{agent_first_name} justement",

            # Patterns contextuels débat TV
            f"écoutez {agent_first_name}",
            f"dites-moi {agent_first_name}",
            f"{agent_first_name} franchement",
            f"{agent_first_name} sincèrement",

            # Patterns avec verbes
            f"{agent_first_name} croyez",
            f"{agent_first_name} trouvez",
            f"{agent_first_name} diriez",
            f"{agent_first_name} ajouteriez",
        ]

        # Vérifier chaque pattern
        for pattern in patterns:
            if pattern in text_lower:
                logger.info(f"🎯 Pattern détecté: '{pattern}' → {getattr(agent, 'name', 'agent')} ")
                return True

        # Patterns regex pour plus de flexibilité
        regex_patterns = [
            # prénom suivi d'une ponctuation ou espace
            rf"\b{re.escape(agent_first_name)}\b[\s,;:!\?…]",
            # prénom en mot entier dans la phrase
            rf"(^|\s){re.escape(agent_first_name)}(\s|$)",
            # prénom suivi d'un mot déclencheur
            rf"{re.escape(agent_first_name)}\s+(que|comment|pouvez|qu'en|votre)",
        ]

        for pattern in regex_patterns:
            if re.search(pattern, text_lower):
                logger.info(f"🎯 Regex détecté: '{pattern}' → {getattr(agent, 'name', 'agent')} ")
                return True

        # NOUVEAU: Détection d'interpellations indirectes (questions sans nom)
        # MAIS seulement si c'est une question générale ET qu'on a un contexte d'animateur
        # Si l'animateur s'adresse explicitement à un agent (ex: "Sarah !" ou "Marcus ?"),
        # cela a déjà été couvert par les patterns ci-dessus.
        # Les questions générales ne déclenchent pas par défaut.

        return False

    def _is_general_question(self, text_lower: str) -> bool:
        """Détecte si c'est une question générale (pas une interpellation spécifique)"""
        
        # Patterns de questions générales
        general_question_patterns = [
            r"que\s+pensez-vous",
            r"comment\s+réagissez-vous",
            r"qu'en\s+dites-vous",
            r"votre\s+avis",
            r"votre\s+opinion",
            r"pouvez-vous\s+expliquer",
            r"pourriez-vous\s+préciser",
            r"avez-vous\s+une\s+réponse",
            r"que\s+répondez-vous",
            r"comment\s+expliquez-vous",
            r"qu'est-ce\s+que\s+vous\s+en\s+pensez",
            r"que\s+diriez-vous",
            r"comment\s+analysez-vous",
            r"votre\s+réaction",
            r"votre\s+position",
        ]

        # Vérifier si le texte contient une question générale
        for pattern in general_question_patterns:
            if re.search(pattern, text_lower):
                return True

        return False

    def classify_address_type(self, text: str, agent_id: str) -> str:
        """Classifie le type d'interpellation pour optimiser la réponse"""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ["pensez", "opinion", "avis", "crois"]):
            return "opinion_request"
        elif any(word in text_lower for word in ["pouvez", "pourriez", "pouvez-vous"]):
            return "action_request"
        elif any(word in text_lower for word in ["expliquez", "précisez", "comment", "pourquoi"]):
            return "explanation_request"
        elif any(word in text_lower for word in ["que", "qu'en", "dites"]):
            return "general_address"
        else:
            return "direct_address"

    def detect_with_animator_authority(self, message: str, speaker: str) -> dict:
        """
        Détection étendue incluant l'autorité de l'animateur
        """
        # 1. Vérifier d'abord les interpellations directes classiques
        direct_address = self.detect_direct_addresses(message, {})
        if direct_address:
            return {
                'detected': True,
                'agent': direct_address[0] if direct_address else None,
                'confidence': 0.90,
                'type': 'direct_address',
                'priority': 'HIGH'
            }
        
        # 2. Si pas d'interpellation directe, vérifier l'autorité animateur
        if speaker == "animateur_principal":
            try:
                from animator_authority_detector import AnimatorAuthorityDetector
                animator_detector = AnimatorAuthorityDetector()
                directive = animator_detector.detect_animator_directive(message, speaker)
                
                if directive:
                    return {
                        'detected': True,
                        'agent': directive.get('target_agent'),
                        'confidence': 0.75,
                        'type': 'animator_directive',
                        'priority': 'MEDIUM',
                        'directive': directive
                    }
            except ImportError:
                logger.debug("AnimatorAuthorityDetector non disponible")
        
        return {
            'detected': False,
            'confidence': 0.0,
            'type': 'none',
            'priority': 'LOW'
        }


