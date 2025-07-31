import 'package:flutter/material.dart';

/// Types de scénarios disponibles
enum ScenarioType {
  jobInterview,
  salesPitch,
  presentation,
  networking,
}

extension ScenarioTypeExtension on ScenarioType {
  String get displayName {
    switch (this) {
      case ScenarioType.jobInterview:
        return "Entretien d'Embauche";
      case ScenarioType.salesPitch:
        return "Argumentaire de Vente";
      case ScenarioType.presentation:
        return "Présentation";
      case ScenarioType.networking:
        return "Réseautage";
    }
  }

  String get emoji {
    switch (this) {
      case ScenarioType.jobInterview:
        return "👤";
      case ScenarioType.salesPitch:
        return "💼";
      case ScenarioType.presentation:
        return "🎤";
      case ScenarioType.networking:
        return "🤝";
    }
  }

  String get description {
    switch (this) {
      case ScenarioType.jobInterview:
        return "Pratiquez vos compétences d'entretien";
      case ScenarioType.salesPitch:
        return "Maîtrisez les techniques de persuasion";
      case ScenarioType.presentation:
        return "Confiance en prise de parole publique";
      case ScenarioType.networking:
        return "Compétences de conversation sociale";
    }
  }
}

/// Types de personnalité IA
enum AIPersonalityType {
  friendly,
  professional,
  challenging,
  supportive,
}

extension AIPersonalityTypeExtension on AIPersonalityType {
  String get displayName {
    switch (this) {
      case AIPersonalityType.friendly:
        return "Amical";
      case AIPersonalityType.professional:
        return "Professionnel";
      case AIPersonalityType.challenging:
        return "Exigeant";
      case AIPersonalityType.supportive:
        return "Bienveillant";
    }
  }

  String get description {
    switch (this) {
      case AIPersonalityType.friendly:
        return "Approche chaleureuse et encourageante";
      case AIPersonalityType.professional:
        return "Axé business et direct";
      case AIPersonalityType.challenging:
        return "Vous pousse à exceller";
      case AIPersonalityType.supportive:
        return "Patient et compréhensif";
    }
  }
}

/// Configuration d'un scénario
class ScenarioConfiguration {
  final ScenarioType type;
  final double difficulty; // 0.0 = Easy, 1.0 = Hard
  final int durationMinutes;
  final AIPersonalityType personality;

  const ScenarioConfiguration({
    required this.type,
    required this.difficulty,
    required this.durationMinutes,
    required this.personality,
  });

  ScenarioConfiguration copyWith({
    ScenarioType? type,
    double? difficulty,
    int? durationMinutes,
    AIPersonalityType? personality,
  }) {
    return ScenarioConfiguration(
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      personality: personality ?? this.personality,
    );
  }

  String get difficultyLabel {
    if (difficulty <= 0.33) return "Facile";
    if (difficulty <= 0.66) return "Moyen";
    return "Difficile";
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'difficulty': difficulty,
      'durationMinutes': durationMinutes,
      'personality': personality.name,
    };
  }

  factory ScenarioConfiguration.fromJson(Map<String, dynamic> json) {
    return ScenarioConfiguration(
      type: ScenarioType.values.firstWhere((e) => e.name == json['type']),
      difficulty: json['difficulty']?.toDouble() ?? 0.5,
      durationMinutes: json['durationMinutes'] ?? 10,
      personality: AIPersonalityType.values.firstWhere((e) => e.name == json['personality']),
    );
  }
}

/// Métriques temps réel pendant l'exercice
class ExerciseMetrics {
  final int wordCount;
  final Duration elapsed;
  final double averageWpm; // Words per minute
  final List<double> audioLevels; // Pour la waveform
  final int pauseCount;
  final double confidenceScore; // 0.0 - 1.0

  const ExerciseMetrics({
    required this.wordCount,
    required this.elapsed,
    required this.averageWpm,
    required this.audioLevels,
    required this.pauseCount,
    required this.confidenceScore,
  });

  ExerciseMetrics copyWith({
    int? wordCount,
    Duration? elapsed,
    double? averageWpm,
    List<double>? audioLevels,
    int? pauseCount,
    double? confidenceScore,
  }) {
    return ExerciseMetrics(
      wordCount: wordCount ?? this.wordCount,
      elapsed: elapsed ?? this.elapsed,
      averageWpm: averageWpm ?? this.averageWpm,
      audioLevels: audioLevels ?? this.audioLevels,
      pauseCount: pauseCount ?? this.pauseCount,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  static ExerciseMetrics empty() {
    return const ExerciseMetrics(
      wordCount: 0,
      elapsed: Duration.zero,
      averageWpm: 0.0,
      audioLevels: [],
      pauseCount: 0,
      confidenceScore: 0.0,
    );
  }
}

/// Suggestion d'aide pendant l'exercice
class HelpSuggestion {
  final String category;
  final String title;
  final String content;
  final List<String> keyPhrases;

  const HelpSuggestion({
    required this.category,
    required this.title,
    required this.content,
    required this.keyPhrases,
  });
}

/// État de l'exercice en cours
enum ExerciseState {
  notStarted,
  recording,
  paused,
  completed,
  error,
}

/// Session d'exercice complète
class ExerciseSession {
  final String id;
  final ScenarioConfiguration configuration;
  final DateTime startTime;
  final DateTime? endTime;
  final ExerciseState state;
  final ExerciseMetrics metrics;
  final List<String> aiMessages;
  final List<String> userTranscripts;
  final int helpUsedCount;

  const ExerciseSession({
    required this.id,
    required this.configuration,
    required this.startTime,
    this.endTime,
    required this.state,
    required this.metrics,
    required this.aiMessages,
    required this.userTranscripts,
    required this.helpUsedCount,
  });

  ExerciseSession copyWith({
    String? id,
    ScenarioConfiguration? configuration,
    DateTime? startTime,
    DateTime? endTime,
    ExerciseState? state,
    ExerciseMetrics? metrics,
    List<String>? aiMessages,
    List<String>? userTranscripts,
    int? helpUsedCount,
  }) {
    return ExerciseSession(
      id: id ?? this.id,
      configuration: configuration ?? this.configuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      state: state ?? this.state,
      metrics: metrics ?? this.metrics,
      aiMessages: aiMessages ?? this.aiMessages,
      userTranscripts: userTranscripts ?? this.userTranscripts,
      helpUsedCount: helpUsedCount ?? this.helpUsedCount,
    );
  }

  Duration get totalDuration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isActive => state == ExerciseState.recording || state == ExerciseState.paused;
  bool get isCompleted => state == ExerciseState.completed;
}
