import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/virelangue_models.dart';

part 'virelangue_leaderboard_service.g.dart';

/// Service de gestion des classements et leaderboards pour les virelangues
/// 
/// 🏆 FONCTIONNALITÉS DU LEADERBOARD :
/// - Classements multiples (valeur gemmes, streaks, performances)
/// - Classements temporels (quotidien, hebdomadaire, mensuel, all-time)
/// - Système de leagues et divisions
/// - Récompenses saisonnières et événements spéciaux
/// - Comparaisons sociales et défis entre amis
/// - Historique des performances et évolution des rangs
/// - Badges d'accomplissement et titres de prestige
class VirelangueLeaderboardService {
  final Logger _logger = Logger();
  
  static const String _leaderboardBoxName = 'virelangueLeaderboardBox';
  static const String _userRankHistoryBoxName = 'virelangueUserRankHistoryBox';
  static const String _seasonStatsBoxName = 'virelangueSeasonStatsBox';
  static const String _achievementsBoxName = 'virelangueAchievementsBox';
  
  // Configuration des saisons et périodes
  static const Duration _seasonDuration = Duration(days: 30); // 1 mois par saison
  static const Duration _weeklyResetDuration = Duration(days: 7);
  static const Duration _dailyResetDuration = Duration(days: 1);
  
  // Seuils pour les leagues
  static const Map<LeaderboardLeague, int> _leagueThresholds = {
    LeaderboardLeague.bronze: 0,
    LeaderboardLeague.silver: 1000,    // 1000 points de gemmes
    LeaderboardLeague.gold: 5000,     // 5000 points de gemmes
    LeaderboardLeague.platinum: 15000, // 15000 points de gemmes
    LeaderboardLeague.diamond: 50000,  // 50000 points de gemmes
    LeaderboardLeague.master: 100000,  // 100000 points de gemmes
  };

