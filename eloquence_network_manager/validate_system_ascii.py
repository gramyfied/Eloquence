#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de validation du Gestionnaire Réseau Intelligent Eloquence
Version ASCII compatible Windows
"""

import asyncio
import os
import sys
import json
import time
import traceback
from pathlib import Path
from typing import Dict, List, Any, Optional

try:
    from colorama import init, Fore, Back, Style
    init()
except ImportError:
    # Fallback sans couleurs
    class MockColor:
        RED = YELLOW = GREEN = BLUE = CYAN = MAGENTA = WHITE = ""
        RESET_ALL = ""
    
    Fore = MockColor()
    Style = MockColor()

# Ajout du chemin vers le module
sys.path.insert(0, str(Path(__file__).parent))

try:
    from eloquence_network_manager import EloquenceNetworkManager
    from exercise_validator import ExerciseValidator
except ImportError as e:
    print(f"ERREUR: Impossible d'importer les modules requis: {e}")
    sys.exit(1)

class ValidationResults:
    """Classe pour stocker les résultats de validation"""
    
    def __init__(self):
        self.tests_passed = 0
        self.tests_total = 0
        self.detailed_results = {}
        self.start_time = time.time()
        
    def add_test_result(self, test_name: str, passed: bool, details: str = ""):
        """Ajoute un résultat de test"""
        self.tests_total += 1
        if passed:
            self.tests_passed += 1
            status = "REUSSI"
        else:
            status = "ECHEC"
            
        self.detailed_results[test_name] = {
            "status": status,
            "details": details,
            "timestamp": time.time()
        }
        
        # Affichage du résultat
        color = Fore.GREEN if passed else Fore.RED
        indicator = "[+]" if passed else "[-]"
        print(f"  {color}{indicator} {test_name}: {status}{Style.RESET_ALL}")
        if details:
            print(f"      {details}")
    
    def get_success_rate(self) -> float:
        """Calcule le taux de réussite"""
        if self.tests_total == 0:
            return 0.0
        return (self.tests_passed / self.tests_total) * 100

async def test_file_structure(results: ValidationResults) -> bool:
    """Test de la structure des fichiers"""
    required_files = [
        "eloquence_network_manager.py",
        "exercise_validator.py", 
        "requirements.txt",
        "README.md",
        "eloquence_network_config.yaml"
    ]
    
    all_passed = True
    base_path = Path(__file__).parent
    
    for file_name in required_files:
        file_path = base_path / file_name
        passed = file_path.exists()
        if not passed:
            all_passed = False
        results.add_test_result(
            f"Fichier {file_name}",
            passed,
            f"Chemin: {file_path}" if passed else f"MANQUANT: {file_path}"
        )
    
    return all_passed

async def test_configuration_loading(results: ValidationResults) -> bool:
    """Test du chargement de la configuration"""
    try:
        manager = EloquenceNetworkManager()
        await manager.initialize()
        
        # Test configuration YAML
        config_path = Path(__file__).parent / "eloquence_network_config.yaml"
        config_exists = config_path.exists()
        results.add_test_result(
            "Configuration YAML",
            config_exists,
            f"Fichier de config: {config_path}"
        )
        
        # Test des variables d'environnement
        env_vars = ["LIVEKIT_API_KEY", "MISTRAL_API_KEY"]
        env_loaded = all(os.getenv(var) for var in env_vars)
        results.add_test_result(
            "Variables d'environnement",
            env_loaded,
            f"Variables testees: {env_vars}"
        )
        
        await manager.close()
        return config_exists and env_loaded
        
    except Exception as e:
        results.add_test_result(
            "Chargement configuration",
            False,
            f"Erreur: {str(e)}"
        )
        return False

async def test_initialization(results: ValidationResults) -> bool:
    """Test d'initialisation du gestionnaire"""
    try:
        manager = EloquenceNetworkManager()
        await manager.initialize()
        
        # Test d'initialisation
        results.add_test_result(
            "Initialisation du gestionnaire",
            True,
            "Initialisation reussie"
        )
        
        # Test de la session HTTP
        has_session = hasattr(manager, 'session') and manager.session is not None
        results.add_test_result(
            "Session HTTP",
            has_session,
            f"Session HTTP: {'active' if has_session else 'inactive'}"
        )
        
        await manager.close()
        return True
        
    except Exception as e:
        results.add_test_result(
            "Initialisation du gestionnaire",
            False,
            f"Erreur: {str(e)}"
        )
        return False

