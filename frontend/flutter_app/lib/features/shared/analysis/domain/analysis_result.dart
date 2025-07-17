import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../confidence_boost/domain/entities/confidence_models.dart';

part 'analysis_result.freezed.dart';
part 'analysis_result.g.dart';

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

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => _$AnalysisResultFromJson(json);
  
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
    final detailedScores = Map<String, double>.from(analysisData['detailed_scores'] ?? {});
    
    return ConfidenceAnalysis(
      overallScore: (analysisData['overall_score'] ?? 0.0).toDouble(),
      confidenceScore: detailedScores['speech_confidence'] ?? 0.0,
      fluencyScore: detailedScores['fluency_score'] ?? 0.0,
      clarityScore: detailedScores['clarity_score'] ?? 0.0,
      energyScore: detailedScores['energy_level'] ?? 0.0,
      feedback: analysisData['feedback'] ?? '',
      transcription: transcription,
      strengths: List<String>.from(analysisData['strengths'] ?? []),
      improvements: List<String>.from(analysisData['improvements'] ?? []),
    );
  }
}