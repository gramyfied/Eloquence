#!/usr/bin/env python3
"""
Script de validation pour vérifier que l'exercice "studio situation pro debat tv"
utilise bien les multi-agents au lieu de Thomas
"""

import json
import sys
import os

def validate_fix():
    """Valide que les corrections appliquées fonctionnent correctement"""
    
    print("🔍 VALIDATION DES CORRECTIONS - STUDIO DEBATE TV")
    print("="*60)
    
    # 1. Vérifier que les fichiers modifiés existent
    files_to_check = [
        'services/livekit-agent/unified_entrypoint.py',
        'frontend/flutter_app/lib/features/studio_situations_pro/data/services/studio_livekit_service.dart',
        'frontend/flutter_app/lib/features/studio_situations_pro/data/services/studio_situations_pro_service.dart',
    ]
    
    print("📁 Vérification des fichiers modifiés:")
    for file_path in files_to_check:
        if os.path.exists(file_path):
            print(f"   ✅ {file_path}")
        else:
            print(f"   ❌ {file_path} - MANQUANT")
            return False
    
    # 2. Vérifier les corrections dans unified_entrypoint.py
    print("\n🔧 Vérification des corrections dans unified_entrypoint.py:")
    
    try:
        with open('services/livekit-agent/unified_entrypoint.py', 'r', encoding='utf-8') as f:
            content = f.read()
        
        checks = [
            ("Priorité absolue aux métadonnées", "return exercise_type"),
            ("studio_debate_tv dans MULTI_AGENT_EXERCISES", "'studio_debate_tv'"),
            ("studio_debatPlateau dans MULTI_AGENT_EXERCISES", "'studio_debatPlateau'"),
            ("Alias studio_debatPlateau", "'studio_debatplateau': 'studio_debate_tv'"),
            ("Alias studio_situations_pro", "'studio_situations_pro': 'studio_situations_pro'"),
        ]
        
        for check_name, check_text in checks:
            if check_text in content:
                print(f"   ✅ {check_name}")
            else:
                print(f"   ❌ {check_name} - MANQUANT")
                return False
                
    except Exception as e:
        print(f"   ❌ Erreur lecture fichier: {e}")
        return False
    
    # 3. Vérifier les corrections dans le frontend
    print("\n🔧 Vérification des corrections dans le frontend:")
    
    try:
        with open('frontend/flutter_app/lib/features/studio_situations_pro/data/services/studio_livekit_service.dart', 'r', encoding='utf-8') as f:
            content = f.read()
        
        if "'exercise_type': 'studio_debate_tv'" in content:
            print("   ✅ Métadonnées studio_debate_tv dans studio_livekit_service.dart")
        else:
            print("   ❌ Métadonnées studio_debate_tv manquantes dans studio_livekit_service.dart")
            return False
            
    except Exception as e:
        print(f"   ❌ Erreur lecture fichier frontend: {e}")
        return False
    
    # 4. Vérifier le mapping des types de simulation
    try:
        with open('frontend/flutter_app/lib/features/studio_situations_pro/data/services/studio_situations_pro_service.dart', 'r', encoding='utf-8') as f:
            content = f.read()
        
        if "_getExerciseTypeForSimulation" in content and "return 'studio_debate_tv'" in content:
            print("   ✅ Mapping des types de simulation correct")
        else:
            print("   ❌ Mapping des types de simulation manquant")
            return False
            
    except Exception as e:
        print(f"   ❌ Erreur lecture fichier service: {e}")
        return False
    
    # 5. Vérifier la configuration multi-agents
    print("\n🔧 Vérification de la configuration multi-agents:")
    
    try:
        with open('services/livekit-agent/multi_agent_config.py', 'r', encoding='utf-8') as f:
            content = f.read()
        
        multi_agent_checks = [
            ("Configuration studio_debate_tv", "get_studio_debate_tv_config"),
            ("Agent Michel Dubois", "michel_dubois_animateur"),
            ("Agent Sarah Johnson", "sarah_johnson_journaliste"),
            ("Agent Marcus Thompson", "marcus_thompson_expert"),
            ("Voix George", '"voice": "George"'),
            ("Voix Bella", '"voice": "Bella"'),
            ("Voix Arnold", '"voice": "Arnold"'),
        ]
        
        for check_name, check_text in multi_agent_checks:
            if check_text in content:
                print(f"   ✅ {check_name}")
            else:
                print(f"   ❌ {check_name} - MANQUANT")
                return False
                
    except Exception as e:
        print(f"   ❌ Erreur lecture multi_agent_config.py: {e}")
        return False
    
    # 6. Vérifier que Thomas n'est pas utilisé pour les multi-agents
    print("\n🔧 Vérification que Thomas n'est pas utilisé pour les multi-agents:")
    
    try:
        with open('services/livekit-agent/multi_agent_main.py', 'r', encoding='utf-8') as f:
            content = f.read()
        
        if "thomas" not in content.lower() or "ai_character" not in content.lower():
            print("   ✅ Pas d'utilisation de Thomas dans multi_agent_main.py")
        else:
            print("   ⚠️ Thomas pourrait être utilisé dans multi_agent_main.py")
            
    except Exception as e:
        print(f"   ❌ Erreur lecture multi_agent_main.py: {e}")
    
    print("\n✅ VALIDATION TERMINÉE AVEC SUCCÈS !")
    print("="*50)
    print("🎯 RÉSUMÉ DES CORRECTIONS APPLIQUÉES:")
    print("1. ✅ Priorité absolue aux métadonnées dans unified_entrypoint.py")
    print("2. ✅ Correction des métadonnées frontend (studio_debate_tv)")
    print("3. ✅ Mapping correct des types de simulation")
    print("4. ✅ Ajout de tous les types d'exercices multi-agents")
    print("5. ✅ Alias complets pour la normalisation")
    print("6. ✅ Configuration multi-agents avec Michel, Sarah, Marcus")
    print("\n🚀 L'exercice 'studio situation pro debat tv' devrait maintenant")
    print("   utiliser les multi-agents (Michel, Sarah, Marcus) au lieu de Thomas !")
    print("\n📋 PROCHAINES ÉTAPES:")
    print("1. Redémarrer les services LiveKit")
    print("2. Tester l'exercice dans l'application")
    print("3. Vérifier que Michel Dubois (animateur) répond au lieu de Thomas")
    
    return True

