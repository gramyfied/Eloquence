import 'package:flutter/material.dart';
import 'confidence_boost_rest_screen.dart'; // Importer le nouvel écran REST simplifié
import '../../domain/entities/confidence_scenario.dart'; // Importer le modèle de scénario
import '../../domain/entities/confidence_models.dart'; // Importer les types de scénario

class ConfidenceBoostScreen extends StatelessWidget {
  final String userId;

  const ConfidenceBoostScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Créer un scénario par défaut pour le nouvel écran
    // Note: Idéalement, cela viendrait d'un provider ou d'une sélection utilisateur
    const defaultScenario = ConfidenceScenario(
      id: 'default-adaptive-scenario',
      title: 'Présentation Projet',
      description: 'Présentez votre dernier projet à un client potentiel en mettant en avant ses avantages clés.',
      prompt: 'Bonjour, je suis ravi de vous présenter notre nouvelle solution...',
      type: ConfidenceScenarioType.presentation,
      durationSeconds: 120,
      tips: ['Soyez clair', 'Montrez de l\'enthousiasme', 'Anticipez les questions'],
      keywords: ['innovation', 'performance', 'sécurité'],
      difficulty: 'Moyen',
      icon: '🚀',
    );

    // Redirige vers l'écran REST simplifié
    return const ConfidenceBoostRestScreen(scenario: defaultScenario);
  }
}