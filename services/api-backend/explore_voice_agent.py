#!/usr/bin/env python3
"""
Explore the voice.Agent class to understand how to use it
"""

import inspect
from livekit.agents.voice import Agent, AgentSession
from livekit.agents import ChatContext
from livekit.plugins import openai, silero

print("=== Exploring livekit.agents.voice.Agent ===")

# Check Agent class
print("\nAgent class info:")
print(f"Module: {Agent.__module__}")
print(f"MRO: {[cls.__name__ for cls in Agent.__mro__]}")

# Check constructor
print("\nAgent.__init__ signature:")
try:
    sig = inspect.signature(Agent.__init__)
    print(f"Parameters: {list(sig.parameters.keys())}")
    for param_name, param in sig.parameters.items():
        if param_name != 'self':
            print(f"  - {param_name}: {param.annotation if param.annotation != inspect.Parameter.empty else 'Any'}")
            if param.default != inspect.Parameter.empty:
                print(f"    Default: {param.default}")
except Exception as e:
    print(f"Error getting signature: {e}")

# Check methods
print("\nAgent methods:")
methods = [m for m in dir(Agent) if not m.startswith('_') and callable(getattr(Agent, m))]
for method in sorted(methods):
    print(f"  - {method}")

# Check AgentSession
print("\n=== Exploring AgentSession ===")
print(f"Module: {AgentSession.__module__}")

print("\nAgentSession.__init__ signature:")
try:
    sig = inspect.signature(AgentSession.__init__)
    print(f"Parameters: {list(sig.parameters.keys())}")
    for param_name, param in sig.parameters.items():
        if param_name != 'self':
            print(f"  - {param_name}: {param.annotation if param.annotation != inspect.Parameter.empty else 'Any'}")
            if param.default != inspect.Parameter.empty:
                print(f"    Default: {param.default}")
except Exception as e:
    print(f"Error getting signature: {e}")

# Check if there's a factory method or builder
print("\n=== Looking for factory methods or builders ===")
import livekit.agents.voice as voice_module

for attr_name in dir(voice_module):
    attr = getattr(voice_module, attr_name)
    if callable(attr) and not attr_name.startswith('_'):
        print(f"\nFound function: {attr_name}")
        try:
            sig = inspect.signature(attr)
            print(f"  Signature: {sig}")
        except:
            pass

# Check ChatContext
print("\n=== Checking ChatContext ===")
print("ChatContext methods:")
methods = [m for m in dir(ChatContext) if not m.startswith('_')]
for method in sorted(methods):
    print(f"  - {method}")

# Try to understand the correct usage pattern
print("\n=== Example usage patterns ===")
print("Based on the API, here's how it might work:")

# Check if there's documentation
if Agent.__doc__:
    print(f"\nAgent docstring:\n{Agent.__doc__}")

if AgentSession.__doc__:
    print(f"\nAgentSession docstring:\n{AgentSession.__doc__}")