import 'package:flutter/material.dart';
import 'confidence_boost_adaptive_screen.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';

/// REDIRECTION FORCÉE : Cette ancienne interface d'enregistrement a été remplacée
/// par l'interface conversationnelle adaptative avec Thomas & Marie.
/// Tous les appels vers RecordingScreen sont maintenant redirigés automatiquement.
class RecordingScreen extends StatelessWidget {
  final ConfidenceScenario scenario;
  final TextSupport textSupport;
  final String sessionId;
  final Function(Duration) onRecordingComplete;

  const RecordingScreen({
    Key? key,
    required this.scenario,
    required this.textSupport,
    required this.sessionId,
    required this.onRecordingComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // REDIRECTION AUTOMATIQUE vers l'interface conversationnelle adaptative
    return ConfidenceBoostAdaptiveScreen(scenario: scenario);
  }
}