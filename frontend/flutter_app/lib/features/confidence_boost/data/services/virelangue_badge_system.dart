import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/virelangue_models.dart';
import 'virelangue_leaderboard_service.dart';

part 'virelangue_badge_system.g.dart';

/// Système de badges avancé pour les virelangues
/// 
/// 🏅 SYSTÈME DE BADGES COMPLET :
/// - Badges de progression (débutant à maître)
/// - Badges de spécialisation (types de virelangues)
/// - Badges temporels (quotidiens, hebdomadaires, saisonniers)
/// - Badges de défis et de maîtrise technique
/// - Badges sociaux et compétitifs
/// - Badges d'événements spéciaux et accomplissements rares
/// - Système de séries de badges et collections thématiques
/// - Badges évolutifs avec niveaux multiples
class VirelangueBadgeSystem {
  final Logger _logger = Logger();
  final VirelangueLeaderboardService _leaderboardService;
  
  static const String _badgeBoxName = 'virelangueBadgeBox';
  static const String _badgeProgressBoxName = 'virelangueBadgeProgressBox';
  static const String _badgeSeriesBoxName = 'virelangueBadgeSeriesBox';
  static const String _specialEventBadgeBoxName = 'virelangueSpecialEventBadgeBox';
  
  VirelangueBadgeSystem(this._leaderboardService);

