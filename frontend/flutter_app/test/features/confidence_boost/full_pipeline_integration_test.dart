import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

// Imports des services
import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_manager.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/ai_character_factory.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/vosk_analysis_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/robust_livekit_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/fallback_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/conversation_engine.dart';

// Imports des modèles
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/ai_character_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';

/// Test d'intégration complet du pipeline LiveKit → VOSK → Mistral
/// 
/// ✅ OBJECTIF : Valider le flux complet avec audio synthétique
/// - Génération d'audio synthétique réaliste 
/// - Envoi via le pipeline LiveKit
/// - Analyse VOSK (transcription + métriques)
/// - Génération de réponse IA Mistral
/// - Validation des personnages adaptatifs (Thomas/Marie)
/// - Test des fallbacks en conditions d'erreur
/// - Validation des performances (< 8s total)

void main() {
  group('🚀 Pipeline Intégration Complète', () {
    late ConversationManager conversationManager;
    late AICharacterFactory characterFactory;
    late VoskAnalysisService voskService;
    late RobustLiveKitService livekitService;
    late FallbackService fallbackService;
    late ConversationEngine conversationEngine;

    setUp(() {
      // Initialiser les services réels
      livekitService = RobustLiveKitService();
      voskService = VoskAnalysisService();
      characterFactory = AICharacterFactory();
      fallbackService = FallbackService();
      conversationEngine = ConversationEngine();
      
      conversationManager = ConversationManager();
    });

    tearDown(() async {
      await conversationManager.dispose();
    });

    test('🎯 Pipeline complet avec audio synthétique', () async {
      print('\n🚀 TEST PIPELINE COMPLET DÉMARRÉ');
      
      // 1. GÉNÉRATION AUDIO SYNTHÉTIQUE
      print('📊 Génération audio synthétique...');
      final audioData = _generateSyntheticSpeech(
        'Bonjour, je suis très motivé pour ce poste de développeur DevOps',
        duration: 4,
      );
      expect(audioData.length, greaterThan(1000));
      print('✅ Audio généré: ${audioData.length} bytes');

      // 2. CONFIGURATION UTILISATEUR ET SCÉNARIO
      final userProfile = UserAdaptiveProfile(
        userId: 'test_user_pipeline',
        confidenceLevel: 6,
        experienceLevel: 7,
        strengths: ['technique', 'analyse'],
        weaknesses: ['présentation', 'stress'],
        preferredTopics: ['DevOps', 'CI/CD'],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now(),
        totalSessions: 5,
        averageScore: 7.2,
      );

      final scenario = ConfidenceScenario(
        id: 'interview_devops_test',
        title: 'Entretien DevOps',
        description: 'Entretien technique pour poste DevOps Senior',
        prompt: 'Présentez votre expérience en infrastructure et automatisation',
        type: ConfidenceScenarioType.interview,
        durationSeconds: 300,
        tips: ['Donnez des exemples concrets', 'Mentionnez vos outils'],
        keywords: ['Docker', 'Kubernetes', 'CI/CD', 'monitoring'],
        difficulty: 'Intermédiaire',
        icon: '🛠️',
      );

      // 3. INITIALISATION CONVERSATION
      print('🎭 Initialisation conversation...');
      final startTime = DateTime.now();
      
      final initSuccess = await conversationManager.initializeConversation(
        scenario: scenario,
        userProfile: userProfile,
        livekitUrl: 'wss://test.livekit.io',
        livekitToken: 'test_token_123',
        preferredCharacter: AICharacterType.thomas,
      );
      
      expect(initSuccess, isTrue);
      print('✅ Conversation initialisée avec Thomas');

      // 4. ANALYSE AUDIO AVEC VOSK
      print('🎤 Analyse VOSK en cours...');
      final voskStart = DateTime.now();
      
      final voskResult = await voskService.analyzeSpeech(audioData);
      
      final voskDuration = DateTime.now().difference(voskStart);
      expect(voskDuration.inSeconds, lessThan(6), reason: 'VOSK doit répondre < 6s');
      print('✅ VOSK analysé en ${voskDuration.inMilliseconds}ms');
      print('📝 Transcription: "${voskResult.transcription}"');
      print('📊 Confiance: ${(voskResult.confidence * 100).toStringAsFixed(1)}%');

      // 5. CRÉATION PERSONNAGE IA
      print('🤖 Création personnage IA...');
      final character = characterFactory.createCharacter(
        scenario: scenario,
        userProfile: userProfile,
        preferredCharacter: AICharacterType.thomas,
      );
      
      expect(character.type, equals(AICharacterType.thomas));
      print('✅ Personnage créé: ${character.type.displayName}');

      // 6. INITIALISATION ET GÉNÉRATION RÉPONSE IA MISTRAL
      print('🧠 Initialisation ConversationEngine...');
      await conversationEngine.initialize(
        scenario: scenario,
        userProfile: userProfile,
        preferredCharacter: AICharacterType.thomas,
      );

      print('🧠 Génération réponse IA...');
      final aiResponse = await conversationEngine.generateAIResponse(
        userMessage: voskResult.transcription,
        performanceMetrics: {
          'confidence_level': voskResult.confidence,
          'fluency_score': voskResult.fluency,
          'clarity_score': voskResult.clarity,
          'speaking_rate': voskResult.speakingRate,
        },
      );
      
      expect(aiResponse.message.isNotEmpty, isTrue);
      print('💬 Réponse IA: "${aiResponse.message.substring(0, min(50, aiResponse.message.length))}..."');

      // 7. VALIDATION PIPELINE COMPLET
      final totalDuration = DateTime.now().difference(startTime);
      expect(totalDuration.inSeconds, lessThan(8), reason: 'Pipeline complet < 8s');
      
      print('⏱️ Durée totale: ${totalDuration.inMilliseconds}ms');
      print('✅ PIPELINE COMPLET VALIDÉ');
    });

    test('🎭 Test personnages adaptatifs Thomas vs Marie', () async {
      print('\n🎭 TEST PERSONNAGES ADAPTATIFS');
      
      final userProfile = UserAdaptiveProfile(
        userId: 'test_personas',
        confidenceLevel: 4,
        experienceLevel: 5,
        strengths: ['créativité'],
        weaknesses: ['confiance', 'structure'],
        preferredTopics: ['innovation'],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now(),
        totalSessions: 2,
        averageScore: 5.5,
      );

      final scenario = ConfidenceScenario(
        id: 'pitch_innovation',
        title: 'Pitch Innovation',
        description: 'Présentation idée innovante',
        prompt: 'Présentez votre idée révolutionnaire',
        type: ConfidenceScenarioType.pitch,
        durationSeconds: 180,
        tips: ['Soyez passionné', 'Montrez l\'impact'],
        keywords: ['innovation', 'disruption', 'valeur'],
        difficulty: 'Avancé',
        icon: '💡',
      );

      // TEST THOMAS (Analytique)
      print('📊 Test personnage Thomas...');
      final thomas = characterFactory.createCharacter(
        scenario: scenario,
        userProfile: userProfile,
        preferredCharacter: AICharacterType.thomas,
      );
      
      expect(thomas.type, equals(AICharacterType.thomas));
      final thomasPrompt = thomas.getSystemPrompt();
      expect(thomasPrompt, contains('Thomas'));
      expect(thomasPrompt.toLowerCase(), contains('analytique'));
      print('✅ Thomas configuré (analytique, structuré)');

      // TEST MARIE (Empathique)  
      print('💝 Test personnage Marie...');
      final marie = characterFactory.createCharacter(
        scenario: scenario,
        userProfile: userProfile,
        preferredCharacter: AICharacterType.marie,
      );
      
      expect(marie.type, equals(AICharacterType.marie));
      final mariePrompt = marie.getSystemPrompt();
      expect(mariePrompt, contains('Marie'));
      expect(mariePrompt.toLowerCase(), contains('empathique'));
      print('✅ Marie configurée (empathique, encourageante)');

      print('🎭 PERSONNAGES ADAPTATIFS VALIDÉS');
    });

    test('🛡️ Test fallbacks et gestion d\'erreurs', () async {
      print('\n🛡️ TEST FALLBACKS ET ERREURS');
      
      final scenario = ConfidenceScenario(
        id: 'test_fallback',
        title: 'Test Fallback',
        description: 'Test des mécanismes de fallback',
        prompt: 'Test prompt',
        type: ConfidenceScenarioType.interview,
        durationSeconds: 120,
        tips: ['Test tip'],
        keywords: ['test'],
        difficulty: 'Test',
        icon: '⚠️',
      );

      final userProfile = UserAdaptiveProfile(
        userId: 'test_fallback_user',
        confidenceLevel: 5,
        experienceLevel: 5,
        strengths: ['test'],
        weaknesses: ['test'],
        preferredTopics: ['test'],
        preferredCharacter: AICharacterType.marie,
        lastSessionDate: DateTime.now(),
        totalSessions: 1,
        averageScore: 5.0,
      );

      // 1. Test avec URL LiveKit invalide
      print('🔴 Test connexion LiveKit échouée...');
      final failureSuccess = await conversationManager.initializeConversation(
        scenario: scenario,
        userProfile: userProfile,
        livekitUrl: 'wss://invalid-url-test.com',
        livekitToken: 'invalid_token',
      );
      
      expect(failureSuccess, isFalse, reason: 'Connexion invalide doit échouer');
      print('✅ Échec LiveKit géré correctement');

      // 2. Test fallback VOSK
      print('🔴 Test timeout VOSK...');
      final invalidAudio = Uint8List.fromList([1, 2, 3]); // Audio invalide
      
      try {
        await voskService.analyzeSpeech(invalidAudio).timeout(
          const Duration(milliseconds: 500), // Timeout court pour forcer l'erreur
        );
        fail('Expected timeout exception');
      } catch (e) {
        expect(e.toString().toLowerCase(), contains('timeout'));
        print('✅ Timeout VOSK géré correctement');
      }

      print('🛡️ FALLBACKS VALIDÉS');
    });

    test('⚡ Test performance et charge', () async {
      print('\n⚡ TEST PERFORMANCE ET CHARGE');
      
      final scenario = ConfidenceScenario(
        id: 'perf_test',
        title: 'Test Performance',
        description: 'Test de charge du pipeline',
        prompt: 'Test performance',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 60,
        tips: ['Rapidité'],
        keywords: ['performance'],
        difficulty: 'Performance',
        icon: '⚡',
      );

      final userProfile = UserAdaptiveProfile(
        userId: 'perf_user',
        confidenceLevel: 8,
        experienceLevel: 9,
        strengths: ['rapidité'],
        weaknesses: [],
        preferredTopics: ['performance'],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now(),
        totalSessions: 10,
        averageScore: 8.5,
      );

      // Test de création multiple de personnages (performance)
      final stopwatch = Stopwatch()..start();
      
      final characters = <AICharacterInstance>[];
      for (int i = 0; i < 5; i++) {
        final character = characterFactory.createCharacter(
          scenario: scenario,
          userProfile: userProfile,
          preferredCharacter: i % 2 == 0 ? AICharacterType.thomas : AICharacterType.marie,
        );
        characters.add(character);
      }
      
      stopwatch.stop();
      expect(characters.length, equals(5));
      expect(stopwatch.elapsedMilliseconds, lessThan(100), 
        reason: 'Création 5 personnages < 100ms');
      
      print('✅ 5 personnages créés en ${stopwatch.elapsedMilliseconds}ms');
      print('⚡ PERFORMANCE VALIDÉE');
    });

    test('🎤 Test ConversationManager streaming', () async {
      print('\n🎤 TEST CONVERSATION MANAGER STREAMING');
      
      final scenario = ConfidenceScenario(
        id: 'streaming_test',
        title: 'Test Streaming',
        description: 'Test streaming conversationnel',
        prompt: 'Test conversation streaming',
        type: ConfidenceScenarioType.interview,
        durationSeconds: 120,
        tips: ['Parlez naturellement'],
        keywords: ['streaming', 'temps réel'],
        difficulty: 'Streaming',
        icon: '🎙️',
      );

      final userProfile = UserAdaptiveProfile(
        userId: 'streaming_user',
        confidenceLevel: 7,
        experienceLevel: 6,
        strengths: ['communication'],
        weaknesses: [],
        preferredTopics: ['technologie'],
        preferredCharacter: AICharacterType.thomas,
        lastSessionDate: DateTime.now(),
        totalSessions: 3,
        averageScore: 7.0,
      );

      // Initialisation
      final initSuccess = await conversationManager.initializeConversation(
        scenario: scenario,
        userProfile: userProfile,
        livekitUrl: 'wss://test.livekit.io',
        livekitToken: 'test_token_streaming',
      );
      
      expect(initSuccess, isTrue);
      print('✅ ConversationManager initialisé');

      // Test de streaming d'audio par chunks
      final audioData = _generateSyntheticSpeech(
        'Test de streaming audio en temps réel',
        duration: 2,
      );
      
      // Simuler l'envoi d'audio par chunks
      const chunkSize = 1000;
      for (int i = 0; i < audioData.length; i += chunkSize) {
        final endIndex = min(i + chunkSize, audioData.length);
        final chunk = audioData.sublist(i, endIndex);
        
        await conversationManager.processUserAudio(Uint8List.fromList(chunk));
        
        // Attendre un petit délai pour simuler le streaming
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      print('✅ Streaming audio par chunks validé');
      
      // Vérifier les états de conversation
      expect(conversationManager.state, isNotNull);
      print('📊 État conversation: ${conversationManager.state}');
      
      print('🎤 CONVERSATION MANAGER STREAMING VALIDÉ');
    });

    // TODO: Tests supplémentaires à implémenter
    // - Test intégration complète avec services backend  
    // - Test gestion des sessions multiples
    // - Test persistance des conversations
    // - Test adaptation dynamique selon le feedback utilisateur
  });
}

/// Génère de l'audio synthétique pour les tests
Uint8List _generateSyntheticSpeech(String text, {int duration = 3}) {
  // Simulation d'audio WAV 16kHz mono
  const sampleRate = 16000;
  const channels = 1;
  const bitsPerSample = 16;
  
  final samples = sampleRate * duration;
  final audioData = <int>[];
  
  // Header WAV simplifié
  audioData.addAll([0x52, 0x49, 0x46, 0x46]); // "RIFF"
  audioData.addAll(_intToBytes(36 + samples * 2, 4)); // File size - 8
  audioData.addAll([0x57, 0x41, 0x56, 0x45]); // "WAVE"
  audioData.addAll([0x66, 0x6D, 0x74, 0x20]); // "fmt "
  audioData.addAll(_intToBytes(16, 4)); // Subchunk1Size
  audioData.addAll(_intToBytes(1, 2)); // PCM format
  audioData.addAll(_intToBytes(channels, 2)); // Channels
  audioData.addAll(_intToBytes(sampleRate, 4)); // Sample rate
  audioData.addAll(_intToBytes(sampleRate * channels * bitsPerSample ~/ 8, 4)); // Byte rate
  audioData.addAll(_intToBytes(channels * bitsPerSample ~/ 8, 2)); // Block align
  audioData.addAll(_intToBytes(bitsPerSample, 2)); // Bits per sample
  audioData.addAll([0x64, 0x61, 0x74, 0x61]); // "data"
  audioData.addAll(_intToBytes(samples * 2, 4)); // Subchunk2Size
  
  // Génération d'audio synthétique avec variations
  for (int i = 0; i < samples; i++) {
    // Signal composite pour simuler la parole
    final t = i / sampleRate;
    final fundamental = sin(440 * 2 * pi * t); // 440 Hz base
    final harmonic1 = 0.3 * sin(880 * 2 * pi * t); // Harmonique
    final noise = (DateTime.now().millisecond % 1000 - 500) / 500.0 * 0.1; // Bruit
    
    // Modulation pour simuler la parole
    final envelope = (0.5 + 0.5 * sin(10 * 2 * pi * t)).abs();
    final speechSim = envelope * (fundamental + harmonic1 + noise);
    
    // Conversion en 16-bit samples
    final sample = (speechSim * 16000).clamp(-32768, 32767).round();
    audioData.addAll(_intToBytes(sample, 2));
  }
  
  return Uint8List.fromList(audioData);
}

/// Convertit un entier en bytes little-endian
List<int> _intToBytes(int value, int bytes) {
  final result = <int>[];
  for (int i = 0; i < bytes; i++) {
    result.add((value >> (8 * i)) & 0xFF);
  }
  return result;
}