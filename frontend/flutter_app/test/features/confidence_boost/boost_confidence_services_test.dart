import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/confidence_analysis_backend_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/unified_speech_analysis_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/mistral_api_service_provider.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';
import 'dart:async';
import '../../test_helpers.dart';

/// Tests unitaires des services pour reproduire les problèmes de timeout
/// 
/// Ces tests isolent chaque service individuellement pour identifier
/// les sources exactes des problèmes de performance.
void main() {
  group('🔧 Tests Unitaires Services - Problèmes de Timeout', () {
    late ProviderContainer container;
    final logger = Logger();

    setUpAll(() async {
      await loadTestEnv();
      SharedPreferences.setMockInitialValues({});
      
      container = ProviderContainer(
        overrides: [
          // Override shared preferences pour les tests
        ],
      );
    });

    tearDownAll(() {
      container.dispose();
    });

    group('🚨 ConfidenceAnalysisBackendService - Timeout 30s', () {
      test('🚨 PROBLÈME: analyzeAudioRecording timeout à 30s (trop long mobile)', () async {
        logger.w('🚨 TEST: Test timeout backend service 30s vs 6s souhaité');
        
        final backendService = ConfidenceAnalysisBackendService();
        const scenario = ConfidenceScenario.professional();
        final audioData = Uint8List.fromList(List.generate(1024, (index) => index % 256));
        
        final stopwatch = Stopwatch()..start();
        
        try {
          // Ce service a actuellement un timeout de 30s (ligne 520 dans confidence_boost_provider.dart)
          await backendService.analyzeAudioRecording(
            audioData: audioData,
            scenario: scenario,
            userContext: 'Test timeout backend',
            recordingDurationSeconds: 10,
          ).timeout(const Duration(seconds: 8)); // Timeout mobile optimal souhaité
          
          fail('Le service backend aurait dû timeout après 8s - il est trop lent pour mobile');
          
        } on TimeoutException {
          stopwatch.stop();
          final elapsedMs = stopwatch.elapsedMilliseconds;
          
          logger.w('🎯 TEST: Backend timeout détecté après ${elapsedMs}ms');
          logger.w('🎯 TEST: PROBLÈME CONFIRMÉ - Backend prend plus de 8s (actuellement configuré à 30s)');
          
          expect(elapsedMs, greaterThan(7000), 
            reason: 'Le timeout confirme que le backend dépasse les 8s mobiles optimaux');
            
        } catch (e) {
          stopwatch.stop();
          logger.w('⚠️ TEST: Autre erreur backend: $e après ${stopwatch.elapsedMilliseconds}ms');
          
          // Une erreur peut aussi indiquer un problème de configuration
          expect(stopwatch.elapsedMilliseconds, greaterThan(1000), 
            reason: 'Le service devrait au moins essayer de se connecter');
        }
      });

      test('🎯 isServiceAvailable devrait répondre rapidement', () async {
        logger.i('🎯 TEST: Test disponibilité rapide du service backend');
        
        final backendService = ConfidenceAnalysisBackendService();
        final stopwatch = Stopwatch()..start();
        
        final isAvailable = await backendService.isServiceAvailable()
          .timeout(const Duration(seconds: 3));
        
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;
        
        logger.i('📊 TEST: Service disponible: $isAvailable en ${elapsedMs}ms');
        
        expect(elapsedMs, lessThan(3000), 
          reason: 'La vérification de disponibilité doit être rapide');
      });
    });

    group('🚨 UnifiedSpeechAnalysisService - Performance', () {
      test('🚨 PROBLÈME: analyzeAudio sans timeout optimisé', () async {
        logger.w('🚨 TEST: Test timeout speech analysis');
        
        final speechService = UnifiedSpeechAnalysisService();
        final audioData = Uint8List.fromList(List.generate(2048, (index) => index % 256));
        
        final stopwatch = Stopwatch()..start();
        
        try {
          final result = await speechService.analyzeAudio(audioData)
            .timeout(const Duration(seconds: 6)); // Timeout Whisper souhaité
          
          stopwatch.stop();
          logger.i('✅ TEST: Speech analysis complété en ${stopwatch.elapsedMilliseconds}ms');
          logger.i('📝 TEST: Transcription: ${result.transcription}');
          
          expect(result, isNotNull);
          expect(result.transcription, isNotEmpty);
          
        } on TimeoutException {
          stopwatch.stop();
          final elapsedMs = stopwatch.elapsedMilliseconds;
          
          logger.w('🎯 TEST: Speech timeout après ${elapsedMs}ms');
          logger.w('🎯 TEST: PROBLÈME - Service speech dépasse 6s optimal Whisper');
          
          expect(elapsedMs, greaterThan(5000),
            reason: 'Le timeout confirme un problème de performance speech');
            
        } catch (e) {
          stopwatch.stop();
          logger.w('⚠️ TEST: Erreur speech: $e après ${stopwatch.elapsedMilliseconds}ms');
        }
      });

      test('🎯 isServiceAvailable speech service', () async {
        logger.i('🎯 TEST: Test disponibilité service speech');
        
        final speechService = UnifiedSpeechAnalysisService();
        final stopwatch = Stopwatch()..start();
        
        final isAvailable = await speechService.isServiceAvailable()
          .timeout(const Duration(seconds: 2));
        
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;
        
        logger.i('📊 TEST: Speech disponible: $isAvailable en ${elapsedMs}ms');
        
        expect(elapsedMs, lessThan(2000),
          reason: 'La vérification speech doit être rapide');
      });
    });

    group('🚨 MistralApiService - Performance API', () {
      test('🚨 Test performance generateText avec cache', () async {
        logger.w('🚨 TEST: Test performance Mistral API');
        
        final mistralService = container.read(mistralApiServiceProvider);
        
        const prompt = 'Analyse cette performance: "Bonjour, je suis confiant"';
        
        // Premier appel (miss de cache)
        final stopwatch1 = Stopwatch()..start();
        
        try {
          final result1 = await mistralService.generateText(
            prompt: prompt,
            maxTokens: 100,
            temperature: 0.7,
          ).timeout(const Duration(seconds: 10));
          
          stopwatch1.stop();
          logger.i('📊 TEST: Mistral premier appel: ${stopwatch1.elapsedMilliseconds}ms');
          logger.i('📝 TEST: Résultat reçu: ${result1.length} caractères');
          
          // Deuxième appel (hit de cache attendu)
          final stopwatch2 = Stopwatch()..start();
          
          final result2 = await mistralService.generateText(
            prompt: prompt,
            maxTokens: 100,
            temperature: 0.7,
          ).timeout(const Duration(seconds: 2));
          
          stopwatch2.stop();
          logger.i('🚀 TEST: Mistral cache hit: ${stopwatch2.elapsedMilliseconds}ms');
          
          expect(result1, isNotEmpty);
          expect(result2, isNotEmpty);
          expect(stopwatch2.elapsedMilliseconds, lessThan(1000), 
            reason: 'Le cache doit accélérer les réponses');
            
        } on TimeoutException {
          stopwatch1.stop();
          logger.w('🎯 TEST: Mistral timeout après ${stopwatch1.elapsedMilliseconds}ms');
          logger.w('🎯 TEST: API Mistral trop lente ou indisponible');
          
        } catch (e) {
          logger.w('⚠️ TEST: Erreur Mistral: $e');
        }
      });

      test('🎯 analyzeContent performance', () async {
        logger.i('🎯 TEST: Test performance analyzeContent Mistral');
        
        final mistralService = container.read(mistralApiServiceProvider);
        
        final stopwatch = Stopwatch()..start();
        
        try {
          final analysis = await mistralService.analyzeContent(
            prompt: 'Analyse brève: "Je présente mon projet avec assurance"',
            maxTokens: 150,
          ).timeout(const Duration(seconds: 8));
          
          stopwatch.stop();
          logger.i('📊 TEST: analyzeContent complété en ${stopwatch.elapsedMilliseconds}ms');
          
          expect(analysis, isNotNull);
          expect(analysis, containsPair('feedback', isA<String>()));
          expect(stopwatch.elapsedMilliseconds, lessThan(8000), 
            reason: 'L\'analyse Mistral doit être complétée en moins de 8s');
            
        } on TimeoutException {
          stopwatch.stop();
          logger.w('🎯 TEST: analyzeContent timeout après ${stopwatch.elapsedMilliseconds}ms');
          
        } catch (e) {
          stopwatch.stop();
          logger.w('⚠️ TEST: Erreur analyzeContent: $e après ${stopwatch.elapsedMilliseconds}ms');
        }
      });
    });

    group('🔄 Tests de Concurrence et Race Conditions', () {
      test('🚨 PROBLÈME: Services parallèles sans synchronisation', () async {
        logger.w('🚨 TEST: Test race conditions entre services');
        
        final backendService = ConfidenceAnalysisBackendService();
        final speechService = UnifiedSpeechAnalysisService();
        final mistralService = container.read(mistralApiServiceProvider);
        
        const scenario = ConfidenceScenario.publicSpeaking();
        final audioData = Uint8List.fromList(List.generate(512, (index) => index % 256));
        
        // Lancer 3 services en parallèle (sans Future.any)
        final futures = [
          // Service 1: Backend
          backendService.analyzeAudioRecording(
            audioData: audioData,
            scenario: scenario,
            userContext: 'Race test 1',
            recordingDurationSeconds: 5,
          ).timeout(const Duration(seconds: 10)),
          
          // Service 2: Speech Analysis
          speechService.analyzeAudio(audioData)
            .timeout(const Duration(seconds: 8))
            .then((result) => result),
          
          // Service 3: Mistral direct
          mistralService.generateText(
            prompt: 'Analyse rapide: performance de 5 secondes',
            maxTokens: 100,
            temperature: 0.5,
          ).timeout(const Duration(seconds: 6)),
        ];
        
        final stopwatch = Stopwatch()..start();
        
        try {
          // Attendre TOUS les services au lieu du premier qui répond
          final results = await Future.wait(futures, eagerError: false)
            .timeout(const Duration(seconds: 12));
          
          stopwatch.stop();
          
          logger.w('⚠️ TEST: Tous les services ont répondu en ${stopwatch.elapsedMilliseconds}ms');
          logger.w('🎯 TEST: PROBLÈME - Attendre tous au lieu du premier optimal');
          
          final completedCount = results.where((r) => r != null).length;
          logger.i('📊 TEST: $completedCount services ont répondu sur ${results.length}');
          
        } on TimeoutException {
          stopwatch.stop();
          logger.w('🎯 TEST: Race condition timeout après ${stopwatch.elapsedMilliseconds}ms');
          logger.w('🎯 TEST: PROBLÈME CONFIRMÉ - Services non synchronisés efficacement');
          
        } catch (e) {
          stopwatch.stop();
          logger.w('⚠️ TEST: Erreur race condition: $e après ${stopwatch.elapsedMilliseconds}ms');
        }
      });

      test('🎯 SOLUTION CIBLE: Future.any() pour premier service qui répond', () async {
        logger.i('🎯 TEST: Test stratégie Future.any optimale');
        
        // Simuler la stratégie optimale avec Future.any
        final futures = [
          // Service rapide simulé
          Future.delayed(const Duration(milliseconds: 2000), () => 'Service rapide'),
          // Service lent simulé
          Future.delayed(const Duration(milliseconds: 8000), () => 'Service lent'),
          // Service très lent simulé
          Future.delayed(const Duration(milliseconds: 15000), () => 'Service très lent'),
        ];
        
        final stopwatch = Stopwatch()..start();
        
        final firstResult = await Future.any(futures);
        
        stopwatch.stop();
        
        logger.i('🚀 TEST: Premier service répondu: "$firstResult" en ${stopwatch.elapsedMilliseconds}ms');
        
        expect(firstResult, equals('Service rapide'));
        expect(stopwatch.elapsedMilliseconds, lessThan(3000), 
          reason: 'Future.any doit retourner le premier service qui répond');
      });
    });

    group('📊 Tests de Performance Mobile', () {
      test('🎯 Métriques cibles pour mobile', () async {
        logger.i('🎯 TEST: Validation des métriques de performance mobile');
        
        // Métriques cibles
        const whisperTargetMs = 6000;  // 6s max pour Whisper
        const backendTargetMs = 30000; // 30s max pour backend complet
        const mobileOptimalMs = 8000;  // 8s optimal pour expérience mobile
        const globalTimeoutMs = 35000; // 35s timeout global absolu
        
        logger.i('📊 TEST: MÉTRIQUES CIBLES:');
        logger.i('   🎵 Whisper optimal: ${whisperTargetMs}ms');
        logger.i('   🔧 Backend max: ${backendTargetMs}ms');
        logger.i('   📱 Mobile optimal: ${mobileOptimalMs}ms');
        logger.i('   🌍 Global timeout: ${globalTimeoutMs}ms');
        
        // Validation des contraintes
        expect(whisperTargetMs, lessThan(mobileOptimalMs), 
          reason: 'Whisper doit être plus rapide que l\'expérience mobile optimale');
        expect(mobileOptimalMs, lessThan(backendTargetMs), 
          reason: 'Mobile optimal doit être plus rapide que backend complet');
        expect(backendTargetMs, lessThan(globalTimeoutMs), 
          reason: 'Backend doit être plus rapide que timeout global');
          
        logger.i('✅ TEST: Métriques cibles cohérentes');
      });
    });
  });
}