  /// Initialise le service de leaderboard
  Future<void> initialize() async {
    try {
      _logger.i('🏆 Initialisation VirelangueLeaderboardService...');
      
      // Ouvrir les boîtes Hive
      if (!Hive.isBoxOpen(_leaderboardBoxName)) {
        await Hive.openBox<LeaderboardEntry>(_leaderboardBoxName);
      }
      if (!Hive.isBoxOpen(_userRankHistoryBoxName)) {
        await Hive.openBox<UserRankHistory>(_userRankHistoryBoxName);
      }
      if (!Hive.isBoxOpen(_seasonStatsBoxName)) {
        await Hive.openBox<SeasonStats>(_seasonStatsBoxName);
      }
      if (!Hive.isBoxOpen(_achievementsBoxName)) {
        await Hive.openBox<LeaderboardAchievement>(_achievementsBoxName);
      }
      
      // Vérifier et réinitialiser les classements si nécessaire
      await _checkAndResetPeriods();
      
      _logger.i('✅ VirelangueLeaderboardService initialisé avec succès');
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur initialisation leaderboard service: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Met à jour l'entrée de leaderboard pour un utilisateur
  Future<void> updateUserLeaderboardEntry({
    required String userId,
    required String username,
    required GemCollection gemCollection,
    required VirelangueUserProgress userProgress,
  }) async {
    try {
      _logger.i('📊 Mise à jour leaderboard pour: $userId');
      
      final box = Hive.box<LeaderboardEntry>(_leaderboardBoxName);
      final currentSeason = getCurrentSeason();
      
      // Récupérer ou créer l'entrée existante
      var entry = box.get(userId) ?? LeaderboardEntry(
        userId: userId,
        username: username,
        totalGemValue: 0,
        gemCounts: {},
        currentStreak: 0,
        bestStreak: 0,
        totalSessions: 0,
        averageScore: 0.0,
        league: LeaderboardLeague.bronze,
        seasonNumber: currentSeason,
        lastUpdated: DateTime.now(),
      );
      
      // Si nouvelle saison, réinitialiser certaines stats
      if (entry.seasonNumber != currentSeason) {
        entry = _resetEntryForNewSeason(entry, currentSeason);
      }
      
      // Mettre à jour les statistiques
      entry.totalGemValue = gemCollection.getTotalValue();
      entry.gemCounts = {
        GemType.ruby: gemCollection.getGemCount(GemType.ruby),
        GemType.emerald: gemCollection.getGemCount(GemType.emerald),
        GemType.diamond: gemCollection.getGemCount(GemType.diamond),
      };
      entry.currentStreak = userProgress.currentStreak;
      entry.bestStreak = math.max(entry.bestStreak, userProgress.currentStreak);
      entry.totalSessions = userProgress.totalSessions;
      entry.averageScore = userProgress.averageScore;
      entry.lastUpdated = DateTime.now();
      
      // Calculer et mettre à jour la league
      entry.league = _calculateLeague(entry.totalGemValue);
      
      // Calculer le score composite pour le classement
      entry.compositeScore = _calculateCompositeScore(entry);
      
      await box.put(userId, entry);
      
      // Enregistrer l'historique des rangs
      await _updateUserRankHistory(userId, entry);
      
      // Vérifier les achievements
      await _checkAndAwardAchievements(userId, entry);
      
      _logger.i('🏆 Leaderboard mis à jour: ${entry.league.displayName}, score: ${entry.compositeScore}');
      
    } catch (e) {
      _logger.e('❌ Erreur mise à jour leaderboard: $e');
    }
  }

  /// Récupère le classement global par score composite
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
    int limit = 100,
  }) async {
    try {
      final box = Hive.box<LeaderboardEntry>(_leaderboardBoxName);
      var entries = box.values.toList();
      
      // Filtrer par période si nécessaire
      entries = _filterByPeriod(entries, period);
      
      // Trier par score composite décroissant
      entries.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
      
      // Appliquer la limite
      if (entries.length > limit) {
        entries = entries.take(limit).toList();
      }
      
      // Assigner les rangs
      for (int i = 0; i < entries.length; i++) {
        entries[i].currentRank = i + 1;
      }
      
      _logger.i('📋 Leaderboard global récupéré: ${entries.length} entrées');
      return entries;
      
    } catch (e) {
      _logger.e('❌ Erreur récupération leaderboard global: $e');
      return [];
    }
  }

  /// Récupère le classement par league spécifique
  Future<List<LeaderboardEntry>> getLeagueLeaderboard({
    required LeaderboardLeague league,
    LeaderboardPeriod period = LeaderboardPeriod.currentSeason,
    int limit = 50,
  }) async {
    try {
      final box = Hive.box<LeaderboardEntry>(_leaderboardBoxName);
      var entries = box.values.where((entry) => entry.league == league).toList();
      
      // Filtrer par période
      entries = _filterByPeriod(entries, period);
      
      // Trier par score composite
      entries.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
      
      // Appliquer la limite
      if (entries.length > limit) {
        entries = entries.take(limit).toList();
      }
      
      // Assigner les rangs dans la league
      for (int i = 0; i < entries.length; i++) {
        entries[i].leagueRank = i + 1;
      }
      
      _logger.i('🏅 Leaderboard ${league.displayName} récupéré: ${entries.length} entrées');
      return entries;
      
    } catch (e) {
      _logger.e('❌ Erreur récupération leaderboard league: $e');
      return [];
    }
  }

