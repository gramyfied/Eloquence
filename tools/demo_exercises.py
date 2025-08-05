#!/usr/bin/env python3
"""
🚀 Script de Démonstration du Générateur d'Exercices Eloquence
===============================================================

Ce script génère automatiquement une collection d'exercices vocaux
de démonstration pour montrer les capacités du générateur.
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

from exercise_generator import EloquenceExerciseGenerator
import json

def main():
    """Génère une collection d'exercices de démonstration"""
    
    print("=" * 70)
    print("   [*] DEMONSTRATION DU GENERATEUR D'EXERCICES ELOQUENCE")
    print("=" * 70)
    
    generator = EloquenceExerciseGenerator()
    
    # Collection d'idées d'exercices à tester
    exercise_ideas = [
        # Exercices basiques
        "Exercice simple de transcription vocale",
        "Analyse de prosodie en temps réel",
        "Feedback vocal avec synthèse TTS",
        
        # Exercices intermédiaires
        "Conversation interactive avec analyse complète",
        "Entraînement à la présentation avec tous les services",
        "Exercice d'articulation avec feedback temps réel",
        
        # Exercices avancés
        "Simulation entretien d'embauche avec analyse comportementale",
        "Coaching pitch investisseur avec métriques avancées",
        "Formation débat public avec analyse persuasion",
        
        # Exercices spécialisés
        "Entraînement virelangues pour améliorer diction",
        "Exercice respiration et gestion du stress",
        "Session storytelling avec analyse émotionnelle"
    ]
    
    print(f"[*] Generation de {len(exercise_ideas)} exercices de demonstration...\n")
    
    all_exercises = {}
    
    for i, idea in enumerate(exercise_ideas, 1):
        print(f"[{i:02d}/{len(exercise_ideas)}] {idea}")
        print("-" * 50)
        
        try:
            # Générer l'exercice sans sauvegarde automatique
            exercise_json = generator.generate_from_description(idea, save_to_file=False)
            
            # Ajouter à la collection
            all_exercises.update(exercise_json)
            
            print("[+] SUCCESS - Exercice genere avec succes")
            
        except Exception as e:
            print(f"[!] ERROR - Erreur lors de la generation: {e}")
        
        print()
    
    # Sauvegarder tous les exercices dans un fichier de démonstration
    demo_file = "demo_exercises_collection.json"
    with open(demo_file, 'w', encoding='utf-8') as f:
        json.dump(all_exercises, f, indent=2, ensure_ascii=False)
    
    print("=" * 70)
    print(f"[+] DEMO TERMINEE - {len(all_exercises)} exercices generes")
    print(f"[*] Fichier de sortie: {demo_file}")
    print("=" * 70)
    
    # Statistiques de la génération
    print("\n[*] STATISTIQUES DE GENERATION:")
    print("-" * 40)
    
    types_count = {}
    difficulties_count = {}
    total_duration = 0
    
    for exercise_id, exercise in all_exercises.items():
        # Compter les types
        exercise_type = exercise.get('type', 'unknown')
        types_count[exercise_type] = types_count.get(exercise_type, 0) + 1
        
        # Compter les difficultés
        difficulty = exercise.get('difficulty', 'unknown')
        difficulties_count[difficulty] = difficulties_count.get(difficulty, 0) + 1
        
        # Durée totale
        total_duration += exercise.get('duration', 0)
    
    print(f"Types d'exercices:")
    for ex_type, count in types_count.items():
        print(f"  - {ex_type}: {count} exercices")
    
    print(f"\nNiveaux de difficulte:")
    for difficulty, count in difficulties_count.items():
        print(f"  - {difficulty}: {count} exercices")
    
    print(f"\nDuree totale: {total_duration} secondes ({total_duration/60:.1f} minutes)")
    
    # Afficher quelques exemples détaillés
    print("\n[*] EXEMPLES D'EXERCICES GENERES:")
    print("-" * 40)
    
    examples_shown = 0
    for exercise_id, exercise in all_exercises.items():
        if examples_shown >= 3:  # Limiter à 3 exemples
            break
            
        print(f"\n[{examples_shown + 1}] ID: {exercise_id}")
        print(f"    Nom: {exercise['name']}")
        print(f"    Type: {exercise['type']} | Difficulte: {exercise['difficulty']}")
        print(f"    Focus: {', '.join(exercise['focus_areas'])}")
        print(f"    Workflow:")
        for j, step in enumerate(exercise['steps'], 1):
            print(f"      {j}. {step['service']} -> {step['endpoint']}")
        print(f"    XP completion: {exercise['gamification']['xp_rewards']['completion']}")
        print(f"    Temps reel: {'Oui' if exercise['realtime_enabled'] else 'Non'}")
        
        examples_shown += 1
    
    print(f"\n[*] ... et {len(all_exercises) - examples_shown} autres exercices dans {demo_file}")
    
    return all_exercises


def analyze_exercises_compatibility():
    """Analyse la compatibilité des exercices générés avec l'architecture Eloquence"""
    
    print("\n" + "=" * 70)
    print("[*] ANALYSE DE COMPATIBILITE AVEC ELOQUENCE")
    print("=" * 70)
    
    try:
        with open("demo_exercises_collection.json", 'r', encoding='utf-8') as f:
            exercises = json.load(f)
    except FileNotFoundError:
        print("[!] Fichier de demo non trouve. Executez d'abord la generation.")
        return
    
    print(f"[*] Analyse de {len(exercises)} exercices...")
    
    # Services utilisés
    services_used = set()
    endpoints_used = set()
    
    for exercise_id, exercise in exercises.items():
        for step in exercise['steps']:
            services_used.add(step['service'])
            endpoints_used.add(f"{step['service']}.{step['endpoint']}")
    
    print(f"\n[*] Services utilises dans les exercices:")
    for service in sorted(services_used):
        print(f"  - {service}")
    
    print(f"\n[*] Endpoints utilises:")
    for endpoint in sorted(endpoints_used):
        print(f"  - {endpoint}")
    
    # Compatibilité avec l'architecture
    compatible_services = {
        "stt_service": "[OK] Compatible - Service Vosk existant",
        "audio_analysis_service": "[OK] Compatible - Services d'analyse existants",
        "tts_service": "[OK] Compatible - Service TTS disponible",
        "livekit": "[OK] Compatible - Infrastructure LiveKit en place"
    }
    
    print(f"\n[*] Compatibilite avec l'architecture Eloquence:")
    for service in sorted(services_used):
        status = compatible_services.get(service, "[?] Service non reconnu")
        print(f"  - {service}: {status}")
    
    # Métriques de gamification
    total_xp_possible = 0
    total_badges = 0
    
    for exercise in exercises.values():
        total_xp_possible += exercise['gamification']['xp_rewards']['completion']
        total_badges += len(exercise['gamification']['badges'])
    
    print(f"\n[*] Metriques de gamification:")
    print(f"  - XP total possible: {total_xp_possible}")
    print(f"  - Badges disponibles: {total_badges}")
    print(f"  - Moyenne XP par exercice: {total_xp_possible/len(exercises):.1f}")


if __name__ == "__main__":
    print("[*] Demarrage de la demonstration...")
    
    # Générer les exercices
    exercises = main()
    
    # Analyser la compatibilité
    analyze_exercises_compatibility()
    
    print(f"\n[+] Demonstration terminee avec succes!")
    print(f"[*] {len(exercises)} exercices generes et analyses")
    print(f"[*] Utilisez 'python exercise_generator.py \"Votre idee\"' pour creer de nouveaux exercices")