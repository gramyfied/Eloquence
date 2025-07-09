import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/text_support_generator.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';

void main() {
  group('TextSupportGenerator Tests d\'Intégration', () {
    late TextSupportGenerator textSupportGenerator;

    // Scénario de test
    final testScenario = ConfidenceScenario(
      id: 'test_scenario',
      title: 'Présentation Produit',
      description: 'Préparer une présentation efficace pour un nouveau produit.',
      prompt: 'Présentez votre nouveau produit innovant à des clients potentiels.',
      type: ConfidenceScenarioType.presentation,
      durationSeconds: 180,
      keywords: ['innovation', 'marché', 'croissance'],
      tips: ['Utiliser des visuels', 'Être concis'],
      difficulty: 'Moyenne',
      icon: '📱',
    );

    setUp(() {
      textSupportGenerator = TextSupportGenerator();
    });

    test('generateSupport génère un TextSupport valide pour fullText', () async {
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: testScenario,
        type: SupportType.fullText,
        difficulty: 'Facile',
      );

      // Assert
      expect(result, isA<TextSupport>());
      expect(result.type, SupportType.fullText);
      expect(result.content, isNotEmpty);
      expect(result.content.length, greaterThan(50)); // Contenu substantiel
      expect(result.suggestedWords, isNotEmpty);
      expect(result.suggestedWords, contains('innovation'));
    });

    test('generateSupport génère un TextSupport valide pour fillInBlanks', () async {
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: testScenario,
        type: SupportType.fillInBlanks,
        difficulty: 'Moyen',
      );

      // Assert
      expect(result, isA<TextSupport>());
      expect(result.type, SupportType.fillInBlanks);
      expect(result.content, isNotEmpty);
      expect(result.content, contains('[BLANK]'));
      expect(result.suggestedWords, isNotEmpty);
      // Test flexible: accepte soit le contenu API soit le fallback
      expect(
        result.suggestedWords.any((word) =>
          word.contains('complétez') || word.contains('innovation')
        ),
        isTrue
      );
    });

    test('generateSupport génère un TextSupport valide pour guidedStructure', () async {
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: testScenario,
        type: SupportType.guidedStructure,
        difficulty: 'Difficile',
      );

      // Assert
      expect(result, isA<TextSupport>());
      expect(result.type, SupportType.guidedStructure);
      expect(result.content, isNotEmpty);
      expect(result.content, contains('1.')); // Structure numérotée
      expect(result.suggestedWords, isNotEmpty);
      // Test flexible: accepte soit le contenu API soit le fallback
      expect(
        result.suggestedWords.any((word) =>
          word.contains('premièrement') || word.contains('innovation')
        ),
        isTrue
      );
    });

    test('generateSupport génère un TextSupport valide pour keywordChallenge', () async {
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: testScenario,
        type: SupportType.keywordChallenge,
        difficulty: 'Facile',
      );

      // Assert
      expect(result, isA<TextSupport>());
      expect(result.type, SupportType.keywordChallenge);
      expect(result.content, isNotEmpty);
      expect(result.content, contains(',')); // Liste de mots séparés par des virgules
      expect(result.suggestedWords, isNotEmpty);
      // Test flexible: accepte soit le contenu API soit le fallback
      expect(
        result.suggestedWords.any((word) =>
          word.contains('défi') || word.contains('innovation')
        ),
        isTrue
      );
    });

    test('generateSupport génère un TextSupport valide pour freeImprovisation', () async {
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: testScenario,
        type: SupportType.freeImprovisation,
        difficulty: 'Moyen',
      );

      // Assert
      expect(result, isA<TextSupport>());
      expect(result.type, SupportType.freeImprovisation);
      expect(result.content, isNotEmpty);
      expect(result.content, contains('•')); // Format de conseils avec puces
      expect(result.suggestedWords, isNotEmpty);
      // Test flexible: accepte soit le contenu API soit le fallback
      expect(
        result.suggestedWords.any((word) =>
          word.contains('spontanéité') || word.contains('innovation')
        ),
        isTrue
      );
    });

    test('generateSupport fonctionne pour tous les niveaux de difficulté', () async {
      final difficulties = ['Facile', 'Moyen', 'Difficile'];
      
      for (final difficulty in difficulties) {
        final result = await textSupportGenerator.generateSupport(
          scenario: testScenario,
          type: SupportType.fullText,
          difficulty: difficulty,
        );

        expect(result, isA<TextSupport>());
        expect(result.content, isNotEmpty);
        expect(result.suggestedWords, isNotEmpty);
      }
    });

    test('generateSupport utilise les mots-clés du scénario dans le contenu suggéré', () async {
      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: testScenario,
        type: SupportType.fullText,
        difficulty: 'Moyen',
      );

      // Assert
      expect(result.suggestedWords, contains('innovation'));
      expect(result.suggestedWords, contains('marché'));
      expect(result.suggestedWords, contains('croissance'));
    });

    test('generateSupport retourne toujours un résultat même en cas d\'erreur potentielle', () async {
      // Test avec un scénario ayant des caractères spéciaux qui pourraient causer des erreurs
      final scenarioComplexe = ConfidenceScenario(
        id: 'test_complexe',
        title: 'Test "Complexe" & Spécial',
        description: 'Description avec caractères spéciaux: éàç & <>',
        prompt: 'Prompt avec caractères spéciaux et "guillemets"',
        type: ConfidenceScenarioType.pitch,
        durationSeconds: 90,
        keywords: ['test', 'spéciaux', 'caractères'],
        tips: ['Attention aux caractères', 'Gérer les erreurs'],
        difficulty: 'Test',
        icon: '🧪',
      );

      // Act
      final result = await textSupportGenerator.generateSupport(
        scenario: scenarioComplexe,
        type: SupportType.fullText,
        difficulty: 'Facile',
      );

      // Assert - Le système doit toujours retourner un TextSupport valide
      expect(result, isA<TextSupport>());
      expect(result.content, isNotEmpty);
      expect(result.type, SupportType.fullText);
    });

    test('generateSupport produit des contenus différents pour différents types', () async {
      // Act - Générer pour tous les types
      final results = <SupportType, TextSupport>{};
      
      for (final type in SupportType.values) {
        results[type] = await textSupportGenerator.generateSupport(
          scenario: testScenario,
          type: type,
          difficulty: 'Moyen',
        );
      }

      // Assert - Vérifier que chaque type a des caractéristiques spécifiques
      expect(results[SupportType.fullText]!.content.length, greaterThan(100));
      expect(results[SupportType.fillInBlanks]!.content, contains('[BLANK]'));
      expect(results[SupportType.guidedStructure]!.content, contains('1.'));
      expect(results[SupportType.keywordChallenge]!.content, contains(','));
      expect(results[SupportType.freeImprovisation]!.content, contains('•'));

      // Vérifier que les contenus sont différents
      final contents = results.values.map((r) => r.content).toSet();
      expect(contents.length, greaterThan(1)); // Au moins 2 contenus différents
    });
  });
}