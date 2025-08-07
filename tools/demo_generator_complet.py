#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🎯 DÉMONSTRATION COMPLÈTE DU GÉNÉRATEUR ELOQUENCE ULTIME
======================================================

Script de démonstration pratique montrant toutes les capacités
du générateur d'exercices Eloquence avec exemples concrets.
"""

import json
import os
from pathlib import Path
from eloquence_generator_ultimate import EloquenceGeneratorUltimate

def demo_generation_complete():
    """Démonstration complète avec génération d'exercices variés"""
    
    print("🚀 DÉMONSTRATION GÉNÉRATEUR ELOQUENCE ULTIME")
    print("=" * 60)
    
    # Initialisation du générateur
    generator = EloquenceGeneratorUltimate()
    
    # Exercices de démonstration avec descriptions variées
    exercices_demo = [
        {
            "description": "exercice de respiration du dragon mystique pour débutants",
            "nom_fichier": "dragon_breath_debutant"
        },
        {
            "description": "virelangues magiques difficiles pour experts en articulation",
            "nom_fichier": "virelangues_expert"
        },
        {
            "description": "accordeur cosmique pour harmoniser sa voix avec l'univers",
            "nom_fichier": "accordeur_cosmique"
        },
        {
            "description": "création d'histoires infinies avec IA collaborative",
            "nom_fichier": "histoires_infinies"
        },
        {
            "description": "simulation entretien d'embauche stressant pour cadre",
            "nom_fichier": "entretien_cadre"
        },
        {
            "description": "débat au tribunal des idées sur l'éthique de l'IA",
            "nom_fichier": "tribunal_ethique_ia"
        },
        {
            "description": "machine à arguments logiques pour débats philosophiques",
            "nom_fichier": "machine_arguments"
        },
        {
            "description": "orateur légendaire style Churchill pour discours inspirants",
            "nom_fichier": "orateur_churchill"
        },
        {
            "description": "studio de scénarios créatifs pour réalisateurs",
            "nom_fichier": "studio_creatif"
        },
        {
            "description": "marché aux objets mystiques - négociation avancée",
            "nom_fichier": "marche_mystique"
        }
    ]
    
    # Création du dossier de sortie
    output_dir = Path("tools/exercices_generes")
    output_dir.mkdir(exist_ok=True)
    
    exercices_generes = []
    
    for i, exercice_info in enumerate(exercices_demo, 1):
        print(f"\n🎯 Génération {i}/10: {exercice_info['description']}")
        print("-" * 50)
        
        try:
            # Génération de l'exercice complet
            exercice = generator.generate_ultimate_exercise(exercice_info['description'])
            
            # Sauvegarde de l'exercice
            fichier_path = output_dir / f"{exercice_info['nom_fichier']}.json"
            with open(fichier_path, 'w', encoding='utf-8') as f:
                json.dump(exercice, f, indent=2, ensure_ascii=False)
            
            # Génération du fichier Flutter
            flutter_path = output_dir / f"{exercice_info['nom_fichier']}_screen.dart"
            with open(flutter_path, 'w', encoding='utf-8') as f:
                f.write(exercice['flutter_implementation'])
            
            # Affichage des informations
            print(f"✅ Nom: {exercice['name']}")
            print(f"📂 Type: {exercice['category']}")
            print(f"🎭 Personnage: {exercice.get('ai_character', exercice['voice_config']['openai_tts']['character_name'])}")
            print(f"🎵 Voix: {exercice['voice_config']['openai_tts']['voice']}")
            print(f"🎮 XP Base: {exercice['gamification']['xp_system']['base_xp']}")
            print(f"🏆 Badges: {len(exercice['gamification']['badge_system']['exercise_badges'])}")
            print(f"💾 Sauvé: {fichier_path.name}")
            print(f"📱 Flutter: {flutter_path.name}")
            
            exercices_generes.append({
                'nom': exercice['name'],
                'type': exercice['category'],
                'fichier_json': str(fichier_path),
                'fichier_flutter': str(flutter_path),
                'personnage': exercice.get('ai_character', exercice['voice_config']['openai_tts']['character_name']),
                'xp_base': exercice['gamification']['xp_system']['base_xp']
            })
            
        except Exception as e:
            print(f"❌ Erreur: {e}")
    
    # Génération du rapport de synthèse
    generer_rapport_synthese(exercices_generes, output_dir)
    
    print(f"\n🎉 GÉNÉRATION TERMINÉE !")
    print(f"📁 Dossier: {output_dir}")
    print(f"✅ Exercices générés: {len(exercices_generes)}/10")
    print(f"📊 Rapport: rapport_generation.md")