def generate_test_instructions():
    """Génère les instructions de test pour valider le fix"""
    
    print("\n📋 INSTRUCTIONS DE TEST:")
    print("="*40)
    print("1. Redémarrez les services LiveKit:")
    print("   ./scripts/restart-unified.ps1")
    print("   ou")
    print("   docker-compose restart livekit-agent")
    print("\n2. Lancez l'application Flutter")
    print("   cd frontend/flutter_app")
    print("   flutter run")
    print("\n3. Testez l'exercice 'Débat en Plateau TV':")
    print("   - Allez dans Studio Situations Pro")
    print("   - Sélectionnez 'Débat en Plateau TV'")
    print("   - Entrez un nom et un sujet")
    print("   - Commencez l'exercice")
    print("\n4. Vérifiez que:")
    print("   ✅ Michel Dubois (animateur) vous accueille")
    print("   ✅ Sarah Johnson (journaliste) participe")
    print("   ✅ Marcus Thompson (expert) participe")
    print("   ❌ Thomas ne répond PAS")
    print("\n5. Messages attendus:")
    print("   'Bonsoir ! Je suis Michel Dubois et bienvenue dans notre studio de débat !'")
    print("   (au lieu de 'Bonjour ! Je suis Thomas...')")

if __name__ == "__main__":
    success = validate_fix()
    if success:
        generate_test_instructions()
    else:
        print("\n❌ VALIDATION ÉCHOUÉE - Vérifiez les corrections")
        sys.exit(1)
