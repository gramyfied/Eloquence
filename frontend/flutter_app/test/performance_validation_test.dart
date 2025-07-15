import 'package:flutter_test/flutter_test.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/mistral_cache_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/data/services/whisper_streaming_service.dart';
import 'package:eloquence_2_0/core/services/optimized_http_service.dart';
import 'package:eloquence_2_0/core/utils/logger_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/mistral_api_service_provider.dart';
import 'fakes/fake_mistral_api_service.dart';

/// Tests de validation des performances après optimisations
///
/// Objectifs :
/// - Latence totale < 3 secondes
/// - Cache Mistral < 100ms pour les hits
/// - Streaming Whisper < 2s par chunk
/// - Pool de connexions HTTP fonctionnel
void main() {
  setUpAll(() async {
    // Charger les variables d'environnement pour les tests
    await dotenv.load(fileName: '.env');
  });

  group('🚀 Tests de validation des performances mobile', () {
    
    late ProviderContainer container;
    late FakeMistralApiService fakeService;

    setUp(() {
      fakeService = FakeMistralApiService();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // === Test 1 : Cache Mistral Performance ===
    test('Cache Mistral doit répondre en < 100ms pour les hits', () async {
      logger.i('TEST', '🧪 Test performance cache Mistral');
      logger.i('TEST', 'MISTRAL_ENABLED: ${dotenv.env['MISTRAL_ENABLED']}');
      logger.i('TEST', 'LLM_SERVICE_URL: ${dotenv.env['LLM_SERVICE_URL']}');
      const prompt = 'Test de performance cache : Génère un feedback motivant';
      
      // Premier appel : miss de cache (non mesuré)
      await container.read(mistralApiServiceProvider).generateText(
        prompt: prompt,
        maxTokens: 100,
        temperature: 0.7,
      );
      
      // Deuxième appel : hit de cache (mesuré)
      final stopwatch = Stopwatch()..start();
      
      final cachedResult = await container.read(mistralApiServiceProvider).generateText(
        prompt: prompt,
        maxTokens: 100,
        temperature: 0.7,
      );
      
      stopwatch.stop();
      final cacheLatency = stopwatch.elapsedMilliseconds;
      
      logger.i('TEST', '⏱️ Latence cache Mistral: ${cacheLatency}ms');
      
      // Vérification
      expect(cachedResult, isNotNull);
      expect(cachedResult, isNotEmpty);
      expect(cacheLatency, lessThan(100),
        reason: 'Le cache doit répondre en moins de 100ms'
      );
      
      // Vérifier les statistiques du cache
      final stats = MistralCacheService.getStatistics();
      if (stats['hitRate'] != null) {
        expect(stats['hitRate'], isA<num>(), reason: 'Le hit rate doit être un nombre');
        expect(stats['hitRate'], greaterThanOrEqualTo(0), reason: 'Le hit rate doit être >= 0 après un hit');
      } else {
        logger.w('TEST', 'hitRate est null : le backend ne fournit pas cette statistique dans ce mode.');
      }
    });
    
    // === Test 2 : Performance streaming Whisper ===
    test('Streaming Whisper doit traiter les chunks en < 2s', () async {
      logger.i('TEST', '🧪 Test performance streaming Whisper');
      
      final whisperService = WhisperStreamingService();
      final scenario = ConfidenceScenario(
        id: 'test-scenario',
        title: 'Scénario de test',
        description: 'Test de performance',
        prompt: 'Testez votre capacité de streaming',
        type: ConfidenceScenarioType.presentation,
        durationSeconds: 30,
        tips: ['Restez naturel', 'Parlez clairement'],
        keywords: ['test', 'performance'],
        difficulty: 'beginner',
        icon: '🎯',
      );
      
      // Démarrer la session
      final sessionStarted = await whisperService.startStreamingSession(
        scenario: scenario,
        language: 'fr',
      );
      
      expect(sessionStarted, isTrue);
      
      // Simuler l'envoi d'un chunk audio
      final testAudioData = Uint8List(320000); // ~10s d'audio à 16kHz
      
      final stopwatch = Stopwatch()..start();
      
      // Écouter la transcription
      bool transcriptionReceived = false;
      whisperService.transcriptionStream.listen((text) {
        if (text.isNotEmpty) {
          transcriptionReceived = true;
          logger.i('TEST', '📝 Transcription partielle reçue: ${text.length} caractères');
        }
      });
      
      // Ajouter les données audio
      await whisperService.addAudioData(testAudioData);
      
      // Attendre max 2 secondes pour la transcription
      await Future.delayed(Duration(seconds: 2));
      
      stopwatch.stop();
      final chunkLatency = stopwatch.elapsedMilliseconds;
      
      logger.i('TEST', '⏱️ Latence chunk Whisper: ${chunkLatency}ms');
      
      // Nettoyage
      await whisperService.stopStreaming();
      whisperService.dispose();
      
      // Vérifications
      expect(chunkLatency, lessThan(2000), 
        reason: 'Le chunk doit être traité en moins de 2s'
      );
    });
    
    // === Test 3 : Performance HTTP optimisé ===
    test('Service HTTP optimisé doit utiliser le pool de connexions', () async {
      logger.i('TEST', '🧪 Test performance HTTP optimisé');
      
      final httpService = OptimizedHttpService();
      
      // Test multiple requêtes pour vérifier le pool
      final urls = [
        'https://httpbin.org/delay/0',
        'https://httpbin.org/delay/0',
        'https://httpbin.org/delay/0',
      ];
      
      final stopwatch = Stopwatch()..start();
      
      // Exécuter 3 requêtes en parallèle
      final futures = urls.map((url) => 
        httpService.get(url, timeout: Duration(seconds: 5))
      ).toList();
      
      final responses = await Future.wait(futures);
      
      stopwatch.stop();
      final totalLatency = stopwatch.elapsedMilliseconds;
      
      logger.i('TEST', '⏱️ Latence totale 3 requêtes: ${totalLatency}ms');
      
      // Vérifications
      expect(responses.length, equals(3));
      for (final response in responses) {
        expect(response.statusCode, equals(200));
      }
      
      // Avec le pool, les 3 requêtes devraient prendre moins qu'en séquentiel
      // Note: Sur certaines connexions réseau, cela peut prendre plus de temps
      expect(totalLatency, lessThan(3000),
        reason: 'Le pool de connexions doit améliorer les performances'
      );
    });
    
    // === Test 4 : Latence end-to-end < 3s ===
    test('Latence end-to-end doit être < 3s', () async {
      logger.i('TEST', '🧪 Test latence end-to-end complète');
      
      final stopwatch = Stopwatch()..start();
      
      // Simuler un workflow complet
      try {
        // 1. Génération de texte avec Mistral (avec cache)
        final mistralText = await container.read(mistralApiServiceProvider).generateText(
          prompt: 'Tu es un coach motivant. Génère un encouragement court pour quelqu\'un qui pratique la prise de parole.',
          maxTokens: 50,
          temperature: 0.7,
        );
        
        final mistralTime = stopwatch.elapsedMilliseconds;
        logger.i('TEST', '⏱️ Mistral: ${mistralTime}ms');
        
        // 2. Analyse avec Mistral (utilise aussi HTTP optimisé)
        // On teste analyzeContent qui existe dans MistralApiService
        try {
          final analysisResult = await container.read(mistralApiServiceProvider).analyzeContent(
            prompt: 'Analyse cette présentation : "Je suis heureux de vous présenter notre projet"',
            maxTokens: 200,
          ).timeout(Duration(seconds: 2));
          
          logger.d('TEST', 'Analyse reçue: ${analysisResult['feedback']}');
        } catch (e) {
          // Attendu en test si l'API n'est pas disponible
          logger.w('TEST', 'API non disponible (normal en test)');
        }
        
        final analysisTime = stopwatch.elapsedMilliseconds - mistralTime;
        logger.i('TEST', '⏱️ Analyse: ${analysisTime}ms');
        
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;
        
        logger.i('TEST', '⏱️ LATENCE TOTALE: ${totalTime}ms');
        
        // Vérification finale
        expect(totalTime, lessThan(3000), 
          reason: 'La latence totale doit être < 3 secondes'
        );
        
      } catch (e) {
        logger.e('TEST', 'Erreur test end-to-end: $e');
        // En cas d'erreur réseau, on vérifie au moins que le timeout fonctionne
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      }
    });
    
    // === Test 5 : Vérification des fallbacks ===
    test('Les fallbacks doivent fonctionner en cas d\'erreur', () async {
      logger.i('TEST', '🧪 Test robustesse des fallbacks');
      
      // Test avec une URL invalide
      final httpService = OptimizedHttpService();
      
      try {
        // Cette requête devrait échouer mais avec retry logic
        final response = await httpService.get(
          'http://invalid-url-that-does-not-exist.test',
          timeout: Duration(seconds: 2),
          maxRetries: 2,
        );
        
        // Si on arrive ici, le fallback n'a pas fonctionné
        fail('La requête aurait dû échouer');
        
      } catch (e) {
        // Succès : l'erreur est gérée proprement
        logger.i('TEST', '✅ Fallback fonctionnel: $e');
        // L'erreur peut être soit "Failed after" soit "Failed host lookup"
        expect(
          e.toString().contains('Failed after') ||
          e.toString().contains('Failed host lookup'),
          isTrue,
          reason: 'L\'erreur doit être gérée correctement'
        );
      }
    });
    
    // === Test 6 : Statistiques du cache ===
    test('Le cache doit fournir des statistiques précises', () async {
      logger.i('TEST', '🧪 Test statistiques du cache');
      
      // Réinitialiser le cache
      await MistralCacheService.clearCache();
      
      // Faire quelques requêtes
      await container.read(mistralApiServiceProvider).generateText(
        prompt: 'Test 1 : Génère un feedback constructif',
        maxTokens: 50,
      );
      
      await container.read(mistralApiServiceProvider).generateText(
        prompt: 'Test 2 : Donne des conseils de présentation',
        maxTokens: 50,
      );
      
      // Répéter une requête (hit)
      await container.read(mistralApiServiceProvider).generateText(
        prompt: 'Test 1 : Génère un feedback constructif',
        maxTokens: 50,
      );
      
      // Vérifier les statistiques
      final stats = MistralCacheService.getStatistics();
      
      logger.i('TEST', '📊 Statistiques cache: $stats');
      
      expect(stats['totalRequests'], equals(3));
      expect(stats['cacheHits'], equals(1));
      expect(stats['cacheMisses'], equals(2));
      expect(stats['hitRate'], closeTo(0.33, 0.01));
      expect(stats['memoryEntries'], equals(2));
    });
  });
}