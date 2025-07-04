#!/usr/bin/env python3
"""
Script de diagnostic pour comprendre l'API ChatContext de LiveKit
"""

import inspect
from livekit import agents
from livekit.agents import llm

print("=== Diagnostic API ChatContext ===\n")

# Examiner ChatContext
print("1. Classe ChatContext:")
print(f"   - Module: {llm.ChatContext.__module__}")
print(f"   - Type: {type(llm.ChatContext)}")

# Lister les méthodes et attributs
print("\n2. Méthodes et attributs de ChatContext:")
for name in dir(llm.ChatContext):
    if not name.startswith('_'):
        attr = getattr(llm.ChatContext, name)
        print(f"   - {name}: {type(attr).__name__}")

# Examiner la signature du constructeur
print("\n3. Signature du constructeur:")
try:
    sig = inspect.signature(llm.ChatContext.__init__)
    print(f"   {sig}")
except Exception as e:
    print(f"   Erreur: {e}")

# Créer une instance et examiner
print("\n4. Instance de ChatContext:")
try:
    ctx = llm.ChatContext()
    print(f"   - Type: {type(ctx)}")
    print(f"   - Attributs publics:")
    for name in dir(ctx):
        if not name.startswith('_'):
            print(f"     - {name}")
except Exception as e:
    print(f"   Erreur lors de la création: {e}")

# Examiner ChatMessage
print("\n5. Classe ChatMessage:")
if hasattr(llm, 'ChatMessage'):
    print(f"   - Existe: Oui")
    for name in dir(llm.ChatMessage):
        if not name.startswith('_'):
            print(f"   - {name}")
else:
    print(f"   - Existe: Non")

# Chercher des exemples dans la documentation
print("\n6. Documentation de ChatContext:")
if llm.ChatContext.__doc__:
    print(llm.ChatContext.__doc__)

# Vérifier s'il y a une méthode pour ajouter des messages
print("\n7. Méthodes pour ajouter des messages:")
ctx_instance = llm.ChatContext()
for method_name in ['append', 'add', 'add_message', 'push', 'messages']:
    if hasattr(ctx_instance, method_name):
        print(f"   - {method_name}: Trouvé")
        attr = getattr(ctx_instance, method_name)
        if callable(attr):
            try:
                sig = inspect.signature(attr)
                print(f"     Signature: {sig}")
            except:
                pass
    else:
        print(f"   - {method_name}: Non trouvé")

# Vérifier la structure des messages
print("\n8. Structure des messages:")
if hasattr(ctx_instance, 'messages'):
    print(f"   - messages: {type(ctx_instance.messages)}")
    print(f"   - Contenu initial: {ctx_instance.messages}")

# Essayer différentes approches
print("\n9. Test de différentes approches:")

# Approche 1: Constructeur avec messages
try:
    from livekit.agents.llm import ChatMessage, ChatRole
    msg = ChatMessage(role=ChatRole.SYSTEM, content="Test")
    ctx1 = llm.ChatContext(messages=[msg])
    print("   ✓ Approche 1: ChatContext(messages=[...]) fonctionne")
except Exception as e:
    print(f"   ✗ Approche 1 échoue: {e}")

# Approche 2: Constructeur avec liste de dicts
try:
    ctx2 = llm.ChatContext(messages=[
        {"role": "system", "content": "Test"}
    ])
    print("   ✓ Approche 2: ChatContext(messages=[dict]) fonctionne")
except Exception as e:
    print(f"   ✗ Approche 2 échoue: {e}")

# Approche 3: Modification directe
try:
    ctx3 = llm.ChatContext()
    if hasattr(ctx3, 'messages') and hasattr(ctx3.messages, 'append'):
        from livekit.agents.llm import ChatMessage, ChatRole
        ctx3.messages.append(ChatMessage(role=ChatRole.SYSTEM, content="Test"))
        print("   ✓ Approche 3: ctx.messages.append(...) fonctionne")
except Exception as e:
    print(f"   ✗ Approche 3 échoue: {e}")

print("\n=== Fin du diagnostic ===")