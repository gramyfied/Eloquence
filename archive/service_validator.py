#!/usr/bin/env python3
"""
Service Validator - Validation Complète des Services pour Conversation Réelle
Vérifie que tous les services requis sont opérationnels avant le lancement
"""

import asyncio
import time
import json
import logging
import os
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, asdict
from pathlib import Path

# Chargement des variables d'environnement
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # Si python-dotenv n'est pas installé, continuer sans
    pass

# Imports pour validation directe
import aiohttp
from marie_ai_character import MarieAICharacter, marie_character

logger = logging.getLogger(__name__)

@dataclass
class ServiceValidationResult:
    """Résultat de validation d'un service"""
    service_name: str
    is_available: bool
    response_time: float
    validation_details: Dict[str, Any]
    issues_detected: List[str]
    recommendations: List[str]
    health_score: float  # 0.0 à 1.0

@dataclass
class EnvironmentCheck:
    """Vérification de l'environnement"""
    check_name: str
    is_valid: bool
    expected_value: Optional[str]
    actual_value: Optional[str]
    severity: str  # "critical", "warning", "info"
    recommendation: str

class ServiceValidator:
    """Validateur complet de tous les services requis"""
    
    def __init__(self):
        self.validation_results: Dict[str, ServiceValidationResult] = {}
        self.environment_checks: List[EnvironmentCheck] = []
        self.overall_validation_start = None
        self.validation_summary = {}
        
        # Seuils de performance acceptables
        self.performance_thresholds = {
            'tts_max_response_time': 10.0,  # secondes
            'vosk_max_response_time': 15.0,  # secondes  
            'mistral_max_response_time': 20.0,  # secondes
            'min_health_score': 0.7,  # Score minimum acceptable
            'min_overall_score': 0.8  # Score global minimum
        }
    
    async def validate_all_services(self) -> Dict[str, Any]:
        """Lance la validation complète de tous les services"""
        
        logger.info("=== DÉBUT VALIDATION COMPLÈTE DES SERVICES ===")
        self.overall_validation_start = time.time()
        
        try:
            # 1. Vérifications d'environnement
            logger.info("Vérification de l'environnement...")
            await self._validate_environment()
            
            # 2. Validation des services individuels
            logger.info("Validation des services individuels...")
            await self._validate_individual_services()
            
            # 3. Tests d'intégration
            logger.info("Tests d'intégration des services...")
            await self._validate_service_integration()
            
            # 4. Validation Marie AI Character
            logger.info("Validation de Marie AI Character...")
            await self._validate_marie_character()
            
            # 5. Génération du rapport final
            validation_report = await self._generate_validation_report()
            
            total_time = time.time() - self.overall_validation_start
            logger.info(f"=== VALIDATION TERMINÉE en {total_time:.1f}s ===")
            
            return validation_report
        
        except Exception as e:
            logger.error(f"Erreur critique pendant la validation: {e}")
            return await self._generate_error_report(str(e))
    
    async def _validate_environment(self):
        """Valide l'environnement et les variables nécessaires"""
        
        # Vérification clé API Mistral
        mistral_key = os.getenv("MISTRAL_API_KEY")
        self.environment_checks.append(EnvironmentCheck(
            check_name="MISTRAL_API_KEY",
            is_valid=mistral_key is not None and len(mistral_key) > 20,
            expected_value="clé API valide",
            actual_value="configurée" if mistral_key else "manquante",
            severity="critical" if not mistral_key else "info",
            recommendation="Configurer MISTRAL_API_KEY dans les variables d'environnement" if not mistral_key else "OK"
        ))
        
        # Vérification clé API Scaleway (alternative)
        scaleway_key = os.getenv("SCALEWAY_API_KEY")
        self.environment_checks.append(EnvironmentCheck(
            check_name="SCALEWAY_API_KEY",
            is_valid=scaleway_key is not None and len(scaleway_key) > 20,
            expected_value="clé API Scaleway valide",
            actual_value="configurée" if scaleway_key else "manquante",
            severity="warning" if not scaleway_key else "info",
            recommendation="Configurer SCALEWAY_API_KEY si utilisation Mistral via Scaleway" if not scaleway_key else "OK"
        ))
        
        # Vérification clé OpenAI (pour TTS)
        openai_key = os.getenv("OPENAI_API_KEY")
        self.environment_checks.append(EnvironmentCheck(
            check_name="OPENAI_API_KEY",
            is_valid=openai_key is not None and len(openai_key) > 20,
            expected_value="clé API OpenAI valide",
            actual_value="configurée" if openai_key else "manquante",
            severity="critical" if not openai_key else "info",
            recommendation="Configurer OPENAI_API_KEY pour le service TTS" if not openai_key else "OK"
        ))
        
        # Vérification structure de fichiers requis
        required_files = [
            "marie_ai_character.py",
            "service_wrappers.py", 
            "conversation_engine.py",
            "interactive_conversation_tester.py"
        ]
        
        for file_name in required_files:
            file_exists = Path(file_name).exists()
            self.environment_checks.append(EnvironmentCheck(
                check_name=f"file_{file_name}",
                is_valid=file_exists,
                expected_value="fichier présent",
                actual_value="présent" if file_exists else "manquant",
                severity="critical" if not file_exists else "info",
                recommendation=f"Le fichier {file_name} est requis pour le fonctionnement" if not file_exists else "OK"
            ))
        
        # Vérification permissions d'écriture
        try:
            test_file = Path("test_write_permissions.tmp")
            test_file.write_text("test")
            test_file.unlink()
            write_permissions = True
        except:
            write_permissions = False
        
        self.environment_checks.append(EnvironmentCheck(
            check_name="write_permissions",
            is_valid=write_permissions,
            expected_value="permissions écriture",
            actual_value="accordées" if write_permissions else "refusées",
            severity="warning" if not write_permissions else "info",
            recommendation="Vérifier les permissions d'écriture dans le répertoire" if not write_permissions else "OK"
        ))
    
    async def _validate_individual_services(self):
        """Valide chaque service individuellement"""
        
        # Validation TTS Service
        await self._validate_tts_service()
        
        # Validation VOSK Service  
        await self._validate_vosk_service()
        
        # Validation Mistral Service
        await self._validate_mistral_service()
    
    async def _validate_tts_service(self):
        """Valide le service TTS directement via Docker endpoint"""
        
        service_name = "TTS_Service"
        start_time = time.time()
        issues = []
        recommendations = []
        validation_details = {}
        
        try:
            # Test direct du service Docker TTS
            test_text = "Test de validation du service TTS"
            
            payload = {
                "model": "tts-1",
                "input": test_text,
                "voice": "alloy",
                "response_format": "wav"
            }
            
            headers = {
                "Authorization": "Bearer fake-key-for-local-service",
                "Content-Type": "application/json"
            }
            
            timeout = aiohttp.ClientTimeout(total=self.performance_thresholds['tts_max_response_time'])
            
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get("http://localhost:5002/health") as response:
                    
                    response_time = time.time() - start_time
                    
                    if response.status == 200:
                        health_data = await response.json()
                        
                        # Vérification de la santé du service TTS
                        tts_available = health_data.get("status") == "ok" and health_data.get("openai_available", False)
                        voices_count = health_data.get("voices_available", 0)
                        
                        validation_details = {
                            'response_time': response_time,
                            'tts_available': tts_available,
                            'engine': health_data.get("engine", "unknown"),
                            'voices_available': voices_count,
                            'language': health_data.get("language", "unknown"),
                            'quality': health_data.get("quality", "unknown"),
                            'endpoint_accessible': True,
                            'status_code': response.status
                        }
                        
                        # Vérifications de qualité
                        if response_time > self.performance_thresholds['tts_max_response_time']:
                            issues.append(f"Temps de réponse élevé: {response_time:.1f}s")
                            recommendations.append("Optimiser les performances du service TTS")
                        
                        if not tts_available:
                            issues.append("Service TTS non disponible ou moteur OpenAI inaccessible")
                            recommendations.append("Vérifier la configuration TTS et la connectivité OpenAI")
                        
                        if voices_count == 0:
                            issues.append("Aucune voix TTS disponible")
                            recommendations.append("Vérifier la configuration des voix TTS")
                        
                        # Score de santé basé sur la disponibilité et performance
                        health_score = 1.0
                        if not tts_available:
                            health_score -= 0.5
                        if response_time > self.performance_thresholds['tts_max_response_time']:
                            health_score -= 0.3
                        if voices_count == 0:
                            health_score -= 0.2
                        health_score = max(0.0, health_score)
                        
                        self.validation_results[service_name] = ServiceValidationResult(
                            service_name=service_name,
                            is_available=tts_available,
                            response_time=response_time,
                            validation_details=validation_details,
                            issues_detected=issues,
                            recommendations=recommendations,
                            health_score=health_score
                        )
                        
                        logger.info(f"TTS Service validé: score={health_score:.2f}, disponible={tts_available}, {voices_count} voix")
                    
                    else:
                        error_text = await response.text()
                        issues.append(f"Erreur HTTP {response.status}: {error_text}")
                        recommendations.append("Vérifier la configuration du service TTS Docker")
                        
                        self.validation_results[service_name] = ServiceValidationResult(
                            service_name=service_name,
                            is_available=False,
                            response_time=response_time,
                            validation_details={'error': error_text, 'status_code': response.status},
                            issues_detected=issues,
                            recommendations=recommendations,
                            health_score=0.0
                        )
        
        except Exception as e:
            response_time = time.time() - start_time
            issues.append(f"Erreur de connexion TTS: {str(e)}")
            recommendations.append("Vérifier que le service TTS Docker est démarré sur localhost:5002")
            
            self.validation_results[service_name] = ServiceValidationResult(
                service_name=service_name,
                is_available=False,
                response_time=response_time,
                validation_details={'error': str(e)},
                issues_detected=issues,
                recommendations=recommendations,
                health_score=0.0
            )
            
            logger.error(f"TTS Service indisponible: {e}")
    
    async def _validate_vosk_service(self):
        """Valide le service VOSK directement via Docker endpoint"""
        
        service_name = "VOSK_Service"
        start_time = time.time()
        issues = []
        recommendations = []
        validation_details = {}
        
        try:
            # Test de santé direct du service Docker VOSK
            timeout = aiohttp.ClientTimeout(total=5.0)
            
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get("http://localhost:2700/health") as response:
                    health_check_time = time.time() - start_time
                    
                    if response.status == 200:
                        health_data = await response.json()
                        is_healthy = health_data.get('status') == 'healthy' and health_data.get('model_loaded', False)
                        
                        validation_details = {
                            'health_check_time': health_check_time,
                            'is_healthy': is_healthy,
                            'status': health_data.get('status'),
                            'model_loaded': health_data.get('model_loaded', False),
                            'model_path': health_data.get('model_path', ''),
                            'endpoint_accessible': True,
                            'status_code': response.status
                        }
                        
                        if not is_healthy:
                            issues.append("VOSK service non sain ou modèle non chargé")
                            recommendations.append("Vérifier le chargement du modèle VOSK")
                        
                        if health_check_time > 5.0:
                            issues.append(f"Temps de réponse VOSK santé élevé: {health_check_time:.1f}s")
                            recommendations.append("Optimiser les performances du service VOSK")
                        
                        # Score de santé basé sur la disponibilité
                        health_score = 1.0 if is_healthy else 0.3
                        if health_check_time > 3.0:
                            health_score -= 0.2
                        health_score = max(0.0, health_score)
                        
                        self.validation_results[service_name] = ServiceValidationResult(
                            service_name=service_name,
                            is_available=is_healthy,
                            response_time=health_check_time,
                            validation_details=validation_details,
                            issues_detected=issues,
                            recommendations=recommendations,
                            health_score=health_score
                        )
                        
                        logger.info(f"VOSK Service validé: score={health_score:.2f}, sain={is_healthy}, modèle chargé={validation_details['model_loaded']}")
                    
                    else:
                        issues.append(f"Erreur HTTP VOSK {response.status}")
                        recommendations.append("Vérifier la configuration du service VOSK Docker")
                        
                        self.validation_results[service_name] = ServiceValidationResult(
                            service_name=service_name,
                            is_available=False,
                            response_time=health_check_time,
                            validation_details={'error': f'HTTP {response.status}', 'status_code': response.status},
                            issues_detected=issues,
                            recommendations=recommendations,
                            health_score=0.0
                        )
        
        except Exception as e:
            response_time = time.time() - start_time
            issues.append(f"Erreur de connexion VOSK: {str(e)}")
            recommendations.append("Vérifier que le service VOSK Docker est démarré sur localhost:2700")
            
            self.validation_results[service_name] = ServiceValidationResult(
                service_name=service_name,
                is_available=False,
                response_time=response_time,
                validation_details={'error': str(e)},
                issues_detected=issues,
                recommendations=recommendations,
                health_score=0.0
            )
            
            logger.error(f"VOSK Service indisponible: {e}")
    
    async def _validate_mistral_service(self):
        """Valide le service Mistral directement via API"""
        
        service_name = "Mistral_Service"
        start_time = time.time()
        issues = []
        recommendations = []
        validation_details = {}
        
        try:
            import os
            api_key = os.getenv("MISTRAL_API_KEY")
            
            if not api_key:
                issues.append("Clé API Mistral manquante")
                recommendations.append("Configurer MISTRAL_API_KEY dans les variables d'environnement")
                
                self.validation_results[service_name] = ServiceValidationResult(
                    service_name=service_name,
                    is_available=False,
                    response_time=0.0,
                    validation_details={'error': 'MISTRAL_API_KEY manquante'},
                    issues_detected=issues,
                    recommendations=recommendations,
                    health_score=0.0
                )
                return
            
            # Test API Mistral direct
            test_prompt = "Répondez simplement 'Test validé' à ce message de validation."
            
            payload = {
                "model": "mistral-nemo-instruct-2407",
                "messages": [
                    {"role": "system", "content": "Tu es un assistant IA. Réponds brièvement."},
                    {"role": "user", "content": test_prompt}
                ],
                "temperature": 0.7,
                "max_tokens": 50
            }
            
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            
            timeout = aiohttp.ClientTimeout(total=self.performance_thresholds['mistral_max_response_time'])
            
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.post(
                    "http://localhost:8001/v1/chat/completions",
                    json=payload,
                    headers=headers
                ) as response:
                    
                    response_time = time.time() - start_time
                    
                    if response.status == 200:
                        result_data = await response.json()
                        response_text = result_data['choices'][0]['message']['content']
                        tokens_used = result_data.get('usage', {}).get('total_tokens', 0)
                        
                        validation_details = {
                            'response_time': response_time,
                            'response_length': len(response_text),
                            'tokens_used': tokens_used,
                            'response_successful': len(response_text) > 0,
                            'api_accessible': True,
                            'status_code': response.status,
                            'model_used': payload['model']
                        }
                        
                        # Vérifications de qualité
                        if response_time > self.performance_thresholds['mistral_max_response_time']:
                            issues.append(f"Temps de réponse Mistral élevé: {response_time:.1f}s")
                            recommendations.append("Optimiser les appels API Mistral")
                        
                        if len(response_text) == 0:
                            issues.append("Aucune réponse générée par Mistral")
                            recommendations.append("Vérifier les quotas API Mistral")
                        
                        if tokens_used == 0:
                            issues.append("Aucun token consommé - possible problème API")
                            recommendations.append("Vérifier la configuration API Mistral")
                        
                        # Score de santé basé sur la réponse
                        health_score = 1.0
                        if len(response_text) == 0:
                            health_score -= 0.5
                        if response_time > self.performance_thresholds['mistral_max_response_time']:
                            health_score -= 0.3
                        if tokens_used == 0:
                            health_score -= 0.2
                        health_score = max(0.0, health_score)
                        
                        self.validation_results[service_name] = ServiceValidationResult(
                            service_name=service_name,
                            is_available=len(response_text) > 0,
                            response_time=response_time,
                            validation_details=validation_details,
                            issues_detected=issues,
                            recommendations=recommendations,
                            health_score=health_score
                        )
                        
                        logger.info(f"Mistral Service validé: score={health_score:.2f}, {len(response_text)} chars, {tokens_used} tokens")
                    
                    else:
                        error_text = await response.text()
                        issues.append(f"Erreur HTTP Mistral {response.status}: {error_text}")
                        recommendations.append("Vérifier la clé API et les quotas Mistral")
                        
                        self.validation_results[service_name] = ServiceValidationResult(
                            service_name=service_name,
                            is_available=False,
                            response_time=response_time,
                            validation_details={'error': error_text, 'status_code': response.status},
                            issues_detected=issues,
                            recommendations=recommendations,
                            health_score=0.0
                        )
        
        except Exception as e:
            response_time = time.time() - start_time
            issues.append(f"Erreur API Mistral: {str(e)}")
            recommendations.append("Vérifier la connectivité internet et la clé API")
            
            self.validation_results[service_name] = ServiceValidationResult(
                service_name=service_name,
                is_available=False,
                response_time=response_time,
                validation_details={'error': str(e)},
                issues_detected=issues,
                recommendations=recommendations,
                health_score=0.0
            )
            
            logger.error(f"Mistral Service indisponible: {e}")
    
    async def _validate_service_integration(self):
        """Valide l'intégration entre les services - version simplifiée"""
        
        service_name = "Integration_Test"
        start_time = time.time()
        issues = []
        recommendations = []
        validation_details = {}
        
        try:
            # Vérifier que les services individuels sont disponibles
            tts_result = self.validation_results.get('TTS_Service')
            vosk_result = self.validation_results.get('VOSK_Service')
            mistral_result = self.validation_results.get('Mistral_Service')
            
            tts_available = tts_result and tts_result.is_available
            vosk_available = vosk_result and vosk_result.is_available
            mistral_available = mistral_result and mistral_result.is_available
            
            integration_time = time.time() - start_time
            
            validation_details = {
                'integration_time': integration_time,
                'tts_available': tts_available,
                'vosk_available': vosk_available,
                'mistral_available': mistral_available,
                'services_validated': 3,
                'services_available': sum([tts_available, vosk_available, mistral_available]),
                'integration_test_type': 'service_availability_check'
            }
            
            # Évaluation de l'intégration basée sur la disponibilité des services
            if not tts_available:
                issues.append("Service TTS non disponible pour intégration")
                recommendations.append("Corriger le service TTS avant intégration complète")
            
            if not vosk_available:
                issues.append("Service VOSK non disponible pour intégration")
                recommendations.append("Corriger le service VOSK avant intégration complète")
            
            if not mistral_available:
                issues.append("Service Mistral non disponible pour intégration")
                recommendations.append("Corriger le service Mistral avant intégration complète")
            
            # Score de santé basé sur la disponibilité des services
            available_count = sum([tts_available, vosk_available, mistral_available])
            health_score = available_count / 3.0
            
            integration_ready = all([tts_available, vosk_available, mistral_available])
            
            if integration_ready:
                recommendations.append("Tous les services sont prêts pour l'intégration complète")
            else:
                recommendations.append(f"Intégration partielle: {available_count}/3 services disponibles")
            
            self.validation_results[service_name] = ServiceValidationResult(
                service_name=service_name,
                is_available=integration_ready,
                response_time=integration_time,
                validation_details=validation_details,
                issues_detected=issues,
                recommendations=recommendations,
                health_score=health_score
            )
            
            logger.info(f"Test d'intégration: score={health_score:.2f}, {available_count}/3 services prêts")
        
        except Exception as e:
            integration_time = time.time() - start_time
            issues.append(f"Erreur test d'intégration: {str(e)}")
            recommendations.append("Vérifier la validation des services individuels")
            
            self.validation_results[service_name] = ServiceValidationResult(
                service_name=service_name,
                is_available=False,
                response_time=integration_time,
                validation_details={'error': str(e)},
                issues_detected=issues,
                recommendations=recommendations,
                health_score=0.0
            )
    
    async def _validate_marie_character(self):
        """Valide Marie AI Character"""
        
        service_name = "Marie_Character"
        start_time = time.time()
        issues = []
        recommendations = []
        validation_details = {}
        
        try:
            # Test basique de Marie
            marie = marie_character
            
            # Réinitialiser Marie
            marie.reset_conversation()
            
            # Test d'analyse d'input
            test_input = "Bonjour Marie, je viens vous présenter notre solution innovante"
            analysis = marie.analyze_user_input(test_input, {'total_time': 10})
            
            # Test de génération de réponse
            response_data = marie.generate_marie_response(test_input, analysis)
            
            validation_time = time.time() - start_time
            
            # Analyser les résultats
            marie_response = response_data.get('response', '')
            marie_satisfaction = response_data.get('marie_satisfaction', 0)
            marie_mode = response_data.get('conversation_mode', '')
            
            validation_details = {
                'processing_time': validation_time,
                'analysis_successful': len(analysis) > 0,
                'response_generated': len(marie_response) > 0,
                'response_length': len(marie_response),
                'marie_satisfaction': marie_satisfaction,
                'conversation_mode': marie_mode,
                'personality_active': True
            }
            
            # Vérifications de Marie
            if len(marie_response) == 0:
                issues.append("Marie ne génère pas de réponse")
                recommendations.append("Vérifier l'initialisation de Marie AI Character")
            
            if marie_satisfaction < 0.1 or marie_satisfaction > 1.0:
                issues.append(f"Niveau de satisfaction Marie incohérent: {marie_satisfaction}")
                recommendations.append("Vérifier les calculs de satisfaction de Marie")
            
            if not marie_mode:
                issues.append("Mode conversationnel Marie non défini")
                recommendations.append("Vérifier la logique de modes de Marie")
            
            # Tester les états de Marie
            marie_summary = marie.get_marie_state_summary()
            if not marie_summary or 'conversation_state' not in marie_summary:
                issues.append("État de Marie mal initialisé")
                recommendations.append("Vérifier l'initialisation complète de Marie")
            
            # Score de santé basé sur la fonctionnalité de Marie
            health_score = 1.0
            if not validation_details.get('response_generated', False):
                health_score -= 0.4
            if not validation_details.get('analysis_successful', False):
                health_score -= 0.3
            if validation_details.get('marie_satisfaction', 0.5) < 0.1 or validation_details.get('marie_satisfaction', 0.5) > 1.0:
                health_score -= 0.2
            if not validation_details.get('conversation_mode', ''):
                health_score -= 0.1
            health_score = max(0.0, health_score)
            
            self.validation_results[service_name] = ServiceValidationResult(
                service_name=service_name,
                is_available=len(marie_response) > 0,
                response_time=validation_time,
                validation_details=validation_details,
                issues_detected=issues,
                recommendations=recommendations,
                health_score=health_score
            )
            
            logger.info(f"Marie Character validée: score={health_score:.2f}")
        
        except Exception as e:
            validation_time = time.time() - start_time
            issues.append(f"Erreur Marie Character: {str(e)}")
            recommendations.append("Vérifier l'import et l'initialisation de marie_ai_character.py")
            
            self.validation_results[service_name] = ServiceValidationResult(
                service_name=service_name,
                is_available=False,
                response_time=validation_time,
                validation_details={'error': str(e)},
                issues_detected=issues,
                recommendations=recommendations,
                health_score=0.0
            )
    
    # Méthodes de calcul de scores de santé supprimées - calcul direct dans les fonctions de validation
    
    async def _generate_validation_report(self) -> Dict[str, Any]:
        """Génère le rapport final de validation"""
        
        total_validation_time = time.time() - self.overall_validation_start
        
        # Calculer les statistiques globales
        all_services = list(self.validation_results.values())
        available_services = [s for s in all_services if s.is_available]
        
        overall_availability = len(available_services) / len(all_services) if all_services else 0
        avg_health_score = sum(s.health_score for s in all_services) / len(all_services) if all_services else 0
        avg_response_time = sum(s.response_time for s in all_services) / len(all_services) if all_services else 0
        
        # Collecter tous les problèmes et recommandations
        all_issues = []
        all_recommendations = []
        
        for service in all_services:
            all_issues.extend(service.issues_detected)
            all_recommendations.extend(service.recommendations)
        
        # Collecter les problèmes d'environnement critiques
        critical_env_issues = [check for check in self.environment_checks if check.severity == "critical" and not check.is_valid]
        
        # Déterminer le statut global
        if critical_env_issues:
            overall_status = "CRITICAL_ENVIRONMENT_ISSUES"
        elif avg_health_score >= self.performance_thresholds['min_overall_score']:
            overall_status = "READY_FOR_PRODUCTION"
        elif avg_health_score >= self.performance_thresholds['min_health_score']:
            overall_status = "READY_WITH_WARNINGS"
        else:
            overall_status = "NOT_READY"
        
        return {
            'validation_metadata': {
                'validation_timestamp': self.overall_validation_start,
                'total_validation_time': total_validation_time,
                'validator_version': '1.0.0',
                'validation_mode': 'comprehensive'
            },
            'overall_status': overall_status,
            'global_metrics': {
                'overall_availability': overall_availability,
                'average_health_score': avg_health_score,
                'average_response_time': avg_response_time,
                'services_validated': len(all_services),
                'services_available': len(available_services),
                'total_issues_detected': len(all_issues),
                'critical_env_issues': len(critical_env_issues)
            },
            'environment_validation': {
                'checks_performed': len(self.environment_checks),
                'checks_passed': sum(1 for check in self.environment_checks if check.is_valid),
                'critical_issues': [asdict(check) for check in critical_env_issues],
                'all_checks': [asdict(check) for check in self.environment_checks]
            },
            'service_validation_results': {
                name: asdict(result) for name, result in self.validation_results.items()
            },
            'recommendations': {
                'immediate_actions': self._get_immediate_actions(),
                'optimization_suggestions': self._get_optimization_suggestions(),
                'all_recommendations': list(set(all_recommendations))
            },
            'readiness_assessment': {
                'ready_for_marie_conversation': overall_status in ["READY_FOR_PRODUCTION", "READY_WITH_WARNINGS"],
                'estimated_success_probability': min(1.0, avg_health_score * overall_availability),
                'bottleneck_services': self._identify_bottlenecks(),
                'next_steps': self._generate_next_steps(overall_status)
            }
        }
    
    def _get_immediate_actions(self) -> List[str]:
        """Retourne les actions immédiates requises"""
        actions = []
        
        # Actions critiques d'environnement
        for check in self.environment_checks:
            if check.severity == "critical" and not check.is_valid:
                actions.append(f"CRITIQUE: {check.recommendation}")
        
        # Actions pour services non disponibles
        for service in self.validation_results.values():
            if not service.is_available:
                actions.append(f"Redémarrer/corriger {service.service_name}")
        
        return actions
    
    def _get_optimization_suggestions(self) -> List[str]:
        """Retourne les suggestions d'optimisation"""
        suggestions = []
        
        for service in self.validation_results.values():
            if service.health_score < self.performance_thresholds['min_health_score']:
                suggestions.append(f"Optimiser {service.service_name} (score: {service.health_score:.2f})")
        
        return suggestions
    
    def _identify_bottlenecks(self) -> List[str]:
        """Identifie les services goulots d'étranglement"""
        bottlenecks = []
        
        for service in self.validation_results.values():
            if service.response_time > 15.0:  # Plus de 15 secondes
                bottlenecks.append(f"{service.service_name} (temps: {service.response_time:.1f}s)")
        
        return bottlenecks
    
    def _generate_next_steps(self, status: str) -> List[str]:
        """Génère les prochaines étapes selon le statut"""
        
        if status == "READY_FOR_PRODUCTION":
            return [
                "Lancer la conversation avec Marie en mode réel",
                "Surveiller les performances en temps réel",
                "Collecter les métriques de conversation"
            ]
        elif status == "READY_WITH_WARNINGS":
            return [
                "Corriger les avertissements non critiques",
                "Lancer la conversation avec surveillance renforcée",
                "Préparer des actions correctives"
            ]
        else:
            return [
                "Corriger les problèmes critiques identifiés",
                "Relancer la validation après corrections",
                "Ne pas démarrer la conversation avant validation OK"
            ]
    
    async def _generate_error_report(self, error: str) -> Dict[str, Any]:
        """Génère un rapport d'erreur"""
        
        return {
            'validation_error': True,
            'error_message': error,
            'validation_timestamp': self.overall_validation_start,
            'partial_results': {
                name: asdict(result) for name, result in self.validation_results.items()
            },
            'environment_checks': [asdict(check) for check in self.environment_checks],
            'recommendations': [
                "Vérifier les logs de validation pour plus de détails",
                "Corriger l'erreur critique avant de relancer",
                "Contacter le support technique si le problème persiste"
            ]
        }

