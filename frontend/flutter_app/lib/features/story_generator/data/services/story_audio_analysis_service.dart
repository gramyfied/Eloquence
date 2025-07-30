import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../confidence_boost/data/services/universal_audio_exercise_service.dart';
import '../../domain/entities/story_models.dart';
import 'story_collaboration_ai_service.dart';

/// Service d'analyse audio spécialisé pour le générateur d'histoires
/// Utilise le UniversalAudioExerciseService comme endpoint optimal
class StoryAudioAnalysisService {
  final UniversalAudioExerciseService _audioService;
  final StoryCollaborationAIService _aiService;
  final String _tag = 'StoryAudioAnalysis';

  StoryAudioAnalysisService({
    UniversalAudioExerciseService? audioService,
    StoryCollaborationAIService? aiService,
  }) : _audioService = audioService ?? UniversalAudioExerciseService(),
       _aiService = aiService ?? StoryCollaborationAIService();

  /// Configuration d'exercice optimisée pour les histoires
  AudioExerciseConfig _createStoryConfig(List<StoryElement> elements, StoryGenre? genre) {
    return AudioExerciseConfig(
      exerciseId: 'story_generator_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Générateur d\'Histoires',
      description: 'Création d\'une histoire avec éléments imposés',
      scenario: 'story_generation',
      language: 'fr',
      maxDuration: const Duration(seconds: 90),
      enableRealTimeEvaluation: true,
      enableTTS: false, // Pas de TTS, juste analyse
      enableSTT: true,  // Transcription active
      customSettings: {
        'exercise_type': 'story_narration',
        'story_elements': elements.map((e) => e.name).toList(),
        'story_genre': genre?.toString().split('.').last ?? 'libre',
        'focus_areas': ['creativity', 'fluency', 'narrative_coherence'],
        'enable_ai_interventions': true,
        'intervention_threshold': 0.3, // Seuil pour les interventions IA
        'real_time_feedback': true,
      },
    );
  }

  /// Démarre une session d'analyse narrative
  Future<String> startStorySession({
    required List<StoryElement> elements,
    StoryGenre? genre,
  }) async {
    try {
      logger.i(_tag, 'Démarrage session narrative avec ${elements.length} éléments');
      
      // Vérifier la santé du service
      final isHealthy = await _audioService.checkHealth();
      if (!isHealthy) {
        throw Exception('Service audio non disponible');
      }

      // Créer la configuration d'exercice optimisée
      final config = _createStoryConfig(elements, genre);
      
      // Démarrer l'exercice audio
      final sessionId = await _audioService.startExercise(config);
      
      logger.i(_tag, 'Session narrative créée: $sessionId');
      return sessionId;
      
    } catch (e) {
      logger.e(_tag, 'Erreur démarrage session narrative: $e');
      rethrow;
    }
  }

  /// Connecte le WebSocket pour l'analyse temps réel
  Future<void> connectRealtimeAnalysis(String sessionId) async {
    try {
      logger.i(_tag, 'Connexion analyse temps réel: $sessionId');
      await _audioService.connectExerciseWebSocket(sessionId);
    } catch (e) {
      logger.e(_tag, 'Erreur connexion temps réel: $e');
      rethrow;
    }
  }

  /// Stream d'état de l'exercice narratif
  Stream<AudioExerciseState> get narrativeStateStream => _audioService.stateStream;

  /// Stream des messages d'échange (transcription, analyses)
  Stream<AudioExchangeMessage> get narrativeMessageStream => _audioService.messageStream;

  /// Stream des métriques temps réel
  Stream<Map<String, dynamic>> get realtimeMetricsStream => _audioService.realTimeMetricsStream;

  /// Analyse narrative complète avec audio
  Future<StoryNarrativeAnalysis> analyzeCompleteNarrative({
    required String sessionId,
    required Story story,
    required Uint8List audioData,
  }) async {
    try {
      logger.i(_tag, 'Analyse narrative complète pour: ${story.title}');

      // 1. Analyse audio avec le service universel
      final audioAnalysis = await _audioService.sendCompleteAudio(
        sessionId: sessionId,
        audioData: audioData,
        fileName: 'story_${story.id}_${DateTime.now().millisecondsSinceEpoch}.wav',
      );

      // 2. Analyse de cohérence IA
      final narrativeAnalysis = await _aiService.analyzeStoryCoherence(
        story: story,
        fullNarrative: audioAnalysis['transcription'] ?? '',
      );

      // 3. Combiner les résultats
      return _combineAnalysisResults(audioAnalysis, narrativeAnalysis, story);

    } catch (e) {
      logger.e(_tag, 'Erreur analyse narrative complète: $e');
      return _createFallbackNarrativeAnalysis(story);
    }
  }

