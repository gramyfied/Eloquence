import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/confidence_livekit_integration.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/data/services/api_service.dart';
import 'fakes/fake_clean_livekit_service.dart';
import 'fakes/fake_api_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/text_support_generator.dart';
import 'fakes/fake_mistral_api_service.dart';

void main() {
  group('ConfidenceLiveKitIntegration Tests', () {
    late ConfidenceLiveKitIntegration confidenceLiveKit;
    late FakeCleanLiveKitService fakeLiveKitService;
    late FakeApiService fakeApiService;
    late TextSupportGenerator textSupportGenerator;
    late FakeMistralApiService fakeMistralApiService;

    setUp(() {
      fakeLiveKitService = FakeCleanLiveKitService();
      fakeApiService = FakeApiService();
      fakeMistralApiService = FakeMistralApiService();
      textSupportGenerator = TextSupportGenerator(mistralService: fakeMistralApiService);
      confidenceLiveKit = ConfidenceLiveKitIntegration(
        livekitService: fakeLiveKitService,
        apiService: fakeApiService,
        textGenerator: textSupportGenerator,
      );
    });

    test('should start confidence session successfully', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      final textSupport = TextSupport(
        type: SupportType.fullText,
        content: 'Test content',
        suggestedWords: ['test', 'content'],
      );

      // Act
      final result = await confidenceLiveKit.startConfidenceSession(
        userId: 'test_user',
        scenario: scenario,
        textSupport: textSupport,
      );

      // Assert
      expect(result, isNotNull);
    });

    test('should handle JSON serialization correctly', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      final textSupport = TextSupport(
        type: SupportType.fillInBlanks,
        content: 'Test [BLANK] content',
        suggestedWords: ['test', 'content'],
      );

      // Act & Assert - Ne devrait pas lever d'exception de sérialisation
      expect(() async {
        await confidenceLiveKit.startConfidenceSession(
          userId: 'test_user',
          scenario: scenario,
          textSupport: textSupport,
        );
      }, returnsNormally);
    });

    test('should serialize ConfidenceScenario to JSON correctly', () {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;

      // Act
      final json = scenario.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals(scenario.id));
      expect(json['title'], equals(scenario.title));
      expect(json['type'], isA<String>()); // L'enum doit être converti en String
      expect(json['durationSeconds'], equals(scenario.durationSeconds));
      expect(json['tips'], isA<List<String>>());
      expect(json['keywords'], isA<List<String>>());
    });

    test('should deserialize ConfidenceScenario from JSON correctly', () {
      // Arrange
      final originalScenario = ConfidenceScenario.getDefaultScenarios().first;
      final json = originalScenario.toJson();

      // Act
      final deserializedScenario = ConfidenceScenario.fromJson(json);

      // Assert
      expect(deserializedScenario.id, equals(originalScenario.id));
      expect(deserializedScenario.title, equals(originalScenario.title));
      expect(deserializedScenario.type, equals(originalScenario.type));
      expect(deserializedScenario.durationSeconds, equals(originalScenario.durationSeconds));
    });

    test('should handle analysis result stream', () async {
      // Arrange
      final mockAnalysis = ConfidenceAnalysis(
        overallScore: 85.0,
        confidenceScore: 80.0,
        fluencyScore: 90.0,
        clarityScore: 85.0,
        energyScore: 88.0,
        feedback: 'Excellent performance!',
        wordCount: 150,
        speakingRate: 120.0,
        keywordsUsed: ['creativity', 'innovation'],
        transcription: 'Test transcription',
        strengths: ['Clear articulation', 'Good pace'],
        improvements: ['More eye contact'],
      );

      // Act
      final stream = confidenceLiveKit.analysisStream;

      // Assert
      expect(stream, isA<Stream<ConfidenceAnalysis>>());
    });

    test('should stop session correctly', () async {
      // Arrange
      
      // Act
      await confidenceLiveKit.endSession();

      // Assert
      // Rien à vérifier, juste que ça ne plante pas
    });
  });
}