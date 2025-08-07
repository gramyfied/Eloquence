#!/usr/bin/env python3
"""
🔧 CORRECTIF TRIBUNAL DES IDÉES - Configuration LiveKit TTS
Résout le problème d'absence d'interaction IA dans l'exercice "Tribunal des Idées Impossibles"

PROBLÈME IDENTIFIÉ:
- L'écran tribunal_idees_screen.dart n'utilise pas le provider LiveKit correct
- Il crée un scénario manuellement au lieu d'utiliser le système unifié
- Il n'utilise pas confidence_livekit_provider qui fonctionne dans confidence_boost

SOLUTION:
- Modifier tribunal_idees_screen.dart pour utiliser ConfidenceBoostLiveKitScreen
- Créer un scénario prédéfini pour le tribunal des idées
- Assurer la compatibilité avec le système LiveKit existant
"""

import os
import shutil
from datetime import datetime

def create_backup(file_path):
    """Créer une sauvegarde du fichier original"""
    if os.path.exists(file_path):
        backup_path = f"{file_path}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copy2(file_path, backup_path)
        print(f"✅ Sauvegarde créée: {backup_path}")
        return backup_path
    return None

def fix_tribunal_idees_screen():
    """Corriger l'écran du tribunal des idées pour utiliser LiveKit"""
    
    tribunal_screen_path = "frontend/flutter_app/lib/features/confidence_boost/presentation/screens/tribunal_idees_screen.dart"
    
    if not os.path.exists(tribunal_screen_path):
        print(f"❌ Fichier non trouvé: {tribunal_screen_path}")
        return False
    
    # Créer une sauvegarde
    create_backup(tribunal_screen_path)
    
    # Nouveau contenu utilisant le système LiveKit unifié
    new_content = '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/confidence_scenario.dart';
import 'confidence_boost_livekit_screen.dart';

/// Écran Tribunal des Idées Impossibles
/// Utilise maintenant le système LiveKit unifié via ConfidenceBoostLiveKitScreen
class TribunalIdeesScreen extends ConsumerWidget {
  const TribunalIdeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔧 FIX: Créer le scénario Tribunal des Idées avec la configuration correcte
    final tribunalScenario = ConfidenceScenario(
      id: 'tribunal_idees_impossibles',
      title: 'Tribunal des Idées Impossibles',
      description: 'Défendez des idées impossibles devant un tribunal bienveillant. '
                  'Exercez votre éloquence en argumentant pour des concepts fantaisistes '
                  'avec conviction et créativité.',
      difficulty: ScenarioDifficulty.intermediate,
      estimatedDuration: const Duration(minutes: 15),
      tags: ['argumentation', 'créativité', 'éloquence', 'débat'],
      aiCharacter: 'thomas', // Utilise le même personnage IA que les autres exercices
      systemPrompt: '''Tu es Thomas, un juge bienveillant mais exigeant du Tribunal des Idées Impossibles.

CONTEXTE:
L'utilisateur va défendre une idée complètement impossible ou fantaisiste. Ton rôle est de:
1. L'écouter avec attention et respect
2. Poser des questions pertinentes pour tester sa logique
3. L'encourager à développer ses arguments
4. Maintenir un ton professionnel mais avec une pointe d'humour
5. Donner des conseils constructifs sur son éloquence

STYLE DE CONVERSATION:
- Commence par "Maître [nom], la cour vous écoute..."
- Utilise un vocabulaire juridique adapté mais accessible
- Pose des questions comme "Comment répondez-vous à l'objection que..." 
- Encourage: "Votre argumentation gagne en force..."
- Conclus par un verdict bienveillant avec des conseils

OBJECTIFS PÉDAGOGIQUES:
- Améliorer la capacité d'argumentation
- Développer la confiance en soi
- Travailler la structure du discours
- Encourager la créativité verbale

Sois exigeant mais toujours encourageant. L'objectif est de faire progresser l'éloquence.''',
      exerciseInstructions: [
        'Choisissez une idée impossible à défendre (ex: "Les nuages devraient payer des impôts")',
        'Préparez 3 arguments principaux',
        'Parlez avec conviction et structure',
        'Répondez aux questions du juge Thomas',
        'Maintenez votre position même face aux objections',
      ],
      successCriteria: [
        'Arguments structurés et cohérents',
        'Conviction dans le ton de voix',
        'Capacité à répondre aux objections',
        'Créativité dans l\'argumentation',
        'Maintien du rôle d\'avocat',
      ],
    );

    // 🔧 FIX: Utiliser directement ConfidenceBoostLiveKitScreen avec le scénario
    return ConfidenceBoostLiveKitScreen(scenario: tribunalScenario);
  }
}

/// Énumération des difficultés de scénario
enum ScenarioDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}
'''
    
    try:
        with open(tribunal_screen_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"✅ Écran tribunal des idées corrigé: {tribunal_screen_path}")
        print("🔧 Modifications appliquées:")
        print("   - Utilise maintenant ConfidenceBoostLiveKitScreen")
        print("   - Scénario prédéfini avec prompt IA optimisé")
        print("   - Compatible avec le système LiveKit existant")
        print("   - Même provider que l'exercice confidence boost qui fonctionne")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la correction: {e}")
        return False

def verify_dependencies():
    """Vérifier que les dépendances nécessaires existent"""
    
    required_files = [
        "frontend/flutter_app/lib/features/confidence_boost/presentation/screens/confidence_boost_livekit_screen.dart",
        "frontend/flutter_app/lib/features/confidence_boost/presentation/providers/confidence_livekit_provider.dart",
        "frontend/flutter_app/lib/features/confidence_boost/data/services/confidence_livekit_service.dart",
        "frontend/flutter_app/lib/features/confidence_boost/domain/entities/confidence_scenario.dart",
    ]
    
    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print("❌ Fichiers manquants pour le correctif:")
        for file in missing_files:
            print(f"   - {file}")
        return False
    
    print("✅ Toutes les dépendances sont présentes")
    return True

def main():
    """Fonction principale du correctif"""
    
    print("🔧 CORRECTIF TRIBUNAL DES IDÉES - Configuration LiveKit TTS")
    print("=" * 60)
    
    # Vérifier les dépendances
    if not verify_dependencies():
        print("\n❌ Correctif annulé: dépendances manquantes")
        return False
    
    # Appliquer le correctif
    success = fix_tribunal_idees_screen()
    
    if success:
        print("\n✅ CORRECTIF APPLIQUÉ AVEC SUCCÈS!")
        print("\n📋 PROCHAINES ÉTAPES:")
        print("1. Redémarrer l'application Flutter")
        print("2. Tester l'exercice 'Tribunal des Idées Impossibles'")
        print("3. Vérifier que l'IA Thomas répond correctement")
        print("4. Confirmer que l'audio fonctionne")
        
        print("\n🔍 DIAGNOSTIC:")
        print("- L'écran utilise maintenant le même système LiveKit que confidence_boost")
        print("- Le scénario est prédéfini avec un prompt IA optimisé")
        print("- Compatible avec confidence_livekit_provider qui fonctionne")
        print("- Même configuration audio et réseau")
        
        return True
    else:
        print("\n❌ ÉCHEC DU CORRECTIF")
        return False

if __name__ == "__main__":
    main()