  /// Initialise le système de badges
  Future<void> initialize() async {
    try {
      _logger.i('🏅 Initialisation VirelangueBadgeSystem...');
      
      // Ouvrir les boîtes Hive
      if (!Hive.isBoxOpen(_badgeBoxName)) {
        await Hive.openBox<VirelangueBadge>(_badgeBoxName);
      }
      if (!Hive.isBoxOpen(_badgeProgressBoxName)) {
        await Hive.openBox<BadgeProgress>(_badgeProgressBoxName);
      }
      if (!Hive.isBoxOpen(_badgeSeriesBoxName)) {
        await Hive.openBox<BadgeSeries>(_badgeSeriesBoxName);
      }
      if (!Hive.isBoxOpen(_specialEventBadgeBoxName)) {
        await Hive.openBox<SpecialEventBadge>(_specialEventBadgeBoxName);
      }
      
      // Initialiser les séries de badges prédéfinies
      await _initializeBadgeSeries();
      
      _logger.i('✅ VirelangueBadgeSystem initialisé avec succès');
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur initialisation badge system: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Vérifie et attribue les nouveaux badges après une session
  Future<List<VirelangueBadge>> checkAndAwardBadges({
    required String userId,
    required VirelangueExerciseState exerciseState,
    required List<GemReward> sessionRewards,
    required VirelangueUserProgress userProgress,
  }) async {
    try {
      _logger.i('🔍 Vérification badges pour: $userId');
      
      final newlyEarnedBadges = <VirelangueBadge>[];
      
      // 1. Badges de progression générale
      newlyEarnedBadges.addAll(await _checkProgressionBadges(userId, userProgress));
      
      // 2. Badges de performance
      newlyEarnedBadges.addAll(await _checkPerformanceBadges(userId, exerciseState, userProgress));
      
      // 3. Badges de gemmes et collection
      newlyEarnedBadges.addAll(await _checkGemBadges(userId, sessionRewards, userProgress));
      
      // 4. Badges de streaks et combos
      newlyEarnedBadges.addAll(await _checkStreakBadges(userId, userProgress));
      
      // 5. Badges de difficulté et spécialisation
      newlyEarnedBadges.addAll(await _checkDifficultyBadges(userId, exerciseState, userProgress));
      
      // 6. Badges temporels (quotidiens, hebdomadaires)
      newlyEarnedBadges.addAll(await _checkTemporalBadges(userId, userProgress));
      
      // 7. Badges d'événements spéciaux
      newlyEarnedBadges.addAll(await _checkSpecialEventBadges(userId, exerciseState));
      
      // 8. Badges de séries et collections
      newlyEarnedBadges.addAll(await _checkSeriesBadges(userId));
      
      // Sauvegarder les nouveaux badges
      if (newlyEarnedBadges.isNotEmpty) {
        await _saveEarnedBadges(userId, newlyEarnedBadges);
        await _updateBadgeProgress(userId, newlyEarnedBadges);
        
        _logger.i('🎉 ${newlyEarnedBadges.length} nouveaux badges obtenus !');
        for (final badge in newlyEarnedBadges) {
          _logger.i('🏅 Badge obtenu: ${badge.name}');
        }
      }
      
      return newlyEarnedBadges;
      
    } catch (e) {
      _logger.e('❌ Erreur vérification badges: $e');
      return [];
    }
  }

  /// Récupère tous les badges d'un utilisateur
  Future<UserBadgeCollection> getUserBadgeCollection(String userId) async {
    try {
      final badgeBox = Hive.box<VirelangueBadge>(_badgeBoxName);
      final userBadges = badgeBox.values
          .where((badge) => badge.userId == userId)
          .toList();
      
      // Trier par date d'obtention (plus récent en premier)
      userBadges.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
      
      // Organiser par catégories
      final badgesByCategory = <BadgeCategory, List<VirelangueBadge>>{};
      for (final category in BadgeCategory.values) {
        badgesByCategory[category] = userBadges
            .where((badge) => badge.category == category)
            .toList();
      }
      
      // Calculer les statistiques
      final stats = _calculateBadgeStats(userBadges);
      
      // Récupérer la progression des séries
      final seriesProgress = await _getBadgeSeriesProgress(userId);
      
      return UserBadgeCollection(
        userId: userId,
        allBadges: userBadges,
        badgesByCategory: badgesByCategory,
        stats: stats,
        seriesProgress: seriesProgress,
        lastUpdated: DateTime.now(),
      );
      
    } catch (e) {
      _logger.e('❌ Erreur récupération collection badges: $e');
      rethrow;
    }
  }

  /// Vérifie les badges de progression générale
  Future<List<VirelangueBadge>> _checkProgressionBadges(
    String userId,
    VirelangueUserProgress userProgress,
  ) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    
    // Badge première session
    if (!earnedBadgeTypes.contains(BadgeType.firstSession) && userProgress.totalSessions >= 1) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.firstSession,
        category: BadgeCategory.progression,
        level: 1,
      ));
    }
    
    // Badges de sessions multiples
    if (!earnedBadgeTypes.contains(BadgeType.sessionNovice) && userProgress.totalSessions >= 10) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.sessionNovice,
        category: BadgeCategory.progression,
        level: 1,
      ));
    }
    
    if (!earnedBadgeTypes.contains(BadgeType.sessionAdept) && userProgress.totalSessions >= 50) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.sessionAdept,
        category: BadgeCategory.progression,
        level: 1,
      ));
    }
    
    if (!earnedBadgeTypes.contains(BadgeType.sessionMaster) && userProgress.totalSessions >= 200) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.sessionMaster,
        category: BadgeCategory.progression,
        level: 1,
      ));
    }
    
    return newBadges;
  }

  /// Vérifie les badges de performance
  Future<List<VirelangueBadge>> _checkPerformanceBadges(
    String userId,
    VirelangueExerciseState exerciseState,
    VirelangueUserProgress userProgress,
  ) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    
    // Badge première performance parfaite
    if (!earnedBadgeTypes.contains(BadgeType.perfectPronunciation) && 
        exerciseState.sessionScore >= 1.0) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.perfectPronunciation,
        category: BadgeCategory.performance,
        level: 1,
      ));
    }
    
    // Badge score moyen élevé
    if (!earnedBadgeTypes.contains(BadgeType.consistentPerformer) && 
        userProgress.averageScore >= 0.85 && userProgress.totalSessions >= 20) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.consistentPerformer,
        category: BadgeCategory.performance,
        level: 1,
      ));
    }
    
    // Badge perfectionniste
    if (!earnedBadgeTypes.contains(BadgeType.perfectionist) && 
        userProgress.averageScore >= 0.95 && userProgress.totalSessions >= 50) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.perfectionist,
        category: BadgeCategory.performance,
        level: 1,
      ));
    }
    
    return newBadges;
  }

  /// Vérifie les badges de gemmes
  Future<List<VirelangueBadge>> _checkGemBadges(
    String userId,
    List<GemReward> sessionRewards,
    VirelangueUserProgress userProgress,
  ) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    
    // Badge première gemme diamant
    final hasDiamond = sessionRewards.any((r) => r.type == GemType.diamond);
    if (!earnedBadgeTypes.contains(BadgeType.firstDiamond) && hasDiamond) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.firstDiamond,
        category: BadgeCategory.gems,
        level: 1,
      ));
    }
    
    // Badge jackpot (plusieurs gemmes rares en une session)
    final rareGemCount = sessionRewards
        .where((r) => r.type == GemType.emerald || r.type == GemType.diamond)
        .fold(0, (sum, r) => sum + r.finalCount);
    
    if (!earnedBadgeTypes.contains(BadgeType.gemJackpot) && rareGemCount >= 5) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.gemJackpot,
        category: BadgeCategory.gems,
        level: 1,
      ));
    }
    
    // Badge collectionneur selon la valeur totale
    if (!earnedBadgeTypes.contains(BadgeType.gemCollector) && 
        userProgress.totalGemValue >= 10000) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.gemCollector,
        category: BadgeCategory.gems,
        level: 1,
      ));
    }
    
    return newBadges;
  }

  /// Vérifie les badges de streaks
  Future<List<VirelangueBadge>> _checkStreakBadges(
    String userId,
    VirelangueUserProgress userProgress,
  ) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    
    // Badges de streaks progressifs
    if (!earnedBadgeTypes.contains(BadgeType.streakWarrior) && 
        userProgress.currentStreak >= 7) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.streakWarrior,
        category: BadgeCategory.streaks,
        level: 1,
      ));
    }
    
    if (!earnedBadgeTypes.contains(BadgeType.streakLegend) && 
        userProgress.currentStreak >= 30) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.streakLegend,
        category: BadgeCategory.streaks,
        level: 1,
      ));
    }
    
    if (!earnedBadgeTypes.contains(BadgeType.streakGod) && 
        userProgress.currentStreak >= 100) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.streakGod,
        category: BadgeCategory.streaks,
        level: 1,
      ));
    }
    
    // Badge combo maître
    if (!earnedBadgeTypes.contains(BadgeType.comboMaster) && 
        userProgress.currentCombo >= 20) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.comboMaster,
        category: BadgeCategory.streaks,
        level: 1,
      ));
    }
    
    return newBadges;
  }

  /// Vérifie les badges de difficulté
  Future<List<VirelangueBadge>> _checkDifficultyBadges(
    String userId,
    VirelangueExerciseState exerciseState,
    VirelangueUserProgress userProgress,
  ) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    
    // Badge première réussite expert
    if (!earnedBadgeTypes.contains(BadgeType.expertConqueror) && 
        exerciseState.currentVirelangue?.difficulty == VirelangueDifficulty.expert &&
        exerciseState.sessionScore >= 0.8) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.expertConqueror,
        category: BadgeCategory.difficulty,
        level: 1,
      ));
    }
    
    // Badge spécialiste selon le niveau actuel
    if (!earnedBadgeTypes.contains(BadgeType.difficultySpecialist) && 
        userProgress.currentLevel == VirelangueDifficulty.expert) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.difficultySpecialist,
        category: BadgeCategory.difficulty,
        level: 1,
      ));
    }
    
    return newBadges;
  }

  /// Vérifie les badges temporels
  Future<List<VirelangueBadge>> _checkTemporalBadges(
    String userId,
    VirelangueUserProgress userProgress,
  ) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    final now = DateTime.now();
    
    // Badge de session quotidienne (session aujourd'hui)
    if (!earnedBadgeTypes.contains(BadgeType.dailyPractice) && 
        _isToday(userProgress.lastSessionDate)) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.dailyPractice,
        category: BadgeCategory.temporal,
        level: 1,
      ));
    }
    
    // Badge weekend warrior (sessions le weekend)
    if (!earnedBadgeTypes.contains(BadgeType.weekendWarrior) && 
        (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) &&
        _isToday(userProgress.lastSessionDate)) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.weekendWarrior,
        category: BadgeCategory.temporal,
        level: 1,
      ));
    }
    
    return newBadges;
  }

  /// Vérifie les badges d'événements spéciaux
  Future<List<VirelangueBadge>> _checkSpecialEventBadges(
    String userId,
    VirelangueExerciseState exerciseState,
  ) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    
    // Badge événement spécial actif
    if (exerciseState.isSpecialEvent && 
        !earnedBadgeTypes.contains(BadgeType.specialEventParticipant)) {
      newBadges.add(_createBadge(
        userId: userId,
        type: BadgeType.specialEventParticipant,
        category: BadgeCategory.special,
        level: 1,
      ));
    }
    
    return newBadges;
  }

  /// Vérifie les badges de séries
  Future<List<VirelangueBadge>> _checkSeriesBadges(String userId) async {
    final newBadges = <VirelangueBadge>[];
    final earnedBadgeTypes = await _getEarnedBadgeTypes(userId);
    
    // Vérifier les séries complétées
    final seriesProgress = await _getBadgeSeriesProgress(userId);
    
    for (final series in seriesProgress) {
      if (series.isComplete && 
          !earnedBadgeTypes.contains(BadgeType.seriesCompleter)) {
        newBadges.add(_createBadge(
          userId: userId,
          type: BadgeType.seriesCompleter,
          category: BadgeCategory.special,
          level: 1,
          seriesName: series.name,
        ));
      }
    }
    
    return newBadges;
  }

  /// Crée un nouveau badge
  VirelangueBadge _createBadge({
    required String userId,
    required BadgeType type,
    required BadgeCategory category,
    required int level,
    String? seriesName,
  }) {
    return VirelangueBadge(
      id: '${userId}_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      category: category,
      name: type.displayName,
      description: type.description,
      iconEmoji: type.iconEmoji,
      level: level,
      rarity: type.rarity,
      earnedAt: DateTime.now(),
      seriesName: seriesName,
    );
  }

  /// Récupère les types de badges déjà obtenus
  Future<Set<BadgeType>> _getEarnedBadgeTypes(String userId) async {
    final badgeBox = Hive.box<VirelangueBadge>(_badgeBoxName);
    return badgeBox.values
        .where((badge) => badge.userId == userId)
        .map((badge) => badge.type)
        .toSet();
  }

  /// Sauvegarde les badges obtenus
  Future<void> _saveEarnedBadges(String userId, List<VirelangueBadge> badges) async {
    final badgeBox = Hive.box<VirelangueBadge>(_badgeBoxName);
    
    for (final badge in badges) {
      await badgeBox.put(badge.id, badge);
    }
  }

  /// Met à jour la progression des badges
  Future<void> _updateBadgeProgress(String userId, List<VirelangueBadge> newBadges) async {
    final progressBox = Hive.box<BadgeProgress>(_badgeProgressBoxName);
    
    var progress = progressBox.get(userId) ?? BadgeProgress(
      userId: userId,
      totalBadges: 0,
      badgesByCategory: {},
      badgesByRarity: {},
      lastBadgeEarned: null,
      streak: 0,
    );
    
    // Mettre à jour les statistiques
    progress.totalBadges += newBadges.length;
    progress.lastBadgeEarned = DateTime.now();
    
    // Mettre à jour par catégorie
    for (final badge in newBadges) {
      progress.badgesByCategory[badge.category] = 
          (progress.badgesByCategory[badge.category] ?? 0) + 1;
      progress.badgesByRarity[badge.rarity] = 
          (progress.badgesByRarity[badge.rarity] ?? 0) + 1;
    }
    
    await progressBox.put(userId, progress);
  }

  /// Calcule les statistiques des badges
  BadgeStats _calculateBadgeStats(List<VirelangueBadge> badges) {
    final totalBadges = badges.length;
    final badgesByRarity = <BadgeRarity, int>{};
    final badgesByCategory = <BadgeCategory, int>{};
    
    for (final badge in badges) {
      badgesByRarity[badge.rarity] = (badgesByRarity[badge.rarity] ?? 0) + 1;
      badgesByCategory[badge.category] = (badgesByCategory[badge.category] ?? 0) + 1;
    }
    
    final rareCount = badgesByRarity[BadgeRarity.rare] ?? 0;
    final epicCount = badgesByRarity[BadgeRarity.epic] ?? 0;
    final legendaryCount = badgesByRarity[BadgeRarity.legendary] ?? 0;
    
    return BadgeStats(
      totalBadges: totalBadges,
      commonBadges: badgesByRarity[BadgeRarity.common] ?? 0,
      rareBadges: rareCount,
      epicBadges: epicCount,
      legendaryBadges: legendaryCount,
      badgesByCategory: badgesByCategory,
      completionPercentage: _calculateCompletionPercentage(badges),
      lastEarnedBadge: badges.isNotEmpty ? badges.first : null,
    );
  }

  /// Calcule le pourcentage de complétion
  double _calculateCompletionPercentage(List<VirelangueBadge> badges) {
    final totalPossibleBadges = BadgeType.values.length;
    final uniqueBadgeTypes = badges.map((b) => b.type).toSet();
    return (uniqueBadgeTypes.length / totalPossibleBadges) * 100.0;
  }

  /// Récupère la progression des séries de badges
  Future<List<BadgeSeriesProgress>> _getBadgeSeriesProgress(String userId) async {
    // À implémenter : logique de progression des séries
    return [];
  }

  /// Initialise les séries de badges prédéfinies
  Future<void> _initializeBadgeSeries() async {
    // À implémenter : création des séries de badges
  }

  /// Vérifie si une date est aujourd'hui
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Libère les ressources
  void dispose() {
    _logger.i('🗑️ VirelangueBadgeSystem disposé');
  }
}

