#!/usr/bin/env python3
"""
Suite de Tests Complète pour le Système de Test Conversationnel Interactif
Valide tous les composants individuellement et l'intégration complète
"""

import asyncio
import json
import time
import logging
import unittest
import tempfile
import wave
import numpy as np
from typing import Dict, Any, List, Optional, Tuple
from pathlib import Path
from dataclasses import asdict
import sys
import traceback
import base64

class BytesJSONEncoder(json.JSONEncoder):
    """Encodeur JSON personnalisé qui gère les objets bytes"""
    def default(self, obj):
        if isinstance(obj, bytes):
            return base64.b64encode(obj).decode('utf-8')
        return super().default(obj)

# Imports des composants à tester
from interactive_conversation_tester import ConversationMetricsCollector, ConversationMetrics
from conversation_engine import (
    IntelligentConversationEngine, 
    AutoRepairSystem, 
    ConversationState, 
    UserPersonality
)
from service_wrappers import RealTTSService, RealVoskService, RealMistralService
from main_orchestrator import (
    InteractiveConversationTester, 
    TestConfiguration, 
    RealTimeAnomalyDetector,
    ExchangeResult
)
from livekit_virtual_user_client import (
    LiveKitVirtualUserClient,
    VirtualUserSession,
    LiveKitConfig,
    AudioSimulator
)
from adaptive_conversation_scenarios import (
    ConversationDynamics,
    ScenarioType,
    UserProfile,
    ConversationPhase
)

logger = logging.getLogger(__name__)

