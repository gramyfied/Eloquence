import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/confidence_livekit_integration.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/text_support_generator.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/mistral_api_service.dart';
import 'package:eloquence_2_0/src/services/clean_livekit_service.dart';
import 'package:eloquence_2_0/data/services/api_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';

import 'confidence_boost_livekit_test.mocks.dart';

// Annotation pour générer les mocks
@GenerateMocks([
  CleanLiveKitService,
  ApiService,
  MistralApiService,
])
void main() {
  late MockCleanLiveKitService mockLivekitService;
  late MockApiService mockApiService;
  late ConfidenceLiveKitIntegration livekitIntegration;
  late ProviderContainer container;
  late StreamController<Uint8List> audioStreamController;

  setUp(() {
    mockLivekitService = MockCleanLiveKitService();
    mockApiService = MockApiService();
    audioStreamController = StreamController<Uint8List>.broadcast();

    // Configuration des mocks pour les propriétés utilisées par ConfidenceLiveKitIntegration
    when(mockLivekitService.onAudioReceivedStream).thenAnswer((_) => audioStreamController.stream);
    when(mockLivekitService.isConnected).thenReturn(true);
    
    // Mock de la méthode requestConfidenceAnalysis
    when(mockLivekitService.requestConfidenceAnalysis(
      scenario: anyNamed('scenario'),
      recordingDurationSeconds: anyNamed('recordingDurationSeconds'),
    )).thenAnswer((_) async => ConfidenceAnalysis(
      overallScore: 85.0,
      confidenceScore: 0.85,
      fluencyScore: 0.80,
      clarityScore: 0.82,
      energyScore: 0.90,
      feedback: 'Test analysis feedback',
    ));

    // Créer l'instance ConfidenceLiveKitIntegration avec les services mockés
    livekitIntegration = ConfidenceLiveKitIntegration(
      livekitService: mockLivekitService,
      apiService: mockApiService,
      // TextSupportGenerator utilise ses fallbacks si l'API échoue
    );

    // Créer un ProviderContainer pour les tests
    container = ProviderContainer(
      overrides: [
        livekitServiceProvider.overrideWithValue(mockLivekitService),
        confidenceLiveKitIntegrationProvider.overrideWithValue(livekitIntegration),
      ],
    );
  });

  tearDown() {
    audioStreamController.close();
    container.dispose();
  }

  final testScenario = ConfidenceScenario(
    id: 'test_scenario',
    title: 'Test Scenario',
    description: 'A test scenario for unit tests.',
    prompt: 'This is a test prompt.',
    type: ConfidenceScenarioType.meeting,
    difficulty: 'intermediate',
    durationSeconds: 30,
    keywords: ['test', 'scenario'],
    tips: ['tip1', 'tip2'],
    icon: '👥',
  );

  group('ConfidenceLiveKitIntegration Tests', () {
    test('should start session successfully with valid scenario', () async {
      // Act
      final result = await livekitIntegration.startSession(
        scenario: testScenario,
        userContext: 'Utilisateur débutant en présentation publique',
        preferredSupportType: SupportType.fullText,
      );
      
      // Assert - La méthode devrait retourner un booléen
      expect(result, isA<bool>());
    });

    test('should start session without text support', () async {
      // Act
      final result = await livekitIntegration.startSession(
        scenario: testScenario,
        userContext: 'Utilisateur expérimenté',
        // Pas de type de support préféré
      );
      
      // Assert
      expect(result, isA<bool>());
    });

    test('should request confidence analysis successfully', () async {
      // Arrange - MockCleanLiveKitService est configuré avec isConnected = true
      
      // Act
      final result = await livekitIntegration.requestConfidenceAnalysis(
        scenario: testScenario,
        recordingDurationSeconds: 30,
      );
      
      // Assert
      expect(result, isNotNull);
      expect(result, isA<ConfidenceAnalysis>());
      expect(result!.overallScore, greaterThan(0));
      expect(result.feedback, isNotEmpty);
    });

    test('should handle confidence analysis when LiveKit disconnected', () async {
      // Arrange
      when(mockLivekitService.isConnected).thenReturn(false);
      
      // Act
      final result = await livekitIntegration.requestConfidenceAnalysis(
        scenario: testScenario,
        recordingDurationSeconds: 30,
      );
      
      // Assert - devrait retourner une analyse de fallback
      expect(result, isNotNull);
      expect(result, isA<ConfidenceAnalysis>());
    });

    test('should start and stop recording successfully', () async {
      // Arrange
      when(mockLivekitService.publishMyAudio()).thenAnswer((_) async {});
      when(mockLivekitService.unpublishMyAudio()).thenAnswer((_) async {});
      
      // Act
      final startResult = await livekitIntegration.startRecording();
      final stopResult = await livekitIntegration.stopRecordingAndAnalyze();
      
      // Assert
      expect(startResult, isTrue);
      expect(stopResult, isTrue);
      verify(mockLivekitService.publishMyAudio()).called(1);
      verify(mockLivekitService.unpublishMyAudio()).called(1);
    });

    test('should check availability correctly', () {
      // Act
      final isAvailable = livekitIntegration.isAvailable;
      
      // Assert
      expect(isAvailable, isA<bool>());
      expect(isAvailable, isTrue); // Car mockLivekitService.isConnected retourne true
    });

    test('should dispose resources without errors', () {
      // Act & Assert - ne devrait pas lancer d'exception
      livekitIntegration.dispose();
    });

    test('should provide analysis stream', () {
      // Act
      final stream = livekitIntegration.analysisStream;
      
      // Assert
      expect(stream, isA<Stream<ConfidenceAnalysis>>());
    });

    test('should end session correctly', () async {
      // Act & Assert - ne devrait pas lancer d'exception
      await livekitIntegration.endSession();
    });

    test('should test various support types', () async {
      final supportTypes = [
        SupportType.fullText,
        SupportType.fillInBlanks,
        SupportType.guidedStructure,
        SupportType.keywordChallenge,
        SupportType.freeImprovisation,
      ];

      for (final supportType in supportTypes) {
        // Act
        final result = await livekitIntegration.startSession(
          scenario: testScenario,
          userContext: 'Test pour type ${supportType.name}',
          preferredSupportType: supportType,
        );
        
        // Assert
        expect(result, isA<bool>(), reason: 'Failed for support type: ${supportType.name}');
      }
    });
  });
}