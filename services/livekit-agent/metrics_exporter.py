"""
Exporter de métriques Prometheus pour le système multi-agents LiveKit
"""
import asyncio
import time
from typing import Dict, List, Optional
from prometheus_client import (
    Counter, Gauge, Histogram, Summary,
    start_http_server, REGISTRY
)
from prometheus_client.core import CollectorRegistry
import logging
from dataclasses import dataclass
from datetime import datetime

logger = logging.getLogger(__name__)

# Métriques globales
agent_requests_total = Counter(
    'agent_requests_total',
    'Nombre total de requêtes traitées par les agents',
    ['agent_type', 'simulation_type', 'status']
)

agent_errors_total = Counter(
    'agent_errors_total',
    'Nombre total d\'erreurs dans les agents',
    ['agent_type', 'error_type']
)

active_agents_total = Gauge(
    'active_agents_total',
    'Nombre d\'agents actuellement actifs',
    ['agent_type', 'simulation_type']
)

concurrent_sessions_total = Gauge(
    'concurrent_sessions_total',
    'Nombre de sessions simultanées'
)

agent_response_time_seconds = Histogram(
    'agent_response_time_seconds',
    'Temps de réponse des agents en secondes',
    ['agent_type', 'action'],
    buckets=(0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0)
)

session_duration_seconds = Histogram(
    'session_duration_seconds',
    'Durée des sessions en secondes',
    ['simulation_type'],
    buckets=(30, 60, 120, 300, 600, 900, 1800, 3600)
)

webrtc_connection_failures_total = Counter(
    'webrtc_connection_failures_total',
    'Nombre total d\'échecs de connexion WebRTC',
    ['reason']
)

ai_api_failures_total = Counter(
    'ai_api_failures_total',
    'Nombre total d\'échecs d\'API IA',
    ['provider', 'error_type']
)

ai_tokens_used_total = Counter(
    'ai_tokens_used_total',
    'Nombre total de tokens IA utilisés',
    ['provider', 'model']
)

audio_processing_duration_seconds = Histogram(
    'audio_processing_duration_seconds',
    'Durée du traitement audio en secondes',
    ['operation'],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0)
)

agent_memory_bytes = Gauge(
    'agent_memory_bytes',
    'Utilisation mémoire par agent en bytes',
    ['agent_id', 'agent_type']
)

redis_operations_total = Counter(
    'redis_operations_total',
    'Nombre total d\'opérations Redis',
    ['operation', 'status']
)

redis_commands_duration_seconds_mean = Gauge(
    'redis_commands_duration_seconds_mean',
    'Durée moyenne des commandes Redis'
)

@dataclass
class SessionMetrics:
    """Métriques pour une session"""
    session_id: str
    simulation_type: str
    start_time: float
    agent_count: int
    interactions: int = 0
    errors: int = 0
    ai_tokens: int = 0
    
