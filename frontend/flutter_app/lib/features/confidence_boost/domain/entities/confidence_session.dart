import 'package:equatable/equatable.dart';
import 'confidence_models.dart' as confidence_models;
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
  final confidence_models.ConfidenceAnalysis? analysis;
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
    confidence_models.ConfidenceAnalysis? analysis,
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
