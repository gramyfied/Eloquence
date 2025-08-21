#!/usr/bin/env python3
"""
VALIDATION FINALE - SYSTÈME D'INTERPELLATION INTELLIGENTE
Confirme que Sarah et Marcus répondent systématiquement quand interpellés
"""
import asyncio
import logging
import json
from datetime import datetime

# Configuration des logs
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Imports du système
try:
    from interpellation_system import AdvancedInterpellationDetector, InterpellationResponseManager
    from enhanced_multi_agent_manager import EnhancedMultiAgentManager
    from multi_agent_config import MultiAgentConfig
    from multi_agent_main import MultiAgentService
    IMPORTS_SUCCESS = True
except ImportError as e:
    logger.error(f"❌ Erreur import: {e}")
    IMPORTS_SUCCESS = False

class ValidationFinaleInterpellation:
    """Validateur final du système d'interpellation"""
    
    def __init__(self):
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "tests": [],
            "summary": {
                "total_tests": 0,
                "passed": 0,
                "failed": 0,
                "success_rate": 0.0
            }
        }
    
    def add_test_result(self, test_name: str, passed: bool, details: str = ""):
        """Ajoute un résultat de test"""
        test_result = {
            "name": test_name,
            "passed": passed,
            "details": details,
            "timestamp": datetime.now().isoformat()
        }
        self.results["tests"].append(test_result)
        
        if passed:
            self.results["summary"]["passed"] += 1
        else:
            self.results["summary"]["failed"] += 1
        
        self.results["summary"]["total_tests"] += 1
        self.results["summary"]["success_rate"] = (
            self.results["summary"]["passed"] / self.results["summary"]["total_tests"] * 100
        )
    
    async def test_detection_avancee(self):
        """Test de détection avancée d'interpellations"""
        print("🔍 TEST: Détection avancée d'interpellations")
        
        detector = AdvancedInterpellationDetector()
        
        # Cas de test complexes
        test_cases = [
            {
                "message": "Sarah, vos investigations sur l'IA révèlent quoi exactement ?",
                "expected": "sarah_johnson_journaliste",
                "type": "direct"
            },
            {
                "message": "Marcus, votre expertise technique sur ce sujet ?",
                "expected": "marcus_thompson_expert", 
                "type": "direct"
            },
            {
                "message": "Qu'en pense notre journaliste sur cette affaire ?",
                "expected": "sarah_johnson_journaliste",
                "type": "indirect"
            },
            {
                "message": "L'avis de notre expert sur cette question ?",
                "expected": "marcus_thompson_expert",
                "type": "indirect"
            },
            {
                "message": "C'est un sujet passionnant qui mérite réflexion.",
                "expected": None,
                "type": None
            }
        ]
        
        all_passed = True
        
        for i, test_case in enumerate(test_cases, 1):
            detections = detector.detect_interpellations(
                test_case["message"], "michel_dubois_animateur", []
            )
            
            if test_case["expected"] is None:
                if len(detections) == 0:
                    print(f"  ✅ {i}. Pas d'interpellation détectée (correct)")
                else:
                    print(f"  ❌ {i}. Interpellation détectée à tort")
                    all_passed = False
            else:
                if len(detections) > 0:
                    detection = detections[0]
                    if detection.agent_id == test_case["expected"]:
                        print(f"  ✅ {i}. {detection.agent_id} détecté ({detection.interpellation_type})")
                    else:
                        print(f"  ❌ {i}. {detection.agent_id} au lieu de {test_case['expected']}")
                        all_passed = False
                else:
                    print(f"  ❌ {i}. Aucune interpellation détectée pour {test_case['expected']}")
                    all_passed = False
        
        self.add_test_result("Détection avancée", all_passed)
        return all_passed
    
    async def test_reponses_garanties(self):
        """Test que les réponses sont garanties"""
        print("\n🎯 TEST: Réponses garanties aux interpellations")
        
        # Configuration
        config = MultiAgentConfig(
            exercise_id="validation_finale",
            room_prefix="test",
            agents=[],
            interaction_rules={},
            turn_management="moderator_controlled"
        )
        
        # Manager avec interpellation
        manager = EnhancedMultiAgentManager("fake_key", "fake_key", config)
        
        # Test des réponses
        test_messages = [
            "Sarah, que pensez-vous ?",
            "Marcus, votre avis ?",
            "Sarah, vos investigations ?",
            "Marcus, votre expertise ?"
        ]
        
        all_passed = True
        
        for i, message in enumerate(test_messages, 1):
            try:
                responses = await manager.process_user_message_with_interpellations(
                    message, "michel_dubois_animateur", []
                )
                
                if len(responses) > 0:
                    response = responses[0]
                    print(f"  ✅ {i}. {response['agent_name']} a répondu ({response['response_type']})")
                    
                    # Vérification que la réponse reconnaît l'interpellation
                    response_text = response['message'].lower()
                    recognition_indicators = ["oui", "effectivement", "absolument", "excellente question"]
                    has_recognition = any(indicator in response_text for indicator in recognition_indicators)
                    
                    if has_recognition:
                        print(f"     ✅ Reconnaissance de l'interpellation")
                    else:
                        print(f"     ⚠️ Pas de reconnaissance claire")
                        all_passed = False
                else:
                    print(f"  ❌ {i}. Aucune réponse générée")
                    all_passed = False
                    
            except Exception as e:
                print(f"  ❌ {i}. Erreur: {e}")
                all_passed = False
        
        self.add_test_result("Réponses garanties", all_passed)
        return all_passed
    
    async def test_integration_complete(self):
        """Test d'intégration complète"""
        print("\n🔗 TEST: Intégration complète du système")
        
        try:
            # Test du service principal
            service = MultiAgentService()
            
            # Test de génération de réponse
            test_message = "Sarah, que pensez-vous de l'intelligence artificielle ?"
            
            response = await service.generate_multiagent_response(test_message)
            
            if response and "Sarah" in response:
                print("  ✅ Service principal fonctionne")
                print(f"  ✅ Réponse: {response[:100]}...")
                self.add_test_result("Intégration service principal", True)
                return True
            else:
                print("  ❌ Service principal ne fonctionne pas correctement")
                self.add_test_result("Intégration service principal", False)
                return False
                
        except Exception as e:
            print(f"  ❌ Erreur intégration: {e}")
            self.add_test_result("Intégration service principal", False)
            return False
    
    async def test_performance(self):
        """Test de performance du système"""
        print("\n⚡ TEST: Performance du système")
        
        detector = AdvancedInterpellationDetector()
        
        import time
        
        # Test de vitesse de détection
        start_time = time.time()
        
        for _ in range(100):
            detector.detect_interpellations(
                "Sarah, que pensez-vous de cette situation ?",
                "michel_dubois_animateur",
                []
            )
        
        end_time = time.time()
        detection_time = end_time - start_time
        
        print(f"  ✅ 100 détections en {detection_time:.3f}s")
        print(f"  ✅ {100/detection_time:.1f} détections/seconde")
        
        # Seuil de performance
        if detection_time < 1.0:  # Moins d'1 seconde pour 100 détections
            self.add_test_result("Performance détection", True, f"{detection_time:.3f}s")
            return True
        else:
            self.add_test_result("Performance détection", False, f"{detection_time:.3f}s")
            return False
    
    def generate_report(self):
        """Génère le rapport de validation"""
        print("\n📊 RAPPORT DE VALIDATION FINALE")
        print("=" * 50)
        
        summary = self.results["summary"]
        print(f"Tests totaux: {summary['total_tests']}")
        print(f"Tests réussis: {summary['passed']}")
        print(f"Tests échoués: {summary['failed']}")
        print(f"Taux de succès: {summary['success_rate']:.1f}%")
        
        print("\n📋 Détail des tests:")
        for test in self.results["tests"]:
            status = "✅" if test["passed"] else "❌"
            print(f"  {status} {test['name']}: {test['details']}")
        
        # Sauvegarde du rapport
        with open("validation_interpellation_finale.json", "w", encoding="utf-8") as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Rapport sauvegardé: validation_interpellation_finale.json")
        
        return summary["success_rate"] >= 90.0  # 90% de succès minimum
    
    async def run_validation_complete(self):
        """Exécute la validation complète"""
        print("🎯 VALIDATION FINALE - SYSTÈME D'INTERPELLATION INTELLIGENTE")
        print("=" * 70)
        
        if not IMPORTS_SUCCESS:
            print("❌ Impossible de continuer - imports échoués")
            return False
        
        try:
            # Tests principaux
            await self.test_detection_avancee()
            await self.test_reponses_garanties()
            await self.test_integration_complete()
            await self.test_performance()
            
            # Génération du rapport
            success = self.generate_report()
            
            if success:
                print("\n🎉 VALIDATION FINALE RÉUSSIE !")
                print("✅ Le système d'interpellation est parfaitement fonctionnel")
                print("✅ Sarah et Marcus répondront systématiquement quand interpellés")
                print("✅ Les débats TV seront parfaitement orchestrés")
                print("✅ ELOQUENCE est prêt pour des débats professionnels !")
            else:
                print("\n⚠️ VALIDATION FINALE AVEC RÉSERVES")
                print("Certains tests ont échoué - vérification recommandée")
            
            return success
            
        except Exception as e:
            print(f"\n❌ ERREUR LORS DE LA VALIDATION: {e}")
            import traceback
            traceback.print_exc()
            return False

async def main():
    """Point d'entrée principal"""
    validator = ValidationFinaleInterpellation()
    success = await validator.run_validation_complete()
    
    if success:
        print("\n🚀 SYSTÈME D'INTERPELLATION VALIDÉ - PRÊT POUR LA PRODUCTION !")
    else:
        print("\n🔧 CORRECTIONS NÉCESSAIRES AVANT PRODUCTION")

if __name__ == "__main__":
    asyncio.run(main())
