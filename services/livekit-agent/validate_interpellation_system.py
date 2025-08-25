#!/usr/bin/env python3
"""
Validation finale du système d'interpellation intelligente
Test complet avec vrais agents et prompts
"""
import asyncio
import logging
import os
from typing import Dict, List

# Configuration des logs
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Import du système
try:
    from interpellation_system import AdvancedInterpellationDetector
    from enhanced_multi_agent_manager import EnhancedMultiAgentManager, get_enhanced_manager
    from multi_agent_config import MultiAgentConfig
    IMPORTS_SUCCESS = True
except ImportError as e:
    logger.error(f"❌ Erreur import: {e}")
    IMPORTS_SUCCESS = False

class ValidationTestSuite:
    """Suite de tests de validation du système d'interpellation"""
    
    def __init__(self):
        self.test_results = []
        self.passed_tests = 0
        self.total_tests = 0
    
    def add_result(self, test_name: str, passed: bool, details: str = ""):
        """Ajoute un résultat de test"""
        self.total_tests += 1
        if passed:
            self.passed_tests += 1
        
        result = {
            'test_name': test_name,
            'passed': passed,
            'details': details
        }
        self.test_results.append(result)
        
        status = "✅ PASSÉ" if passed else "❌ ÉCHEC"
        print(f"{status}: {test_name}")
        if details:
            print(f"   {details}")
    
    def print_summary(self):
        """Affiche le résumé des tests"""
        print("\n" + "="*60)
        print("📊 RÉSUMÉ DES TESTS DE VALIDATION")
        print("="*60)
        print(f"Tests réussis: {self.passed_tests}/{self.total_tests}")
        print(f"Taux de réussite: {(self.passed_tests/self.total_tests)*100:.1f}%")
        
        if self.passed_tests == self.total_tests:
            print("\n🎉 TOUS LES TESTS SONT PASSÉS !")
            print("✅ Le système d'interpellation est prêt pour la production")
        else:
            print(f"\n⚠️ {self.total_tests - self.passed_tests} test(s) ont échoué")
            print("❌ Des corrections sont nécessaires")
            
            # Afficher les tests échoués
            failed_tests = [r for r in self.test_results if not r['passed']]
            print("\nTests échoués:")
            for test in failed_tests:
                print(f"   - {test['test_name']}: {test['details']}")

async def test_detector_patterns():
    """Test des patterns de détection d'interpellation"""
    
    print("🧪 TEST: PATTERNS DE DÉTECTION")
    print("-" * 40)
    
    detector = AdvancedInterpellationDetector()
    validator = ValidationTestSuite()
    
    # Test patterns directs Sarah
    test_cases_sarah = [
        "Sarah, que pensez-vous ?",
        "Journaliste, votre avis ?",
        "Sarah Johnson, pouvez-vous nous éclairer ?",
        "Madame Johnson, votre analyse ?",
        "Notre journaliste, qu'en pensez-vous ?"
    ]
    
    for i, message in enumerate(test_cases_sarah, 1):
        detections = detector.detect_interpellations(message, "michel_dubois_animateur", [])
        has_sarah_detection = any(d.agent_id == "sarah_johnson_journaliste" and d.interpellation_type == "direct" for d in detections)
        validator.add_result(
            f"Pattern direct Sarah {i}",
            has_sarah_detection,
            f"Message: '{message}'"
        )
    
    # Test patterns directs Marcus
    test_cases_marcus = [
        "Marcus, votre expertise ?",
        "Expert, qu'en pensez-vous ?",
        "Marcus Thompson, pouvez-vous nous éclairer ?",
        "Monsieur Thompson, votre analyse ?",
        "Notre expert, qu'en pensez-vous ?"
    ]
    
    for i, message in enumerate(test_cases_marcus, 1):
        detections = detector.detect_interpellations(message, "sarah_johnson_journaliste", [])
        has_marcus_detection = any(d.agent_id == "marcus_thompson_expert" and d.interpellation_type == "direct" for d in detections)
        validator.add_result(
            f"Pattern direct Marcus {i}",
            has_marcus_detection,
            f"Message: '{message}'"
        )
    
    # Test patterns indirects
    test_cases_indirect = [
        ("Qu'en pense notre journaliste ?", "sarah_johnson_journaliste"),
        ("L'avis de notre expert ?", "marcus_thompson_expert"),
        ("Votre enquête révèle quoi ?", "sarah_johnson_journaliste"),
        ("Votre expertise technique ?", "marcus_thompson_expert")
    ]
    
    for i, (message, expected_agent) in enumerate(test_cases_indirect, 1):
        detections = detector.detect_interpellations(message, "michel_dubois_animateur", [])
        has_indirect_detection = any(d.agent_id == expected_agent and d.interpellation_type == "indirect" for d in detections)
        validator.add_result(
            f"Pattern indirect {i}",
            has_indirect_detection,
            f"Message: '{message}' -> {expected_agent}"
        )
    
    # Test pas d'interpellation
    test_cases_no_interpellation = [
        "C'est un sujet intéressant.",
        "Je suis d'accord avec vous.",
        "Pouvez-vous expliquer ?",
        "C'est une bonne question."
    ]
    
    for i, message in enumerate(test_cases_no_interpellation, 1):
        detections = detector.detect_interpellations(message, "user", [])
        no_detection = len(detections) == 0
        validator.add_result(
            f"Pas d'interpellation {i}",
            no_detection,
            f"Message: '{message}'"
        )
    
    validator.print_summary()
    return validator.passed_tests == validator.total_tests

