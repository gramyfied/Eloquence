#!/usr/bin/env python3
"""
Validateur d'Exercices Eloquence
===============================

Détecte automatiquement les exercices dans le projet et valide leur compatibilité
avec l'architecture réseau active.

Auteur: Eloquence Team
Version: 1.0.0
"""

import asyncio
import re
import os
import json
import yaml
import argparse
import logging
import time
from pathlib import Path
from typing import Dict, List, Optional, Set, NamedTuple
from dataclasses import dataclass, asdict
from datetime import datetime
from colorama import Fore, Back, Style, init
import traceback

from eloquence_network_manager import EloquenceNetworkManager, HealthCheckResult

# Initialiser colorama
init(autoreset=True)

# --- ASCII Icons ---
ICON_OK = "[OK]"
ICON_KO = "[KO]"
ICON_WARN = "[WARN]"
ICON_FAIL = "[FAIL]"
ICON_INFO = "[INFO]"
ICON_ACTION = "[ACTION]"
ICON_ERROR = "[ERROR]"
ICON_SCAN = "[SCAN]"
ICON_VALIDATE = "[VALIDATE]"
ICON_MONITOR = "[MONITOR]"
ICON_SUMMARY = "[SUMMARY]"
ICON_DETAILS = "[DETAILS]"

@dataclass
class ExerciseMetadata:
    """Métadonnées d'un exercice détecté"""
    name: str
    file_path: str
    exercise_type: str  # 'voice', 'cosmic', 'conversation', etc.
    language: str  # 'flutter', 'python', 'javascript'
    class_name: Optional[str] = None
    function_name: Optional[str] = None
    line_number: int = 0
    dependencies: List[str] = None
    required_services: List[str] = None
    api_endpoints: List[str] = None
    description: str = ""
    
    def __post_init__(self):
        if self.dependencies is None:
            self.dependencies = []
        if self.required_services is None:
            self.required_services = []
        if self.api_endpoints is None:
            self.api_endpoints = []

