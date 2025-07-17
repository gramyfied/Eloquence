import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../domain/analysis_result.dart';
import '../domain/exercise_config.dart';
import '../../../../core/services/universal_speech_analysis_service.dart';

// Provider générique pour tous exercices
class ExerciseAnalysisProvider<T extends ExerciseConfig> 
    extends StateNotifier<AsyncValue<AnalysisResult?>> {
  
  final UniversalSpeechAnalysisService _analysisService;
  final String exerciseType;
  
  ExerciseAnalysisProvider({
    required UniversalSpeechAnalysisService analysisService,
    required this.exerciseType,
  }) : _analysisService = analysisService,
       super(const AsyncValue.data(null));
  
  /// Analyse universelle
  Future<void> analyzeRecording({
    required Uint8List audioData,
    required T config,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _analysisService.analyzeAudio(
        audioData: audioData,
        exerciseType: exerciseType,
        config: config,
      );
      
      state = AsyncValue.data(result);
      
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Providers spécialisés pour chaque exercice
final confidenceAnalysisProvider =
    StateNotifierProvider<ExerciseAnalysisProvider<ConfidenceConfig>, AsyncValue<AnalysisResult?>>((ref) {
  return ExerciseAnalysisProvider<ConfidenceConfig>(
    analysisService: ref.read(universalSpeechAnalysisServiceProvider),
    exerciseType: 'confidence',
  );
});

// Futurs exercices (extensibilité triviale)
final pronunciationAnalysisProvider =
    StateNotifierProvider<ExerciseAnalysisProvider<PronunciationConfig>, AsyncValue<AnalysisResult?>>((ref) {
  return ExerciseAnalysisProvider<PronunciationConfig>(
    analysisService: ref.read(universalSpeechAnalysisServiceProvider),
    exerciseType: 'pronunciation',
  );
});

final fluencyAnalysisProvider =
    StateNotifierProvider<ExerciseAnalysisProvider<FluencyConfig>, AsyncValue<AnalysisResult?>>((ref) {
  return ExerciseAnalysisProvider<FluencyConfig>(
    analysisService: ref.read(universalSpeechAnalysisServiceProvider),
    exerciseType: 'fluency',
  );
});