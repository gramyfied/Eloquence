import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'dragon_breath_models.g.dart';

/// Niveaux de progression du Dragon
@HiveType(typeId: 40)
enum DragonLevel {
  @HiveField(0)
  apprenti,     // Apprenti Dragon (0-10 sessions)
  @HiveField(1)
  maitre,       // Maître du Souffle (11-25 sessions)
  @HiveField(2)
  sage,         // Dragon Sage (26-50 sessions)
  @HiveField(3)
  legende       // Légende Vivante (50+ sessions)
}

extension DragonLevelExtension on DragonLevel {
  String get displayName {
    switch (this) {
      case DragonLevel.apprenti:
        return 'Apprenti Dragon';
      case DragonLevel.maitre:
        return 'Maître du Souffle';
      case DragonLevel.sage:
        return 'Dragon Sage';
      case DragonLevel.legende:
        return 'Légende Vivante';
    }
  }

  String get description {
    switch (this) {
      case DragonLevel.apprenti:
        return 'Tu découvres ta force';
      case DragonLevel.maitre:
        return 'Tu contrôles ton énergie';
      case DragonLevel.sage:
        return 'Tu inspires par ta présence';
      case DragonLevel.legende:
        return 'Ton souffle commande le respect';
    }
  }

  Color get dragonColor {
    switch (this) {
      case DragonLevel.apprenti:
        return const Color(0xFF00D4FF); // Cyan
      case DragonLevel.maitre:
        return const Color(0xFF4ECDC4); // Vert
      case DragonLevel.sage:
        return const Color(0xFF8B5CF6); // Violet
      case DragonLevel.legende:
        return const Color(0xFFFFD700); // Doré
    }
  }

  int get requiredSessions {
    switch (this) {
      case DragonLevel.apprenti:
        return 0;
      case DragonLevel.maitre:
        return 11;
      case DragonLevel.sage:
        return 26;
      case DragonLevel.legende:
        return 50;
    }
  }

  String get emoji {
    switch (this) {
      case DragonLevel.apprenti:
        return '🐲';
      case DragonLevel.maitre:
        return '🐉';
      case DragonLevel.sage:
        return '🌟';
      case DragonLevel.legende:
        return '👑';
    }
  }
}

/// Phases de l'exercice de respiration
@HiveType(typeId: 41)
enum BreathingPhase {
  @HiveField(0)
  preparation,  // Préparation initiale
  @HiveField(1)
  inspiration,  // Phase d'inspiration
  @HiveField(2)
  retention,    // Rétention du souffle (optionnel)
  @HiveField(3)
  expiration,   // Phase d'expiration
  @HiveField(4)
  pause,        // Pause entre cycles
  @HiveField(5)
  completed     // Exercice terminé
}

extension BreathingPhaseExtension on BreathingPhase {
  String get displayName {
    switch (this) {
      case BreathingPhase.preparation:
        return 'Préparation';
      case BreathingPhase.inspiration:
        return 'Inspiration';
      case BreathingPhase.retention:
        return 'Rétention';
      case BreathingPhase.expiration:
        return 'Expiration';
      case BreathingPhase.pause:
        return 'Pause';
      case BreathingPhase.completed:
        return 'Terminé';
    }
  }

  String get instruction {
    switch (this) {
      case BreathingPhase.preparation:
        return 'Préparez-vous à commencer';
      case BreathingPhase.inspiration:
        return 'Inspirez profondément';
      case BreathingPhase.retention:
        return 'Retenez votre souffle';
      case BreathingPhase.expiration:
        return 'Expirez lentement';
      case BreathingPhase.pause:
        return 'Petite pause';
      case BreathingPhase.completed:
        return 'Exercice terminé !';
    }
  }

  Color get phaseColor {
    switch (this) {
      case BreathingPhase.preparation:
        return const Color(0xFF8B5CF6); // Violet
      case BreathingPhase.inspiration:
        return const Color(0xFF00D4FF); // Cyan
      case BreathingPhase.retention:
        return const Color(0xFFFFB347); // Orange
      case BreathingPhase.expiration:
        return const Color(0xFF4ECDC4); // Vert
      case BreathingPhase.pause:
        return const Color(0xFFB3FFFFFF); // Blanc transparent
      case BreathingPhase.completed:
        return const Color(0xFFFFD700); // Doré
    }
  }
}

