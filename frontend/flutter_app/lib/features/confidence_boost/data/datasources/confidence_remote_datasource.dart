import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../data/services/api_service.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';

abstract class ConfidenceRemoteDataSource {
  Future<List<ConfidenceScenario>> getScenarios();
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
        overallScore: 0.84, // Valeur moyenne simulée
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
      type: ConfidenceScenarioType.values.firstWhere((e) => e.name == json['type'], orElse: () => ConfidenceScenarioType.presentation),
      durationSeconds: json['duration_seconds'],
      tips: List<String>.from(json['tips'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      difficulty: json['difficulty'] ?? 'intermediate',
      icon: json['icon'] ?? '🎯',
    );
  }
}