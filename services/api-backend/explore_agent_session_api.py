#!/usr/bin/env python3
"""
Explore AgentSession API to understand how to use it correctly
"""

import inspect
from livekit.agents.voice import Agent, AgentSession
from livekit.agents import llm

print("=== Exploring AgentSession API ===")

# List all methods of AgentSession
print("\nAgentSession methods:")
for attr in dir(AgentSession):
    if not attr.startswith('_'):
        obj = getattr(AgentSession, attr)
        if callable(obj):
            print(f"\n  - {attr}")
            try:
                sig = inspect.signature(obj)
                print(f"    Signature: {sig}")
                # Get docstring if available
                if obj.__doc__:
                    doc_lines = obj.__doc__.strip().split('\n')
                    if doc_lines:
                        print(f"    Doc: {doc_lines[0]}")
            except:
                pass

# Check for async methods
print("\n\n=== Async methods ===")
for attr in dir(AgentSession):
    if not attr.startswith('_'):
        obj = getattr(AgentSession, attr)
        if inspect.iscoroutinefunction(obj):
            print(f"  - {attr} (async)")

# Look for connection-related methods
print("\n\n=== Connection-related methods ===")
for attr in dir(AgentSession):
    if 'connect' in attr.lower() or 'start' in attr.lower() or 'join' in attr.lower():
        print(f"  - {attr}")

# Check the docstring
print("\n\n=== AgentSession docstring ===")
if AgentSession.__doc__:
    print(AgentSession.__doc__)

# Check if there's a factory method or different usage pattern
print("\n\n=== Looking for usage examples in module ===")
import livekit.agents.voice as voice_module

# Check if there are any example functions
for attr in dir(voice_module):
    if 'example' in attr.lower() or 'demo' in attr.lower() or 'test' in attr.lower():
        print(f"Found: {attr}")

# Try to understand the relationship between Agent and AgentSession
print("\n\n=== Understanding Agent and AgentSession relationship ===")

# Check if Agent has methods that work with AgentSession
print("\nAgent methods that might relate to AgentSession:")
for attr in dir(Agent):
    if not attr.startswith('_') and callable(getattr(Agent, attr)):
        if 'session' in attr.lower() or 'start' in attr.lower():
            print(f"  - {attr}")

# Check the module-level functions
print("\n\n=== Module-level functions ===")
for attr in dir(voice_module):
    obj = getattr(voice_module, attr)
    if callable(obj) and not attr.startswith('_') and not inspect.isclass(obj):
        print(f"  - {attr}")
        try:
            sig = inspect.signature(obj)
            print(f"    Signature: {sig}")
        except:
            pass