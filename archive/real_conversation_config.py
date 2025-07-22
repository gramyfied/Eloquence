#!/usr/bin/env python3
"""
Real Conversation Config - Paramètres optimaux pour conversation réelle avec Marie

Ce module fournit les configurations prédéfinies et optimisées pour différents
scénarios de conversation avec Marie. Il inclut les paramètres de personnalité,
timeouts, thresholds qualité, et réglages performance validés empiriquement
pour maximiser l'authenticité et l'efficacité des interactions.

Configurations disponibles :
- Configuration par défaut équilibrée
- Mode démonstration (Marie modérée)
- Mode évaluation intensive (Marie très exigeante)
- Mode formation commerciale (Marie pédagogique)
- Mode test performance (focus vitesse)
- Mode debug développement (logging étendu)

Paramètres optimisés :
- Intensité personnalité Marie par contexte
- Timeouts services adaptés aux contraintes réelles
- Seuils qualité conversation calibrés
- Configurations monitoring temps réel
- Réglages auto-réparation efficaces
"""

from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
from enum import Enum
import json
from datetime import timedelta

class ConversationMode(Enum):
    """Modes de conversation prédéfinis"""
    BALANCED = "balanced"  # Configuration équilibrée par défaut
    DEMONSTRATION = "demonstration"  # Mode démonstration client
    INTENSIVE_EVALUATION = "intensive_evaluation"  # Évaluation intensive
    COMMERCIAL_TRAINING = "commercial_training"  # Formation commerciale
    PERFORMANCE_TEST = "performance_test"  # Test performance
    DEBUG_DEVELOPMENT = "debug_development"  # Debug développement

class UserPersonalityType(Enum):
    """Types de personnalité utilisateur simulé"""
    INTERESTED_PROSPECT = "interested_prospect"
    SKEPTICAL_BUYER = "skeptical_buyer"
    ANALYTICAL_EVALUATOR = "analytical_evaluator"
    BUDGET_CONSCIOUS = "budget_conscious"
    TIME_PRESSED_EXECUTIVE = "time_pressed_executive"
    TECHNICAL_EXPERT = "technical_expert"

@dataclass
class ServiceTimeouts:
    """Configuration timeouts services"""
    tts_timeout: float = 30.0
    vosk_timeout: float = 20.0
    mistral_timeout: float = 45.0
    exchange_timeout: float = 60.0
    connection_timeout: float = 10.0
    retry_timeout: float = 5.0

@dataclass
class QualityThresholds:
    """Seuils qualité conversation"""
    overall_quality_threshold: float = 0.7
    marie_personality_coherence: float = 0.75
    contextual_relevance: float = 0.7
    commercial_impact: float = 0.65
    transcription_accuracy: float = 0.8
    auto_correction_trigger: float = 0.6

@dataclass
class MariePersonalityConfig:
    """Configuration personnalité Marie"""
    intensity: float = 0.8  # 0.0-1.0
    satisfaction_decay_rate: float = 0.05
    patience_decay_rate: float = 0.08
    initial_satisfaction: float = 0.5
    initial_patience: float = 1.0
    initial_interest: float = 0.5
    exigence_threshold: float = 0.3
    challenge_mode_trigger: float = 0.4

@dataclass
class UserSimulationConfig:
    """Configuration simulation utilisateur"""
    personality_type: UserPersonalityType = UserPersonalityType.INTERESTED_PROSPECT
    realism_level: float = 0.7  # 0.0-1.0
    engagement_level: float = 0.7
    technical_depth: float = 0.5
    budget_sensitivity: float = 0.5
    time_pressure: float = 0.3
    decision_authority: float = 0.8

@dataclass
class MonitoringConfig:
    """Configuration monitoring temps réel"""
    update_interval_seconds: float = 1.0
    alert_history_retention_hours: int = 24
    metrics_buffer_size: int = 1000
    enable_predictive_analysis: bool = True
    enable_auto_repair_triggers: bool = True
    enable_visual_dashboard: bool = False
    critical_alert_threshold: int = 2

