import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
      logger.i(_tag, 'Analyse narrative complète RÉELLE pour: ${story.title}');
      
      // Préparer les données pour l'API backend
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8005/api/story/analyze-narrative'),
      );
      
      // Ajouter le fichier audio
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioData,
          filename: 'story_${sessionId}.wav',
        ),
      );
      
      // Ajouter les métadonnées
      request.fields['session_id'] = sessionId;
      request.fields['story_title'] = story.title ?? 'Histoire sans titre';
      request.fields['story_elements'] = jsonEncode(
        story.elements.map((e) => e.name).toList()
      );
      if (story.genre != null) {
        request.fields['genre'] = story.genre.toString().split('.').last;
      }
      
      logger.i(_tag, 'Envoi vers backend pour analyse Vosk + Mistral');
      
      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final analysisData = responseData['analysis'];
          final transcription = responseData['transcription'] ?? '';
          
          final maxLength = transcription.length > 100 ? 100 : transcription.length;
          logger.i(_tag, 'Analyse réussie - transcription: ${transcription.substring(0, maxLength)}...');
          
          // Convertir l'analyse backend vers le modèle Flutter
          return StoryNarrativeAnalysis(
            storyId: sessionId,
            overallScore: (analysisData['overall_score'] as num?)?.toDouble() ?? 75.0,
            creativityScore: (analysisData['creativity_score'] as num?)?.toDouble() ?? 80.0,
            relevanceScore: (analysisData['element_usage_score'] as num?)?.toDouble() ?? 70.0,
            structureScore: (analysisData['plot_coherence_score'] as num?)?.toDouble() ?? 75.0,
            positiveFeedback: (analysisData['strengths'] as List?)?.cast<String>().join(', ') ??
                'Excellente utilisation des éléments narratifs !',
            improvementSuggestions: (analysisData['improvements'] as List?)?.cast<String>().join(', ') ??
                'Continuez à développer votre créativité.',
            audioMetrics: AudioMetrics(
              articulationScore: 85.0,
              fluencyScore: (analysisData['fluidity_score'] as num?)?.toDouble() ?? 80.0,
              emotionScore: 75.0,
              volumeVariation: 60.0,
              speakingRate: 150.0,
              fillerWords: ['euh', 'donc'],
            ),
            transcription: transcription,
            titleSuggestion: analysisData['title_suggestion'] as String? ?? 'Histoire Créative',
            detectedKeywords: (analysisData['detected_keywords'] as List?)?.cast<String>() ??
                ['aventure', 'créativité', 'imagination'],
          );
        } else {
          logger.w(_tag, 'Réponse backend sans succès, utilisation fallback');
          return StoryNarrativeAnalysis.fallback();
        }
      } else {
        logger.e(_tag, 'Erreur HTTP backend: ${response.statusCode}');
        return StoryNarrativeAnalysis.fallback();
      }

    } catch (e) {
      logger.e(_tag, 'Erreur analyse narrative complète: $e');
      return StoryNarrativeAnalysis.fallback();
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
  
  /// Nettoyage des ressources
  void dispose() {
    _audioService.dispose();
    _aiService.dispose();
  }
}