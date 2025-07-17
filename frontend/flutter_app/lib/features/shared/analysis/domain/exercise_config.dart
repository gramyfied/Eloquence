import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../confidence_boost/domain/entities/confidence_scenario.dart';

part 'exercise_config.freezed.dart';
part 'exercise_config.g.dart';

@freezed
abstract class ExerciseConfig with _$ExerciseConfig {
  const factory ExerciseConfig.confidence({
    required ConfidenceScenario scenario,
    @Default([]) List<String> keywords,
    @Default(60) int expectedDuration,
    @Default({}) Map<String, dynamic> additionalParams,
  }) = ConfidenceConfig;
  
  // Futurs exercices extensibles
  const factory ExerciseConfig.pronunciation({
    required String targetText,
    required String language,
    @Default(0.8) double accuracyThreshold,
    @Default({}) Map<String, dynamic> additionalParams,
  }) = PronunciationConfig;
  
  const factory ExerciseConfig.fluency({
    required String topic,
    required int targetDuration,
    @Default(120) int targetWordsPerMinute,
    @Default({}) Map<String, dynamic> additionalParams,
  }) = FluencyConfig;

  factory ExerciseConfig.fromJson(Map<String, dynamic> json) => _$ExerciseConfigFromJson(json);
}