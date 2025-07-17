import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/core/services/universal_speech_analysis_service.dart';
import 'package:eloquence_2_0/features/shared/analysis/presentation/exercise_analysis_provider.dart';
import 'package:eloquence_2_0/features/shared/analysis/domain/analysis_result.dart';
import 'package:eloquence_2_0/features/shared/analysis/domain/exercise_config.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:typed_data';

class MockUniversalSpeechAnalysisService extends Mock implements UniversalSpeechAnalysisService {}

void main() {
  group('ExerciseAnalysisProvider Tests for Confidence', () {
    late MockUniversalSpeechAnalysisService mockAnalysisService;
    late ProviderContainer container;

    setUp(() {
      mockAnalysisService = MockUniversalSpeechAnalysisService();
      container = ProviderContainer(
        overrides: [
          universalSpeechAnalysisServiceProvider.overrideWithValue(mockAnalysisService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should analyze recording successfully', () async {
      // Arrange
      final audioData = Uint8List.fromList([1, 2, 3, 4]);
      final scenario = ConfidenceScenario(id: '1', title: 'Test', description: 'Test desc', difficulty: 'easy', keywords: [], tips: [], prompt: '', type: ConfidenceScenarioType.presentation, durationSeconds: 60, icon: '');
      final config = ConfidenceConfig(scenario: scenario);
      final expectedResult = AnalysisResult(
        exerciseType: 'confidence',
        transcription: 'Test transcription',
        recognitionDetails: {},
        analysis: {
          'overall_score': 85.0,
          'detailed_scores': {'confidence': 0.9},
          'feedback': 'Excellent travail',
          'recommendations': ['Continuez ainsi'],
        },
        processingTimeMs: 1500.0,
      );

      when(() => mockAnalysisService.analyzeAudio(
        audioData: any(named: 'audioData'),
        exerciseType: 'confidence',
        config: any(named: 'config', that: isA<ConfidenceConfig>()),
      )).thenAnswer((_) async => expectedResult);

      // Act
      await container.read(confidenceAnalysisProvider.notifier).analyzeRecording(
        audioData: audioData,
        config: config,
      );

      // Assert
      final state = container.read(confidenceAnalysisProvider);
      expect(state, isA<AsyncData<AnalysisResult?>>());
      expect(state.value, expectedResult);
    });

    test('should handle analysis error gracefully', () async {
      // Arrange
      final audioData = Uint8List.fromList([1, 2, 3, 4]);
      final scenario = ConfidenceScenario(id: '1', title: 'Test', description: 'Test desc', difficulty: 'easy', keywords: [], tips: [], prompt: '', type: ConfidenceScenarioType.presentation, durationSeconds: 60, icon: '');
      final config = ConfidenceConfig(scenario: scenario);

      when(() => mockAnalysisService.analyzeAudio(
        audioData: any(named: 'audioData'),
        exerciseType: 'confidence',
        config: any(named: 'config', that: isA<ConfidenceConfig>()),
      )).thenThrow(Exception('Network error'));

      // Act
      await container.read(confidenceAnalysisProvider.notifier).analyzeRecording(
        audioData: audioData,
        config: config,
      );

      // Assert
      final state = container.read(confidenceAnalysisProvider);
      expect(state, isA<AsyncError>());
    });
  });
}