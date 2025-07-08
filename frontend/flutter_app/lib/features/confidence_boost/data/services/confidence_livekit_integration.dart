import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../src/services/clean_livekit_service.dart';
import '../../../../data/services/api_service.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_session.dart';

/// Service d'intégration LiveKit pour l'exercice Confidence Boost
/// Utilise le pipeline STT/TTS/LLM existant de LiveKit
class ConfidenceLiveKitIntegration {
  final CleanLiveKitService livekitService;
  final ApiService apiService;
  static const String _tag = 'ConfidenceLiveKitIntegration';

  ConfidenceLiveKitIntegration({
    required this.livekitService,
    required this.apiService,
  });

  /// Démarre une session LiveKit pour l'exercice Confidence Boost
  Future<String?> startConfidenceSession({
    required String userId,
    required ConfidenceScenario scenario,
  }) async {
    try {
      logger.i(_tag, 'Démarrage session LiveKit pour Confidence Boost');
      
      // Créer un scénario spécialisé pour l'exercice de confiance
      final confidenceScenarioId = 'confidence_boost_${scenario.type}_${scenario.difficulty}';
      
      // Démarrer la session LiveKit avec le scénario de confiance
      final session = await apiService.startSession(
        confidenceScenarioId,
        userId,
        language: 'fr',
        goal: 'Améliorer la confiance en soi lors de ${scenario.title}',
        isMultiAgent: false,
      );

      // Connecter à LiveKit
      final connected = await livekitService.connect(
        session.livekitUrl,
        session.token,
      );

      if (connected) {
        logger.i(_tag, 'Session LiveKit connectée: ${session.sessionId}');
        return session.sessionId;
      } else {
        logger.e(_tag, 'Échec de connexion LiveKit');
        return null;
      }
    } catch (e) {
      logger.e(_tag, 'Erreur lors du démarrage de la session LiveKit: $e');
      return null;
    }
  }

  /// Envoie le contexte du scénario à l'agent LiveKit
  Future<void> sendScenarioContext(ConfidenceScenario scenario) async {
    try {
      if (!livekitService.isConnected) {
        logger.w(_tag, 'LiveKit non connecté, impossible d\'envoyer le contexte');
        return;
      }

      // Construire le message de contexte pour l'agent
      final contextMessage = _buildContextMessage(scenario);
      
      // TODO: Implémenter l'envoi de données à l'agent LiveKit
      // Pour l'instant, logger le contexte
      logger.i(_tag, 'Contexte envoyé à l\'agent: $contextMessage');
      
    } catch (e) {
      logger.e(_tag, 'Erreur lors de l\'envoi du contexte: $e');
    }
  }

  /// Démarre l'enregistrement audio via LiveKit
  Future<bool> startRecording() async {
    try {
      if (!livekitService.isConnected) {
        logger.w(_tag, 'LiveKit non connecté, impossible de démarrer l\'enregistrement');
        return false;
      }

      // Activer le microphone via LiveKit
      await livekitService.publishMyAudio();
      logger.i(_tag, 'Enregistrement audio démarré via LiveKit');
      return true;
    } catch (e) {
      logger.e(_tag, 'Erreur lors du démarrage de l\'enregistrement: $e');
      return false;
    }
  }

  /// Arrête l'enregistrement audio via LiveKit
  Future<bool> stopRecording() async {
    try {
      if (!livekitService.isConnected) {
        logger.w(_tag, 'LiveKit non connecté');
        return false;
      }

      // Désactiver le microphone via LiveKit
      await livekitService.unpublishMyAudio();
      logger.i(_tag, 'Enregistrement audio arrêté via LiveKit');
      return true;
    } catch (e) {
      logger.e(_tag, 'Erreur lors de l\'arrêt de l\'enregistrement: $e');
      return false;
    }
  }

