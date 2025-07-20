import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/fallback_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';

void main() {
  group('FallbackService Tests', () {
    late FallbackService fallbackService;
    late ConfidenceScenario testScenario;
    late Uint8List mockAudioData;

    setUp(() {
      fallbackService = FallbackService();
      testScenario = ConfidenceScenario(
        id: 'test-scenario',
        title: 'Test Interview',
        description: 'Test scenario for fallback',
        type: ConfidenceScenarioType.interview,
        difficulty: 'intermediate',
        prompt: 'Parlez-nous de votre expérience',
        durationSeconds: 180,
        tips: ['Soyez confiant'],
        keywords: ['expérience', 'compétences', 'motivation'],
        icon: 'interview_icon',
      );
      mockAudioData = Uint8List.fromList(List.generate(5000, (index) => index % 256));
    });

    test('Niveau 1: withLiveKitFallback devrait retenter sur échec', () async {
      int attempts = 0;
      final result = await fallbackService.withLiveKitFallback<String>(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Connection failed');
          }
          return 'Success';
        },
        operationName: 'test_operation',
        maxRetries: 3,
      );

      expect(result, equals('Success'));
      expect(attempts, equals(3));
    });

    test('Niveau 1: withLiveKitFallback devrait retourner null après épuisement des tentatives', () async {
      final result = await fallbackService.withLiveKitFallback<String>(
        operation: () async => throw Exception('Always fails'),
        operationName: 'failing_operation',
        maxRetries: 2,
      );

      expect(result, isNull);
      expect(fallbackService.consecutiveFailures, greaterThan(0));
    });

    test('Niveau 2: withVoskFallback devrait fournir une analyse VOSK directe', () async {
      final result = await fallbackService.withVoskFallback(
        audioData: mockAudioData,
        scenario: testScenario,
        cacheKey: 'test-cache-key',
      );

      expect(result, isNotNull);
      expect(result!.overallConfidenceScore, equals(75));
      expect(result.otherMetrics['transcription'], isNotNull);
      expect(result.otherMetrics['clarity'], equals(0.7));
      expect(result.otherMetrics['isFromFallback'], isTrue);
    });

    test('Niveau 2: withVoskFallback devrait utiliser le cache', () async {
      const cacheKey = 'vosk-test-cache';

      // Premier appel - devrait calculer
      final result1 = await fallbackService.withVoskFallback(
        audioData: mockAudioData,
        scenario: testScenario,
        cacheKey: cacheKey,
      );

      // Deuxième appel - devrait utiliser le cache
      final result2 = await fallbackService.withVoskFallback(
        audioData: mockAudioData,
        scenario: testScenario,
        cacheKey: cacheKey,
      );

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.overallConfidenceScore, equals(result2!.overallConfidenceScore));
    });

    test('Niveau 3: withMistralFallback devrait générer des réponses Thomas', () async {
      final responses = await fallbackService.withMistralFallback(
        userMessage: 'Parlez-moi de votre expérience DevOps',
        characterType: AICharacterType.thomas,
        scenario: testScenario,
      );

      expect(responses, isNotEmpty);
      expect(responses.length, lessThanOrEqualTo(3));
      expect(responses.first, contains(''));
    });

    test('Niveau 3: withMistralFallback devrait générer des réponses Marie', () async {
      final responses = await fallbackService.withMistralFallback(
        userMessage: 'Je suis passionné par la technologie',
        characterType: AICharacterType.marie,
        scenario: testScenario,
      );

      expect(responses, isNotEmpty);
      expect(responses.length, lessThanOrEqualTo(3));
      expect(responses.first, contains(''));
    });

    test('Niveau 3: withMistralFallback devrait utiliser le cache de conversation', () async {
      const cacheKey = 'mistral-test-cache';

      // Premier appel
      final responses1 = await fallbackService.withMistralFallback(
        userMessage: 'Test message',
        characterType: AICharacterType.thomas,
        scenario: testScenario,
        cacheKey: cacheKey,
      );

      // Deuxième appel avec même clé
      final responses2 = await fallbackService.withMistralFallback(
        userMessage: 'Different message',
        characterType: AICharacterType.marie,
        scenario: testScenario,
        cacheKey: cacheKey,
      );

      expect(responses1, equals(responses2)); // Devrait être identique via cache
    });

    test('Niveau 4: getDegradedModeConfig devrait retourner une configuration selon le niveau', () async {
      // Simuler des échecs pour changer le niveau
      for (int i = 0; i < 3; i++) {
        await fallbackService.withLiveKitFallback<String>(
          operation: () async => throw Exception('Fail'),
          operationName: 'test_fail',
          maxRetries: 1,
        );
      }

      final config = fallbackService.getDegradedModeConfig();

      expect(config['fallback_level'], isNotNull);
      expect(config['consecutive_failures'], greaterThan(0));
      expect(config['features_disabled'], isList);
      expect(config['user_message'], isNotEmpty);
      expect(config['retry_enabled'], isA<bool>());
      expect(config['estimated_recovery_time'], isA<Duration>());
    });

    test('reset devrait réinitialiser l\'état du service', () async {
      // Provoquer des échecs
      await fallbackService.withLiveKitFallback<String>(
        operation: () async => throw Exception('Fail'),
        operationName: 'test_fail',
        maxRetries: 1,
      );

      expect(fallbackService.consecutiveFailures, greaterThan(0));

      // Réinitialiser
      await fallbackService.reset();

      expect(fallbackService.consecutiveFailures, equals(0));
      expect(fallbackService.currentLevel, equals(FallbackLevel.normal));
    });

    test('Les niveaux de fallback devraient s\'adapter selon les échecs', () async {
      expect(fallbackService.currentLevel, equals(FallbackLevel.normal));

      // 2 échecs -> limited
      for (int i = 0; i < 2; i++) {
        await fallbackService.withLiveKitFallback<String>(
          operation: () async => throw Exception('Fail'),
          operationName: 'test_fail',
          maxRetries: 1,
        );
      }
      expect(fallbackService.currentLevel, equals(FallbackLevel.limited));

      // 5 échecs -> degraded
      for (int i = 0; i < 3; i++) {
        await fallbackService.withLiveKitFallback<String>(
          operation: () async => throw Exception('Fail'),
          operationName: 'test_fail',
          maxRetries: 1,
        );
      }
      expect(fallbackService.currentLevel, equals(FallbackLevel.degraded));
    });

    test('Extension FallbackLevel devrait fournir les bonnes propriétés', () {
      expect(FallbackLevel.normal.displayName, equals('Normal'));
      expect(FallbackLevel.limited.displayName, equals('Limité'));
      expect(FallbackLevel.degraded.displayName, equals('Dégradé'));
      expect(FallbackLevel.critical.displayName, equals('Critique'));

      expect(FallbackLevel.normal.isOperational, isTrue);
      expect(FallbackLevel.critical.isOperational, isFalse);

      expect(FallbackLevel.normal.allowsAIFeatures, isTrue);
      expect(FallbackLevel.limited.allowsAIFeatures, isTrue);
      expect(FallbackLevel.degraded.allowsAIFeatures, isFalse);
    });
  });
}