/// Configuration d'un exercice de respiration
@HiveType(typeId: 42)
class BreathingExercise extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  int inspirationDuration;  // Durée en secondes
  
  @HiveField(4)
  int expirationDuration;   // Durée en secondes
  
  @HiveField(5)
  int retentionDuration;    // Durée en secondes (0 si pas de rétention)
  
  @HiveField(6)
  int pauseDuration;        // Durée en secondes
  
  @HiveField(7)
  int totalCycles;          // Nombre de cycles à effectuer
  
  @HiveField(8)
  DragonLevel requiredLevel;
  
  @HiveField(9)
  String benefits;          // Bénéfices de l'exercice
  
  @HiveField(10)
  bool isCustom;            // Si l'exercice est personnalisé
  
  @HiveField(11)
  DateTime createdAt;

  BreathingExercise({
    required this.id,
    required this.name,
    required this.description,
    this.inspirationDuration = 4,
    this.expirationDuration = 6,
    this.retentionDuration = 0,
    this.pauseDuration = 2,
    this.totalCycles = 5,
    this.requiredLevel = DragonLevel.apprenti,
    this.benefits = '',
    this.isCustom = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Durée totale d'un cycle en secondes
  int get cycleDuration => inspirationDuration + expirationDuration + retentionDuration + pauseDuration;
  
  /// Durée totale de l'exercice en secondes
  int get totalDuration => cycleDuration * totalCycles;

  factory BreathingExercise.defaultExercise() {
    return BreathingExercise(
      id: 'dragon_breath_basic',
      name: 'Souffle de Dragon Basique',
      description: 'Forge ton souffle comme un dragon forge ses flammes',
      inspirationDuration: 4,
      expirationDuration: 6,
      retentionDuration: 0,
      pauseDuration: 2,
      totalCycles: 5,
      requiredLevel: DragonLevel.apprenti,
      benefits: '🔥 Forge ton souffle\n⚡ Développe ta présence\n👑 Commande le respect',
    );
  }
}

/// Métriques d'une session de respiration
@HiveType(typeId: 43)
class BreathingMetrics extends HiveObject {
  @HiveField(0)
  double averageBreathDuration;
  
  @HiveField(1)
  double consistency;           // Régularité de la respiration (0-1)
  
  @HiveField(2)
  double controlScore;          // Score de contrôle (0-1)
  
  @HiveField(3)
  int completedCycles;
  
  @HiveField(4)
  int totalCycles;
  
  @HiveField(5)
  Duration actualDuration;
  
  @HiveField(6)
  Duration expectedDuration;
  
  @HiveField(7)
  double qualityScore;          // Score global de qualité (0-1)
  
  @HiveField(8)
  List<double> cycleDeviations; // Écarts par cycle
  
  @HiveField(9)
  DateTime timestamp;

  BreathingMetrics({
    required this.averageBreathDuration,
    required this.consistency,
    required this.controlScore,
    required this.completedCycles,
    required this.totalCycles,
    required this.actualDuration,
    required this.expectedDuration,
    required this.qualityScore,
    this.cycleDeviations = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Calcule le pourcentage de completion
  double get completionPercentage => completedCycles / totalCycles;
  
  /// Indique si l'exercice est réussi (>= 70% de qualité)
  bool get isSuccessful => qualityScore >= 0.7;
  
  /// Indique si l'exercice est excellent (>= 90% de qualité)
  bool get isExcellent => qualityScore >= 0.9;
}

/// Achievement déblocable pour le Dragon
@HiveType(typeId: 44)
class DragonAchievement extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  String emoji;
  
  @HiveField(4)
  DragonLevel requiredLevel;
  
  @HiveField(5)
  int requiredSessions;
  
  @HiveField(6)
  double requiredQuality;       // Score minimum requis
  
  @HiveField(7)
  int xpReward;                 // Récompense en XP
  
  @HiveField(8)
  bool isUnlocked;
  
  @HiveField(9)
  DateTime? unlockedAt;

  @HiveField(10)
  String category;              // Catégorie de l'achievement

  @HiveField(11)
  int currentValue;             // Valeur actuelle (ex: 7 sessions)

  @HiveField(12)
  int targetValue;              // Valeur cible (ex: 10 sessions)

  DragonAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.requiredLevel = DragonLevel.apprenti,
    this.requiredSessions = 1,
    this.requiredQuality = 0.7,
    this.xpReward = 50,
    this.isUnlocked = false,
    this.unlockedAt,
    this.category = 'general',
    this.currentValue = 0,
    int? targetValue,
  }) : targetValue = targetValue ?? requiredSessions;

  /// Progression vers l'achievement (0.0 à 1.0)
  double get progress {
    if (isUnlocked) return 1.0;
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Description de progression (ex: "7/10 sessions")
  String get progressDescription {
    if (isUnlocked) return 'Débloqué !';
    return '$currentValue/$targetValue';
  }

  /// Met à jour la progression de l'achievement
  DragonAchievement updateProgress(int newCurrentValue) {
    return DragonAchievement(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      requiredLevel: requiredLevel,
      requiredSessions: requiredSessions,
      requiredQuality: requiredQuality,
      xpReward: xpReward,
      isUnlocked: newCurrentValue >= targetValue ? true : isUnlocked,
      unlockedAt: newCurrentValue >= targetValue && !isUnlocked ? DateTime.now() : unlockedAt,
      category: category,
      currentValue: newCurrentValue,
      targetValue: targetValue,
    );
  }

  static List<DragonAchievement> getAllAchievements() {
    return [
      DragonAchievement(
        id: 'first_flame',
        name: 'Première Flamme',
        description: 'Première session complétée',
        emoji: '🔥',
        requiredSessions: 1,
        xpReward: 50,
        category: 'progression',
        targetValue: 1,
      ),
      DragonAchievement(
        id: 'breath_master',
        name: 'Souffle de Maître',
        description: 'Qualité excellente atteinte',
        emoji: '⚡',
        requiredQuality: 0.9,
        xpReward: 100,
        category: 'performance',
        targetValue: 1,
      ),
      DragonAchievement(
        id: 'precision_master',
        name: 'Précision de Maître',
        description: '90% de régularité atteinte',
        emoji: '🎯',
        requiredQuality: 0.9,
        xpReward: 150,
        category: 'performance',
        targetValue: 1,
      ),
      DragonAchievement(
        id: 'royal_series',
        name: 'Série Royale',
        description: '7 jours consécutifs de pratique',
        emoji: '👑',
        requiredSessions: 7,
        xpReward: 200,
        category: 'consistency',
        targetValue: 7,
      ),
      DragonAchievement(
        id: 'legendary_dragon',
        name: 'Dragon Légendaire',
        description: '30 sessions complétées',
        emoji: '🌟',
        requiredLevel: DragonLevel.legende,
        requiredSessions: 30,
        xpReward: 500,
        category: 'progression',
        targetValue: 30,
      ),
      DragonAchievement(
        id: 'perfectionist',
        name: 'Perfectionniste',
        description: '5 sessions parfaites (100% qualité)',
        emoji: '💎',
        requiredQuality: 1.0,
        xpReward: 300,
        category: 'performance',
        targetValue: 5,
      ),
      DragonAchievement(
        id: 'dedicated_warrior',
        name: 'Guerrier Dévoué',
        description: '14 jours consécutifs',
        emoji: '⚔️',
        requiredSessions: 14,
        xpReward: 400,
        category: 'consistency',
        targetValue: 14,
      ),
      DragonAchievement(
        id: 'breath_veteran',
        name: 'Vétéran du Souffle',
        description: '100 sessions complétées',
        emoji: '🥇',
        requiredSessions: 100,
        xpReward: 1000,
        category: 'progression',
        targetValue: 100,
      ),
    ];
  }
}

/// Session d'exercice de respiration
@HiveType(typeId: 45)
class BreathingSession extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String exerciseId;
  
  @HiveField(3)
  DateTime startTime;
  
  @HiveField(4)
  DateTime? endTime;
  
  @HiveField(5)
  BreathingMetrics? metrics;
  
  @HiveField(6)
  List<DragonAchievement> unlockedAchievements;
  
  @HiveField(7)
  int xpGained;
  
  @HiveField(8)
  bool isCompleted;
  
  @HiveField(9)
  String motivationalMessage;

  BreathingSession({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.startTime,
    this.endTime,
    this.metrics,
    this.unlockedAchievements = const [],
    this.xpGained = 0,
    this.isCompleted = false,
    this.motivationalMessage = '',
  });

  /// Durée de la session
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  
  /// Termine la session avec les métriques
  void complete(BreathingMetrics sessionMetrics) {
    endTime = DateTime.now();
    metrics = sessionMetrics;
    isCompleted = true;
    
    // Calcul de l'XP basé sur la performance
    xpGained = _calculateXP(sessionMetrics);
    
    // Message motivationnel basé sur la performance
    motivationalMessage = _generateMotivationalMessage(sessionMetrics);
  }

  int _calculateXP(BreathingMetrics metrics) {
    int baseXP = 25; // XP de base pour completion
    
    // Bonus pour la qualité
    int qualityBonus = (metrics.qualityScore * 50).round();
    
    // Bonus pour completion
    int completionBonus = metrics.completionPercentage == 1.0 ? 25 : 0;
    
    // Bonus pour excellence
    int excellenceBonus = metrics.isExcellent ? 50 : 0;
    
    return baseXP + qualityBonus + completionBonus + excellenceBonus;
  }

  String _generateMotivationalMessage(BreathingMetrics metrics) {
    if (metrics.isExcellent) {
      return "Tu as forgé ton souffle comme un maître ! Ton dragon intérieur rayonne de puissance.";
    } else if (metrics.isSuccessful) {
      return "Excellent travail ! Ta maîtrise du souffle grandit avec chaque session.";
    } else if (metrics.completionPercentage >= 0.5) {
      return "Bon début ! Continue à pratiquer pour libérer la puissance de ton dragon.";
    } else {
      return "Chaque dragon doit apprendre à contrôler ses flammes. Continue l'entraînement !";
    }
  }
}

