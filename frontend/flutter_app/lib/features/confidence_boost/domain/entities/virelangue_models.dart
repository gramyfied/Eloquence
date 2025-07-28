import 'dart:math' as math;
import 'package:hive/hive.dart';

part 'virelangue_models.g.dart';

/// Types de gemmes collectables
@HiveType(typeId: 30)
enum GemType {
  @HiveField(0)
  ruby,      // Rubis - Commun (60%)
  @HiveField(1)
  emerald,   // Émeraude - Rare (30%)
  @HiveField(2)
  diamond    // Diamant - Légendaire (10%)
}

extension GemTypeExtension on GemType {
  String get displayName {
    switch (this) {
      case GemType.ruby:
        return 'Rubis';
      case GemType.emerald:
        return 'Émeraude';
      case GemType.diamond:
        return 'Diamant';
    }
  }

  String get emoji {
    switch (this) {
      case GemType.ruby:
        return '💎';
      case GemType.emerald:
        return '💚';
      case GemType.diamond:
        return '💍';
    }
  }

  int get baseValue {
    switch (this) {
      case GemType.ruby:
        return 1;
      case GemType.emerald:
        return 3;
      case GemType.diamond:
        return 10;
    }
  }

  double get probability {
    switch (this) {
      case GemType.ruby:
        return 0.6;  // 60%
      case GemType.emerald:
        return 0.3;  // 30%
      case GemType.diamond:
        return 0.1;  // 10%
    }
  }
}

/// Niveaux de difficulté des virelangues
@HiveType(typeId: 33)
enum VirelangueDifficulty {
  @HiveField(0)
  easy,      // Facile
  @HiveField(1)
  medium,    // Moyen
  @HiveField(2)
  hard,      // Difficile
  @HiveField(3)
  expert     // Expert
}

extension VirelangueDifficultyExtension on VirelangueDifficulty {
  String get displayName {
    switch (this) {
      case VirelangueDifficulty.easy:
        return 'Facile';
      case VirelangueDifficulty.medium:
        return 'Moyen';
      case VirelangueDifficulty.hard:
        return 'Difficile';
      case VirelangueDifficulty.expert:
        return 'Expert';
    }
  }

  double get multiplier {
    switch (this) {
      case VirelangueDifficulty.easy:
        return 1.0;
      case VirelangueDifficulty.medium:
        return 1.3;
      case VirelangueDifficulty.hard:
        return 1.6;
      case VirelangueDifficulty.expert:
        return 2.0;
    }
  }

  double get targetScore {
    switch (this) {
      case VirelangueDifficulty.easy:
        return 0.7;   // 70%
      case VirelangueDifficulty.medium:
        return 0.75;  // 75%
      case VirelangueDifficulty.hard:
        return 0.8;   // 80%
      case VirelangueDifficulty.expert:
        return 0.85;  // 85%
    }
  }
}