  /// Demande une analyse de confiance à l'agent LiveKit
  Future<ConfidenceAnalysis?> requestConfidenceAnalysis({
    required ConfidenceScenario scenario,
    required int recordingDurationSeconds,
  }) async {
    try {
      if (!livekitService.isConnected) {
        logger.w(_tag, 'LiveKit non connecté, impossible de demander l\'analyse');
        return null;
      }

      // Construire la demande d'analyse
      final analysisRequest = _buildAnalysisRequest(scenario, recordingDurationSeconds);
      
      // TODO: Implémenter la communication avec l'agent LiveKit pour l'analyse
      // Pour l'instant, simuler une analyse
      logger.i(_tag, 'Demande d\'analyse envoyée: $analysisRequest');
      
      // Simuler une attente de réponse de l'agent
      await Future.delayed(const Duration(seconds: 2));
      
      // Retourner une analyse simulée pour l'instant
      return _createSimulatedAnalysis(scenario, recordingDurationSeconds);
      
    } catch (e) {
      logger.e(_tag, 'Erreur lors de la demande d\'analyse: $e');
      return null;
    }
  }

  /// Termine la session LiveKit
  Future<void> endSession(String sessionId) async {
    try {
      logger.i(_tag, 'Fin de la session LiveKit: $sessionId');
      
      // Déconnecter LiveKit
      await livekitService.disconnect();
      
      // Terminer la session côté backend
      await apiService.endSession(sessionId);
      
      logger.i(_tag, 'Session LiveKit terminée avec succès');
    } catch (e) {
      logger.e(_tag, 'Erreur lors de la fin de session: $e');
    }
  }

  /// Construit le message de contexte pour l'agent
  String _buildContextMessage(ConfidenceScenario scenario) {
    return '''
Contexte de l'exercice Confidence Boost:
- Titre: ${scenario.title}
- Type: ${scenario.type}
- Difficulté: ${scenario.difficulty}
- Description: ${scenario.description}
- Mots-clés suggérés: ${scenario.keywords.join(', ')}
- Conseils: ${scenario.tips.join(' | ')}

Mission: Analyser la performance de l'utilisateur en termes de confiance, fluidité, clarté et énergie.
Fournir des retours constructifs et encourageants.
''';
  }

  /// Construit la demande d'analyse
  String _buildAnalysisRequest(ConfidenceScenario scenario, int duration) {
    return '''
Analyse demandée pour:
- Scénario: ${scenario.title}
- Durée d'enregistrement: ${duration}s
- Critères: Confiance, Fluidité, Clarté, Énergie
- Mots-clés attendus: ${scenario.keywords.join(', ')}

Veuillez fournir une analyse détaillée avec scores et suggestions d'amélioration.
''';
  }

  /// Crée une analyse simulée (temporaire)
  ConfidenceAnalysis _createSimulatedAnalysis(ConfidenceScenario scenario, int duration) {
    // Simulation basique pour les tests
    final wordCount = duration * 2; // Estimation
    final speakingRate = (wordCount / duration) * 60;
    
    return ConfidenceAnalysis(
      confidenceScore: 0.75,
      fluencyScore: 0.80,
      clarityScore: 0.78,
      energyScore: 0.72,
      wordCount: wordCount,
      speakingRate: speakingRate,
      keywordsUsed: scenario.keywords.take(2).toList(),
      transcription: 'Transcription via LiveKit (simulée)',
      feedback: 'Bonne performance ! Votre expression via LiveKit montre de la confiance.',
      strengths: ['Expression naturelle', 'Bonne utilisation du vocabulaire'],
      improvements: ['Augmenter légèrement l\'énergie', 'Intégrer plus de mots-clés'],
    );
  }

  /// Vérifie si LiveKit est disponible et connecté
  bool get isAvailable => livekitService.isConnected;

  /// Stream pour écouter les changements d'état de LiveKit
  Stream<bool> get connectionStateStream {
    // TODO: Implémenter un stream pour les changements d'état
    return Stream.periodic(const Duration(seconds: 1), (_) => livekitService.isConnected);
  }
}