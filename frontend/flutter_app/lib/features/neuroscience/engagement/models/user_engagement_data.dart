import 'package:equatable/equatable.dart';

class UserEngagementData extends Equatable {
  final BehavioralData behavioralData;
  final EmotionalData emotionalData;
  final CognitiveData cognitiveData;
  final DateTime timestamp;

  const UserEngagementData({
    required this.behavioralData,
    required this.emotionalData,
    required this.cognitiveData,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [behavioralData, emotionalData, cognitiveData, timestamp];
}

class BehavioralData extends Equatable {
  final List<DateTime> sessionDates;
  final List<int> sessionDurations;
  final List<ExerciseData> exerciseData;
  final Map<String, int> featureUsage;
  final List<SocialInteraction> socialInteractions;

  const BehavioralData({
    required this.sessionDates,
    required this.sessionDurations,
    required this.exerciseData,
    required this.featureUsage,
    required this.socialInteractions,
  });

  @override
  List<Object?> get props => [sessionDates, sessionDurations, exerciseData, featureUsage, socialInteractions];
}

class EmotionalData extends Equatable {
  final double satisfactionLevel;
  final double frustrationLevel;
  final double enthusiasmLevel;
  final double anxietyLevel;
  final double confidenceLevel;

  const EmotionalData({
    required this.satisfactionLevel,
    required this.frustrationLevel,
    required this.enthusiasmLevel,
    required this.anxietyLevel,
    required this.confidenceLevel,
  });

  @override
  List<Object?> get props => [satisfactionLevel, frustrationLevel, enthusiasmLevel, anxietyLevel, confidenceLevel];
}

class CognitiveData extends Equatable {
  final double attentionLevel;
  final double comprehensionLevel;
  final double memorizationLevel;
  final double reflectionLevel;
  final double creativityLevel;

  const CognitiveData({
    required this.attentionLevel,
    required this.comprehensionLevel,
    required this.memorizationLevel,
    required this.reflectionLevel,
    required this.creativityLevel,
  });

  @override
  List<Object?> get props => [attentionLevel, comprehensionLevel, memorizationLevel, reflectionLevel, creativityLevel];
}

// Moved from engagement_models.dart to resolve dependency issues
class ExerciseData extends Equatable {
  final double completionRate;
  const ExerciseData({required this.completionRate});
  @override
  List<Object?> get props => [completionRate];
}

class SocialInteraction extends Equatable {
  const SocialInteraction();
  @override
  List<Object?> get props => [];
}