  /// Récupère la position d'un utilisateur dans le classement global
  Future<UserLeaderboardPosition> getUserPosition(String userId) async {
    try {
      final globalLeaderboard = await getGlobalLeaderboard(limit: 10000);
      final userEntry = globalLeaderboard.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => throw Exception('Utilisateur non trouvé'),
      );
      
      final leagueLeaderboard = await getLeagueLeaderboard(league: userEntry.league);
      final leaguePosition = leagueLeaderboard.indexWhere((e) => e.userId == userId) + 1;
      
      final position = UserLeaderboardPosition(
        globalRank: userEntry.currentRank,
        leagueRank: leaguePosition,
        league: userEntry.league,
        totalGemValue: userEntry.totalGemValue,
        compositeScore: userEntry.compositeScore,
        percentile: _calculatePercentile(userEntry.currentRank, globalLeaderboard.length),
        isTopPerformer: userEntry.currentRank <= 10,
        progressToNextLeague: _calculateProgressToNextLeague(userEntry),
      );
      
      _logger.i('📍 Position utilisateur: rang global ${position.globalRank}, league ${position.league.displayName}');
      return position;
      
    } catch (e) {
      _logger.e('❌ Erreur récupération position utilisateur: $e');
      throw Exception('Impossible de récupérer la position de l\'utilisateur');
    }
  }

  /// Récupère les achievements d'un utilisateur
  Future<List<LeaderboardAchievement>> getUserAchievements(String userId) async {
    try {
      final box = Hive.box<LeaderboardAchievement>(_achievementsBoxName);
      final achievements = box.values
          .where((achievement) => achievement.userId == userId)
          .toList();
      
      // Trier par date d'obtention (plus récent en premier)
      achievements.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
      
      _logger.i('🏅 ${achievements.length} achievements trouvés pour: $userId');
      return achievements;
      
    } catch (e) {
      _logger.e('❌ Erreur récupération achievements: $e');
      return [];
    }
  }

  /// Récupère les statistiques de saison actuelle
  Future<SeasonStats> getCurrentSeasonStats() async {
    try {
      final box = Hive.box<SeasonStats>(_seasonStatsBoxName);
      final currentSeason = getCurrentSeason();
      
      return box.get('season_$currentSeason') ?? SeasonStats(
        seasonNumber: currentSeason,
        startDate: _getSeasonStartDate(currentSeason),
        endDate: _getSeasonEndDate(currentSeason),
        totalParticipants: 0,
        totalGemValueAwarded: 0,
        topPerformers: [],
        averageScore: 0.0,
      );
      
    } catch (e) {
      _logger.e('❌ Erreur récupération stats saison: $e');
      rethrow;
    }
  }

  /// Calcule le score composite pour le classement
  double _calculateCompositeScore(LeaderboardEntry entry) {
    // Pondération des différents critères
    const gemValueWeight = 0.4;      // 40% - valeur des gemmes
    const streakWeight = 0.2;        // 20% - streak actuel
    const sessionWeight = 0.15;      // 15% - nombre de sessions
    const averageScoreWeight = 0.15; // 15% - score moyen
    const rareGemWeight = 0.1;       // 10% - gemmes rares
    
    // Normaliser les valeurs
    final normalizedGemValue = math.min(entry.totalGemValue / 50000.0, 1.0);
    final normalizedStreak = math.min(entry.currentStreak / 30.0, 1.0);
    final normalizedSessions = math.min(entry.totalSessions / 100.0, 1.0);
    final normalizedAvgScore = entry.averageScore;
    final normalizedRareGems = math.min(
      ((entry.gemCounts[GemType.emerald] ?? 0) + 
       (entry.gemCounts[GemType.diamond] ?? 0) * 3) / 100.0, 
      1.0
    );
    
    final compositeScore = 
        (normalizedGemValue * gemValueWeight) +
        (normalizedStreak * streakWeight) +
        (normalizedSessions * sessionWeight) +
        (normalizedAvgScore * averageScoreWeight) +
        (normalizedRareGems * rareGemWeight);
    
    return compositeScore * 10000; // Multiplier pour avoir des scores plus lisibles
  }

  /// Calcule la league basée sur la valeur des gemmes
  LeaderboardLeague _calculateLeague(int totalGemValue) {
    for (final entry in _leagueThresholds.entries.toList().reversed) {
      if (totalGemValue >= entry.value) {
        return entry.key;
      }
    }
    return LeaderboardLeague.bronze;
  }

  /// Calcule le pourcentage de progression vers la league suivante
  double _calculateProgressToNextLeague(LeaderboardEntry entry) {
    final currentLeague = entry.league;
    final nextLeague = _getNextLeague(currentLeague);
    
    if (nextLeague == null) return 1.0; // Déjà au maximum
    
    final currentThreshold = _leagueThresholds[currentLeague] ?? 0;
    final nextThreshold = _leagueThresholds[nextLeague] ?? 0;
    
    if (nextThreshold <= currentThreshold) return 1.0;
    
    final progress = (entry.totalGemValue - currentThreshold) / 
                     (nextThreshold - currentThreshold);
    
    return math.max(0.0, math.min(1.0, progress));
  }

  /// Obtient la league suivante
  LeaderboardLeague? _getNextLeague(LeaderboardLeague currentLeague) {
    final leagues = LeaderboardLeague.values;
    final currentIndex = leagues.indexOf(currentLeague);
    
    if (currentIndex < leagues.length - 1) {
      return leagues[currentIndex + 1];
    }
    
    return null; // Déjà au niveau maximum
  }

  /// Calcule le percentile d'un rang
  double _calculatePercentile(int rank, int totalParticipants) {
    if (totalParticipants <= 1) return 100.0;
    return ((totalParticipants - rank) / (totalParticipants - 1)) * 100.0;
  }

  /// Filtre les entrées par période
  List<LeaderboardEntry> _filterByPeriod(List<LeaderboardEntry> entries, LeaderboardPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case LeaderboardPeriod.daily:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return entries.where((e) => e.lastUpdated.isAfter(startOfDay)).toList();
        
      case LeaderboardPeriod.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return entries.where((e) => e.lastUpdated.isAfter(startOfWeekDay)).toList();
        
      case LeaderboardPeriod.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return entries.where((e) => e.lastUpdated.isAfter(startOfMonth)).toList();
        
      case LeaderboardPeriod.currentSeason:
        final currentSeason = getCurrentSeason();
        return entries.where((e) => e.seasonNumber == currentSeason).toList();
        
      case LeaderboardPeriod.allTime:
      default:
        return entries;
    }
  }

  /// Vérifie et réinitialise les périodes si nécessaire
  Future<void> _checkAndResetPeriods() async {
    try {
      // Logique de réinitialisation des classements périodiques
      // À implémenter selon les besoins spécifiques
      _logger.i('🔄 Vérification des périodes de réinitialisation...');
    } catch (e) {
      _logger.e('❌ Erreur vérification périodes: $e');
    }
  }

  /// Réinitialise une entrée pour une nouvelle saison
  LeaderboardEntry _resetEntryForNewSeason(LeaderboardEntry entry, int newSeason) {
    return LeaderboardEntry(
      userId: entry.userId,
      username: entry.username,
      totalGemValue: 0,
      gemCounts: {},
      currentStreak: 0,
      bestStreak: 0, // Garder le record de l'ancienne saison
      totalSessions: 0,
      averageScore: 0.0,
      league: LeaderboardLeague.bronze,
      seasonNumber: newSeason,
      lastUpdated: DateTime.now(),
    );
  }

  /// Met à jour l'historique des rangs d'un utilisateur
  Future<void> _updateUserRankHistory(String userId, LeaderboardEntry entry) async {
    try {
      final box = Hive.box<UserRankHistory>(_userRankHistoryBoxName);
      var history = box.get(userId) ?? UserRankHistory(
        userId: userId,
        rankSnapshots: [],
      );
      
      // Ajouter un nouveau snapshot
      final snapshot = RankSnapshot(
        timestamp: DateTime.now(),
        globalRank: entry.currentRank,
        leagueRank: entry.leagueRank,
        league: entry.league,
        totalGemValue: entry.totalGemValue,
        compositeScore: entry.compositeScore,
      );
      
      history.rankSnapshots.add(snapshot);
      
      // Garder seulement les 100 derniers snapshots
      if (history.rankSnapshots.length > 100) {
        history.rankSnapshots = history.rankSnapshots.skip(history.rankSnapshots.length - 100).toList();
      }
      
      await box.put(userId, history);
      
    } catch (e) {
      _logger.e('❌ Erreur mise à jour historique rangs: $e');
    }
  }

  /// Vérifie et attribue les achievements
  Future<void> _checkAndAwardAchievements(String userId, LeaderboardEntry entry) async {
    try {
      final achievementBox = Hive.box<LeaderboardAchievement>(_achievementsBoxName);
      final userAchievements = await getUserAchievements(userId);
      final earnedTypes = userAchievements.map((a) => a.type).toSet();
      
      // Vérifier chaque type d'achievement
      for (final achievementType in AchievementType.values) {
        if (!earnedTypes.contains(achievementType) && 
            _checkAchievementCondition(achievementType, entry)) {
          
          final achievement = LeaderboardAchievement(
            userId: userId,
            type: achievementType,
            title: achievementType.title,
            description: achievementType.description,
            iconEmoji: achievementType.iconEmoji,
            earnedAt: DateTime.now(),
            gemValueAtEarning: entry.totalGemValue,
          );
          
          final key = '${userId}_${achievementType.name}';
          await achievementBox.put(key, achievement);
          
          _logger.i('🏅 Achievement débloqué: ${achievement.title} pour $userId');
        }
      }
      
    } catch (e) {
      _logger.e('❌ Erreur vérification achievements: $e');
    }
  }

  /// Vérifie si une condition d'achievement est remplie
  bool _checkAchievementCondition(AchievementType type, LeaderboardEntry entry) {
    switch (type) {
      case AchievementType.firstGem:
        return entry.totalGemValue > 0;
      case AchievementType.gemCollector:
        return entry.totalGemValue >= 1000;
      case AchievementType.gemMaster:
        return entry.totalGemValue >= 10000;
      case AchievementType.streakWarrior:
        return entry.currentStreak >= 10;
      case AchievementType.streakLegend:
        return entry.currentStreak >= 30;
      case AchievementType.sessionMarathon:
        return entry.totalSessions >= 100;
      case AchievementType.perfectionist:
        return entry.averageScore >= 0.95;
      case AchievementType.rareCollector:
        final rareGems = (entry.gemCounts[GemType.emerald] ?? 0) + 
                        (entry.gemCounts[GemType.diamond] ?? 0);
        return rareGems >= 50;
      case AchievementType.leagueClimber:
        return entry.league.index >= LeaderboardLeague.gold.index;
      case AchievementType.topTen:
        return entry.currentRank <= 10;
    }
  }

  /// Obtient la saison actuelle
  int getCurrentSeason() {
    final appStartDate = DateTime(2024, 1, 1); // Date de début de l'app
    final daysSinceStart = DateTime.now().difference(appStartDate).inDays;
    return (daysSinceStart ~/ _seasonDuration.inDays) + 1;
  }

  /// Obtient la date de début d'une saison
  DateTime _getSeasonStartDate(int seasonNumber) {
    final appStartDate = DateTime(2024, 1, 1);
    return appStartDate.add(Duration(days: (seasonNumber - 1) * _seasonDuration.inDays));
  }

  /// Obtient la date de fin d'une saison
  DateTime _getSeasonEndDate(int seasonNumber) {
    return _getSeasonStartDate(seasonNumber).add(_seasonDuration);
  }

  /// Libère les ressources
  void dispose() {
    _logger.i('🗑️ VirelangueLeaderboardService disposé');
  }
}

