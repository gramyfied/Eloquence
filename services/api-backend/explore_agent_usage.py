#!/usr/bin/env python3
"""
Script pour explorer l'utilisation correcte de l'Agent dans LiveKit v1.1.5
"""

import inspect
from livekit.agents import voice
from livekit import agents

print("=== Exploring Agent usage patterns ===\n")

# Explorer les exemples dans le module
print("=== Looking for example usage in voice module ===")
if hasattr(voice, '__file__'):
    print(f"Module file: {voice.__file__}")

# Explorer les classes disponibles
print("\n=== Available classes in voice module ===")
for name, obj in inspect.getmembers(voice):
    if inspect.isclass(obj):
        print(f"  - {name}")

# Explorer VoicePipelineAgent si elle existe
print("\n=== Looking for VoicePipelineAgent ===")
if hasattr(voice, 'VoicePipelineAgent'):
    print("VoicePipelineAgent found!")
    vpa = voice.VoicePipelineAgent
    print(f"Constructor signature: {inspect.signature(vpa.__init__)}")
else:
    print("VoicePipelineAgent not found")

# Explorer les fonctions helper
print("\n=== Looking for helper functions ===")
for name, obj in inspect.getmembers(voice):
    if inspect.isfunction(obj):
        print(f"  - {name}")
        print(f"    Signature: {inspect.signature(obj)}")

# Explorer le module agents pour des patterns
print("\n=== Looking in agents module for patterns ===")
for name, obj in inspect.getmembers(agents):
    if 'voice' in name.lower() or 'agent' in name.lower():
        print(f"  - {name}: {type(obj)}")

# Vérifier s'il y a une fonction pour créer un agent vocal
print("\n=== Looking for voice agent creation functions ===")
if hasattr(agents, 'voice_assistant'):
    print("Found agents.voice_assistant")
    print(f"Signature: {inspect.signature(agents.voice_assistant)}")

# Explorer le module principal pour des exemples
print("\n=== Checking main agents module for examples ===")
if hasattr(agents, 'cli'):
    print("Found agents.cli")
    if hasattr(agents.cli, 'run_app'):
        print(f"run_app signature: {inspect.signature(agents.cli.run_app)}")

# Vérifier s'il y a une classe VoiceAssistant dans le module principal
print("\n=== Looking for VoiceAssistant in main module ===")
if hasattr(agents, 'VoiceAssistant'):
    print("Found agents.VoiceAssistant!")
    va = agents.VoiceAssistant
    print(f"Constructor signature: {inspect.signature(va.__init__)}")
    
# Explorer comment utiliser Agent avec AgentSession
print("\n=== Understanding Agent + AgentSession pattern ===")
if hasattr(voice, 'Agent') and hasattr(voice, 'AgentSession'):
    print("Both Agent and AgentSession found")
    print("\nAgent constructor:")
    print(f"  {inspect.signature(voice.Agent.__init__)}")
    print("\nAgentSession.start method:")
    print(f"  {inspect.signature(voice.AgentSession.start)}")
    
    # Vérifier s'il y a une méthode pour connecter l'agent à une room
    agent_methods = [m for m in dir(voice.Agent) if not m.startswith('_')]
    print(f"\nAgent public methods: {agent_methods}")