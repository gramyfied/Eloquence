from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
import time
import json

@dataclass
class AnalysisResult:
    """Résultat d'analyse générique pour tous exercices"""
    exercise_type: str
    overall_score: float
    detailed_scores: Dict[str, float]
    feedback: str
    recommendations: List[str]
    processing_time: float
    metadata: Dict[str, Any]

class BaseAnalyzer(ABC):
    """Interface commune pour tous les analyseurs d'exercices"""
    
    def __init__(self, exercise_type: str):
        self.exercise_type = exercise_type
        
    @abstractmethod
    async def analyze(
        self, 
        recognition_result: Dict[str, Any],
        config: Optional[str] = None
    ) -> AnalysisResult:
        """Analyse spécifique à chaque type d'exercice"""
        pass
        
    def _parse_config(self, config: Optional[str]) -> Dict[str, Any]:
        """Parse la configuration JSON de l'exercice"""
        if not config:
            return {}
        try:
            return json.loads(config)
        except json.JSONDecodeError:
            return {}
        
    def _calculate_base_metrics(self, recognition_result: Dict[str, Any]) -> Dict[str, float]:
        """Métriques communes à tous exercices"""
        text = recognition_result.get('text', '')
        words = recognition_result.get('words', [])
        confidence = recognition_result.get('confidence', 0)
        speech_metrics = recognition_result.get('speech_metrics', {})
        
        return {
            'speech_confidence': confidence,
            'word_count': len(text.split()),
            'speech_rate': speech_metrics.get('speech_rate', 0),
            'pause_frequency': speech_metrics.get('pause_frequency', 0),
            'fluency_score': speech_metrics.get('fluency_score', 0),
            'clarity_score': confidence,  # Vosk confidence = clarté
            'duration': speech_metrics.get('duration', 0)
        }
        
    def _generate_base_feedback(self, metrics: Dict[str, float]) -> str:
        """Feedback de base commun"""
        feedback_parts = []
        
        if metrics.get('speech_confidence', 0) > 0.8:
            feedback_parts.append("Excellente clarté de prononciation.")
        elif metrics.get('speech_confidence', 0) > 0.6:
            feedback_parts.append("Bonne clarté générale, quelques améliorations possibles.")
        else:
            feedback_parts.append("Travaillez sur la clarté de votre prononciation.")
            
        if metrics.get('speech_rate', 0) > 180:
            feedback_parts.append("Débit un peu rapide, pensez à ralentir.")
        elif metrics.get('speech_rate', 0) < 120:
            feedback_parts.append("Débit un peu lent, vous pouvez accélérer légèrement.")
        else:
            feedback_parts.append("Excellent débit de parole.")
            
        return " ".join(feedback_parts)
        
    def _generate_base_recommendations(self, metrics: Dict[str, float]) -> List[str]:
        """Recommandations de base communes"""
        recommendations = []
        
        if metrics.get('pause_frequency', 0) > 0.3:
            recommendations.append("Réduisez les pauses pour améliorer la fluidité")
            
        if metrics.get('speech_confidence', 0) < 0.7:
            recommendations.append("Travaillez sur l'articulation et la prononciation")
            
        if metrics.get('speech_rate', 0) < 120:
            recommendations.append("Augmentez légèrement votre débit de parole")
            
        return recommendations