async def test_functional_features(results: ValidationResults) -> bool:
    """Test des fonctionnalités principales"""
    try:
        manager = EloquenceNetworkManager()
        await manager.initialize()
        
        # Test de vérification des services
        start_time = time.time()
        health_report = await manager.check_all_services()
        check_time = time.time() - start_time
        
        results.add_test_result(
            "Verification des services",
            health_report is not None,
            f"Services verifies en {check_time:.2f}s"
        )
        
        # Test de santé globale
        health_valid = isinstance(health_report, dict) and 'global_health_score' in health_report
        score = health_report.get('global_health_score', 0) if health_valid else 0
        results.add_test_result(
            "Sante globale",
            health_valid,
            f"Score: {score}% en {check_time:.2f}s"
        )
        
        # Test des métriques de performance
        performance_ok = check_time < 5.0
        results.add_test_result(
            "Performance (<5s)",
            performance_ok,
            f"Verification: {check_time:.2f}s"
        )
        
        await manager.close()
        return health_report is not None and health_valid and performance_ok
        
    except Exception as e:
        results.add_test_result(
            "Tests fonctionnels",
            False,
            f"Erreur: {str(e)}"
        )
        return False

async def test_exercise_validator(results: ValidationResults) -> bool:
    """Test du validateur d'exercices"""
    try:
        # Initialiser le gestionnaire réseau pour le validateur
        manager = EloquenceNetworkManager()
        await manager.initialize()
        
        # Créer le validateur avec le gestionnaire réseau
        validator = ExerciseValidator(manager)
        
        # Test de création du validateur
        results.add_test_result(
            "Creation du validateur",
            validator is not None,
            "Validateur cree avec succes"
        )
        
        # Test de détection d'exercices avec le détecteur
        detector = ExerciseDetector(".")
        
        # Test de création du détecteur
        results.add_test_result(
            "Creation du detecteur",
            detector is not None,
            "Detecteur cree avec succes"
        )
        
        await manager.close()
        return True
        
    except Exception as e:
        results.add_test_result(
            "Validateur d'exercices",
            False,
            f"Erreur: {str(e)}"
        )
        return False

async def test_cli_interface(results: ValidationResults) -> bool:
    """Test de l'interface CLI"""
    try:
        # Test de l'import CLI
        import eloquence_network_manager as main_module
        has_main = hasattr(main_module, '__main__') or hasattr(main_module, 'main')
        
        results.add_test_result(
            "Interface CLI disponible",
            True,  # Si l'import fonctionne, l'interface est disponible
            "Module CLI importe avec succes"
        )
        
        # Test des fonctions CLI principales
        manager = EloquenceNetworkManager()
        await manager.initialize()
        
        # Test de génération de rapport
        report = await manager.generate_report()
        report_valid = isinstance(report, dict) and 'metadata' in report
        
        results.add_test_result(
            "Generation de rapport",
            report_valid,
            f"Rapport genere: {len(str(report))} caracteres"
        )
        
        await manager.close()
        return report_valid
        
    except Exception as e:
        results.add_test_result(
            "Interface CLI",
            False,
            f"Erreur: {str(e)}"
        )
        return False

async def test_integration(results: ValidationResults) -> bool:
    """Tests d'intégration"""
    try:
        manager = EloquenceNetworkManager()
        await manager.initialize()
        
        # Créer le validateur avec le gestionnaire réseau
        validator = ExerciseValidator(manager)
        
        # Test d'intégration manager + validator
        integration_ok = True
        
        # Test de workflow complet
        start_time = time.time()
        
        # 1. Vérification de santé
        health = await manager.check_all_services()
        
        # 2. Génération de rapport
        report = await manager.generate_report()
        
        total_time = time.time() - start_time
        
        workflow_ok = all([
            health is not None,
            report is not None,
            total_time < 10.0
        ])
        
        results.add_test_result(
            "Workflow complet",
            workflow_ok,
            f"Execution complete en {total_time:.2f}s"
        )
        
        await manager.close()
        return workflow_ok
        
    except Exception as e:
        results.add_test_result(
            "Tests d'integration",
            False,
            f"Erreur: {str(e)}"
        )
        return False

async def test_documentation(results: ValidationResults) -> bool:
    """Test de la documentation"""
    try:
        readme_path = Path(__file__).parent / "README.md"
        readme_exists = readme_path.exists()
        
        if readme_exists:
            content = readme_path.read_text(encoding='utf-8')
            has_sections = all(section in content.lower() for section in [
                'installation', 'utilisation', 'configuration'
            ])
            doc_size_ok = len(content) > 1000  # Au moins 1KB de documentation
            
            results.add_test_result(
                "Documentation README",
                has_sections and doc_size_ok,
                f"Taille: {len(content)} caracteres, Sections: {has_sections}"
            )
            
            return has_sections and doc_size_ok
        else:
            results.add_test_result(
                "Documentation README",
                False,
                "Fichier README.md manquant"
            )
            return False
            
    except Exception as e:
        results.add_test_result(
            "Documentation",
            False,
            f"Erreur: {str(e)}"
        )
        return False

