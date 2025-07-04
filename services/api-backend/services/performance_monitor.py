"""
🚀 PERFORMANCE MONITOR - Système de monitoring des goulots d'étranglement
Mesure la latence, détecte les bottlenecks et optimise les performances temps réel
"""

import time
import asyncio
import logging
from typing import Dict, List, Optional
from dataclasses import dataclass, field
from collections import deque
import statistics

logger = logging.getLogger(__name__)

@dataclass
class PerformanceMetric:
    """Métrique de performance pour un composant"""
    name: str
    start_time: float
    end_time: Optional[float] = None
    duration: Optional[float] = None
    success: bool = True
    error_message: Optional[str] = None
    metadata: Dict = field(default_factory=dict)

class PerformanceMonitor:
    """Moniteur de performance temps réel pour détecter les goulots d'étranglement"""
    
    def __init__(self, max_history: int = 100):
        self.max_history = max_history
        self.metrics_history: Dict[str, deque] = {}
        self.active_metrics: Dict[str, PerformanceMetric] = {}
        self.thresholds = {
            "stt_processing": 2.0,      # STT doit être < 2s
            "tts_synthesis": 0.5,       # TTS premier chunk < 500ms
            "llm_response": 4.0,        # LLM réponse < 4s
            "end_to_end": 6.0,          # Pipeline complet < 6s
            "audio_chunk": 0.1,         # Traitement chunk audio < 100ms
            "network_request": 1.0,     # Requêtes réseau < 1s
        }
        
    def start_metric(self, metric_name: str, metadata: Dict = None) -> str:
        """Démarre la mesure d'une métrique"""
        metric_id = f"{metric_name}_{int(time.time() * 1000)}"
        
        metric = PerformanceMetric(
            name=metric_name,
            start_time=time.time(),
            metadata=metadata or {}
        )
        
        self.active_metrics[metric_id] = metric
        
        logger.debug(f"⏱️ PERF: Début mesure {metric_name} (ID: {metric_id})")
        return metric_id
    
    def end_metric(self, metric_id: str, success: bool = True, error_message: str = None):
        """Termine la mesure d'une métrique"""
        if metric_id not in self.active_metrics:
            logger.warning(f"⏱️ PERF: Métrique inconnue: {metric_id}")
            return
        
        metric = self.active_metrics[metric_id]
        metric.end_time = time.time()
        metric.duration = metric.end_time - metric.start_time
        metric.success = success
        metric.error_message = error_message
        
        # Ajouter à l'historique
        if metric.name not in self.metrics_history:
            self.metrics_history[metric.name] = deque(maxlen=self.max_history)
        
        self.metrics_history[metric.name].append(metric)
        
        # Log de performance avec détection de goulot d'étranglement
        self._log_performance_result(metric)
        
        # Nettoyer les métriques actives
        del self.active_metrics[metric_id]
    
    def _log_performance_result(self, metric: PerformanceMetric):
        """Log le résultat de performance avec détection de bottleneck"""
        duration_ms = metric.duration * 1000
        threshold = self.thresholds.get(metric.name, 1.0)
        threshold_ms = threshold * 1000
        
        # Déterminer le niveau de performance
        if metric.duration <= threshold * 0.5:
            level = "EXCELLENT"
            emoji = "🚀"
        elif metric.duration <= threshold:
            level = "BON"
            emoji = "✅"
        elif metric.duration <= threshold * 1.5:
            level = "LENT"
            emoji = "⚠️"
        else:
            level = "GOULOT"
            emoji = "🐌"
        
        # Log principal
        if metric.success:
            logger.info(f"{emoji} PERF: {metric.name} - {duration_ms:.1f}ms ({level}) - Seuil: {threshold_ms:.0f}ms")
        else:
            logger.error(f"❌ PERF: {metric.name} - ÉCHEC après {duration_ms:.1f}ms - {metric.error_message}")
        
        # Log détaillé pour les goulots d'étranglement
        if level in ["LENT", "GOULOT"]:
            self._log_bottleneck_analysis(metric)
        
        # Métadonnées supplémentaires
        if metric.metadata:
            logger.debug(f"📊 PERF: {metric.name} - Métadonnées: {metric.metadata}")
    
    def _log_bottleneck_analysis(self, metric: PerformanceMetric):
        """Analyse détaillée des goulots d'étranglement"""
        logger.warning(f"🔍 BOTTLENECK: {metric.name} est lent ({metric.duration:.3f}s)")
        
        # Suggestions d'optimisation par composant
        suggestions = {
            "stt_processing": [
                "Réduire la taille des chunks audio",
                "Optimiser la configuration Whisper",
                "Vérifier la latence réseau vers le service STT"
            ],
            "tts_synthesis": [
                "Utiliser un cache TTS plus agressif",
                "Réduire la qualité audio temporairement",
                "Paralléliser la synthèse de chunks"
            ],
            "llm_response": [
                "Réduire max_tokens dans la configuration",
                "Utiliser le cache de réponses",
                "Optimiser les prompts pour des réponses plus courtes"
            ],
            "network_request": [
                "Vérifier la connectivité réseau",
                "Augmenter le pool de connexions",
                "Implémenter un retry plus intelligent"
            ]
        }
        
        if metric.name in suggestions:
            logger.warning(f"💡 OPTIMISATIONS: {metric.name}")
            for suggestion in suggestions[metric.name]:
                logger.warning(f"   - {suggestion}")
    
    def get_performance_stats(self, metric_name: str) -> Dict:
        """Obtient les statistiques de performance pour une métrique"""
        if metric_name not in self.metrics_history:
            return {}
        
        history = self.metrics_history[metric_name]
        durations = [m.duration for m in history if m.success]
        
        if not durations:
            return {"error": "Aucune mesure réussie"}
        
        stats = {
            "count": len(durations),
            "avg_ms": statistics.mean(durations) * 1000,
            "min_ms": min(durations) * 1000,
            "max_ms": max(durations) * 1000,
            "median_ms": statistics.median(durations) * 1000,
            "threshold_ms": self.thresholds.get(metric_name, 1.0) * 1000,
            "success_rate": len(durations) / len(history) * 100
        }
        
        if len(durations) > 1:
            stats["std_dev_ms"] = statistics.stdev(durations) * 1000
        
        return stats
    
    def log_performance_summary(self):
        """Log un résumé complet des performances"""
        logger.info("📊 RÉSUMÉ PERFORMANCE - Dernières mesures")
        logger.info("=" * 60)
        
        for metric_name in self.metrics_history:
            stats = self.get_performance_stats(metric_name)
            if "error" not in stats:
                avg_ms = stats["avg_ms"]
                threshold_ms = stats["threshold_ms"]
                success_rate = stats["success_rate"]
                
                # Déterminer l'état global
                if avg_ms <= threshold_ms * 0.5:
                    status = "🚀 EXCELLENT"
                elif avg_ms <= threshold_ms:
                    status = "✅ BON"
                elif avg_ms <= threshold_ms * 1.5:
                    status = "⚠️ LENT"
                else:
                    status = "🐌 GOULOT"
                
                logger.info(f"{status} {metric_name:20} | Moy: {avg_ms:6.1f}ms | Seuil: {threshold_ms:6.0f}ms | Succès: {success_rate:5.1f}%")
        
        logger.info("=" * 60)
    
    def detect_bottlenecks(self) -> List[str]:
        """Détecte automatiquement les goulots d'étranglement"""
        bottlenecks = []
        
        for metric_name in self.metrics_history:
            stats = self.get_performance_stats(metric_name)
            if "error" not in stats:
                avg_ms = stats["avg_ms"]
                threshold_ms = stats["threshold_ms"]
                
                if avg_ms > threshold_ms * 1.5:
                    bottlenecks.append(f"{metric_name} ({avg_ms:.1f}ms > {threshold_ms:.0f}ms)")
        
        if bottlenecks:
            logger.warning(f"🚨 GOULOTS DÉTECTÉS: {', '.join(bottlenecks)}")
        
        return bottlenecks

