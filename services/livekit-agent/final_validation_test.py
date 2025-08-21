#!/usr/bin/env python3
"""
Test final de validation pour Enhanced Multi-Agent Manager
Valide tous les aspects critiques du système
"""

from enhanced_multi_agent_manager import get_enhanced_manager
from multi_agent_config import MultiAgentConfig

def main():
    print("🚀 VALIDATION FINALE ENHANCED MULTI-AGENT MANAGER")
    print("=" * 60)
    
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
        print("\n🧪 VALIDATION DES PROMPTS FRANÇAIS:")
        for agent_id, agent in manager.agents.items():
            system_prompt = agent["system_prompt"]
            
            # Vérifications obligatoires
            assert "FRANÇAIS" in system_prompt or "français" in system_prompt, f"Agent {agent['name']} n'a pas de mention française"
            assert "INTERDICTION TOTALE" in system_prompt, f"Agent {agent['name']} n'a pas d'interdiction anglaise"
            assert "pas un assistant IA" in system_prompt, f"Agent {agent['name']} ne spécifie pas qu'il n'est pas IA"
            
            print(f"✅ Agent {agent['name']} configuré en français")
        
        # Test voix neutres
        print("\n🧪 VALIDATION DES VOIX NEUTRES:")
        expected_voices = ["JBFqnCBsd6RMkjVDRZzb", "EXAVITQu4vr4xnSDxMaL", "VR6AewLTigWG4xSOukaG"]
        for agent_id, agent in manager.agents.items():
            voice_id = agent["voice_id"]
            assert voice_id in expected_voices, f"Agent {agent['name']} a une voix non neutre: {voice_id}"
            print(f"✅ Agent {agent['name']} a une voix neutre sans accent: {voice_id}")
        
        # Test détection anglais
        print("\n🧪 VALIDATION DÉTECTION ANGLAIS:")
        assert manager._contains_english("I am an AI assistant"), "Anglais non détecté"
        assert not manager._contains_english("Je suis français"), "Français détecté comme anglais"
        print("✅ Détection anglais/français fonctionnelle")
        
        # Test système anti-répétition
        print("\n🧪 VALIDATION SYSTÈME ANTI-RÉPÉTITION:")
        agent_id = "michel_dubois_animateur"
        test_response = "Excellente question ! Laissez-moi y réfléchir..."
        manager._update_memory(agent_id, test_response)
        assert agent_id in manager.conversation_memory, "Mémoire non mise à jour"
        assert manager.agents[agent_id]["name"] in manager.last_responses, "Dernière réponse non enregistrée"
        print("✅ Système anti-répétition fonctionnel")
        
        # Test détection émotionnelle
        print("\n🧪 VALIDATION DÉTECTION ÉMOTIONNELLE:")
        emotional_context = manager._detect_emotional_context("", "Excellente réponse !", "michel_dubois_animateur")
        assert emotional_context.primary_emotion in ["enthousiasme", "autorité", "bienveillance", "neutre"], f"Émotion inattendue: {emotional_context.primary_emotion}"
        assert 0.0 <= emotional_context.intensity <= 1.0, f"Intensité invalide: {emotional_context.intensity}"
        print(f"✅ Détection émotionnelle: {emotional_context.primary_emotion} ({emotional_context.intensity})")
        
        # Test rotation speakers
        print("\n🧪 VALIDATION ROTATION SPEAKERS:")
        import asyncio
        async def test_rotation():
            next_speaker = await manager.get_next_speaker("michel_dubois_animateur", "")
            assert next_speaker in ["sarah_johnson_journaliste", "marcus_thompson_expert"]
            print(f"✅ Rotation après Michel: {next_speaker}")
            
            next_speaker = await manager.get_next_speaker("sarah_johnson_journaliste", "")
            assert next_speaker == "marcus_thompson_expert"
            print(f"✅ Rotation après Sarah: {next_speaker}")
            
            next_speaker = await manager.get_next_speaker("marcus_thompson_expert", "")
            assert next_speaker == "michel_dubois_animateur"
            print(f"✅ Rotation après Marcus: {next_speaker}")
        
        asyncio.run(test_rotation())
        
        print("\n" + "=" * 60)
        print("🎉 ÉTAPE 1 COMPLÈTEMENT VALIDÉE !")
        print("✅ Enhanced Multi-Agent Manager opérationnel")
        print("✅ Prompts révolutionnaires français intégrés")
        print("✅ Voix neutres sans accent configurées")
        print("✅ Système anti-répétition fonctionnel")
        print("✅ Détection émotionnelle active")
        print("✅ Rotation intelligente des speakers")
        print("✅ Détection anglais/français opérationnelle")
        print("✅ Tous les tests passent avec succès !")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