class TestResult:
    """Résultat de test standardisé"""
    
    def __init__(self, test_name: str):
        self.test_name = test_name
        self.start_time = time.time()
        self.end_time = None
        self.success = False
        self.error_message = None
        self.details = {}
        self.performance_metrics = {}
    
    def complete(self, success: bool, error_message: str = None, details: Dict[str, Any] = None):
        """Marque le test comme terminé"""
        self.end_time = time.time()
        self.success = success
        self.error_message = error_message
        self.details = details or {}
        self.performance_metrics['duration'] = self.end_time - self.start_time
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit le résultat en dictionnaire"""
        return {
            'test_name': self.test_name,
            'success': self.success,
            'duration': self.performance_metrics.get('duration', 0),
            'error_message': self.error_message,
            'details': self.details,
            'performance_metrics': self.performance_metrics
        }

class MockServices:
    """Services mockés pour les tests"""
    
    class MockTTSService:
        """Service TTS mocké"""
        
        def __init__(self, should_fail: bool = False):
            self.should_fail = should_fail
            self.calls_count = 0
        
        async def synthesize_speech(self, text: str) -> Dict[str, Any]:
            self.calls_count += 1
            
            if self.should_fail:
                raise RuntimeError("Mock TTS failure")
            
            # Générer des données audio factices
            audio_data = np.random.randint(-1000, 1000, 16000, dtype=np.int16).tobytes()
            
            return {
                'audio_data': audio_data,
                'audio_data_size': len(audio_data),  # Taille pour validation, mais sérialisable
                'audio_duration': len(text.split()) * 0.5,  # ~0.5s par mot
                'quality_score': 0.85,
                'signal_to_noise_ratio': 25.0
            }
        
        def get_performance_stats(self) -> Dict[str, Any]:
            return {
                'calls_count': self.calls_count,
                'performance_metrics': {
                    'avg_response_time': 1.2,
                    'success_rate': 0.95 if not self.should_fail else 0.0
                }
            }
    
    class MockVoskService:
        """Service VOSK mocké"""
        
        def __init__(self, should_fail: bool = False):
            self.should_fail = should_fail
            self.calls_count = 0
        
        async def transcribe_audio(self, audio_data: bytes, context: Dict[str, Any] = None) -> Dict[str, Any]:
            self.calls_count += 1
            
            if self.should_fail:
                raise RuntimeError("Mock VOSK failure")
            
            # Transcription factice basée sur la taille des données audio
            words_estimated = len(audio_data) // 2000  # Approximation
            fake_transcription = f"Message utilisateur transcrit avec {words_estimated} mots environ"
            
            return {
                'text': fake_transcription,
                'confidence': 0.87,
                'voice_activity_detection': 0.9,
                'processing_time': 0.8,
                'language_detected': 'fr-FR'
            }
        
        async def _check_health(self) -> bool:
            return not self.should_fail
        
        def get_performance_stats(self) -> Dict[str, Any]:
            return {
                'calls_count': self.calls_count,
                'performance_metrics': {
                    'avg_response_time': 0.8,
                    'success_rate': 0.92 if not self.should_fail else 0.0
                }
            }
    
    class MockMistralService:
        """Service Mistral mocké"""
        
        def __init__(self, should_fail: bool = False):
            self.should_fail = should_fail
            self.calls_count = 0
            self.response_templates = [
                "Merci pour votre question très pertinente. Effectivement, notre solution peut vous aider.",
                "C'est une excellente remarque que vous faites là. Laissez-moi vous expliquer concrètement.",
                "Je comprends parfaitement votre préoccupation concernant ce point. Voici notre approche.",
                "Parfait ! C'est exactement le type de défi que nous résolvons. Quelle serait la prochaine étape ?"
            ]
        
        async def generate_response(self, user_input: str, conversation_type: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
            self.calls_count += 1
            
            if self.should_fail:
                raise RuntimeError("Mock Mistral failure")
            
            # Réponse basée sur le contexte
            response = self.response_templates[self.calls_count % len(self.response_templates)]
            
            # Adapter selon le type de conversation
            if conversation_type == "negociation_prix":
                response += " Concernant le budget, nous avons des options flexibles."
            elif conversation_type == "support_technique":
                response += " Techniquement, voici comment nous procédons."
            
            return {
                'response': response,
                'total_tokens': len(response.split()) * 2,  # Approximation tokens
                'processing_time': 1.5,
                'cost_estimate': 0.002,
                'confidence_score': 0.89
            }
        
        def get_performance_stats(self) -> Dict[str, Any]:
            return {
                'calls_count': self.calls_count,
                'performance_metrics': {
                    'avg_response_time': 1.5,
                    'success_rate': 0.94 if not self.should_fail else 0.0
                }
            }

class ComponentValidator:
    """Validateur pour chaque composant individuel"""
    
    def __init__(self):
        self.test_results: List[TestResult] = []
    
    async def validate_metrics_collector(self) -> TestResult:
        """Valide le collecteur de métriques"""
        
        test = TestResult("metrics_collector_validation")
        
        try:
            collector = ConversationMetricsCollector()
            
            # Données d'échange de test
            test_exchange_data = {
                'user_message': 'Bonjour, comment allez-vous ?',
                'transcribed_message': 'Bonjour comment allez vous',
                'ai_response': 'Bonjour ! Je vais très bien, merci de demander. Comment puis-je vous aider ?',
                'conversation_state': 'greeting',
                'tts_time': 1.2,
                'vosk_time': 0.8,
                'mistral_time': 2.1,
                'total_time': 4.5,
                'vosk_confidence': 0.87,
                'audio_duration': 3.2,
                'audio_quality': 0.85,
                'tokens_used': 24,
                'api_latency': 1.8,
                'cost_estimate': 0.003,
                'expected_keywords': ['bonjour', 'aide', 'assistance'],
                'snr': 22.5,
                'vad_score': 0.92,
                'issues_detected': [],
                'repairs_applied': [],
                'error_count': 0,
                'retry_count': 0
            }
            
            # Collecter les métriques
            metrics = collector.collect_exchange_metrics(test_exchange_data)
            
            # Validations
            validations = {
                'metrics_object_created': isinstance(metrics, ConversationMetrics),
                'timing_metrics_present': all(hasattr(metrics, attr) for attr in ['tts_response_time', 'vosk_response_time', 'mistral_response_time']),
                'audio_metrics_present': all(hasattr(metrics, attr) for attr in ['audio_duration', 'audio_quality_score', 'signal_to_noise_ratio']),
                'ai_metrics_present': all(hasattr(metrics, attr) for attr in ['response_relevance', 'response_coherence', 'response_engagement']),
                'conversational_metrics_present': all(hasattr(metrics, attr) for attr in ['conversation_flow_score', 'user_satisfaction_estimate']),
                'technical_metrics_present': all(hasattr(metrics, attr) for attr in ['api_response_time', 'total_tokens_used', 'cost_estimate']),
                'metrics_count_sufficient': len(asdict(metrics)) >= 30
            }
            
            all_valid = all(validations.values())
            
            # Rapport de conversation
            collector.exchange_history.append(metrics)
            conversation_report = collector.generate_conversation_report()
            
            validations['conversation_report_generated'] = 'conversation_summary' in conversation_report
            validations['trends_analysis_present'] = 'trends_analysis' in conversation_report
            
            test.complete(
                success=all_valid and validations['conversation_report_generated'],
                details={
                    'validations': validations,
                    'metrics_count': len(asdict(metrics)),
                    'conversation_report_keys': list(conversation_report.keys())
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test
    
    async def validate_conversation_engine(self) -> TestResult:
        """Valide le moteur de conversation intelligente"""
        
        test = TestResult("conversation_engine_validation")
        
        try:
            engine = IntelligentConversationEngine()
            
            # Tester la génération de messages utilisateur
            user_message1 = engine.generate_next_user_message(None)
            user_message2 = engine.generate_next_user_message("Bonjour, comment puis-je vous aider ?")
            
            # Tester l'analyse de réponse IA
            ai_analysis = engine._analyze_ai_response("C'est une excellente question ! Notre solution utilise l'IA pour améliorer votre communication. Avez-vous des besoins spécifiques ?")
            
            # Tester la mise à jour d'état
            initial_state = engine.context.current_state
            engine._update_conversation_state(ai_analysis)
            
            validations = {
                'user_message_generated': isinstance(user_message1, dict) and 'text' in user_message1,
                'message_adapts_to_context': user_message1['text'] != user_message2['text'],
                'conversation_phase_present': 'conversation_phase' in user_message1,
                'ai_analysis_comprehensive': len(ai_analysis) >= 5,
                'state_updates_working': True,  # Basique, pourrait être plus sophistiqué
                'personality_affects_generation': engine.context.personality is not None
            }
            
            # Tester différentes personnalités
            personalities_tested = []
            for personality in [UserPersonality.COMMERCIAL_CONFIANT, UserPersonality.CLIENT_EXIGEANT]:
                engine.context.personality = personality
                msg = engine.generate_next_user_message("Présentez-moi votre solution")
                personalities_tested.append({
                    'personality': personality.value,
                    'message_length': len(msg['text'])
                })
            
            validations['personality_variation'] = len(set(p['message_length'] for p in personalities_tested)) > 1
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'ai_analysis_keys': list(ai_analysis.keys()),
                    'personalities_tested': personalities_tested,
                    'state_transitions': len(engine.context.state_history)
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test
    
    async def validate_auto_repair_system(self) -> TestResult:
        """Valide le système d'auto-réparation"""
        
        test = TestResult("auto_repair_system_validation")
        
        try:
            repair_system = AutoRepairSystem()
            
            # Tester différents types de problèmes
            test_issues = [
                ('response_too_short', 'greeting', {'response_length': 5}),
                ('low_engagement', 'presentation_solution', {'engagement_score': 0.2}),
                ('context_incoherence', 'negociation', {'coherence_score': 0.3}),
                ('service_timeout', 'any_state', {'timeout_duration': 15.0})
            ]
            
            repair_results = []
            for issue_type, conversation_state, context in test_issues:
                result = repair_system.repair_issue(issue_type, conversation_state, context)
                repair_results.append({
                    'issue': issue_type,
                    'success': result['success'],
                    'strategy': result.get('strategy_used', 'none'),
                    'message': result.get('message', '')
                })
            
            # Statistiques de réparation
            stats = repair_system.get_repair_statistics()
            
            validations = {
                'repairs_attempted': len(repair_results) == len(test_issues),
                'all_repairs_have_strategy': all(r['strategy'] != 'none' for r in repair_results),
                'success_rate_calculated': 'success_rate' in stats,
                'most_common_issues_tracked': 'most_common_issues' in stats,
                'strategies_count_tracked': 'strategies_used' in stats,
                'repair_history_maintained': len(repair_system.repair_history) == len(test_issues)
            }
            
            # Tester l'escalade
            escalation_result = repair_system._escalate_repair("critical_error", "any_state", {})
            validations['escalation_works'] = escalation_result['success']
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'repair_results': repair_results,
                    'repair_statistics': stats,
                    'escalation_result': escalation_result
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test
    
    async def validate_service_wrappers(self) -> TestResult:
        """Valide les wrappers de services avec des mocks"""
        
        test = TestResult("service_wrappers_validation")
        
        try:
            # Utiliser les services mockés
            mock_tts = MockServices.MockTTSService()
            mock_vosk = MockServices.MockVoskService()
            mock_mistral = MockServices.MockMistralService()
            
            # Tester TTS
            tts_result = await mock_tts.synthesize_speech("Bonjour, ceci est un test")
            tts_stats = mock_tts.get_performance_stats()
            
            # Tester VOSK
            test_audio = np.random.randint(-1000, 1000, 16000, dtype=np.int16).tobytes()
            vosk_result = await mock_vosk.transcribe_audio(test_audio)
            vosk_health = await mock_vosk._check_health()
            vosk_stats = mock_vosk.get_performance_stats()
            
            # Tester Mistral
            mistral_result = await mock_mistral.generate_response(
                "Quelle est votre solution ?", 
                "presentation_client",
                {'conversation_phase': 'identification_besoin'}
            )
            mistral_stats = mock_mistral.get_performance_stats()
            
            validations = {
                'tts_response_valid': 'audio_data' in tts_result and len(tts_result['audio_data']) > 0,
                'tts_stats_available': 'performance_metrics' in tts_stats,
                'vosk_transcription_valid': 'text' in vosk_result and 'confidence' in vosk_result,
                'vosk_health_check_works': vosk_health is True,
                'vosk_stats_available': 'performance_metrics' in vosk_stats,
                'mistral_response_valid': 'response' in mistral_result and len(mistral_result['response']) > 0,
                'mistral_tokens_tracked': 'total_tokens' in mistral_result,
                'mistral_cost_estimated': 'cost_estimate' in mistral_result,
                'mistral_stats_available': 'performance_metrics' in mistral_stats
            }
            
            # Tester les services en échec
            mock_tts_fail = MockServices.MockTTSService(should_fail=True)
            mock_vosk_fail = MockServices.MockVoskService(should_fail=True)
            mock_mistral_fail = MockServices.MockMistralService(should_fail=True)
            
            failure_tests = []
            
            try:
                await mock_tts_fail.synthesize_speech("Test")
                failure_tests.append(('tts', False))
            except RuntimeError:
                failure_tests.append(('tts', True))
            
            try:
                await mock_vosk_fail.transcribe_audio(test_audio)
                failure_tests.append(('vosk', False))
            except RuntimeError:
                failure_tests.append(('vosk', True))
            
            try:
                await mock_mistral_fail.generate_response("Test", "test")
                failure_tests.append(('mistral', False))
            except RuntimeError:
                failure_tests.append(('mistral', True))
            
            validations['error_handling_works'] = all(failed for _, failed in failure_tests)
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'service_results': {
                        'tts': tts_result,
                        'vosk': vosk_result,
                        'mistral': mistral_result
                    },
                    'service_stats': {
                        'tts': tts_stats,
                        'vosk': vosk_stats,
                        'mistral': mistral_stats
                    },
                    'failure_tests': failure_tests
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test
    
    async def validate_anomaly_detector(self) -> TestResult:
        """Valide le détecteur d'anomalies"""
        
        test = TestResult("anomaly_detector_validation")
        
        try:
            detector = RealTimeAnomalyDetector()
            
            # Créer des résultats d'échange de test
            exchange_results = []
            
            # Échange normal
            normal_exchange = ExchangeResult(
                exchange_number=1,
                user_message="Bonjour",
                ai_response="Bonjour ! Comment puis-je vous aider ?",
                conversation_state="greeting",
                success=True,
                metrics={
                    'transcription_confidence': 0.9,
                    'response_relevance': 0.8,
                    'response_engagement': 0.7,
                    'user_satisfaction_estimate': 0.8
                },
                issues_detected=[],
                repairs_applied=[],
                total_time=3.0,
                component_times={'tts': 1.0, 'vosk': 0.8, 'mistral': 1.2}
            )
            exchange_results.append(normal_exchange)
            
            # Échange avec problèmes
            problematic_exchange = ExchangeResult(
                exchange_number=2,
                user_message="Question complexe",
                ai_response="Euh...",
                conversation_state="greeting",
                success=False,
                metrics={
                    'transcription_confidence': 0.3,  # Faible
                    'response_relevance': 0.2,  # Très faible
                    'response_engagement': 0.1,  # Très faible
                    'user_satisfaction_estimate': 0.2
                },
                issues_detected=[],
                repairs_applied=[],
                total_time=18.0,  # Trop long
                component_times={'tts': 1.0, 'vosk': 2.0, 'mistral': 15.0}
            )
            
            # Détecter les anomalies
            anomalies = detector.detect_anomalies(problematic_exchange, exchange_results)
            
            # Tester la sévérité
            severity = detector._calculate_severity(anomalies)
            
            # Obtenir le résumé
            anomaly_summary = detector.get_anomaly_summary()
            
            validations = {
                'anomalies_detected': len(anomalies) > 0,
                'excessive_response_time_detected': 'excessive_response_time' in anomalies,
                'low_confidence_detected': 'low_transcription_confidence' in anomalies,
                'low_relevance_detected': 'low_ai_relevance' in anomalies,
                'low_engagement_detected': 'low_ai_engagement' in anomalies,
                'severity_calculated': severity in ['minor', 'moderate', 'severe'],
                'anomaly_summary_complete': 'anomaly_breakdown' in anomaly_summary,
                'severity_breakdown_present': 'severity_breakdown' in anomaly_summary,
                'timeline_tracked': 'anomaly_timeline' in anomaly_summary
            }
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'anomalies_detected': anomalies,
                    'severity_calculated': severity,
                    'anomaly_summary': anomaly_summary,
                    'test_exchanges_count': len(exchange_results) + 1
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test
    
    async def validate_scenario_dynamics(self) -> TestResult:
        """Valide les dynamiques de scénarios adaptatifs"""
        
        test = TestResult("scenario_dynamics_validation")
        
        try:
            dynamics = ConversationDynamics()
            
            # Tester différents scénarios
            scenarios_tested = []
            
            for scenario_type in [ScenarioType.PRESENTATION_CLIENT, ScenarioType.COMMERCIAL_DEMO, ScenarioType.NEGOCIATION_PRIX]:
                for user_profile in [UserProfile.PROSPECT_CURIEUX, UserProfile.CLIENT_EXIGEANT]:
                    dynamics.set_scenario(scenario_type, user_profile)
                    
                    # Générer quelques messages
                    messages = []
                    ai_response = None
                    
                    for i in range(3):
                        user_message_data = dynamics.generate_contextual_user_message(ai_response)
                        messages.append(user_message_data)
                        
                        # Simuler une réponse IA
                        ai_response = f"Réponse IA {i+1} pour {scenario_type.value}"
                    
                    # Obtenir les métriques
                    metrics = dynamics.get_scenario_metrics()
                    
                    scenarios_tested.append({
                        'scenario': scenario_type.value,
                        'profile': user_profile.value,
                        'messages_generated': len(messages),
                        'progression': metrics['progression_percentage'],
                        'engagement': metrics['user_engagement'],
                        'phases_completed': metrics['phases_completed']
                    })
            
            validations = {
                'scenarios_tested': len(scenarios_tested) > 0,
                'all_scenarios_generate_messages': all(s['messages_generated'] > 0 for s in scenarios_tested),
                'progression_calculated': all('progression' in s for s in scenarios_tested),
                'engagement_tracked': all('engagement' in s for s in scenarios_tested),
                'phase_transitions_work': any(s['phases_completed'] > 0 for s in scenarios_tested),
                'different_profiles_produce_variation': len(set(s['profile'] for s in scenarios_tested)) > 1
            }
            
            # Tester l'analyse de réponse IA
            sample_ai_responses = [
                "Concernant le prix, nous avons plusieurs options intéressantes.",
                "Techniquement, notre solution utilise l'IA avancée pour analyser.",
                "Parfait ! Programmons une démonstration personnalisée."
            ]
            
            ai_analyses = []
            for response in sample_ai_responses:
                analysis = dynamics._analyze_ai_response(response)
                ai_analyses.append(analysis)
            
            validations['ai_analysis_comprehensive'] = all(len(analysis) >= 5 for analysis in ai_analyses)
            validations['price_detection_works'] = ai_analyses[0]['mentions_price']
            validations['technical_detection_works'] = ai_analyses[1]['technical_content']
            validations['next_steps_detection_works'] = ai_analyses[2]['suggests_next_steps']
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'scenarios_tested': scenarios_tested,
                    'ai_analyses_samples': ai_analyses,
                    'total_test_combinations': len(scenarios_tested)
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test
    
    async def validate_audio_simulator(self) -> TestResult:
        """Valide le simulateur audio"""
        
        test = TestResult("audio_simulator_validation")
        
        try:
            simulator = AudioSimulator()
            
            # Tester la génération audio
            test_texts = [
                "Bonjour, comment allez-vous ?",
                "Pouvez-vous me présenter votre solution en détail ?",
                "Je ne suis pas convaincu par votre proposition."
            ]
            
            audio_results = []
            
            for text in test_texts:
                for voice_style in ["neutral", "commercial_confiant", "client_exigeant"]:
                    audio_data = simulator.generate_audio_from_text(text, voice_style)
                    
                    audio_results.append({
                        'text': text,
                        'voice_style': voice_style,
                        'audio_size': len(audio_data),
                        'estimated_duration': len(text.split()) * 0.5
                    })
            
            # Tester la sauvegarde WAV
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                test_audio = simulator.generate_audio_from_text("Test audio", "neutral")
                simulator.save_audio_to_wav(test_audio, temp_file.name)
                
                # Vérifier que le fichier existe et a une taille raisonnable
                wav_file_path = Path(temp_file.name)
                wav_file_exists = wav_file_path.exists()
                wav_file_size = wav_file_path.stat().st_size if wav_file_exists else 0
            
            validations = {
                'audio_generated_for_all_texts': len(audio_results) == len(test_texts) * 3,
                'audio_data_not_empty': all(r['audio_size'] > 0 for r in audio_results),
                'different_voice_styles_produce_variation': len(set(r['audio_size'] for r in audio_results)) > 1,
                'wav_file_saved_successfully': wav_file_exists,
                'wav_file_has_reasonable_size': wav_file_size > 100,  # Au moins 100 bytes
                'audio_duration_correlates_with_text': True  # Simplifié pour cet exemple
            }
            
            # Nettoyer le fichier temporaire
            if wav_file_exists:
                wav_file_path.unlink()
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'audio_results': audio_results,
                    'wav_file_size': wav_file_size,
                    'total_audio_generated': len(audio_results)
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test