/// Progression globale de l'utilisateur
@HiveType(typeId: 46)
class DragonProgress extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  DragonLevel currentLevel;
  
  @HiveField(2)
  int totalSessions;
  
  @HiveField(3)
  int totalXP;
  
  @HiveField(4)
  int currentStreak;           // Série de jours consécutifs
  
  @HiveField(5)
  int longestStreak;           // Plus longue série
  
  @HiveField(6)
  double averageQuality;       // Qualité moyenne
  
  @HiveField(7)
  double bestQuality;          // Meilleure qualité
  
  @HiveField(8)
  Duration totalPracticeTime;  // Temps total de pratique
  
  @HiveField(9)
  DateTime lastSessionDate;
  
  @HiveField(10)
  List<DragonAchievement> achievements;
  
  @HiveField(11)
  Map<String, dynamic> statistics;

  DragonProgress({
    required this.userId,
    this.currentLevel = DragonLevel.apprenti,
    this.totalSessions = 0,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.averageQuality = 0.0,
    this.bestQuality = 0.0,
    Duration? totalPracticeTime,
    DateTime? lastSessionDate,
    this.achievements = const [],
    Map<String, dynamic>? statistics,
  }) : totalPracticeTime = totalPracticeTime ?? Duration.zero,
       lastSessionDate = lastSessionDate ?? DateTime.now(),
       statistics = statistics ?? {};

  /// Met à jour la progression après une session
  void updateWithSession(BreathingSession session) {
    if (session.metrics == null) return;
    
    final metrics = session.metrics!;
    
    // Mise à jour des statistiques de base
    totalSessions++;
    totalXP += session.xpGained;
    totalPracticeTime += session.duration;
    
    // Mise à jour de la qualité
    averageQuality = ((averageQuality * (totalSessions - 1)) + metrics.qualityScore) / totalSessions;
    bestQuality = math.max(bestQuality, metrics.qualityScore);
    
    // Mise à jour du streak
    final now = DateTime.now();
    final daysSinceLastSession = now.difference(lastSessionDate).inDays;
    
    if (daysSinceLastSession <= 1) {
      currentStreak++;
    } else {
      currentStreak = 1;
    }
    
    longestStreak = math.max(longestStreak, currentStreak);
    lastSessionDate = now;
    
    // Mise à jour du niveau
    _updateLevel();
    
    // Ajout des achievements débloqués
    achievements.addAll(session.unlockedAchievements);
  }

  void _updateLevel() {
    if (totalSessions >= DragonLevel.legende.requiredSessions) {
      currentLevel = DragonLevel.legende;
    } else if (totalSessions >= DragonLevel.sage.requiredSessions) {
      currentLevel = DragonLevel.sage;
    } else if (totalSessions >= DragonLevel.maitre.requiredSessions) {
      currentLevel = DragonLevel.maitre;
    } else {
      currentLevel = DragonLevel.apprenti;
    }
  }

  /// Progression vers le niveau suivant (0.0 à 1.0)
  double get progressToNextLevel {
    final nextLevel = _getNextLevel();
    if (nextLevel == null) return 1.0; // Niveau max atteint
    
    final currentRequired = currentLevel.requiredSessions;
    final nextRequired = nextLevel.requiredSessions;
    final progress = (totalSessions - currentRequired) / (nextRequired - currentRequired);
    
    return progress.clamp(0.0, 1.0);
  }

  DragonLevel? _getNextLevel() {
    switch (currentLevel) {
      case DragonLevel.apprenti:
        return DragonLevel.maitre;
      case DragonLevel.maitre:
        return DragonLevel.sage;
      case DragonLevel.sage:
        return DragonLevel.legende;
      case DragonLevel.legende:
        return null; // Niveau maximum
    }
  }

  /// Sessions restantes pour le prochain niveau
  int get sessionsToNextLevel {
    final nextLevel = _getNextLevel();
    if (nextLevel == null) return 0;
    
    return math.max(0, nextLevel.requiredSessions - totalSessions);
  }
}