@dataclass
class ValidationReport:
    """Rapport de validation d'un exercice"""
    exercise_name: str
    is_valid: bool
    completeness_score: int  # 0-100%
    architecture_type: str  # 'principale', 'alternative', 'hybride'
    required_actions: List[str]
    missing_services: List[str]
    available_services: List[str]
    estimated_fix_time: str  # '30 minutes', '2 heures', etc.
    recommendations: List[str]
    service_health_scores: Dict[str, float]
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class ExerciseDetector:
    """Détecteur d'exercices dans le projet"""
    
    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.logger = self._setup_logger()
        
        # Patterns de détection par langage
        self.detection_patterns = {
            'flutter': [
                r'class\s+(\w*(?:Screen|Exercise|Page))\s*extends\s*(?:StatefulWidget|StatelessWidget)',
                r'class\s+(\w+(?:Screen|Exercise|Page))\s*extends\s*(?:ConsumerWidget|HookWidget)',
                r'class\s+(Cosmic\w+|Voice\w+|Confidence\w+|Breathing\w+|Conversation\w+)',
            ],
            'python': [
                r'def\s+(\w*exercise\w*)\s*\(',
                r'class\s+(\w*Exercise\w*)\s*(?:\(.*\))?:',
                r'def\s+(cosmic_\w+|voice_\w+|confidence_\w+|breathing_\w+)\s*\(',
            ],
            'javascript': [
                r'(?:const|let|var)\s+(\w*Exercise\w*)\s*=',
                r'function\s+(\w*Exercise\w*)\s*\(',
                r'class\s+(\w*Exercise\w*)\s*{',
            ]
        }
        
        # Extensions de fichiers à analyser
        self.file_extensions = {
            'flutter': ['.dart'],
            'python': ['.py'],
            'javascript': ['.js', '.ts', '.jsx', '.tsx']
        }
        
        # Mots-clés pour détecter le type d'exercice
        self.exercise_type_keywords = {
            'voice': ['voice', 'vocal', 'microphone', 'speech', 'audio'],
            'cosmic': ['cosmic', 'space', 'universe', 'star', 'galaxy'],
            'conversation': ['conversation', 'chat', 'dialogue', 'talk', 'mistral'],
            'breathing': ['breathing', 'breath', 'respiration', 'dragon'],
            'simulation': ['simulation', 'sim', 'scenario', 'roleplay'],
            'confidence': ['confidence', 'boost', 'self'],
            'articulation': ['articulation', 'pronunciation', 'diction'],
            'exercise': ['exercise', 'training', 'practice']  # Fallback
        }
        
    def _setup_logger(self) -> logging.Logger:
        """Configure le système de logging"""
        logger = logging.getLogger('exercise_detector')
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            
        return logger
        
    async def scan_project(self) -> List[ExerciseMetadata]:
        """
        Scan récursif du projet pour détecter les exercices
        
        Returns:
            List[ExerciseMetadata]: Liste des exercices détectés
        """
        self.logger.info(f"{ICON_SCAN} Scan du projet: {self.project_path}")
        
        exercises = []
        total_files = 0
        
        try:
            # Parcourir tous les fichiers source
            for language, extensions in self.file_extensions.items():
                for extension in extensions:
                    pattern = f"**/*{extension}"
                    
                    for file_path in self.project_path.rglob(pattern):
                        # Ignorer certains dossiers
                        if any(ignored in str(file_path) for ignored in [
                            'node_modules', '.git', 'build', 'dist', 
                            '.dart_tool', 'android', 'ios', 'windows'
                        ]):
                            continue
                            
                        total_files += 1
                        
                        try:
                            file_exercises = await self._analyze_file(file_path, language)
                            exercises.extend(file_exercises)
                            
                        except Exception as e:
                            self.logger.warning(f"Erreur lors de l'analyse de {file_path}: {str(e)}")
                            
            self.logger.info(f"{ICON_OK} Scan terminé - {len(exercises)} exercices détectés dans {total_files} fichiers")
            
            # Post-traitement: déduplication et enrichissement
            exercises = self._post_process_exercises(exercises)
            
            return exercises
            
        except Exception as e:
            self.logger.error(f"{ICON_ERROR} Erreur lors du scan: {str(e)}")
            return []
            
    async def _analyze_file(self, file_path: Path, language: str) -> List[ExerciseMetadata]:
        """Analyse un fichier pour détecter les exercices"""
        exercises = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            patterns = self.detection_patterns.get(language, [])
            
            for pattern in patterns:
                matches = re.finditer(pattern, content, re.MULTILINE | re.IGNORECASE)
                
                for match in matches:
                    exercise_name = match.group(1)
                    line_number = content[:match.start()].count('\n') + 1
                    
                    # Déterminer le type d'exercice
                    exercise_type = self._infer_exercise_type(exercise_name, content)
                    
                    # Extraire les dépendances et endpoints API
                    dependencies = self._extract_dependencies(content, language)
                    api_endpoints = self._extract_api_endpoints(content)
                    
                    # Créer les métadonnées
                    exercise = ExerciseMetadata(
                        name=exercise_name.lower(),
                        file_path=str(file_path.relative_to(self.project_path)),
                        exercise_type=exercise_type,
                        language=language,
                        class_name=exercise_name if 'class' in pattern else None,
                        function_name=exercise_name if 'def' in pattern else None,
                        line_number=line_number,
                        dependencies=dependencies,
                        api_endpoints=api_endpoints,
                        description=f"Exercice {exercise_type} détecté dans {file_path.name}"
                    )
                    
                    exercises.append(exercise)
                    
        except Exception as e:
            self.logger.debug(f"Erreur lors de l'analyse de {file_path}: {str(e)}")
            
        return exercises
        
    def _infer_exercise_type(self, exercise_name: str, content: str) -> str:
        """Infère le type d'exercice à partir du nom et du contenu"""
        exercise_name_lower = exercise_name.lower()
        content_lower = content.lower()
        
        # Recherche par mots-clés dans le nom
        for exercise_type, keywords in self.exercise_type_keywords.items():
            if any(keyword in exercise_name_lower for keyword in keywords):
                return exercise_type
                
        # Recherche par mots-clés dans le contenu (échantillon)
        content_sample = content_lower[:2000]  # Analyser les 2000 premiers caractères
        
        for exercise_type, keywords in self.exercise_type_keywords.items():
            keyword_count = sum(content_sample.count(keyword) for keyword in keywords)
            if keyword_count >= 2:  # Au moins 2 occurrences
                return exercise_type
                
        return 'exercise'  # Type par défaut
        
    def _extract_dependencies(self, content: str, language: str) -> List[str]:
        """Extrait les dépendances du code"""
        dependencies = []
        
        try:
            if language == 'flutter':
                # Imports Dart/Flutter
                import_pattern = r"import\s+['\"]([^'\"]+)['\"]"
                imports = re.findall(import_pattern, content)
                
                # Filtrer les dépendances pertinentes
                relevant_imports = [
                    imp for imp in imports 
                    if any(keyword in imp for keyword in [
                        'livekit', 'websocket', 'http', 'audio', 'microphone', 
                        'speech', 'provider', 'riverpod'
                    ])
                ]
                dependencies.extend(relevant_imports)
                
            elif language == 'python':
                # Imports Python
                import_pattern = r"(?:from\s+(\S+)\s+import|import\s+(\S+))"
                matches = re.findall(import_pattern, content)
                
                for match in matches:
                    module = match[0] or match[1]
                    if any(keyword in module for keyword in [
                        'aiohttp', 'websockets', 'redis', 'asyncio',
                        'speech', 'audio', 'livekit'
                    ]):
                        dependencies.append(module)
                        
            elif language == 'javascript':
                # Imports JavaScript/TypeScript
                import_pattern = r"import\s+.*?from\s+['\"]([^'\"]+)['\"]"
                imports = re.findall(import_pattern, content)
                
                relevant_imports = [
                    imp for imp in imports 
                    if any(keyword in imp for keyword in [
                        'websocket', 'axios', 'fetch', 'audio', 'microphone'
                    ])
                ]
                dependencies.extend(relevant_imports)
                
        except Exception as e:
            self.logger.debug(f"Erreur lors de l'extraction des dépendances: {str(e)}")
            
        return list(set(dependencies))  # Supprimer les doublons
        
    def _extract_api_endpoints(self, content: str) -> List[str]:
        """Extrait les endpoints API utilisés"""
        endpoints = []
        
        try:
            # Patterns pour détecter les URLs d'API
            url_patterns = [
                r'["\']http[s]?://[^"\']+["\']',
                r'["\']ws[s]?://[^"\']+["\']',
                r'["\'][^"\']*:\d+[^"\']*["\']',  # URLs avec ports
                r'localhost:\d+',
                r'127\.0\.0\.1:\d+'
            ]
            
            for pattern in url_patterns:
                matches = re.findall(pattern, content, re.IGNORECASE)
                
                for match in matches:
                    # Nettoyer l'URL
                    url = match.strip('\'"')
                    if url and url not in endpoints:
                        endpoints.append(url)
                        
        except Exception as e:
            self.logger.debug(f"Erreur lors de l'extraction des endpoints: {str(e)}")
            
        return endpoints
        
    def _post_process_exercises(self, exercises: List[ExerciseMetadata]) -> List[ExerciseMetadata]:
        """Post-traitement des exercices détectés"""
        # Supprimer les doublons basés sur le nom
        unique_exercises = {}
        
        for exercise in exercises:
            key = exercise.name
            if key not in unique_exercises:
                unique_exercises[key] = exercise
            else:
                # Garder celui avec le plus d'informations
                existing = unique_exercises[key]
                if len(exercise.dependencies) > len(existing.dependencies):
                    unique_exercises[key] = exercise
                    
        processed_exercises = list(unique_exercises.values())
        
        # Enrichir avec les services requis basés sur le type
        for exercise in processed_exercises:
            exercise.required_services = self._infer_required_services(exercise)
            
        return processed_exercises
        
    def _infer_required_services(self, exercise: ExerciseMetadata) -> List[str]:
        """Infère les services requis pour un exercice"""
        service_keywords = {
            'voice': ['vosk_stt', 'eloquence_exercises_api'],
            'cosmic': ['livekit_server', 'livekit_token_service', 'vosk_stt', 'eloquence_exercises_api'],
            'conversation': ['mistral_conversation', 'livekit_server', 'livekit_token_service', 'eloquence_exercises_api'],
            'breathing': ['eloquence_exercises_api'],
            'simulation': ['livekit_server', 'livekit_token_service', 'mistral_conversation', 'eloquence_exercises_api'],
            'confidence': ['mistral_conversation', 'eloquence_exercises_api'],
            'articulation': ['vosk_stt', 'eloquence_exercises_api'],
            'exercise': ['eloquence_exercises_api']  # Fallback
        }
        
        return service_keywords.get(exercise.exercise_type, ['eloquence_exercises_api'])


