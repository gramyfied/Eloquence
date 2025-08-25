#!/usr/bin/env python3
"""
Test de validation rapide pour Enhanced Multi-Agent Manager
"""

from enhanced_multi_agent_manager import get_enhanced_manager
from multi_agent_config import MultiAgentConfig

def main():
    print("🚀 VALIDATION RAPIDE ENHANCED MULTI-AGENT MANAGER")
    print("=" * 50)
    
    try:
        # Configuration test
        config = MultiAgentConfig(
            exercise_id="studio_debate_tv",
            room_prefix="studio_debatPlateau",
            agents=[],
            interaction_rules={},
            turn_management="moderator_controlled"
        )
        
        # Test création manager
        manager = get_enhanced_manager("test_key", "test_key", config)
        print("✅ Enhanced Manager créé avec succès")
        
        # Test agents français
        for agent_id, agent in manager.agents.items():
            system_prompt = agent["system_prompt"]
            
            # Vérifications obligatoires
            assert "FRANÇAIS" in system_prompt or "français" in system_prompt
            assert "generate response" not in system_prompt.lower()
            assert "INTERDICTION TOTALE" in system_prompt
            assert "pas un assistant IA" in system_prompt
            
            print(f"✅ Agent {agent['name']} configuré en français")
        
        # Test voix neutres
        expected_voices = ["JBFqnCBsd6RMkjVDRZzb", "EXAVITQu4vr4xnSDxMaL", "VR6AewLTigWG4xSOukaG"]
        for agent_id, agent in manager.agents.items():
            voice_id = agent["voice_id"]
            assert voice_id in expected_voices
            print(f"✅ Agent {agent['name']} a une voix neutre sans accent: {voice_id}")
        
        # Test détection anglais
        assert manager._contains_english("I am an AI assistant")
        assert not manager._contains_english("Je suis français")
        print("✅ Détection anglais/français fonctionnelle")
        
        # Test système anti-répétition
        agent_id = "michel_dubois_animateur"
        test_response = "Excellente question ! Laissez-moi y réfléchir..."
        manager._update_memory(agent_id, test_response)
        assert agent_id in manager.conversation_memory
        print("✅ Système anti-répétition fonctionnel")
        
        print("\n" + "=" * 50)
        print("🎉 ÉTAPE 1 COMPLÈTEMENT VALIDÉE !")
        print("✅ Enhanced Multi-Agent Manager opérationnel")
        print("✅ Prompts révolutionnaires français intégrés")
        print("✅ Voix neutres sans accent configurées")
        print("✅ Système anti-répétition fonctionnel")
        print("✅ Détection anglais/français opérationnelle")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