/// Modèle d'un virelangue
@HiveType(typeId: 31)
class Virelangue extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String text;
  
  @HiveField(2)
  VirelangueDifficulty difficulty;
  
  @HiveField(3)
  double targetScore;
  
  @HiveField(4)
  List<String> problemSounds;
  
  @HiveField(5)
  String? category;
  
  @HiveField(6)
  bool isCustomGenerated;
  
  @HiveField(7)
  DateTime? generatedAt;
  
  @HiveField(8)
  String theme;
  
  @HiveField(9)
  String language;
  
  @HiveField(10)
  String description;
  
  @HiveField(11)
  bool isCustom;
  
  @HiveField(12)
  DateTime createdAt;

  Virelangue({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.targetScore,
    this.problemSounds = const [],
    this.category,
    this.isCustomGenerated = false,
    this.generatedAt,
    this.theme = '',
    this.language = 'fr',
    this.description = '',
    this.isCustom = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Virelangue.fromJson(Map<String, dynamic> json) {
    return Virelangue(
      id: json['id'] as String,
      text: json['text'] as String,
      difficulty: VirelangueDifficulty.values[json['difficulty'] as int],
      targetScore: (json['target_score'] as num).toDouble(),
      problemSounds: List<String>.from(json['problem_sounds'] ?? []),
      category: json['category'] as String?,
      isCustomGenerated: json['is_custom_generated'] as bool? ?? false,
      generatedAt: json['generated_at'] != null 
          ? DateTime.parse(json['generated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'difficulty': difficulty.index,
      'target_score': targetScore,
      'problem_sounds': problemSounds,
      'category': category,
      'is_custom_generated': isCustomGenerated,
      'generated_at': generatedAt?.toIso8601String(),
    };
  }
}

/// Collection de gemmes d'un utilisateur
@HiveType(typeId: 32)
class GemCollection extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  Map<GemType, int> gems;
  
  @HiveField(2)
  int totalValue;
  
  @HiveField(3)
  DateTime lastUpdated;

  GemCollection({
    required this.userId,
    Map<GemType, int>? gems,
    this.totalValue = 0,
    DateTime? lastUpdated,
  }) : gems = gems ?? {GemType.ruby: 0, GemType.emerald: 0, GemType.diamond: 0},
       lastUpdated = lastUpdated ?? DateTime.now();

  /// Ajoute des gemmes à la collection
  void addGems(GemType type, int count) {
    gems[type] = (gems[type] ?? 0) + count;
    _recalculateTotalValue();
    lastUpdated = DateTime.now();
  }

  /// Recalcule la valeur totale
  void _recalculateTotalValue() {
    totalValue = gems.entries.fold(0, (sum, entry) =>
        sum + (entry.value * entry.key.baseValue));
  }

  /// Calcule la valeur totale de la collection
  int getTotalValue() {
    return totalValue;
  }

  /// Obtient le nombre total de gemmes
  int getTotalCount() {
    return gems.values.fold(0, (sum, count) => sum + count);
  }

  /// Obtient le nombre de gemmes d'un type spécifique
  int getGemCount(GemType type) {
    return gems[type] ?? 0;
  }

  // Propriétés compatibles avec l'ancienne interface
  int get rubies => gems[GemType.ruby] ?? 0;
  int get emeralds => gems[GemType.emerald] ?? 0;
  int get diamonds => gems[GemType.diamond] ?? 0;

  factory GemCollection.fromJson(Map<String, dynamic> json) {
    final gemsMap = <GemType, int>{};
    if (json['gems'] != null) {
      final gemsData = json['gems'] as Map<String, dynamic>;
      gemsData.forEach((key, value) {
        final gemType = GemType.values[int.parse(key)];
        gemsMap[gemType] = value as int;
      });
    }
    
    return GemCollection(
      userId: json['user_id'] as String,
      gems: gemsMap,
      totalValue: json['total_value'] as int? ?? 0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final gemsData = <String, int>{};
    gems.forEach((key, value) {
      gemsData[key.index.toString()] = value;
    });
    
    return {
      'user_id': userId,
      'gems': gemsData,
      'total_value': totalValue,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  GemCollection copyWith({
    String? userId,
    Map<GemType, int>? gems,
    int? totalValue,
    DateTime? lastUpdated,
  }) {
    return GemCollection(
      userId: userId ?? this.userId,
      gems: gems ?? Map.from(this.gems),
      totalValue: totalValue ?? this.totalValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Récompense de gemmes obtenue après un virelangue
class GemReward {
  final GemType type;
  final int count;
  final double multiplier;
  final String reason;

  const GemReward({
    required this.type,
    required this.count,
    required this.multiplier,
    required this.reason,
  });

  int get finalCount => (count * multiplier).round();

  factory GemReward.fromJson(Map<String, dynamic> json) {
    return GemReward(
      type: GemType.values[json['type'] as int],
      count: json['count'] as int,
      multiplier: (json['multiplier'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'count': count,
      'multiplier': multiplier,
      'reason': reason,
    };
  }
}

/// État de l'exercice de virelangues
class VirelangueExerciseState {
  final String sessionId;
  final String userId;
  final List<Virelangue> availableVirelangues;
  final Virelangue? currentVirelangue;
  final GemCollection userGems;
  final DateTime startTime;
  final DateTime? endTime;
  final int currentAttempt;
  final int maxAttempts;
  final bool isActive;
  final int currentCombo;
  final int currentStreak;
  final List<VirelanguePronunciationResult> pronunciationResults;
  final List<GemReward> collectedGems;
  final double sessionScore;
  final bool isSpecialEvent;
  final bool isLoading;
  final bool isRecording;
  final Object? error;

  const VirelangueExerciseState({
    required this.sessionId,
    required this.userId,
    required this.availableVirelangues,
    this.currentVirelangue,
    required this.userGems,
    required this.startTime,
    this.endTime,
    this.currentAttempt = 0,
    this.maxAttempts = 3,
    this.isActive = true,
    this.currentCombo = 0,
    this.currentStreak = 0,
    this.pronunciationResults = const [],
    this.collectedGems = const [],
    this.sessionScore = 0.0,
    this.isSpecialEvent = false,
    this.isLoading = false,
    this.isRecording = false,
    this.error,
  });

  /// Constructor pour état initial
  factory VirelangueExerciseState.initial({required String userId}) {
    return VirelangueExerciseState(
      sessionId: '',
      userId: userId,
      availableVirelangues: [],
      currentVirelangue: null,
      userGems: GemCollection(userId: userId),
      startTime: DateTime.now(),
      endTime: null,
      currentAttempt: 0,
      maxAttempts: 3,
      isActive: false,
      currentCombo: 0,
      currentStreak: 0,
      pronunciationResults: [],
      collectedGems: [],
      sessionScore: 0.0,
      isSpecialEvent: false,
      isLoading: false,
      isRecording: false,
      error: null,
    );
  }

  VirelangueExerciseState copyWith({
    String? sessionId,
    String? userId,
    List<Virelangue>? availableVirelangues,
    Virelangue? currentVirelangue,
    GemCollection? userGems,
    DateTime? startTime,
    DateTime? endTime,
    int? currentAttempt,
    int? maxAttempts,
    bool? isActive,
    int? currentCombo,
    int? currentStreak,
    List<VirelanguePronunciationResult>? pronunciationResults,
    List<GemReward>? collectedGems,
    double? sessionScore,
    bool? isSpecialEvent,
    bool? isLoading,
    bool? isRecording,
    Object? error,
  }) {
    return VirelangueExerciseState(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      availableVirelangues: availableVirelangues ?? this.availableVirelangues,
      currentVirelangue: currentVirelangue ?? this.currentVirelangue,
      userGems: userGems ?? this.userGems,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      isActive: isActive ?? this.isActive,
      currentCombo: currentCombo ?? this.currentCombo,
      currentStreak: currentStreak ?? this.currentStreak,
      pronunciationResults: pronunciationResults ?? this.pronunciationResults,
      collectedGems: collectedGems ?? this.collectedGems,
      sessionScore: sessionScore ?? this.sessionScore,
      isSpecialEvent: isSpecialEvent ?? this.isSpecialEvent,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      error: error ?? this.error,
    );
  }
}

/// Résultat d'analyse de prononciation d'un virelangue
class VirelanguePronunciationResult {
  final String virelangueId;
  final int attemptNumber;
  final double overallScore;
  final Map<String, double> phonemeScores;
  final List<String> detectedErrors;
  final List<String> strengths;
  final List<String> improvements;
  final Duration pronunciationTime;
  final double clarity;
  final double fluency;
  final DateTime timestamp;

  const VirelanguePronunciationResult({
    required this.virelangueId,
    required this.attemptNumber,
    required this.overallScore,
    required this.phonemeScores,
    required this.detectedErrors,
    required this.strengths,
    required this.improvements,
    required this.pronunciationTime,
    required this.clarity,
    required this.fluency,
    required this.timestamp,
  });

  bool get isSuccess => overallScore >= 0.7; // 70% minimum
  bool get isExcellent => overallScore >= 0.9; // 90% excellent

  factory VirelanguePronunciationResult.fromAudioAnalysis(
    Map<String, dynamic> audioAnalysisResult,
    {required int attemptNumber}
  ) {
    return VirelanguePronunciationResult(
      virelangueId: audioAnalysisResult['virelangue_id'] as String? ?? '',
      attemptNumber: attemptNumber,
      overallScore: (audioAnalysisResult['overall_score'] as num?)?.toDouble() ?? 0.0,
      phonemeScores: Map<String, double>.from(
        (audioAnalysisResult['phoneme_scores'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      detectedErrors: List<String>.from(audioAnalysisResult['detected_errors'] ?? []),
      strengths: List<String>.from(audioAnalysisResult['strengths'] ?? []),
      improvements: List<String>.from(audioAnalysisResult['improvements'] ?? []),
      pronunciationTime: Duration(
        milliseconds: audioAnalysisResult['pronunciation_time_ms'] as int? ?? 0,
      ),
      clarity: (audioAnalysisResult['clarity'] as num?)?.toDouble() ?? 0.0,
      fluency: (audioAnalysisResult['fluency'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }

  factory VirelanguePronunciationResult.fromJson(Map<String, dynamic> json) {
    return VirelanguePronunciationResult(
      virelangueId: json['virelangue_id'] as String,
      attemptNumber: json['attempt_number'] as int,
      overallScore: (json['overall_score'] as num).toDouble(),
      phonemeScores: Map<String, double>.from(
        (json['phoneme_scores'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      detectedErrors: List<String>.from(json['detected_errors'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      pronunciationTime: Duration(
        milliseconds: json['pronunciation_time_ms'] as int? ?? 0,
      ),
      clarity: (json['clarity'] as num?)?.toDouble() ?? 0.0,
      fluency: (json['fluency'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Configuration spécifique pour l'exercice de virelangues
class VirelangueExerciseConfig {
  final List<VirelangueDifficulty> allowedDifficulties;
  final bool enableCustomGeneration;
  final List<String>? targetSounds;
  final int maxVirelanguesPerSession;
  final bool enableSpecialEvents;
  final double gemMultiplier;

  const VirelangueExerciseConfig({
    this.allowedDifficulties = const [
      VirelangueDifficulty.easy,
      VirelangueDifficulty.medium,
      VirelangueDifficulty.hard,
    ],
    this.enableCustomGeneration = true,
    this.targetSounds,
    this.maxVirelanguesPerSession = 8,
    this.enableSpecialEvents = true,
    this.gemMultiplier = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'allowed_difficulties': allowedDifficulties.map((d) => d.index).toList(),
      'enable_custom_generation': enableCustomGeneration,
      'target_sounds': targetSounds,
      'max_virelangues_per_session': maxVirelanguesPerSession,
      'enable_special_events': enableSpecialEvents,
      'gem_multiplier': gemMultiplier,
    };
  }
}

/// Statistiques détaillées des virelangues pour un utilisateur
@HiveType(typeId: 35)
class VirelangueStats extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  int totalSessions;
  
  @HiveField(2)
  int totalVirelangues;
  
  @HiveField(3)
  double averageScore;
  
  @HiveField(4)
  double bestScore;
  
  @HiveField(5)
  int currentStreak;
  
  @HiveField(6)
  int bestStreak;
  
  @HiveField(7)
  Map<VirelangueDifficulty, int> difficultyStats;
  
  @HiveField(8)
  DateTime lastSessionDate;
  
  @HiveField(9)
  int totalTimeSpentMs;

  VirelangueStats({
    required this.userId,
    this.totalSessions = 0,
    this.totalVirelangues = 0,
    this.averageScore = 0.0,
    this.bestScore = 0.0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    Map<VirelangueDifficulty, int>? difficultyStats,
    DateTime? lastSessionDate,
    this.totalTimeSpentMs = 0,
  }) : difficultyStats = difficultyStats ?? {},
       lastSessionDate = lastSessionDate ?? DateTime.now();
}

/// Progression utilisateur pour les virelangues
@HiveType(typeId: 36)
class VirelangueUserProgress extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  int totalSessions;
  
  @HiveField(2)
  double bestScore;
  
  @HiveField(3)
  double averageScore;
  
  @HiveField(4)
  int currentCombo;
  
  @HiveField(5)
  int currentStreak;
  
  @HiveField(6)
  int totalGemValue;
  
  @HiveField(7)
  VirelangueDifficulty currentLevel;
  
  @HiveField(8)
  DateTime lastSessionDate;
  
  @HiveField(9)
  List<String> recentVirelangueIds;
  
  @HiveField(10)
  List<VirelangueDifficulty> recentDifficulties;

  VirelangueUserProgress({
    required this.userId,
    this.totalSessions = 0,
    this.bestScore = 0.0,
    this.averageScore = 0.0,
    this.currentCombo = 0,
    this.currentStreak = 0,
    this.totalGemValue = 0,
    this.currentLevel = VirelangueDifficulty.easy,
    DateTime? lastSessionDate,
    List<String>? recentVirelangueIds,
    List<VirelangueDifficulty>? recentDifficulties,
  }) : lastSessionDate = lastSessionDate ?? DateTime.now(),
       recentVirelangueIds = recentVirelangueIds ?? [],
       recentDifficulties = recentDifficulties ?? [];
}