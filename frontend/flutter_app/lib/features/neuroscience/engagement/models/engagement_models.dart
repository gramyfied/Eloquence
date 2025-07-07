import 'package:equatable/equatable.dart';

// Enums
enum InterventionType {
  rewardAdjustment,
  feedbackLoopModification,
  progressionPathAdjustment,
  habitReinforcement,
  noveltyInjection,
}

enum CheckpointType {
  shortTerm,
  mediumTerm,
}

enum DisengagementType {
  lowUsageFrequency,
  shortSessions,
  lowCompletionRate,
  highFrustration,
  highAnxiety,
  lowAttention,
}

enum OpportunityType {
  highEnthusiasm,
  highConfidence,
  highExploration,
}

// Main Data Carrier Classes
class EngagementOptimization extends Equatable {
  final EngagementAnalysis analysis;
  final EngagementPrediction prediction;
  final List<EngagementIntervention> interventions;
  final List<EngagementCheckpoint> scheduledCheckpoints;

  const EngagementOptimization({
    required this.analysis,
    required this.prediction,
    required this.interventions,
    required this.scheduledCheckpoints,
  });

  @override
  List<Object?> get props => [analysis, prediction, interventions, scheduledCheckpoints];
}

class EngagementAnalysis extends Equatable {
  final BehavioralMetrics behavioralMetrics;
  final EmotionalMetrics emotionalMetrics;
  final CognitiveMetrics cognitiveMetrics;
  final List<DisengagementSign> disengagementSigns;
  final List<EngagementOpportunity> engagementOpportunities;

  const EngagementAnalysis({
    required this.behavioralMetrics,
    required this.emotionalMetrics,
    required this.cognitiveMetrics,
    required this.disengagementSigns,
    required this.engagementOpportunities,
  });

  @override
  List<Object?> get props => [
        behavioralMetrics,
        emotionalMetrics,
        cognitiveMetrics,
        disengagementSigns,
        engagementOpportunities,
      ];
}

class EngagementPrediction extends Equatable {
  final double shortTermEngagement;
  final double mediumTermEngagement;
  final double longTermEngagement;
  final double churnRisk;
  final double habitFormationProbability;
  final double skillProgressionRate;

  const EngagementPrediction({
    required this.shortTermEngagement,
    required this.mediumTermEngagement,
    required this.longTermEngagement,
    required this.churnRisk,
    required this.habitFormationProbability,
    required this.skillProgressionRate,
  });

  @override
  List<Object?> get props => [
        shortTermEngagement,
        mediumTermEngagement,
        longTermEngagement,
        churnRisk,
        habitFormationProbability,
        skillProgressionRate,
      ];
}

// Metrics Classes
class BehavioralMetrics extends Equatable {
  final double usageFrequency;
  final double averageSessionDuration;
  final double exerciseCompletionRate;
  final double explorationRate;
  final double socialEngagementRate;

  const BehavioralMetrics({
    required this.usageFrequency,
    required this.averageSessionDuration,
    required this.exerciseCompletionRate,
    required this.explorationRate,
    required this.socialEngagementRate,
  });

  @override
  List<Object?> get props => [
        usageFrequency,
        averageSessionDuration,
        exerciseCompletionRate,
        explorationRate,
        socialEngagementRate,
      ];
}

class EmotionalMetrics extends Equatable {
  final double satisfactionScore;
  final double frustrationScore;
  final double enthusiasmScore;
  final double anxietyScore;
  final double confidenceScore;

  const EmotionalMetrics({
    required this.satisfactionScore,
    required this.frustrationScore,
    required this.enthusiasmScore,
    required this.anxietyScore,
    required this.confidenceScore,
  });

  @override
  List<Object?> get props => [
        satisfactionScore,
        frustrationScore,
        enthusiasmScore,
        anxietyScore,
        confidenceScore,
      ];
}

class CognitiveMetrics extends Equatable {
  final double attentionScore;
  final double comprehensionScore;
  final double memorizationScore;
  final double reflectionScore;
  final double creativityScore;

