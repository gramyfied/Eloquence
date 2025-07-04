#!/usr/bin/env python3
"""
Diagnostic approfondi du plugin OpenAI de LiveKit
"""

import asyncio
import os
import sys
import inspect
from typing import Any

# Ajouter le chemin pour les imports
sys.path.append(os.path.join(os.path.dirname(__file__), 'services/api-backend'))

def analyze_class(cls: Any, name: str, indent: int = 0):
    """Analyser une classe et ses méthodes"""
    prefix = "  " * indent
    print(f"{prefix}[CLASS] {name}")
    print(f"{prefix}   Type: {type(cls)}")
    
    # Méthodes publiques
    methods = []
    for attr_name in dir(cls):
        if not attr_name.startswith('_'):
            attr = getattr(cls, attr_name, None)
            if callable(attr):
                methods.append(attr_name)
    
    if methods:
        print(f"{prefix}   [METHODS] Publiques:")
        for method in methods[:10]:  # Limiter à 10
            print(f"{prefix}      - {method}()")
    
    # Signature du constructeur
    try:
        sig = inspect.signature(cls.__init__ if hasattr(cls, '__init__') else cls)
        print(f"{prefix}   [CONSTRUCTOR] {sig}")
    except:
        pass

async def diagnose_plugin():
    """Diagnostic du plugin OpenAI"""
    print("\n" + "="*60)
    print("[DIAGNOSTIC] PLUGIN OPENAI LIVEKIT")
    print("="*60)
    
    # 1. Import et analyse du plugin
    print("\n[1] Import du plugin OpenAI...")
    try:
        from livekit.plugins import openai as openai_plugin
        print("[OK] Plugin importé avec succès")
    except ImportError as e:
        print(f"[ERREUR] Import: {e}")
        return
    
    # 2. Analyser les composants disponibles
    print("\n[2] Composants disponibles dans le plugin:")
    components = []
    for name in dir(openai_plugin):
        if not name.startswith('_'):
            obj = getattr(openai_plugin, name)
            if isinstance(obj, type):  # C'est une classe
                components.append((name, obj))
    
    for name, obj in components:
        analyze_class(obj, name, indent=1)
    
    # 3. Créer et analyser le TTS
    print("\n[3] Création et analyse du TTS...")
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("[ERREUR] OPENAI_API_KEY non définie")
        return
    
    try:
        tts = openai_plugin.TTS(
            api_key=api_key,
            model="tts-1",
            voice="alloy"
        )
        print("[OK] TTS créé avec succès")
        
        # Analyser les méthodes du TTS
        print("\n   [ANALYSE] TTS détaillée:")
        print(f"   Type: {type(tts)}")
        print(f"   Module: {tts.__class__.__module__}")
        
        # Méthodes importantes
        important_methods = ['synthesize', 'stream', 'aclose', '__aenter__', '__aexit__']
        print("\n   [METHODS] Importantes:")
        for method_name in important_methods:
            if hasattr(tts, method_name):
                method = getattr(tts, method_name)
                try:
                    sig = inspect.signature(method)
                    print(f"      - {method_name}{sig}")
                except:
                    print(f"      - {method_name}()")
        
        # Vérifier si c'est un TTS compatible LiveKit
        print("\n   [CHECK] Compatibilité LiveKit:")
        from livekit import agents
        
        # Vérifier les interfaces
        if hasattr(agents, 'tts'):
            print("   [OK] Module agents.tts trouvé")
            
            # Vérifier si le TTS implémente l'interface
            if hasattr(agents.tts, 'TTS'):
                base_tts = agents.tts.TTS
                print(f"   [INFO] Interface TTS de base: {base_tts}")
                
                # Vérifier l'héritage
                if isinstance(tts, base_tts):
                    print("   [OK] Le TTS OpenAI hérite de l'interface LiveKit")
                else:
                    print("   [WARNING] Le TTS OpenAI n'hérite pas directement de l'interface")
        
    except Exception as e:
        print(f"[ERREUR] Création TTS: {e}")
        import traceback
        traceback.print_exc()
    
    # 4. Analyser comment le TTS gère l'audio
    print("\n[4] Analyse de la gestion audio...")
    try:
        # Simuler une synthèse pour voir le type de retour
        print("   [TEST] Synthèse (sans await)...")
        
        # Créer une tâche de test
        async def test_synthesis():
            try:
                # Test avec un texte court
                result = tts.synthesize("Test")
                print(f"   [INFO] Type de résultat: {type(result)}")
                
                # Si c'est une coroutine, l'attendre
                if inspect.iscoroutine(result):
                    print("   [INFO] C'est une coroutine, await nécessaire")
                    actual_result = await result
                    print(f"   [INFO] Type après await: {type(actual_result)}")
                    
                    # Analyser le résultat
                    if hasattr(actual_result, '__iter__'):
                        print("   [INFO] Le résultat est itérable")
                        # Prendre le premier élément pour analyse
                        try:
                            first_item = None
                            async for item in actual_result:
                                first_item = item
                                break
                            if first_item:
                                print(f"   [INFO] Type d'élément: {type(first_item)}")
                                if hasattr(first_item, '__dict__'):
                                    print(f"   [INFO] Attributs: {list(first_item.__dict__.keys())}")
                        except:
                            pass
                            
            except Exception as e:
                print(f"   [ERREUR] Test synthèse: {e}")
        
        # Exécuter le test
        await test_synthesis()
        
    except Exception as e:
        print(f"[ERREUR] Analyse audio: {e}")
    
    # 5. Recommandations
    print("\n[5] Recommandations:")
    print("   [OK] Utiliser le plugin OpenAI officiel pour éviter les problèmes d'AudioEmitter")
    print("   [OK] Le plugin gère automatiquement le cycle de vie de l'audio")
    print("   [OK] Pas besoin de gérer manuellement push(), start(), end_input()")
    print("   [EXEMPLE] Utilisation:")
    print("      tts = openai_plugin.TTS(api_key=key, model='tts-1', voice='alloy')")
    print("      session = AgentSession(llm=llm, tts=tts, vad=vad)")

async def main():
    """Point d'entrée principal"""
    await diagnose_plugin()
    
    print("\n" + "="*60)
    print("[OK] DIAGNOSTIC TERMINÉ")
    print("="*60)

if __name__ == "__main__":
    asyncio.run(main())