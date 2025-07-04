#!/usr/bin/env python3
"""
Diagnostic script to explore LiveKit agents API structure
"""

import sys
import inspect

print("=== LiveKit Agents API Diagnostic ===")
print(f"Python version: {sys.version}")

try:
    import livekit
    try:
        print(f"\nLiveKit version: {livekit.__version__}")
    except AttributeError:
        print("\nLiveKit version: (no __version__ attribute)")
except Exception as e:
    print(f"Error importing livekit: {e}")
    sys.exit(1)

print("\n=== Exploring livekit.agents module ===")
try:
    import livekit.agents
    print("livekit.agents imported successfully")
    
    # List all attributes in livekit.agents
    print("\nAttributes in livekit.agents:")
    for attr in sorted(dir(livekit.agents)):
        if not attr.startswith('_'):
            obj = getattr(livekit.agents, attr)
            print(f"  - {attr}: {type(obj).__name__}")
            
            # If it's a module, explore its contents
            if inspect.ismodule(obj):
                print(f"    Contents of {attr}:")
                for sub_attr in sorted(dir(obj)):
                    if not sub_attr.startswith('_'):
                        sub_obj = getattr(obj, sub_attr)
                        print(f"      - {sub_attr}: {type(sub_obj).__name__}")
    
    # Look for VoicePipelineAgent or VoiceAssistant
    print("\n=== Searching for Voice-related classes ===")
    
    # Check if voice_assistant module exists
    try:
        import livekit.agents.voice_assistant
        print("livekit.agents.voice_assistant module exists!")
        print("Contents:")
        for attr in dir(livekit.agents.voice_assistant):
            if not attr.startswith('_'):
                print(f"  - {attr}")
    except ImportError:
        print("livekit.agents.voice_assistant module NOT found")
    
    # Check if VoicePipelineAgent is directly in agents
    if hasattr(livekit.agents, 'VoicePipelineAgent'):
        print("\nVoicePipelineAgent found in livekit.agents!")
    
    # Check if VoiceAssistant is directly in agents
    if hasattr(livekit.agents, 'VoiceAssistant'):
        print("\nVoiceAssistant found in livekit.agents!")
    
    # Check for pipeline module
    try:
        import livekit.agents.pipeline
        print("\nlivekit.agents.pipeline module exists!")
        print("Contents:")
        for attr in dir(livekit.agents.pipeline):
            if not attr.startswith('_'):
                obj = getattr(livekit.agents.pipeline, attr)
                print(f"  - {attr}: {type(obj).__name__}")
    except ImportError:
        print("\nlivekit.agents.pipeline module NOT found")
    
    # Check for voice module
    try:
        import livekit.agents.voice
        print("\nlivekit.agents.voice module exists!")
        print("Contents:")
        for attr in dir(livekit.agents.voice):
            if not attr.startswith('_'):
                obj = getattr(livekit.agents.voice, attr)
                print(f"  - {attr}: {type(obj).__name__}")
    except ImportError:
        print("\nlivekit.agents.voice module NOT found")
        
except Exception as e:
    print(f"Error exploring livekit.agents: {e}")
    import traceback
    traceback.print_exc()

print("\n=== Looking for any class with 'Voice' or 'Pipeline' in name ===")
try:
    import livekit.agents
    for attr in dir(livekit.agents):
        if 'Voice' in attr or 'Pipeline' in attr or 'voice' in attr or 'pipeline' in attr:
            print(f"Found: {attr}")
            obj = getattr(livekit.agents, attr)
            if inspect.isclass(obj):
                print(f"  - It's a class!")
                print(f"  - Module: {obj.__module__}")
except Exception as e:
    print(f"Error: {e}")

print("\n=== Checking plugins ===")
try:
    from livekit.plugins import openai, silero
    print("Plugins imported successfully")
    
    # Check OpenAI plugin
    print("\nOpenAI plugin contents:")
    for attr in dir(openai):
        if not attr.startswith('_') and attr.isupper():
            print(f"  - {attr}")
            
except Exception as e:
    print(f"Error with plugins: {e}")