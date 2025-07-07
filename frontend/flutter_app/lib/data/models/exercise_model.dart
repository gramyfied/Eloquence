import 'package:eloquence_2_0/domain/entities/exercise.dart';
import 'package:flutter/foundation.dart'; // Pour @required ou @non_nullable si nécessaire, mais souvent implicite

class ExerciseModel extends Exercise {
  const ExerciseModel({
    required String id,
    required String title,
    required String description,
    required ExerciseType type,
    required ExerciseDifficulty difficulty,
    required int durationInMinutes,
    bool isCompleted = false,
    DateTime? lastAttemptDate,
  }) : super(
          id: id,
          title: title,
          description: description,
          type: type,
          difficulty: difficulty,
          durationInMinutes: durationInMinutes,
          isCompleted: isCompleted,
          lastAttemptDate: lastAttemptDate,
        );

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ExerciseType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => ExerciseType.conversation), // Default value if not found
      difficulty: ExerciseDifficulty.values.firstWhere(
          (e) => e.toString().split('.').last == json['difficulty'],
          orElse: () => ExerciseDifficulty.beginner), // Default value
      durationInMinutes: json['durationInMinutes'],
      isCompleted: json['isCompleted'] ?? false,
      lastAttemptDate: json['lastAttemptDate'] != null
          ? DateTime.parse(json['lastAttemptDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'durationInMinutes': durationInMinutes,
      'isCompleted': isCompleted,
      'lastAttemptDate': lastAttemptDate?.toIso8601String(),
    };
  }

  // Convert an Exercise entity to an ExerciseModel
  factory ExerciseModel.fromEntity(Exercise entity) {
    return ExerciseModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      difficulty: entity.difficulty,
      durationInMinutes: entity.durationInMinutes,
      isCompleted: entity.isCompleted,
      lastAttemptDate: entity.lastAttemptDate,
    );
  }

  // Convert an ExerciseType string to enum
  static ExerciseType _parseExerciseType(String typeString) {
    return ExerciseType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => ExerciseType.conversation, // Default if not found
    );
  }

  // Convert an ExerciseDifficulty string to enum
  static ExerciseDifficulty _parseExerciseDifficulty(String difficultyString) {
    return ExerciseDifficulty.values.firstWhere(
      (e) => e.toString().split('.').last == difficultyString,
      orElse: () => ExerciseDifficulty.beginner, // Default if not found
    );
  }

  // Convert ExerciseModel to Exercise entity
  Exercise toEntity() {
    return this;
  }
}