  /// Génère une intervention IA contextuelle
  Future<AIIntervention> generateContextualIntervention({
    required Story story,
    required String currentSegment,
    required Duration elapsedTime,
  }) async {
    try {
      logger.i(_tag, 'Génération intervention contextuelle');

      // Évaluer la performance actuelle
      final performance = await _aiService.evaluateNarrativePerformance(
        story: story,
        currentSegment: currentSegment,
        elapsedTime: elapsedTime,
      );

      // Déterminer le type d'intervention approprié
      final interventionType = _determineInterventionType(performance);

      // Générer l'intervention
      return await _aiService.generateStoryTwist(
        currentStory: story,
        availableElements: story.elements,
        config: AIInterventionConfig(
          type: interventionType,
          intensity: _calculateInterventionIntensity(performance),
          context: currentSegment,
        ),
      );

    } catch (e) {
      logger.e(_tag, 'Erreur génération intervention: $e');
      return AIIntervention(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Et si nous ajoutions une petite surprise à votre histoire ?',
        timestamp: Duration(seconds: 30),
        wasAccepted: false,
      );
    }
  }

  /// Termine la session et récupère l'évaluation finale
  Future<AudioExerciseEvaluation> completeStorySession(String sessionId) async {
    try {
      logger.i(_tag, 'Finalisation session narrative: $sessionId');
      
      final evaluation = await _audioService.completeExercise(sessionId);
      
      // Fermer la connexion WebSocket
      await _audioService.disconnectWebSocket();
      
      return evaluation;
      
    } catch (e) {
      logger.e(_tag, 'Erreur finalisation session: $e');
      rethrow;
    }
  }

  /// Combine les résultats d'analyse audio et IA
  StoryNarrativeAnalysis _combineAnalysisResults(
    Map<String, dynamic> audioAnalysis, 
    NarrativeAnalysis narrativeAnalysis,
    Story story,
  ) {
    return StoryNarrativeAnalysis(
      // Scores combinés (50% audio + 50% IA)
      overallScore: (audioAnalysis['overall_score'] as double? ?? 0.7 + narrativeAnalysis.overallScore) / 2,
      fluidityScore: audioAnalysis['fluency_score'] as double? ?? narrativeAnalysis.fluidityScore,
      creativityScore: narrativeAnalysis.creativityScore,
      coherenceScore: narrativeAnalysis.plotCoherenceScore,
      elementUsageScore: narrativeAnalysis.elementUsageScore,
      
      // Données audio
      transcription: audioAnalysis['transcription'] as String? ?? '',
      audioMetrics: AudioMetrics.fromJson(audioAnalysis['audio_metrics'] ?? {}),
      
      // Analyses IA
      narrativeFeedback: narrativeAnalysis.narrativeFeedback,
      strengths: narrativeAnalysis.strengths,
      improvements: narrativeAnalysis.improvements,
      highlightMoments: narrativeAnalysis.highlightMoments,
      
      // Métadonnées
      analysisTimestamp: DateTime.now(),
      storyDuration: story.metrics.totalDuration,
    );
  }

  /// Détermine le type d'intervention basé sur la performance
  InterventionType _determineInterventionType(Map<String, dynamic> performance) {
    final score = performance['performance_score'] as double? ?? 0.5;
    final pacing = performance['pacing_feedback'] as String? ?? '';
    
    if (score < 0.4) {
      return InterventionType.creativeBoost;
    } else if (pacing.contains('lent')) {
      return InterventionType.narrativeChallenge;
    } else if (score > 0.8) {
      return InterventionType.plotTwist;
    } else {
      return InterventionType.mysteryElement;
    }
  }

