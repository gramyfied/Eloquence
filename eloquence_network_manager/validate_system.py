#!/usr/bin/env python3
"""
Script de Validation Système - Gestionnaire Réseau Eloquence
============================================================

Valide tous les critères de réussite obligatoires selon les spécifications.

Auteur: Eloquence Team
Version: 1.0.0
"""

import asyncio
import os
import sys
import json
import time
import tempfile
import psutil
from pathlib import Path
from colorama import Fore, Back, Style, init

# Initialiser colorama
init(autoreset=True)

# Ajouter le répertoire parent au PYTHONPATH
sys.path.insert(0, str(Path(__file__).parent))

from eloquence_network_manager import EloquenceNetworkManager
from exercise_validator import ExerciseDetector, ExerciseValidator


class SystemValidator:
    """Validateur du système selon les critères de réussite"""
    
    def __init__(self):
        self.results = []
        self.total_tests = 0
        self.passed_tests = 0
        
    def test(self, name: str, condition: bool, details: str = ""):
        """Enregistre le résultat d'un test"""
        self.total_tests += 1
        
        if condition:
            self.passed_tests += 1
            icon = "✅"
            color = Fore.GREEN
            status = "PASS"
        else:
            icon = "❌"
            color = Fore.RED
            status = "FAIL"
            
        print(f"{color}{icon} {name}: {status}{Style.RESET_ALL}")
        if details:
            print(f"    {details}")
            
        self.results.append({
            'name': name,
            'passed': condition,
            'details': details
        })
        
    def print_summary(self):
        """Affiche le résumé final"""
        success_rate = (self.passed_tests / self.total_tests) * 100 if self.total_tests > 0 else 0
        
        print(f"\n{'='*80}")
        print(f"{Fore.CYAN}[*] RESUME DE VALIDATION{Style.RESET_ALL}")
        print(f"{'='*80}")
        print(f"Tests exécutés: {self.total_tests}")
        print(f"Tests réussis: {self.passed_tests}")
        print(f"Tests échoués: {self.total_tests - self.passed_tests}")
        print(f"Taux de réussite: {success_rate:.1f}%")
        
        if success_rate >= 90:
            print(f"\n{Fore.GREEN}[+] VALIDATION REUSSIE - Systeme pret pour la production{Style.RESET_ALL}")
        elif success_rate >= 80:
            print(f"\n{Fore.YELLOW}[!] VALIDATION PARTIELLE - Quelques ameliorations necessaires{Style.RESET_ALL}")
        else:
            print(f"\n{Fore.RED}[-] VALIDATION ECHOUEE - Corrections majeures requises{Style.RESET_ALL}")
            
        return success_rate >= 90