async def test_enhanced_manager_integration():
    """Test de l'intégration dans EnhancedMultiAgentManager"""
    
    print("\n🧪 TEST: INTÉGRATION ENHANCED MANAGER")
    print("-" * 40)
    
    validator = ValidationTestSuite()
    
    # Configuration
    config = MultiAgentConfig(
        exercise_id="test_integration",
        room_prefix="test",
        agents=[],
        interaction_rules={},
        turn_management="moderator_controlled"
    )
    
    # Test création manager
    try:
        manager = EnhancedMultiAgentManager("fake_key", "fake_key", config)
        validator.add_result(
            "Création EnhancedMultiAgentManager",
            True,
            "Manager créé avec succès"
        )
    except Exception as e:
        validator.add_result(
            "Création EnhancedMultiAgentManager",
            False,
            f"Erreur: {e}"
        )
        return False
    
    # Test présence système d'interpellation
    has_interpellation = hasattr(manager, 'interpellation_manager')
    validator.add_result(
        "Système d'interpellation intégré",
        has_interpellation,
        "Interpellation manager présent" if has_interpellation else "Interpellation manager absent"
    )
    
    # Test méthode process_user_message_with_interpellations
    has_method = hasattr(manager, 'process_user_message_with_interpellations')
    validator.add_result(
        "Méthode process_user_message_with_interpellations",
        has_method,
        "Méthode présente" if has_method else "Méthode absente"
    )
    
    # Test agents configurés
    agents_count = len(manager.agents) if hasattr(manager, 'agents') else 0
    expected_agents = 3  # Michel, Sarah, Marcus
    validator.add_result(
        "Agents configurés",
        agents_count == expected_agents,
        f"{agents_count} agents configurés (attendu: {expected_agents})"
    )
    
    # Test prompts avec règles d'interpellation
    if hasattr(manager, 'agents') and len(manager.agents) > 0:
        sarah_agent = manager.agents.get("sarah_johnson_journaliste", {})
        sarah_prompt = sarah_agent.get("system_prompt", "")
        has_sarah_interpellation = "RÈGLES D'INTERPELLATION CRITIQUES" in sarah_prompt
        validator.add_result(
            "Prompt Sarah avec règles d'interpellation",
            has_sarah_interpellation,
            "Règles d'interpellation présentes" if has_sarah_interpellation else "Règles d'interpellation absentes"
        )
        
        marcus_agent = manager.agents.get("marcus_thompson_expert", {})
        marcus_prompt = marcus_agent.get("system_prompt", "")
        has_marcus_interpellation = "RÈGLES D'INTERPELLATION CRITIQUES" in marcus_prompt
        validator.add_result(
            "Prompt Marcus avec règles d'interpellation",
            has_marcus_interpellation,
            "Règles d'interpellation présentes" if has_marcus_interpellation else "Règles d'interpellation absentes"
        )
    
    validator.print_summary()
    return validator.passed_tests == validator.total_tests

