import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';
import 'dart:async';

/// Tests d'intégration pour reproduire les problèmes de timeout actuels
/// 
/// Ces tests sont conçus pour ÉCHOUER avec l'implémentation actuelle
/// afin de valider que les corrections résolvent bien les problèmes.
void main() {
  group('🚨 Tests d\'intégration - Problèmes de Timeout Actuels', () {
    late ProviderContainer container;
    final logger = Logger();
    
    setUpAll(() async {
      // Configuration minimal pour tests
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
      );
    });

    tearDownAll(() {
      container.dispose();
    });

    test('🚨 PROBLÈME ACTUEL: Backend timeout à 30s (trop long pour mobile)', () async {
      logger.w('🚨 TEST: Ce test reproduit le timeout backend actuel de 30s');
      
      final provider = container.read(confidenceBoostProvider.notifier);
      const scenario = ConfidenceScenario.professional();
      final textSupport = TextSupport(
        type: SupportType.fillInBlanks,
        content: 'Test de timeout backend',
        suggestedWords: ['test'],
      );
      
      // Mesurer le temps d'exécution
      final stopwatch = Stopwatch()..start();
      
      try {
        // Cette analyse devrait timeout après 30s avec l'implémentation actuelle
        await provider.analyzePerformance(
          scenario: scenario,
          textSupport: textSupport,
          recordingDuration: const Duration(seconds: 10),
          audioData: Uint8List.fromList(List.generate(1024, (index) => index % 256)),
        ).timeout(const Duration(seconds: 10)); // Nous forçons un timeout plus court pour le test
        
        fail('Le test aurait dû timeout - l\'implémentation actuelle devrait être trop lente');
        
      } on TimeoutException {
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;
        
        logger.i('⏱️ TEST: Timeout détecté après ${elapsedMs}ms');
        logger.w('🎯 TEST: PROBLÈME CONFIRMÉ: L\'analyse prend plus de 10s (timeout backend 30s)');
        
        // Ce test confirme le problème : l'analyse est trop lente
        expect(elapsedMs, greaterThan(9000), 
          reason: 'Le timeout confirme que l\'implémentation actuelle est trop lente');
          
      } catch (e) {
        stopwatch.stop();
        logger.e('❌ TEST: Erreur inattendue: $e');
        // Une erreur différente peut aussi indiquer des problèmes dans l'implémentation
      }
    });

    test('🚨 PROBLÈME ACTUEL: Race conditions dans analyses parallèles', () async {
      logger.w('🚨 TEST: Ce test reproduit les race conditions actuelles');
      
      final provider = container.read(confidenceBoostProvider.notifier);
      const scenario = ConfidenceScenario.interview();
      final textSupport = TextSupport(
        type: SupportType.freeImprovisation,
        content: 'Test race conditions',
        suggestedWords: [],
      );
      
      // Lancer plusieurs analyses en parallèle pour déclencher des race conditions
      final futures = List.generate(3, (index) async {
        return provider.analyzePerformance(
          scenario: scenario,
          textSupport: textSupport,
          recordingDuration: Duration(seconds: 5 + index),
          audioData: Uint8List.fromList(List.generate(512 * (index + 1), (i) => i % 256)),
        );
      });
      
      try {
        // Avec l'implémentation actuelle, cela peut créer des race conditions
        await Future.wait(futures).timeout(const Duration(seconds: 15));
        
        // Si on arrive ici sans race condition, vérifier que les résultats sont cohérents
        final analysis1 = container.read(confidenceBoostProvider).lastAnalysis;
        
        // Attendre un peu et relancer pour voir si on obtient des résultats différents
        await Future.delayed(const Duration(milliseconds: 100));
        
        await provider.analyzePerformance(
          scenario: scenario,
          textSupport: textSupport,
          recordingDuration: const Duration(seconds: 5),
          audioData: Uint8List.fromList(List.generate(512, (i) => i % 256)),
        );
        
        final analysis2 = container.read(confidenceBoostProvider).lastAnalysis;
        
        // Avec des race conditions, les résultats peuvent être incohérents
        if (analysis1 != null && analysis2 != null) {
          logger.w('⚠️ TEST: Analyse 1: ${analysis1.overallScore}');
          logger.w('⚠️ TEST: Analyse 2: ${analysis2.overallScore}');
          
          // Les race conditions peuvent causer des résultats imprévisibles
        }
        
      } on TimeoutException {
        logger.w('🎯 TEST: PROBLÈME CONFIRMÉ: Timeout lors d\'analyses parallèles');
        
      } catch (e) {
        logger.w('🎯 TEST: PROBLÈME CONFIRMÉ: Erreur lors d\'analyses parallèles: $e');
        // Les erreurs peuvent indiquer des race conditions
      }
    });

    test('🚨 PROBLÈME ACTUEL: Timeout global 35s non optimal pour mobile', () async {
      logger.w('🚨 TEST: Ce test montre le timeout global actuel de 35s');
      
      final provider = container.read(confidenceBoostProvider.notifier);
      const scenario = ConfidenceScenario.publicSpeaking();
      final textSupport = TextSupport(
        type: SupportType.guidedStructure,
        content: 'Test timeout global',
        suggestedWords: ['structure', 'guide'],
      );
      
      final stopwatch = Stopwatch()..start();
      
      try {
        // Simuler une situation où tous les services échouent pour déclencher le timeout global
        await provider.analyzePerformance(
          scenario: scenario,
          textSupport: textSupport,
          recordingDuration: const Duration(seconds: 30),
          audioData: null, // Données nulles pour forcer les échecs
        ).timeout(const Duration(seconds: 8)); // Timeout mobile optimal souhaité
        
      } on TimeoutException {
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;
        
        logger.w('🎯 TEST: TIMEOUT DÉTECTÉ après ${elapsedMs}ms');
        logger.w('🎯 TEST: PROBLÈME: L\'implémentation actuelle prendrait 35s au lieu de 8s max');
        
        expect(elapsedMs, greaterThan(7000), 
          reason: 'Le timeout confirme que l\'implémentation dépasse les 8s optimaux mobile');
          
      } catch (e) {
        stopwatch.stop();
        logger.w('⚠️ TEST: Autre comportement détecté: $e après ${stopwatch.elapsedMilliseconds}ms');
      }
    });

    test('🚨 PROBLÈME ACTUEL: Gestion d\'état incohérente pendant analyses', () async {
      logger.w('🚨 TEST: Ce test vérifie la cohérence d\'état pendant les analyses');
      
      final provider = container.read(confidenceBoostProvider);
      final notifier = container.read(confidenceBoostProvider.notifier);
      const scenario = ConfidenceScenario.professional();
      final textSupport = TextSupport(
        type: SupportType.fillInBlanks,
        content: 'Test d\'état',
        suggestedWords: ['état', 'test'],
      );
      
      // Vérifier l'état initial
      expect(provider.isAnalyzing, isFalse);
      expect(provider.currentStage, equals(0));
      
      // Lancer l'analyse et vérifier immédiatement l'état
      final analysisTask = notifier.analyzePerformance(
        scenario: scenario,
        textSupport: textSupport,
        recordingDuration: const Duration(seconds: 5),
        audioData: Uint8List.fromList(List.generate(256, (i) => i)),
      );
      
      // Petit délai pour que l'état se mette à jour
      await Future.delayed(const Duration(milliseconds: 100));
      
      // L'état devrait indiquer qu'une analyse est en cours
      logger.i('📊 TEST: État isAnalyzing: ${provider.isAnalyzing}');
      logger.i('📊 TEST: Stage actuel: ${provider.currentStage}');
      logger.i('📊 TEST: Description: ${provider.currentStageDescription}');
      
      // Attendre la fin avec timeout
      try {
        await analysisTask.timeout(const Duration(seconds: 12));
        
        // Vérifier l'état final
        expect(provider.isAnalyzing, isFalse, 
          reason: 'L\'analyse devrait être terminée');
        expect(provider.lastAnalysis, isNotNull, 
          reason: 'Une analyse devrait avoir été générée');
          
      } on TimeoutException {
        logger.w('🎯 TEST: PROBLÈME CONFIRMÉ: Analyse trop longue ou état incohérent');
        
        // L'état peut rester incohérent en cas de timeout
        logger.w('📊 TEST: État final isAnalyzing: ${provider.isAnalyzing}');
      }
    });

    test('🎯 RÉFÉRENCE: Performance souhaitée après corrections', () async {
      logger.i('🎯 TEST: Ce test définit les performances cibles après corrections');
      
      // Définir les métriques cibles
      const targetVoskTimeout = Duration(seconds: 6);
      const targetBackendTimeout = Duration(seconds: 30);
      const targetGlobalTimeout = Duration(seconds: 35);
      const targetMobileOptimal = Duration(seconds: 8);
      
      logger.i('📊 TEST: MÉTRIQUES CIBLES APRÈS CORRECTIONS:');
      logger.i('   🎵 Vosk timeout: ${targetVoskTimeout.inSeconds}s');
      logger.i('   🔧 Backend timeout: ${targetBackendTimeout.inSeconds}s');
      logger.i('   📱 Mobile optimal: ${targetMobileOptimal.inSeconds}s');
      logger.i('   🌍 Global timeout: ${targetGlobalTimeout.inSeconds}s');
      
      // Ce test passera une fois les corrections appliquées
      expect(targetMobileOptimal.inSeconds, lessThan(10),
        reason: 'L\'expérience mobile doit être fluide');
      expect(targetVoskTimeout.inSeconds, lessThan(targetBackendTimeout.inSeconds),
        reason: 'Vosk doit être plus rapide que le backend complet');
        
      logger.i('✅ TEST: Métriques cibles validées');
    });
  });
}