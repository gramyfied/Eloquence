import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_manager.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_engine.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/robust_livekit_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/ai_character_factory.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/adaptive_ai_character_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'conversation_manager_test.mocks.dart';

@GenerateMocks([
  ConversationEngine,
  RobustLiveKitService,
  AICharacterFactory,
  AdaptiveAICharacterService,
])
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
  
  group('ConversationManager Tests', () {
    late ConversationManager conversationManager;
    late MockConversationEngine mockConversationEngine;
    late MockRobustLiveKitService mockLiveKitService;
    late MockAICharacterFactory mockAICharacterFactory;
    late MockAdaptiveAICharacterService mockAICharacterService;
    late ConfidenceScenario testScenario;
    late UserAdaptiveProfile testUserProfile;
    late AICharacterConfig testCharacterConfig;

    setUp(() {
      mockConversationEngine = MockConversationEngine();
      mockLiveKitService = MockRobustLiveKitService();
      mockAICharacterFactory = MockAICharacterFactory();
      mockAICharacterService = MockAdaptiveAICharacterService();

      conversationManager = ConversationManager(
        conversationEngine: mockConversationEngine,
        liveKitService: mockLiveKitService,
        characterFactory: mockAICharacterFactory,
        aiCharacterService: mockAICharacterService,
      );

      testScenario = const ConfidenceScenario(
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
        strengths: const ['communication', 'organisation'],
        weaknesses: const ['gestion du stress', 'improvisation'],
        preferredTopics: const ['technologie', 'management'],
        preferredCharacter: AICharacterType.marie,
        lastSessionDate: DateTime.now().subtract(const Duration(days: 1)),
        totalSessions: 5,
        averageScore: 75.0,
      );

      testCharacterConfig = const AICharacterConfig(
        character: AICharacterType.marie,
        scenarioType: ConfidenceScenarioType.interview,
        personalityTraits: ['Empathique'],
        conversationStyle: ConversationStyle.friendly,
        challengeLevel: ChallengeLevel.low,
        feedbackStyle: FeedbackStyle.encouraging,
      );

      // Stubs par défaut pour les mocks
      when(mockLiveKitService.initialize(
        livekitUrl: anyNamed('livekitUrl'),
        livekitToken: anyNamed('livekitToken'),
        roomName: anyNamed('roomName'),
        participantName: anyNamed('participantName'),
        isMobileOptimized: true,
      )).thenAnswer((_) async => true);

      when(mockConversationEngine.initialize(
        scenario: anyNamed('scenario'),
        userProfile: anyNamed('userProfile'),
        preferredCharacter: anyNamed('preferredCharacter'),
      )).thenAnswer((_) async {});
      
      when(mockAICharacterService.initialize()).thenAnswer((_) async {});

      when(mockAICharacterFactory.createCharacter(
        scenario: anyNamed('scenario'),
        userProfile: anyNamed('userProfile'),
        preferredCharacter: anyNamed('preferredCharacter'),
      )).thenReturn(AICharacterInstance(
          type: AICharacterType.marie,
          config: testCharacterConfig,
          scenario: testScenario,
          userProfile: testUserProfile,
          createdAt: DateTime.now()));

      when(mockConversationEngine.generateIntroduction()).thenAnswer((_) async => ConversationResponse(
          message: 'Bonjour',
          character: AICharacterType.marie,
          emotionalState: AIEmotionalState.empathetic,
          suggestedUserResponses: [],
          requiresUserResponse: true));
      
      when(mockLiveKitService.dispose()).thenAnswer((_) async {});
      when(mockConversationEngine.getConversationHistory()).thenReturn([]);
      when(mockConversationEngine.reset()).thenAnswer((_) {});
    });

    tearDown(() {
      // No need to call dispose on the real manager, as it's not created with real resources
    });

    group('Initialisation', () {
      test('devrait s\'initialiser correctement avec des données valides', () async {
        // Act
        final result = await conversationManager.initializeConversation(
          scenario: testScenario,
          userProfile: testUserProfile,
          livekitUrl: 'wss://test.livekit.cloud',
          livekitToken: 'valid-token',
        );

        // Assert
        expect(result, isTrue);
        expect(conversationManager.state, equals(ConversationState.ready));
        verify(mockLiveKitService.initialize(
          livekitUrl: anyNamed('livekitUrl'),
          livekitToken: anyNamed('livekitToken'),
          roomName: anyNamed('roomName'),
          participantName: anyNamed('participantName'),
          isMobileOptimized: true,
        )).called(1);
        verify(mockConversationEngine.initialize(
          scenario: anyNamed('scenario'),
          userProfile: anyNamed('userProfile'),
          preferredCharacter: anyNamed('preferredCharacter'),
        )).called(1);
      });

      test('devrait gérer les erreurs d\'initialisation de LiveKit', () async {
        // Arrange
        when(mockLiveKitService.initialize(
          livekitUrl: anyNamed('livekitUrl'),
          livekitToken: anyNamed('livekitToken'),
          roomName: anyNamed('roomName'),
          participantName: anyNamed('participantName'),
          isMobileOptimized: true,
        )).thenAnswer((_) async => false);

        List<ConversationEvent> events = [];
        final sub = conversationManager.events.listen(events.add);

        // Act
        final result = await conversationManager.initializeConversation(
          scenario: testScenario,
          userProfile: testUserProfile,
          livekitUrl: 'url-qui-marche-pas',
          livekitToken: 'token-invalide',
        );

        // Assert
        expect(result, isFalse);
        await Future.delayed(Duration.zero);
        expect(events.any((e) => e.type == ConversationEventType.error && e.data == 'Échec connexion LiveKit'), isTrue);
        sub.cancel();
      });
    });
  });
}