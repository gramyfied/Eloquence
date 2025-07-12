import 'package:hive/hive.dart';

part 'gamification_models.g.dart';

@HiveType(typeId: 20)
class UserGamificationProfile extends HiveObject {
  @HiveField(0)
  String userId;
  @HiveField(1)
  int totalXP;
  @HiveField(2)
  int currentLevel;
  @HiveField(3)
  int xpInCurrentLevel;
  @HiveField(4)
  int xpRequiredForNextLevel;
  @HiveField(5)
  List<String> earnedBadgeIds;
  @HiveField(6)
  int currentStreak;
  @HiveField(7)
  int longestStreak;
  @HiveField(8)
  DateTime lastSessionDate;
  @HiveField(9)
  Map<String, int> skillLevels;
  @HiveField(10)
  int totalSessions;
  @HiveField(11)
  int perfectSessions;

  UserGamificationProfile({
    required this.userId,
    this.totalXP = 0,
    this.currentLevel = 1,
    this.xpInCurrentLevel = 0,
    this.xpRequiredForNextLevel = 100,
    this.earnedBadgeIds = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastSessionDate,
    this.skillLevels = const {},
    this.totalSessions = 0,
    this.perfectSessions = 0,
  });

  static int calculateLevel(int totalXP) {
    if (totalXP < 1000) return (totalXP / 100).floor() + 1; // 1-10
    if (totalXP < 3250) return ((totalXP - 1000) / 150).floor() + 11; // 11-25
    if (totalXP < 8250) return ((totalXP - 3250) / 200).floor() + 26; // 26-50
    return ((totalXP - 8250) / 300).floor() + 51; // 51+
  }

  static int calculateXPForNextLevel(int currentLevel) {
    if (currentLevel <= 10) return 100;
    if (currentLevel <= 25) return 150;
    if (currentLevel <= 50) return 200;
    return 300;
  }

  UserGamificationProfile copyWith({
    int? totalXP,
    int? currentLevel,
    int? xpInCurrentLevel,
    int? xpRequiredForNextLevel,
    List<String>? earnedBadgeIds,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastSessionDate,
    Map<String, int>? skillLevels,
    int? totalSessions,
    int? perfectSessions,
  }) {
    return UserGamificationProfile(
      userId: userId,
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      xpInCurrentLevel: xpInCurrentLevel ?? this.xpInCurrentLevel,
      xpRequiredForNextLevel: xpRequiredForNextLevel ?? this.xpRequiredForNextLevel,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      skillLevels: skillLevels ?? this.skillLevels,
      totalSessions: totalSessions ?? this.totalSessions,
      perfectSessions: perfectSessions ?? this.perfectSessions,
    );
  }
}

@HiveType(typeId: 24)
class Badge extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String description;
  @HiveField(3)
  String iconPath;
  @HiveField(4)
  BadgeRarity rarity;
  @HiveField(5)
  BadgeCategory category;
  @HiveField(6)
  DateTime? earnedDate;
  @HiveField(7)
  int xpReward;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.rarity,
    required this.category,
    this.earnedDate,
    required this.xpReward,
  });
}

@HiveType(typeId: 22)
enum BadgeRarity {
  @HiveField(0)
  common,
  @HiveField(1)
  rare,
  @HiveField(2)
  epic,
  @HiveField(3)
  legendary
}

@HiveType(typeId: 23)
enum BadgeCategory {
  @HiveField(0)
  performance,
  @HiveField(1)
  streak,
  @HiveField(2)
  social,
  @HiveField(3)
  special,
  @HiveField(4)
  milestone
}

class GamificationResult {
  final int earnedXP;
  final List<Badge> newBadges;
  final bool levelUp;
  final int newLevel;
  final int xpInCurrentLevel;
  final int xpRequiredForNextLevel;
  final StreakInfo streakInfo;
  final BonusMultiplier bonusMultiplier;

  GamificationResult({
    required this.earnedXP,
    required this.newBadges,
    required this.levelUp,
    required this.newLevel,
    required this.xpInCurrentLevel,
    required this.xpRequiredForNextLevel,
    required this.streakInfo,
    required this.bonusMultiplier,
  });
}

class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final bool streakBroken;
  final bool newRecord;

  StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakBroken,
    required this.newRecord,
  });
}

class BonusMultiplier {
    final double performanceMultiplier;
    final double streakMultiplier;
    final double timeMultiplier;
    final double difficultyMultiplier;

    BonusMultiplier({
        required this.performanceMultiplier,
        required this.streakMultiplier,
        required this.timeMultiplier,
        required this.difficultyMultiplier,
    });
}

// Fictional classes to avoid errors, will be defined later
class LevelUpResult {
  final bool leveledUp;
  final int newLevel;
  LevelUpResult({required this.leveledUp, required this.newLevel});
}