/// État de l'exercice de respiration en cours
class BreathingExerciseState {
  final String sessionId;
  final BreathingExercise exercise;
  final BreathingPhase currentPhase;
  final int currentCycle;
  final int remainingSeconds;
  final bool isActive;
  final bool isPaused;
  final BreathingMetrics? currentMetrics;
  final List<String> motivationalMessages;
  final DragonProgress userProgress;
  final bool isLoading;
  final String? error;

  const BreathingExerciseState({
    required this.sessionId,
    required this.exercise,
    required this.currentPhase,
    required this.currentCycle,
    required this.remainingSeconds,
    required this.isActive,
    required this.isPaused,
    this.currentMetrics,
    this.motivationalMessages = const [],
    required this.userProgress,
    this.isLoading = false,
    this.error,
  });

  factory BreathingExerciseState.initial({
    required String userId,
    BreathingExercise? exercise,
  }) {
    final defaultExercise = exercise ?? BreathingExercise.defaultExercise();
    
    return BreathingExerciseState(
      sessionId: '',
      exercise: defaultExercise,
      currentPhase: BreathingPhase.preparation,
      currentCycle: 0,
      remainingSeconds: 0,
      isActive: false,
      isPaused: false,
      userProgress: DragonProgress(userId: userId),
      isLoading: false,
    );
  }

