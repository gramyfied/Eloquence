import 'package:equatable/equatable.dart';
import '../../../../domain/entities/exercise.dart';

// Enums
enum NodeState { mastered, completed, inProgress, available }
enum ExerciseDuration { short, complete, standard }
enum ExerciseCount { reduced, standard }
enum AdaptationPriority { maximumImpact, balancedProgression }

// Main ProgressionPath Class
class ProgressionPath extends Equatable {
  final Map<String, double> skillProgressions;
  final List<LearningStep> learningSequence;
  final List<DynamicAdaptationRule> dynamicAdaptationRules;

  ProgressionPath()
      : skillProgressions = {},
        learningSequence = [],
        dynamicAdaptationRules = [];

  void addSkillProgression(String skill, double difficulty) {
    skillProgressions[skill] = difficulty;
  }

  void addLearningStep(LearningStep step) {
    learningSequence.add(step);
  }

  void addDynamicAdaptationRule(DynamicAdaptationRule rule) {
    dynamicAdaptationRules.add(rule);
  }

  @override
  List<Object?> get props => [skillProgressions, learningSequence, dynamicAdaptationRules];
}

// Data carrier classes
class ProgressionUpdate extends Equatable {
  final ProgressionPath newPath;
  final List<Exercise> nextExercises;
  final ProgressionVisualizations visualizations;

  const ProgressionUpdate({
    required this.newPath,
    required this.nextExercises,
    required this.visualizations,
  });

  @override
  List<Object?> get props => [newPath, nextExercises, visualizations];
}

class ProgressionVisualizations extends Equatable {
  final Map<String, double> skillMap;
  final Map<String, List<double>> progressionChart;
  final List<ProgressionNode> progressionPath;

  const ProgressionVisualizations({
    required this.skillMap,
    required this.progressionChart,
    required this.progressionPath,
  });

  @override
  List<Object?> get props => [skillMap, progressionChart, progressionPath];
}

class ProgressionNode extends Equatable {
  final String id;
  final String title;
  final String type;
  final NodeState state;

  const ProgressionNode({
    required this.id,
    required this.title,
    required this.type,
    required this.state,
  });

  @override
  List<Object?> get props => [id, title, type, state];
}

class ContextualAdaptation extends Equatable {
  final List<String> focusSkills;
  final List<String> scenarios;
  final ExerciseDuration exerciseDuration;
  final ExerciseCount exerciseCount;
  final AdaptationPriority priority;

  const ContextualAdaptation({
    this.focusSkills = const [],
    this.scenarios = const [],
    this.exerciseDuration = ExerciseDuration.standard,
    this.exerciseCount = ExerciseCount.standard,
    this.priority = AdaptationPriority.balancedProgression,
  });

  @override
  List<Object?> get props => [focusSkills, scenarios, exerciseDuration, exerciseCount, priority];
}

class LearningStep extends Equatable {
  final String type;
  final String targetSkill;
  final double difficulty;
  final int estimatedDuration;

  const LearningStep({
    required this.type,
    required this.targetSkill,
    required this.difficulty,
    required this.estimatedDuration,
  });

  @override
  List<Object?> get props => [type, targetSkill, difficulty, estimatedDuration];
}

class DynamicAdaptationRule extends Equatable {
  final String type;
  final String condition;
  final String action;
  final int priority;

  const DynamicAdaptationRule({
    required this.type,
    required this.condition,
    required this.action,
    required this.priority,
  });

  @override
  List<Object?> get props => [type, condition, action, priority];
}