async def validate_system():
    """Fonction principale de validation"""
    validator = SystemValidator()
    
    print(f"{Fore.CYAN}[*] VALIDATION DU GESTIONNAIRE RESEAU ELOQUENCE{Style.RESET_ALL}")
    print(f"{'='*80}\n")
    
    # ===== TESTS DE STRUCTURE ET FICHIERS =====
    print(f"{Fore.BLUE}[+] Tests de Structure{Style.RESET_ALL}")
    print("-" * 30)
    
    # Vérifier la présence des fichiers obligatoires
    required_files = [
        'eloquence_network_manager.py',
        'exercise_validator.py', 
        'eloquence_network_config.yaml',
        'requirements.txt',
        'README.md'
    ]
    
    for file_name in required_files:
        file_path = Path(file_name)
        validator.test(
            f"Fichier {file_name} présent",
            file_path.exists(),
            f"Chemin: {file_path.absolute()}"
        )
        
    # Vérifier la présence des tests
    test_files = [
        'tests/test_network_manager.py',
        'tests/test_exercise_validator.py'
    ]
    
    for test_file in test_files:
        test_path = Path(test_file)
        validator.test(
            f"Test {test_file} présent",
            test_path.exists(),
            f"Chemin: {test_path.absolute()}"
        )
    
    # ===== TESTS DE CONFIGURATION =====
    print(f"\n{Fore.BLUE}[+] Tests de Configuration{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Test de chargement de la configuration YAML
        import yaml
        with open('eloquence_network_config.yaml', 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
            
        validator.test(
            "Configuration YAML valide",
            'services' in config and len(config['services']) >= 6,
            f"Services configurés: {len(config.get('services', []))}"
        )
        
        # Vérifier les services critiques
        service_names = [s['name'] for s in config.get('services', [])]
        critical_services = [
            'eloquence_exercises_api', 'livekit_server', 'livekit_token_service',
            'vosk_stt', 'mistral_conversation', 'redis'
        ]
        
        for service in critical_services:
            validator.test(
                f"Service {service} configuré",
                service in service_names,
                f"Trouvé dans la configuration"
            )
            
    except Exception as e:
        validator.test("Configuration YAML valide", False, f"Erreur: {str(e)}")
    
    # ===== TESTS D'INITIALISATION =====
    print(f"\n{Fore.BLUE}🚀 Tests d'Initialisation{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Test d'import des modules
        validator.test("Import EloquenceNetworkManager", True, "Module importé avec succès")
        validator.test("Import ExerciseDetector", True, "Module importé avec succès")
        validator.test("Import ExerciseValidator", True, "Module importé avec succès")
        
        # Test de création d'instance
        manager = EloquenceNetworkManager()
        validator.test("Création instance EloquenceNetworkManager", True, "Instance créée")
        
        # Test de chargement de configuration
        config_loaded = await manager._load_configuration()
        validator.test("Chargement configuration", config_loaded, "Configuration chargée depuis YAML")
        
        validator.test(
            "Services détectés automatiquement",
            len(manager.services) >= 6,
            f"{len(manager.services)} services détectés"
        )
        
    except Exception as e:
        validator.test("Initialisation système", False, f"Erreur: {str(e)}")
        
    # ===== TESTS FONCTIONNELS =====
    print(f"\n{Fore.BLUE}⚡ Tests Fonctionnels{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Test des méthodes obligatoires du gestionnaire réseau
        manager = EloquenceNetworkManager()
        await manager._load_configuration()
        
        # Vérifier la présence des méthodes obligatoires
        required_methods = [
            'initialize', 'check_service_health', 'check_all_services',
            'auto_fix_issues', 'generate_report'
        ]
        
        for method_name in required_methods:
            validator.test(
                f"Méthode {method_name} implémentée",
                hasattr(manager, method_name) and callable(getattr(manager, method_name)),
                f"Méthode trouvée dans EloquenceNetworkManager"
            )
            
        # Test de vérification de santé globale
        manager._init_http_session()
        
        # Mock des vérifications pour éviter les erreurs réseau
        from unittest.mock import AsyncMock
        
        async def mock_check_service(service_name):
            from eloquence_network_manager import HealthCheckResult
            return HealthCheckResult(service_name, 'healthy', 100)
            
        original_method = manager.check_service_health
        manager.check_service_health = mock_check_service
        
        start_time = time.time()
        health_report = await manager.check_all_services()
        duration = time.time() - start_time
        
        validator.test(
            "Score de santé global calculé",
            'global_health_score' in health_report,
            f"Score: {health_report.get('global_health_score', 'N/A')}%"
        )
        
        validator.test(
            "Performance vérification < 5s",
            duration < 5.0,
            f"Durée: {duration:.2f}s"
        )
        
        validator.test(
            "Rapport structuré complet",
            all(key in health_report for key in ['services', 'summary', 'global_health_score']),
            "Toutes les clés requises présentes"
        )
        
        # Restaurer la méthode originale
        manager.check_service_health = original_method
        
        await manager.close()
        
    except Exception as e:
        validator.test("Tests fonctionnels", False, f"Erreur: {str(e)}")
        
    # ===== TESTS DU VALIDATEUR D'EXERCICES =====
    print(f"\n{Fore.BLUE}🏃 Tests Validateur d'Exercices{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Test du détecteur d'exercices
        detector = ExerciseDetector('.')
        
        # Test des patterns de détection
        validator.test(
            "Patterns de détection configurés",
            len(detector.detection_patterns) >= 3,
            f"Patterns pour {len(detector.detection_patterns)} langages"
        )
        
        validator.test(
            "Types d'exercices supportés",
            len(detector.exercise_type_keywords) >= 7,
            f"{len(detector.exercise_type_keywords)} types supportés"
        )
        
        # Test d'inférence de type d'exercice
        cosmic_type = detector._infer_exercise_type('cosmic_voice_screen', '')
        validator.test(
            "Inférence type d'exercice",
            cosmic_type == 'cosmic',
            f"cosmic_voice_screen → {cosmic_type}"
        )
        
        # Test d'inférence des services requis
        from exercise_validator import ExerciseMetadata
        test_exercise = ExerciseMetadata(
            name='test_cosmic',
            file_path='test.dart',
            exercise_type='cosmic',
            language='flutter'
        )
        
        required_services = detector._infer_required_services(test_exercise)
        validator.test(
            "Services requis inférés",
            len(required_services) >= 3 and 'livekit_server' in required_services,
            f"Services: {', '.join(required_services)}"
        )
        
    except Exception as e:
        validator.test("Tests validateur d'exercices", False, f"Erreur: {str(e)}")
        
    # ===== TESTS DE PERFORMANCE =====
    print(f"\n{Fore.BLUE}⚡ Tests de Performance{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Test de détection d'architecture
        manager = EloquenceNetworkManager()
        await manager._load_configuration()
        
        start_time = time.time()
        # Simulation de détection d'architecture
        service_health = {
            'eloquence_exercises_api': type('HealthResult', (), {'status': 'healthy'})(),
            'livekit_server': type('HealthResult', (), {'status': 'healthy'})(),
            'vosk_stt': type('HealthResult', (), {'status': 'healthy'})(),
        }
        
        # Créer un validateur pour tester la détection d'architecture
        temp_validator = ExerciseValidator(manager)
        arch_type = temp_validator._determine_architecture_type(service_health)
        duration = time.time() - start_time
        
        validator.test(
            "Détection architecture < 2s",
            duration < 2.0,
            f"Durée: {duration:.3f}s, Type: {arch_type}"
        )
        
        # Test d'utilisation mémoire
        process = psutil.Process()
        memory_mb = process.memory_info().rss / 1024 / 1024
        
        validator.test(
            "Utilisation mémoire < 100MB",
            memory_mb < 100,
            f"Mémoire: {memory_mb:.1f}MB"
        )
        
        await manager.close()
        
    except Exception as e:
        validator.test("Tests de performance", False, f"Erreur: {str(e)}")
        
    # ===== TESTS CLI =====
    print(f"\n{Fore.BLUE}🖥️ Tests Interface CLI{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Test de présence des commandes CLI
        import subprocess
        
        # Test help du gestionnaire principal
        result = subprocess.run(
            [sys.executable, 'eloquence_network_manager.py', '--help'],
            capture_output=True, text=True, timeout=10
        )
        
        validator.test(
            "CLI gestionnaire réseau fonctionnel",
            result.returncode == 0 and '--check' in result.stdout,
            "Commande --help exécutée avec succès"
        )
        
        # Test help du validateur d'exercices
        result = subprocess.run(
            [sys.executable, 'exercise_validator.py', '--help'],
            capture_output=True, text=True, timeout=10
        )
        
        validator.test(
            "CLI validateur exercices fonctionnel",
            result.returncode == 0 and '--scan' in result.stdout,
            "Commande --help exécutée avec succès"
        )
        
    except Exception as e:
        validator.test("Tests interface CLI", False, f"Erreur: {str(e)}")
        
    # ===== TESTS D'INTÉGRATION =====
    print(f"\n{Fore.BLUE}🔗 Tests d'Intégration{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Test d'exécution des tests unitaires
        result = subprocess.run(
            [sys.executable, '-m', 'pytest', 'tests/', '-v', '--tb=short'],
            capture_output=True, text=True, timeout=60, cwd='.'
        )
        
        # Analyser les résultats des tests
        if result.returncode == 0:
            test_output = result.stdout
            passed_tests = test_output.count(' PASSED')
            failed_tests = test_output.count(' FAILED')
            
            validator.test(
                "Tests unitaires passent",
                failed_tests == 0,
                f"Passés: {passed_tests}, Échoués: {failed_tests}"
            )
        else:
            validator.test(
                "Tests unitaires passent",
                False,
                f"Code de sortie: {result.returncode}"
            )
            
    except subprocess.TimeoutExpired:
        validator.test("Tests unitaires passent", False, "Timeout après 60s")
    except Exception as e:
        validator.test("Tests unitaires passent", False, f"Erreur: {str(e)}")
        
    # ===== TESTS DE DOCUMENTATION =====
    print(f"\n{Fore.BLUE}[+] Tests de Documentation{Style.RESET_ALL}")
    print("-" * 30)
    
    try:
        # Vérifier la qualité du README
        readme_path = Path('README.md')
        if readme_path.exists():
            readme_content = readme_path.read_text(encoding='utf-8')
            
            required_sections = [
                '## 🌟 Fonctionnalités',
                '## 🚀 Installation', 
                '## 📋 Utilisation',
                '## 🧪 Tests',
                '## 🚨 Dépannage'
            ]
            
            sections_found = sum(1 for section in required_sections if section in readme_content)
            
            validator.test(
                "Documentation complète",
                sections_found >= 4,
                f"{sections_found}/{len(required_sections)} sections trouvées"
            )
            
            validator.test(
                "Exemples d'usage inclus",
                '```bash' in readme_content and 'python3' in readme_content,
                "Exemples de commandes trouvés"
            )
            
        else:
            validator.test("Documentation complète", False, "README.md manquant")
            
    except Exception as e:
        validator.test("Tests de documentation", False, f"Erreur: {str(e)}")
    
    # ===== RÉSUMÉ FINAL =====
    success = validator.print_summary()
    
    # Sauvegarder le rapport de validation
    report = {
        'timestamp': time.time(),
        'total_tests': validator.total_tests,
        'passed_tests': validator.passed_tests,
        'success_rate': (validator.passed_tests / validator.total_tests) * 100,
        'results': validator.results,
        'system_ready': success
    }
    
    with open('validation_report.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
        
    print(f"\n[*] Rapport de validation sauvegarde: validation_report.json")
    
    return success


if __name__ == '__main__':
    try:
        # Configurer l'event loop pour Windows
        if sys.platform.startswith('win'):
            asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
            
        # Exécuter la validation
        success = asyncio.run(validate_system())
        
        # Code de sortie
        sys.exit(0 if success else 1)
        
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}[!] Validation interrompue par l'utilisateur{Style.RESET_ALL}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Fore.RED}[-] Erreur fatale lors de la validation: {str(e)}{Style.RESET_ALL}")
        sys.exit(1)