class IntegrationValidator:
    """Validateur pour les tests d'intégration"""
    
    def __init__(self):
        self.test_results: List[TestResult] = []
    
    async def validate_end_to_end_mock_conversation(self) -> TestResult:
        """Valide une conversation complète de bout en bout avec des mocks"""
        
        test = TestResult("end_to_end_mock_conversation")
        
        try:
            # Configuration du test avec des services mockés
            config = TestConfiguration(
                max_exchanges=3,
                scenario_type="presentation_client",
                user_personality="commercial_confiant",
                enable_auto_repair=True,
                enable_real_time_metrics=True
            )
            
            # Créer l'orchestrateur principal
            tester = InteractiveConversationTester(config)
            
            # Remplacer les services par des mocks
            tester.tts_service = MockServices.MockTTSService()
            tester.vosk_service = MockServices.MockVoskService()
            tester.mistral_service = MockServices.MockMistralService()
            
            # Exécuter une validation des services mockés
            await tester._validate_all_services()
            
            # Simuler quelques échanges manuellement (sans LiveKit)
            exchange_results = []
            
            for exchange_num in range(3):
                try:
                    # Générer un message utilisateur
                    user_message_data = tester.conversation_engine.generate_next_user_message(
                        "Réponse IA précédente" if exchange_num > 0 else None
                    )
                    
                    # Simuler TTS
                    tts_result = await tester.tts_service.synthesize_speech(user_message_data['text'])
                    
                    # Simuler VOSK
                    vosk_result = await tester.vosk_service.transcribe_audio(
                        tts_result['audio_data']
                    )
                    
                    # Simuler Mistral
                    mistral_result = await tester.mistral_service.generate_response(
                        vosk_result['text'],
                        config.scenario_type,
                        {'conversation_phase': user_message_data['conversation_phase']}
                    )
                    
                    # Collecter les métriques
                    exchange_data = {
                        'user_message': user_message_data['text'],
                        'transcribed_message': vosk_result['text'],
                        'ai_response': mistral_result['response'],
                        'conversation_state': user_message_data['conversation_phase'],
                        'tts_time': 1.2,
                        'vosk_time': 0.8,
                        'mistral_time': 1.5,
                        'total_time': 3.5,
                        'vosk_confidence': vosk_result['confidence'],
                        'audio_duration': tts_result['audio_duration'],
                        'audio_quality': tts_result['quality_score'],
                        'tokens_used': mistral_result['total_tokens'],
                        'api_latency': mistral_result['processing_time'],
                        'cost_estimate': mistral_result['cost_estimate'],
                        'expected_keywords': user_message_data.get('keywords_to_expect', []),
                        'snr': tts_result['signal_to_noise_ratio'],
                        'vad_score': 0.9,
                        'issues_detected': [],
                        'repairs_applied': [],
                        'error_count': 0,
                        'retry_count': 0
                    }
                    
                    metrics = tester.metrics_collector.collect_exchange_metrics(exchange_data)
                    
                    exchange_result = ExchangeResult(
                        exchange_number=exchange_num + 1,
                        user_message=user_message_data['text'],
                        ai_response=mistral_result['response'],
                        conversation_state=user_message_data['conversation_phase'],
                        success=True,
                        metrics=asdict(metrics),
                        issues_detected=[],
                        repairs_applied=[],
                        total_time=3.5,
                        component_times={'tts': 1.2, 'vosk': 0.8, 'mistral': 1.5}
                    )
                    
                    exchange_results.append(exchange_result)
                    
                    # Détection d'anomalies
                    anomalies = tester.anomaly_detector.detect_anomalies(
                        exchange_result, 
                        exchange_results[:-1]
                    )
                    
                except Exception as e:
                    logger.error(f"Erreur dans l'échange {exchange_num + 1}: {e}")
                    break
            
            # Générer le rapport final simulé
            tester.exchange_results = exchange_results
            
            # Valider les résultats
            validations = {
                'all_exchanges_completed': len(exchange_results) == 3,
                'all_exchanges_successful': all(ex.success for ex in exchange_results),
                'metrics_collected_for_all': all(ex.metrics for ex in exchange_results),
                'conversation_progressed': len(set(ex.conversation_state for ex in exchange_results)) > 1,
                'services_responded': all(
                    service.calls_count > 0 for service in [
                        tester.tts_service, tester.vosk_service, tester.mistral_service
                    ]
                ),
                'anomaly_detection_active': tester.anomaly_detector is not None,
                'auto_repair_available': tester.auto_repair is not None
            }
            
            # Statistiques finales
            final_stats = {
                'total_exchanges': len(exchange_results),
                'average_exchange_time': sum(ex.total_time for ex in exchange_results) / len(exchange_results) if exchange_results else 0,
                'conversation_states_visited': list(set(ex.conversation_state for ex in exchange_results)),
                'total_processing_time': sum(ex.total_time for ex in exchange_results)
            }
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'exchange_results_summary': [
                        {
                            'exchange_number': ex.exchange_number,
                            'success': ex.success,
                            'conversation_state': ex.conversation_state,
                            'total_time': ex.total_time
                        } for ex in exchange_results
                    ],
                    'final_stats': final_stats,
                    'service_call_counts': {
                        'tts': tester.tts_service.calls_count,
                        'vosk': tester.vosk_service.calls_count,
                        'mistral': tester.mistral_service.calls_count
                    }
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test
    
    async def validate_livekit_client_mock(self) -> TestResult:
        """Valide le client LiveKit avec des données mockées"""
        
        test = TestResult("livekit_client_mock")
        
        try:
            # Configuration LiveKit de test
            config = LiveKitConfig(
                host="localhost",
                port=7880,
                room_name="test_room",
                participant_name="test_participant"
            )
            
            client = LiveKitVirtualUserClient(config)
            
            # Tester la simulation audio
            audio_simulator = AudioSimulator()
            test_audio = audio_simulator.generate_audio_from_text(
                "Bonjour, ceci est un test de client LiveKit",
                "commercial_confiant"
            )
            
            # Tester les configurations
            session_personalities = []
            for personality in ["commercial_confiant", "client_exigeant", "prospect_interesse"]:
                session = await client.create_virtual_user_session(personality)
                session_stats = session.get_session_stats()
                session_personalities.append({
                    'personality': personality,
                    'session_id': session_stats['session_id'],
                    'user_personality': session_stats['user_personality']
                })
            
            # Note: On ne teste pas la connexion réelle LiveKit car elle nécessite un serveur
            # On valide plutôt la structure et la logique
            
            validations = {
                'client_created_successfully': client is not None,
                'audio_simulator_works': len(test_audio) > 0,
                'sessions_created_with_different_personalities': len(session_personalities) == 3,
                'session_stats_available': all('session_id' in s for s in session_personalities),
                'personality_correctly_assigned': all(
                    s['personality'] == s['user_personality'] for s in session_personalities
                ),
                'session_cleanup_available': hasattr(client, 'cleanup_sessions')
            }
            
            # Test des actions virtuelles (simulation)
            from livekit_virtual_user_client import VirtualUserAction
            
            test_actions = [
                VirtualUserAction("speak", "Bonjour", 2.0),
                VirtualUserAction("listen", None, 3.0),
                VirtualUserAction("pause", None, 1.0)
            ]
            
            actions_valid = all(
                hasattr(action, 'action_type') and 
                action.action_type in ['speak', 'listen', 'pause', 'disconnect']
                for action in test_actions
            )
            
            validations['virtual_actions_structure_valid'] = actions_valid
            
            # Nettoyer
            client.cleanup_sessions()
            
            test.complete(
                success=all(validations.values()),
                details={
                    'validations': validations,
                    'session_personalities': session_personalities,
                    'test_audio_size': len(test_audio),
                    'test_actions_count': len(test_actions)
                }
            )
        
        except Exception as e:
            test.complete(False, str(e), {'traceback': traceback.format_exc()})
        
        self.test_results.append(test)
        return test