class MetricsCollector:
    """Collecteur de métriques pour le système multi-agents"""
    
    def __init__(self, agent_id: str, agent_type: str, port: int = 9091):
        self.agent_id = agent_id
        self.agent_type = agent_type
        self.port = port
        self.sessions: Dict[str, SessionMetrics] = {}
        self.start_time = time.time()
        
    async def start_server(self):
        """Démarre le serveur HTTP Prometheus"""
        try:
            start_http_server(self.port)
            logger.info(f"Serveur de métriques démarré sur le port {self.port}")
        except Exception as e:
            logger.error(f"Erreur au démarrage du serveur de métriques: {e}")
            
    def record_request(self, simulation_type: str, status: str = "success"):
        """Enregistre une requête"""
        agent_requests_total.labels(
            agent_type=self.agent_type,
            simulation_type=simulation_type,
            status=status
        ).inc()
        
    def record_error(self, error_type: str):
        """Enregistre une erreur"""
        agent_errors_total.labels(
            agent_type=self.agent_type,
            error_type=error_type
        ).inc()
        
    def set_active_agents(self, count: int, simulation_type: str):
        """Définit le nombre d'agents actifs"""
        active_agents_total.labels(
            agent_type=self.agent_type,
            simulation_type=simulation_type
        ).set(count)
        
    def record_response_time(self, duration: float, action: str):
        """Enregistre le temps de réponse"""
        agent_response_time_seconds.labels(
            agent_type=self.agent_type,
            action=action
        ).observe(duration)
        
    def start_session(self, session_id: str, simulation_type: str, agent_count: int):
        """Démarre une nouvelle session"""
        self.sessions[session_id] = SessionMetrics(
            session_id=session_id,
            simulation_type=simulation_type,
            start_time=time.time(),
            agent_count=agent_count
        )
        concurrent_sessions_total.inc()
        
    def end_session(self, session_id: str):
        """Termine une session"""
        if session_id in self.sessions:
            session = self.sessions[session_id]
            duration = time.time() - session.start_time
            session_duration_seconds.labels(
                simulation_type=session.simulation_type
            ).observe(duration)
            del self.sessions[session_id]
            concurrent_sessions_total.dec()
            
    def record_webrtc_failure(self, reason: str):
        """Enregistre un échec WebRTC"""
        webrtc_connection_failures_total.labels(reason=reason).inc()
        
    def record_ai_failure(self, provider: str, error_type: str):
        """Enregistre un échec d'API IA"""
        ai_api_failures_total.labels(
            provider=provider,
            error_type=error_type
        ).inc()
        
    def record_ai_tokens(self, provider: str, model: str, tokens: int):
        """Enregistre l'utilisation de tokens IA"""
        ai_tokens_used_total.labels(
            provider=provider,
            model=model
        ).inc(tokens)
        
    def record_audio_processing(self, duration: float, operation: str):
        """Enregistre le temps de traitement audio"""
        audio_processing_duration_seconds.labels(
            operation=operation
        ).observe(duration)
        
    def set_memory_usage(self, bytes_used: int):
        """Définit l'utilisation mémoire"""
        agent_memory_bytes.labels(
            agent_id=self.agent_id,
            agent_type=self.agent_type
        ).set(bytes_used)
        
    def record_redis_operation(self, operation: str, status: str = "success"):
        """Enregistre une opération Redis"""
        redis_operations_total.labels(
            operation=operation,
            status=status
        ).inc()
        
    def set_redis_latency(self, latency: float):
        """Définit la latence Redis"""
        redis_commands_duration_seconds_mean.set(latency)
        
    async def collect_system_metrics(self):
        """Collecte périodique des métriques système"""
        while True:
            try:
                # Collecte de l'utilisation mémoire
                import psutil
                process = psutil.Process()
                memory_info = process.memory_info()
                self.set_memory_usage(memory_info.rss)
                
                # Mise à jour du nombre de sessions actives
                concurrent_sessions_total.set(len(self.sessions))
                
                await asyncio.sleep(30)  # Collecte toutes les 30 secondes
            except Exception as e:
                logger.error(f"Erreur lors de la collecte des métriques système: {e}")
                await asyncio.sleep(30)
                
class PerformanceTracker:
    """Tracker de performance pour mesurer les temps d'exécution"""
    
    def __init__(self, collector: MetricsCollector):
        self.collector = collector
        self.start_times: Dict[str, float] = {}
        
    def start_timing(self, operation: str):
        """Démarre le chronométrage d'une opération"""
        self.start_times[operation] = time.time()
        
    def end_timing(self, operation: str, metric_type: str = "response"):
        """Termine le chronométrage et enregistre la métrique"""
        if operation in self.start_times:
            duration = time.time() - self.start_times[operation]
            
            if metric_type == "response":
                self.collector.record_response_time(duration, operation)
            elif metric_type == "audio":
                self.collector.record_audio_processing(duration, operation)
                
            del self.start_times[operation]
            return duration
        return 0.0
        
    async def __aenter__(self):
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        # Nettoyer les timings non terminés
        self.start_times.clear()
        
# Instance globale du collecteur
_metrics_collector: Optional[MetricsCollector] = None

def init_metrics(agent_id: str, agent_type: str, port: int = 9091) -> MetricsCollector:
    """Initialise le collecteur de métriques"""
    global _metrics_collector
    _metrics_collector = MetricsCollector(agent_id, agent_type, port)
    return _metrics_collector

def get_metrics_collector() -> Optional[MetricsCollector]:
    """Récupère le collecteur de métriques"""
    return _metrics_collector

# Décorateur pour mesurer automatiquement les performances
def track_performance(operation: str):
    """Décorateur pour tracker les performances d'une fonction"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            collector = get_metrics_collector()
            if collector:
                tracker = PerformanceTracker(collector)
                tracker.start_timing(operation)
                try:
                    result = await func(*args, **kwargs)
                    tracker.end_timing(operation, "response")
                    return result
                except Exception as e:
                    tracker.end_timing(operation, "response")
                    collector.record_error(type(e).__name__)
                    raise
            else:
                return await func(*args, **kwargs)
        return wrapper
    return decorator