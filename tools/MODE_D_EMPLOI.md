# 📖 Mode d'Emploi : Générateur Eloquence Ultimate

Ce guide explique comment utiliser le script `eloquence_generator_ultimate.py` pour générer des exercices d'éloquence complets et personnalisés.

## 1. Utilisation de Base

Le moyen le plus simple d'utiliser le générateur est d'exécuter le script de démonstration `demo_generator_usage.py`. Ce script montre comment :
- Initialiser le générateur.
- Générer un exercice à partir d'une simple description textuelle.
- Accéder aux différentes parties de l'exercice généré (gamification, voix, etc.).
- Sauvegarder l'exercice complet au format JSON.

Pour l'exécuter, utilisez la commande suivante depuis le répertoire racine du projet :

```bash
cd tools
python demo_generator_usage.py
```

## 2. Intégration dans un autre script Python

Pour intégrer le générateur dans votre propre code, suivez ces étapes :

### Étape 1 : Importer la classe
```python
from eloquence_generator_ultimate import EloquenceGeneratorUltimate
```

### Étape 2 : Initialiser le générateur
```python
generator = EloquenceGeneratorUltimate()
```

### Étape 3 : Générer un exercice
Utilisez la méthode `generate_ultimate_exercise()` avec une description textuelle de l'exercice que vous souhaitez créer.

```python
# Description de l'exercice souhaité
description = "Un exercice de débat sur un sujet philosophique complexe"

# Génération de l'exercice complet
try:
    exercice_complet = generator.generate_ultimate_exercise(description)
    
    # Afficher le résultat
    import json
    print(json.dumps(exercice_complet, indent=2, ensure_ascii=False))
    
except Exception as e:
    print(f"Une erreur est survenue : {e}")

```

## 3. Structure de l'Exercice Généré

La méthode `generate_ultimate_exercise()` retourne un dictionnaire Python contenant la configuration complète de l'exercice. Voici les clés principales :

- `name` (str) : Nom de l'exercice.
- `category` (str) : Type d'exercice détecté (ex: `tribunal_idees`).
- `description` (str) : La description originale que vous avez fournie.
- `instructions` (str) : Instructions pour l'utilisateur.
- `difficulty` (str) : Difficulté estimée (`débutant`, `intermédiaire`, `avancé`).
- `estimated_duration` (int) : Durée estimée en minutes.
- `ui_config` (dict) : Configuration complète du design (thème, couleurs, animations).
- `gamification` (dict) : Système de gamification (XP, badges, achievements).
- `voice_config` (dict) : Configuration de la voix OpenAI TTS (personnage, type de voix, etc.).
- `livekit_config` (dict) : Configuration pour la session de conversation en temps réel.
- `flutter_implementation` (str) : Code source Flutter prêt à l'emploi pour l'interface de l'exercice.
- `gamified_implementation` (str) : Code source Flutter incluant toute la logique de gamification.
- `metadata` (dict) : Métadonnées sur la génération de l'exercice.

## 4. Personnalisation

Le générateur est conçu pour être intelligent et déduire le type d'exercice à partir de votre description. Pour obtenir les meilleurs résultats, soyez aussi descriptif que possible.

**Exemples de descriptions efficaces :**

- `"Je veux un exercice de respiration pour me calmer, style zen ou mystique."`
- `"Créer une simulation d'entretien d'embauche pour un poste de développeur senior."`
- `"Un virelangue très rapide et difficile pour travailler la diction."`
- `"Un exercice de storytelling où je collabore avec une IA pour créer une histoire de science-fiction."`

Le générateur s'occupe du reste, en assemblant tous les modules nécessaires pour créer une expérience complète et immersive.