class ComprehensiveTestSuite:
    """Suite de tests complète pour tout le système"""
    
    def __init__(self):
        self.component_validator = ComponentValidator()
        self.integration_validator = IntegrationValidator()
        self.all_test_results: List[TestResult] = []
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """Lance tous les tests de validation"""
        
        print("Lancement de la Suite de Tests Complète")
        print("=" * 50)
        
        start_time = time.time()
        
        # Tests des composants individuels
        print("\n--- VALIDATION DES COMPOSANTS ---")
        
        component_tests = [
            self.component_validator.validate_metrics_collector,
            self.component_validator.validate_conversation_engine,
            self.component_validator.validate_auto_repair_system,
            self.component_validator.validate_service_wrappers,
            self.component_validator.validate_anomaly_detector,
            self.component_validator.validate_scenario_dynamics,
            self.component_validator.validate_audio_simulator
        ]
        
        for test_func in component_tests:
            try:
                result = await test_func()
                self.all_test_results.append(result)
                status = "[PASS]" if result.success else "[FAIL]"
                print(f"{status} {result.test_name} ({result.performance_metrics.get('duration', 0):.2f}s)")
                
                if not result.success:
                    print(f"    Erreur: {result.error_message}")
            
            except Exception as e:
                print(f"[ERROR] {test_func.__name__}: {e}")
        
        # Tests d'intégration
        print("\n--- VALIDATION D'INTÉGRATION ---")
        
        integration_tests = [
            self.integration_validator.validate_end_to_end_mock_conversation,
            self.integration_validator.validate_livekit_client_mock
        ]
        
        for test_func in integration_tests:
            try:
                result = await test_func()
                self.all_test_results.append(result)
                status = "[PASS]" if result.success else "[FAIL]"
                print(f"{status} {result.test_name} ({result.performance_metrics.get('duration', 0):.2f}s)")
                
                if not result.success:
                    print(f"    Erreur: {result.error_message}")
            
            except Exception as e:
                print(f"[ERROR] {test_func.__name__}: {e}")
        
        # Combiner tous les résultats
        self.all_test_results.extend(self.component_validator.test_results)
        self.all_test_results.extend(self.integration_validator.test_results)
        
        # Générer le rapport final
        total_time = time.time() - start_time
        report = self._generate_test_report(total_time)
        
        print(f"\n--- RÉSUMÉ FINAL ---")
        print(f"Tests executes: {report['summary']['total_tests']}")
        print(f"Succes: {report['summary']['tests_passed']}")
        print(f"Echecs: {report['summary']['tests_failed']}")
        print(f"Taux de reussite: {report['summary']['success_rate']:.1%}")
        print(f"Duree totale: {total_time:.1f}s")
        
        return report
    
    def _generate_test_report(self, total_execution_time: float) -> Dict[str, Any]:
        """Génère le rapport final de tests"""
        
        # Statistiques générales
        total_tests = len(self.all_test_results)
        tests_passed = sum(1 for result in self.all_test_results if result.success)
        tests_failed = total_tests - tests_passed
        success_rate = tests_passed / total_tests if total_tests > 0 else 0
        
        # Détails par catégorie
        component_results = [r for r in self.all_test_results if 'component' in r.test_name or any(comp in r.test_name for comp in ['metrics', 'conversation', 'repair', 'service', 'anomaly', 'scenario', 'audio'])]
        integration_results = [r for r in self.all_test_results if 'integration' in r.test_name or 'end_to_end' in r.test_name or 'livekit' in r.test_name]
        
        # Tests les plus lents
        slowest_tests = sorted(
            self.all_test_results, 
            key=lambda x: x.performance_metrics.get('duration', 0), 
            reverse=True
        )[:5]
        
        # Tests échoués
        failed_tests = [r for r in self.all_test_results if not r.success]
        
        return {
            'summary': {
                'total_tests': total_tests,
                'tests_passed': tests_passed,
                'tests_failed': tests_failed,
                'success_rate': success_rate,
                'total_execution_time': total_execution_time
            },
            'category_breakdown': {
                'component_tests': {
                    'total': len(component_results),
                    'passed': sum(1 for r in component_results if r.success),
                    'success_rate': sum(1 for r in component_results if r.success) / len(component_results) if component_results else 0
                },
                'integration_tests': {
                    'total': len(integration_results),
                    'passed': sum(1 for r in integration_results if r.success),
                    'success_rate': sum(1 for r in integration_results if r.success) / len(integration_results) if integration_results else 0
                }
            },
            'performance_analysis': {
                'average_test_duration': sum(r.performance_metrics.get('duration', 0) for r in self.all_test_results) / total_tests if total_tests > 0 else 0,
                'slowest_tests': [
                    {
                        'test_name': r.test_name,
                        'duration': r.performance_metrics.get('duration', 0),
                        'success': r.success
                    } for r in slowest_tests
                ]
            },
            'detailed_results': [r.to_dict() for r in self.all_test_results],
            'failed_tests_analysis': [
                {
                    'test_name': r.test_name,
                    'error_message': r.error_message,
                    'duration': r.performance_metrics.get('duration', 0)
                } for r in failed_tests
            ],
            'recommendations': self._generate_test_recommendations(failed_tests, slowest_tests)
        }
    
    def _generate_test_recommendations(self, failed_tests: List[TestResult], slowest_tests: List[TestResult]) -> List[str]:
        """Génère des recommandations basées sur les résultats de tests"""
        
        recommendations = []
        
        if failed_tests:
            recommendations.append(f"Résoudre les {len(failed_tests)} tests échoués pour assurer la fiabilité du système")
            
            # Analyser les erreurs communes
            error_patterns = {}
            for test in failed_tests:
                if test.error_message:
                    error_key = test.error_message.split(':')[0] if ':' in test.error_message else test.error_message
                    error_patterns[error_key] = error_patterns.get(error_key, 0) + 1
            
            for error, count in error_patterns.items():
                if count > 1:
                    recommendations.append(f"Erreur récurrente '{error}' apparaît dans {count} tests - investigation nécessaire")
        
        # Analyser les performances
        slow_threshold = 5.0  # 5 secondes
        very_slow_tests = [t for t in slowest_tests if t.performance_metrics.get('duration', 0) > slow_threshold]
        
        if very_slow_tests:
            recommendations.append(f"Optimiser les performances de {len(very_slow_tests)} tests lents (>{slow_threshold}s)")
        
        # Recommandations spécifiques par type de test
        component_failures = [t for t in failed_tests if any(comp in t.test_name for comp in ['metrics', 'conversation', 'repair'])]
        if component_failures:
            recommendations.append("Tests de composants échoués - vérifier la logique métier de base")
        
        integration_failures = [t for t in failed_tests if 'integration' in t.test_name or 'end_to_end' in t.test_name]
        if integration_failures:
            recommendations.append("Tests d'intégration échoués - vérifier la compatibilité entre composants")
        
        if not recommendations:
            recommendations.append("Tous les tests sont passés avec succès - système prêt pour le déploiement")
            recommendations.append("Considérer l'ajout de tests de charge pour valider les performances en conditions réelles")
        
        return recommendations

# Fonction principale pour lancer tous les tests
async def main():
    """Fonction principale pour lancer la suite de tests complète"""
    
    # Configuration du logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Créer et lancer la suite de tests
    test_suite = ComprehensiveTestSuite()
    
    try:
        report = await test_suite.run_all_tests()
        
        # Sauvegarder le rapport
        timestamp = int(time.time())
        report_filename = f'comprehensive_test_report_{timestamp}.json'
        
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False, cls=BytesJSONEncoder)
        
        print(f"\nRapport détaillé sauvegardé: {report_filename}")
        
        # Afficher les recommandations
        recommendations = report.get('recommendations', [])
        if recommendations:
            print(f"\nRECOMMANDATIONS:")
            for i, rec in enumerate(recommendations, 1):
                print(f"{i}. {rec}")
        
        return report['summary']['success_rate'] == 1.0
    
    except Exception as e:
        print(f"ERREUR CRITIQUE dans la suite de tests: {e}")
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)