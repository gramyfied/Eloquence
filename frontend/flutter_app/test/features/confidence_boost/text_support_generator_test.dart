import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/text_support_generator.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import '../../fakes/fake_mistral_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/mistral_api_service_provider.dart';
void main() {
  group('TextSupportGenerator Tests', () {
    late TextSupportGenerator textSupportGenerator;
    late FakeMistralApiService fakeMistralService;
    late ProviderContainer container;

    setUp(() {
      fakeMistralService = FakeMistralApiService();
      container = ProviderContainer(
        overrides: [
          mistralApiServiceProvider.overrideWith((ref) => fakeMistralService),
        ],
      );
      final textSupportGeneratorProvider = Provider<TextSupportGenerator>((ref) => TextSupportGenerator.create(ref));
      textSupportGenerator = container.read(textSupportGeneratorProvider);
    });

    test('should generate full text support successfully', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.fullText,
        difficulty: 'beginner',
      );

      // Assert
      expect(result.type, equals(SupportType.fullText));
      expect(result.content, isNotEmpty);
      expect(result.content.length, greaterThan(100));
      expect(result.suggestedWords, isNotEmpty);
      expect(result.content, contains('projet'));
      expect(result.content, contains('initiative'));
    });

    test('should generate fill-in-blanks support with [BLANK] placeholders', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.fillInBlanks,
        difficulty: 'intermediate',
      );

      // Assert
      expect(result.type, equals(SupportType.fillInBlanks));
      expect(result.content, contains('[BLANK]'));
      expect(result.content.split('[BLANK]').length, greaterThan(3)); // Au moins 2 blancs
      expect(result.suggestedWords, isNotEmpty);
    });

    test('should generate guided structure with numbered points', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.guidedStructure,
        difficulty: 'beginner',
      );

      // Assert
      expect(result.type, equals(SupportType.guidedStructure));
      expect(result.content, contains('1.'));
      expect(result.content, contains('2.'));
      expect(result.content, contains('3.'));
      expect(result.content, contains('Introduction'));
      expect(result.suggestedWords, isNotEmpty);
    });

    test('should generate keyword challenge with comma-separated words', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.keywordChallenge,
        difficulty: 'advanced',
      );

      // Assert
      expect(result.type, equals(SupportType.keywordChallenge));
      expect(result.content, contains(','));
      expect(result.content.split(',').length, greaterThanOrEqualTo(6));
      expect(result.content, contains('innovation'));
      expect(result.suggestedWords, isNotEmpty);
    });

    test('should generate free improvisation coaching tips', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.freeImprovisation,
        difficulty: 'intermediate',
      );

      // Assert
      expect(result.type, equals(SupportType.freeImprovisation));
      expect(result.content, contains('•'));
      expect(result.content.split('•').length, greaterThan(3)); // Au moins 3 conseils
      expect(result.content, contains('authentique'));
      expect(result.suggestedWords, isNotEmpty);
    });

    test('should fallback to default content when service fails', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      fakeMistralService.shouldFail = true;
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.fullText,
        difficulty: 'beginner',
      );

      // Assert
      expect(result.type, equals(SupportType.fullText));
      expect(result.content, isNotEmpty);
      expect(result.content, contains('projet'));
      expect(result.suggestedWords, isNotEmpty);
    });

    test('should include scenario keywords in suggested words', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.fullText,
        difficulty: 'beginner',
      );

      // Assert
      expect(result.suggestedWords, isNotEmpty);
      expect(result.suggestedWords.length, lessThanOrEqualTo(6));
      
      // Vérifier que certains mots-clés du scénario sont inclus
      final hasScenarioKeywords = scenario.keywords.any(
        (keyword) => result.suggestedWords.contains(keyword)
      );
      expect(hasScenarioKeywords, isTrue);
    });

    test('should handle custom response from fake service', () async {
      // Arrange
      final scenario = ConfidenceScenario.getDefaultScenarios().first;
      fakeMistralService.customResponse = 'Custom test response for testing';
      
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenario,
        type: SupportType.fullText,
        difficulty: 'beginner',
      );

      // Assert
      expect(result.type, equals(SupportType.fullText));
      expect(result.content, contains('Custom test response'));
      expect(result.suggestedWords, isNotEmpty);
    });
  });
}