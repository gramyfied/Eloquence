import 'package:equatable/equatable.dart';

class UserPerformance extends Equatable {
  final String id;
  final String exerciseType;
  final int durationInMinutes;
  final double completionRate;
  final List<dynamic> skillsData; // Ou une classe SkillData si définie
  final DateTime timestamp;
  final double score;

  const UserPerformance({
    required this.id,
    required this.exerciseType,
    required this.durationInMinutes,
    required this.completionRate,
    this.skillsData = const [],
    required this.timestamp,
    required this.score,
  });

  bool isExceptional() {
    // Logique pour déterminer si la performance est exceptionnelle
    return score > 0.9;
  }

  // Ajout de copyWith pour faciliter les modifications si nécessaire
  UserPerformance copyWith({
    String? id,
    String? exerciseType,
    int? durationInMinutes,
    double? completionRate,
    List<dynamic>? skillsData,
    DateTime? timestamp,
    double? score,
  }) {
    return UserPerformance(
      id: id ?? this.id,
      exerciseType: exerciseType ?? this.exerciseType,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      completionRate: completionRate ?? this.completionRate,
      skillsData: skillsData ?? this.skillsData,
      timestamp: timestamp ?? this.timestamp,
      score: score ?? this.score,
    );
  }

  @override
  List<Object?> get props => [
        id,
        exerciseType,
        durationInMinutes,
        completionRate,
        skillsData,
        timestamp,
        score,
      ];
}