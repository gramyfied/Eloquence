from .base_analyzer import BaseAnalyzer, AnalysisResult
from typing import Dict, Any, Optional, List
import time
import re

class ConfidenceAnalyzer(BaseAnalyzer):
    """Analyseur spécialisé pour exercices de confiance"""
    
    def __init__(self):
        super().__init__("confidence")
        
    async def analyze(
        self, 
        recognition_result: Dict[str, Any],
        config: Optional[str] = None
    ) -> AnalysisResult:
        
        start_time = time.time()
        
        # Configuration de l'exercice
        exercise_config = self._parse_config(config)
        scenario = exercise_config.get('scenario', {})
        
        # Métriques de base
        base_metrics = self._calculate_base_metrics(recognition_result)
        
        # Analyse spécifique confiance
        confidence_metrics = self._analyze_confidence_specific(
            recognition_result, scenario
        )
        
        # Scores détaillés
        detailed_scores = {
            **base_metrics,
            **confidence_metrics
        }
        
        # Score global optimisé
        overall_score = self._calculate_confidence_score(detailed_scores)
        
        # Feedback personnalisé
        feedback = self._generate_confidence_feedback(
            recognition_result, detailed_scores, scenario
        )
        
        # Recommandations
        recommendations = self._generate_confidence_recommendations(detailed_scores)
        
        processing_time = (time.time() - start_time) * 1000
        
        return AnalysisResult(
            exercise_type=self.exercise_type,
            overall_score=overall_score,
            detailed_scores=detailed_scores,
            feedback=feedback,
            recommendations=recommendations,
            processing_time=processing_time,
            metadata={
                'scenario': scenario,
                'word_analysis': self._analyze_words(recognition_result),
                'vosk_confidence': recognition_result.get('confidence', 0),
                'speech_metrics': recognition_result.get('speech_metrics', {})
            }
        )
        
    def _analyze_confidence_specific(
        self, 
        recognition_result: Dict[str, Any], 
        scenario: Dict[str, Any]
    ) -> Dict[str, float]:
        """Analyse spécifique aux exercices de confiance"""
        
        text = recognition_result.get('text', '').lower()
        words = recognition_result.get('words', [])
        speech_metrics = recognition_result.get('speech_metrics', {})
        
        # Mots-clés du scénario
        scenario_keywords = scenario.get('keywords', [])
        keyword_matches = sum(1 for kw in scenario_keywords if kw.lower() in text)
        keyword_score = min(keyword_matches / max(1, len(scenario_keywords)), 1.0)
        
        # Analyse des hésitations
        hesitation_patterns = ['euh', 'hum', 'alors', 'donc', 'en fait', 'voilà']
        hesitations = sum(1 for pattern in hesitation_patterns if pattern in text)
        hesitation_score = max(0, 1 - (hesitations / max(1, len(text.split()) * 0.1)))
        
        # Analyse de l'assertivité
        assertive_words = ['je pense', 'je crois', 'certainement', 'absolument', 'clairement']
        assertiveness = sum(1 for word in assertive_words if word in text)
        assertiveness_score = min(assertiveness / max(1, len(text.split()) * 0.05), 1.0)
        
        # Énergie vocale (basée sur variation de confiance)
        energy_score = 1 - speech_metrics.get('confidence_variance', 0)
        
        return {
            'keyword_relevance': keyword_score,
            'hesitation_control': hesitation_score,
            'assertiveness': assertiveness_score,
            'energy_level': max(0, min(energy_score, 1))
        }
        
    def _calculate_confidence_score(self, metrics: Dict[str, float]) -> float:
        """Calcul du score de confiance optimisé"""
        
        weights = {
            'speech_confidence': 0.25,
            'keyword_relevance': 0.20,
            'hesitation_control': 0.20,
            'assertiveness': 0.15,
            'fluency_score': 0.15,
            'energy_level': 0.05
        }
        
        weighted_score = sum(
            metrics.get(metric, 0) * weight 
            for metric, weight in weights.items()
        )
        
        return min(max(weighted_score * 100, 0), 100)
        
    def _generate_confidence_feedback(
        self, 
        recognition_result: Dict[str, Any],
        metrics: Dict[str, float], 
        scenario: Dict[str, Any]
    ) -> str:
        """Génère un feedback spécifique à la confiance"""
        
        feedback_parts = []
        
        # Feedback base
        base_feedback = self._generate_base_feedback(metrics)
        feedback_parts.append(base_feedback)
        
        # Feedback spécifique confiance
        if metrics.get('assertiveness', 0) > 0.7:
            feedback_parts.append("Excellent niveau d'assertivité dans votre discours.")
        elif metrics.get('assertiveness', 0) > 0.4:
            feedback_parts.append("Bonne assertivité, vous pouvez être encore plus affirmatif.")
        else:
            feedback_parts.append("Travaillez sur l'assertivité de votre discours.")
            
        if metrics.get('hesitation_control', 0) > 0.8:
            feedback_parts.append("Très bonne maîtrise, peu d'hésitations.")
        else:
            feedback_parts.append("Réduisez les hésitations pour plus d'impact.")
            
        return " ".join(feedback_parts)
        
    def _generate_confidence_recommendations(self, metrics: Dict[str, float]) -> List[str]:
        """Génère des recommandations spécifiques à la confiance"""
        
        recommendations = self._generate_base_recommendations(metrics)
        
        if metrics.get('assertiveness', 0) < 0.5:
            recommendations.append("Utilisez plus d'expressions affirmatives")
            
        if metrics.get('hesitation_control', 0) < 0.7:
            recommendations.append("Préparez mieux vos idées pour éviter les hésitations")
            
        if metrics.get('keyword_relevance', 0) < 0.6:
            recommendations.append("Intégrez plus de mots-clés pertinents au sujet")
            
        return recommendations
        
    def _analyze_words(self, recognition_result: Dict[str, Any]) -> Dict[str, Any]:
        """Analyse détaillée des mots pour métadonnées"""
        
        words = recognition_result.get('words', [])
        text = recognition_result.get('text', '')
        
        return {
            'total_words': len(words),
            'unique_words': len(set([w.get('word', '') for w in words])),
            'avg_word_confidence': sum([w.get('conf', 0) for w in words]) / len(words) if words else 0,
            'text_length': len(text),
            'vocabulary_richness': len(set(text.split())) / len(text.split()) if text.split() else 0
        }