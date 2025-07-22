#!/usr/bin/env python3
"""
Real Time Monitor - Surveillance conversation en temps réel avec Marie

Ce module assure la surveillance continue de la conversation réelle avec Marie,
détectant les anomalies, analysant les performances en temps réel et générant
des alertes instantanées pour maintenir la qualité optimale du pipeline conversationnel.

Fonctionnalités principales :
- Monitoring métriques temps réel (latence, qualité, erreurs)
- Détection anomalies instantanée avec seuils adaptatifs  
- Surveillance état personnalité Marie en continu
- Analyse performance pipeline TTS→VOSK→Mistral→TTS
- Alertes automatiques et recommandations d'optimisation
- Interface de monitoring visuelle avec graphiques temps réel
- Collecte insights conversationnels pour amélioration continue

Intégration :
- Utilisé par RealConversationManager pour monitoring continu
- Interface avec MetricsCollector pour données temps réel
- Alertes transmises à AutoRepairSystem pour correction automatique
"""

import asyncio
import threading
import time
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Callable, Set, Tuple
from dataclasses import dataclass, asdict, field
from collections import deque, defaultdict
from enum import Enum
import statistics
import math

class AlertSeverity(Enum):
    """Niveaux de sévérité des alertes"""
    INFO = "info"
    WARNING = "warning" 
    CRITICAL = "critical"
    EMERGENCY = "emergency"

class MonitoringMetric(Enum):
    """Types de métriques surveillées"""
    LATENCY_TTS = "latency_tts"
    LATENCY_VOSK = "latency_vosk"
    LATENCY_MISTRAL = "latency_mistral"
    LATENCY_TOTAL = "latency_total"
    QUALITY_TRANSCRIPTION = "quality_transcription"
    QUALITY_MARIE_RESPONSE = "quality_marie_response"
    ERROR_RATE = "error_rate"
    MARIE_SATISFACTION = "marie_satisfaction"
    MARIE_PATIENCE = "marie_patience"
    PIPELINE_SUCCESS_RATE = "pipeline_success_rate"
    CONVERSATION_COHERENCE = "conversation_coherence"
    USER_ENGAGEMENT = "user_engagement"

@dataclass
class AlertThreshold:
    """Configuration des seuils d'alerte pour une métrique"""
    metric: MonitoringMetric
    warning_threshold: float
    critical_threshold: float
    emergency_threshold: float
    evaluation_window_seconds: int = 30
    min_samples_required: int = 3
    adaptive_adjustment: bool = True

@dataclass
class RealTimeAlert:
    """Alerte générée par le monitoring temps réel"""
    alert_id: str
    timestamp: datetime
    severity: AlertSeverity
    metric: MonitoringMetric
    current_value: float
    threshold_violated: float
    message: str
    context: Dict[str, Any]
    recommendations: List[str]
    auto_repair_triggered: bool = False

@dataclass
class ConversationState:
    """État temps réel de la conversation avec Marie"""
    exchange_count: int = 0
    total_duration_seconds: float = 0.0
    current_marie_mode: str = "initial_evaluation"
    marie_satisfaction_level: float = 0.5
    marie_patience_level: float = 1.0
    marie_interest_level: float = 0.5
    last_exchange_quality: float = 0.0
    pipeline_health_score: float = 1.0
    consecutive_errors: int = 0
    conversation_coherence_score: float = 0.0
    performance_trend: str = "stable"

@dataclass
class MonitoringConfig:
    """Configuration du monitoring temps réel"""
    update_interval_seconds: float = 1.0
    alert_history_retention_hours: int = 24
    metrics_buffer_size: int = 1000
    enable_predictive_analysis: bool = True
    enable_auto_repair_triggers: bool = True
    enable_visual_dashboard: bool = False
    alert_callbacks: List[Callable] = field(default_factory=list)
    custom_thresholds: Dict[MonitoringMetric, AlertThreshold] = field(default_factory=dict)

