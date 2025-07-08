import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../data/services/api_service.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_session.dart';

abstract class ConfidenceRemoteDataSource {
  Future<List<ConfidenceScenario>> getScenarios();
  Future<void> saveSession(ConfidenceSession session);
  Future<List<ConfidenceSession>> getUserSessions(String userId);
  Future<ConfidenceAnalysis> analyzeAudio({
    required String audioFilePath,
    required ConfidenceScenario scenario,
  });
}

class ConfidenceRemoteDataSourceImpl implements ConfidenceRemoteDataSource {
  final ApiService apiService;
  final SupabaseClient supabaseClient;

  ConfidenceRemoteDataSourceImpl({
    required this.apiService,
    required this.supabaseClient,
  });

  @override
  Future<List<ConfidenceScenario>> getScenarios() async {
    try {
      // Récupérer les scénarios depuis Supabase
      final response = await supabaseClient
          .from('confidence_scenarios')
          .select()
          .eq('is_active', true)
          .order('created_at');

      return (response as List)
          .map((json) => _scenarioFromSupabaseJson(json))
          .toList();
    } catch (e) {
      logger.e('ConfidenceRemoteDataSource', 'Erreur lors de la récupération des scénarios: $e');
      // Retourner une liste vide en cas d'erreur
      return [];
    }
  }

  @override
  Future<void> saveSession(ConfidenceSession session) async {
    try {
      // Sauvegarder la session dans Supabase
      await supabaseClient.from('confidence_sessions').insert({
        'id': session.id,
        'user_id': session.userId,
        'scenario_id': session.scenario.id,
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'recording_duration_seconds': session.recordingDurationSeconds,
        'audio_file_path': session.audioFilePath,
        'confidence_score': session.analysis?.confidenceScore,
        'fluency_score': session.analysis?.fluencyScore,
        'clarity_score': session.analysis?.clarityScore,
        'energy_score': session.analysis?.energyScore,
        'word_count': session.analysis?.wordCount,
        'speaking_rate': session.analysis?.speakingRate,
        'keywords_used': session.analysis?.keywordsUsed,
        'transcription': session.analysis?.transcription,
        'feedback': session.analysis?.feedback,
        'strengths': session.analysis?.strengths,
        'improvements': session.analysis?.improvements,
        'achieved_badges': session.achievedBadges,
        'is_completed': session.isCompleted,
      });

      logger.i('ConfidenceRemoteDataSource', 'Session sauvegardée avec succès: ${session.id}');
    } catch (e) {
      logger.e('ConfidenceRemoteDataSource', 'Erreur lors de la sauvegarde de la session: $e');
      rethrow;
    }
  }

  @override
  Future<List<ConfidenceSession>> getUserSessions(String userId) async {
    try {
      // Récupérer les sessions de l'utilisateur depuis Supabase
      final response = await supabaseClient
          .from('confidence_sessions')
          .select('*, confidence_scenarios(*)')
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      return (response as List)
          .map((json) => _sessionFromSupabaseJson(json))
          .toList();
    } catch (e) {
      logger.e('ConfidenceRemoteDataSource', 'Erreur lors de la récupération des sessions: $e');
      return [];
    }
  }

  @override
  Future<ConfidenceAnalysis> analyzeAudio({
    required String audioFilePath,
    required ConfidenceScenario scenario,
  }) async {
    try {
      // Utiliser l'API backend pour analyser l'audio
      // Cette partie utilise les services existants (Whisper + Mistral)
      
      // Pour l'instant, retourner une analyse simulée
      // TODO: Implémenter l'appel réel à l'API d'analyse
      
      await Future.delayed(const Duration(seconds: 2)); // Simulation du temps d'analyse
      
      return ConfidenceAnalysis(
        confidenceScore: 0.85,
        fluencyScore: 0.82,
        clarityScore: 0.88,
        energyScore: 0.80,
        wordCount: 120,
        speakingRate: 150.0,
        keywordsUsed: scenario.keywords.take(3).toList(),
        transcription: 'Transcription simulée de l\'enregistrement audio...',
        feedback: 'Excellent travail ! Votre présentation était claire et engageante.',
        strengths: [
          'Bonne articulation',
          'Rythme approprié',
          'Utilisation des mots-clés',
        ],
        improvements: [
          'Ajouter plus d\'énergie dans la voix',
          'Faire des pauses plus marquées',
        ],
      );
    } catch (e) {
      logger.e('ConfidenceRemoteDataSource', 'Erreur lors de l\'analyse audio: $e');
      rethrow;
    }
  }

  // Méthodes de conversion depuis/vers Supabase JSON
  ConfidenceScenario _scenarioFromSupabaseJson(Map<String, dynamic> json) {
    return ConfidenceScenario(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      prompt: json['prompt'],
      type: _parseScenarioType(json['type']),
      durationSeconds: json['duration_seconds'],
      tips: List<String>.from(json['tips'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      difficulty: json['difficulty'] ?? 'intermediate',
      icon: json['icon'] ?? '🎯',
    );
  }

  ConfidenceSession _sessionFromSupabaseJson(Map<String, dynamic> json) {
    final scenarioJson = json['confidence_scenarios'];
    final scenario = scenarioJson != null 
        ? _scenarioFromSupabaseJson(scenarioJson)
        : _createPlaceholderScenario();

    ConfidenceAnalysis? analysis;
    if (json['confidence_score'] != null) {
      analysis = ConfidenceAnalysis(
        confidenceScore: (json['confidence_score'] as num).toDouble(),
        fluencyScore: (json['fluency_score'] as num).toDouble(),
        clarityScore: (json['clarity_score'] as num).toDouble(),
        energyScore: (json['energy_score'] as num).toDouble(),
        wordCount: json['word_count'] ?? 0,
        speakingRate: (json['speaking_rate'] as num?)?.toDouble() ?? 0.0,
        keywordsUsed: List<String>.from(json['keywords_used'] ?? []),
        transcription: json['transcription'] ?? '',
        feedback: json['feedback'] ?? '',
        strengths: List<String>.from(json['strengths'] ?? []),
        improvements: List<String>.from(json['improvements'] ?? []),
      );
    }

    return ConfidenceSession(
      id: json['id'],
      userId: json['user_id'],
      scenario: scenario,
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      recordingDurationSeconds: json['recording_duration_seconds'] ?? 0,
      audioFilePath: json['audio_file_path'],
      analysis: analysis,
      achievedBadges: List<String>.from(json['achieved_badges'] ?? []),
      isCompleted: json['is_completed'] ?? false,
    );
  }

  ConfidenceScenarioType _parseScenarioType(String type) {
    switch (type) {
      case 'team_meeting':
        return ConfidenceScenarioType.teamMeeting;
      case 'client_presentation':
        return ConfidenceScenarioType.clientPresentation;
      case 'elevator_pitch':
        return ConfidenceScenarioType.elevatorPitch;
      case 'team_motivation':
        return ConfidenceScenarioType.teamMotivation;
      case 'product_demo':
        return ConfidenceScenarioType.productDemo;
      default:
        return ConfidenceScenarioType.teamMeeting;
    }
  }

  ConfidenceScenario _createPlaceholderScenario() {
    return const ConfidenceScenario(
      id: 'placeholder',
      title: 'Scénario non disponible',
      description: 'Le scénario original n\'est plus disponible',
      prompt: 'Exprimez-vous librement',
      type: ConfidenceScenarioType.teamMeeting,
      durationSeconds: 30,
      tips: [],
      keywords: [],
      difficulty: 'beginner',
      icon: '🎯',
    );
  }
}