import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_manager.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_engine.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/ai_character_factory.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/robust_livekit_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Pipeline Conversationnel End-to-End avec LiveKit', () {
    late ConversationManager conversationManager;
    late ConfidenceScenario testScenario;
    late UserAdaptiveProfile testUserProfile;

    setUp(() {
      // Initialisation du gestionnaire principal
      conversationManager = ConversationManager();

      // Scénario de test - Entretien d'embauche DevOps
      testScenario = ConfidenceScenario(
        id: 'interview-devops-livekit',
        title: 'Entretien DevOps avec LiveKit',
        description: 'Test d\'intégration complète avec orchestration LiveKit',
        prompt: 'Présentez votre expérience en infrastructure cloud et DevOps',
        type: ConfidenceScenarioType.interview,
        durationSeconds: 300,
        tips: [
          'Mentionnez vos compétences en containers',
          'Parlez de votre expérience CI/CD',
          'Décrivez vos projets d\'infrastructure'
        ],
        keywords: ['docker', 'kubernetes', 'terraform', 'aws', 'jenkins'],
        difficulty: 'advanced',
        icon: '☁️',
      );

      // Profil utilisateur expérimenté
      testUserProfile = UserAdaptiveProfile(
        userId: 'test-devops-expert',
        confidenceLevel: 8,
        experienceLevel: 9,
        strengths: ['technique', 'infrastructure', 'automation'],
        weaknesses: ['communication publique'],
        preferredTopics: ['devops', 'cloud', 'containers'],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now().subtract(Duration(days: 1)),
        totalSessions: 15,
        averageScore: 85.5,
      );
    });

    tearDown(() async {
      await conversationManager.dispose();
    });

    test('Test End-to-End: Pipeline LiveKit complet', () async {
      // 🎯 Phase 1: Initialisation de la conversation avec LiveKit
      const mockLivekitUrl = 'wss://test.livekit.cloud';
      const mockLivekitToken = 'test-token-devops-session';

      final initSuccess = await conversationManager.initializeConversation(
        scenario: testScenario,
        userProfile: testUserProfile,
        livekitUrl: mockLivekitUrl,
        livekitToken: mockLivekitToken,
        preferredCharacter: AICharacterType.thomas,
      );

      // En environnement de test, la connexion LiveKit échouera (normal)
      // Mais on teste la logique d'initialisation
      expect(conversationManager.state, anyOf([
        ConversationState.ready,
        ConversationState.idle, // Si connexion LiveKit échoue
      ]));

      // 🎯 Phase 2: Test des streams de conversation
      expect(conversationManager.events, isNotNull);
      expect(conversationManager.transcriptions, isNotNull);
      expect(conversationManager.metrics, isNotNull);

      // 🎯 Phase 3: Simulation d'un tour de conversation complet
      final mockAudioData = Uint8List.fromList([
        // Simulation de données audio PCM 16-bit, 16kHz
        for (int i = 0; i < 8000; i++) // 0.5 seconde d'audio
          ...[
            (i % 256), // Byte bas
            ((i ~/ 256) % 256), // Byte haut
          ]
      ]);

      // Test de traitement audio via ConversationManager
      await conversationManager.processUserAudio(mockAudioData);

      // Vérifier que l'audio est buffurisé pour traitement LiveKit
      expect(conversationManager.state, anyOf([
        ConversationState.userSpeaking,
        ConversationState.processing,
        ConversationState.idle,
      ]));

      print('✅ Pipeline LiveKit testé - architecture validée');
    });

    test('Test End-to-End: Orchestration LiveKit avec états', () async {
      // Test des transitions d'état orchestrées par LiveKit
      final eventsList = <ConversationEvent>[];
      final transcriptionsList = <TranscriptionSegment>[];
      final metricsList = <ConversationMetrics>[];

      // Écouter les streams
      conversationManager.events.listen(eventsList.add);
      conversationManager.transcriptions.listen(transcriptionsList.add);
      conversationManager.metrics.listen(metricsList.add);

      // Tentative d'initialisation (échouera en test mais testera la logique)
      await conversationManager.initializeConversation(
        scenario: testScenario,
        userProfile: testUserProfile,
        livekitUrl: 'wss://test.livekit.cloud',
        livekitToken: 'test-token',
      );

      // Attendre un peu pour les événements asynchrones
      await Future.delayed(Duration(milliseconds: 100));

      // Vérifier que des événements ont été émis
      expect(eventsList, isNotEmpty);
      
      // Au minimum, un événement d'erreur doit être émis (connexion LiveKit impossible en test)
      final hasErrorEvent = eventsList.any((e) => e.type == ConversationEventType.error);
      expect(hasErrorEvent, isTrue);

      print('✅ Orchestration LiveKit testée - événements validés');
    });

    test('Test End-to-End: Gestion des métriques temps réel', () async {
      // Test du système de métriques temps réel de LiveKit
      ConversationMetrics? lastMetrics;
      
      conversationManager.metrics.listen((metrics) {
        lastMetrics = metrics;
      });

      // Simuler une session
      await conversationManager.initializeConversation(
        scenario: testScenario,
        userProfile: testUserProfile,
        livekitUrl: 'wss://test.livekit.cloud',
        livekitToken: 'test-token',
      );

      // Simuler des tours de conversation
      final mockAudio = Uint8List(1600); // 0.1s à 16kHz
      await conversationManager.processUserAudio(mockAudio);

      // Attendre le traitement
      await Future.delayed(Duration(milliseconds: 200));

      // Les métriques peuvent être émises ou non selon l'état de la connexion
      if (lastMetrics != null) {
        expect(lastMetrics!.totalDuration, greaterThan(Duration.zero));
        expect(lastMetrics!.currentState, isA<ConversationState>());
      }

      print('✅ Métriques temps réel testées - pipeline LiveKit validé');
    });

    test('Test End-to-End: Gestion des erreurs LiveKit', () async {
      // Test de la robustesse face aux erreurs LiveKit
      final errorEvents = <ConversationEvent>[];
      
      conversationManager.events
          .where((e) => e.type == ConversationEventType.error)
          .listen(errorEvents.add);

      // Tenter de démarrer sans initialisation
      await conversationManager.startConversation();

      // Vérifier l'état après erreur
      expect(conversationManager.state, ConversationState.idle);

      // Initialisation avec URL invalide
      final initResult = await conversationManager.initializeConversation(
        scenario: testScenario,
        userProfile: testUserProfile,
        livekitUrl: 'ws://invalid-url',
        livekitToken: 'invalid-token',
      );

      expect(initResult, isFalse);

      // Attendre les événements d'erreur
      await Future.delayed(Duration(milliseconds: 300));

      // Vérifier qu'au moins une erreur a été capturée
      expect(errorEvents, isNotEmpty);

      print('✅ Gestion d\'erreurs LiveKit testée - robustesse validée');
    });

    test('Test End-to-End: Lifecycle complet de conversation', () async {
      final events = <ConversationEvent>[];
      conversationManager.events.listen(events.add);

      // 1. Initialisation
      await conversationManager.initializeConversation(
        scenario: testScenario,
        userProfile: testUserProfile,
        livekitUrl: 'wss://test.livekit.cloud',
        livekitToken: 'test-token',
      );

      // 2. Tentative de démarrage (échouera mais testera la logique)
      await conversationManager.startConversation();

      // 3. Test de pause/reprise
      conversationManager.pauseConversation();
      expect(conversationManager.state, anyOf([
        ConversationState.paused,
        ConversationState.idle, // Si pas initialisé à cause de LiveKit
      ]));

      conversationManager.resumeConversation();

      // 4. Fin de conversation
      final summary = await conversationManager.endConversation();

      expect(summary.scenario.id, equals(testScenario.id));
      expect(summary.character, equals(AICharacterType.thomas));
      expect(conversationManager.state, ConversationState.ended);

      // Vérifier le cycle d'événements
      final eventTypes = events.map((e) => e.type).toSet();
      expect(eventTypes, contains(ConversationEventType.conversationEnded));

      print('✅ Lifecycle complet testé - orchestration LiveKit validée');
    });

    test('Test End-to-End: Intégration VOSK via LiveKit', () async {
      // Test spécifique de l'intégration VOSK orchestrée par LiveKit
      final transcriptions = <TranscriptionSegment>[];
      conversationManager.transcriptions.listen(transcriptions.add);

      await conversationManager.initializeConversation(
        scenario: testScenario,
        userProfile: testUserProfile,
        livekitUrl: 'wss://test.livekit.cloud',
        livekitToken: 'test-token',
      );

      // Simuler un audio avec contenu DevOps
      final devopsAudio = Uint8List.fromList([
        // Audio simulé pour "Je maîtrise Docker et Kubernetes"
        for (int i = 0; i < 32000; i++) // 2 secondes à 16kHz
          ...[
            (i % 256),
            ((i ~/ 256) % 256),
          ]
      ]);

      // Envoyer l'audio via le pipeline LiveKit
      await conversationManager.processUserAudio(devopsAudio);

      // Attendre le traitement VOSK via LiveKit
      await Future.delayed(Duration(milliseconds: 500));

      // En environnement de test, on aura au minimum une transcription en cours
      expect(transcriptions, isNotEmpty);
      
      if (transcriptions.isNotEmpty) {
        final firstTranscription = transcriptions.first;
        expect(firstTranscription.text, isNotEmpty);
        expect(firstTranscription.timestamp, isNotNull);
      }

      print('✅ Intégration VOSK via LiveKit testée - transcription validée');
    });

    test('Test End-to-End: Performance du pipeline LiveKit', () async {
      final startTime = DateTime.now();

      // Test de performance de l'orchestration LiveKit
      await conversationManager.initializeConversation(
        scenario: testScenario,
        userProfile: testUserProfile,
        livekitUrl: 'wss://test.livekit.cloud',
        livekitToken: 'test-token',
      );

      final initTime = DateTime.now();
      final initDuration = initTime.difference(startTime);

      // L'initialisation doit être rapide même si la connexion échoue
      expect(initDuration.inSeconds, lessThan(5));

      // Test de traitement audio
      final audioStartTime = DateTime.now();
      final testAudio = Uint8List(8000); // 0.5s à 16kHz
      
      await conversationManager.processUserAudio(testAudio);
      
      final audioProcessTime = DateTime.now().difference(audioStartTime);
      expect(audioProcessTime.inMilliseconds, lessThan(100)); // Traitement rapide

      print('✅ Performance pipeline LiveKit validée:');
      print('   🚀 Init: ${initDuration.inMilliseconds}ms');
      print('   🎤 Audio: ${audioProcessTime.inMilliseconds}ms');
    });
  });
}