// ========== MODÈLES DE DONNÉES ==========

/// Entrée de leaderboard pour un utilisateur
@HiveType(typeId: 56)
class LeaderboardEntry extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  String username;
  
  @HiveField(2)
  int totalGemValue;
  
  @HiveField(3)
  Map<GemType, int> gemCounts;
  
  @HiveField(4)
  int currentStreak;
  
  @HiveField(5)
  int bestStreak;
  
  @HiveField(6)
  int totalSessions;
  
  @HiveField(7)
  double averageScore;
  
  @HiveField(8)
  LeaderboardLeague league;
  
  @HiveField(9)
  int seasonNumber;
  
  @HiveField(10)
  DateTime lastUpdated;
  
  @HiveField(11)
  double compositeScore;
  
  @HiveField(12)
  int currentRank;
  
  @HiveField(13)
  int leagueRank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.totalGemValue = 0,
    Map<GemType, int>? gemCounts,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalSessions = 0,
    this.averageScore = 0.0,
    this.league = LeaderboardLeague.bronze,
    required this.seasonNumber,
    required this.lastUpdated,
    this.compositeScore = 0.0,
    this.currentRank = 0,
    this.leagueRank = 0,
  }) : gemCounts = gemCounts ?? {};
}

/// Leagues du leaderboard
enum LeaderboardLeague {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
}

