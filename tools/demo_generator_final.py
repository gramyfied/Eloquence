#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🎯 DÉMONSTRATION FINALE DU GÉNÉRATEUR ELOQUENCE ULTIMATE
=======================================================

Script de démonstration pratique montrant comment utiliser
le générateur d'exercices Eloquence Ultimate.
"""

import sys
import os
import json
from pathlib import Path

# Ajouter le répertoire parent au path pour importer le générateur
sys.path.append(str(Path(__file__).parent))

from eloquence_generator_ultimate import EloquenceGeneratorUltimate

def demo_generation_exercices():
    """Démonstration de génération d'exercices"""
    print("🎯 DÉMONSTRATION GÉNÉRATEUR ELOQUENCE ULTIMATE")
    print("=" * 55)
    
    generator = EloquenceGeneratorUltimate()
    
    # Exemples d'exercices à générer
    exemples_exercices = [
        {
            'description': "exercice de respiration avec dragon mystique pour débutants",
            'titre': "🐉 Souffle du Dragon Mystique"
        },
        {
            'description': "virelangues magiques difficiles pour améliorer l'articulation",
            'titre': "🪄 Virelangues Enchantés"
        },
        {
            'description': "simulation d'entretien professionnel avec coach expert",
            'titre': "💼 Entretien Professionnel"
        },
        {
            'description': "débat philosophique au tribunal des idées",
            'titre': "⚖️ Tribunal des Idées"
        },
        {
            'description': "création d'histoires collaboratives infinies",
            'titre': "📚 Histoires Infinies"
        }
    ]
    
    exercices_generes = []
    
    for i, exemple in enumerate(exemples_exercices, 1):
        print(f"\n🔄 Génération {i}/5: {exemple['titre']}")
        print("-" * 40)
        
        try:
            # Génération de l'exercice
            exercice = generator.generate_ultimate_exercise(exemple['description'])
            
            # Affichage des informations principales
            print(f"✅ Nom: {exercice['name']}")
            print(f"📂 Type: {exercice['category']}")
            print(f"🎭 Personnage: {exercice['voice_config']['openai_tts']['character_name']}")
            print(f"🎵 Voix: {exercice['voice_config']['openai_tts']['voice']}")
            print(f"⏱️  Durée: {exercice['estimated_duration']} min")
            print(f"🎯 Difficulté: {exercice['difficulty']}")
            
            # Informations gamification
            gamification = exercice['gamification']
            print(f"🎮 XP de base: {gamification['xp_system']['base_xp']}")
            print(f"🏆 Badges: {len(gamification['badge_system']['exercise_badges'])}")
            print(f"🎖️  Achievements: {len(gamification['achievement_system']['main_achievements'])}")
            
            # Informations techniques
            print(f"📱 Code Flutter: {len(exercice['flutter_implementation'])} caractères")
            print(f"🎮 Code Gamifié: {len(exercice['gamified_implementation'])} caractères")
            
            exercices_generes.append(exercice)
            
        except Exception as e:
            print(f"❌ Erreur: {e}")
    
    print(f"\n🎉 GÉNÉRATION TERMINÉE")
    print("=" * 30)
    print(f"Exercices générés avec succès: {len(exercices_generes)}/5")
    
    return exercices_generes

def demo_sauvegarde_exercices(exercices):
    """Démonstration de sauvegarde des exercices"""
    print(f"\n💾 SAUVEGARDE DES EXERCICES")
    print("=" * 30)
    
    generator = EloquenceGeneratorUltimate()
    
    for i, exercice in enumerate(exercices, 1):
        try:
            # Sauvegarde de l'exercice
            filepath = generator.exercise_manager.save_exercise(exercice)
            print(f"✅ Exercice {i} sauvegardé: {filepath}")
        except Exception as e:
            print(f"❌ Erreur sauvegarde {i}: {e}")

