import 'package:equatable/equatable.dart';
import 'confidence_scenario.dart';

/// Représente une session d'exercice Confidence Boost
class ConfidenceSession extends Equatable {
  final String id;
  final String userId;
  final ConfidenceScenario scenario;
  final DateTime startTime;
  final DateTime? endTime;
  final int recordingDurationSeconds;
  final String? audioFilePath;
  final ConfidenceAnalysis? analysis;
  final List<String> achievedBadges;
  final bool isCompleted;
  final List<String> unlockedBadges; // Badges débloqués pendant cette session

  const ConfidenceSession({
    required this.id,
    required this.userId,
    required this.scenario,
    required this.startTime,
    this.endTime,
    required this.recordingDurationSeconds,
    this.audioFilePath,
    this.analysis,
    this.achievedBadges = const [],
    this.isCompleted = false,
    this.unlockedBadges = const [],
  });

  /// Durée totale de la session en secondes
  int get totalDurationSeconds {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inSeconds;
  }

  /// Copie avec modifications
  ConfidenceSession copyWith({
    String? id,
    String? userId,
    ConfidenceScenario? scenario,
    DateTime? startTime,
    DateTime? endTime,
    int? recordingDurationSeconds,
    String? audioFilePath,
    ConfidenceAnalysis? analysis,
    List<String>? achievedBadges,
    bool? isCompleted,
    List<String>? unlockedBadges,
  }) {
    return ConfidenceSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scenario: scenario ?? this.scenario,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recordingDurationSeconds: recordingDurationSeconds ?? this.recordingDurationSeconds,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      analysis: analysis ?? this.analysis,
      achievedBadges: achievedBadges ?? this.achievedBadges,
      isCompleted: isCompleted ?? this.isCompleted,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        scenario,
        startTime,
        endTime,
        recordingDurationSeconds,
        audioFilePath,
        analysis,
        achievedBadges,
        isCompleted,
        unlockedBadges,
      ];
}

/// Analyse de la session de confiance
class ConfidenceAnalysis extends Equatable {
  final double confidenceScore;
  final double fluencyScore;
  final double clarityScore;
  final double energyScore;
  final int wordCount;
  final double speakingRate; // mots par minute
  final List<String> keywordsUsed;
  final String transcription;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> improvementSuggestions; // Suggestions d'amélioration spécifiques

  const ConfidenceAnalysis({
    required this.confidenceScore,
    required this.fluencyScore,
    required this.clarityScore,
    required this.energyScore,
    required this.wordCount,
    required this.speakingRate,
    required this.keywordsUsed,
    required this.transcription,
    required this.feedback,
    required this.strengths,
    required this.improvements,
    this.improvementSuggestions = const [],
  });

  /// Score global (moyenne pondérée)
  double get overallScore {
    return (confidenceScore * 0.4 +
            fluencyScore * 0.2 +
            clarityScore * 0.2 +
            energyScore * 0.2) /
        1.0;
  }

  @override
  List<Object?> get props => [
        confidenceScore,
        fluencyScore,
        clarityScore,
        energyScore,
        wordCount,
        speakingRate,
        keywordsUsed,
        transcription,
        feedback,
        strengths,
        improvements,
        improvementSuggestions,
      ];
}