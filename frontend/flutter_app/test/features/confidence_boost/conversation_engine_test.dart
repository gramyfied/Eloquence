import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Mock pour le permission_handler
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/permissions/methods'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'requestPermissions') {
        return {Permission.microphone.value: PermissionStatus.granted.index};
      }
      return null;
    },
  );

  group('ConversationEngine Tests', () {
    late ConversationEngine conversationEngine;
    late MockOptimizedHttpService mockHttpService;
    late MockAdaptiveAICharacterService mockAICharacterService;
    late ConfidenceScenario testScenario;
    late UserAdaptiveProfile testUserProfile;

    setUp(() {
      // Initialiser les données de test d'abord
      testScenario = const ConfidenceScenario(
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

      mockHttpService = MockOptimizedHttpService();
      mockAICharacterService = MockAdaptiveAICharacterService();
      
      conversationEngine = ConversationEngine(
        httpService: mockHttpService,
        aiCharacterService: mockAICharacterService,
      );
      
      // Setup des mocks directement dans setUp
      when(mockAICharacterService.selectOptimalCharacter(
        scenario: anyNamed('scenario'),
        profile: anyNamed('profile'),
        userPreference: anyNamed('userPreference'),
      )).thenReturn(AICharacterType.thomas);
      
      when(mockAICharacterService.initialize()).thenAnswer((_) async {});
      
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
      // Act & Assert
      expect(() async => await conversationEngine.initialize(
        scenario: testScenario,
        userProfile: testUserProfile,
        preferredCharacter: AICharacterType.thomas,
      ), returnsNormally);
    });
  });
}