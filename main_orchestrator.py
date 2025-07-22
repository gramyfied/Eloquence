#!/usr/bin/env python3
"""
Orchestrateur Principal du Test Conversationnel Interactif
Coordonne tous les composants pour une conversation adaptative complète
"""

import asyncio
import json
import time
import logging
import tempfile
import wave
import numpy as np
from pathlib import Path
from typing import Dict, Any, Optional, List
from dataclasses import dataclass, asdict

# Imports des composants créés
from interactive_conversation_tester import ConversationMetricsCollector
from conversation_engine import (
    IntelligentConversationEngine, 
    AutoRepairSystem, 
    ConversationState, 
    UserPersonality
)
from service_wrappers import RealTTSService, RealVoskService, RealMistralService

logger = logging.getLogger(__name__)

@dataclass
class TestConfiguration:
    """Configuration du test conversationnel"""
    max_exchanges: int = 10
    scenario_type: str = "presentation_client"
    user_personality: str = "commercial_confiant"
    target_conversation_states: List[str] = None
    enable_auto_repair: bool = True
    enable_real_time_metrics: bool = True
    save_audio_files: bool = False
    conversation_timeout: float = 300.0  # 5 minutes max
    exchange_timeout: float = 30.0  # 30 secondes par échange

@dataclass
class ExchangeResult:
    """Résultat d'un échange complet"""
    exchange_number: int
    user_message: str
    ai_response: str
    conversation_state: str
    success: bool
    metrics: Dict[str, Any]
    issues_detected: List[str]
    repairs_applied: List[str]
    total_time: float
    component_times: Dict[str, float]

class RealTimeAnomalyDetector:
    """Détecteur d'anomalies en temps réel pendant la conversation"""
    
    def __init__(self):
        self.anomaly_thresholds = {
            'response_time_threshold': 15.0,  # secondes
            'confidence_threshold': 0.6,
            'relevance_threshold': 0.5,
            'engagement_threshold': 0.4,
            'consecutive_failures_threshold': 2
        }
        
        self.anomaly_history = []
        self.current_anomalies = []
    
    def detect_anomalies(self, exchange_result: ExchangeResult, previous_exchanges: List[ExchangeResult]) -> List[str]:
        """Détecte les anomalies en temps réel"""
        
        anomalies = []
        metrics = exchange_result.metrics
        
        # Anomalie de temps de réponse
        if exchange_result.total_time > self.anomaly_thresholds['response_time_threshold']:
            anomalies.append('excessive_response_time')
        
        # Anomalie de confiance VOSK
        vosk_confidence = metrics.get('transcription_confidence', 1.0)
        if vosk_confidence < self.anomaly_thresholds['confidence_threshold']:
            anomalies.append('low_transcription_confidence')
        
        # Anomalie de pertinence IA
        ai_relevance = metrics.get('response_relevance', 1.0)
        if ai_relevance < self.anomaly_thresholds['relevance_threshold']:
            anomalies.append('low_ai_relevance')
        
        # Anomalie d'engagement
        ai_engagement = metrics.get('response_engagement', 1.0)
        if ai_engagement < self.anomaly_thresholds['engagement_threshold']:
            anomalies.append('low_ai_engagement')
        
        # Anomalie d'échecs consécutifs
        if len(previous_exchanges) >= 2:
            recent_failures = sum(1 for ex in previous_exchanges[-2:] if not ex.success)
            if recent_failures >= self.anomaly_thresholds['consecutive_failures_threshold']:
                anomalies.append('consecutive_failures')
        
        # Anomalie de régression de qualité
        if len(previous_exchanges) >= 3:
            recent_scores = [ex.metrics.get('user_satisfaction_estimate', 0.5) for ex in previous_exchanges[-3:]]
            if all(recent_scores[i] > recent_scores[i+1] for i in range(len(recent_scores)-1)):
                anomalies.append('quality_regression')
        
        # Anomalie de blocage conversationnel
        if exchange_result.conversation_state == previous_exchanges[-1].conversation_state if previous_exchanges else False:
            if len(previous_exchanges) >= 2 and all(ex.conversation_state == exchange_result.conversation_state for ex in previous_exchanges[-2:]):
                anomalies.append('conversation_state_stuck')
        
        # Enregistrer les anomalies
        if anomalies:
            self.current_anomalies.extend(anomalies)
            self.anomaly_history.append({
                'exchange_number': exchange_result.exchange_number,
                'timestamp': time.time(),
                'anomalies': anomalies,
                'severity': self._calculate_severity(anomalies)
            })
        
        return anomalies
    
    def _calculate_severity(self, anomalies: List[str]) -> str:
        """Calcule la sévérité des anomalies"""
        
        severe_anomalies = ['consecutive_failures', 'excessive_response_time']
        moderate_anomalies = ['quality_regression', 'conversation_state_stuck']
        
        if any(anomaly in severe_anomalies for anomaly in anomalies):
            return 'severe'
        elif any(anomaly in moderate_anomalies for anomaly in anomalies):
            return 'moderate'
        else:
            return 'minor'
    
    def get_anomaly_summary(self) -> Dict[str, Any]:
        """Retourne un résumé des anomalies détectées"""
        
        if not self.anomaly_history:
            return {'no_anomalies': True}
        
        anomaly_counts = {}
        for record in self.anomaly_history:
            for anomaly in record['anomalies']:
                anomaly_counts[anomaly] = anomaly_counts.get(anomaly, 0) + 1
        
        severity_counts = {}
        for record in self.anomaly_history:
            severity = record['severity']
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
        
        return {
            'total_anomaly_events': len(self.anomaly_history),
            'unique_anomaly_types': len(anomaly_counts),
            'anomaly_breakdown': anomaly_counts,
            'severity_breakdown': severity_counts,
            'current_active_anomalies': len(self.current_anomalies),
            'anomaly_timeline': self.anomaly_history
        }

