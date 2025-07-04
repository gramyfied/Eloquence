#!/usr/bin/env python3
"""
Script de diagnostic pour comprendre l'API agents de LiveKit v1.1.5
"""

import inspect
from livekit import agents
from livekit.agents import voice_assistant

print("=== Diagnostic API LiveKit Agents v1.1.5 ===\n")

# 1. Examiner le module agents
print("1. Contenu du module 'agents':")
for name in dir(agents):
    if not name.startswith('_'):
        try:
            attr = getattr(agents, name)
            print(f"   - {name}: {type(attr).__name__}")
        except:
            print(f"   - {name}: (erreur d'accès)")

# 2. Chercher VoiceAssistant
print("\n2. Recherche de VoiceAssistant:")
voice_classes = []
for name in dir(agents):
    if 'voice' in name.lower() or 'assistant' in name.lower():
        voice_classes.append(name)
        print(f"   - Trouvé: {name}")

if not voice_classes:
    print("   - Aucune classe Voice/Assistant trouvée directement")

# 3. Explorer les sous-modules
print("\n3. Sous-modules disponibles:")
import pkgutil
import livekit.agents
for importer, modname, ispkg in pkgutil.iter_modules(livekit.agents.__path__):
    print(f"   - {modname} (package: {ispkg})")

# 4. Vérifier voice_assistant
print("\n4. Module voice_assistant:")
try:
    from livekit.agents import voice_assistant
    print("   ✓ Module voice_assistant importé avec succès")
    
    print("\n   Contenu de voice_assistant:")
    for name in dir(voice_assistant):
        if not name.startswith('_'):
            attr = getattr(voice_assistant, name)
            print(f"     - {name}: {type(attr).__name__}")
            
    # Chercher VoiceAssistant
    if hasattr(voice_assistant, 'VoiceAssistant'):
        print("\n   ✓ VoiceAssistant trouvé dans voice_assistant!")
        print("     Usage: from livekit.agents.voice_assistant import VoiceAssistant")
    
except ImportError as e:
    print(f"   ✗ Erreur d'import: {e}")

# 5. Vérifier les imports possibles
print("\n5. Imports possibles:")
try:
    from livekit.agents.voice_assistant import VoiceAssistant
    print("   ✓ from livekit.agents.voice_assistant import VoiceAssistant")
except ImportError as e:
    print(f"   ✗ VoiceAssistant import échoue: {e}")

try:
    from livekit.agents import VoiceAssistant
    print("   ✓ from livekit.agents import VoiceAssistant")
except ImportError as e:
    print(f"   ✗ Direct import échoue: {e}")

# 6. Alternatives pour créer un agent
print("\n6. Classes d'agent disponibles:")
agent_classes = []
for name in dir(agents):
    try:
        attr = getattr(agents, name)
        if isinstance(attr, type) and 'agent' in name.lower():
            agent_classes.append(name)
            print(f"   - {name}")
    except:
        pass

# 7. Examiner JobContext
print("\n7. JobContext et ses méthodes:")
if hasattr(agents, 'JobContext'):
    print("   ✓ JobContext disponible")
    for name in dir(agents.JobContext):
        if not name.startswith('_') and callable(getattr(agents.JobContext, name, None)):
            print(f"     - {name}()")

# 8. Exemple de code fonctionnel
print("\n8. Code recommandé pour LiveKit v1.1.5:")
print("""
# Option 1: Import explicite
from livekit.agents.voice_assistant import VoiceAssistant

# Option 2: Si VoiceAssistant n'existe pas, utiliser l'approche manuelle
# avec les composants individuels (STT, TTS, LLM)
""")

print("\n=== Fin du diagnostic ===")