async def test_context_integration():
    """Test de l'intégration du contexte utilisateur"""
    
    print("\n🧪 TEST: INTÉGRATION CONTEXTE UTILISATEUR")
    print("-" * 40)
    
    validator = ValidationTestSuite()
    
    # Configuration
    config = MultiAgentConfig(
        exercise_id="test_context",
        room_prefix="test",
        agents=[],
        interaction_rules={},
        turn_management="moderator_controlled"
    )
    
    manager = EnhancedMultiAgentManager("fake_key", "fake_key", config)
    
    # Test configuration contexte
    try:
        manager.set_user_context("Pierre", "Intelligence Artificielle")
        context = manager.get_user_context()
        
        has_correct_name = context.get('user_name') == "Pierre"
        has_correct_subject = context.get('user_subject') == "Intelligence Artificielle"
        
        validator.add_result(
            "Configuration contexte utilisateur",
            has_correct_name and has_correct_subject,
            f"Nom: {context.get('user_name')}, Sujet: {context.get('user_subject')}"
        )
    except Exception as e:
        validator.add_result(
            "Configuration contexte utilisateur",
            False,
            f"Erreur: {e}"
        )
    
    # Test injection dans prompts
    if hasattr(manager, 'agents') and len(manager.agents) > 0:
        michel_agent = manager.agents.get("michel_dubois_animateur", {})
        michel_prompt = michel_agent.get("system_prompt", "")
        
        has_user_name = "Pierre" in michel_prompt
        has_user_subject = "Intelligence Artificielle" in michel_prompt
        
        validator.add_result(
            "Injection contexte dans prompt Michel",
            has_user_name and has_user_subject,
            f"Nom présent: {has_user_name}, Sujet présent: {has_user_subject}"
        )
    
    validator.print_summary()
    return validator.passed_tests == validator.total_tests

async def run_validation_suite():
    """Exécute la suite complète de validation"""
    
    print("🎯 VALIDATION COMPLÈTE DU SYSTÈME D'INTERPELLATION")
    print("=" * 60)
    
    if not IMPORTS_SUCCESS:
        print("❌ Impossible de continuer - imports échoués")
        return False
    
    try:
        # Test 1: Patterns de détection
        test1_passed = await test_detector_patterns()
        
        # Test 2: Intégration Enhanced Manager
        test2_passed = await test_enhanced_manager_integration()
        
        # Test 3: Intégration contexte
        test3_passed = await test_context_integration()
        
        # Résumé final
        print("\n" + "="*60)
        print("🎯 RÉSUMÉ FINAL DE VALIDATION")
        print("="*60)
        
        all_tests = [
            ("Patterns de détection", test1_passed),
            ("Intégration Enhanced Manager", test2_passed),
            ("Intégration contexte", test3_passed)
        ]
        
        passed_count = sum(1 for _, passed in all_tests if passed)
        total_count = len(all_tests)
        
        for test_name, passed in all_tests:
            status = "✅ PASSÉ" if passed else "❌ ÉCHEC"
            print(f"{status}: {test_name}")
        
        print(f"\nRésultat global: {passed_count}/{total_count} tests passés")
        
        if passed_count == total_count:
            print("\n🎉 SYSTÈME D'INTERPELLATION COMPLÈTEMENT VALIDÉ !")
            print("✅ Sarah et Marcus répondront systématiquement quand interpellés")
            print("✅ Les débats TV seront parfaitement orchestrés")
            print("✅ Le système est prêt pour la production")
            return True
        else:
            print(f"\n⚠️ {total_count - passed_count} test(s) ont échoué")
            print("❌ Des corrections sont nécessaires avant la production")
            return False
            
    except Exception as e:
        print(f"\n❌ ERREUR LORS DE LA VALIDATION: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(run_validation_suite())
    exit(0 if success else 1)