class ExerciseValidator:
    """Validateur d'exercices"""
    
    def __init__(self, network_manager: EloquenceNetworkManager):
        self.network_manager = network_manager
        self.logger = self._setup_logger()
        
    def _setup_logger(self) -> logging.Logger:
        """Configure le système de logging"""
        logger = logging.getLogger('exercise_validator')
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            
        return logger
        
    async def validate_exercise(self, exercise: ExerciseMetadata) -> ValidationReport:
        """
        Valide un exercice spécifique
        
        Args:
            exercise: Métadonnées de l'exercice à valider
            
        Returns:
            ValidationReport: Rapport de validation
        """
        self.logger.info(f"{ICON_VALIDATE} Validation de l'exercice: {exercise.name}")
        
        try:
            # 1. Vérifier l'état des services requis
            service_health = await self._check_required_services(exercise.required_services)
            
            # 2. Déterminer le type d'architecture
            architecture_type = self._determine_architecture_type(service_health)
            
            # 3. Calculer le score de complétude
            completeness_score = self._calculate_completeness_score(exercise, service_health)
            
            # 4. Identifier les services manquants
            missing_services = [
                service for service in exercise.required_services
                if service not in service_health or service_health[service].status != 'healthy'
            ]
            
            available_services = [
                service for service in exercise.required_services
                if service in service_health and service_health[service].status == 'healthy'
            ]
            
            # 5. Générer les actions requises
            required_actions = self._generate_required_actions(exercise, service_health, missing_services)
            
            # 6. Générer les recommandations
            recommendations = self._generate_recommendations(exercise, service_health)
            
            # 7. Estimer le temps de correction
            estimated_fix_time = self._estimate_fix_time(missing_services, required_actions)
            
            # 8. Calculer les scores de santé des services
            service_health_scores = {
                service: self._calculate_service_health_score(result)
                for service, result in service_health.items()
            }
            
            # 9. Déterminer si l'exercice est valide
            is_valid = completeness_score >= 80 and len(missing_services) == 0
            
            return ValidationReport(
                exercise_name=exercise.name,
                is_valid=is_valid,
                completeness_score=completeness_score,
                architecture_type=architecture_type,
                required_actions=required_actions,
                missing_services=missing_services,
                available_services=available_services,
                estimated_fix_time=estimated_fix_time,
                recommendations=recommendations,
                service_health_scores=service_health_scores
            )
            
        except Exception as e:
            self.logger.error(f"{ICON_ERROR} Erreur lors de la validation de {exercise.name}: {str(e)}")
            
            return ValidationReport(
                exercise_name=exercise.name,
                is_valid=False,
                completeness_score=0,
                architecture_type='inconnue',
                required_actions=[f"Erreur de validation: {str(e)}"],
                missing_services=exercise.required_services,
                available_services=[],
                estimated_fix_time='Indéterminé',
                recommendations=['Résoudre l\'erreur de validation'],
                service_health_scores={}
            )
            
    async def _check_required_services(self, required_services: List[str]) -> Dict[str, HealthCheckResult]:
        """Vérifie l'état des services requis"""
        service_health = {}
        
        for service_name in required_services:
            try:
                result = await self.network_manager.check_service_health(service_name)
                service_health[service_name] = result
            except Exception as e:
                self.logger.warning(f"Erreur lors de la vérification de {service_name}: {str(e)}")
                service_health[service_name] = HealthCheckResult(
                    service_name=service_name,
                    status='error',
                    response_time=0,
                    error_message=str(e)
                )
                
        return service_health
        
    def _determine_architecture_type(self, service_health: Dict[str, HealthCheckResult]) -> str:
        """Détermine le type d'architecture basé sur les services actifs"""
        healthy_services = [
            service for service, result in service_health.items()
            if result.status == 'healthy'
        ]
        
        # Services de l'architecture principale
        principal_services = {
            'eloquence_exercises_api', 'livekit_server', 'livekit_token_service',
            'vosk_stt', 'mistral_conversation', 'redis'
        }
        
        # Services de l'architecture alternative/fallback
        fallback_services = {
            'tts_service', 'whisper_stt', 'llm_service_fallback', 'vosk_service_fallback'
        }
        
        principal_healthy = sum(1 for s in healthy_services if s in principal_services)
        fallback_healthy = sum(1 for s in healthy_services if s in fallback_services)
        
        if principal_healthy >= 4:  # Au moins 4 services principaux actifs
            return 'principale'
        elif fallback_healthy >= 2:
            return 'alternative'
        elif principal_healthy >= 2 and fallback_healthy >= 1:
            return 'hybride'
        else:
            return 'dégradée'
            
    def _calculate_completeness_score(self, exercise: ExerciseMetadata, 
                                    service_health: Dict[str, HealthCheckResult]) -> int:
        """Calcule le score de complétude (0-100%)"""
        score = 0
        
        # 1. Services requis disponibles (60%)
        required_services = len(exercise.required_services)
        if required_services > 0:
            healthy_required = sum(
                1 for service in exercise.required_services
                if service in service_health and service_health[service].status == 'healthy'
            )
            score += (healthy_required / required_services) * 60
            
        # 2. Qualité des dépendances (20%)
        if exercise.dependencies:
            # Simple heuristique: si des dépendances sont définies, c'est bon
            score += 20
        else:
            score += 10  # Score partiel si aucune dépendance détectée
            
        # 3. Endpoints API détectés (10%)
        if exercise.api_endpoints:
            score += 10
        else:
            score += 5  # Score partiel
            
        # 4. Métadonnées complètes (10%)
        metadata_score = 0
        if exercise.class_name or exercise.function_name:
            metadata_score += 3
        if exercise.description:
            metadata_score += 3
        if exercise.line_number > 0:
            metadata_score += 2
        if exercise.file_path:
            metadata_score += 2
            
        score += metadata_score
        
        return min(100, int(score))
        
    def _generate_required_actions(self, exercise: ExerciseMetadata,
                                 service_health: Dict[str, HealthCheckResult],
                                 missing_services: List[str]) -> List[str]:
        """Génère la liste des actions requises"""
        actions = []
        
        # Actions pour les services manquants
        for service in missing_services:
            if service in service_health:
                result = service_health[service]
                if result.status == 'timeout':
                    actions.append(f"Optimiser timeout pour le service {service}")
                elif result.status == 'unreachable':
                    actions.append(f"Vérifier la connectivité réseau vers {service}")
                elif result.status == 'unhealthy':
                    actions.append(f"Redémarrer le service {service}")
                else:
                    actions.append(f"Diagnostiquer le problème avec {service}")
            else:
                actions.append(f"Configurer et démarrer le service {service}")
                
        # Actions spécifiques selon le type d'exercice
        if exercise.exercise_type == 'cosmic':
            if 'livekit_server' in missing_services:
                actions.append("Configurer les variables d'environnement LiveKit")
            if 'vosk_stt' in missing_services:
                actions.append("Télécharger les modèles de reconnaissance vocale Vosk")
                
        elif exercise.exercise_type == 'conversation':
            if 'mistral_conversation' in missing_services:
                actions.append("Vérifier la clé API Mistral et l'URL Scaleway")
                
        # Actions pour améliorer la robustesse
        if not exercise.api_endpoints:
            actions.append("Ajouter la gestion d'erreur pour les appels API")
            
        if len(exercise.dependencies) < 2:
            actions.append("Vérifier et compléter les imports nécessaires")
            
        return actions
        
    def _generate_recommendations(self, exercise: ExerciseMetadata,
                                service_health: Dict[str, HealthCheckResult]) -> List[str]:
        """Génère des recommandations d'optimisation"""
        recommendations = []
        
        # Recommandations de performance
        slow_services = [
            service for service, result in service_health.items()
            if result.status == 'healthy' and result.response_time > 1000
        ]
        
        if slow_services:
            recommendations.append(
                f"Optimiser les performances des services lents: {', '.join(slow_services)}"
            )
            
        # Recommandations de fiabilité
        if exercise.exercise_type in ['cosmic', 'conversation']:
            recommendations.append("Implémenter un mécanisme de fallback pour les services critiques")
            
        # Recommandations de monitoring
        recommendations.append("Ajouter des logs de diagnostic pour faciliter le debugging")
        
        # Recommandations spécifiques
        if exercise.exercise_type == 'voice':
            recommendations.append("Implémenter la détection de silence pour économiser les ressources")
            
        elif exercise.exercise_type == 'cosmic':
            recommendations.append("Ajouter une vérification de compatibilité WebRTC")
            
        return recommendations
        
    def _estimate_fix_time(self, missing_services: List[str], required_actions: List[str]) -> str:
        """Estime le temps de correction nécessaire"""
        # Base de temps selon le nombre de services manquants
        base_time = len(missing_services) * 15  # 15 minutes par service
        
        # Ajustements selon les types d'actions
        for action in required_actions:
            if 'redémarrer' in action.lower():
                base_time += 5
            elif 'configurer' in action.lower():
                base_time += 30
            elif 'télécharger' in action.lower():
                base_time += 45
            elif 'diagnostiquer' in action.lower():
                base_time += 60
                
        # Convertir en format lisible
        if base_time < 60:
            return f"{base_time} minutes"
        elif base_time < 240:
            hours = base_time // 60
            minutes = base_time % 60
            return f"{hours}h{minutes:02d}"
        else:
            return "Plus de 4 heures"
            
    def _calculate_service_health_score(self, result: HealthCheckResult) -> float:
        """Calcule un score de santé pour un service (0-100)"""
        if result.status == 'healthy':
            # Score basé sur le temps de réponse
            if result.response_time < 100:
                return 100.0
            elif result.response_time < 500:
                return 90.0
            elif result.response_time < 1000:
                return 80.0
            elif result.response_time < 5000:
                return 60.0
            else:
                return 40.0
        elif result.status == 'timeout':
            return 20.0
        elif result.status == 'unhealthy':
            return 10.0
        else:
            return 0.0
            
    async def validate_all_exercises(self, exercises: List[ExerciseMetadata]) -> Dict[str, ValidationReport]:
        """Valide tous les exercices"""
        self.logger.info(f"{ICON_VALIDATE} Validation de {len(exercises)} exercices...")
        
        reports = {}
        
        for exercise in exercises:
            try:
                report = await self.validate_exercise(exercise)
                reports[exercise.name] = report
            except Exception as e:
                self.logger.error(f"{ICON_ERROR} Erreur lors de la validation de {exercise.name}: {str(e)}")
                
        return reports


