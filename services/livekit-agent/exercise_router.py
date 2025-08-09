"""
Router Intelligent pour les Exercices Eloquence
Corrige le problème de confusion entre agents individuels et multi-agents
"""
import logging
from typing import Dict, Any, Tuple, Optional
from enum import Enum
from dataclasses import dataclass

logger = logging.getLogger(__name__)


class ExerciseType(Enum):
    """Types d'exercices supportés"""
    INDIVIDUAL = "individual"  # Un seul agent IA
    MULTI_AGENT = "multi_agent"  # Plusieurs agents qui interagissent


@dataclass
class ExerciseRoute:
    """Configuration de routage pour un exercice"""
    exercise_id: str
    exercise_type: ExerciseType
    handler_module: str  # "main" ou "multi_agent_main"
    description: str


class ExerciseRouter:
    """Router intelligent pour diriger les exercices vers le bon système"""
    
    # Configuration des exercices avec leur type correct
    EXERCISE_ROUTES: Dict[str, ExerciseRoute] = {
        # ========== EXERCICES INDIVIDUELS ==========
        'confidence_boost': ExerciseRoute(
            exercise_id='confidence_boost',
            exercise_type=ExerciseType.INDIVIDUAL,
            handler_module='main',
            description='Coaching individuel pour renforcer la confiance'
        ),
        
        'tribunal_idees_impossibles': ExerciseRoute(
            exercise_id='tribunal_idees_impossibles',
            exercise_type=ExerciseType.INDIVIDUAL,
            handler_module='main',
            description='Défense d\'idées impossibles devant un juge magistrat'
        ),
        
        'cosmic_voice_control': ExerciseRoute(
            exercise_id='cosmic_voice_control',
            exercise_type=ExerciseType.INDIVIDUAL,
            handler_module='main',
            description='Contrôle vocal cosmique'
        ),
        
        'job_interview': ExerciseRoute(
            exercise_id='job_interview',
            exercise_type=ExerciseType.INDIVIDUAL,
            handler_module='main',
            description='Entretien d\'embauche individuel avec coach IA'
        ),
        
        # ========== EXERCICES MULTI-AGENTS ==========
        'studio_debate_tv': ExerciseRoute(
            exercise_id='studio_debate_tv',
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Débat télévisé avec animateur, journaliste et expert'
        ),
        
        'studio_debatPlateau': ExerciseRoute(
            exercise_id='studio_debate_tv',  # Même config que studio_debate_tv
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Débat plateau TV (alias français)'
        ),
        
        'studio_job_interview': ExerciseRoute(
            exercise_id='studio_job_interview',
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Entretien d\'embauche avec RH et expert technique'
        ),
        
        'studio_entretienEmbauche': ExerciseRoute(
            exercise_id='studio_job_interview',  # Même config
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Entretien d\'embauche multi-agents (alias français)'
        ),
        
        'studio_boardroom': ExerciseRoute(
            exercise_id='studio_boardroom',
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Réunion de direction avec PDG et directeur financier'
        ),
        
        'studio_reunionDirection': ExerciseRoute(
            exercise_id='studio_boardroom',  # Même config
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Réunion de direction (alias français)'
        ),
        
        'studio_sales_conference': ExerciseRoute(
            exercise_id='studio_sales_conference',
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Conférence de vente avec client et partenaire technique'
        ),
        
        'studio_conferenceVente': ExerciseRoute(
            exercise_id='studio_sales_conference',  # Même config
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Conférence de vente (alias français)'
        ),
        
        'studio_keynote': ExerciseRoute(
            exercise_id='studio_keynote',
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Conférence publique avec modératrice et expert audience'
        ),
        
        'studio_conferencePublique': ExerciseRoute(
            exercise_id='studio_keynote',  # Même config
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Conférence publique (alias français)'
        ),
        
        # ========== EXERCICE GÉNÉRIQUE (PROBLÉMATIQUE) ==========
        'studio_situations_pro': ExerciseRoute(
            exercise_id='studio_situations_pro',
            exercise_type=ExerciseType.MULTI_AGENT,
            handler_module='multi_agent_main',
            description='Exercice générique - ATTENTION: Devrait être plus spécifique'
        ),
    }
    
    @classmethod
    def route_exercise(cls, exercise_type: str, user_data: Dict[str, Any] = None) -> Tuple[ExerciseRoute, Dict[str, Any]]:
        """
        Route un exercice vers le bon système
        
        Args:
            exercise_type: Type d'exercice demandé
            user_data: Données utilisateur optionnelles
            
        Returns:
            Tuple[ExerciseRoute, Dict]: Route et données utilisateur
        """
        logger.info(f"🎯 ROUTAGE EXERCICE: '{exercise_type}'")
        
        # Données utilisateur par défaut
        if user_data is None:
            user_data = {
                'user_name': 'Participant',
                'user_subject': 'votre présentation'
            }
        
        # Recherche de la route
        if exercise_type in cls.EXERCISE_ROUTES:
            route = cls.EXERCISE_ROUTES[exercise_type]
            logger.info(f"✅ Route trouvée: {route.exercise_type.value} → {route.handler_module}")
            logger.info(f"   Description: {route.description}")
            return route, user_data
        else:
            # Fallback vers confidence_boost pour les exercices inconnus
            logger.warning(f"⚠️ Exercice inconnu '{exercise_type}', fallback vers confidence_boost")
            route = cls.EXERCISE_ROUTES['confidence_boost']
            return route, user_data
    
    @classmethod
    def is_multi_agent_exercise(cls, exercise_type: str) -> bool:
        """Vérifie si un exercice nécessite le système multi-agents"""
        route, _ = cls.route_exercise(exercise_type)
        return route.exercise_type == ExerciseType.MULTI_AGENT
    
    @classmethod
    def is_individual_exercise(cls, exercise_type: str) -> bool:
        """Vérifie si un exercice est individuel"""
        route, _ = cls.route_exercise(exercise_type)
        return route.exercise_type == ExerciseType.INDIVIDUAL
    
    @classmethod
    def get_handler_module(cls, exercise_type: str) -> str:
        """Retourne le module handler approprié"""
        route, _ = cls.route_exercise(exercise_type)
        return route.handler_module
    
    @classmethod
    def list_exercises_by_type(cls, exercise_type: ExerciseType) -> Dict[str, ExerciseRoute]:
        """Liste tous les exercices d'un type donné"""
        return {
            key: route for key, route in cls.EXERCISE_ROUTES.items()
            if route.exercise_type == exercise_type
        }
    
    @classmethod
    def validate_exercise_consistency(cls) -> Dict[str, Any]:
        """Valide la cohérence de la configuration des exercices"""
        validation_report = {
            'total_exercises': len(cls.EXERCISE_ROUTES),
            'individual_count': 0,
            'multi_agent_count': 0,
            'issues': [],
            'recommendations': []
        }
        
        for exercise_id, route in cls.EXERCISE_ROUTES.items():
            if route.exercise_type == ExerciseType.INDIVIDUAL:
                validation_report['individual_count'] += 1
            else:
                validation_report['multi_agent_count'] += 1
            
            # Vérifications spécifiques
            if exercise_id == 'studio_situations_pro':
                validation_report['issues'].append(
                    "studio_situations_pro est trop générique - devrait être plus spécifique"
                )
                validation_report['recommendations'].append(
                    "Remplacer studio_situations_pro par des exercices spécifiques"
                )
        
        logger.info(f"📊 VALIDATION EXERCICES:")
        logger.info(f"   Total: {validation_report['total_exercises']}")
        logger.info(f"   Individuels: {validation_report['individual_count']}")
        logger.info(f"   Multi-agents: {validation_report['multi_agent_count']}")
        
        if validation_report['issues']:
            logger.warning(f"⚠️ Problèmes détectés: {len(validation_report['issues'])}")
            for issue in validation_report['issues']:
                logger.warning(f"   - {issue}")
        
        return validation_report


# Fonction utilitaire pour l'intégration
def get_exercise_route(exercise_type: str, user_data: Dict[str, Any] = None) -> Tuple[ExerciseRoute, Dict[str, Any]]:
    """Fonction utilitaire pour obtenir la route d'un exercice"""
    return ExerciseRouter.route_exercise(exercise_type, user_data)


# Test de validation au chargement du module
if __name__ == "__main__":
    # Validation automatique
    report = ExerciseRouter.validate_exercise_consistency()
    print("Rapport de validation:", report)
    
    # Tests de routage
    test_exercises = [
        'confidence_boost',
        'tribunal_idees_impossibles', 
        'studio_debate_tv',
        'studio_job_interview',
        'exercice_inexistant'
    ]
    
    for exercise in test_exercises:
        route, data = ExerciseRouter.route_exercise(exercise)
        print(f"{exercise} → {route.exercise_type.value} ({route.handler_module})")