// ========== MODÈLES DE DONNÉES ==========

/// Badge de virelangue
@HiveType(typeId: 42)
class VirelangueBadge extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  BadgeType type;
  
  @HiveField(3)
  BadgeCategory category;
  
  @HiveField(4)
  String name;
  
  @HiveField(5)
  String description;
  
  @HiveField(6)
  String iconEmoji;
  
  @HiveField(7)
  int level;
  
  @HiveField(8)
  BadgeRarity rarity;
  
  @HiveField(9)
  DateTime earnedAt;
  
  @HiveField(10)
  String? seriesName;

  VirelangueBadge({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.name,
    required this.description,
    required this.iconEmoji,
    this.level = 1,
    required this.rarity,
    required this.earnedAt,
    this.seriesName,
  });
}

/// Types de badges
enum BadgeType {
  // Progression
  firstSession,
  sessionNovice,
  sessionAdept,
  sessionMaster,
  
  // Performance
  perfectPronunciation,
  consistentPerformer,
  perfectionist,
  
  // Gemmes
  firstDiamond,
  gemJackpot,
  gemCollector,
  
  // Streaks
  streakWarrior,
  streakLegend,
  streakGod,
  comboMaster,
  
  // Difficulté
  expertConqueror,
  difficultySpecialist,
  
