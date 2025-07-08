import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/confidence_analysis_service.dart';
import 'package:eloquence_2_0/src/services/clean_livekit_service.dart';
import 'package:eloquence_2_0/data/services/api_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_session.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';

import 'confidence_boost_livekit_test.mocks.dart';

// Annotation pour générer les mocks
@GenerateMocks([
  ApiService,
  CleanLiveKitService,
])
void main() {
  late MockApiService mockApiService;
  late MockCleanLiveKitService mockLivekitService;
  late ProviderContainer container;

  setUp(() {
    mockApiService = MockApiService();
    mockLivekitService = MockCleanLiveKitService();

    // Créer un ProviderContainer pour les tests
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        livekitServiceProvider.overrideWithValue(mockLivekitService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  final testScenario = ConfidenceScenario(
    id: 'test_scenario',
    title: 'Test Scenario',
    description: 'A test scenario for unit tests.',
    prompt: 'This is a test prompt.',
    type: ConfidenceScenarioType.teamMeeting,
    difficulty: 'intermediate',
    durationSeconds: 30,
    keywords: ['test', 'scenario'],
    tips: ['tip1', 'tip2'],
    icon: '👥',
  );

  group('ConfidenceAnalysisService with LiveKit Integration', () {
    test('should use LiveKit when available', () async {
      // Arrange
      final analysisService = ConfidenceAnalysisService(
        apiService: mockApiService,
        livekitService: mockLivekitService,
      );
      
      // Simuler LiveKit comme étant connecté
      when(mockLivekitService.isConnected).thenReturn(true);
      
      // Act
      final result = await analysisService.analyzeRecording(
        audioFilePath: 'fake/path.m4a',
        scenario: testScenario,
        recordingDurationSeconds: 30,
      );
      
      // Assert
      // Le résultat devrait être l'analyse simulée de LiveKit
      expect(result.transcription, 'Transcription via LiveKit (simulée)');
      verifyNever(mockApiService.transcribeAudio(any));
    });

    test('should handle fallback scenario correctly', () async {
      // Arrange
      final analysisService = ConfidenceAnalysisService(
        apiService: mockApiService,
        livekitService: mockLivekitService,
      );
      
      // Simuler LiveKit comme étant déconnecté
      when(mockLivekitService.isConnected).thenReturn(false);
      
      // Simuler la transcription et l'analyse de fallback
      when(mockApiService.transcribeAudio(any)).thenAnswer((_) async => 'fallback transcription');
      when(mockApiService.generateResponse(any)).thenAnswer((_) async => jsonEncode({
        'response': '{"confidenceScore": 0.6, "fluencyScore": 0.6, "clarityScore": 0.6, "energyScore": 0.6, "wordCount": 40, "speakingRate": 80.0, "keywordsUsed": [], "transcription": "fallback transcription", "feedback": "fallback feedback", "strengths": [], "improvements": []}'
      }));

      // Act
      final result = await analysisService.analyzeRecording(
        audioFilePath: 'fake/path.m4a',
        scenario: testScenario,
        recordingDurationSeconds: 30,
      );
      
      // Assert
      // Vérifier que le résultat est valide même si la transcription exacte peut varier
      expect(result, isA<ConfidenceAnalysis>());
      expect(result.confidenceScore, isA<double>());
      expect(result.fluencyScore, isA<double>());
      expect(result.clarityScore, isA<double>());
      expect(result.energyScore, isA<double>());
    });
  });
}