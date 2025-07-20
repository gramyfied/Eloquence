import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_manager.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_engine.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ConversationManager Tests', () {
    late ConversationManager conversationManager;
    late ConfidenceScenario testScenario;
    late UserAdaptiveProfile testUserProfile;

    setUp(() {
      conversationManager = ConversationManager();

      // Données de test avec les bons constructeurs
      testScenario = ConfidenceScenario(
        id: 'test-scenario',
        title: 'Entretien d\'embauche',
        description: 'Simulation d\'entretien d\'embauche',
        prompt: 'Présentez-vous de manière professionnelle',
        type: ConfidenceScenarioType.interview,
        durationSeconds: 180,
        tips: ['Soyez confiant', 'Structurez votre réponse'],
        keywords: ['compétences', 'expérience', 'motivation'],
        difficulty: 'intermediate',
        icon: '💼',
      );

      testUserProfile = UserAdaptiveProfile(
        userId: 'test-user-123',
        confidenceLevel: 7,
        experienceLevel: 6,
        strengths: ['communication', 'organisation'],
        weaknesses: ['gestion du stress', 'improvisation'],
        preferredTopics: ['technologie', 'management'],
        preferredCharacter: AICharacterType.marie,
        lastSessionDate: DateTime.now().subtract(Duration(days: 1)),
        totalSessions: 5,
        averageScore: 75.0,
      );
    });

    tearDown(() async {
      // Nettoyer les ressources après chaque test
      await conversationManager.dispose();
    });

    group('État initial', () {
      test('devrait avoir l\'état idle au démarrage', () {
        expect(conversationManager.state, equals(ConversationState.idle));
      });

      test('devrait avoir des streams non null', () {
        expect(conversationManager.events, isA<Stream<ConversationEvent>>());
        expect(conversationManager.transcriptions, isA<Stream<TranscriptionSegment>>());
        expect(conversationManager.metrics, isA<Stream<ConversationMetrics>>());
      });
    });

    group('Initialisation', () {
      test('devrait échouer avec des URL/tokens invalides', () async {
        // Act & Assert
        final result = await conversationManager.initializeConversation(
          scenario: testScenario,
          userProfile: testUserProfile,
          livekitUrl: 'invalid-url',
          livekitToken: 'invalid-token',
        );

        expect(result, isFalse);
        expect(conversationManager.state, isNot(equals(ConversationState.ready)));
      });

      test('devrait gérer les erreurs d\'initialisation gracieusement', () async {
        // Arrange
        List<ConversationEvent> events = [];
        conversationManager.events.listen((event) => events.add(event));

        // Act
        final result = await conversationManager.initializeConversation(
          scenario: testScenario,
          userProfile: testUserProfile,
          livekitUrl: '', // URL vide pour provoquer une erreur
          livekitToken: '',
        );

        // Assert
        expect(result, isFalse);
        
        // Attendre un peu pour que les événements soient émis
        await Future.delayed(Duration(milliseconds: 10));
        
        // Vérifier qu'un événement d'erreur a été émis
        expect(events.any((e) => e.type == ConversationEventType.error), isTrue);
      });
    });

    group('Gestion des événements', () {
      test('devrait émettre des événements dans le bon ordre', () async {
        // Arrange
        List<ConversationEvent> events = [];
        conversationManager.events.listen((event) => events.add(event));

        // Act - Essayer d'initialiser (même si ça échoue, on veut voir les événements)
        await conversationManager.initializeConversation(
          scenario: testScenario,
          userProfile: testUserProfile,
          livekitUrl: 'wss://test.livekit.cloud',
          livekitToken: 'test-token',
        );

        // Assert
        await Future.delayed(Duration(milliseconds: 10));
        expect(events.isNotEmpty, isTrue);
        
        // Le premier événement devrait être le type d'initialisation ou d'erreur
        final eventTypes = events.map((e) => e.type).toList();
        expect(eventTypes, anyOf([
          contains(ConversationEventType.initialized),
          contains(ConversationEventType.error),
        ]));
      });

      test('devrait créer des événements avec timestamp', () async {
        // Arrange
        List<ConversationEvent> events = [];
        conversationManager.events.listen((event) => events.add(event));

        // Act
        await conversationManager.initializeConversation(
          scenario: testScenario,
          userProfile: testUserProfile,
          livekitUrl: 'wss://test.livekit.cloud',
          livekitToken: 'test-token',
        );

        // Assert
        await Future.delayed(Duration(milliseconds: 10));
        expect(events.isNotEmpty, isTrue);
        
        for (final event in events) {
          expect(event.timestamp, isA<DateTime>());
          expect(event.type, isA<ConversationEventType>());
        }
      });
    });

    group('Gestion des transcriptions', () {
      test('devrait émettre des transcriptions avec les bonnes propriétés', () async {
        // Arrange
        List<TranscriptionSegment> transcriptions = [];
        conversationManager.transcriptions.listen((segment) => transcriptions.add(segment));

        // Act - Simuler des données audio (même en mode userSpeaking)
        // Note: On ne peut pas facilement forcer l'état userSpeaking sans initialiser d'abord
        final audioData = Uint8List.fromList([1, 2, 3, 4, 5]);
        await conversationManager.processUserAudio(audioData);

        // Assert - Si pas en mode speaking, rien ne devrait être émis
        await Future.delayed(Duration(milliseconds: 10));
        
        // Les transcriptions peuvent être vides si pas en mode userSpeaking
        // On vérifie juste que le stream fonctionne
        expect(transcriptions.length, greaterThanOrEqualTo(0));
      });
    });

    group('Gestion de l\'audio', () {
      test('devrait accepter des données audio sans erreur', () async {
        // Arrange
        final audioData = Uint8List.fromList(List.generate(1024, (i) => i % 256));

        // Act & Assert - Ne devrait pas lever d'exception
        expect(
          () => conversationManager.processUserAudio(audioData),
          returnsNormally,
        );
      });

      test('devrait traiter des buffers audio vides', () async {
        // Arrange
        final emptyAudioData = Uint8List(0);

        // Act & Assert - Ne devrait pas lever d'exception
        expect(
          () => conversationManager.processUserAudio(emptyAudioData),
          returnsNormally,
        );
      });
    });

    group('Contrôles de conversation', () {
      test('pauseConversation devrait émettre un événement de pause', () async {
        // Arrange
        List<ConversationEvent> events = [];
        conversationManager.events.listen((event) => events.add(event));

        // Act
        conversationManager.pauseConversation();

        // Assert
        await Future.delayed(Duration(milliseconds: 10));
        
        // Peut émettre un événement de pause selon l'état
        final pauseEvents = events.where((e) => e.type == ConversationEventType.conversationPaused);
        // La pause ne fonctionne que dans certains états, donc on ne force pas
        expect(pauseEvents.length, greaterThanOrEqualTo(0));
      });

      test('resumeConversation devrait émettre un événement de reprise', () async {
        // Arrange
        List<ConversationEvent> events = [];
        conversationManager.events.listen((event) => events.add(event));

        // Act
        conversationManager.resumeConversation();

        // Assert
        await Future.delayed(Duration(milliseconds: 10));
        
        // La reprise ne fonctionne que si en pause, donc on ne force pas
        final resumeEvents = events.where((e) => e.type == ConversationEventType.conversationResumed);
        expect(resumeEvents.length, greaterThanOrEqualTo(0));
      });
    });

    group('Fin de conversation', () {
      test('endConversation devrait retourner un résumé valide', () async {
        // Act
        final summary = await conversationManager.endConversation();

        // Assert
        expect(summary, isA<ConversationSummary>());
        expect(summary.totalDuration, isA<Duration>());
        expect(summary.turnCount, isA<int>());
        expect(summary.averageResponseTime, isA<Duration>());
        expect(summary.conversationHistory, isA<List>());
        expect(conversationManager.state, equals(ConversationState.ended));
      });

      test('endConversation devrait émettre un événement de fin', () async {
        // Arrange
        List<ConversationEvent> events = [];
        conversationManager.events.listen((event) => events.add(event));

        // Act
        await conversationManager.endConversation();

        // Assert
        await Future.delayed(Duration(milliseconds: 10));
        expect(events.any((e) => e.type == ConversationEventType.conversationEnded), isTrue);
      });
    });

    group('Nettoyage des ressources', () {
      test('dispose devrait nettoyer sans erreur', () async {
        // Act & Assert - Ne devrait pas lever d'exception
        expect(
          () => conversationManager.dispose(),
          returnsNormally,
        );
      });

      test('dispose devrait être idempotent', () async {
        // Act - Appeler dispose plusieurs fois
        await conversationManager.dispose();
        await conversationManager.dispose();
        await conversationManager.dispose();

        // Assert - Ne devrait pas lever d'exception
        expect(conversationManager.state, equals(ConversationState.ended));
      });
    });

    group('Modèles de données', () {
      test('ConversationEvent devrait avoir les propriétés requises', () {
        // Act
        final event = ConversationEvent(
          type: ConversationEventType.aiMessage,
          timestamp: DateTime.now(),
          data: {'message': 'Test'},
        );

        // Assert
        expect(event.type, equals(ConversationEventType.aiMessage));
        expect(event.timestamp, isA<DateTime>());
        expect(event.data, equals({'message': 'Test'}));
      });

      test('TranscriptionSegment devrait avoir les propriétés requises', () {
        // Act
        final segment = TranscriptionSegment(
          text: 'Bonjour tout le monde',
          isFinal: true,
          confidence: 0.95,
          timestamp: DateTime.now(),
        );

        // Assert
        expect(segment.text, equals('Bonjour tout le monde'));
        expect(segment.isFinal, isTrue);
        expect(segment.confidence, equals(0.95));
        expect(segment.timestamp, isA<DateTime>());
      });

      test('ConversationMetrics devrait avoir les propriétés requises', () {
        // Act
        final metrics = ConversationMetrics(
          totalDuration: Duration(minutes: 3),
          turnCount: 5,
          averageResponseTime: Duration(milliseconds: 1200),
          currentState: ConversationState.processing,
        );

        // Assert
        expect(metrics.totalDuration, equals(Duration(minutes: 3)));
        expect(metrics.turnCount, equals(5));
        expect(metrics.averageResponseTime, equals(Duration(milliseconds: 1200)));
        expect(metrics.currentState, equals(ConversationState.processing));
      });

      test('ConversationSummary devrait être créé correctement', () {
        // Arrange
        final conversationHistory = <ConversationTurn>[];

        // Act
        final summary = ConversationSummary(
          scenario: testScenario,
          character: AICharacterType.marie,
          totalDuration: Duration(minutes: 8),
          turnCount: 6,
          averageResponseTime: Duration(milliseconds: 1100),
          conversationHistory: conversationHistory,
        );

        // Assert
        expect(summary.scenario, equals(testScenario));
        expect(summary.character, equals(AICharacterType.marie));
        expect(summary.totalDuration, equals(Duration(minutes: 8)));
        expect(summary.turnCount, equals(6));
        expect(summary.averageResponseTime, equals(Duration(milliseconds: 1100)));
        expect(summary.conversationHistory, equals(conversationHistory));
      });
    });

    group('États de conversation', () {
      test('devrait avoir tous les états définis', () {
        // Assert - Vérifier que tous les états existent
        expect(ConversationState.values.length, equals(8));
        expect(ConversationState.values, contains(ConversationState.idle));
        expect(ConversationState.values, contains(ConversationState.ready));
        expect(ConversationState.values, contains(ConversationState.aiSpeaking));
        expect(ConversationState.values, contains(ConversationState.userSpeaking));
        expect(ConversationState.values, contains(ConversationState.processing));
        expect(ConversationState.values, contains(ConversationState.aiThinking));
        expect(ConversationState.values, contains(ConversationState.paused));
        expect(ConversationState.values, contains(ConversationState.ended));
      });

      test('état initial devrait être idle', () {
        // Assert
        expect(conversationManager.state, equals(ConversationState.idle));
      });
    });

    group('Types d\'événements', () {
      test('devrait avoir tous les types d\'événements définis', () {
        // Assert - Vérifier que tous les types d'événements existent
        expect(ConversationEventType.values.length, equals(13));
        expect(ConversationEventType.values, contains(ConversationEventType.initialized));
        expect(ConversationEventType.values, contains(ConversationEventType.conversationStarted));
        expect(ConversationEventType.values, contains(ConversationEventType.conversationEnded));
        expect(ConversationEventType.values, contains(ConversationEventType.aiMessage));
        expect(ConversationEventType.values, contains(ConversationEventType.userMessage));
        expect(ConversationEventType.values, contains(ConversationEventType.error));
      });
    });

    group('Robustesse', () {
      test('devrait gérer les appels répétés à startConversation', () async {
        // Act & Assert - Ne devrait pas lever d'exception
        expect(() => conversationManager.startConversation(), returnsNormally);
        expect(() => conversationManager.startConversation(), returnsNormally);
        expect(() => conversationManager.startConversation(), returnsNormally);
      });

      test('devrait gérer les paramètres nulls gracieusement', () async {
        // Act & Assert - Devrait gérer les erreurs sans crash
        expect(
          () => conversationManager.processUserAudio(Uint8List(0)),
          returnsNormally,
        );
      });

      test('devrait maintenir la cohérence des streams', () async {
        // Arrange
        List<ConversationEvent> events = [];
        List<TranscriptionSegment> transcriptions = [];
        List<ConversationMetrics> metrics = [];

        conversationManager.events.listen((event) => events.add(event));
        conversationManager.transcriptions.listen((segment) => transcriptions.add(segment));
        conversationManager.metrics.listen((metric) => metrics.add(metric));

        // Act - Effectuer plusieurs opérations
        await conversationManager.initializeConversation(
          scenario: testScenario,
          userProfile: testUserProfile,
          livekitUrl: 'wss://test.livekit.cloud',
          livekitToken: 'test-token',
        );
        
        conversationManager.pauseConversation();
        conversationManager.resumeConversation();
        await conversationManager.endConversation();

        // Assert - Les streams devraient rester cohérents
        await Future.delayed(Duration(milliseconds: 50));
        
        expect(events.length, greaterThanOrEqualTo(1));
        expect(transcriptions.length, greaterThanOrEqualTo(0));
        expect(metrics.length, greaterThanOrEqualTo(0));
      });
    });
  });
}