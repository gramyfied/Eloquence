// Service Unifié pour la gestion centralisée de l'analyse, feedback, gamification, prosodie, etc.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import 'badge_service.dart';
import 'confidence_analysis_backend_service.dart';
import 'confidence_livekit_integration.dart';
import 'gamification_service.dart';
import 'mistral_api_service.dart';
import 'prosody_analysis_interface.dart';
import 'streak_service.dart';
import 'xp_calculator_service.dart';
import 'text_support_generator.dart';

// Imports des providers Riverpod
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/mistral_api_service_provider.dart';
import 'package:eloquence_2_0/features/confidence_boost/presentation/providers/confidence_boost_provider.dart';

class UnifiedConfidenceService {
  final IMistralApiService mistralApiService;
  final ConfidenceAnalysisBackendService analysisBackendService;
  final GamificationService gamificationService;
  final BadgeService badgeService;
  final StreakService streakService;
  final XPCalculatorService xpCalculatorService;
  final ProsodyAnalysisInterface prosodyAnalysis;
  final ConfidenceLiveKitIntegration livekitIntegration;
  final Ref ref;

  UnifiedConfidenceService({
    required this.mistralApiService,
    required this.analysisBackendService,
    required this.gamificationService,
    required this.badgeService,
    required this.streakService,
    required this.xpCalculatorService,
    required this.prosodyAnalysis,
    required this.livekitIntegration,
    required this.ref,
  });

  /// Analyse complète : audioData, scénario, textSupport, userId, durée
  Future<Map<String, dynamic>> analyzeAll({
    required Uint8List audioData,
    required ConfidenceScenario scenario,
    required TextSupport textSupport,
    required String userId,
    required Duration sessionDuration,
  }) async {
    // Analyse backend
    final analysis = await analysisBackendService.analyzeAudioRecording(
      audioData: audioData,
      scenario: scenario,
      userContext: userId,
      recordingDurationSeconds: sessionDuration.inSeconds,
    );

    // Prosodie
    final prosody = await prosodyAnalysis.analyzeProsody(
      audioData: audioData,
      scenario: scenario,
      language: 'fr',
    );

    // Feedback IA (optionnel, peut être intégré dans l'analyse)
    final feedback = await mistralApiService.generateText(
      prompt: 'Analyse ce fichier audio : ${scenario.title}',
      maxTokens: 200,
      temperature: 0.7,
    );

    // Gamification
    final gamificationResult = await gamificationService.processSessionCompletion(
      userId: userId,
      analysis: analysis!,
      scenario: scenario,
      textSupport: textSupport,
      sessionDuration: sessionDuration,
    );

    return {
      'analysis': analysis,
      'prosody': prosody,
      'feedback': feedback,
      'gamification': gamificationResult,
    };
  }

  // Factory pour TextSupportGenerator
  TextSupportGenerator getTextSupportGenerator() {
    return TextSupportGenerator(ref.read(mistralApiServiceProvider));
  }

  // Ajoutez ici d'autres méthodes unifiées selon les besoins...
}

// Provider Riverpod pour le service unifié
final unifiedConfidenceServiceProvider = Provider<UnifiedConfidenceService>((ref) {
  return UnifiedConfidenceService(
    mistralApiService: ref.read(mistralApiServiceProvider),
    analysisBackendService: ref.read(confidenceAnalysisBackendServiceProvider),
    gamificationService: ref.read(gamificationServiceProvider),
    badgeService: ref.read(badgeServiceProvider),
    streakService: ref.read(streakServiceProvider),
    xpCalculatorService: ref.read(xpCalculatorServiceProvider),
    prosodyAnalysis: ref.read(prosodyAnalysisInterfaceProvider),
    livekitIntegration: ref.read(confidenceLiveKitIntegrationProvider),
    ref: ref,
  );
});