# Point d'entrée principal
async def main():
    """Fonction principale de validation"""
    
    print("Validation Complète des Services pour Conversation Réelle avec Marie")
    print("=" * 70)
    
    # Créer et lancer le validateur
    validator = ServiceValidator()
    
    try:
        # Lancer la validation complète
        report = await validator.validate_all_services()
        
        # Sauvegarder le rapport
        timestamp = int(time.time())
        report_filename = f'service_validation_report_{timestamp}.json'
        
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\nRapport de validation sauvegardé: {report_filename}")
        
        # Afficher le résumé
        if not report.get('validation_error'):
            status = report['overall_status']
            metrics = report['global_metrics']
            
            print(f"\nSTATUT GLOBAL: {status}")
            print(f"Score de santé moyen: {metrics['average_health_score']:.2f}")
            print(f"Services disponibles: {metrics['services_available']}/{metrics['services_validated']}")
            print(f"Temps de réponse moyen: {metrics['average_response_time']:.1f}s")
            
            # Actions immédiates
            immediate_actions = report['recommendations']['immediate_actions']
            if immediate_actions:
                print(f"\nACTIONS IMMÉDIATES REQUISES:")
                for i, action in enumerate(immediate_actions, 1):
                    print(f"{i}. {action}")
            
            # Prêt pour Marie ?
            ready = report['readiness_assessment']['ready_for_marie_conversation']
            success_prob = report['readiness_assessment']['estimated_success_probability']
            
            print(f"\nPRÊT POUR CONVERSATION MARIE: {'OUI' if ready else 'NON'}")
            print(f"Probabilité de succès estimée: {success_prob:.1%}")
            
            return ready
        else:
            print(f"ERREUR DE VALIDATION: {report['error_message']}")
            return False
    
    except Exception as e:
        print(f"ERREUR CRITIQUE DE VALIDATION: {e}")
        return False

if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())