  // Temporel
  dailyPractice,
  weekendWarrior,
  
  // Spécial
  specialEventParticipant,
  seriesCompleter,
}

extension BadgeTypeExtension on BadgeType {
  String get displayName {
    switch (this) {
      case BadgeType.firstSession:
        return 'Premier Pas';
      case BadgeType.sessionNovice:
        return 'Novice Déterminé';
      case BadgeType.sessionAdept:
        return 'Adepte Assidu';
      case BadgeType.sessionMaster:
        return 'Maître de la Pratique';
      case BadgeType.perfectPronunciation:
        return 'Prononciation Parfaite';
      case BadgeType.consistentPerformer:
        return 'Performance Constante';
      case BadgeType.perfectionist:
        return 'Perfectionniste';
      case BadgeType.firstDiamond:
        return 'Premier Diamant';
      case BadgeType.gemJackpot:
        return 'Jackpot de Gemmes';
      case BadgeType.gemCollector:
        return 'Grand Collectionneur';
      case BadgeType.streakWarrior:
        return 'Guerrier des Séries';
      case BadgeType.streakLegend:
        return 'Légende des Séries';
      case BadgeType.streakGod:
        return 'Dieu des Séries';
      case BadgeType.comboMaster:
        return 'Maître des Combos';
      case BadgeType.expertConqueror:
        return 'Conquérant Expert';
      case BadgeType.difficultySpecialist:
        return 'Spécialiste de la Difficulté';
      case BadgeType.dailyPractice:
        return 'Pratique Quotidienne';
      case BadgeType.weekendWarrior:
        return 'Guerrier du Weekend';
      case BadgeType.specialEventParticipant:
        return 'Participant Spécial';
      case BadgeType.seriesCompleter:
        return 'Compléteur de Série';
    }
  }
  
