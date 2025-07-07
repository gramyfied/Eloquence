import 'package:equatable/equatable.dart';

enum LearningStyle { visual, auditory, kinesthetic, readWrite }

enum ExperienceLevel { beginner, intermediate, advanced, expert }

class UserProfile extends Equatable {
  final String userId;
  final String username;
  final ExperienceLevel experienceLevel;
  final double recentPerformanceAverage;
  final LearningStyle? preferredLearningStyle;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.experienceLevel,
    this.recentPerformanceAverage = 0.0,
    this.preferredLearningStyle,
  });

  UserProfile copyWith({
    String? userId,
    String? username,
    ExperienceLevel? experienceLevel,
    double? recentPerformanceAverage,
    LearningStyle? preferredLearningStyle,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      recentPerformanceAverage: recentPerformanceAverage ?? this.recentPerformanceAverage,
      preferredLearningStyle: preferredLearningStyle ?? this.preferredLearningStyle,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        username,
        experienceLevel,
        recentPerformanceAverage,
        preferredLearningStyle,
      ];
}