def demo_chargement_exercices():
    """Démonstration de chargement des exercices"""
    print(f"\n📂 CHARGEMENT DES EXERCICES")
    print("=" * 30)
    
    generator = EloquenceGeneratorUltimate()
    
    try:
        # Liste des exercices sauvegardés
        exercices = generator.exercise_manager.list_exercises()
        print(f"📊 {len(exercices)} exercice(s) trouvé(s)")
        
        for exercice_info in exercices[:3]:  # Afficher les 3 premiers
            exercice = generator.exercise_manager.load_exercise(exercice_info['id'])
            if exercice:
                print(f"✅ {exercice['name']} - {exercice['category']}")
            else:
                print(f"❌ Erreur chargement: {exercice_info['id']}")
                
    except Exception as e:
        print(f"❌ Erreur: {e}")

def demo_generation_personnalisee():
    """Démonstration de génération personnalisée"""
    print(f"\n🎨 GÉNÉRATION PERSONNALISÉE")
    print("=" * 30)
    
    generator = EloquenceGeneratorUltimate()
    
    # Exemples de descriptions personnalisées
    descriptions_personnalisees = [
        "exercice de respiration zen avec maître bouddhiste",
        "simulation de présentation TED Talk inspirante",
        "jeu de rôle négociation commerciale difficile",
        "exercice d'improvisation théâtrale créative",
        "débat politique avec modérateur impartial"
    ]
    
    for description in descriptions_personnalisees:
        print(f"\n🔄 Génération: {description[:40]}...")
        
        try:
            exercice = generator.generate_ultimate_exercise(description)
            print(f"✅ Généré: {exercice['name']}")
            print(f"   Type détecté: {exercice['category']}")
            print(f"   Personnage: {exercice['voice_config']['openai_tts']['character_name']}")
            
        except Exception as e:
            print(f"❌ Erreur: {e}")

def demo_fonctionnalites_avancees():
    """Démonstration des fonctionnalités avancées"""
    print(f"\n⚡ FONCTIONNALITÉS AVANCÉES")
    print("=" * 30)
    
    generator = EloquenceGeneratorUltimate()
    
    # Génération d'un exercice complexe
    description = "exercice de respiration dragon mystique avec gamification complète"
    exercice = generator.generate_ultimate_exercise(description)
    
    print("🔍 ANALYSE DÉTAILLÉE DE L'EXERCICE")
    print("-" * 35)
    
    # Analyse du système de design
    ui_config = exercice['ui_config']
    print(f"🎨 Thème: {ui_config['theme']['primary_color']} / {ui_config['theme']['secondary_color']}")
    print(f"✨ Effets: {ui_config['theme']['particle_effects']}")
    print(f"🎭 Animation: {ui_config['theme']['animation_style']}")
    
    # Analyse LiveKit
    livekit_config = exercice['livekit_config']
    print(f"📡 Room: {livekit_config['room_configuration']['name']}")
    print(f"🎤 Audio: {livekit_config['audio_processing']['sample_rate']}Hz")
    print(f"🤖 Agent: {livekit_config['ai_agent_config']['agent_type']}")
    
    # Analyse gamification
    gamification = exercice['gamification']
    xp_system = gamification['xp_system']
    print(f"🎮 XP: {xp_system['base_xp']} (x{xp_system['multiplier']})")
    print(f"🏆 Bonus: {len(xp_system['bonus_conditions'])} conditions")
    
    # Analyse voix
    voice_config = exercice['voice_config']
    openai_tts = voice_config['openai_tts']
    print(f"🎵 Voix: {openai_tts['voice']} (vitesse: {openai_tts['speed']})")
    print(f"🎭 Personnalité: {openai_tts['personality']}")
    print(f"👤 Personnage: {openai_tts['character_name']}")