  const CognitiveMetrics({
    required this.attentionScore,
    required this.comprehensionScore,
    required this.memorizationScore,
    required this.reflectionScore,
    required this.creativityScore,
  });

  @override
  List<Object?> get props => [
        attentionScore,
        comprehensionScore,
        memorizationScore,
        reflectionScore,
        creativityScore,
      ];
}

// Signs and Opportunities
class DisengagementSign extends Equatable {
  final DisengagementType type;
  final double severity;
  final String metric;
  final double value;

  const DisengagementSign({
    required this.type,
    required this.severity,
    required this.metric,
    required this.value,
  });

  @override
  List<Object?> get props => [type, severity, metric, value];
}

class EngagementOpportunity extends Equatable {
  final OpportunityType type;
  final double potentialImpact;
  final InterventionType recommendedIntervention;

  const EngagementOpportunity({
    required this.type,
    required this.potentialImpact,
    required this.recommendedIntervention,
  });

  @override
  List<Object?> get props => [type, potentialImpact, recommendedIntervention];
}

// Interventions
abstract class EngagementIntervention extends Equatable {
  final InterventionType type;
  final int priority;
  final Duration duration;

  const EngagementIntervention({
    required this.type,
    required this.priority,
    required this.duration,
  });

  @override
  List<Object?> get props => [type, priority, duration];
}

class RewardAdjustmentIntervention extends EngagementIntervention {
  final String rewardType;
  final double adjustmentFactor;

  const RewardAdjustmentIntervention({
    required InterventionType type,
    required int priority,
    required Duration duration,
    required this.rewardType,
    required this.adjustmentFactor,
  }) : super(type: type, priority: priority, duration: duration);

  @override
  List<Object?> get props => [...super.props, rewardType, adjustmentFactor];
}

class FeedbackLoopModificationIntervention extends EngagementIntervention {
  final String loopType;
  final Map<String, dynamic> modifications;

  const FeedbackLoopModificationIntervention({
    required InterventionType type,
    required int priority,
    required Duration duration,
    required this.loopType,
    required this.modifications,
  }) : super(type: type, priority: priority, duration: duration);

  @override
  List<Object?> get props => [...super.props, loopType, modifications];
}

class ProgressionPathAdjustmentIntervention extends EngagementIntervention {
  final double difficultyAdjustment;
  final List<String> focusSkills;

  const ProgressionPathAdjustmentIntervention({
    required InterventionType type,
    required int priority,
    required Duration duration,
    required this.difficultyAdjustment,
    required this.focusSkills,
  }) : super(type: type, priority: priority, duration: duration);

  @override
  List<Object?> get props => [...super.props, difficultyAdjustment, focusSkills];
}

class HabitReinforcementIntervention extends EngagementIntervention {
  final String habitType;
  final String reinforcementType;

  const HabitReinforcementIntervention({
    required InterventionType type,
    required int priority,
    required Duration duration,
    required this.habitType,
    required this.reinforcementType,
  }) : super(type: type, priority: priority, duration: duration);

  @override
  List<Object?> get props => [...super.props, habitType, reinforcementType];
}

class NoveltyInjectionIntervention extends EngagementIntervention {
  final String noveltyType;
  final double intensity;

  const NoveltyInjectionIntervention({
    required InterventionType type,
    required int priority,
    required Duration duration,
    required this.noveltyType,
    required this.intensity,
  }) : super(type: type, priority: priority, duration: duration);

  @override
  List<Object?> get props => [...super.props, noveltyType, intensity];
}

// Checkpoints
class EngagementCheckpoint extends Equatable {
  final CheckpointType type;
  final DateTime scheduledDate;
  final List<String> metrics;
  final Map<String, double> thresholds;

  const EngagementCheckpoint({
    required this.type,
    required this.scheduledDate,
    required this.metrics,
    required this.thresholds,
  });

  @override
  List<Object?> get props => [type, scheduledDate, metrics, thresholds];
}

// These models have been moved to user_engagement_data.dart to avoid circular dependencies.