  /// Calcule l'intensité d'intervention appropriée
  double _calculateInterventionIntensity(Map<String, dynamic> performance) {
    final score = performance['performance_score'] as double? ?? 0.5;
    
    if (score < 0.3) {
      return 0.8; // Intervention forte
    } else if (score < 0.6) {
      return 0.6; // Intervention modérée
    } else {
      return 0.4; // Intervention subtile
    }
  }

  /// Analyse narrative de fallback
  StoryNarrativeAnalysis _createFallbackNarrativeAnalysis(Story story) {
    return StoryNarrativeAnalysis(
      overallScore: 0.7,
      fluidityScore: 0.7,
      creativityScore: 0.75,
      coherenceScore: 0.7,
      elementUsageScore: 0.8,
      transcription: 'Transcription non disponible',
      audioMetrics: AudioMetrics.empty(),
      narrativeFeedback: 'Belle histoire créative ! Continuez à pratiquer pour améliorer votre fluidité narrative.',
      strengths: ['Créativité', 'Utilisation des éléments'],
      improvements: ['Fluidité du récit', 'Gestion du temps'],
      highlightMoments: ['Intégration créative des éléments'],
      analysisTimestamp: DateTime.now(),
      storyDuration: story.metrics.totalDuration,
    );
  }

  /// Nettoyage des ressources
  void dispose() {
    _audioService.dispose();
    _aiService.dispose();
  }
}

/// Résultat d'analyse narrative combinant audio et IA
class StoryNarrativeAnalysis {
  final double overallScore;
  final double fluidityScore;
  final double creativityScore;
  final double coherenceScore;
  final double elementUsageScore;
  final String transcription;
  final AudioMetrics audioMetrics;
  final String narrativeFeedback;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> highlightMoments;
  final DateTime analysisTimestamp;
  final Duration storyDuration;

  const StoryNarrativeAnalysis({
    required this.overallScore,
    required this.fluidityScore,
    required this.creativityScore,
    required this.coherenceScore,
    required this.elementUsageScore,
    required this.transcription,
    required this.audioMetrics,
    required this.narrativeFeedback,
    required this.strengths,
    required this.improvements,
    required this.highlightMoments,
    required this.analysisTimestamp,
    required this.storyDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'overall_score': overallScore,
      'fluidity_score': fluidityScore,
      'creativity_score': creativityScore,
      'coherence_score': coherenceScore,
      'element_usage_score': elementUsageScore,
      'transcription': transcription,
      'audio_metrics': audioMetrics.toJson(),
      'narrative_feedback': narrativeFeedback,
      'strengths': strengths,
      'improvements': improvements,
      'highlight_moments': highlightMoments,
      'analysis_timestamp': analysisTimestamp.toIso8601String(),
      'story_duration_ms': storyDuration.inMilliseconds,
    };
  }
}

/// Métriques audio spécifiques au récit
class AudioMetrics {
  final double averageVolume;
  final double speechRate; // mots par minute
  final int pauseCount;
  final double averagePauseDuration;
  final double voiceClarity;
  final double emotionalRange;

  const AudioMetrics({
    required this.averageVolume,
    required this.speechRate,
    required this.pauseCount,
    required this.averagePauseDuration,
    required this.voiceClarity,
    required this.emotionalRange,
  });

  factory AudioMetrics.fromJson(Map<String, dynamic> json) {
    return AudioMetrics(
      averageVolume: (json['average_volume'] as num?)?.toDouble() ?? 0.0,
      speechRate: (json['speech_rate'] as num?)?.toDouble() ?? 0.0,
      pauseCount: json['pause_count'] as int? ?? 0,
      averagePauseDuration: (json['average_pause_duration'] as num?)?.toDouble() ?? 0.0,
      voiceClarity: (json['voice_clarity'] as num?)?.toDouble() ?? 0.0,
      emotionalRange: (json['emotional_range'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory AudioMetrics.empty() {
    return const AudioMetrics(
      averageVolume: 0.0,
      speechRate: 0.0,
      pauseCount: 0,
      averagePauseDuration: 0.0,
      voiceClarity: 0.0,
      emotionalRange: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_volume': averageVolume,
      'speech_rate': speechRate,
      'pause_count': pauseCount,
      'average_pause_duration': averagePauseDuration,
      'voice_clarity': voiceClarity,
      'emotional_range': emotionalRange,
    };
  }
}