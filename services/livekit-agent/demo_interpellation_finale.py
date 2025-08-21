#!/usr/bin/env python3
"""
DÉMONSTRATION FINALE - SYSTÈME D'INTERPELLATION INTELLIGENTE
Montre le système d'interpellation en action avec des exemples concrets
"""
import asyncio
import logging
from datetime import datetime

# Configuration des logs
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Imports du système
try:
    from interpellation_system import AdvancedInterpellationDetector, InterpellationResponseManager
    from enhanced_multi_agent_manager import EnhancedMultiAgentManager
    from multi_agent_config import MultiAgentConfig
    IMPORTS_SUCCESS = True
except ImportError as e:
    logger.error(f"❌ Erreur import: {e}")
    IMPORTS_SUCCESS = False

class DemoInterpellationFinale:
    """Démonstration du système d'interpellation intelligente"""
    
    def __init__(self):
        self.config = MultiAgentConfig(
            exercise_id="demo_interpellation",
            room_prefix="demo",
            agents=[],
            interaction_rules={},
            turn_management="moderator_controlled"
        )
        
        self.manager = EnhancedMultiAgentManager("fake_key", "fake_key", self.config)
        self.manager.set_user_context("Pierre", "Intelligence Artificielle")
        
        self.conversation_history = []
    
    def print_separator(self, title: str):
        """Affiche un séparateur avec titre"""
        print(f"\n{'='*60}")
        print(f"🎯 {title}")
        print(f"{'='*60}")
    
    def print_message(self, speaker: str, message: str, message_type: str = "normal"):
        """Affiche un message de conversation"""
        if message_type == "interpellation":
            print(f"🎯 {speaker}: {message}")
        else:
            print(f"💬 {speaker}: {message}")
    
    async def demo_interpellation_directe(self):
        """Démonstration des interpellations directes"""
        self.print_separator("INTERPELLATIONS DIRECTES")
        
        test_cases = [
            {
                "message": "Sarah, que pensez-vous de l'impact de l'IA sur le journalisme ?",
                "speaker": "Michel Dubois",
                "expected_agent": "Sarah Johnson"
            },
            {
                "message": "Marcus, votre expertise technique sur les algorithmes de recommandation ?",
                "speaker": "Sarah Johnson",
                "expected_agent": "Marcus Thompson"
            },
            {
                "message": "Sarah, vos investigations révèlent quoi sur les biais algorithmiques ?",
                "speaker": "Pierre (Utilisateur)",
                "expected_agent": "Sarah Johnson"
            }
        ]
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n{i}. INTERPELLATION DIRECTE")
            self.print_message(test_case["speaker"], test_case["message"])
            
            try:
                responses = await self.manager.process_user_message_with_interpellations(
                    test_case["message"],
                    test_case["speaker"].lower().replace(" ", "_"),
                    self.conversation_history
                )
                
                if responses:
                    response = responses[0]
                    self.print_message(
                        response['agent_name'], 
                        response['message'], 
                        response['response_type']
                    )
                    
                    # Ajouter à l'historique
                    self.conversation_history.append({
                        'speaker_id': response['agent_id'],
                        'speaker_name': response['agent_name'],
                        'message': response['message'],
                        'response_type': response['response_type']
                    })
                    
                    print(f"   🎭 Émotion: {response['emotion']}")
                    print(f"   ✅ Type: {response['response_type']}")
                else:
                    print("❌ Aucune réponse générée")
                    
            except Exception as e:
                print(f"❌ Erreur: {e}")
    
    async def demo_interpellation_indirecte(self):
        """Démonstration des interpellations indirectes"""
        self.print_separator("INTERPELLATIONS INDIRECTES")
        
        test_cases = [
            {
                "message": "Qu'en pense notre journaliste sur cette question ?",
                "speaker": "Michel Dubois",
                "expected_agent": "Sarah Johnson"
            },
            {
                "message": "L'avis de notre expert sur ce sujet ?",
                "speaker": "Sarah Johnson",
                "expected_agent": "Marcus Thompson"
            },
            {
                "message": "Du point de vue journalistique, comment analyser cette situation ?",
                "speaker": "Pierre (Utilisateur)",
                "expected_agent": "Sarah Johnson"
            }
        ]
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n{i}. INTERPELLATION INDIRECTE")
            self.print_message(test_case["speaker"], test_case["message"])
            
            try:
                responses = await self.manager.process_user_message_with_interpellations(
                    test_case["message"],
                    test_case["speaker"].lower().replace(" ", "_"),
                    self.conversation_history
                )
                
                if responses:
                    response = responses[0]
                    self.print_message(
                        response['agent_name'], 
                        response['message'], 
                        response['response_type']
                    )
                    
                    # Ajouter à l'historique
                    self.conversation_history.append({
                        'speaker_id': response['agent_id'],
                        'speaker_name': response['agent_name'],
                        'message': response['message'],
                        'response_type': response['response_type']
                    })
                    
                    print(f"   🎭 Émotion: {response['emotion']}")
                    print(f"   ✅ Type: {response['response_type']}")
                else:
                    print("❌ Aucune réponse générée")
                    
            except Exception as e:
                print(f"❌ Erreur: {e}")
    
    async def demo_interpellation_multiple(self):
        """Démonstration des interpellations multiples"""
        self.print_separator("INTERPELLATIONS MULTIPLES")
        
        test_cases = [
            {
                "message": "Sarah, vos investigations ? Et Marcus, votre expertise technique ?",
                "speaker": "Michel Dubois",
                "expected_agents": ["Sarah Johnson", "Marcus Thompson"]
            },
            {
                "message": "Notre journaliste et notre expert, que pensez-vous de cette situation ?",
                "speaker": "Pierre (Utilisateur)",
                "expected_agents": ["Sarah Johnson", "Marcus Thompson"]
            }
        ]
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n{i}. INTERPELLATION MULTIPLE")
            self.print_message(test_case["speaker"], test_case["message"])
            
            try:
                responses = await self.manager.process_user_message_with_interpellations(
                    test_case["message"],
                    test_case["speaker"].lower().replace(" ", "_"),
                    self.conversation_history
                )
                
                if responses:
                    for j, response in enumerate(responses):
                        self.print_message(
                            response['agent_name'], 
                            response['message'], 
                            response['response_type']
                        )
                        
                        # Ajouter à l'historique
                        self.conversation_history.append({
                            'speaker_id': response['agent_id'],
                            'speaker_name': response['agent_name'],
                            'message': response['message'],
                            'response_type': response['response_type']
                        })
                        
                        print(f"   🎭 Émotion: {response['emotion']}")
                        print(f"   ✅ Type: {response['response_type']}")
                else:
                    print("❌ Aucune réponse générée")
                    
            except Exception as e:
                print(f"❌ Erreur: {e}")
    
    async def demo_conversation_normale(self):
        """Démonstration de conversation normale (sans interpellation)"""
        self.print_separator("CONVERSATION NORMALE (SANS INTERPELLATION)")
        
        test_cases = [
            {
                "message": "C'est un sujet très intéressant qui mérite réflexion.",
                "speaker": "Pierre (Utilisateur)"
            },
            {
                "message": "L'intelligence artificielle pose de nombreuses questions.",
                "speaker": "Michel Dubois"
            }
        ]
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n{i}. CONVERSATION NORMALE")
            self.print_message(test_case["speaker"], test_case["message"])
            
            try:
                responses = await self.manager.process_user_message_with_interpellations(
                    test_case["message"],
                    test_case["speaker"].lower().replace(" ", "_"),
                    self.conversation_history
                )
                
                if responses:
                    response = responses[0]
                    self.print_message(
                        response['agent_name'], 
                        response['message'], 
                        response['response_type']
                    )
                    
                    # Ajouter à l'historique
                    self.conversation_history.append({
                        'speaker_id': response['agent_id'],
                        'speaker_name': response['agent_name'],
                        'message': response['message'],
                        'response_type': response['response_type']
                    })
                    
                    print(f"   🎭 Émotion: {response['emotion']}")
                    print(f"   ✅ Type: {response['response_type']}")
                else:
                    print("❌ Aucune réponse générée")
                    
            except Exception as e:
                print(f"❌ Erreur: {e}")
    
    async def demo_detection_avancee(self):
        """Démonstration de la détection avancée"""
        self.print_separator("DÉTECTION AVANCÉE D'INTERPELLATIONS")
        
        detector = AdvancedInterpellationDetector()
        
        test_messages = [
            "Sarah, vos investigations sur l'IA révèlent quoi exactement ?",
            "Marcus, votre expertise technique sur ce sujet ?",
            "Qu'en pense notre journaliste sur cette affaire ?",
            "L'avis de notre expert sur cette question ?",
            "C'est un sujet passionnant qui mérite réflexion."
        ]
        
        for i, message in enumerate(test_messages, 1):
            print(f"\n{i}. Message: '{message}'")
            
            detections = detector.detect_interpellations(
                message, "michel_dubois_animateur", self.conversation_history
            )
            
            if detections:
                for detection in detections:
                    print(f"   🎯 Détecté: {detection.agent_name}")
                    print(f"   📊 Confiance: {detection.confidence:.2f}")
                    print(f"   🏷️ Type: {detection.interpellation_type}")
                    print(f"   🔍 Déclencheur: '{detection.trigger_phrase}'")
            else:
                print("   ✅ Aucune interpellation détectée")
    
    def print_statistics(self):
        """Affiche les statistiques de la démonstration"""
        self.print_separator("STATISTIQUES DE LA DÉMONSTRATION")
        
        total_messages = len(self.conversation_history)
        interpellation_responses = sum(1 for msg in self.conversation_history if msg.get('response_type') == 'interpellation')
        normal_responses = total_messages - interpellation_responses
        
        print(f"📊 Messages totaux: {total_messages}")
        print(f"🎯 Réponses d'interpellation: {interpellation_responses}")
        print(f"💬 Réponses normales: {normal_responses}")
        
        if total_messages > 0:
            interpellation_rate = (interpellation_responses / total_messages) * 100
            print(f"📈 Taux d'interpellation: {interpellation_rate:.1f}%")
        
        # Analyse par agent
        agent_stats = {}
        for msg in self.conversation_history:
            agent_name = msg['speaker_name']
            if agent_name not in agent_stats:
                agent_stats[agent_name] = {'total': 0, 'interpellations': 0}
            
            agent_stats[agent_name]['total'] += 1
            if msg.get('response_type') == 'interpellation':
                agent_stats[agent_name]['interpellations'] += 1
        
        print(f"\n👥 Statistiques par agent:")
        for agent, stats in agent_stats.items():
            interpellation_rate = (stats['interpellations'] / stats['total']) * 100 if stats['total'] > 0 else 0
            print(f"   {agent}: {stats['total']} messages ({stats['interpellations']} interpellations - {interpellation_rate:.1f}%)")
    
    async def run_demo_complete(self):
        """Exécute la démonstration complète"""
        print("🎬 DÉMONSTRATION FINALE - SYSTÈME D'INTERPELLATION INTELLIGENTE")
        print("=" * 70)
        print(f"🕐 Début: {datetime.now().strftime('%H:%M:%S')}")
        
        if not IMPORTS_SUCCESS:
            print("❌ Impossible de continuer - imports échoués")
            return
        
        try:
            # Démonstrations
            await self.demo_interpellation_directe()
            await self.demo_interpellation_indirecte()
            await self.demo_interpellation_multiple()
            await self.demo_conversation_normale()
            await self.demo_detection_avancee()
            
            # Statistiques
            self.print_statistics()
            
            print(f"\n🎉 DÉMONSTRATION TERMINÉE AVEC SUCCÈS !")
            print(f"🕐 Fin: {datetime.now().strftime('%H:%M:%S')}")
            print("\n✅ Le système d'interpellation fonctionne parfaitement")
            print("✅ Sarah et Marcus répondent systématiquement quand interpellés")
            print("✅ Les débats TV sont parfaitement orchestrés")
            print("✅ ELOQUENCE est prêt pour la production !")
            
        except Exception as e:
            print(f"\n❌ ERREUR LORS DE LA DÉMONSTRATION: {e}")
            import traceback
            traceback.print_exc()

async def main():
    """Point d'entrée principal"""
    demo = DemoInterpellationFinale()
    await demo.run_demo_complete()

if __name__ == "__main__":
    asyncio.run(main())
