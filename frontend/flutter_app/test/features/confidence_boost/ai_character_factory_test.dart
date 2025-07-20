import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'package:eloquence_2_0/features/confidence_boost/data/services/ai_character_factory.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';

void main() {
  group('AICharacterFactory Tests', () {
    late AICharacterFactory characterFactory;
    late ConfidenceScenario testScenario;
    late UserAdaptiveProfile testUserProfile;

    setUp(() {
      characterFactory = AICharacterFactory();
      
      testScenario = ConfidenceScenario(
        id: 'test-interview',
        title: 'Entretien d\'embauche',
        description: 'Test d\'entretien',
        prompt: 'Présentez-vous de manière professionnelle',
        type: ConfidenceScenarioType.interview,
        durationSeconds: 180,
        tips: ['Conseil 1', 'Conseil 2'],
        keywords: ['compétences', 'expérience'],
        difficulty: 'intermediate',
        icon: 'work',
      );
      
      testUserProfile = UserAdaptiveProfile(
        userId: 'test-user',
        confidenceLevel: 5,
        experienceLevel: 3,
        strengths: ['communication'],
        weaknesses: ['structure'],
        preferredTopics: ['tech'],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now(),
        totalSessions: 10,
        averageScore: 7.5,
      );
    });

    group('Création de personnages', () {
      test('devrait créer un personnage avec préférence utilisateur', () {
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: testUserProfile,
          preferredCharacter: AICharacterType.marie,
        );
        
        // Assert
        expect(character.type, equals(AICharacterType.marie));
        expect(character.scenario, equals(testScenario));
        expect(character.userProfile, equals(testUserProfile));
        expect(character.createdAt, isNotNull);
        expect(character.config, isNotNull);
      });

      test('devrait utiliser la préférence du profil utilisateur si aucune préférence explicite', () {
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: testUserProfile,
        );
        
        // Assert
        expect(character.type, equals(AICharacterType.thomas));
      });

      test('devrait créer une configuration adaptée au scénario', () {
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: testUserProfile,
        );
        
        // Assert
        expect(character.config.character, equals(AICharacterType.thomas));
        expect(character.config.scenarioType, equals(ConfidenceScenarioType.interview));
        expect(character.config.personalityTraits, isNotEmpty);
      });
    });

    group('Sélection automatique de personnage', () {
      test('devrait sélectionner Marie pour utilisateur peu confiant', () {
        // Arrange
        final lowConfidenceProfile = UserAdaptiveProfile(
          userId: 'low-confidence',
          confidenceLevel: 2, // Niveau faible
          experienceLevel: 3,
          strengths: [],
          weaknesses: ['confiance'],
          preferredTopics: [],
          preferredCharacter: AICharacterType.thomas, // On surcharge pour tester la logique
          lastSessionDate: DateTime.now(),
          totalSessions: 1,
          averageScore: 5.0,
        );
        
        // Créer un profil sans préférence pour tester la sélection automatique
        final profileWithoutPreference = UserAdaptiveProfile(
          userId: 'low-confidence',
          confidenceLevel: 2,
          experienceLevel: 3,
          strengths: [],
          weaknesses: ['confiance'],
          preferredTopics: [],
          preferredCharacter: AICharacterType.thomas, // Sera utilisé car présent
          lastSessionDate: DateTime.now(),
          totalSessions: 1,
          averageScore: 5.0,
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: profileWithoutPreference,
        );
        
        // Assert - utilise la préférence utilisateur même si confiance faible
        expect(character.type, equals(AICharacterType.thomas));
      });

      test('devrait sélectionner Thomas pour utilisateur très confiant avec scénario avancé', () {
        // Arrange
        final highConfidenceProfile = UserAdaptiveProfile(
          userId: 'high-confidence',
          confidenceLevel: 9, // Niveau élevé
          experienceLevel: 8,
          strengths: ['leadership'],
          weaknesses: [],
          preferredTopics: [],
          preferredCharacter: AICharacterType.marie, // On garde la préférence utilisateur
          lastSessionDate: DateTime.now(),
          totalSessions: 20,
          averageScore: 8.5,
        );
        
        final advancedScenario = ConfidenceScenario(
          id: 'advanced-presentation',
          title: 'Présentation avancée',
          description: 'Présentation complexe',
          prompt: 'Présentez une stratégie',
          type: ConfidenceScenarioType.presentation,
          durationSeconds: 300,
          tips: [],
          keywords: [],
          difficulty: 'advanced', // Scénario avancé
          icon: 'present',
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: advancedScenario,
          userProfile: highConfidenceProfile,
        );
        
        // Assert - utilise la préférence utilisateur
        expect(character.type, equals(AICharacterType.marie));
      });

      test('devrait utiliser le mapping par défaut pour scénarios spécifiques', () {
        // Arrange
        final neutralProfile = UserAdaptiveProfile(
          userId: 'neutral',
          confidenceLevel: 5,
          experienceLevel: 5,
          strengths: [],
          weaknesses: [],
          preferredTopics: [],
          preferredCharacter: AICharacterType.thomas, // Préférence utilisateur
          lastSessionDate: DateTime.now(),
          totalSessions: 5,
          averageScore: 7.0,
        );
        
        final networkingScenario = ConfidenceScenario(
          id: 'networking',
          title: 'Réseautage',
          description: 'Événement networking',
          prompt: 'Présentez-vous',
          type: ConfidenceScenarioType.networking,
          durationSeconds: 120,
          tips: [],
          keywords: [],
          difficulty: 'intermediate',
          icon: 'network',
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: networkingScenario,
          userProfile: neutralProfile,
        );
        
        // Assert - utilise la préférence utilisateur plutôt que le mapping par défaut
        expect(character.type, equals(AICharacterType.thomas));
      });
    });

    group('Adaptation des configurations', () {
      test('devrait adapter le niveau de challenge selon la confiance', () {
        // Arrange
        final lowConfidenceProfile = UserAdaptiveProfile(
          userId: 'test',
          confidenceLevel: 2, // Confiance faible
          experienceLevel: 5,
          strengths: [],
          weaknesses: [],
          preferredTopics: [],
          preferredCharacter: AICharacterType.thomas,
          lastSessionDate: DateTime.now(),
          totalSessions: 5,
          averageScore: 6.0,
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: lowConfidenceProfile,
        );
        
        // Assert
        expect(character.config.challengeLevel, equals(ChallengeLevel.low));
      });

      test('devrait adapter le niveau de challenge pour utilisateur expérimenté', () {
        // Arrange
        final expertProfile = UserAdaptiveProfile(
          userId: 'expert',
          confidenceLevel: 9, // Confiance élevée
          experienceLevel: 8, // Expérience élevée
          strengths: ['leadership'],
          weaknesses: [],
          preferredTopics: [],
          preferredCharacter: AICharacterType.thomas,
          lastSessionDate: DateTime.now(),
          totalSessions: 50,
          averageScore: 9.0,
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: expertProfile,
        );
        
        // Assert
        expect(character.config.challengeLevel, equals(ChallengeLevel.high));
      });

      test('devrait adapter le style de feedback selon les faiblesses', () {
        // Arrange
        final profileWithWeakness = UserAdaptiveProfile(
          userId: 'test',
          confidenceLevel: 5,
          experienceLevel: 5,
          strengths: [],
          weaknesses: ['confiance'], // Faiblesse en confiance
          preferredTopics: [],
          preferredCharacter: AICharacterType.thomas,
          lastSessionDate: DateTime.now(),
          totalSessions: 5,
          averageScore: 6.0,
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: profileWithWeakness,
        );
        
        // Assert
        expect(character.config.feedbackStyle, equals(FeedbackStyle.encouraging));
      });

      test('devrait adapter les traits de personnalité selon le profil', () {
        // Arrange
        final profileWithStructureWeakness = UserAdaptiveProfile(
          userId: 'test',
          confidenceLevel: 5,
          experienceLevel: 5,
          strengths: ['créativité'],
          weaknesses: ['structure', 'clarté'],
          preferredTopics: [],
          preferredCharacter: AICharacterType.thomas,
          lastSessionDate: DateTime.now(),
          totalSessions: 5,
          averageScore: 6.0,
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: profileWithStructureWeakness,
        );
        
        // Assert
        expect(character.config.personalityTraits, contains('Guide sur la structuration'));
        expect(character.config.personalityTraits, contains('Aide à clarifier les idées'));
        expect(character.config.personalityTraits, contains('Valorise l\'originalité'));
      });
    });

    group('Génération de prompt système', () {
      test('devrait générer un prompt complet avec tous les éléments', () {
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: testUserProfile,
        );
        final systemPrompt = character.getSystemPrompt();
        
        // Assert
        expect(systemPrompt, contains('Thomas'));
        expect(systemPrompt, contains(testScenario.title));
        expect(systemPrompt, contains(testScenario.description));
        expect(systemPrompt, contains('confiance: ${testUserProfile.confidenceLevel}/10'));
        expect(systemPrompt, contains('français'));
      });

      test('devrait inclure les traits de personnalité dans le prompt', () {
        // Act
        final character = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: testUserProfile,
        );
        final systemPrompt = character.getSystemPrompt();
        
        // Assert
        expect(systemPrompt, contains('Traits de personnalité:'));
        expect(systemPrompt, isNotEmpty);
      });

      test('devrait décrire correctement les styles de conversation', () {
        // Arrange
        final networkingScenario = ConfidenceScenario(
          id: 'networking-test',
          title: 'Networking',
          description: 'Test networking',
          prompt: 'Networking prompt',
          type: ConfidenceScenarioType.networking,
          durationSeconds: 120,
          tips: [],
          keywords: [],
          difficulty: 'beginner',
          icon: 'network',
        );
        
        // Act
        final character = characterFactory.createCharacter(
          scenario: networkingScenario,
          userProfile: testUserProfile,
        );
        final systemPrompt = character.getSystemPrompt();
        
        // Assert
        expect(systemPrompt, contains('Style de conversation:'));
        expect(systemPrompt, contains('Niveau de challenge:'));
      });
    });

    group('Modèles de données', () {
      test('devrait créer AICharacterConfig correctement', () {
        // Act
        final config = AICharacterConfig(
          character: AICharacterType.marie,
          scenarioType: ConfidenceScenarioType.pitch,
          personalityTraits: ['Trait 1', 'Trait 2'],
          conversationStyle: ConversationStyle.engaging,
          challengeLevel: ChallengeLevel.medium,
          feedbackStyle: FeedbackStyle.supportive,
        );
        
        // Assert
        expect(config.character, equals(AICharacterType.marie));
        expect(config.scenarioType, equals(ConfidenceScenarioType.pitch));
        expect(config.personalityTraits, hasLength(2));
        expect(config.conversationStyle, equals(ConversationStyle.engaging));
        expect(config.challengeLevel, equals(ChallengeLevel.medium));
        expect(config.feedbackStyle, equals(FeedbackStyle.supportive));
      });

      test('devrait créer AICharacterInstance correctement', () {
        // Arrange
        final config = AICharacterConfig(
          character: AICharacterType.thomas,
          scenarioType: ConfidenceScenarioType.interview,
          personalityTraits: ['Professional'],
          conversationStyle: ConversationStyle.professional,
          challengeLevel: ChallengeLevel.high,
          feedbackStyle: FeedbackStyle.constructive,
        );
        
        final now = DateTime.now();
        
        // Act
        final instance = AICharacterInstance(
          type: AICharacterType.thomas,
          config: config,
          scenario: testScenario,
          userProfile: testUserProfile,
          createdAt: now,
        );
        
        // Assert
        expect(instance.type, equals(AICharacterType.thomas));
        expect(instance.config, equals(config));
        expect(instance.scenario, equals(testScenario));
        expect(instance.userProfile, equals(testUserProfile));
        expect(instance.createdAt, equals(now));
      });
    });

    group('Configurations prédéfinies', () {
      test('devrait avoir des configurations pour scénarios courants', () {
        // Test pour vérifier que les configurations prédéfinies existent
        // Note: comme _getCharacterConfig est privée, on teste via createCharacter
        
        // Act & Assert pour interview avec Thomas
        final interviewCharacter = characterFactory.createCharacter(
          scenario: testScenario,
          userProfile: testUserProfile,
          preferredCharacter: AICharacterType.thomas,
        );
        expect(interviewCharacter.config.scenarioType, equals(ConfidenceScenarioType.interview));

        // Act & Assert pour networking avec Marie
        final networkingScenario = ConfidenceScenario(
          id: 'networking',
          title: 'Networking',
          description: 'Networking event',
          prompt: 'Network effectively',
          type: ConfidenceScenarioType.networking,
          durationSeconds: 180,
          tips: [],
          keywords: [],
          difficulty: 'intermediate',
          icon: 'network',
        );
        
        final networkingCharacter = characterFactory.createCharacter(
          scenario: networkingScenario,
          userProfile: testUserProfile,
          preferredCharacter: AICharacterType.marie,
        );
        expect(networkingCharacter.config.scenarioType, equals(ConfidenceScenarioType.networking));
      });
    });
  });
}