  String get description {
    switch (this) {
      case BadgeType.firstSession:
        return 'Complétez votre première session';
      case BadgeType.sessionNovice:
        return 'Complétez 10 sessions';
      case BadgeType.sessionAdept:
        return 'Complétez 50 sessions';
      case BadgeType.sessionMaster:
        return 'Complétez 200 sessions';
      case BadgeType.perfectPronunciation:
        return 'Obtenez un score parfait';
      case BadgeType.consistentPerformer:
        return 'Maintenez 85% de moyenne';
      case BadgeType.perfectionist:
        return 'Maintenez 95% de moyenne';
      case BadgeType.firstDiamond:
        return 'Obtenez votre premier diamant';
      case BadgeType.gemJackpot:
        return 'Obtenez 5+ gemmes rares en une session';
      case BadgeType.gemCollector:
        return 'Collectez 10000 points de gemmes';
      case BadgeType.streakWarrior:
        return 'Maintenez une série de 7';
      case BadgeType.streakLegend:
        return 'Maintenez une série de 30';
      case BadgeType.streakGod:
        return 'Maintenez une série de 100';
      case BadgeType.comboMaster:
        return 'Atteignez un combo de 20';
      case BadgeType.expertConqueror:
        return 'Réussissez un virelangue expert';
      case BadgeType.difficultySpecialist:
        return 'Atteignez le niveau expert';
      case BadgeType.dailyPractice:
        return 'Pratiquez quotidiennement';
      case BadgeType.weekendWarrior:
        return 'Pratiquez le weekend';
      case BadgeType.specialEventParticipant:
        return 'Participez à un événement spécial';
      case BadgeType.seriesCompleter:
        return 'Complétez une série de badges';
    }
  }
  
