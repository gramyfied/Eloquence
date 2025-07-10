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
    print("🎙️ DEBUG: Recording completed, duration: ${duration.inSeconds}s");
    if (!mounted) return;
    
    setState(() {
      _recordingDuration = duration;
    });
    
    if (_selectedScenario != null && _selectedTextSupport != null) {
      print("🔄 DEBUG: Starting analysis for scenario: ${_selectedScenario!.title}");
      
      await ref.read(confidenceBoostProvider.notifier).analyzePerformance(
            scenario: _selectedScenario!,
            textSupport: _selectedTextSupport!,
            recordingDuration: _recordingDuration,
          );
      
      print("✅ DEBUG: Analysis completed, checking results...");
      
      if (!mounted) {
        print("⚠️ DEBUG: Widget disposed during analysis");
        return;
      }
      
      final analysisResult = ref.read(confidenceBoostProvider).lastAnalysis;
      print("📊 DEBUG: Analysis result available: ${analysisResult != null}");
      print("🔍 DEBUG: Provider state: ${ref.read(confidenceBoostProvider)}");
      print("🔍 DEBUG: Local _analysisResult: ${_analysisResult != null}");
      
      if (analysisResult != null) {
        print("📈 DEBUG: Analysis score: ${analysisResult.overallScore}");
        print("🔍 DEBUG: Setting local _analysisResult...");
        setState(() {
          _analysisResult = analysisResult;
        });
        print("✅ DEBUG: Local _analysisResult set: ${_analysisResult != null}");
        
        print("🚀 DEBUG: Navigating to results page...");
        if (mounted) {
          print("🔍 DEBUG: PageView children count before navigation: ${(_analysisResult != null) ? 'ResultsScreen included' : 'ResultsScreen NOT included'}");
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          print("✅ DEBUG: Navigation to results initiated");
        }
      } else {
        print("❌ DEBUG: No analysis result available - navigation blocked");
        print("🔍 DEBUG: Provider lastAnalysis is null despite analysis completion");
      }
    } else {
      print("❌ DEBUG: Missing scenario or text support");
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