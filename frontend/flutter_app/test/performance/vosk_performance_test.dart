import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/core/services/universal_speech_analysis_service.dart';
import 'dart:typed_data';
import 'package:eloquence_2_0/features/shared/analysis/domain/exercise_config.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';


void main() {
  group('Vosk Performance Tests', () {
    late UniversalSpeechAnalysisService service;

    setUp(() {
      service = UniversalSpeechAnalysisService();
    });

    test('should complete analysis in under 2 seconds', () async {
      // Arrange
      final audioData = _generateTestAudioData();
      final config = ExerciseConfig.confidence(
        scenario: ConfidenceScenario(id: '1', title: 'Test', description: 'Test desc', difficulty: 'easy', keywords: [], tips: [], prompt: '', type: ConfidenceScenarioType.presentation, durationSeconds: 60, icon: ''),
      );

      // Act
      final stopwatch = Stopwatch()..start();
      final result = await service.analyzeAudio(
        audioData: audioData,
        exerciseType: 'confidence',
        config: config,
      );
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(result.processingTimeMs, lessThan(2000));
      expect(result.isError, false);
    });

    test('should handle health check quickly', () async {
      // Act
      final stopwatch = Stopwatch()..start();
      final isHealthy = await service.checkHealth();
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(isHealthy, isA<bool>());
    });
  });
}

Uint8List _generateTestAudioData() {
  // Générer des données audio de test
  return Uint8List.fromList(List.generate(16000, (i) => i % 256));
}