async def main():
    """Point d'entrée principal avec interface CLI"""
    parser = argparse.ArgumentParser(description='Validateur d\'Exercices Eloquence')
    parser.add_argument('--scan', action='store_true', help='Scanner le projet pour détecter les exercices')
    parser.add_argument('--validate', type=str, metavar='EXERCISE_NAME', help='Valider un exercice spécifique')
    parser.add_argument('--validate-all', action='store_true', help='Valider tous les exercices détectés')
    parser.add_argument('--monitor', type=int, metavar='INTERVAL', help='Monitoring continu des exercices (interval en secondes)')
    parser.add_argument('--project-path', type=str, default='.', help='Chemin vers le projet à analyser')
    # Déterminer le fichier de configuration à utiliser (local si disponible)
    script_dir = Path(__file__).resolve().parent
    local_config_path = script_dir / 'eloquence_network_config.local.yaml'
    default_config_path = script_dir / 'eloquence_network_config.yaml'
    
    config_to_use = local_config_path if local_config_path.exists() else default_config_path
    
    parser.add_argument('--config', type=str, default=str(config_to_use), help='Fichier de configuration réseau')
    parser.add_argument('--output', type=str, help='Fichier de sortie pour les résultats (JSON)')
    
    args = parser.parse_args()
    
    try:
        # Initialiser le détecteur
        detector = ExerciseDetector(args.project_path)
        
        # Initialiser le gestionnaire réseau pour la validation
        network_manager = EloquenceNetworkManager(config_path=args.config)
        if not await network_manager.initialize():
            print(f"{Fore.RED}{ICON_ERROR} Échec de l'initialisation du gestionnaire réseau{Style.RESET_ALL}")
            return 1
            
        validator = ExerciseValidator(network_manager)
        
        if args.scan:
            # Scanner le projet
            print(f"{Fore.CYAN}{ICON_SCAN} Scan des exercices dans: {args.project_path}{Style.RESET_ALL}\n")
            
            exercises = await detector.scan_project()
            
            if exercises:
                print(f"{Fore.GREEN}{ICON_INFO} {len(exercises)} exercices détectés:{Style.RESET_ALL}\n")
                
                for exercise in exercises:
                    print(f"{ICON_DETAILS} {exercise.name}")
                    print(f"  - Type: {exercise.exercise_type}")
                    print(f"  - Fichier: {exercise.file_path}:{exercise.line_number}")
                    print(f"  - Langage: {exercise.language}")
                    print(f"  - Services requis: {', '.join(exercise.required_services)}")
                    print()
                    
                if args.output:
                    # Sauvegarder les résultats
                    with open(args.output, 'w', encoding='utf-8') as f:
                        json.dump([asdict(ex) for ex in exercises], f, indent=2, default=str)
                    print(f"{Fore.GREEN}{ICON_INFO} Résultats sauvegardés: {args.output}{Style.RESET_ALL}")
                    
            else:
                print(f"{Fore.YELLOW}{ICON_WARN} Aucun exercice détecté{Style.RESET_ALL}")
                
        elif args.validate:
            # Valider un exercice spécifique
            print(f"{Fore.CYAN}{ICON_VALIDATE} Validation: {args.validate}{Style.RESET_ALL}\n")
            
            # D'abord scanner pour trouver l'exercice
            exercises = await detector.scan_project()
            target_exercise = next((ex for ex in exercises if ex.name == args.validate), None)
            
            if not target_exercise:
                print(f"{Fore.RED}{ICON_ERROR} Exercice '{args.validate}' non trouvé{Style.RESET_ALL}")
                return 1
                
            # Valider l'exercice
            report = await validator.validate_exercise(target_exercise)
            
            # Afficher le rapport
            print(f"{ICON_INFO} Architecture: {report.architecture_type.title()}")
            print(f"{ICON_INFO} Score de complétude: {report.completeness_score}%")
            print(f"{ICON_INFO} Valide: {report.is_valid}")
            print(f"{ICON_INFO} Temps estimé: {report.estimated_fix_time}")
            
            if report.missing_services:
                print(f"\n{Fore.RED}{ICON_ERROR} Services manquants:{Style.RESET_ALL}")
                for service in report.missing_services:
                    print(f"  - {service}")
                    
            if report.required_actions:
                print(f"\n{Fore.YELLOW}{ICON_ACTION} Actions requises:{Style.RESET_ALL}")
                for action in report.required_actions:
                    print(f"  - {action}")
                    
            if report.recommendations:
                print(f"\n{Fore.BLUE}{ICON_INFO} Recommandations:{Style.RESET_ALL}")
                for rec in report.recommendations:
                    print(f"  - {rec}")
                    
        elif args.validate_all:
            # Valider tous les exercices
            print(f"{Fore.CYAN}{ICON_VALIDATE} Validation de tous les exercices{Style.RESET_ALL}\n")
            
            exercises = await detector.scan_project()
            if not exercises:
                print(f"{Fore.YELLOW}{ICON_WARN} Aucun exercice détecté{Style.RESET_ALL}")
                return 0
                
            reports = await validator.validate_all_exercises(exercises)
            
            # Statistiques globales
            valid_exercises = sum(1 for report in reports.values() if report.is_valid)
            avg_score = sum(report.completeness_score for report in reports.values()) / len(reports)
            
            print(f"{ICON_SUMMARY} Résumé global:")
            print(f"  - Exercices valides: {valid_exercises}/{len(reports)}")
            print(f"  - Score moyen: {avg_score:.1f}%")
            print()
            
            # Détails par exercice
            for exercise_name, report in reports.items():
                status_icon = ICON_OK if report.is_valid else ICON_KO
                status_color = Fore.GREEN if report.is_valid else Fore.RED
                
                print(f"{status_color}{status_icon} {exercise_name} ({report.completeness_score}%){Style.RESET_ALL}")
                
                if not report.is_valid and report.required_actions:
                    print(f"  - Actions: {report.required_actions[0]}")
                    
        elif args.monitor:
            # Monitoring continu
            print(f"{Fore.CYAN}{ICON_MONITOR} Monitoring continu des exercices (intervalle: {args.monitor}s){Style.RESET_ALL}\n")
            
            try:
                while True:
                    exercises = await detector.scan_project()
                    reports = await validator.validate_all_exercises(exercises)
                    
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    valid_count = sum(1 for report in reports.values() if report.is_valid)
                    total_count = len(reports)
                    
                    if valid_count == total_count:
                        color = Fore.GREEN
                        icon = ICON_OK
                    elif valid_count > total_count // 2:
                        color = Fore.YELLOW
                        icon = ICON_WARN
                    else:
                        color = Fore.RED
                        icon = ICON_FAIL
                        
                    print(f"{color}[{timestamp}] {icon} Exercices: {valid_count}/{total_count} valides{Style.RESET_ALL}")
                    
                    # Afficher les exercices en erreur
                    for name, report in reports.items():
                        if not report.is_valid:
                            print(f"  {Fore.RED}- {name}: {report.required_actions[0] if report.required_actions else 'Erreur inconnue'}{Style.RESET_ALL}")
                            
                    await asyncio.sleep(args.monitor)
                    
            except KeyboardInterrupt:
                print(f"\n{Fore.YELLOW}>> Arrêt du monitoring demandé{Style.RESET_ALL}")
                
        else:
            # Afficher l'aide
            parser.print_help()
            
        return 0
        
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}>> Arrêt demandé par l'utilisateur{Style.RESET_ALL}")
        return 0
    except Exception as e:
        print(f"{Fore.RED}{ICON_ERROR} {str(e)}{Style.RESET_ALL}")
        traceback.print_exc()
        return 1
    finally:
        if 'network_manager' in locals():
            await network_manager.close()


if __name__ == '__main__':
    # Configurer l'événement loop pour Windows
    if os.name == 'nt':
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
        
    exit_code = asyncio.run(main())
    exit(exit_code)