  String get iconEmoji {
    switch (this) {
      case BadgeType.firstSession:
        return '🌟';
      case BadgeType.sessionNovice:
        return '🔰';
      case BadgeType.sessionAdept:
        return '🎯';
      case BadgeType.sessionMaster:
        return '🏆';
      case BadgeType.perfectPronunciation:
        return '💯';
      case BadgeType.consistentPerformer:
        return '📈';
      case BadgeType.perfectionist:
        return '🎭';
      case BadgeType.firstDiamond:
        return '💎';
      case BadgeType.gemJackpot:
        return '🎰';
      case BadgeType.gemCollector:
        return '👑';
      case BadgeType.streakWarrior:
        return '🔥';
      case BadgeType.streakLegend:
        return '⚡';
      case BadgeType.streakGod:
        return '🌟';
      case BadgeType.comboMaster:
        return '🎮';
      case BadgeType.expertConqueror:
        return '⚔️';
      case BadgeType.difficultySpecialist:
        return '🧠';
      case BadgeType.dailyPractice:
        return '📅';
      case BadgeType.weekendWarrior:
        return '🗡️';
      case BadgeType.specialEventParticipant:
        return '🎉';
      case BadgeType.seriesCompleter:
        return '📚';
    }
  }
  
  BadgeRarity get rarity {
    switch (this) {
      case BadgeType.firstSession:
      case BadgeType.dailyPractice:
        return BadgeRarity.common;
      case BadgeType.sessionNovice:
      case BadgeType.perfectPronunciation:
      case BadgeType.firstDiamond:
      case BadgeType.streakWarrior:
        return BadgeRarity.rare;
      case BadgeType.sessionAdept:
      case BadgeType.consistentPerformer:
      case BadgeType.gemJackpot:
      case BadgeType.streakLegend:
      case BadgeType.expertConqueror:
        return BadgeRarity.epic;
      case BadgeType.sessionMaster:
      case BadgeType.perfectionist:
      case BadgeType.gemCollector:
      case BadgeType.streakGod:
      case BadgeType.difficultySpecialist:
      case BadgeType.comboMaster:
      case BadgeType.weekendWarrior:
      case BadgeType.specialEventParticipant:
      case BadgeType.seriesCompleter:
        return BadgeRarity.legendary;
    }
  }
}