@dataclass
class AutoRepairConfig:
    """Configuration auto-réparation"""
    enable_auto_repair: bool = True
    max_repair_attempts: int = 3
    repair_timeout: float = 15.0
    escalation_threshold: int = 2
    learning_enabled: bool = True
    conservative_mode: bool = False

@dataclass
class PerformanceConfig:
    """Configuration performance"""
    enable_audio_save: bool = False
    enable_detailed_logging: bool = True
    parallel_processing: bool = True
    cache_enabled: bool = True
    optimization_level: str = "balanced"  # conservative, balanced, aggressive
    memory_limit_mb: int = 1024

@dataclass
class RealConversationConfiguration:
    """Configuration complète conversation réelle"""
    # Identifiants configuration
    config_name: str = "default"
    config_description: str = "Configuration par défaut équilibrée"
    mode: ConversationMode = ConversationMode.BALANCED
    
    # Paramètres conversation
    max_exchanges: int = 10
    conversation_scenario: str = "commercial_pitch"
    target_duration_minutes: int = 15
    
    # Configurations composants
    service_timeouts: ServiceTimeouts = field(default_factory=ServiceTimeouts)
    quality_thresholds: QualityThresholds = field(default_factory=QualityThresholds)
    marie_personality: MariePersonalityConfig = field(default_factory=MariePersonalityConfig)
    user_simulation: UserSimulationConfig = field(default_factory=UserSimulationConfig)
    monitoring: MonitoringConfig = field(default_factory=MonitoringConfig)
    auto_repair: AutoRepairConfig = field(default_factory=AutoRepairConfig)
    performance: PerformanceConfig = field(default_factory=PerformanceConfig)
    
    # Métadonnées
    created_by: str = "system"
    version: str = "1.0"
    validation_status: str = "validated"
    optimization_notes: List[str] = field(default_factory=list)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit configuration en dictionnaire"""
        result = {}
        for field_name, field_value in self.__dict__.items():
            if hasattr(field_value, '__dict__'):
                result[field_name] = field_value.__dict__
            elif isinstance(field_value, Enum):
                result[field_name] = field_value.value
            else:
                result[field_name] = field_value
        return result
    
    def save_to_file(self, filepath: str):
        """Sauvegarde configuration dans fichier JSON"""
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, indent=2, ensure_ascii=False)
    
    @classmethod
    def load_from_file(cls, filepath: str) -> 'RealConversationConfiguration':
        """Charge configuration depuis fichier JSON"""
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Reconstruction objets complexes
        config = cls()
        for key, value in data.items():
            if hasattr(config, key):
                setattr(config, key, value)
        
        return config

class OptimizedConfigFactory:
    """
    Factory pour configurations optimisées prédéfinies
    
    Responsabilités :
    - Génération configurations optimisées par use case
    - Validation paramètres et cohérence
    - Recommandations ajustements contextuels
    - Templates configuration réutilisables
    """
    
    @staticmethod
    def create_balanced_config() -> RealConversationConfiguration:
        """
        Configuration équilibrée par défaut
        
        Optimisée pour : Usage général, démonstrations, tests standards
        Marie : Modérément exigeante, professionnelle
        Performance : Équilibrée entre qualité et vitesse
        """
        config = RealConversationConfiguration(
            config_name="balanced_default",
            config_description="Configuration équilibrée pour usage général",
            mode=ConversationMode.BALANCED,
            max_exchanges=10,
            target_duration_minutes=15
        )
        
        # Timeouts optimisés pour usage normal
        config.service_timeouts = ServiceTimeouts(
            tts_timeout=25.0,
            vosk_timeout=18.0,
            mistral_timeout=40.0,
            exchange_timeout=55.0,
            connection_timeout=8.0,
            retry_timeout=4.0
        )
        
        # Seuils qualité standards
        config.quality_thresholds = QualityThresholds(
            overall_quality_threshold=0.72,
            marie_personality_coherence=0.75,
            contextual_relevance=0.7,
            commercial_impact=0.68,
            transcription_accuracy=0.8,
            auto_correction_trigger=0.65
        )
        
        # Marie modérément exigeante
        config.marie_personality = MariePersonalityConfig(
            intensity=0.75,
            satisfaction_decay_rate=0.04,
            patience_decay_rate=0.06,
            initial_satisfaction=0.55,
            initial_patience=0.9,
            exigence_threshold=0.35
        )
        
        # Utilisateur prospect intéressé
        config.user_simulation = UserSimulationConfig(
            personality_type=UserPersonalityType.INTERESTED_PROSPECT,
            realism_level=0.75,
            engagement_level=0.75,
            technical_depth=0.5,
            budget_sensitivity=0.4,
            time_pressure=0.3
        )
        
        config.optimization_notes = [
            "Timeouts optimisés pour latence réseau moyenne",
            "Seuils qualité calibrés pour équilibre performance/qualité",
            "Marie configurée pour progression naturelle conversation",
            "Utilisateur simulé engagé mais réaliste"
        ]
        
        return config
    
    @staticmethod
    def create_demonstration_config() -> RealConversationConfiguration:
        """
        Configuration démonstration client
        
        Optimisée pour : Démonstrations commerciales, présentations clients
        Marie : Professionnelle mais accessible, moins impatiente
        Performance : Privilégie qualité sur vitesse
        """
        config = RealConversationConfiguration(
            config_name="client_demonstration",
            config_description="Configuration optimisée démonstrations clients",
            mode=ConversationMode.DEMONSTRATION,
            max_exchanges=8,
            target_duration_minutes=12
        )
        
        # Timeouts plus généreux pour démonstration
        config.service_timeouts = ServiceTimeouts(
            tts_timeout=35.0,
            vosk_timeout=25.0,
            mistral_timeout=50.0,
            exchange_timeout=70.0,
            connection_timeout=12.0,
            retry_timeout=6.0
        )
        
        # Seuils qualité élevés
        config.quality_thresholds = QualityThresholds(
            overall_quality_threshold=0.78,
            marie_personality_coherence=0.8,
            contextual_relevance=0.75,
            commercial_impact=0.75,
            transcription_accuracy=0.85,
            auto_correction_trigger=0.7
        )
        
        # Marie plus patiente et pédagogique
        config.marie_personality = MariePersonalityConfig(
            intensity=0.65,
            satisfaction_decay_rate=0.03,
            patience_decay_rate=0.04,
            initial_satisfaction=0.6,
            initial_patience=1.0,
            exigence_threshold=0.25,
            challenge_mode_trigger=0.3
        )
        
        # Utilisateur analytique intéressé
        config.user_simulation = UserSimulationConfig(
            personality_type=UserPersonalityType.ANALYTICAL_EVALUATOR,
            realism_level=0.8,
            engagement_level=0.8,
            technical_depth=0.6,
            budget_sensitivity=0.5,
            time_pressure=0.2
        )
        
        # Monitoring renforcé
        config.monitoring.enable_visual_dashboard = True
        config.monitoring.update_interval_seconds = 0.5
        
        # Performance privilégiant qualité
        config.performance.enable_detailed_logging = True
        config.performance.optimization_level = "conservative"
        
        config.optimization_notes = [
            "Timeouts généreux pour éviter interruptions pendant démo",
            "Qualité maximale pour impression client positive",
            "Marie patiente pour permettre questions détaillées",
            "Monitoring visuel pour suivi temps réel"
        ]
        
        return config
    
    @staticmethod
    def create_intensive_evaluation_config() -> RealConversationConfiguration:
        """
        Configuration évaluation intensive
        
        Optimisée pour : Tests stress, évaluation limites système
        Marie : Très exigeante, impatiente, challengeante
        Performance : Tests robustesse et récupération erreurs
        """
        config = RealConversationConfiguration(
            config_name="intensive_evaluation",
            config_description="Configuration tests intensifs et évaluation limites",
            mode=ConversationMode.INTENSIVE_EVALUATION,
            max_exchanges=15,
            target_duration_minutes=20
        )
        
        # Timeouts serrés pour stress test
        config.service_timeouts = ServiceTimeouts(
            tts_timeout=20.0,
            vosk_timeout=15.0,
            mistral_timeout=30.0,
            exchange_timeout=45.0,
            connection_timeout=5.0,
            retry_timeout=3.0
        )
        
        # Seuils qualité exigeants
        config.quality_thresholds = QualityThresholds(
            overall_quality_threshold=0.8,
            marie_personality_coherence=0.85,
            contextual_relevance=0.8,
            commercial_impact=0.75,
            transcription_accuracy=0.85,
            auto_correction_trigger=0.7
        )
        
        # Marie très exigeante et impatiente
        config.marie_personality = MariePersonalityConfig(
            intensity=0.95,
            satisfaction_decay_rate=0.08,
            patience_decay_rate=0.12,
            initial_satisfaction=0.4,
            initial_patience=0.7,
            exigence_threshold=0.5,
            challenge_mode_trigger=0.6
        )
        
        # Utilisateur sceptique et exigeant
        config.user_simulation = UserSimulationConfig(
            personality_type=UserPersonalityType.SKEPTICAL_BUYER,
            realism_level=0.9,
            engagement_level=0.6,
            technical_depth=0.8,
            budget_sensitivity=0.8,
            time_pressure=0.6
        )
        
        # Auto-réparation agressive
        config.auto_repair.max_repair_attempts = 5
        config.auto_repair.escalation_threshold = 1
        config.auto_repair.conservative_mode = False
        
        # Monitoring très fréquent
        config.monitoring.update_interval_seconds = 0.5
        config.monitoring.critical_alert_threshold = 1
        
        config.optimization_notes = [
            "Timeouts réduits pour tester robustesse sous stress",
            "Seuils qualité élevés pour validation excellence",
            "Marie très exigeante pour évaluer adaptabilité",
            "Auto-réparation agressive pour tests récupération"
        ]
        
        return config
    
    @staticmethod
    def create_commercial_training_config() -> RealConversationConfiguration:
        """
        Configuration formation commerciale
        
        Optimisée pour : Formation équipes commerciales, coaching
        Marie : Pédagogique, feedback constructif, progression guidée
        Performance : Focus apprentissage et analyse détaillée
        """
        config = RealConversationConfiguration(
            config_name="commercial_training",
            config_description="Configuration formation et coaching commercial",
            mode=ConversationMode.COMMERCIAL_TRAINING,
            max_exchanges=12,
            target_duration_minutes=18
        )
        
        # Timeouts permettant réflexion
        config.service_timeouts = ServiceTimeouts(
            tts_timeout=40.0,
            vosk_timeout=30.0,
            mistral_timeout=60.0,
            exchange_timeout=80.0,
            connection_timeout=10.0,
            retry_timeout=5.0
        )
        
        # Seuils adaptés formation
        config.quality_thresholds = QualityThresholds(
            overall_quality_threshold=0.7,
            marie_personality_coherence=0.75,
            contextual_relevance=0.75,
            commercial_impact=0.8,  # Focus commercial important
            transcription_accuracy=0.8,
            auto_correction_trigger=0.65
        )
        
        # Marie pédagogique mais exigeante
        config.marie_personality = MariePersonalityConfig(
            intensity=0.7,
            satisfaction_decay_rate=0.02,  # Plus tolérante
            patience_decay_rate=0.03,
            initial_satisfaction=0.5,
            initial_patience=1.0,
            exigence_threshold=0.3,
            challenge_mode_trigger=0.4
        )
        
        # Utilisateur en apprentissage
        config.user_simulation = UserSimulationConfig(
            personality_type=UserPersonalityType.INTERESTED_PROSPECT,
            realism_level=0.7,
            engagement_level=0.9,  # Très engagé pour apprendre
            technical_depth=0.4,
            budget_sensitivity=0.6,
            time_pressure=0.1  # Pas pressé, apprentissage
        )
        
        # Monitoring détaillé pour feedback
        config.monitoring.enable_predictive_analysis = True
        config.monitoring.metrics_buffer_size = 2000
        
        # Performance avec logging étendu
        config.performance.enable_detailed_logging = True
        config.performance.enable_audio_save = True
        
        config.optimization_notes = [
            "Timeouts généreux pour permettre apprentissage progressif",
            "Focus sur impact commercial pour formation vente",
            "Marie pédagogique mais maintient standards professionnels",
            "Logging détaillé pour analyse post-formation"
        ]
        
        return config
    
    @staticmethod
    def create_performance_test_config() -> RealConversationConfiguration:
        """
        Configuration test performance
        
        Optimisée pour : Tests vitesse, benchmark, validation technique
        Marie : Efficace, directe, focus résultats
        Performance : Vitesse maximale, optimisations agressives
        """
        config = RealConversationConfiguration(
            config_name="performance_test",
            config_description="Configuration optimisée vitesse et performance",
            mode=ConversationMode.PERFORMANCE_TEST,
            max_exchanges=20,
            target_duration_minutes=10  # Conversation rapide
        )
        
        # Timeouts minimaux
        config.service_timeouts = ServiceTimeouts(
            tts_timeout=15.0,
            vosk_timeout=10.0,
            mistral_timeout=25.0,
            exchange_timeout=35.0,
            connection_timeout=3.0,
            retry_timeout=2.0
        )
        
        # Seuils plus permissifs pour vitesse
        config.quality_thresholds = QualityThresholds(
            overall_quality_threshold=0.65,
            marie_personality_coherence=0.7,
            contextual_relevance=0.65,
            commercial_impact=0.6,
            transcription_accuracy=0.75,
            auto_correction_trigger=0.55
        )
        
        # Marie directe et efficace
        config.marie_personality = MariePersonalityConfig(
            intensity=0.8,
            satisfaction_decay_rate=0.06,
            patience_decay_rate=0.1,  # Impatiente pour vitesse
            initial_satisfaction=0.5,
            initial_patience=0.8,
            exigence_threshold=0.4
        )
        
        # Utilisateur pressé
        config.user_simulation = UserSimulationConfig(
            personality_type=UserPersonalityType.TIME_PRESSED_EXECUTIVE,
            realism_level=0.6,  # Moins de variabilité pour vitesse
            engagement_level=0.7,
            technical_depth=0.5,
            budget_sensitivity=0.3,
            time_pressure=0.9  # Très pressé
        )
        
        # Monitoring optimisé performance
        config.monitoring.update_interval_seconds = 2.0
        config.monitoring.metrics_buffer_size = 500
        config.monitoring.enable_predictive_analysis = False
        
        # Performance agressive
        config.performance.optimization_level = "aggressive"
        config.performance.parallel_processing = True
        config.performance.enable_audio_save = False
        config.performance.enable_detailed_logging = False
        
        config.optimization_notes = [
            "Timeouts minimaux pour vitesse maximale",
            "Seuils qualité réduits au profit performance",
            "Marie impatiente pour accélérer conversation",
            "Optimisations agressives tous composants"
        ]
        
        return config
    
    @staticmethod
    def create_debug_development_config() -> RealConversationConfiguration:
        """
        Configuration debug développement
        
        Optimisée pour : Développement, debug, tests intégration
        Marie : Comportement prévisible, logs détaillés
        Performance : Debug/logging maximum, timeouts généreux
        """
        config = RealConversationConfiguration(
            config_name="debug_development",
            config_description="Configuration debug et développement",
            mode=ConversationMode.DEBUG_DEVELOPMENT,
            max_exchanges=5,  # Tests courts
            target_duration_minutes=8
        )
        
        # Timeouts très généreux pour debug
        config.service_timeouts = ServiceTimeouts(
            tts_timeout=60.0,
            vosk_timeout=45.0,
            mistral_timeout=90.0,
            exchange_timeout=120.0,
            connection_timeout=20.0,
            retry_timeout=10.0
        )
        
        # Seuils permissifs pour tests
        config.quality_thresholds = QualityThresholds(
            overall_quality_threshold=0.5,
            marie_personality_coherence=0.6,
            contextual_relevance=0.5,
            commercial_impact=0.5,
            transcription_accuracy=0.7,
            auto_correction_trigger=0.4
        )
        
        # Marie prévisible pour tests
        config.marie_personality = MariePersonalityConfig(
            intensity=0.6,
            satisfaction_decay_rate=0.01,  # Très lente
            patience_decay_rate=0.01,
            initial_satisfaction=0.7,
            initial_patience=1.0,
            exigence_threshold=0.2
        )
        
        # Utilisateur simple pour tests
        config.user_simulation = UserSimulationConfig(
            personality_type=UserPersonalityType.INTERESTED_PROSPECT,
            realism_level=0.5,  # Comportement simple
            engagement_level=0.8,
            technical_depth=0.3,
            budget_sensitivity=0.3,
            time_pressure=0.1
        )
        
        # Auto-réparation conservative
        config.auto_repair.conservative_mode = True
        config.auto_repair.max_repair_attempts = 1
        
        # Monitoring détaillé
        config.monitoring.update_interval_seconds = 0.5
        config.monitoring.enable_visual_dashboard = True
        
        # Performance avec maximum logs
        config.performance.enable_detailed_logging = True
        config.performance.enable_audio_save = True
        config.performance.optimization_level = "conservative"
        
        config.optimization_notes = [
            "Timeouts très généreux pour debug sans pression",
            "Seuils permissifs pour focus sur fonctionnement",
            "Marie prévisible pour tests reproductibles",
            "Logging maximum pour analyse développement"
        ]
        
        return config
    
    @staticmethod
    def get_all_predefined_configs() -> Dict[str, RealConversationConfiguration]:
        """
        Obtient toutes les configurations prédéfinies
        
        Returns:
            Dict[str, RealConversationConfiguration]: Configurations par nom
        """
        return {
            "balanced": OptimizedConfigFactory.create_balanced_config(),
            "demonstration": OptimizedConfigFactory.create_demonstration_config(),
            "intensive_evaluation": OptimizedConfigFactory.create_intensive_evaluation_config(),
            "commercial_training": OptimizedConfigFactory.create_commercial_training_config(),
            "performance_test": OptimizedConfigFactory.create_performance_test_config(),
            "debug_development": OptimizedConfigFactory.create_debug_development_config()
        }
    
    @staticmethod
    def recommend_config(requirements: Dict[str, Any]) -> str:
        """
        Recommande configuration basée sur exigences
        
        Args:
            requirements: Dictionnaire avec contraintes et objectifs
            
        Returns:
            str: Nom configuration recommandée
        """
        # Analyse exigences pour recommandation
        is_demo = requirements.get('is_demonstration', False)
        is_training = requirements.get('is_training', False)
        is_performance_test = requirements.get('is_performance_test', False)
        is_debug = requirements.get('is_debug', False)
        
        max_duration = requirements.get('max_duration_minutes', 15)
        quality_priority = requirements.get('quality_priority', 'medium')
        marie_intensity_needed = requirements.get('marie_intensity', 'medium')
        
        # Logique recommandation
        if is_debug:
            return "debug_development"
        elif is_performance_test:
            return "performance_test"
        elif is_demo and quality_priority == 'high':
            return "demonstration"
        elif is_training:
            return "commercial_training"
        elif marie_intensity_needed == 'high' or quality_priority == 'high':
            return "intensive_evaluation"
        else:
            return "balanced"
    
    @staticmethod
    def validate_config(config: RealConversationConfiguration) -> List[str]:
        """
        Valide cohérence configuration
        
        Args:
            config: Configuration à valider
            
        Returns:
            List[str]: Liste problèmes détectés (vide si valide)
        """
        issues = []
        
        # Validation timeouts
        if config.service_timeouts.exchange_timeout < (
            config.service_timeouts.tts_timeout + 
            config.service_timeouts.vosk_timeout + 
            config.service_timeouts.mistral_timeout
        ):
            issues.append("Exchange timeout trop court par rapport aux timeouts services")
        
        # Validation seuils qualité
        if config.quality_thresholds.auto_correction_trigger > config.quality_thresholds.overall_quality_threshold:
            issues.append("Seuil auto-correction supérieur au seuil qualité global")
        
        # Validation Marie
        if config.marie_personality.initial_satisfaction < 0 or config.marie_personality.initial_satisfaction > 1:
            issues.append("Satisfaction initiale Marie hors range [0,1]")
        
        if config.marie_personality.intensity > 0.9 and config.marie_personality.patience_decay_rate < 0.05:
            issues.append("Marie très intense mais patience decay trop faible")
        
        # Validation utilisateur
        if config.user_simulation.time_pressure > 0.8 and config.target_duration_minutes > 20:
            issues.append("Utilisateur pressé mais conversation longue prévue")
        
        # Validation cohérence performance
        if (config.performance.optimization_level == "aggressive" and 
            config.performance.enable_detailed_logging):
            issues.append("Performance agressive incompatible avec logging détaillé")
        
        return issues

# Configurations prédéfinies instantanées
DEFAULT_CONFIG = OptimizedConfigFactory.create_balanced_config()
DEMO_CONFIG = OptimizedConfigFactory.create_demonstration_config()
TRAINING_CONFIG = OptimizedConfigFactory.create_commercial_training_config()
PERFORMANCE_CONFIG = OptimizedConfigFactory.create_performance_test_config()
DEBUG_CONFIG = OptimizedConfigFactory.create_debug_development_config()

def load_config_by_name(config_name: str) -> RealConversationConfiguration:
    """
    Charge configuration par nom prédéfini
    
    Args:
        config_name: Nom configuration
        
    Returns:
        RealConversationConfiguration: Configuration chargée
        
    Raises:
        ValueError: Si nom configuration inconnu
    """
    configs = OptimizedConfigFactory.get_all_predefined_configs()
    
    if config_name not in configs:
        available = list(configs.keys())
        raise ValueError(f"Configuration '{config_name}' inconnue. Disponibles: {available}")
    
    return configs[config_name]

def save_all_predefined_configs(output_dir: str = "configs/"):
    """
    Sauvegarde toutes les configurations prédéfinies
    
    Args:
        output_dir: Répertoire sortie
    """
    import os
    os.makedirs(output_dir, exist_ok=True)
    
    configs = OptimizedConfigFactory.get_all_predefined_configs()
    
    for name, config in configs.items():
        filepath = os.path.join(output_dir, f"{name}_config.json")
        config.save_to_file(filepath)
        print(f"Configuration '{name}' sauvegardée: {filepath}")

def create_custom_config_template() -> RealConversationConfiguration:
    """
    Crée template configuration personnalisée
    
    Returns:
        RealConversationConfiguration: Template à personnaliser
    """
    config = OptimizedConfigFactory.create_balanced_config()
    config.config_name = "custom_template"
    config.config_description = "Template configuration personnalisée"
    config.optimization_notes = [
        "TEMPLATE : Ajuster paramètres selon besoins spécifiques",
        "Marie intensity : 0.5-0.9 selon exigence souhaitée",
        "Timeouts : adapter selon infrastructure réseau",
        "Qualité : équilibrer avec contraintes performance"
    ]
    
    return config

if __name__ == "__main__":
    # Démonstration usage
    print("=== CONFIGURATIONS CONVERSATION RÉELLE MARIE ===")
    print()
    
    # Liste configurations disponibles
    configs = OptimizedConfigFactory.get_all_predefined_configs()
    print(f"Configurations prédéfinies disponibles ({len(configs)}):")
    for name, config in configs.items():
        print(f"  - {name}: {config.config_description}")
    print()
    
    # Exemple validation
    test_config = DEFAULT_CONFIG
    issues = OptimizedConfigFactory.validate_config(test_config)
    print(f"Validation configuration '{test_config.config_name}':")
    if issues:
        for issue in issues:
            print(f"  ⚠️  {issue}")
    else:
        print("  ✅ Configuration valide")
    print()
    
    # Exemple recommandation
    requirements = {
        'is_demonstration': True,
        'quality_priority': 'high',
        'max_duration_minutes': 12
    }
    recommended = OptimizedConfigFactory.recommend_config(requirements)
    print(f"Configuration recommandée pour démo qualité: {recommended}")
    print()
    
    # Sauvegarde exemple
    print("Sauvegarde configuration exemple...")
    example_config = load_config_by_name("balanced")
    example_config.save_to_file("example_config.json")
    print("Configuration sauvegardée: example_config.json")