"""
Moniteur de santé des conversations pour Eloquence
Surveille et rapporte la qualité des interactions IA
"""
import logging
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)

@dataclass
class InteractionMetrics:
    """Métriques d'une interaction individuelle"""
    timestamp: datetime
    user_message_length: int
    ai_response_length: int
    response_time: float
    success: bool
    exercise_type: str
    error_message: Optional[str] = None

@dataclass
class ConversationHealthReport:
    """Rapport de santé conversationnelle"""
    total_interactions: int = 0
    successful_interactions: int = 0
    failed_interactions: int = 0
    average_response_time: float = 0.0
    silence_timeouts: int = 0
    health_score: float = 0.0
    status: str = "unknown"
    recommendations: List[str] = field(default_factory=list)
    last_updated: datetime = field(default_factory=datetime.now)

class ConversationHealthMonitor:
    """Surveille la santé des conversations IA en temps réel"""
    
    def __init__(self, exercise_type: str):
        self.exercise_type = exercise_type
        self.interactions: List[InteractionMetrics] = []
        self.silence_timeouts = 0
        self.start_time = datetime.now()
        self.is_monitoring = True
        
        logger.info(f"🩺 ConversationHealthMonitor initialisé pour {exercise_type}")
    
    async def log_interaction(self, user_message: str, ai_response: str, response_time: float, success: bool = True, error: str = None):
        """Log une interaction complète avec métriques"""
        interaction = InteractionMetrics(
            timestamp=datetime.now(),
            user_message_length=len(user_message) if user_message else 0,
            ai_response_length=len(ai_response) if ai_response else 0,
            response_time=response_time,
            success=success,
            exercise_type=self.exercise_type,
            error_message=error
        )
        
        self.interactions.append(interaction)
        
        # Log détaillé
        if success:
            logger.info(f"✅ Interaction #{len(self.interactions)}: "
                       f"{interaction.user_message_length} chars → "
                       f"{interaction.ai_response_length} chars "
                       f"({response_time:.2f}s)")
        else:
            logger.error(f"❌ Interaction #{len(self.interactions)} ÉCHOUÉE: "
                        f"{interaction.user_message_length} chars → "
                        f"ERREUR: {error} ({response_time:.2f}s)")
        
        # Analyse en temps réel
        await self.analyze_interaction_quality(interaction)
    
    async def log_silence_timeout(self, silence_duration: float, timeout_count: int):
        """Log un timeout de silence"""
        self.silence_timeouts += 1
        
        logger.warning(f"⏰ Timeout silence #{timeout_count}: {silence_duration:.1f}s "
                      f"(Total: {self.silence_timeouts})")
        
        # Analyser si trop de silences
        if self.silence_timeouts > 5:
            logger.warning("⚠️ ALERTE: Trop de silences détectés - Problème conversationnel possible")
    
    async def analyze_interaction_quality(self, interaction: InteractionMetrics):
        """Analyse la qualité d'une interaction en temps réel"""
        
        # Alertes en temps réel
        if not interaction.success:
            logger.error(f"🚨 ALERTE: Interaction échouée - {interaction.error_message}")
        
        elif interaction.response_time > 10.0:
            logger.warning(f"⚠️ ALERTE: Temps de réponse lent ({interaction.response_time:.2f}s)")
        
        elif interaction.ai_response_length == 0:
            logger.error("🚨 ALERTE: Réponse IA vide")
        
        elif interaction.ai_response_length > 500:
            logger.warning(f"⚠️ ALERTE: Réponse IA trop longue ({interaction.ai_response_length} chars)")
        
        # Analyse de tendance (dernières 5 interactions)
        if len(self.interactions) >= 5:
            recent_interactions = self.interactions[-5:]
            recent_failures = sum(1 for i in recent_interactions if not i.success)
            
            if recent_failures >= 3:
                logger.error("🚨 ALERTE CRITIQUE: 3+ échecs dans les 5 dernières interactions")
    
    def get_health_report(self) -> ConversationHealthReport:
        """Génère un rapport de santé complet"""
        if not self.interactions:
            return ConversationHealthReport(status="no_data")
        
        # Calculs de base
        total = len(self.interactions)
        successful = sum(1 for i in self.interactions if i.success)
        failed = total - successful
        
        # Temps de réponse moyen
        response_times = [i.response_time for i in self.interactions if i.success]
        avg_response_time = sum(response_times) / len(response_times) if response_times else 0.0
        
        # Score de santé (0-100)
        success_rate = (successful / total) * 100 if total > 0 else 0
        response_penalty = max(0, (avg_response_time - 3.0) * 10)  # Pénalité si > 3s
        silence_penalty = min(self.silence_timeouts * 5, 30)  # Max 30 points de pénalité
        
        health_score = max(0, success_rate - response_penalty - silence_penalty)
        
        # Statut
        if health_score >= 80:
            status = "excellent"
        elif health_score >= 60:
            status = "good"
        elif health_score >= 40:
            status = "fair"
        else:
            status = "poor"
        
        # Recommandations
        recommendations = self.generate_recommendations(success_rate, avg_response_time, self.silence_timeouts)
        
        return ConversationHealthReport(
            total_interactions=total,
            successful_interactions=successful,
            failed_interactions=failed,
            average_response_time=avg_response_time,
            silence_timeouts=self.silence_timeouts,
            health_score=health_score,
            status=status,
            recommendations=recommendations,
            last_updated=datetime.now()
        )
    
    def generate_recommendations(self, success_rate: float, avg_response_time: float, silence_count: int) -> List[str]:
        """Génère des recommandations basées sur les métriques"""
        recommendations = []
        
        if success_rate < 70:
            recommendations.append("🔧 Vérifier la configuration LLM et les clés API")
            recommendations.append("🔧 Analyser les logs d'erreur pour identifier les causes d'échec")
        
        if avg_response_time > 5.0:
            recommendations.append("⚡ Optimiser les paramètres LLM (réduire max_tokens)")
            recommendations.append("⚡ Vérifier la latence réseau vers l'API")
        
        if silence_count > 3:
            recommendations.append("🗣️ Améliorer les instructions de relance conversationnelle")
            recommendations.append("🗣️ Réduire le timeout de silence (actuellement 8s)")
        
        if len(self.interactions) < 5:
            recommendations.append("📊 Collecter plus de données pour une analyse précise")
        
        if not recommendations:
            recommendations.append("✅ Conversation en bonne santé, continuer le monitoring")
        
        return recommendations
    
    def get_detailed_stats(self) -> Dict:
        """Retourne des statistiques détaillées"""
        if not self.interactions:
            return {"status": "no_data"}
        
        # Analyse temporelle
        session_duration = (datetime.now() - self.start_time).total_seconds()
        interactions_per_minute = (len(self.interactions) / session_duration) * 60 if session_duration > 0 else 0
        
        # Analyse des erreurs
        error_types = {}
        for interaction in self.interactions:
            if not interaction.success and interaction.error_message:
                error_types[interaction.error_message] = error_types.get(interaction.error_message, 0) + 1
        
        # Tendances récentes (dernière minute)
        recent_cutoff = datetime.now() - timedelta(minutes=1)
        recent_interactions = [i for i in self.interactions if i.timestamp > recent_cutoff]
        
        return {
            "session_duration_seconds": session_duration,
            "interactions_per_minute": interactions_per_minute,
            "recent_interactions_count": len(recent_interactions),
            "error_breakdown": error_types,
            "health_trend": "improving" if len(recent_interactions) > 0 else "stable"
        }
    
    def stop_monitoring(self):
        """Arrête le monitoring"""
        self.is_monitoring = False
        
        # Rapport final
        final_report = self.get_health_report()
        logger.info(f"📊 RAPPORT FINAL - Santé: {final_report.health_score:.1f}/100 ({final_report.status})")
        logger.info(f"📊 Interactions: {final_report.successful_interactions}/{final_report.total_interactions} réussies")
        logger.info(f"📊 Temps moyen: {final_report.average_response_time:.2f}s")
        
        if final_report.recommendations:
            logger.info("📋 Recommandations:")
            for rec in final_report.recommendations:
                logger.info(f"   {rec}")