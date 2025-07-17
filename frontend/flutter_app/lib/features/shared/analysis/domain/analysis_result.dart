import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../confidence_boost/domain/entities/confidence_models.dart';

part 'analysis_result.freezed.dart';

@freezed
class AnalysisResult with _$AnalysisResult {
  const factory AnalysisResult({
    required String exerciseType,
    required String transcription,
    required Map<String, dynamic> recognitionDetails,
    required Map<String, dynamic> analysis,
    required double processingTimeMs,
    @Default(false) bool isError,
    String? errorMessage,
  }) = _AnalysisResult;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // Transformation robuste pour gérer les différents formats de l'API
    
    // Gestion du exerciseType/exercise_type
    final exerciseType = json['exerciseType'] ?? json['exercise_type'] ?? '';
    
    // Gestion du transcription (obligatoire)
    final transcription = json['transcription'] ?? '';
    
    // Gestion des recognitionDetails/recognition_details
    final recognitionDetails = json['recognitionDetails'] ?? json['recognition_details'] ?? <String, dynamic>{};
    
    // Gestion du analysis (obligatoire)
    final analysis = json['analysis'] ?? <String, dynamic>{};
    
    // Gestion du processingTimeMs/processing_time_ms
    final processingTime = json['processingTimeMs'] ?? json['processing_time_ms'] ?? 0;
    final processingTimeMs = (processingTime is num) ? processingTime.toDouble() : 0.0;
    
    // Gestion des champs booléens et optionnels
    final isError = json['isError'] ?? json['is_error'] ?? false;
    final errorMessage = json['errorMessage'] ?? json['error_message'];
    
    return AnalysisResult(
      exerciseType: exerciseType,
      transcription: transcription,
      recognitionDetails: recognitionDetails,
      analysis: analysis,
      processingTimeMs: processingTimeMs,
      isError: isError,
      errorMessage: errorMessage,
    );
  }
  
  factory AnalysisResult.createFallback({
    required String exerciseType,
    required String error,
    required double processingTime,
  }) {
    return AnalysisResult(
      exerciseType: exerciseType,
      transcription: '',
      recognitionDetails: {},
      analysis: {
        'overall_score': 0.0,
        'detailed_scores': {},
        'feedback': 'Analyse non disponible: $error',
        'recommendations': ['Vérifiez votre connexion réseau'],
      },
      processingTimeMs: processingTime,
      isError: true,
      errorMessage: error,
    );
  }
}

// Extension pour compatibilité avec l'existant
extension AnalysisResultExtension on AnalysisResult {
  /// Convertit vers ConfidenceAnalysis pour compatibilité
  ConfidenceAnalysis toConfidenceAnalysis() {
    final analysisData = analysis;
    
    // Conversion sûre des scores détaillés : int -> double
    final rawDetailedScores = analysisData['detailed_scores'] ?? {};
    final detailedScores = <String, double>{};
    
    // Convertir chaque valeur numérique en double de manière sûre
    rawDetailedScores.forEach((key, value) {
      if (value is num) {
        detailedScores[key] = value.toDouble();
      }
    });
    
    // Score global de base
    final overallScore = _safeToDouble(analysisData['overall_score']) ??
                        _safeToDouble(analysisData['score']) ?? 0.0;
    
    // ADAPTATION SPÉCIFIQUE VOSK : Si les scores détaillés sont majoritairement à 0,
    // utiliser l'overall_score comme base et redistribuer intelligemment
    final hasValidDetailedScores = detailedScores.values.where((score) => score > 0.1).length >= 3;
    
    double confidenceScore, fluencyScore, clarityScore, energyScore;
    
    if (hasValidDetailedScores) {
      // Utilisation des scores détaillés Vosk
      confidenceScore = detailedScores['speech_confidence'] ?? 0.0;
      fluencyScore = detailedScores['fluency_score'] ?? 0.0;
      clarityScore = detailedScores['clarity_score'] ?? 0.0;
      energyScore = detailedScores['energy_level'] ?? 0.0;
    } else {
      // Redistribution intelligente basée sur l'overall_score Vosk
      final baseScore = overallScore / 100.0; // Normaliser à 0-1
      
      // Utiliser les métriques Vosk disponibles avec redistribution
      final hesitationControl = detailedScores['hesitation_control'] ?? 0.0;
      final assertiveness = detailedScores['assertiveness'] ?? 0.0;
      final voskEnergyLevel = detailedScores['energy_level'] ?? 0.0;
      final keywordRelevance = detailedScores['keyword_relevance'] ?? 0.0;
      
      // Redistribution intelligente pour compenser les métriques manquantes
      confidenceScore = _calculateVoskConfidence(baseScore, hesitationControl, assertiveness);
      fluencyScore = _calculateVoskFluency(baseScore, hesitationControl, detailedScores['pause_frequency'] ?? 0.0);
      clarityScore = _calculateVoskClarity(baseScore, detailedScores['speech_confidence'] ?? 0.0);
      energyScore = voskEnergyLevel > 0 ? voskEnergyLevel : baseScore;
    }
    
    return ConfidenceAnalysis(
      overallScore: overallScore,
      confidenceScore: confidenceScore * 100,
      fluencyScore: fluencyScore * 100,
      clarityScore: clarityScore * 100,
      energyScore: energyScore * 100,
      feedback: analysisData['feedback'] ?? '',
      transcription: transcription,
      strengths: List<String>.from(analysisData['strengths'] ?? []),
      improvements: List<String>.from(analysisData['recommendations'] ?? []),
      wordCount: _safeToInt(detailedScores['word_count']) ?? 0,
      speakingRate: _safeToDouble(detailedScores['speech_rate']) ?? 0.0,
      keywordsUsed: [], // Vosk ne fournit pas cette info directement
      // Métriques spécifiques Vosk (déjà en format 0-1)
      hesitationControl: detailedScores['hesitation_control'] ?? 0.0,
      assertiveness: detailedScores['assertiveness'] ?? 0.0,
      keywordRelevance: detailedScores['keyword_relevance'] ?? 0.0,
      speechConfidence: detailedScores['speech_confidence'] ?? 0.0,
    );
  }
  
  /// Calcule le score de confiance basé sur les métriques Vosk
  double _calculateVoskConfidence(double baseScore, double hesitationControl, double assertiveness) {
    if (hesitationControl > 0 || assertiveness > 0) {
      return (hesitationControl * 0.6 + assertiveness * 0.4).clamp(0.0, 1.0);
    }
    return baseScore.clamp(0.0, 1.0);
  }
  
  /// Calcule le score de fluidité basé sur les métriques Vosk
  double _calculateVoskFluency(double baseScore, double hesitationControl, double pauseFrequency) {
    if (hesitationControl > 0) {
      final fluidityFromPauses = pauseFrequency > 0 ? (1.0 - pauseFrequency).clamp(0.0, 1.0) : 1.0;
      return (hesitationControl * 0.7 + fluidityFromPauses * 0.3).clamp(0.0, 1.0);
    }
    return baseScore.clamp(0.0, 1.0);
  }
  
  /// Calcule le score de clarté basé sur les métriques Vosk
  double _calculateVoskClarity(double baseScore, double speechConfidence) {
    return speechConfidence > 0 ? speechConfidence.clamp(0.0, 1.0) : baseScore.clamp(0.0, 1.0);
  }
  
  /// Méthode utilitaire pour conversion sûre num -> double
  double _safeToDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
  
  /// Méthode utilitaire pour conversion sûre num -> int
  int _safeToInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}