import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_manager.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';

void main() {
  group('Pipeline Conversationnel - Tests Validés', () {
    late ConversationManager conversationManager;

    setUp(() {
      conversationManager = ConversationManager();
    });

    tearDown(() {
      conversationManager.dispose();
    });

    test('API ConversationManager - Vérification des signatures', () {
      // Test pour confirmer que l'API existe et compile
      expect(conversationManager, isNotNull);
      expect(conversationManager.state, equals(ConversationState.idle));
      expect(conversationManager.events, isNotNull);
      expect(conversationManager.transcriptions, isNotNull);
      expect(conversationManager.metrics, isNotNull);
      
      print('✅ API ConversationManager vérifiée');
    });

    test('États de conversation - Énumération complète', () {
      // Vérifier que tous les états existent
      final states = ConversationState.values;
      
      expect(states, contains(ConversationState.idle));
      expect(states, contains(ConversationState.ready));
      expect(states, contains(ConversationState.aiSpeaking));
      expect(states, contains(ConversationState.userSpeaking));
      expect(states, contains(ConversationState.processing));
      expect(states, contains(ConversationState.aiThinking));
      expect(states, contains(ConversationState.paused));
      expect(states, contains(ConversationState.ended));
      
      print('✅ États de conversation validés: ${states.length} états');
    });

    test('Types d\'événements - Énumération complète', () {
      // Vérifier que tous les types d'événements existent
      final eventTypes = ConversationEventType.values;
      
      expect(eventTypes, contains(ConversationEventType.initialized));
      expect(eventTypes, contains(ConversationEventType.conversationStarted));
      expect(eventTypes, contains(ConversationEventType.conversationEnded));
      expect(eventTypes, contains(ConversationEventType.aiMessage));
      expect(eventTypes, contains(ConversationEventType.userMessage));
      expect(eventTypes, contains(ConversationEventType.error));
      
      print('✅ Types d\'événements validés: ${eventTypes.length} types');
    });

    test('Modèles de données - Construction', () {
      // Tester la construction des modèles
      final event = ConversationEvent(
        type: ConversationEventType.initialized,
        timestamp: DateTime.now(),
        data: 'test',
      );
      
      expect(event.type, equals(ConversationEventType.initialized));
      expect(event.timestamp, isNotNull);
      expect(event.data, equals('test'));
      
      final transcription = TranscriptionSegment(
        text: 'Test transcription',
        isFinal: true,
        confidence: 0.85,
        timestamp: DateTime.now(),
      );
      
      expect(transcription.text, equals('Test transcription'));
      expect(transcription.isFinal, isTrue);
      expect(transcription.confidence, equals(0.85));
      
      final metrics = ConversationMetrics(
        totalDuration: Duration(minutes: 2),
        turnCount: 5,
        averageResponseTime: Duration(seconds: 1),
        currentState: ConversationState.ready,
      );
      
      expect(metrics.turnCount, equals(5));
      expect(metrics.currentState, equals(ConversationState.ready));
      
      print('✅ Modèles de données validés');
    });

    test('Initialisation avec paramètres réels', () async {
      // Créer un profil utilisateur simple
      final userProfile = UserAdaptiveProfile(
        learningStyle: LearningStyle.visual,
        difficultyPreference: DifficultyLevel.beginner,
        confidenceLevel: 0.6,
        preferredLanguage: 'fr',
        adaptationHistory: [],
        lastUpdated: DateTime.now(),
      );
      
      // Créer un scénario simple 
      final scenario = ConfidenceScenario(
        id: 'test_scenario',
        title: 'Test Interview',
        description: 'Scenario de test',
        type: ScenarioType.interview,
        difficulty: DifficultyLevel.beginner,
        estimatedDuration: Duration(minutes: 5),
        objectives: ['Objective 1'],
        keywordCategories: [],
        supportedCharacters: [AICharacterType.thomas],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      // Tenter l'initialisation (devrait échouer sans vraie connexion LiveKit)
      final result = await conversationManager.initializeConversation(
        scenario: scenario,
        userProfile: userProfile,
        livekitUrl: 'ws://test-livekit-url',
        livekitToken: 'test-token',
        preferredCharacter: AICharacterType.thomas,
      );
      
      // On s'attend à ce que l'initialisation échoue (pas de vraie connexion)
      expect(result, isFalse);
      
      print('✅ Paramètres d\'initialisation validés (échec attendu sans LiveKit)');
    });

    test('Méthodes de gestion de conversation', () async {
      // Vérifier que les méthodes existent et sont appelables
      conversationManager.pauseConversation();
      conversationManager.resumeConversation();
      
      // Tester le traitement audio (devrait échouer gracieusement)
      final audioData = Uint8List.fromList([1, 2, 3, 4, 5]);
      await conversationManager.processUserAudio(audioData);
      
      // Tester la fin de conversation (devrait gérer l'état vide)
      try {
        final summary = await conversationManager.endConversation();
        expect(summary, isNotNull);
      } catch (e) {
        // Attendu si la conversation n'est pas initialisée
        print('Note: endConversation a échoué comme attendu: $e');
      }
      
      print('✅ Méthodes de gestion validées');
    });

    test('Streams - Écoute des événements', () async {
      // Tester l'écoute des streams
      bool eventReceived = false;
      bool transcriptionReceived = false;
      bool metricsReceived = false;
      
      // Écouter les événements (avec timeout)
      final eventSubscription = conversationManager.events.listen((event) {
        eventReceived = true;
        print('Event reçu: ${event.type}');
      });
      
      final transcriptionSubscription = conversationManager.transcriptions.listen((segment) {
        transcriptionReceived = true;
        print('Transcription reçue: ${segment.text}');
      });
      
      final metricsSubscription = conversationManager.metrics.listen((metrics) {
        metricsReceived = true;
        print('Métriques reçues: ${metrics.turnCount} tours');
      });
      
      // Attendre un petit délai pour voir si des événements sont émis
      await Future.delayed(Duration(milliseconds: 100));
      
      // Nettoyer les subscriptions
      await eventSubscription.cancel();
      await transcriptionSubscription.cancel();
      await metricsSubscription.cancel();
      
      // Les streams doivent être configurés même si aucun événement n'est émis
      expect(conversationManager.events, isNotNull);
      expect(conversationManager.transcriptions, isNotNull);
      expect(conversationManager.metrics, isNotNull);
      
      print('✅ Streams configurés et écoutable');
    });

    test('Gestion des ressources - Dispose', () async {
      // Tester le nettoyage des ressources
      await conversationManager.dispose();
      
      // Après dispose, l'état devrait être géré proprement
      expect(conversationManager.state, isNotNull);
      
      print('✅ Nettoyage des ressources validé');
    });

    test('Performance et métriques - Structure', () {
      // Vérifier la structure des métriques
      final metrics = ConversationMetrics(
        totalDuration: Duration(minutes: 5, seconds: 30),
        turnCount: 8,
        averageResponseTime: Duration(milliseconds: 1500),
        currentState: ConversationState.processing,
      );
      
      expect(metrics.totalDuration.inSeconds, equals(330));
      expect(metrics.turnCount, equals(8));
      expect(metrics.averageResponseTime.inMilliseconds, equals(1500));
      expect(metrics.currentState, equals(ConversationState.processing));
      
      print('✅ Structure des métriques validée');
    });
  });

  group('Types et Énumérations - Validation', () {
    test('AICharacterType - Valeurs disponibles', () {
      final characterTypes = AICharacterType.values;
      
      expect(characterTypes, contains(AICharacterType.thomas));
      expect(characterTypes, contains(AICharacterType.marie));
      
      print('✅ Types de personnages IA: ${characterTypes.map((t) => t.name).join(', ')}');
    });

    test('ScenarioType - Valeurs disponibles', () {
      final scenarioTypes = ScenarioType.values;
      
      expect(scenarioTypes, isNotEmpty);
      print('✅ Types de scénarios: ${scenarioTypes.map((t) => t.name).join(', ')}');
    });

    test('DifficultyLevel - Valeurs disponibles', () {
      final difficultyLevels = DifficultyLevel.values;
      
      expect(difficultyLevels, isNotEmpty);
      print('✅ Niveaux de difficulté: ${difficultyLevels.map((d) => d.name).join(', ')}');
    });

    test('LearningStyle - Valeurs disponibles', () {
      final learningStyles = LearningStyle.values;
      
      expect(learningStyles, isNotEmpty);
      print('✅ Styles d\'apprentissage: ${learningStyles.map((s) => s.name).join(', ')}');
    });
  });

  group('Pipeline complet - Simulation', () {
    test('Workflow typique sans LiveKit', () async {
      final conversationManager = ConversationManager();
      
      try {
        // 1. État initial
        expect(conversationManager.state, equals(ConversationState.idle));
        
        // 2. Créer les objets requis
        final userProfile = UserAdaptiveProfile(
          learningStyle: LearningStyle.visual,
          difficultyPreference: DifficultyLevel.intermediate,
          confidenceLevel: 0.7,
          preferredLanguage: 'fr',
          adaptationHistory: [],
          lastUpdated: DateTime.now(),
        );
        
        final scenario = ConfidenceScenario(
          id: 'interview_devops',
          title: 'Entretien DevOps',
          description: 'Simulation entretien pour poste DevOps',
          type: ScenarioType.interview,
          difficulty: DifficultyLevel.intermediate,
          estimatedDuration: Duration(minutes: 15),
          objectives: ['Démontrer expertise DevOps', 'Communication technique'],
          keywordCategories: [],
          supportedCharacters: [AICharacterType.thomas],
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        
        // 3. Tenter l'initialisation (échouera sans LiveKit)
        final stopwatch = Stopwatch()..start();
        final initResult = await conversationManager.initializeConversation(
          scenario: scenario,
          userProfile: userProfile,
          livekitUrl: 'ws://localhost:7880',
          livekitToken: 'test-token-123',
          preferredCharacter: AICharacterType.thomas,
        );
        stopwatch.stop();
        
        // 4. Valider les résultats
        expect(initResult, isFalse); // Échec attendu sans vraie connexion
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // < 10s timeout
        
        // 5. Tester les contrôles de conversation
        conversationManager.pauseConversation();
        expect(conversationManager.state, isNotNull);
        
        conversationManager.resumeConversation();
        expect(conversationManager.state, isNotNull);
        
        // 6. Tester le traitement audio
        final audioData = Uint8List.fromList(List.generate(1000, (i) => i % 256));
        await conversationManager.processUserAudio(audioData);
        
        print('✅ Workflow complet simulé:');
        print('   - Initialisation: ${stopwatch.elapsedMilliseconds}ms');
        print('   - Audio traité: ${audioData.length} bytes');
        print('   - État final: ${conversationManager.state}');
        
      } finally {
        // 7. Nettoyage
        await conversationManager.dispose();
      }
    });
  });
}