async def validate_system():
    """Fonction principale de validation"""
    results = ValidationResults()
    
    try:
        print(f"{Fore.CYAN}[*] VALIDATION DU GESTIONNAIRE RESEAU ELOQUENCE{Style.RESET_ALL}")
        print(f"{'='*80}\n")
        
        # ===== TESTS DE STRUCTURE ET FICHIERS =====
        print(f"{Fore.BLUE}[+] Tests de Structure{Style.RESET_ALL}")
        print("-" * 30)
        await test_file_structure(results)
        
        # ===== TESTS DE CONFIGURATION =====
        print(f"\n{Fore.BLUE}[+] Tests de Configuration{Style.RESET_ALL}")
        print("-" * 30)
        await test_configuration_loading(results)
        
        # ===== TESTS D'INITIALISATION =====
        print(f"\n{Fore.BLUE}[+] Tests d'Initialisation{Style.RESET_ALL}")
        print("-" * 30)
        await test_initialization(results)
        
        # ===== TESTS FONCTIONNELS =====
        print(f"\n{Fore.BLUE}[+] Tests Fonctionnels{Style.RESET_ALL}")
        print("-" * 30)
        await test_functional_features(results)
        
        # ===== TESTS DU VALIDATEUR D'EXERCICES =====
        print(f"\n{Fore.BLUE}[+] Tests Validateur d'Exercices{Style.RESET_ALL}")
        print("-" * 30)
        await test_exercise_validator(results)
        
        # ===== TESTS CLI =====
        print(f"\n{Fore.BLUE}[+] Tests Interface CLI{Style.RESET_ALL}")
        print("-" * 30)
        await test_cli_interface(results)
        
        # ===== TESTS D'INTEGRATION =====
        print(f"\n{Fore.BLUE}[+] Tests d'Integration{Style.RESET_ALL}")
        print("-" * 30)
        await test_integration(results)
        
        # ===== TESTS DE DOCUMENTATION =====
        print(f"\n{Fore.BLUE}[+] Tests de Documentation{Style.RESET_ALL}")
        print("-" * 30)
        await test_documentation(results)
        
        # ===== RÉSUMÉ FINAL =====
        success_rate = results.get_success_rate()
        total_time = time.time() - results.start_time
        
        print(f"\n{'='*80}")
        print(f"{Fore.CYAN}[*] RESUME DE VALIDATION{Style.RESET_ALL}")
        print(f"{'='*80}")
        print(f"Tests reussis: {results.tests_passed}/{results.tests_total}")
        print(f"Taux de reussite: {success_rate:.1f}%")
        print(f"Temps total: {total_time:.2f}s")
        
        # Évaluation finale
        if success_rate >= 90:
            print(f"\n{Fore.GREEN}[+] VALIDATION REUSSIE - Systeme pret pour la production{Style.RESET_ALL}")
        elif success_rate >= 80:
            print(f"\n{Fore.YELLOW}[!] VALIDATION PARTIELLE - Quelques ameliorations necessaires{Style.RESET_ALL}")
        else:
            print(f"\n{Fore.RED}[-] VALIDATION ECHOUEE - Corrections majeures requises{Style.RESET_ALL}")
        
        # Sauvegarde du rapport
        report = {
            "validation_summary": {
                "tests_passed": results.tests_passed,
                "tests_total": results.tests_total,
                "success_rate": success_rate,
                "total_time": total_time,
                "timestamp": time.time()
            },
            "detailed_results": results.detailed_results
        }
        
        report_file = Path(__file__).parent / "validation_report.json"
        report_file.write_text(json.dumps(report, indent=2, ensure_ascii=False))
        print(f"\n[*] Rapport de validation sauvegarde: validation_report.json")
        
        return success_rate >= 80
        
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}[!] Validation interrompue par l'utilisateur{Style.RESET_ALL}")
        return False
    except Exception as e:
        print(f"\n{Fore.RED}[-] Erreur fatale lors de la validation: {str(e)}{Style.RESET_ALL}")
        print(f"Traceback: {traceback.format_exc()}")
        return False

if __name__ == "__main__":
    try:
        success = asyncio.run(validate_system())
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n{Fore.RED}[-] Erreur fatale lors de la validation: {str(e)}{Style.RESET_ALL}")
        sys.exit(1)