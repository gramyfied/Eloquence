import 'dart:io';
import 'dart:typed_data';
import 'package:eloquence_2_0/features/confidence_boost/data/services/confidence_analysis_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:eloquence_2_0/data/services/api_service.dart';
import 'package:eloquence_2_0/src/services/clean_livekit_service.dart';

import 'confidence_boost_livekit_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Ajout pour initialiser les services

  // Mocker le MethodChannel pour path_provider avant que les tests ne s'exécutent
  setUpAll(() {
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        // Créer un répertoire temporaire réel sur la machine hôte pour le test
        final tempDir = Directory.systemTemp.createTempSync('test_app_');
        return tempDir.path;
      }
      return null;
    });
  });

  // Nettoyer le mock après les tests
  tearDownAll(() {
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler(null);
  });

  late ApiService mockApiService;
  late CleanLiveKitService mockLiveKitService;
  late ConfidenceAnalysisService confidenceAnalysisService;

  setUp(() {
    mockApiService = MockApiService();
    mockLiveKitService = MockCleanLiveKitService();
    confidenceAnalysisService = ConfidenceAnalysisService(
      apiService: mockApiService,
      livekitService: mockLiveKitService, // Correction du nom du paramètre
    );
  });

  group('Confidence Boost End-to-End AI Test', () {
    test('synthesizes audio, analyzes it via fallback, and returns valid results', () async {
      // 1. Définir un texte de transcription attendu et un scénario factice
      const expectedTranscription = "Je suis un test de confiance. J'articule clairement et je parle avec assurance.";
      final scenario = ConfidenceScenario(
        id: 'test-scenario',
        title: 'Test Scenario',
        description: 'A scenario for testing.',
        prompt: 'Parlez de ce que la confiance signifie pour vous.',
        type: ConfidenceScenarioType.teamMeeting,
        durationSeconds: 30,
        tips: ['Respirez profondément', 'Parlez lentement'],
        keywords: ['confiance', 'test', 'assurance'],
        difficulty: 'intermediate', // intermediate = Moyen
        icon: '👥',
      );
      
      // 2. Créer un fichier audio factice. Son contenu n'a pas d'importance car l'API est mockée.
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/test_audio.m4a');
      await tempFile.writeAsBytes(Uint8List.fromList([1, 2, 3]));

      // 3. Configurer le mock pour la transcription (la seule dépendance externe dans le fallback)
      when(mockApiService.transcribeAudio(tempFile.path))
          .thenAnswer((_) async => expectedTranscription);
      
      // Configurer le mock de LiveKit pour qu'il ne soit pas disponible, forçant le fallback
      when(mockLiveKitService.isConnected).thenReturn(false);

      // 5. Appeler la méthode d'analyse avec tous les paramètres requis
      final result = await confidenceAnalysisService.analyzeRecording(
        audioFilePath: tempFile.path,
        scenario: scenario,
        recordingDurationSeconds: 5, // Durée factice
      );

      // 6. Vérifier les résultats en utilisant l'objet ConfidenceAnalysis
      expect(result, isA<ConfidenceAnalysis>());
      expect(result.transcription, expectedTranscription);
      expect(result.confidenceScore, isA<double>());
      expect(result.clarityScore, isA<double>());
      expect(result.keywordsUsed, containsAll(['confiance', 'test', 'assurance']));
      expect(result.strengths, isNotEmpty);
      expect(result.improvements, isA<List>());

      // Nettoyage
      await tempFile.delete();
    });
  });
}