class InteractiveConversationTester:
    """Orchestrateur principal du test conversationnel interactif"""
    
    def __init__(self, config: TestConfiguration = None):
        self.config = config or TestConfiguration()
        
        # Initialisation des composants
        self.conversation_engine = IntelligentConversationEngine()
        self.metrics_collector = ConversationMetricsCollector()
        self.auto_repair = AutoRepairSystem()
        self.anomaly_detector = RealTimeAnomalyDetector()
        
        # Services réels
        self.tts_service = RealTTSService(base_url="http://localhost:5002")
        self.vosk_service = RealVoskService(base_url="http://localhost:2700")
        self.mistral_service = RealMistralService(api_key=None, model="mistral-nemo-instruct-2407")
        
        # État du test
        self.current_exchange = 0
        self.conversation_active = True
        self.exchange_results: List[ExchangeResult] = []
        self.global_start_time = None
        
        # Configuration de la personnalité utilisateur
        personality_map = {
            "commercial_confiant": UserPersonality.COMMERCIAL_CONFIANT,
            "client_exigeant": UserPersonality.CLIENT_EXIGEANT,
            "prospect_interesse": UserPersonality.PROSPECT_INTERESSE,
            "decision_maker": UserPersonality.DECISION_MAKER,
            "technicien_sceptique": UserPersonality.TECHNICIEN_SCEPTIQUE
        }
        
        self.conversation_engine.context.personality = personality_map.get(
            self.config.user_personality, 
            UserPersonality.COMMERCIAL_CONFIANT
        )
        
        self.conversation_engine.context.scenario_type = self.config.scenario_type
    
    async def run_interactive_conversation_test(self) -> Dict[str, Any]:
        """Lance le test conversationnel interactif complet"""
        
        logger.info("=== DÉBUT TEST CONVERSATIONNEL INTERACTIF ===")
        self.global_start_time = time.time()
        
        try:
            # Validation préalable des services
            await self._validate_all_services()
            
            # Démarrage de la conversation
            ai_last_response = None
            
            while self.conversation_active and self.current_exchange < self.config.max_exchanges:
                try:
                    # Vérification du timeout global
                    if time.time() - self.global_start_time > self.config.conversation_timeout:
                        logger.warning("Timeout global atteint, arrêt de la conversation")
                        break
                    
                    # Exécuter un échange complet
                    exchange_result = await self._execute_complete_exchange(ai_last_response)
                    
                    # Ajouter à l'historique
                    self.exchange_results.append(exchange_result)
                    
                    # Détection d'anomalies en temps réel
                    if self.config.enable_real_time_metrics:
                        anomalies = self.anomaly_detector.detect_anomalies(exchange_result, self.exchange_results[:-1])
                        exchange_result.issues_detected.extend(anomalies)
                    
                    # Auto-réparation si nécessaire
                    if self.config.enable_auto_repair and exchange_result.issues_detected:
                        await self._handle_detected_issues(exchange_result)
                    
                    # Préparer pour le prochain échange
                    ai_last_response = exchange_result.ai_response
                    self.current_exchange += 1
                    
                    # Vérifier si la conversation doit continuer
                    self.conversation_active = self._should_continue_conversation(exchange_result)
                    
                    # Log de progression
                    logger.info(f"Échange {exchange_result.exchange_number} terminé: "
                              f"état={exchange_result.conversation_state}, "
                              f"succès={exchange_result.success}, "
                              f"temps={exchange_result.total_time:.2f}s")
                
                except Exception as e:
                    logger.error(f"Erreur dans l'échange {self.current_exchange + 1}: {e}")
                    
                    # Tentative de réparation d'urgence
                    if self.config.enable_auto_repair:
                        repair_result = self.auto_repair.repair_issue(
                            'exchange_error', 
                            self.conversation_engine.context.current_state.value,
                            {'error': str(e), 'exchange_number': self.current_exchange}
                        )
                        
                        if not repair_result['success']:
                            logger.error("Échec de la réparation d'urgence, arrêt du test")
                            break
                    else:
                        break
            
            # Génération du rapport final
            final_report = await self._generate_final_report()
            
            logger.info("=== TEST CONVERSATIONNEL TERMINÉ ===")
            logger.info(f"Échanges réalisés: {len(self.exchange_results)}")
            logger.info(f"État final: {self.conversation_engine.context.current_state.value}")
            logger.info(f"Durée totale: {time.time() - self.global_start_time:.1f}s")
            
            return final_report
        
        except Exception as e:
            logger.error(f"Erreur critique dans le test: {e}")
            
            # Rapport d'erreur
            error_report = {
                'error': True,
                'error_message': str(e),
                'exchanges_completed': len(self.exchange_results),
                'partial_results': [asdict(ex) for ex in self.exchange_results],
                'timestamp': time.time()
            }
            
            return error_report
    
    async def _execute_complete_exchange(self, ai_last_response: Optional[str]) -> ExchangeResult:
        """Exécute un échange complet utilisateur → IA"""
        
        exchange_start = time.time()
        exchange_number = self.current_exchange + 1
        component_times = {}
        
        logger.info(f"\n--- ÉCHANGE {exchange_number} ---")
        
        try:
            # Étape 1: Générer le message utilisateur
            user_message_data = self.conversation_engine.generate_next_user_message(ai_last_response)
            user_text = user_message_data['text']
            
            logger.info(f"État conversation: {user_message_data['conversation_phase']}")
            logger.info(f"Message utilisateur: {user_text}")
            
            # Étape 2: Synthèse TTS du message utilisateur
            tts_start = time.time()
            try:
                tts_result = await self.tts_service.synthesize_speech(user_text)
                component_times['tts'] = time.time() - tts_start
                audio_data = tts_result['audio_data']
                logger.info(f"TTS synthèse: {len(audio_data)} bytes en {component_times['tts']:.2f}s")
            except Exception as e:
                component_times['tts'] = time.time() - tts_start
                raise RuntimeError(f"Erreur TTS: {e}")
            
            # Étape 3: Transcription VOSK
            vosk_start = time.time()
            try:
                vosk_result = await self.vosk_service.transcribe_audio(
                    audio_data, 
                    {'type': self.config.scenario_type, 'context': user_message_data}
                )
                component_times['vosk'] = time.time() - vosk_start
                transcribed_text = vosk_result['text']
                vosk_confidence = vosk_result['confidence']
                logger.info(f"VOSK transcription: '{transcribed_text}' (conf={vosk_confidence:.2f}) en {component_times['vosk']:.2f}s")
            except Exception as e:
                component_times['vosk'] = time.time() - vosk_start
                raise RuntimeError(f"Erreur VOSK: {e}")
            
            # Étape 4: Génération Mistral
            mistral_start = time.time()
            try:
                mistral_result = await self.mistral_service.generate_response(
                    transcribed_text,
                    self.config.scenario_type,
                    {
                        'conversation_phase': user_message_data['conversation_phase'],
                        'personality': self.conversation_engine.context.personality.value,
                        'exchange_number': exchange_number
                    }
                )
                component_times['mistral'] = time.time() - mistral_start
                ai_response = mistral_result['response']
                logger.info(f"Mistral génération: '{ai_response}' en {component_times['mistral']:.2f}s")
            except Exception as e:
                component_times['mistral'] = time.time() - mistral_start
                raise RuntimeError(f"Erreur Mistral: {e}")
            
            # Étape 5: Collecte des métriques
            total_time = time.time() - exchange_start
            
            # Préparer les données pour le collecteur de métriques
            exchange_data = {
                'user_message': user_text,
                'transcribed_message': transcribed_text,
                'ai_response': ai_response,
                'conversation_state': user_message_data['conversation_phase'],
                'tts_time': component_times['tts'],
                'vosk_time': component_times['vosk'],
                'mistral_time': component_times['mistral'],
                'total_time': total_time,
                'vosk_confidence': vosk_confidence,
                'audio_duration': tts_result.get('audio_duration', 0),
                'audio_quality': tts_result.get('quality_score', 0),
                'tokens_used': mistral_result.get('total_tokens', 0),
                'api_latency': mistral_result.get('processing_time', 0),
                'cost_estimate': mistral_result.get('cost_estimate', 0),
                'expected_keywords': user_message_data.get('keywords_to_expect', []),
                'snr': tts_result.get('signal_to_noise_ratio', 0),
                'vad_score': vosk_result.get('voice_activity_detection', 0),
                'issues_detected': [],
                'repairs_applied': [],
                'error_count': 0,
                'retry_count': 0
            }
            
            # Collecter les métriques
            metrics = self.metrics_collector.collect_exchange_metrics(exchange_data)
            
            # Créer le résultat de l'échange
            exchange_result = ExchangeResult(
                exchange_number=exchange_number,
                user_message=user_text,
                ai_response=ai_response,
                conversation_state=user_message_data['conversation_phase'],
                success=True,
                metrics=asdict(metrics),
                issues_detected=[],
                repairs_applied=[],
                total_time=total_time,
                component_times=component_times
            )
            
            return exchange_result
        
        except Exception as e:
            # Créer un résultat d'échec
            total_time = time.time() - exchange_start
            
            exchange_result = ExchangeResult(
                exchange_number=exchange_number,
                user_message=user_message_data.get('text', '') if 'user_message_data' in locals() else '',
                ai_response='',
                conversation_state=self.conversation_engine.context.current_state.value,
                success=False,
                metrics={},
                issues_detected=[f'exchange_error: {str(e)}'],
                repairs_applied=[],
                total_time=total_time,
                component_times=component_times
            )
            
            return exchange_result
    
    async def _validate_all_services(self):
        """Valide que tous les services sont opérationnels"""
        
        logger.info("Validation des services...")
        
        # Test TTS
        try:
            test_tts = await self.tts_service.synthesize_speech("Test de validation")
            logger.info("Service TTS opérationnel")
        except Exception as e:
            raise RuntimeError(f"Service TTS non opérationnel: {e}")
        
        # Test VOSK (via health check)
        try:
            vosk_healthy = await self.vosk_service._check_health()
            if vosk_healthy:
                logger.info("Service VOSK opérationnel")
            else:
                raise RuntimeError("Service VOSK non sain")
        except Exception as e:
            raise RuntimeError(f"Service VOSK non opérationnel: {e}")
        
        # Test Mistral
        try:
            test_mistral = await self.mistral_service.generate_response(
                "Test de validation", 
                "test", 
                {'conversation_phase': 'validation'}
            )
            logger.info("Service Mistral opérationnel")
        except Exception as e:
            raise RuntimeError(f"Service Mistral non opérationnel: {e}")
        
        logger.info("Tous les services sont opérationnels")
    
    async def _handle_detected_issues(self, exchange_result: ExchangeResult):
        """Gère les problèmes détectés avec auto-réparation"""
        
        for issue in exchange_result.issues_detected:
            logger.warning(f"Problème détecté: {issue}")
            
            repair_result = self.auto_repair.repair_issue(
                issue, 
                exchange_result.conversation_state,
                {
                    'exchange_number': exchange_result.exchange_number,
                    'metrics': exchange_result.metrics
                }
            )
            
            if repair_result['success']:
                exchange_result.repairs_applied.append(repair_result['strategy_used'])
                logger.info(f"Réparation réussie: {repair_result['strategy_used']}")
            else:
                logger.error(f"Échec réparation pour: {issue}")
    
    def _should_continue_conversation(self, exchange_result: ExchangeResult) -> bool:
        """Détermine si la conversation doit continuer"""
        
        # Arrêter si trop de problèmes
        if len(exchange_result.issues_detected) > 3:
            logger.info("Trop de problèmes détectés, arrêt de la conversation")
            return False
        
        # Arrêter si état final atteint
        if exchange_result.conversation_state == 'closing':
            logger.info("État de clôture atteint, fin de conversation")
            return False
        
        # Arrêter si réponse IA indique la fin
        ai_response = exchange_result.ai_response.lower()
        end_indicators = ['au revoir', 'à bientôt', 'merci pour', 'fin de']
        if any(indicator in ai_response for indicator in end_indicators):
            logger.info("IA a indiqué la fin de conversation")
            return False
        
        # Arrêter si satisfaction trop faible
        satisfaction = exchange_result.metrics.get('user_satisfaction_estimate', 1.0)
        if satisfaction < 0.3 and exchange_result.exchange_number >= 3:
            logger.info("Satisfaction utilisateur trop faible, arrêt de conversation")
            return False
        
        return True
    
    async def _generate_final_report(self) -> Dict[str, Any]:
        """Génère le rapport final complet"""
        
        # Rapport de conversation du collecteur de métriques
        conversation_report = self.metrics_collector.generate_conversation_report()
        
        # Statistiques d'auto-réparation
        repair_stats = self.auto_repair.get_repair_statistics()
        
        # Résumé des anomalies
        anomaly_summary = self.anomaly_detector.get_anomaly_summary()
        
        # Statistiques des services
        service_stats = {
            'tts_service': self.tts_service.get_performance_stats(),
            'vosk_service': self.vosk_service.get_performance_stats(),
            'mistral_service': self.mistral_service.get_performance_stats()
        }
        
        # Analyse de la progression conversationnelle
        conversation_progression = self._analyze_conversation_progression()
        
        # Recommendations basées sur les résultats
        recommendations = self._generate_comprehensive_recommendations()
        
        # Compilation du rapport final
        final_report = {
            'test_metadata': {
                'test_start_time': self.global_start_time,
                'test_duration': time.time() - self.global_start_time,
                'total_exchanges': len(self.exchange_results),
                'configuration': asdict(self.config),
                'conversation_personality': self.conversation_engine.context.personality.value,
                'scenario_type': self.config.scenario_type
            },
            'conversation_analysis': conversation_report,
            'exchange_details': [asdict(ex) for ex in self.exchange_results],
            'auto_repair_analysis': repair_stats,
            'anomaly_analysis': anomaly_summary,
            'service_performance': service_stats,
            'conversation_progression': conversation_progression,
            'recommendations': recommendations,
            'test_summary': {
                'overall_success_rate': sum(1 for ex in self.exchange_results if ex.success) / len(self.exchange_results) if self.exchange_results else 0,
                'average_exchange_time': sum(ex.total_time for ex in self.exchange_results) / len(self.exchange_results) if self.exchange_results else 0,
                'conversation_completed': self.conversation_engine.context.current_state == ConversationState.CLOSING,
                'final_conversation_state': self.conversation_engine.context.current_state.value,
                'total_issues_detected': sum(len(ex.issues_detected) for ex in self.exchange_results),
                'total_repairs_applied': sum(len(ex.repairs_applied) for ex in self.exchange_results)
            }
        }
        
        return final_report
    
    def _analyze_conversation_progression(self) -> Dict[str, Any]:
        """Analyse la progression de la conversation"""
        
        if not self.exchange_results:
            return {'no_data': True}
        
        # Évolution des états
        state_progression = [ex.conversation_state for ex in self.exchange_results]
        state_transitions = []
        
        for i in range(1, len(state_progression)):
            if state_progression[i] != state_progression[i-1]:
                state_transitions.append({
                    'from_state': state_progression[i-1],
                    'to_state': state_progression[i],
                    'exchange_number': i + 1
                })
        
        # Évolution de la qualité
        quality_scores = []
        for ex in self.exchange_results:
            if 'user_satisfaction_estimate' in ex.metrics:
                quality_scores.append({
                    'exchange': ex.exchange_number,
                    'satisfaction': ex.metrics['user_satisfaction_estimate'],
                    'relevance': ex.metrics.get('response_relevance', 0),
                    'engagement': ex.metrics.get('response_engagement', 0)
                })
        
        # Tendance générale
        if len(quality_scores) >= 2:
            first_half = quality_scores[:len(quality_scores)//2]
            second_half = quality_scores[len(quality_scores)//2:]
            
            avg_first = sum(q['satisfaction'] for q in first_half) / len(first_half)
            avg_second = sum(q['satisfaction'] for q in second_half) / len(second_half)
            
            trend = 'improving' if avg_second > avg_first else 'declining' if avg_second < avg_first else 'stable'
        else:
            trend = 'insufficient_data'
        
        return {
            'state_progression': state_progression,
            'state_transitions': state_transitions,
            'quality_evolution': quality_scores,
            'conversation_trend': trend,
            'states_reached': len(set(state_progression)),
            'successful_transitions': len(state_transitions)
        }
    
    def _generate_comprehensive_recommendations(self) -> List[str]:
        """Génère des recommandations basées sur l'analyse complète"""
        
        recommendations = []
        
        # Analyse des performances de service
        for service_name, stats in self._get_service_performance_summary().items():
            if stats.get('avg_response_time', 0) > 10:
                recommendations.append(f"Optimiser les performances du service {service_name} (temps de réponse élevé)")
            
            if stats.get('success_rate', 1) < 0.9:
                recommendations.append(f"Améliorer la fiabilité du service {service_name} (taux d'échec élevé)")
        
        # Analyse des métriques conversationnelles
        if self.exchange_results:
            avg_satisfaction = sum(ex.metrics.get('user_satisfaction_estimate', 0.5) for ex in self.exchange_results) / len(self.exchange_results)
            
            if avg_satisfaction < 0.6:
                recommendations.append("Améliorer la qualité des réponses IA pour augmenter la satisfaction utilisateur")
            
            avg_relevance = sum(ex.metrics.get('response_relevance', 0.5) for ex in self.exchange_results) / len(self.exchange_results)
            if avg_relevance < 0.7:
                recommendations.append("Renforcer la pertinence contextuelle des réponses IA")
        
        # Analyse des réparations
        repair_stats = self.auto_repair.get_repair_statistics()
        if repair_stats.get('success_rate', 1) < 0.8:
            recommendations.append("Améliorer les stratégies d'auto-réparation pour une meilleure robustesse")
        
        # Analyse des anomalies
        anomaly_summary = self.anomaly_detector.get_anomaly_summary()
        if not anomaly_summary.get('no_anomalies', False):
            most_frequent_anomalies = sorted(
                anomaly_summary.get('anomaly_breakdown', {}).items(),
                key=lambda x: x[1],
                reverse=True
            )[:3]
            
            for anomaly, count in most_frequent_anomalies:
                recommendations.append(f"Traiter l'anomalie récurrente: {anomaly} ({count} occurrences)")
        
        return recommendations
    
    def _get_service_performance_summary(self) -> Dict[str, Dict[str, Any]]:
        """Résumé des performances des services"""
        
        return {
            'TTS': self.tts_service.get_performance_stats().get('performance_metrics', {}),
            'VOSK': self.vosk_service.get_performance_stats().get('performance_metrics', {}),
            'Mistral': self.mistral_service.get_performance_stats().get('performance_metrics', {})
        }

# Fonction principale pour lancer le test
async def main():
    """Fonction principale pour lancer le test conversationnel"""
    
    print("Test Conversationnel Interactif avec Auto-Réparation")
    print("=" * 60)
    
    # Configuration du test
    config = TestConfiguration(
        max_exchanges=8,
        scenario_type="presentation_client",
        user_personality="commercial_confiant",
        enable_auto_repair=True,
        enable_real_time_metrics=True
    )
    
    # Créer et lancer le testeur
    tester = InteractiveConversationTester(config)
    
    try:
        # Exécuter le test
        report = await tester.run_interactive_conversation_test()
        
        # Sauvegarder le rapport
        timestamp = int(time.time())
        report_filename = f'conversation_test_report_{timestamp}.json'
        
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\nRapport sauvegardé: {report_filename}")
        
        # Afficher le résumé
        summary = report.get('test_summary', {})
        print(f"\nRÉSUMÉ DU TEST:")
        print(f"Échanges réalisés: {summary.get('total_exchanges', 0)}")
        print(f"Taux de succès: {summary.get('overall_success_rate', 0):.1%}")
        print(f"Temps moyen par échange: {summary.get('average_exchange_time', 0):.1f}s")
        print(f"État final: {summary.get('final_conversation_state', 'unknown')}")
        print(f"Conversation terminée: {'Oui' if summary.get('conversation_completed', False) else 'Non'}")
        print(f"Problèmes détectés: {summary.get('total_issues_detected', 0)}")
        print(f"Réparations appliquées: {summary.get('total_repairs_applied', 0)}")
        
        # Recommandations principales
        recommendations = report.get('recommendations', [])
        if recommendations:
            print(f"\nRECOMMANDATIONS PRINCIPALES:")
            for i, rec in enumerate(recommendations[:5], 1):
                print(f"{i}. {rec}")
        
        return True
    
    except Exception as e:
        print(f"ERREUR CRITIQUE: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(main())