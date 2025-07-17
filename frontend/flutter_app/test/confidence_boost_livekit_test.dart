import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/confidence_livekit_integration.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fakes/fake_clean_livekit_service.dart';
import 'fakes/fake_api_service.dart';
import 'test_setup.dart';

void main() {
  group('ConfidenceLiveKitIntegration Tests', () {
    setUpAll(() async {
      await setupTestEnvironment();
    });
    late ConfidenceLiveKitIntegration confidenceLiveKit;
    late FakeCleanLiveKitService fakeLiveKitService;
    late FakeApiService fakeApiService;
    late ProviderContainer container;

    setUp(() {
      fakeLiveKitService = FakeCleanLiveKitService();
      fakeApiService = FakeApiService();
      
      container = ProviderContainer(
        overrides: [
          livekitServiceProvider.overrideWithValue(fakeLiveKitService),
          apiServiceProvider.overrideWithValue(fakeApiService),
          // Assurez-vous que tous les providers dont dépend confidenceLiveKitIntegrationProvider sont overridés
        ],
      );

      // Lisez le provider pour obtenir une instance correctement initialisée avec la ref
      confidenceLiveKit = container.read(confidenceLiveKitIntegrationProvider);
    });

    tearDown(() {
      container.dispose();
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
      final result = await confidenceLiveKit.startSession(
        scenario: scenario,
        userContext: 'test_user_context',
        preferredSupportType: textSupport.type,
        livekitUrl: 'ws://mock-livekit-url.com', // Fournir une URL factice
        livekitToken: 'mock_livekit_token', // Fournir un token factice
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
        await confidenceLiveKit.startSession(
          scenario: scenario,
          userContext: 'test_user_context',
          preferredSupportType: textSupport.type,
          livekitUrl: 'ws://mock-livekit-url.com', // Fournir une URL factice
          livekitToken: 'mock_livekit_token', // Fournir un token factice
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