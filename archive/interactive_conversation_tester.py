#!/usr/bin/env python3
"""
Système de Test Conversationnel Interactif avec Auto-Réparation
Teste l'IA Marie avec conversations adaptatives et métriques exhaustives
"""

import asyncio
import json
import requests
import tempfile
import wave
import numpy as np
import time
import logging
import os
import random
from pathlib import Path
from typing import Optional, Dict, Any, List, Union
from datetime import datetime
from dataclasses import dataclass, asdict
import aiohttp
from livekit import rtc

# Configuration du logging sans émojis (compatible Windows)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('conversation_test.log', encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)

# Configuration des services existants
VOSK_SERVICE_URL = "http://localhost:2700"
OPENAI_TTS_URL = "http://localhost:5002"
LIVEKIT_URL = "ws://localhost:7880"
API_BACKEND_URL = "http://localhost:8000"
AGENT_SERVICE_URL = "http://localhost:8080"

# Configuration pour tests
MAX_EXCHANGES = 10
SAMPLE_RATE = 16000

@dataclass
class ConversationMetrics:
    """Collecte exhaustive de 30+ métriques par échange"""
    
    # Identifiants d'échange
    exchange_number: int
    timestamp: float
    user_message: str
    ai_response: str
    conversation_state: str
    
    # Métriques temporelles (5 métriques)
    tts_response_time: float
    vosk_response_time: float
    mistral_response_time: float
    total_exchange_time: float
    user_wait_time: float
    
    # Métriques qualité audio (5 métriques)
    audio_quality_score: float
    transcription_confidence: float
    audio_duration: float
    signal_to_noise_ratio: float
    voice_activity_detection: float
    
    # Métriques qualité IA (5 métriques)
    response_relevance: float
    response_coherence: float
    response_engagement: float
    response_naturalness: float
    context_awareness: float
    
    # Métriques conversationnelles (5 métriques)
    topic_continuity: float
    conversation_flow_score: float
    user_satisfaction_estimate: float
    conversation_progress: float
    response_appropriateness: float
    
    # Métriques techniques (5 métriques)
    api_response_time: float
    total_tokens_used: int
    cost_estimate: float
    error_count: int
    retry_count: int
    
    # Métriques d'analyse (5+ métriques)
    word_count: int
    sentence_count: int
    question_count: int
    enthusiasm_score: float
    formality_score: float
    politeness_score: float
    
    # Détection de problèmes
    issues_detected: List[str]
    repairs_applied: List[str]

