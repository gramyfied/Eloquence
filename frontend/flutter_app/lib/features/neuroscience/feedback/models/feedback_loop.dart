import 'package:equatable/equatable.dart';
import '../../reward/models/reward.dart';

// Main FeedbackLoop class
class FeedbackLoop extends Equatable {
  final FeedbackLoopType type;
  final Trigger trigger;
  final FeedbackAction action;
  final Reward reward;
  final Investment investment;
  final int feedbackDelay; // in milliseconds
  final double predictabilityRatio; // 0.0 to 1.0

  const FeedbackLoop({
    required this.type,
    required this.trigger,
    required this.action,
    required this.reward,
    required this.investment,
    required this.feedbackDelay,
    required this.predictabilityRatio,
  });

  @override
  List<Object?> get props => [type, trigger, action, reward, investment, feedbackDelay, predictabilityRatio];
}

// Enums
enum FeedbackLoopType {
  dailyPractice,
  skillProgression,
  contextualPreparation,
  postPerformance,
  exploration,
}

enum TriggerType {
  external,
  contextual,
  internal,
}

enum InternalTriggerType {
  curiosity,
}

// Component Classes
class Trigger extends Equatable {
  final TriggerType type;
  final String message;
  final bool contextAwareness;
  final InternalTriggerType? internalTriggerReinforcement;

  const Trigger({
    required this.type,
    required this.message,
    required this.contextAwareness,
    this.internalTriggerReinforcement,
  });

  @override
  List<Object?> get props => [type, message, contextAwareness, internalTriggerReinforcement];
}

class FeedbackAction extends Equatable {
  final String type;
  final int duration;
  final double complexity;
  final String focusArea;
  final bool setupRequired;
  final bool oneButtonStart;

  const FeedbackAction({
    required this.type,
    required this.duration,
    required this.complexity,
    required this.focusArea,
    required this.setupRequired,
    required this.oneButtonStart,
  });

  @override
  List<Object?> get props => [type, duration, complexity, focusArea, setupRequired, oneButtonStart];
}

class Investment extends Equatable {
  final String type;
  final double effortRequired;
  final int timeRequired;
  final String futureBenefit;

  const Investment({
    required this.type,
    required this.effortRequired,
    required this.timeRequired,
    required this.futureBenefit,
  });

  @override
  List<Object?> get props => [type, effortRequired, timeRequired, futureBenefit];
}

// Abstract Template Class
abstract class FeedbackLoopTemplate {
  FeedbackLoop customize(dynamic userProfile);
}