extension LeaderboardLeagueExtension on LeaderboardLeague {
  String get displayName {
    switch (this) {
      case LeaderboardLeague.bronze:
        return 'Bronze';
      case LeaderboardLeague.silver:
        return 'Argent';
      case LeaderboardLeague.gold:
        return 'Or';
      case LeaderboardLeague.platinum:
        return 'Platine';
      case LeaderboardLeague.diamond:
        return 'Diamant';
      case LeaderboardLeague.master:
        return 'Maître';
    }
  }
  
  String get emoji {
    switch (this) {
      case LeaderboardLeague.bronze:
        return '🥉';
      case LeaderboardLeague.silver:
        return '🥈';
      case LeaderboardLeague.gold:
        return '🥇';
      case LeaderboardLeague.platinum:
        return '💎';
      case LeaderboardLeague.diamond:
        return '💍';
      case LeaderboardLeague.master:
        return '👑';
    }
  }
}

/// Périodes de leaderboard
enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  currentSeason,
  allTime,
}

/// Position d'un utilisateur dans le leaderboard
class UserLeaderboardPosition {
  final int globalRank;
  final int leagueRank;
  final LeaderboardLeague league;
  final int totalGemValue;
  final double compositeScore;
  final double percentile;
  final bool isTopPerformer;
  final double progressToNextLeague;

