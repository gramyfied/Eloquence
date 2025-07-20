import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

import 'package:eloquence_2_0/core/services/optimized_http_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/adaptive_ai_character_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_engine.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';

import 'conversation_engine_test.mocks.dart';

// Génération des mocks
@GenerateMocks([
  OptimizedHttpService,
  AdaptiveAICharacterService,
])
void main() {
  group('ConversationEngine Tests', () {
    late ConversationEngine conversationEngine;
    late MockOptimizedHttpService mockHttpService;
    late MockAdaptiveAICharacterService mockAICharacterService;
    late ConfidenceScenario testScenario;
    late UserAdaptiveProfile testUserProfile;

    setUp(() {
      mockHttpService = MockOptimizedHttpService();
      mockAICharacterService = MockAdaptiveAICharacterService();
      
      conversationEngine = ConversationEngine(
        httpService: mockHttpService,
        aiCharacterService: mockAICharacterService,
      );
      
      // Scénario avec tous les champs requis
      testScenario = ConfidenceScenario(
        id: 'test-scenario',
        title: 'Entretien d\'embauche',
        description: 'Test d\'entretien',
        prompt: 'Présentez-vous de manière professionnelle',
        type: ConfidenceScenarioType.interview,
        durationSeconds: 180,
        tips: ['Conseil 1', 'Conseil 2'],
        keywords: ['mot-clé 1', 'mot-clé 2'],
        difficulty: 'intermediate',
        icon: 'work',
      );
      
      // Profil utilisateur avec tous les champs requis
      testUserProfile = UserAdaptiveProfile(
        userId: 'test-user',
        confidenceLevel: 5,
        experienceLevel: 3,
        strengths: ['Force 1', 'Force 2'],
        weaknesses: ['Faiblesse 1'],
        preferredTopics: ['Sujet 1'],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now(),
        totalSessions: 5,
        averageScore: 7.5,
      );
      
      // Setup des mocks directement dans setUp
      // Mock pour AdaptiveAICharacterService
      when(mockAICharacterService.selectOptimalCharacter(
        scenario: anyNamed('scenario'),
        profile: anyNamed('profile'),
        userPreference: anyNamed('userPreference'),
      )).thenReturn(AICharacterType.thomas);
      
      when(mockAICharacterService.initialize()).thenAnswer((_) async {});
      
      when(mockAICharacterService.generateContextualDialogue(
        character: anyNamed('character'),
        phase: anyNamed('phase'),
        context: anyNamed('context'),
        preferredEmotion: anyNamed('preferredEmotion'),
      )).thenAnswer((_) async => AdaptiveDialogue(
        speaker: AICharacterType.thomas,
        message: 'Message IA de test',
        emotionalState: AIEmotionalState.encouraging,
        phase: AIInterventionPhase.scenarioIntroduction,
        priorityLevel: 5,
        triggers: ['trigger1'],
        personalizedVariables: {'var1': 'value1'},
        displayDuration: Duration(seconds: 5),
        requiresUserResponse: true,
      ));
      
      // Mock pour OptimizedHttpService - succès par défaut
      when(mockHttpService.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': 'Réponse Mistral de test'
              }
            }
          ]
        }),
        200,
      ));
    });

    test('devrait s\'initialiser correctement', () async {
      // Act
      await conversationEngine.initialize(
        scenario: testScenario,
        userProfile: testUserProfile,
        preferredCharacter: AICharacterType.thomas,
      );
      
      // Assert
      verify(mockAICharacterService.initialize()).called(1);
      expect(conversationEngine.getConversationHistory(), isEmpty);
    });

    test('devrait utiliser la réponse de fallback en cas d\'erreur réseau', () async {
      // Arrange - Configurer l'erreur pour HTTP
      when(mockHttpService.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        timeout: anyNamed('timeout'),
      )).thenThrow(const SocketException('Erreur réseau simulée'));
      
      await conversationEngine.initialize(
        scenario: testScenario,
        userProfile: testUserProfile,
      );
      
      // Act
      final response = await conversationEngine.generateAIResponse(
        userMessage: 'Message de test',
      );
      
      // Assert - Devrait retourner un fallback (pas l'erreur)
      expect(response.message, isNotEmpty);
      expect(response.character, equals(AICharacterType.thomas));
      expect(response.suggestedUserResponses, isNotEmpty);
    });

    test('devrait gérer l\'historique de conversation', () async {
      // Arrange
      await conversationEngine.initialize(
        scenario: testScenario,
        userProfile: testUserProfile,
      );
      
      // Act
      await conversationEngine.generateAIResponse(userMessage: 'Premier message');
      await conversationEngine.generateAIResponse(userMessage: 'Deuxième message');
      
      // Assert
      final history = conversationEngine.getConversationHistory();
      expect(history.length, equals(4)); // 2 user + 2 AI
      expect(history[0].speaker, equals(ConversationSpeaker.user));
      expect(history[1].speaker, equals(ConversationSpeaker.ai));
    });

    test('devrait réinitialiser correctement', () async {
      // Arrange
      await conversationEngine.initialize(
        scenario: testScenario,
        userProfile: testUserProfile,
      );
      await conversationEngine.generateAIResponse(userMessage: 'Test message');
      
      // Act
      conversationEngine.reset();
      
      // Assert
      expect(conversationEngine.getConversationHistory(), isEmpty);
    });

    test('devrait générer une introduction', () async {
      // Arrange - Mock pour introduction
      when(mockHttpService.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': 'Bonjour ! Je suis Thomas, votre coach pour cet entretien.'
              }
            }
          ]
        }),
        200,
      ));
      
      await conversationEngine.initialize(
        scenario: testScenario,
        userProfile: testUserProfile,
      );
      
      // Act
      final introduction = await conversationEngine.generateIntroduction();
      
      // Assert
      expect(introduction.message, isNotEmpty);
      expect(introduction.character, equals(AICharacterType.thomas));
      expect(introduction.requiresUserResponse, isTrue);
      expect(introduction.suggestedUserResponses, isNotEmpty);
    });

    test('devrait créer des objets ConversationTurn correctement', () {
      // Act
      final turn = ConversationTurn(
        speaker: ConversationSpeaker.ai,
        character: AICharacterType.thomas,
        message: 'Message de test',
        emotionalState: AIEmotionalState.encouraging,
        timestamp: DateTime.now(),
        metadata: {'test': 'data'},
      );
      
      // Assert
      expect(turn.speaker, equals(ConversationSpeaker.ai));
      expect(turn.character, equals(AICharacterType.thomas));
      expect(turn.message, equals('Message de test'));
      expect(turn.emotionalState, equals(AIEmotionalState.encouraging));
      expect(turn.metadata, containsPair('test', 'data'));
    });

    test('devrait créer des objets ConversationResponse correctement', () {
      // Act
      final response = ConversationResponse(
        message: 'Message de réponse',
        character: AICharacterType.marie,
        emotionalState: AIEmotionalState.empathetic,
        suggestedUserResponses: ['Suggestion 1', 'Suggestion 2'],
        requiresUserResponse: true,
      );
      
      // Assert
      expect(response.message, equals('Message de réponse'));
      expect(response.character, equals(AICharacterType.marie));
      expect(response.emotionalState, equals(AIEmotionalState.empathetic));
      expect(response.suggestedUserResponses, hasLength(2));
      expect(response.requiresUserResponse, isTrue);
    });
  });
}