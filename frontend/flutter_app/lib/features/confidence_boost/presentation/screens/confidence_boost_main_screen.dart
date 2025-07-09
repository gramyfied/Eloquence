import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../providers/confidence_boost_provider.dart';
import 'scenario_selection_screen.dart';
import 'text_support_selection_screen.dart';
import 'recording_screen.dart';
import 'results_screen.dart';

class ConfidenceBoostMainScreen extends ConsumerStatefulWidget {
  const ConfidenceBoostMainScreen({Key? key}) : super(key: key);

  @override
  _ConfidenceBoostMainScreenState createState() =>
      _ConfidenceBoostMainScreenState();
}

class _ConfidenceBoostMainScreenState extends ConsumerState<ConfidenceBoostMainScreen> {
  late PageController _pageController;
  ConfidenceScenario? _selectedScenario;
  TextSupport? _selectedTextSupport;
  ConfidenceAnalysis? _analysisResult;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onScenarioSelected(ConfidenceScenario scenario) {
    setState(() {
      _selectedScenario = scenario;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onSupportSelected(TextSupport support) {
    setState(() {
      _selectedTextSupport = support;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onRecordingComplete(Duration duration) async {
    if (!mounted) return;
    
    setState(() {
      _recordingDuration = duration;
    });
    
    if (_selectedScenario != null && _selectedTextSupport != null) {
      await ref.read(confidenceBoostProvider.notifier).analyzePerformance(
            scenario: _selectedScenario!,
            textSupport: _selectedTextSupport!,
            recordingDuration: _recordingDuration,
          );
      
      if (!mounted) return;
      
      setState(() {
        _analysisResult = ref.read(confidenceBoostProvider).lastAnalysis;
      });
      
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onRestart() {
    if (!mounted) return;
    
    setState(() {
      _selectedScenario = null;
      _selectedTextSupport = null;
      _analysisResult = null;
      _recordingDuration = Duration.zero;
    });
    _pageController.jumpToPage(0);
  }

  void _onExit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ScenarioSelectionScreen(onScenarioSelected: _onScenarioSelected),
          if (_selectedScenario != null)
            TextSupportSelectionScreen(
              scenario: _selectedScenario!,
              onSupportSelected: _onSupportSelected,
            ),
          if (_selectedScenario != null && _selectedTextSupport != null)
            RecordingScreen(
              scenario: _selectedScenario!,
              textSupport: _selectedTextSupport!,
              sessionId: 'session-id-placeholder', // TODO: Remplacer par un vrai ID de session
              onRecordingComplete: _onRecordingComplete,
            ),
          if (_analysisResult != null)
            ResultsScreen(
              analysis: _analysisResult!,
              onContinue: _onRestart,
            ),
        ],
      ),
    );
  }
}