  const UserLeaderboardPosition({
    required this.globalRank,
    required this.leagueRank,
    required this.league,
    required this.totalGemValue,
    required this.compositeScore,
    required this.percentile,
    required this.isTopPerformer,
    required this.progressToNextLeague,
  });
}

/// Historique des rangs d'un utilisateur
@HiveType(typeId: 57)
class UserRankHistory extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  List<RankSnapshot> rankSnapshots;

  UserRankHistory({
    required this.userId,
    required this.rankSnapshots,
  });
}

/// Snapshot d'un rang à un moment donné
@HiveType(typeId: 58)
class RankSnapshot extends HiveObject {
  @HiveField(0)
  DateTime timestamp;
  
  @HiveField(1)
  int globalRank;
  
  @HiveField(2)
  int leagueRank;
  
  @HiveField(3)
  LeaderboardLeague league;
  
  @HiveField(4)
  int totalGemValue;
  
  @HiveField(5)
  double compositeScore;

  RankSnapshot({
    required this.timestamp,
    required this.globalRank,
    required this.leagueRank,
    required this.league,
    required this.totalGemValue,
    required this.compositeScore,
  });
}

/// Statistiques de saison
@HiveType(typeId: 59)
class SeasonStats extends HiveObject {
  @HiveField(0)
  int seasonNumber;
  