def demo_export_flutter():
    """Démonstration d'export du code Flutter"""
    print(f"\n📱 EXPORT CODE FLUTTER")
    print("=" * 25)
    
    generator = EloquenceGeneratorUltimate()
    
    # Génération d'un exercice pour export
    exercice = generator.generate_ultimate_exercise("virelangues magiques pour articulation")
    
    # Création du dossier d'export
    export_dir = Path("tools/flutter_export")
    export_dir.mkdir(exist_ok=True)
    
    # Export du code principal
    main_file = export_dir / f"{exercice['category']}_screen.dart"
    with open(main_file, 'w', encoding='utf-8') as f:
        f.write(exercice['flutter_implementation'])
    
    # Export du code gamifié
    gamified_file = export_dir / f"gamified_{exercice['category']}_screen.dart"
    with open(gamified_file, 'w', encoding='utf-8') as f:
        f.write(exercice['gamified_implementation'])
    
    # Export de la configuration
    config_file = export_dir / f"{exercice['category']}_config.json"
    config_data = {
        'name': exercice['name'],
        'category': exercice['category'],
        'ui_config': exercice['ui_config'],
        'voice_config': exercice['voice_config'],
        'livekit_config': exercice['livekit_config'],
        'gamification': exercice['gamification']
    }
    
    with open(config_file, 'w', encoding='utf-8') as f:
        json.dump(config_data, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Code principal: {main_file}")
    print(f"✅ Code gamifié: {gamified_file}")
    print(f"✅ Configuration: {config_file}")
    print(f"📊 Taille totale: {len(exercice['flutter_implementation']) + len(exercice['gamified_implementation'])} caractères")

def demo_statistiques():
    """Démonstration des statistiques du générateur"""
    print(f"\n📊 STATISTIQUES DU GÉNÉRATEUR")
    print("=" * 35)
    
    generator = EloquenceGeneratorUltimate()
    
    # Statistiques des types d'exercices
    types_exercices = list(generator.exercise_configs.keys())
    print(f"🎯 Types d'exercices disponibles: {len(types_exercices)}")
    
    for type_exercice in types_exercices:
        config = generator.exercise_configs[type_exercice]
        print(f"   • {type_exercice}: {config['ai_character']}")
    
    # Statistiques des voix
    voix_disponibles = set()
    for config in generator.exercise_configs.values():
        voix_disponibles.add(config['voice_profile']['voice'])
    
    print(f"\n🎵 Voix OpenAI TTS utilisées: {len(voix_disponibles)}")
    for voix in sorted(voix_disponibles):
        print(f"   • {voix}")
    
    # Statistiques des thèmes
    themes_disponibles = set()
    for config in generator.exercise_configs.values():
        themes_disponibles.add(config['design_theme'])
    
    print(f"\n🎨 Thèmes de design: {len(themes_disponibles)}")
    for theme in sorted(themes_disponibles):
        print(f"   • {theme}")

def main():
    """Fonction principale de démonstration"""
    print("🚀 DÉMONSTRATION COMPLÈTE DU GÉNÉRATEUR ELOQUENCE ULTIMATE")
    print("=" * 65)
    print("Ce script démontre toutes les capacités du générateur ultime.")
    print()
    
    try:
        # 1. Génération d'exercices
        exercices = demo_generation_exercices()
        
        # 2. Sauvegarde
        if exercices:
            demo_sauvegarde_exercices(exercices)
        
        # 3. Chargement
        demo_chargement_exercices()
        
        # 4. Génération personnalisée
        demo_generation_personnalisee()
        
        # 5. Fonctionnalités avancées
        demo_fonctionnalites_avancees()
        
        # 6. Export Flutter
        demo_export_flutter()
        
        # 7. Statistiques
        demo_statistiques()
        
        print(f"\n🎉 DÉMONSTRATION TERMINÉE AVEC SUCCÈS !")
        print("=" * 40)
        print("Le générateur Eloquence Ultimate est prêt à l'emploi.")
        print("Vous pouvez maintenant l'intégrer dans votre application Flutter.")
        
    except Exception as e:
        print(f"\n❌ Erreur durant la démonstration: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
