#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🎯 DÉMONSTRATION PRATIQUE DU GÉNÉRATEUR ELOQUENCE ULTIMATE
=========================================================

Script de démonstration pour montrer l'utilisation pratique du générateur
et créer des exercices concrets prêts à l'emploi.
"""

import json
import os
from eloquence_generator_ultimate import EloquenceGeneratorUltimate

def demo_generator_usage():
    """Démonstration complète du générateur avec exemples concrets"""
    
    print("🚀 DÉMONSTRATION GÉNÉRATEUR ELOQUENCE ULTIMATE")
    print("=" * 60)
    
    # Initialisation du générateur
    generator = EloquenceGeneratorUltimate()
    
    # Exemples d'exercices à générer
    exercise_requests = [
        {
            "description": "exercice de respiration du dragon pour gérer le stress avant un discours",
            "expected_type": "souffle_dragon",
            "use_case": "Préparation avant prise de parole publique"
        },
        {
            "description": "virelangues français difficiles pour améliorer l'articulation",
            "expected_type": "virelangues_magiques", 
            "use_case": "Entraînement diction pour journalistes"
        },
        {
            "description": "simulation entretien d'embauche pour poste de manager",
            "expected_type": "simulateur_situations",
            "use_case": "Préparation entretien professionnel"
        },
        {
            "description": "débat sur l'intelligence artificielle et l'éthique",
            "expected_type": "tribunal_idees",
            "use_case": "Formation débat pour étudiants"
        },
        {
            "description": "création d'histoire fantastique collaborative avec IA",
            "expected_type": "histoires_infinies",
            "use_case": "Développement créativité narrative"
        }
    ]
    
    generated_exercises = []
    
    for i, request in enumerate(exercise_requests, 1):
        print(f"\n📝 EXERCICE {i}: {request['use_case']}")
        print("-" * 50)
        print(f"Description: {request['description']}")
        
        try:
            # Génération de l'exercice
            exercise = generator.generate_ultimate_exercise(request['description'])
            
            # Vérification du type détecté
            detected_type = exercise['category']
            expected_type = request['expected_type']
            
            print(f"✅ Type détecté: {detected_type}")
            print(f"🎯 Type attendu: {expected_type}")
            print(f"🎪 Correspondance: {'✓' if detected_type == expected_type else '✗'}")
            
            # Informations sur l'exercice généré
            print(f"🏷️  Nom: {exercise['name']}")
            print(f"⏱️  Durée: {exercise['estimated_duration']} minutes")
            print(f"🎮 Personnage IA: {exercise.get('ai_character', 'N/A')}")
            print(f"🎵 Voix: {exercise.get('voice_config', {}).get('openai_tts', {}).get('voice', 'N/A')}")
            print(f"🏆 XP de base: {exercise.get('gamification', {}).get('xp_system', {}).get('base_xp', 'N/A')}")
            print(f"🎨 Thème: {exercise.get('design_theme', 'N/A')}")
            
            # Sauvegarde de l'exercice
            exercise_filename = f"exercise_{detected_type}_{i}.json"
            exercise_path = os.path.join("tools", "generated_exercises", exercise_filename)
            
            # Création du dossier si nécessaire
            os.makedirs(os.path.dirname(exercise_path), exist_ok=True)
            
            # Sauvegarde
            with open(exercise_path, 'w', encoding='utf-8') as f:
                json.dump(exercise, f, indent=2, ensure_ascii=False)
            
            print(f"💾 Sauvegardé: {exercise_path}")
            
            generated_exercises.append({
                'request': request,
                'exercise': exercise,
                'file_path': exercise_path
            })
            
        except Exception as e:
            print(f"❌ Erreur lors de la génération: {e}")
    
    # Résumé final
    print(f"\n🎉 RÉSUMÉ DE LA DÉMONSTRATION")
    print("=" * 40)
    print(f"📊 Exercices générés: {len(generated_exercises)}")
    print(f"✅ Taux de succès: {len(generated_exercises)/len(exercise_requests)*100:.1f}%")
    
    # Statistiques par type
    type_stats = {}
    for gen_ex in generated_exercises:
        ex_type = gen_ex['exercise']['category']
        type_stats[ex_type] = type_stats.get(ex_type, 0) + 1
    
    print("\n📈 Répartition par type d'exercice:")
    for ex_type, count in type_stats.items():
        print(f"  • {ex_type}: {count} exercice(s)")
    
    # Génération d'un rapport détaillé
    generate_detailed_report(generated_exercises)
    
    return generated_exercises

def generate_detailed_report(exercises):
    """Génère un rapport détaillé des exercices générés"""
    
    report_path = os.path.join("tools", "RAPPORT_GENERATION_EXERCICES.md")
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# 📊 RAPPORT DE GÉNÉRATION D'EXERCICES ELOQUENCE\n\n")
        f.write(f"**Date de génération:** {__import__('datetime').datetime.now().strftime('%d/%m/%Y %H:%M:%S')}\n\n")
        f.write(f"**Nombre d'exercices générés:** {len(exercises)}\n\n")
        
        f.write("## 🎯 EXERCICES GÉNÉRÉS\n\n")
        
        for i, gen_ex in enumerate(exercises, 1):
            exercise = gen_ex['exercise']
            request = gen_ex['request']
            
            f.write(f"### {i}. {exercise['name']}\n\n")
            f.write(f"**Cas d'usage:** {request['use_case']}\n\n")
            f.write(f"**Description demandée:** {request['description']}\n\n")
            
            f.write("**Caractéristiques:**\n")
            f.write(f"- 🏷️ Type: `{exercise['category']}`\n")
            f.write(f"- ⏱️ Durée: {exercise['estimated_duration']} minutes\n")
            f.write(f"- 🎭 Personnage: {exercise.get('ai_character', 'N/A')}\n")
            f.write(f"- 🎵 Voix: {exercise.get('voice_config', {}).get('openai_tts', {}).get('voice', 'N/A')}\n")
            f.write(f"- 🏆 XP de base: {exercise.get('gamification', {}).get('xp_system', {}).get('base_xp', 'N/A')}\n")
            f.write(f"- 🎨 Thème: {exercise.get('design_theme', 'N/A')}\n\n")
            
            f.write("**Fonctionnalités intégrées:**\n")
            f.write("- ✅ Gamification complète (XP, badges, achievements)\n")
            f.write("- ✅ Voix OpenAI TTS avec émotions\n")
            f.write("- ✅ LiveKit bidirectionnel\n")
            f.write("- ✅ Design système professionnel\n")
            f.write("- ✅ Code Flutter prêt à l'emploi\n\n")
            
            f.write(f"**Fichier généré:** `{gen_ex['file_path']}`\n\n")
            f.write("---\n\n")
        
        f.write("## 🚀 UTILISATION\n\n")
        f.write("Pour utiliser ces exercices dans votre application Flutter:\n\n")
        f.write("1. Copiez le code Flutter généré dans votre projet\n")
        f.write("2. Configurez les dépendances (LiveKit, Confetti, etc.)\n")
        f.write("3. Intégrez les services de gamification\n")
        f.write("4. Configurez OpenAI TTS avec votre clé API\n")
        f.write("5. Testez l'exercice dans votre environnement\n\n")
        
        f.write("## 🎮 GAMIFICATION\n\n")
        f.write("Chaque exercice inclut:\n")
        f.write("- **Système XP** avec bonus selon performance\n")
        f.write("- **Badges** débloquables selon progression\n")
        f.write("- **Achievements** pour motivation long terme\n")
        f.write("- **Animations** de célébration immersives\n")
        f.write("- **Feedback** haptique pour engagement\n\n")
        
        f.write("## 🎵 VOIX ET IA\n\n")
        f.write("Configuration OpenAI TTS:\n")
        f.write("- **Voix distinctives** par personnage\n")
        f.write("- **Émotions adaptées** au contexte\n")
        f.write("- **Vitesse modulée** selon l'émotion\n")
        f.write("- **Personnalité** cohérente du personnage\n\n")
        
        f.write("## 📡 LIVEKIT INTEGRATION\n\n")
        f.write("Fonctionnalités temps réel:\n")
        f.write("- **Conversations bidirectionnelles** fluides\n")
        f.write("- **Analyse audio** en temps réel\n")
        f.write("- **Feedback instantané** sur performance\n")
        f.write("- **Adaptation dynamique** de l'IA\n\n")
        
        f.write("---\n\n")
        f.write("*Généré par le Générateur Eloquence Ultimate v1.0*\n")
    
    print(f"📋 Rapport détaillé généré: {report_path}")

def demo_specific_exercise(exercise_type, description):
    """Démonstration pour un exercice spécifique"""
    
    print(f"\n🎯 GÉNÉRATION EXERCICE SPÉCIFIQUE: {exercise_type}")
    print("=" * 50)
    
    generator = EloquenceGeneratorUltimate()
    
    try:
        exercise = generator.generate_ultimate_exercise(description)
        
        print(f"✅ Exercice généré avec succès!")
        print(f"🏷️ Nom: {exercise['name']}")
        print(f"📂 Type: {exercise['category']}")
        print(f"🎭 Personnage: {exercise.get('ai_character', 'N/A')}")
        
        # Affichage du code Flutter (extrait)
        flutter_code = exercise['flutter_implementation']
        print(f"\n📱 Code Flutter généré ({len(flutter_code)} caractères)")
        print("Extrait du code:")
        print("-" * 30)
        print(flutter_code[:500] + "..." if len(flutter_code) > 500 else flutter_code)
        
        return exercise
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def main():
    """Fonction principale de démonstration"""
    
    print("🎪 BIENVENUE DANS LA DÉMONSTRATION DU GÉNÉRATEUR ELOQUENCE!")
    print("=" * 70)
    
    # Démonstration complète
    exercises = demo_generator_usage()
    
    # Test d'un exercice spécifique
    print("\n" + "=" * 70)
    demo_specific_exercise(
        "accordeur_cosmique", 
        "exercice d'accordage vocal avec fréquences cosmiques pour harmoniser la voix"
    )
    
    print(f"\n🎉 DÉMONSTRATION TERMINÉE!")
    print(f"📁 Consultez le dossier 'tools/generated_exercises/' pour voir les exercices générés")
    print(f"📋 Consultez 'tools/RAPPORT_GENERATION_EXERCICES.md' pour le rapport détaillé")

if __name__ == "__main__":
    main()