# Instance globale du moniteur
performance_monitor = PerformanceMonitor()

# Décorateur pour mesurer automatiquement les performances
def measure_performance(metric_name: str, metadata: Dict = None):
    """Décorateur pour mesurer automatiquement les performances d'une fonction"""
    def decorator(func):
        if asyncio.iscoroutinefunction(func):
            async def async_wrapper(*args, **kwargs):
                metric_id = performance_monitor.start_metric(metric_name, metadata)
                try:
                    result = await func(*args, **kwargs)
                    performance_monitor.end_metric(metric_id, success=True)
                    return result
                except Exception as e:
                    performance_monitor.end_metric(metric_id, success=False, error_message=str(e))
                    raise
            return async_wrapper
        else:
            def sync_wrapper(*args, **kwargs):
                metric_id = performance_monitor.start_metric(metric_name, metadata)
                try:
                    result = func(*args, **kwargs)
                    performance_monitor.end_metric(metric_id, success=True)
                    return result
                except Exception as e:
                    performance_monitor.end_metric(metric_id, success=False, error_message=str(e))
                    raise
            return sync_wrapper
    return decorator

# Context manager pour mesures manuelles
class PerformanceContext:
    """Context manager pour mesurer les performances manuellement"""
    
    def __init__(self, metric_name: str, metadata: Dict = None):
        self.metric_name = metric_name
        self.metadata = metadata
        self.metric_id = None
    
    def __enter__(self):
        self.metric_id = performance_monitor.start_metric(self.metric_name, self.metadata)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        success = exc_type is None
        error_message = str(exc_val) if exc_val else None
        performance_monitor.end_metric(self.metric_id, success=success, error_message=error_message)

# Fonction utilitaire pour mesures rapides
def measure_time(metric_name: str, metadata: Dict = None):
    """Fonction utilitaire pour créer un context manager de mesure"""
    return PerformanceContext(metric_name, metadata)