def generer_rapport_synthese(exercices: list, output_dir: Path):
    """Génère un rapport de synthèse des exercices générés"""
    
    rapport_path = output_dir / "rapport_generation.md"
    
    rapport_content = f"""# 📊 RAPPORT DE GÉNÉRATION ELOQUENCE ULTIME

## 🎯 Résumé de la génération

**Date:** {Path().cwd()}
**Exercices générés:** {len(exercices)}
**Générateur:** EloquenceGeneratorUltimate v1.0

## 📋 Liste des exercices générés

| # | Nom de l'exercice | Type | Personnage IA | XP Base | Fichiers |
|---|---|---|---|---|---|
"""
    
    for i, ex in enumerate(exercices, 1):
        rapport_content += f"| {i} | {ex['nom']} | {ex['type']} | {ex['personnage']} | {ex['xp_base']} | JSON + Flutter |\n"
    
    rapport_content += f"""
## 🎮 Statistiques de gamification

### Distribution des XP de base
"""
    
    # Calcul des statistiques XP
    xp_values = [ex['xp_base'] for ex in exercices]
    xp_min = min(xp_values) if xp_values else 0
    xp_max = max(xp_values) if xp_values else 0
    xp_moy = sum(xp_values) / len(xp_values) if xp_values else 0
    
    rapport_content += f"""
- **XP Minimum:** {xp_min}
- **XP Maximum:** {xp_max}
- **XP Moyen:** {xp_moy:.1f}

### Types d'exercices générés
"""
    
    # Comptage des types
    types_count = {}
    for ex in exercices:
        type_ex = ex['type']
        types_count[type_ex] = types_count.get(type_ex, 0) + 1
    
    for type_ex, count in types_count.items():
        rapport_content += f"- **{type_ex}:** {count} exercice(s)\n"
    
    rapport_content += f"""
## 🎭 Personnages IA utilisés

"""
    
    # Liste des personnages
    personnages = list(set(ex['personnage'] for ex in exercices))
    for personnage in sorted(personnages):
        rapport_content += f"- {personnage}\n"
    
    rapport_content += f"""
## 📱 Fichiers générés

### Fichiers JSON (Configuration complète)
"""
    
    for ex in exercices:
        rapport_content += f"- `{Path(ex['fichier_json']).name}`\n"
    
    rapport_content += f"""
### Fichiers Flutter (Interface utilisateur)
"""
    
    for ex in exercices:
        rapport_content += f"- `{Path(ex['fichier_flutter']).name}`\n"
    
    rapport_content += f"""
## 🚀 Utilisation des exercices

### Intégration dans votre app Flutter

1. **Copiez les fichiers .dart** dans votre projet Flutter
2. **Importez les configurations JSON** dans vos services
3. **Configurez LiveKit** avec vos tokens
4. **Ajoutez les clés OpenAI** pour TTS
5. **Testez les exercices** en mode développement

### Configuration requise

```yaml
dependencies:
  flutter: sdk: flutter
  livekit_client: ^2.0.0
  confetti: ^0.7.0
  http: ^1.1.0
```

### Variables d'environnement

```env
OPENAI_API_KEY=your_openai_key
LIVEKIT_URL=wss://your-livekit-server.com
LIVEKIT_API_KEY=your_livekit_key
LIVEKIT_SECRET_KEY=your_livekit_secret
```

## ✨ Fonctionnalités incluses

- ✅ **Gamification complète** (XP, badges, achievements)
- ✅ **Voix OpenAI TTS** avec personnalités distinctes
- ✅ **LiveKit bidirectionnel** pour conversations temps réel
- ✅ **Design système professionnel** avec thèmes adaptatifs
- ✅ **Animations et effets** pour engagement maximal
- ✅ **Validation et fallback** ultra-robustes
- ✅ **Code Flutter optimisé** prêt pour production

## 🎯 Prochaines étapes

1. **Testez les exercices** générés
2. **Personnalisez les thèmes** selon vos besoins
3. **Ajoutez vos propres personnages** IA
4. **Intégrez avec votre backend** utilisateur
5. **Déployez en production** avec confiance

---

*Généré par EloquenceGeneratorUltimate - Le générateur d'exercices le plus avancé pour l'éloquence*
"""
    
    with open(rapport_path, 'w', encoding='utf-8') as f:
        f.write(rapport_content)
    
    print(f"📊 Rapport généré: {rapport_path}")