class ConversationMetricsCollector:
    """Collecteur de toutes les métriques conversationnelles"""
    
    def __init__(self):
        self.conversation_metrics: List[ConversationMetrics] = []
        self.global_metrics = {}
        self.quality_trends = []
        self.exchange_history = []  # Historique des échanges bruts
    
    def collect_exchange_metrics(self, exchange_data: Dict[str, Any]) -> ConversationMetrics:
        """Collecte les métriques d'un échange complet"""
        
        metrics = ConversationMetrics(
            exchange_number=len(self.conversation_metrics) + 1,
            timestamp=time.time(),
            user_message=exchange_data.get('user_message', ''),
            ai_response=exchange_data.get('ai_response', ''),
            conversation_state=exchange_data.get('conversation_state', ''),
            
            # Métriques temporelles
            tts_response_time=exchange_data.get('tts_time', 0.0),
            vosk_response_time=exchange_data.get('vosk_time', 0.0),
            mistral_response_time=exchange_data.get('mistral_time', 0.0),
            total_exchange_time=exchange_data.get('total_time', 0.0),
            user_wait_time=exchange_data.get('total_time', 0.0),
            
            # Métriques qualité audio
            audio_quality_score=exchange_data.get('audio_quality', 0.0),
            transcription_confidence=exchange_data.get('vosk_confidence', 0.0),
            audio_duration=exchange_data.get('audio_duration', 0.0),
            signal_to_noise_ratio=exchange_data.get('snr', 0.0),
            voice_activity_detection=exchange_data.get('vad_score', 0.0),
            
            # Métriques qualité IA
            response_relevance=self._calculate_relevance(exchange_data),
            response_coherence=self._calculate_coherence(exchange_data),
            response_engagement=self._calculate_engagement(exchange_data),
            response_naturalness=self._calculate_naturalness(exchange_data),
            context_awareness=self._calculate_context_awareness(exchange_data),
            
            # Métriques conversationnelles
            topic_continuity=self._measure_topic_continuity(exchange_data),
            conversation_flow_score=self._measure_conversation_flow(exchange_data),
            user_satisfaction_estimate=self._estimate_user_satisfaction(exchange_data),
            conversation_progress=self._measure_progress(exchange_data),
            response_appropriateness=self._measure_appropriateness(exchange_data),
            
            # Métriques techniques
            api_response_time=exchange_data.get('api_latency', 0.0),
            total_tokens_used=exchange_data.get('tokens_used', 0),
            cost_estimate=exchange_data.get('cost_estimate', 0.0),
            error_count=exchange_data.get('error_count', 0),
            retry_count=exchange_data.get('retry_count', 0),
            
            # Métriques d'analyse
            word_count=len(exchange_data.get('ai_response', '').split()),
            sentence_count=exchange_data.get('ai_response', '').count('.') + exchange_data.get('ai_response', '').count('!') + exchange_data.get('ai_response', '').count('?'),
            question_count=exchange_data.get('ai_response', '').count('?'),
            enthusiasm_score=self._calculate_enthusiasm(exchange_data),
            formality_score=self._calculate_formality(exchange_data),
            politeness_score=self._calculate_politeness(exchange_data),
            
            # Détection de problèmes
            issues_detected=exchange_data.get('issues_detected', []),
            repairs_applied=exchange_data.get('repairs_applied', [])
        )
        
        self.conversation_metrics.append(metrics)
        self._update_quality_trends(metrics)
        
        return metrics
    
    def _calculate_relevance(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule la pertinence de la réponse IA"""
        user_msg = exchange_data.get('user_message', '').lower()
        ai_response = exchange_data.get('ai_response', '').lower()
        expected_keywords = exchange_data.get('expected_keywords', [])
        
        relevance_score = 0.0
        for keyword in expected_keywords:
            if keyword.lower() in ai_response:
                relevance_score += 1.0
        
        if expected_keywords:
            relevance_score = relevance_score / len(expected_keywords)
        
        return min(relevance_score, 1.0)
    
    def _calculate_coherence(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule la cohérence logique de la réponse"""
        ai_response = exchange_data.get('ai_response', '')
        
        coherence_score = 0.5  # Score de base
        
        # Bonus si la réponse contient une question (engagement)
        if '?' in ai_response:
            coherence_score += 0.2
        
        # Bonus si la réponse est ni trop courte ni trop longue
        word_count = len(ai_response.split())
        if 5 <= word_count <= 50:
            coherence_score += 0.2
        
        # Malus si réponse générique
        generic_phrases = ['très intéressant', 'je vois', 'c\'est bien', 'pouvez-vous']
        if any(phrase in ai_response.lower() for phrase in generic_phrases):
            coherence_score -= 0.3
        
        return max(0.0, min(coherence_score, 1.0))
    
    def _calculate_engagement(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule le niveau d'engagement de la réponse"""
        ai_response = exchange_data.get('ai_response', '')
        
        engagement_score = 0.0
        
        # Questions directes
        if '?' in ai_response:
            engagement_score += 0.3
        
        # Encouragements
        encouraging_words = ['excellent', 'très bien', 'parfait', 'continuez', 'bravo']
        for word in encouraging_words:
            if word in ai_response.lower():
                engagement_score += 0.1
        
        # Personnalisation
        personal_words = ['vous', 'votre', 'votre']
        personal_count = sum(1 for word in personal_words if word in ai_response.lower())
        engagement_score += min(personal_count * 0.1, 0.3)
        
        return min(engagement_score, 1.0)
    
    def _calculate_naturalness(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule le naturel de la réponse"""
        ai_response = exchange_data.get('ai_response', '')
        
        # Score basé sur la longueur et structure
        word_count = len(ai_response.split())
        if 10 <= word_count <= 30:
            naturalness = 0.8
        elif 5 <= word_count <= 50:
            naturalness = 0.6
        else:
            naturalness = 0.3
        
        # Bonus pour contractions et langage naturel
        natural_patterns = ['n\'est', 'c\'est', 'qu\'', 'j\'ai', 'vous\'']
        if any(pattern in ai_response.lower() for pattern in natural_patterns):
            naturalness += 0.2
        
        return min(naturalness, 1.0)
    
    def _calculate_context_awareness(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule la conscience du contexte"""
        conversation_state = exchange_data.get('conversation_state', '')
        ai_response = exchange_data.get('ai_response', '').lower()
        
        context_score = 0.5  # Score de base
        
        # Vérification de la cohérence avec l'état de conversation
        state_keywords = {
            'greeting': ['bonjour', 'salut', 'ravi', 'plaisir'],
            'presentation': ['projet', 'solution', 'présenter', 'expliquer'],
            'questions_reponses': ['question', 'détail', 'préciser', 'comment'],
            'negociation': ['prix', 'coût', 'budget', 'tarif'],
            'closing': ['signature', 'contrat', 'accord', 'prochaine']
        }
        
        expected_keywords = state_keywords.get(conversation_state, [])
        if expected_keywords:
            keyword_matches = sum(1 for keyword in expected_keywords if keyword in ai_response)
            context_score = keyword_matches / len(expected_keywords)
        
        return min(context_score, 1.0)
    
    def _measure_topic_continuity(self, exchange_data: Dict[str, Any]) -> float:
        """Mesure la continuité du sujet"""
        if len(self.conversation_metrics) == 0:
            return 1.0  # Premier échange
        
        # Analyse simple basée sur les mots-clés communs
        current_response = exchange_data.get('ai_response', '').lower().split()
        previous_response = self.conversation_metrics[-1].ai_response.lower().split()
        
        common_words = set(current_response) & set(previous_response)
        common_words = {word for word in common_words if len(word) > 3}  # Mots significatifs
        
        if len(current_response) + len(previous_response) > 0:
            continuity = len(common_words) / (len(set(current_response + previous_response)) + 1e-6)
        else:
            continuity = 0.0
        
        return min(continuity * 2, 1.0)  # Normalisation
    
    def _measure_conversation_flow(self, exchange_data: Dict[str, Any]) -> float:
        """Mesure la fluidité de la conversation"""
        total_time = exchange_data.get('total_time', 0.0)
        
        # Score basé sur le temps de réponse
        if total_time <= 2.0:
            flow_score = 1.0
        elif total_time <= 5.0:
            flow_score = 0.8
        elif total_time <= 10.0:
            flow_score = 0.6
        else:
            flow_score = 0.3
        
        # Bonus si pas d'erreurs
        error_count = exchange_data.get('error_count', 0)
        if error_count == 0:
            flow_score += 0.1
        
        return min(flow_score, 1.0)
    
    def _estimate_user_satisfaction(self, exchange_data: Dict[str, Any]) -> float:
        """Estime la satisfaction utilisateur"""
        # Combinaison de plusieurs facteurs
        relevance = self._calculate_relevance(exchange_data)
        engagement = self._calculate_engagement(exchange_data)
        coherence = self._calculate_coherence(exchange_data)
        flow = self._measure_conversation_flow(exchange_data)
        
        satisfaction = (relevance * 0.3 + engagement * 0.3 + coherence * 0.2 + flow * 0.2)
        
        return satisfaction
    
    def _measure_progress(self, exchange_data: Dict[str, Any]) -> float:
        """Mesure le progrès de la conversation"""
        state_progression = {
            'greeting': 0.1,
            'presentation': 0.3,
            'questions_reponses': 0.6,
            'negociation': 0.8,
            'closing': 1.0
        }
        
        current_state = exchange_data.get('conversation_state', 'greeting')
        return state_progression.get(current_state, 0.5)
    
    def _measure_appropriateness(self, exchange_data: Dict[str, Any]) -> float:
        """Mesure l'appropriété de la réponse"""
        ai_response = exchange_data.get('ai_response', '')
        conversation_state = exchange_data.get('conversation_state', '')
        
        # Score de base
        appropriateness = 0.7
        
        # Vérifications spécifiques par état
        if conversation_state == 'greeting' and any(word in ai_response.lower() for word in ['bonjour', 'salut', 'ravi']):
            appropriateness += 0.2
        elif conversation_state == 'negociation' and any(word in ai_response.lower() for word in ['prix', 'coût', 'budget']):
            appropriateness += 0.2
        elif conversation_state == 'closing' and any(word in ai_response.lower() for word in ['signature', 'contrat']):
            appropriateness += 0.2
        
        return min(appropriateness, 1.0)
    
    def _calculate_enthusiasm(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule le score d'enthousiasme"""
        ai_response = exchange_data.get('ai_response', '')
        
        enthusiasm_indicators = ['!', 'excellent', 'fantastique', 'parfait', 'merveilleux', 'génial']
        enthusiasm_count = sum(ai_response.lower().count(indicator) for indicator in enthusiasm_indicators)
        
        return min(enthusiasm_count / 3.0, 1.0)
    
    def _calculate_formality(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule le niveau de formalité"""
        ai_response = exchange_data.get('ai_response', '').lower()
        
        formal_indicators = ['monsieur', 'madame', 'vous', 'veuillez', 'permettez-moi']
        informal_indicators = ['salut', 'coucou', 'tu', 'ça va']
        
        formal_count = sum(1 for indicator in formal_indicators if indicator in ai_response)
        informal_count = sum(1 for indicator in informal_indicators if indicator in ai_response)
        
        if formal_count + informal_count == 0:
            return 0.5  # Neutre
        
        return formal_count / (formal_count + informal_count)
    
    def _calculate_politeness(self, exchange_data: Dict[str, Any]) -> float:
        """Calcule le score de politesse"""
        ai_response = exchange_data.get('ai_response', '').lower()
        
        polite_indicators = ['merci', 's\'il vous plaît', 'excusez-moi', 'permettez', 'avec plaisir']
        politeness_count = sum(1 for indicator in polite_indicators if indicator in ai_response)
        
        return min(politeness_count / 2.0, 1.0)
    
    def _update_quality_trends(self, metrics: ConversationMetrics):
        """Met à jour les tendances de qualité"""
        quality_score = (
            metrics.response_relevance * 0.25 +
            metrics.response_coherence * 0.25 +
            metrics.response_engagement * 0.25 +
            metrics.conversation_flow_score * 0.25
        )
        
        self.quality_trends.append({
            'exchange': metrics.exchange_number,
            'timestamp': metrics.timestamp,
            'quality_score': quality_score
        })
    
    def generate_conversation_report(self) -> Dict[str, Any]:
        """Génère un rapport complet de la conversation"""
        
        if not self.conversation_metrics:
            return {'error': 'Aucune métrique collectée'}
        
        # Calculer les moyennes
        avg_metrics = self._calculate_averages()
        
        # Analyser les tendances
        trends = self._analyze_trends()
        
        # Identifier les problèmes récurrents
        recurring_issues = self._identify_recurring_issues()
        
        # Recommandations d'amélioration
        recommendations = self._generate_recommendations()
        
        return {
            'conversation_summary': {
                'total_exchanges': len(self.conversation_metrics),
                'conversation_duration': self._calculate_total_duration(),
                'final_state': self.conversation_metrics[-1].conversation_state,
                'success_rate': self._calculate_success_rate()
            },
            'performance_averages': avg_metrics,
            'quality_trends': trends,
            'recurring_issues': recurring_issues,
            'recommendations': recommendations,
            'detailed_exchanges': [asdict(m) for m in self.conversation_metrics]
        }
    
    def _calculate_averages(self) -> Dict[str, float]:
        """Calcule les moyennes des métriques"""
        if not self.conversation_metrics:
            return {}
        
        metrics_sums = {}
        for metric in self.conversation_metrics:
            metric_dict = asdict(metric)
            for key, value in metric_dict.items():
                if isinstance(value, (int, float)) and key != 'timestamp':
                    if key not in metrics_sums:
                        metrics_sums[key] = []
                    metrics_sums[key].append(value)
        
        averages = {}
        for key, values in metrics_sums.items():
            if values:
                averages[f'avg_{key}'] = sum(values) / len(values)
        
        return averages
    
    def _analyze_trends(self) -> Dict[str, Any]:
        """Analyse les tendances de qualité"""
        if len(self.quality_trends) < 2:
            return {'trend': 'insufficient_data'}
        
        scores = [t['quality_score'] for t in self.quality_trends]
        
        # Calcul de la tendance (simple slope)
        x = list(range(len(scores)))
        y = scores
        n = len(x)
        
        slope = (n * sum(x[i] * y[i] for i in range(n)) - sum(x) * sum(y)) / (n * sum(x[i]**2 for i in range(n)) - sum(x)**2)
        
        trend_direction = 'improving' if slope > 0.01 else 'declining' if slope < -0.01 else 'stable'
        
        return {
            'trend': trend_direction,
            'slope': slope,
            'initial_score': scores[0],
            'final_score': scores[-1],
            'best_score': max(scores),
            'worst_score': min(scores)
        }
    
    def _identify_recurring_issues(self) -> List[Dict[str, Any]]:
        """Identifie les problèmes récurrents"""
        issue_counts = {}
        
        for metric in self.conversation_metrics:
            for issue in metric.issues_detected:
                if issue not in issue_counts:
                    issue_counts[issue] = 0
                issue_counts[issue] += 1
        
        recurring_issues = []
        for issue, count in issue_counts.items():
            if count > 1:  # Considéré comme récurrent si apparaît plus d'une fois
                recurring_issues.append({
                    'issue': issue,
                    'occurrences': count,
                    'frequency': count / len(self.conversation_metrics)
                })
        
        return sorted(recurring_issues, key=lambda x: x['occurrences'], reverse=True)
    
    def _generate_recommendations(self) -> List[str]:
        """Génère des recommandations d'amélioration"""
        recommendations = []
        
        if not self.conversation_metrics:
            return recommendations
        
        # Analyse des moyennes pour recommandations
        avg_relevance = sum(m.response_relevance for m in self.conversation_metrics) / len(self.conversation_metrics)
        avg_engagement = sum(m.response_engagement for m in self.conversation_metrics) / len(self.conversation_metrics)
        avg_flow = sum(m.conversation_flow_score for m in self.conversation_metrics) / len(self.conversation_metrics)
        avg_response_time = sum(m.total_exchange_time for m in self.conversation_metrics) / len(self.conversation_metrics)
        
        if avg_relevance < 0.6:
            recommendations.append("Améliorer la pertinence des réponses en analysant mieux le contexte utilisateur")
        
        if avg_engagement < 0.5:
            recommendations.append("Augmenter l'engagement en posant plus de questions et en montrant plus d'enthousiasme")
        
        if avg_flow < 0.6:
            recommendations.append("Améliorer la fluidité conversationnelle en réduisant les temps de réponse")
        
        if avg_response_time > 5.0:
            recommendations.append("Optimiser les performances pour réduire le temps de réponse")
        
        # Analyse des problèmes récurrents
        recurring_issues = self._identify_recurring_issues()
        for issue_info in recurring_issues:
            if issue_info['frequency'] > 0.3:  # Si plus de 30% d'occurrences
                recommendations.append(f"Résoudre le problème récurrent: {issue_info['issue']}")
        
        return recommendations
    
    def _calculate_total_duration(self) -> float:
        """Calcule la durée totale de la conversation"""
        if not self.conversation_metrics:
            return 0.0
        
        return sum(m.total_exchange_time for m in self.conversation_metrics)
    
    def _calculate_success_rate(self) -> float:
        """Calcule le taux de succès global"""
        if not self.conversation_metrics:
            return 0.0
        
        successful_exchanges = sum(1 for m in self.conversation_metrics if len(m.issues_detected) == 0)
        return successful_exchanges / len(self.conversation_metrics)

if __name__ == "__main__":
    # Test basique du collecteur de métriques
    logger.info("Test du collecteur de métriques conversationnelles")
    
    collector = ConversationMetricsCollector()
    
    # Données d'échange simulées
    test_exchange = {
        'user_message': 'Bonjour, comment allez-vous ?',
        'ai_response': 'Bonjour ! Je vais très bien, merci. Comment puis-je vous aider aujourd\'hui ?',
        'conversation_state': 'greeting',
        'tts_time': 1.2,
        'vosk_time': 0.8,
        'mistral_time': 2.1,
        'total_time': 4.1,
        'audio_quality': 0.9,
        'vosk_confidence': 0.85,
        'audio_duration': 3.0,
        'expected_keywords': ['bonjour', 'aider'],
        'issues_detected': [],
        'repairs_applied': []
    }
    
    metrics = collector.collect_exchange_metrics(test_exchange)
    logger.info(f"Métriques collectées: {metrics.exchange_number} échanges")
    logger.info(f"Score de pertinence: {metrics.response_relevance:.2f}")
    logger.info(f"Score d'engagement: {metrics.response_engagement:.2f}")
    logger.info(f"Score de cohérence: {metrics.response_coherence:.2f}")
    
    # Test rapport
    report = collector.generate_conversation_report()
    logger.info("Rapport généré avec succès")
    
    print("Test du collecteur de métriques terminé avec succès")