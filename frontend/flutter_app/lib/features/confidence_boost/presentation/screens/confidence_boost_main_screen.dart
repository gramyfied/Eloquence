import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../providers/confidence_boost_provider.dart';
import 'scenario_selection_screen.dart';
import 'confidence_boost_adaptive_screen.dart';

class ConfidenceBoostMainScreen extends ConsumerStatefulWidget {
  const ConfidenceBoostMainScreen({Key? key}) : super(key: key);

  @override
  ConfidenceBoostMainScreenState createState() =>
      ConfidenceBoostMainScreenState();
}

class ConfidenceBoostMainScreenState extends ConsumerState<ConfidenceBoostMainScreen> {
  ConfidenceScenario? _selectedScenario;

  void _onScenarioSelected(ConfidenceScenario scenario) {
    setState(() {
      _selectedScenario = scenario;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedScenario == null) {
      return Scaffold(
        body: ScenarioSelectionScreen(onScenarioSelected: _onScenarioSelected),
      );
    }

    // ✅ CORRECTION CRITIQUE : Utiliser l'écran adaptatif unifié avec système de fallback intégré
    return ConfidenceBoostAdaptiveScreen(
      scenario: _selectedScenario!,
    );
  }
}