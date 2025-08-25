#!/usr/bin/env python3
"""
Debug test pour identifier l'erreur
"""

try:
    print("1. Test import MultiAgentConfig...")
    from multi_agent_config import MultiAgentConfig
    print("✅ MultiAgentConfig importé")
    
    print("2. Test création config...")
    config = MultiAgentConfig(
        exercise_id="test",
        room_prefix="test", 
        agents=[],
        interaction_rules={},
        turn_management="test"
    )
    print("✅ Config créée")
    
    print("3. Test import EnhancedMultiAgentManager...")
    from enhanced_multi_agent_manager import get_enhanced_manager
    print("✅ get_enhanced_manager importé")
    
    print("4. Test création manager...")
    manager = get_enhanced_manager("test", "test", config)
    print("✅ Manager créé")
    
    print("5. Test accès agents...")
    print(f"Nombre d'agents: {len(manager.agents)}")
    for agent_id, agent in manager.agents.items():
        print(f"Agent: {agent['name']} - {agent['role']}")
    
    print("6. Test prompts français...")
    for agent_id, agent in manager.agents.items():
        prompt = agent["system_prompt"]
        print(f"Agent {agent['name']}: 'FRANÇAIS' in prompt = {'FRANÇAIS' in prompt}")
        print(f"Agent {agent['name']}: 'generate response' in prompt = {'generate response' in prompt.lower()}")
    
    print("7. Test voix...")
    for agent_id, agent in manager.agents.items():
        print(f"Agent {agent['name']}: voix = {agent['voice_id']}")
    
    print("8. Test détection anglais...")
    print(f"Contains english 'I am': {manager._contains_english('I am an AI')}")
    print(f"Contains english 'Je suis': {manager._contains_english('Je suis français')}")
    
    print("🎉 TOUS LES TESTS PASSÉS !")
    
except Exception as e:
    print(f"❌ ERREUR: {e}")
    import traceback
    traceback.print_exc()