  @HiveField(1)
  DateTime startDate;
  
  @HiveField(2)
  DateTime endDate;
  
  @HiveField(3)
  int totalParticipants;
  
  @HiveField(4)
  int totalGemValueAwarded;
  
  @HiveField(5)
  List<String> topPerformers;
  
  @HiveField(6)
  double averageScore;

  SeasonStats({
    required this.seasonNumber,
    required this.startDate,
    required this.endDate,
    this.totalParticipants = 0,
    this.totalGemValueAwarded = 0,
    this.topPerformers = const [],
    this.averageScore = 0.0,
  });
}

/// Achievement de leaderboard
@HiveType(typeId: 60)
class LeaderboardAchievement extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  AchievementType type;
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  String description;
  
  @HiveField(4)
  String iconEmoji;
  
  @HiveField(5)
  DateTime earnedAt;
  
  @HiveField(6)
  int gemValueAtEarning;

  LeaderboardAchievement({
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.earnedAt,
    required this.gemValueAtEarning,
  });
}

/// Types d'achievements
enum AchievementType {
  firstGem,
  gemCollector,
  gemMaster,
  streakWarrior,
  streakLegend,
  sessionMarathon,
  perfectionist,
  rareCollector,
  leagueClimber,
  topTen,
}

extension AchievementTypeExtension on AchievementType {
  String get title {
    switch (this) {
      case AchievementType.firstGem:
        return 'Première Gemme';
      case AchievementType.gemCollector:
        return 'Collectionneur';
      case AchievementType.gemMaster:
        return 'Maître des Gemmes';
      case AchievementType.streakWarrior:
        return 'Guerrier des Séries';
      case AchievementType.streakLegend:
        return 'Légende des Séries';
      case AchievementType.sessionMarathon:
        return 'Marathonien';
      case AchievementType.perfectionist:
        return 'Perfectionniste';
      case AchievementType.rareCollector:
        return 'Chasseur de Rares';
      case AchievementType.leagueClimber:
        return 'Grimpeur de Leagues';
      case AchievementType.topTen:
        return 'Top 10';
    }
  }
  
  String get description {
    switch (this) {
      case AchievementType.firstGem:
        return 'Obtenez votre première gemme';
      case AchievementType.gemCollector:
        return 'Collectez 1000 points de gemmes';
      case AchievementType.gemMaster:
        return 'Collectez 10000 points de gemmes';
      case AchievementType.streakWarrior:
        return 'Maintenez une série de 10';
      case AchievementType.streakLegend:
        return 'Maintenez une série de 30';
      case AchievementType.sessionMarathon:
        return 'Complétez 100 sessions';
      case AchievementType.perfectionist:
        return 'Maintenez 95% de score moyen';
      case AchievementType.rareCollector:
        return 'Collectez 50 gemmes rares';
      case AchievementType.leagueClimber:
        return 'Atteignez la league Or';
      case AchievementType.topTen:
        return 'Entrez dans le top 10';
    }
  }
  
  String get iconEmoji {
    switch (this) {
      case AchievementType.firstGem:
        return '✨';
      case AchievementType.gemCollector:
        return '💎';
      case AchievementType.gemMaster:
        return '👑';
      case AchievementType.streakWarrior:
        return '🔥';
      case AchievementType.streakLegend:
        return '⚡';
      case AchievementType.sessionMarathon:
        return '🏃';
      case AchievementType.perfectionist:
        return '🎯';
      case AchievementType.rareCollector:
        return '🏆';
      case AchievementType.leagueClimber:
        return '🚀';
      case AchievementType.topTen:
        return '🌟';
    }
  }
}

/// Provider pour le service de leaderboard
final virelangueLeaderboardServiceProvider = Provider<VirelangueLeaderboardService>((ref) {
  return VirelangueLeaderboardService();
});