  BreathingExerciseState copyWith({
    String? sessionId,
    BreathingExercise? exercise,
    BreathingPhase? currentPhase,
    int? currentCycle,
    int? remainingSeconds,
    bool? isActive,
    bool? isPaused,
    BreathingMetrics? currentMetrics,
    List<String>? motivationalMessages,
    DragonProgress? userProgress,
    bool? isLoading,
    String? error,
  }) {
    return BreathingExerciseState(
      sessionId: sessionId ?? this.sessionId,
      exercise: exercise ?? this.exercise,
      currentPhase: currentPhase ?? this.currentPhase,
      currentCycle: currentCycle ?? this.currentCycle,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      currentMetrics: currentMetrics ?? this.currentMetrics,
      motivationalMessages: motivationalMessages ?? this.motivationalMessages,
      userProgress: userProgress ?? this.userProgress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Progression du cycle actuel (0.0 à 1.0)
  double get cycleProgress => currentCycle / exercise.totalCycles;
  
  /// Progression de la phase actuelle (0.0 à 1.0)
  double get phaseProgress {
    final phaseDuration = _getCurrentPhaseDuration();
    if (phaseDuration == 0) return 0.0;
    
    final elapsed = phaseDuration - remainingSeconds;
    return (elapsed / phaseDuration).clamp(0.0, 1.0);
  }

  int _getCurrentPhaseDuration() {
    switch (currentPhase) {
      case BreathingPhase.inspiration:
        return exercise.inspirationDuration;
      case BreathingPhase.retention:
        return exercise.retentionDuration;
      case BreathingPhase.expiration:
        return exercise.expirationDuration;
      case BreathingPhase.pause:
        return exercise.pauseDuration;
      default:
        return 0;
    }
  }
}