class RealTimeMonitor:
    """
    Système de monitoring temps réel pour conversation avec Marie
    
    Responsabilités :
    - Surveillance continue métriques conversation
    - Détection anomalies temps réel avec seuils adaptatifs
    - Génération alertes automatiques avec recommandations
    - Analyse tendances performance et prédictions
    - Interface monitoring visuelle pour supervision
    - Intégration système auto-réparation pour corrections
    """
    
    def __init__(self, config: Optional[MonitoringConfig] = None):
        """
        Initialise le système de monitoring temps réel
        
        Args:
            config: Configuration monitoring personnalisée
        """
        self.config = config or MonitoringConfig()
        self.is_monitoring = False
        self.monitoring_thread = None
        self.start_time = None
        
        # État conversation temps réel
        self.conversation_state = ConversationState()
        
        # Buffers métriques circulaires pour analyse temporelle
        self.metrics_buffers = {
            metric: deque(maxlen=self.config.metrics_buffer_size) 
            for metric in MonitoringMetric
        }
        
        # Historique alertes
        self.alert_history: List[RealTimeAlert] = []
        self.active_alerts: Set[str] = set()
        
        # Seuils d'alerte par défaut
        self.alert_thresholds = self._initialize_default_thresholds()
        self.alert_thresholds.update(self.config.custom_thresholds)
        
        # Callbacks externes pour notifications
        self.alert_callbacks = self.config.alert_callbacks.copy()
        
        # Cache analyses statistiques
        self.stats_cache = {}
        self.cache_update_time = {}
        
        # Configuration logging
        self.logger = logging.getLogger(__name__)
        
        self.logger.info("RealTimeMonitor initialisé")
    
    def _initialize_default_thresholds(self) -> Dict[MonitoringMetric, AlertThreshold]:
        """
        Initialise les seuils d'alerte par défaut pour toutes les métriques
        
        Returns:
            Dict[MonitoringMetric, AlertThreshold]: Seuils configurés
        """
        return {
            MonitoringMetric.LATENCY_TTS: AlertThreshold(
                metric=MonitoringMetric.LATENCY_TTS,
                warning_threshold=15.0,  # 15 secondes
                critical_threshold=25.0,  # 25 secondes
                emergency_threshold=40.0,  # 40 secondes
                evaluation_window_seconds=30
            ),
            MonitoringMetric.LATENCY_VOSK: AlertThreshold(
                metric=MonitoringMetric.LATENCY_VOSK,
                warning_threshold=10.0,  # 10 secondes
                critical_threshold=18.0,  # 18 secondes
                emergency_threshold=30.0,  # 30 secondes
                evaluation_window_seconds=30
            ),
            MonitoringMetric.LATENCY_MISTRAL: AlertThreshold(
                metric=MonitoringMetric.LATENCY_MISTRAL,
                warning_threshold=20.0,  # 20 secondes
                critical_threshold=35.0,  # 35 secondes
                emergency_threshold=50.0,  # 50 secondes
                evaluation_window_seconds=45
            ),
            MonitoringMetric.LATENCY_TOTAL: AlertThreshold(
                metric=MonitoringMetric.LATENCY_TOTAL,
                warning_threshold=45.0,  # 45 secondes
                critical_threshold=70.0,  # 70 secondes
                emergency_threshold=100.0,  # 100 secondes
                evaluation_window_seconds=60
            ),
            MonitoringMetric.QUALITY_TRANSCRIPTION: AlertThreshold(
                metric=MonitoringMetric.QUALITY_TRANSCRIPTION,
                warning_threshold=0.7,  # 70% qualité
                critical_threshold=0.5,  # 50% qualité
                emergency_threshold=0.3,  # 30% qualité
                evaluation_window_seconds=45
            ),
            MonitoringMetric.QUALITY_MARIE_RESPONSE: AlertThreshold(
                metric=MonitoringMetric.QUALITY_MARIE_RESPONSE,
                warning_threshold=0.6,  # 60% pertinence
                critical_threshold=0.4,  # 40% pertinence
                emergency_threshold=0.2,  # 20% pertinence
                evaluation_window_seconds=60
            ),
            MonitoringMetric.ERROR_RATE: AlertThreshold(
                metric=MonitoringMetric.ERROR_RATE,
                warning_threshold=0.1,  # 10% erreurs
                critical_threshold=0.25,  # 25% erreurs
                emergency_threshold=0.5,  # 50% erreurs
                evaluation_window_seconds=120
            ),
            MonitoringMetric.MARIE_SATISFACTION: AlertThreshold(
                metric=MonitoringMetric.MARIE_SATISFACTION,
                warning_threshold=0.3,  # Satisfaction < 30%
                critical_threshold=0.15,  # Satisfaction < 15%
                emergency_threshold=0.05,  # Satisfaction < 5%
                evaluation_window_seconds=90
            ),
            MonitoringMetric.MARIE_PATIENCE: AlertThreshold(
                metric=MonitoringMetric.MARIE_PATIENCE,
                warning_threshold=0.4,  # Patience < 40%
                critical_threshold=0.2,  # Patience < 20%
                emergency_threshold=0.1,  # Patience < 10%
                evaluation_window_seconds=60
            ),
            MonitoringMetric.PIPELINE_SUCCESS_RATE: AlertThreshold(
                metric=MonitoringMetric.PIPELINE_SUCCESS_RATE,
                warning_threshold=0.8,  # 80% succès
                critical_threshold=0.6,  # 60% succès
                emergency_threshold=0.4,  # 40% succès
                evaluation_window_seconds=180
            )
        }
    
    def start_monitoring(self, conversation_manager=None):
        """
        Démarre le monitoring temps réel
        
        Args:
            conversation_manager: Manager conversation pour accès métriques
        """
        if self.is_monitoring:
            self.logger.warning("Monitoring déjà actif")
            return
        
        self.conversation_manager = conversation_manager
        self.is_monitoring = True
        self.start_time = datetime.now()
        
        # Lancement thread monitoring
        self.monitoring_thread = threading.Thread(
            target=self._monitoring_loop,
            daemon=True
        )
        self.monitoring_thread.start()
        
        self.logger.info("Monitoring temps réel démarré")
    
    def stop_monitoring(self):
        """Arrête le monitoring temps réel"""
        if not self.is_monitoring:
            return
        
        self.is_monitoring = False
        
        if self.monitoring_thread and self.monitoring_thread.is_alive():
            self.monitoring_thread.join(timeout=5.0)
        
        self.logger.info("Monitoring temps réel arrêté")
    
    def _monitoring_loop(self):
        """Boucle principale de monitoring temps réel"""
        while self.is_monitoring:
            try:
                # Collecte métriques actuelles
                current_metrics = self._collect_current_metrics()
                
                # Mise à jour état conversation
                self._update_conversation_state(current_metrics)
                
                # Détection anomalies et génération alertes
                self._detect_anomalies(current_metrics)
                
                # Nettoyage historique alertes anciennes
                self._cleanup_old_alerts()
                
                # Pause avant prochaine itération
                time.sleep(self.config.update_interval_seconds)
                
            except Exception as e:
                self.logger.error(f"Erreur dans boucle monitoring: {e}")
                time.sleep(self.config.update_interval_seconds * 2)
    
    def _collect_current_metrics(self) -> Dict[MonitoringMetric, float]:
        """
        Collecte les métriques actuelles depuis tous les sources
        
        Returns:
            Dict[MonitoringMetric, float]: Métriques temps réel
        """
        metrics = {}
        
        if not self.conversation_manager:
            return metrics
        
        try:
            # Métriques depuis MetricsCollector
            if hasattr(self.conversation_manager, 'metrics_collector'):
                collector = self.conversation_manager.metrics_collector
                current_session = collector.get_current_session_summary()
                
                # Latences
                metrics[MonitoringMetric.LATENCY_TTS] = current_session.get('average_tts_latency', 0.0)
                metrics[MonitoringMetric.LATENCY_VOSK] = current_session.get('average_vosk_latency', 0.0)
                metrics[MonitoringMetric.LATENCY_MISTRAL] = current_session.get('average_mistral_latency', 0.0)
                metrics[MonitoringMetric.LATENCY_TOTAL] = current_session.get('average_total_latency', 0.0)
                
                # Qualité
                metrics[MonitoringMetric.QUALITY_TRANSCRIPTION] = current_session.get('average_transcription_quality', 1.0)
                metrics[MonitoringMetric.QUALITY_MARIE_RESPONSE] = current_session.get('average_marie_relevance', 1.0)
                
                # Taux erreurs
                total_exchanges = current_session.get('total_exchanges', 1)
                total_errors = current_session.get('total_errors', 0)
                metrics[MonitoringMetric.ERROR_RATE] = total_errors / max(total_exchanges, 1)
                
                # Succès pipeline
                successful_exchanges = current_session.get('successful_exchanges', 0)
                metrics[MonitoringMetric.PIPELINE_SUCCESS_RATE] = successful_exchanges / max(total_exchanges, 1)
            
            # Métriques Marie depuis le character
            if hasattr(self.conversation_manager, 'marie_character'):
                marie = self.conversation_manager.marie_character
                
                metrics[MonitoringMetric.MARIE_SATISFACTION] = getattr(marie, 'current_satisfaction', 0.5)
                metrics[MonitoringMetric.MARIE_PATIENCE] = getattr(marie, 'current_patience', 1.0)
                
                # Calcul cohérence conversation basée sur progression Marie
                conversation_progress = getattr(marie, 'conversation_progress', 0.0)
                metrics[MonitoringMetric.CONVERSATION_COHERENCE] = min(conversation_progress / 0.8, 1.0)
            
            # Ajout métriques aux buffers
            for metric, value in metrics.items():
                self.metrics_buffers[metric].append({
                    'timestamp': datetime.now(),
                    'value': value
                })
            
        except Exception as e:
            self.logger.error(f"Erreur collecte métriques: {e}")
        
        return metrics
    
    def _update_conversation_state(self, current_metrics: Dict[MonitoringMetric, float]):
        """
        Met à jour l'état temps réel de la conversation
        
        Args:
            current_metrics: Métriques actuelles collectées
        """
        try:
            # Métriques de base
            if self.conversation_manager and hasattr(self.conversation_manager, 'metrics_collector'):
                session_summary = self.conversation_manager.metrics_collector.get_current_session_summary()
                self.conversation_state.exchange_count = session_summary.get('total_exchanges', 0)
            
            # Durée totale
            if self.start_time:
                self.conversation_state.total_duration_seconds = (datetime.now() - self.start_time).total_seconds()
            
            # État Marie
            self.conversation_state.marie_satisfaction_level = current_metrics.get(MonitoringMetric.MARIE_SATISFACTION, 0.5)
            self.conversation_state.marie_patience_level = current_metrics.get(MonitoringMetric.MARIE_PATIENCE, 1.0)
            
            # Qualité dernier échange
            self.conversation_state.last_exchange_quality = current_metrics.get(MonitoringMetric.QUALITY_MARIE_RESPONSE, 0.0)
            
            # Score santé pipeline
            pipeline_success = current_metrics.get(MonitoringMetric.PIPELINE_SUCCESS_RATE, 1.0)
            error_rate = current_metrics.get(MonitoringMetric.ERROR_RATE, 0.0)
            self.conversation_state.pipeline_health_score = pipeline_success * (1.0 - error_rate)
            
            # Analyse tendance performance
            self.conversation_state.performance_trend = self._analyze_performance_trend()
            
            # Mode Marie actuel
            if self.conversation_manager and hasattr(self.conversation_manager, 'marie_character'):
                marie = self.conversation_manager.marie_character
                self.conversation_state.current_marie_mode = getattr(marie, 'current_mode', 'initial_evaluation')
            
        except Exception as e:
            self.logger.error(f"Erreur mise à jour état conversation: {e}")
    
    def _analyze_performance_trend(self) -> str:
        """
        Analyse la tendance de performance récente
        
        Returns:
            str: Tendance ('improving', 'stable', 'degrading')
        """
        try:
            # Analyse sur les 5 dernières métriques de qualité
            quality_buffer = self.metrics_buffers[MonitoringMetric.QUALITY_MARIE_RESPONSE]
            
            if len(quality_buffer) < 3:
                return "stable"
            
            recent_values = [item['value'] for item in list(quality_buffer)[-5:]]
            
            # Calcul tendance via régression linéaire simple
            if len(recent_values) >= 3:
                x = list(range(len(recent_values)))
                y = recent_values
                
                # Calcul pente
                n = len(x)
                sum_x = sum(x)
                sum_y = sum(y)
                sum_xy = sum(x[i] * y[i] for i in range(n))
                sum_x2 = sum(x[i] * x[i] for i in range(n))
                
                slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
                
                if slope > 0.02:
                    return "improving"
                elif slope < -0.02:
                    return "degrading"
                else:
                    return "stable"
            
        except Exception as e:
            self.logger.error(f"Erreur analyse tendance: {e}")
        
        return "stable"
    
    def _detect_anomalies(self, current_metrics: Dict[MonitoringMetric, float]):
        """
        Détecte les anomalies dans les métriques actuelles
        
        Args:
            current_metrics: Métriques à analyser
        """
        for metric, current_value in current_metrics.items():
            if metric not in self.alert_thresholds:
                continue
            
            threshold_config = self.alert_thresholds[metric]
            
            # Vérification seuils par ordre de sévérité
            severity = None
            violated_threshold = None
            
            if self._is_threshold_violated(metric, current_value, threshold_config.emergency_threshold, "emergency"):
                severity = AlertSeverity.EMERGENCY
                violated_threshold = threshold_config.emergency_threshold
            elif self._is_threshold_violated(metric, current_value, threshold_config.critical_threshold, "critical"):
                severity = AlertSeverity.CRITICAL
                violated_threshold = threshold_config.critical_threshold
            elif self._is_threshold_violated(metric, current_value, threshold_config.warning_threshold, "warning"):
                severity = AlertSeverity.WARNING
                violated_threshold = threshold_config.warning_threshold
            
            # Génération alerte si seuil violé
            if severity:
                self._generate_alert(metric, current_value, violated_threshold, severity, threshold_config)
    
    def _is_threshold_violated(self, metric: MonitoringMetric, current_value: float, 
                              threshold: float, threshold_type: str) -> bool:
        """
        Vérifie si un seuil est violé en tenant compte du contexte métrique
        
        Args:
            metric: Métrique évaluée
            current_value: Valeur actuelle
            threshold: Seuil à vérifier
            threshold_type: Type de seuil (warning/critical/emergency)
            
        Returns:
            bool: True si seuil violé
        """
        # Métriques où valeur haute = problème (latences, erreurs)
        high_bad_metrics = {
            MonitoringMetric.LATENCY_TTS, MonitoringMetric.LATENCY_VOSK,
            MonitoringMetric.LATENCY_MISTRAL, MonitoringMetric.LATENCY_TOTAL,
            MonitoringMetric.ERROR_RATE
        }
        
        # Métriques où valeur basse = problème (qualité, satisfaction)
        low_bad_metrics = {
            MonitoringMetric.QUALITY_TRANSCRIPTION, MonitoringMetric.QUALITY_MARIE_RESPONSE,
            MonitoringMetric.MARIE_SATISFACTION, MonitoringMetric.MARIE_PATIENCE,
            MonitoringMetric.PIPELINE_SUCCESS_RATE, MonitoringMetric.CONVERSATION_COHERENCE
        }
        
        if metric in high_bad_metrics:
            return current_value > threshold
        elif metric in low_bad_metrics:
            return current_value < threshold
        
        return False
    
    def _generate_alert(self, metric: MonitoringMetric, current_value: float, 
                       violated_threshold: float, severity: AlertSeverity, 
                       threshold_config: AlertThreshold):
        """
        Génère une alerte pour anomalie détectée
        
        Args:
            metric: Métrique problématique
            current_value: Valeur actuelle
            violated_threshold: Seuil violé
            severity: Sévérité de l'alerte
            threshold_config: Configuration seuil
        """
        alert_id = f"{metric.value}_{severity.value}_{int(time.time())}"
        
        # Éviter alertes dupliquées récentes
        if alert_id in self.active_alerts:
            return
        
        # Construction message et recommandations
        message = self._build_alert_message(metric, current_value, violated_threshold, severity)
        recommendations = self._build_alert_recommendations(metric, current_value, severity)
        
        # Contexte additionnel
        context = {
            'conversation_state': asdict(self.conversation_state),
            'metric_history': self._get_metric_history_summary(metric),
            'related_metrics': self._get_related_metrics_context(metric)
        }
        
        # Création alerte
        alert = RealTimeAlert(
            alert_id=alert_id,
            timestamp=datetime.now(),
            severity=severity,
            metric=metric,
            current_value=current_value,
            threshold_violated=violated_threshold,
            message=message,
            context=context,
            recommendations=recommendations
        )
        
        # Déclenchement auto-réparation si configuré
        if self.config.enable_auto_repair_triggers and severity in [AlertSeverity.CRITICAL, AlertSeverity.EMERGENCY]:
            alert.auto_repair_triggered = self._trigger_auto_repair(alert)
        
        # Ajout à l'historique
        self.alert_history.append(alert)
        self.active_alerts.add(alert_id)
        
        # Notification callbacks externes
        self._notify_alert_callbacks(alert)
        
        self.logger.warning(f"Alerte générée [{severity.value}]: {message}")
    
    def _build_alert_message(self, metric: MonitoringMetric, current_value: float, 
                            threshold: float, severity: AlertSeverity) -> str:
        """
        Construit le message d'alerte contextualisé
        
        Args:
            metric: Métrique problématique
            current_value: Valeur actuelle
            threshold: Seuil violé
            severity: Sévérité
            
        Returns:
            str: Message d'alerte formaté
        """
        metric_names = {
            MonitoringMetric.LATENCY_TTS: "Latence TTS",
            MonitoringMetric.LATENCY_VOSK: "Latence VOSK",
            MonitoringMetric.LATENCY_MISTRAL: "Latence Mistral",
            MonitoringMetric.LATENCY_TOTAL: "Latence totale pipeline",
            MonitoringMetric.QUALITY_TRANSCRIPTION: "Qualité transcription",
            MonitoringMetric.QUALITY_MARIE_RESPONSE: "Pertinence réponses Marie",
            MonitoringMetric.ERROR_RATE: "Taux d'erreurs",
            MonitoringMetric.MARIE_SATISFACTION: "Satisfaction Marie",
            MonitoringMetric.MARIE_PATIENCE: "Patience Marie",
            MonitoringMetric.PIPELINE_SUCCESS_RATE: "Taux succès pipeline"
        }
        
        metric_name = metric_names.get(metric, metric.value)
        
        if "latency" in metric.value or "error_rate" in metric.value:
            comparison = "dépasse"
            unit = "s" if "latency" in metric.value else "%"
            current_display = f"{current_value:.1f}{unit}"
            threshold_display = f"{threshold:.1f}{unit}"
        else:
            comparison = "en dessous de"
            unit = "%"
            current_display = f"{current_value*100:.0f}{unit}"
            threshold_display = f"{threshold*100:.0f}{unit}"
        
        return (f"{metric_name} {comparison} seuil {severity.value}: "
                f"{current_display} (seuil: {threshold_display})")
    
    def _build_alert_recommendations(self, metric: MonitoringMetric, current_value: float, 
                                   severity: AlertSeverity) -> List[str]:
        """
        Construit les recommandations contextualisées pour l'alerte
        
        Args:
            metric: Métrique problématique
            current_value: Valeur actuelle
            severity: Sévérité
            
        Returns:
            List[str]: Recommandations d'action
        """
        recommendations = []
        
        # Recommandations par type de métrique
        if metric == MonitoringMetric.LATENCY_TTS:
            recommendations.extend([
                "Vérifier charge serveur TTS (localhost:5002)",
                "Réduire complexité/longueur messages TTS",
                "Redémarrer service TTS si latence persistante"
            ])
        
        elif metric == MonitoringMetric.LATENCY_VOSK:
            recommendations.extend([
                "Vérifier ressources CPU pour VOSK",
                "Optimiser qualité audio pour transcription plus rapide",
                "Redémarrer service VOSK (localhost:2700)"
            ])
        
        elif metric == MonitoringMetric.LATENCY_MISTRAL:
            recommendations.extend([
                "Vérifier connectivité réseau Scaleway",
                "Réduire longueur prompts Mistral",
                "Basculer sur modèle Mistral plus rapide temporairement"
            ])
        
        elif metric == MonitoringMetric.QUALITY_TRANSCRIPTION:
            recommendations.extend([
                "Améliorer qualité audio TTS source",
                "Ajuster paramètres VOSK pour meilleure précision",
                "Vérifier bruit ambiant dans audio généré"
            ])
        
        elif metric == MonitoringMetric.QUALITY_MARIE_RESPONSE:
            recommendations.extend([
                "Revoir prompts/contexte fourni à Marie",
                "Ajuster intensité personnalité Marie",
                "Vérifier cohérence progression conversationnelle"
            ])
        
        elif metric == MonitoringMetric.MARIE_SATISFACTION:
            recommendations.extend([
                "Améliorer pertinence messages utilisateur",
                "Ajuster stratégie conversationnelle",
                "Réviser objectifs/contexte de la conversation"
            ])
        
        elif metric == MonitoringMetric.MARIE_PATIENCE:
            recommendations.extend([
                "Accélérer rythme conversation",
                "Éviter répétitions/redondances",
                "Améliorer qualité transcription pour réduire incompréhensions"
            ])
        
        elif metric == MonitoringMetric.ERROR_RATE:
            recommendations.extend([
                "Diagnostiquer source principale des erreurs",
                "Activer auto-réparation si disponible",
                "Vérifier santé tous les services en amont"
            ])
        
        # Recommandations par sévérité
        if severity == AlertSeverity.EMERGENCY:
            recommendations.insert(0, "ACTION IMMÉDIATE REQUISE - Risque d'échec conversation")
        elif severity == AlertSeverity.CRITICAL:
            recommendations.insert(0, "Intervention urgente recommandée")
        
        return recommendations
    
    def _get_metric_history_summary(self, metric: MonitoringMetric) -> Dict[str, Any]:
        """
        Résumé historique d'une métrique pour contexte alerte
        
        Args:
            metric: Métrique à analyser
            
        Returns:
            Dict[str, Any]: Statistiques historiques
        """
        buffer = self.metrics_buffers[metric]
        
        if len(buffer) == 0:
            return {}
        
        values = [item['value'] for item in buffer]
        
        return {
            'count_samples': len(values),
            'mean': statistics.mean(values),
            'median': statistics.median(values),
            'std_dev': statistics.stdev(values) if len(values) > 1 else 0.0,
            'min': min(values),
            'max': max(values),
            'trend': self._calculate_metric_trend(values)
        }
    
    def _calculate_metric_trend(self, values: List[float]) -> str:
        """
        Calcule la tendance d'une série de valeurs
        
        Args:
            values: Série de valeurs à analyser
            
        Returns:
            str: Tendance ('increasing', 'decreasing', 'stable')
        """
        if len(values) < 2:
            return 'stable'
        
        # Comparaison moyenne première moitié vs seconde moitié
        mid = len(values) // 2
        first_half_avg = statistics.mean(values[:mid])
        second_half_avg = statistics.mean(values[mid:])
        
        diff_percent = abs(second_half_avg - first_half_avg) / (first_half_avg + 0.001)
        
        if diff_percent < 0.05:  # 5% de changement
            return 'stable'
        elif second_half_avg > first_half_avg:
            return 'increasing'
        else:
            return 'decreasing'
    
    def _get_related_metrics_context(self, metric: MonitoringMetric) -> Dict[str, float]:
        """
        Obtient le contexte des métriques liées pour analyse corrélation
        
        Args:
            metric: Métrique principale
            
        Returns:
            Dict[str, float]: Métriques liées actuelles
        """
        context = {}
        
        # Relations entre métriques
        metric_relationships = {
            MonitoringMetric.LATENCY_TTS: [MonitoringMetric.LATENCY_TOTAL, MonitoringMetric.QUALITY_TRANSCRIPTION],
            MonitoringMetric.LATENCY_VOSK: [MonitoringMetric.LATENCY_TOTAL, MonitoringMetric.QUALITY_TRANSCRIPTION],
            MonitoringMetric.LATENCY_MISTRAL: [MonitoringMetric.LATENCY_TOTAL, MonitoringMetric.QUALITY_MARIE_RESPONSE],
            MonitoringMetric.QUALITY_TRANSCRIPTION: [MonitoringMetric.QUALITY_MARIE_RESPONSE, MonitoringMetric.MARIE_SATISFACTION],
            MonitoringMetric.MARIE_SATISFACTION: [MonitoringMetric.MARIE_PATIENCE, MonitoringMetric.CONVERSATION_COHERENCE]
        }
        
        related_metrics = metric_relationships.get(metric, [])
        
        for related_metric in related_metrics:
            buffer = self.metrics_buffers[related_metric]
            if buffer:
                context[related_metric.value] = buffer[-1]['value']
        
        return context
    
    def _trigger_auto_repair(self, alert: RealTimeAlert) -> bool:
        """
        Déclenche auto-réparation pour alerte critique
        
        Args:
            alert: Alerte nécessitant intervention
            
        Returns:
            bool: True si auto-réparation déclenchée
        """
        try:
            if (self.conversation_manager and 
                hasattr(self.conversation_manager, 'auto_repair_system')):
                
                # Conversion alerte en format auto-réparation
                repair_context = {
                    'error_type': f'monitoring_alert_{alert.metric.value}',
                    'severity': alert.severity.value,
                    'current_value': alert.current_value,
                    'threshold_violated': alert.threshold_violated,
                    'recommendations': alert.recommendations
                }
                
                auto_repair = self.conversation_manager.auto_repair_system
                return auto_repair.attempt_repair('monitoring_anomaly', repair_context)
            
        except Exception as e:
            self.logger.error(f"Erreur déclenchement auto-réparation: {e}")
        
        return False
    
    def _notify_alert_callbacks(self, alert: RealTimeAlert):
        """
        Notifie tous les callbacks enregistrés d'une nouvelle alerte
        
        Args:
            alert: Alerte à notifier
        """
        for callback in self.alert_callbacks:
            try:
                callback(alert)
            except Exception as e:
                self.logger.error(f"Erreur callback alerte: {e}")
    
    def _cleanup_old_alerts(self):
        """Nettoie les alertes anciennes de l'historique"""
        cutoff_time = datetime.now() - timedelta(hours=self.config.alert_history_retention_hours)
        
        # Suppression alertes anciennes
        self.alert_history = [
            alert for alert in self.alert_history 
            if alert.timestamp > cutoff_time
        ]
        
        # Nettoyage alertes actives résolues
        active_alert_ids = {alert.alert_id for alert in self.alert_history[-100:]}  # 100 dernières
        self.active_alerts = self.active_alerts.intersection(active_alert_ids)
    
    def get_current_status(self) -> Dict[str, Any]:
        """
        Obtient le statut complet actuel du monitoring
        
        Returns:
            Dict[str, Any]: Statut monitoring détaillé
        """
        return {
            'monitoring_active': self.is_monitoring,
            'monitoring_duration_seconds': (datetime.now() - self.start_time).total_seconds() if self.start_time else 0,
            'conversation_state': asdict(self.conversation_state),
            'active_alerts_count': len(self.active_alerts),
            'total_alerts_generated': len(self.alert_history),
            'recent_alerts': [
                {
                    'timestamp': alert.timestamp.isoformat(),
                    'severity': alert.severity.value,
                    'metric': alert.metric.value,
                    'message': alert.message
                }
                for alert in self.alert_history[-5:]  # 5 dernières alertes
            ],
            'performance_summary': self._get_performance_summary()
        }
    
    def _get_performance_summary(self) -> Dict[str, Any]:
        """
        Résumé performance actuelle pour statut monitoring
        
        Returns:
            Dict[str, Any]: Résumé performance
        """
        summary = {}
        
        key_metrics = [
            MonitoringMetric.LATENCY_TOTAL,
            MonitoringMetric.QUALITY_MARIE_RESPONSE,
            MonitoringMetric.ERROR_RATE,
            MonitoringMetric.MARIE_SATISFACTION
        ]
        
        for metric in key_metrics:
            buffer = self.metrics_buffers[metric]
            if buffer:
                recent_values = [item['value'] for item in list(buffer)[-10:]]
                summary[metric.value] = {
                    'current': recent_values[-1] if recent_values else 0.0,
                    'average_recent': statistics.mean(recent_values),
                    'trend': self._calculate_metric_trend(recent_values)
                }
        
        return summary
    
    def add_alert_callback(self, callback: Callable[[RealTimeAlert], None]):
        """
        Ajoute un callback pour notifications d'alertes
        
        Args:
            callback: Fonction appelée pour chaque alerte
        """
        self.alert_callbacks.append(callback)
    
    def update_threshold(self, metric: MonitoringMetric, threshold_config: AlertThreshold):
        """
        Met à jour le seuil d'alerte pour une métrique
        
        Args:
            metric: Métrique à configurer
            threshold_config: Nouvelle configuration seuil
        """
        self.alert_thresholds[metric] = threshold_config
        self.logger.info(f"Seuil mis à jour pour {metric.value}")
    
    def export_monitoring_report(self, filepath: Optional[str] = None) -> str:
        """
        Exporte un rapport complet de monitoring
        
        Args:
            filepath: Chemin fichier optionnel
            
        Returns:
            str: Chemin fichier rapport généré
        """
        if not filepath:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filepath = f"monitoring_report_{timestamp}.json"
        
        report = {
            'monitoring_session': {
                'start_time': self.start_time.isoformat() if self.start_time else None,
                'report_time': datetime.now().isoformat(),
                'monitoring_duration_seconds': (datetime.now() - self.start_time).total_seconds() if self.start_time else 0
            },
            'conversation_state': asdict(self.conversation_state),
            'alert_summary': {
                'total_alerts': len(self.alert_history),
                'alerts_by_severity': {
                    severity.value: len([a for a in self.alert_history if a.severity == severity])
                    for severity in AlertSeverity
                },
                'alerts_by_metric': {
                    metric.value: len([a for a in self.alert_history if a.metric == metric])
                    for metric in MonitoringMetric
                }
            },
            'performance_analytics': self._get_performance_summary(),
            'alert_history': [
                {
                    'timestamp': alert.timestamp.isoformat(),
                    'severity': alert.severity.value,
                    'metric': alert.metric.value,
                    'current_value': alert.current_value,
                    'threshold_violated': alert.threshold_violated,
                    'message': alert.message,
                    'auto_repair_triggered': alert.auto_repair_triggered
                }
                for alert in self.alert_history
            ]
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"Rapport monitoring exporté: {filepath}")
        return filepath