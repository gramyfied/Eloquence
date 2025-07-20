import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_manager.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/ai_character_factory.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_engine.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/vosk_analysis_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/robust_livekit_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/boost_confidence_models.dart';
import 'package:eloquence_2_0/features/shared/analysis/domain/analysis_result.dart';

// Mock classes
@GenerateMocks([
  RobustLiveKitService,
  VoskAnalysisService,
])
import 'conversation_pipeline_mock_integration_test.mocks.dart';

void main() {
  group('Pipeline Conversationnel avec Mocks', () {
    late ConversationManager conversationManager;
    late MockRobustLiveKitService mockLiveKitService;
    late MockVoskAnalysisService mockVoskService;
    late AICharacterFactory characterFactory;
    late ConversationEngine conversationEngine;

    setUp(() {
      // Initialiser les mocks
      mockLiveKitService = MockRobustLiveKitService();
      mockVoskService = MockVoskAnalysisService();
      
      // Stub les méthodes mockées
      when(mockLiveKitService.initialize()).thenAnswer((_) async => true);
      when(mockLiveKitService.isConnected).thenReturn(true);
      when(mockLiveKitService.dispose()).thenAnswer((_) async {});
      
      when(mockVoskService.analyzeAudioStream(any))
          .thenAnswer((_) async => _createMockAnalysisResult());
      when(mockVoskService.dispose()).thenAnswer((_) async {});

      // Créer les services réels
      characterFactory = AICharacterFactory();
      conversationEngine = ConversationEngine();
      
      // Le ConversationManager utilise nos mocks
      conversationManager = ConversationManager(
        liveKitService: mockLiveKitService,
        voskService: mockVoskService,
      );
    });

    tearDown(() {
      conversationManager.dispose();
    });

    test('Pipeline complet avec mocks - Initialisation', () async {
      // Arrange
      final scenario = ConversationScenario.interviewDevOps;
      
      // Act
      final stopwatch = Stopwatch()..start();
      final result = await conversationManager.initializeConversation(
        scenario,
        AICharacterType.thomas,
      );
      stopwatch.stop();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // < 5s
      verify(mockLiveKitService.initialize()).called(1);
      
      print('✅ Initialisation réussie en ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Pipeline complet avec mocks - Traitement audio utilisateur', () async {
      // Arrange
      await conversationManager.initializeConversation(
        ConversationScenario.interviewDevOps,
        AICharacterType.thomas,
      );
      
      final mockAudioData = List<int>.filled(1000, 127); // Audio simulé
      
      // Act
      final stopwatch = Stopwatch()..start();
      final result = await conversationManager.processUserAudio(mockAudioData);
      stopwatch.stop();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // < 8s
      verify(mockVoskService.analyzeAudioStream(any)).called(1);
      
      print('✅ Traitement audio réussi en ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Pipeline complet avec mocks - Analyse de performance', () async {
      // Arrange
      await conversationManager.initializeConversation(
        ConversationScenario.interviewDevOps,
        AICharacterType.thomas,
      );
      
      final mockContext = ConversationContext(
        scenario: ConversationScenario.interviewDevOps,
        character: _createMockCharacter(),
        turnHistory: [],
        currentState: ConversationState.ready,
      );
      
      // Act
      final stopwatch = Stopwatch()..start();
      final metrics = await conversationManager.analyzePerformanceRobust(
        mockContext,
        _createMockAnalysisResult(),
      );
      stopwatch.stop();

      // Assert
      expect(metrics, isNotNull);
      expect(metrics.confidenceScore, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // < 3s
      
      print('✅ Analyse performance réussie en ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Pipeline complet avec mocks - Workflow end-to-end', () async {
      // Arrange
      final scenario = ConversationScenario.interviewDevOps;
      final mockAudioData = List<int>.filled(1000, 127);
      
      // Act - Workflow complet
      final initStopwatch = Stopwatch()..start();
      
      // 1. Initialisation
      final initResult = await conversationManager.initializeConversation(
        scenario,
        AICharacterType.thomas,
      );
      initStopwatch.stop();
      
      // 2. Traitement audio
      final audioStopwatch = Stopwatch()..start();
      final audioResult = await conversationManager.processUserAudio(mockAudioData);
      audioStopwatch.stop();
      
      // 3. Analyse de performance
      final analysisStopwatch = Stopwatch()..start();
      final mockContext = ConversationContext(
        scenario: scenario,
        character: _createMockCharacter(),
        turnHistory: [],
        currentState: ConversationState.processing,
      );
      
      final metrics = await conversationManager.analyzePerformanceRobust(
        mockContext,
        _createMockAnalysisResult(),
      );
      analysisStopwatch.stop();

      // Assert - Résultats
      expect(initResult.isSuccess, isTrue);
      expect(audioResult.isSuccess, isTrue);
      expect(metrics.confidenceScore, greaterThan(0));

      // Assert - Performance
      expect(initStopwatch.elapsedMilliseconds, lessThan(5000));
      expect(audioStopwatch.elapsedMilliseconds, lessThan(8000));
      expect(analysisStopwatch.elapsedMilliseconds, lessThan(3000));

      // Verify LiveKit orchestration
      verify(mockLiveKitService.initialize()).called(1);
      verify(mockVoskService.analyzeAudioStream(any)).called(1);
      
      print('✅ Workflow end-to-end complet:');
      print('   🚀 Init: ${initStopwatch.elapsedMilliseconds}ms');
      print('   🎤 Audio: ${audioStopwatch.elapsedMilliseconds}ms');
      print('   📊 Analyse: ${analysisStopwatch.elapsedMilliseconds}ms');
    });

    test('Pipeline avec mocks - Gestion des erreurs LiveKit', () async {
      // Arrange
      when(mockLiveKitService.initialize()).thenThrow(Exception('Connection failed'));
      
      // Act
      final result = await conversationManager.initializeConversation(
        ConversationScenario.interviewDevOps,
        AICharacterType.thomas,
      );

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.error, contains('Connection failed'));
      
      print('✅ Gestion d\'erreur LiveKit validée');
    });

    test('Pipeline avec mocks - Fallback VOSK', () async {
      // Arrange
      await conversationManager.initializeConversation(
        ConversationScenario.interviewDevOps,
        AICharacterType.thomas,
      );
      
      when(mockVoskService.analyzeAudioStream(any))
          .thenThrow(Exception('VOSK timeout'));
      
      // Act
      final result = await conversationManager.processUserAudio([1, 2, 3]);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.error, contains('VOSK timeout'));
      
      print('✅ Fallback VOSK validé');
    });
  });
}

// Helper methods
AnalysisResult _createMockAnalysisResult() {
  return AnalysisResult(
    transcription: "Bonjour, je suis intéressé par ce poste",
    confidenceScore: 0.85,
    clarity: 0.80,
    pace: 0.75,
    volume: 0.82,
    stressLevel: 0.25,
    fluency: 0.88,
    articulation: 0.86,
    timestamp: DateTime.now(),
    audioLength: 3.5,
    languageQuality: 0.90,
    nonVerbalScore: 0.78,
    suggestions: [
      "Parlez un peu plus lentement",
      "Articulez davantage les consonnes"
    ],
    detailedMetrics: {
      'pause_analysis': {'total_pauses': 2, 'avg_pause_duration': 0.8},
      'speech_rate': {'words_per_minute': 150, 'syllables_per_second': 4.2},
      'voice_quality': {'pitch_variation': 0.85, 'energy_level': 0.75}
    },
  );
}

AICharacter _createMockCharacter() {
  return AICharacter(
    id: 'thomas_devops_001',
    name: 'Thomas',
    type: AICharacterType.thomas,
    personality: CharacterPersonality(
      traits: ['professionnel', 'bienveillant', 'analytique'],
      communicationStyle: ConversationStyle.professional,
      expertise: ['DevOps', 'Infrastructure', 'CI/CD'],
      adaptability: 0.8,
    ),
    conversationStyle: ConversationStyle.professional,
    specializations: ['DevOps', 'Infrastructure as Code', 'Monitoring'],
    difficultyLevel: DifficultyLevel.intermediate,
    context: {
      'scenario': 'Entretien DevOps',
      'company': 'TechCorp',
      'position': 'DevOps Engineer',
    },
    lastUpdated: DateTime.now(),
  );
}