def demo_exercice_specifique():
    """Démonstration de génération d'un exercice spécifique avec analyse détaillée"""
    
    print("\n🔍 ANALYSE DÉTAILLÉE D'UN EXERCICE")
    print("=" * 40)
    
    generator = EloquenceGeneratorUltimate()
    
    # Génération d'un exercice complexe
    description = "débat philosophique avancé sur l'éthique de l'intelligence artificielle avec Socrate"
    
    print(f"📝 Description: {description}")
    print("⏳ Génération en cours...")
    
    exercice = generator.generate_ultimate_exercise(description)
    
    print("\n📊 ANALYSE COMPLÈTE DE L'EXERCICE")
    print("-" * 40)
    
    # Informations générales
    print(f"🎯 Nom: {exercice['name']}")
    print(f"📂 Catégorie: {exercice['category']}")
    print(f"⏱️  Durée: {exercice['estimated_duration']} minutes")
    print(f"🎭 Personnage: {exercice.get('ai_character', exercice['voice_config']['openai_tts']['character_name'])}")
    print(f"🎨 Thème: {exercice['ui_config']['theme']['primary_color']}")
    
    # Analyse gamification
    print(f"\n🎮 GAMIFICATION")
    print(f"💰 XP Base: {exercice['gamification']['xp_system']['base_xp']}")
    print(f"⚡ Multiplicateur: {exercice['gamification']['xp_system']['multiplier']}")
    print(f"🏆 Badges disponibles: {len(exercice['gamification']['badge_system']['exercise_badges'])}")
    achievements = exercice['gamification']['achievement_system']
    achievement_count = len(achievements.get('main_achievements', achievements.get('achievements', [])))
    print(f"🎖️  Achievements: {achievement_count}")
    
    # Analyse voix
    print(f"\n🎵 CONFIGURATION VOIX")
    voice_config = exercice['voice_config']['openai_tts']
    print(f"🗣️  Voix: {voice_config['voice']}")
    print(f"⚡ Vitesse: {voice_config['speed']}")
    print(f"🎭 Personnalité: {voice_config['personality']}")
    
    # Analyse LiveKit
    print(f"\n📡 LIVEKIT CONFIGURATION")
    livekit_config = exercice['livekit_config']
    print(f"🏠 Room: {livekit_config['room_configuration']['name']}")
    print(f"👥 Max participants: {livekit_config['room_configuration']['max_participants']}")
    
    # Gestion robuste de la configuration audio
    if 'audio_processing' in livekit_config:
        print(f"🎤 Sample rate: {livekit_config['audio_processing']['sample_rate']}")
    else:
        print(f"🎤 Audio: Configuration par défaut")
    
    # Taille du code généré
    flutter_code_size = len(exercice['flutter_implementation'])
    gamified_code_size = len(exercice['gamified_implementation'])
    
    print(f"\n📱 CODE GÉNÉRÉ")
    print(f"📄 Flutter standard: {flutter_code_size:,} caractères")
    print(f"🎮 Flutter gamifié: {gamified_code_size:,} caractères")
    print(f"📊 Total: {flutter_code_size + gamified_code_size:,} caractères")
    
    # Sauvegarde de l'analyse
    output_dir = Path("tools/exercices_generes")
    output_dir.mkdir(exist_ok=True)
    
    analysis_path = output_dir / "analyse_detaillee.json"
    with open(analysis_path, 'w', encoding='utf-8') as f:
        json.dump(exercice, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Analyse sauvée: {analysis_path}")

def demo_performance():
    """Test de performance du générateur"""
    
    print("\n⚡ TEST DE PERFORMANCE")
    print("=" * 30)
    
    import time
    
    generator = EloquenceGeneratorUltimate()
    
    descriptions_test = [
        "exercice simple de respiration",
        "virelangue complexe pour experts",
        "débat philosophique avancé",
        "simulation entretien technique",
        "création histoire fantastique"
    ]
    
    temps_total = 0
    exercices_generes = 0
    
    for i, desc in enumerate(descriptions_test, 1):
        print(f"⏱️  Test {i}/5: {desc[:30]}...")
        
        start_time = time.time()
        
        try:
            exercice = generator.generate_ultimate_exercise(desc)
            end_time = time.time()
            
            duree = end_time - start_time
            temps_total += duree
            exercices_generes += 1
            
            print(f"   ✅ Généré en {duree:.2f}s")
            
        except Exception as e:
            print(f"   ❌ Erreur: {e}")
    
    if exercices_generes > 0:
        temps_moyen = temps_total / exercices_generes
        print(f"\n📊 RÉSULTATS PERFORMANCE")
        print(f"⏱️  Temps total: {temps_total:.2f}s")
        print(f"📈 Temps moyen: {temps_moyen:.2f}s par exercice")
        print(f"🚀 Débit: {exercices_generes/temps_total:.1f} exercices/seconde")
        print(f"✅ Taux de réussite: {exercices_generes}/{len(descriptions_test)} ({exercices_generes/len(descriptions_test)*100:.1f}%)")

if __name__ == "__main__":
    # Démonstration complète
    demo_generation_complete()
    
    # Analyse détaillée
    demo_exercice_specifique()
    
    # Test de performance
    demo_performance()
    
    print("\n🎉 DÉMONSTRATION TERMINÉE !")
    print("📁 Consultez le dossier 'tools/exercices_generes' pour voir tous les fichiers générés")