/// Catégories de badges
enum BadgeCategory {
  progression,
  performance,
  gems,
  streaks,
  difficulty,
  temporal,
  special,
}

/// Rareté des badges
enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Progression des badges d'un utilisateur
@HiveType(typeId: 43)
class BadgeProgress extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  int totalBadges;
  
  @HiveField(2)
  Map<BadgeCategory, int> badgesByCategory;
  
  @HiveField(3)
  Map<BadgeRarity, int> badgesByRarity;
  
  @HiveField(4)
  DateTime? lastBadgeEarned;
  
  @HiveField(5)
  int streak;

  BadgeProgress({
    required this.userId,
    this.totalBadges = 0,
    required this.badgesByCategory,
    required this.badgesByRarity,
    this.lastBadgeEarned,
    this.streak = 0,
  });
}

/// Collection de badges d'un utilisateur
class UserBadgeCollection {
  final String userId;
  final List<VirelangueBadge> allBadges;
  final Map<BadgeCategory, List<VirelangueBadge>> badgesByCategory;
  final BadgeStats stats;
  final List<BadgeSeriesProgress> seriesProgress;
  final DateTime lastUpdated;

  const UserBadgeCollection({
    required this.userId,
    required this.allBadges,
    required this.badgesByCategory,
    required this.stats,
    required this.seriesProgress,
    required this.lastUpdated,
  });
}

/// Statistiques des badges
class BadgeStats {
  final int totalBadges;
  final int commonBadges;
  final int rareBadges;
  final int epicBadges;
  final int legendaryBadges;
  final Map<BadgeCategory, int> badgesByCategory;
  final double completionPercentage;
  final VirelangueBadge? lastEarnedBadge;

  const BadgeStats({
    required this.totalBadges,
    required this.commonBadges,
    required this.rareBadges,
    required this.epicBadges,
    required this.legendaryBadges,
    required this.badgesByCategory,
    required this.completionPercentage,
    this.lastEarnedBadge,
  });
}

/// Série de badges
@HiveType(typeId: 44)
class BadgeSeries extends HiveObject {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String description;
  
  @HiveField(2)
  List<BadgeType> requiredBadges;
  
  @HiveField(3)
  BadgeRarity seriesRarity;
  
  @HiveField(4)
  String rewardEmoji;

  BadgeSeries({
    required this.name,
    required this.description,
    required this.requiredBadges,
    required this.seriesRarity,
    required this.rewardEmoji,
  });
}

/// Progression d'une série de badges
class BadgeSeriesProgress {
  final String name;
  final List<BadgeType> requiredBadges;
  final List<BadgeType> earnedBadges;
  final bool isComplete;
  final double progressPercentage;

  const BadgeSeriesProgress({
    required this.name,
    required this.requiredBadges,
    required this.earnedBadges,
    required this.isComplete,
    required this.progressPercentage,
  });
}

/// Badge d'événement spécial
@HiveType(typeId: 45)
class SpecialEventBadge extends HiveObject {
  @HiveField(0)
  String eventName;
  
  @HiveField(1)
  String eventDescription;
  
  @HiveField(2)
  DateTime startDate;
  
  @HiveField(3)
  DateTime endDate;
  
  @HiveField(4)
  BadgeType associatedBadge;
  
  @HiveField(5)
  bool isActive;

  SpecialEventBadge({
    required this.eventName,
    required this.eventDescription,
    required this.startDate,
    required this.endDate,
    required this.associatedBadge,
    this.isActive = true,
  });
}

/// Provider pour le système de badges
final virelangueBadgeSystemProvider = Provider<VirelangueBadgeSystem>((ref) {
  final leaderboardService = ref.watch(virelangueLeaderboardServiceProvider);
  return VirelangueBadgeSystem(leaderboardService);
});