import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/gamification_models.dart';

// Types temporaires pour compilation
class AnalysisResult {
  final double overallConfidenceScore;
  final Map<String, double> skillScores;
  
  AnalysisResult({
    required this.overallConfidenceScore,
    this.skillScores = const {},
  });
}

enum ConversationDifficulty { debutant, intermediaire, avance, expert }

extension ConversationDifficultyExtension on ConversationDifficulty {
  String get name => toString().split('.').last;
}

/// Service de Gamification Adaptatif Intelligent pour Confidence Boost
/// 
/// ✅ FONCTIONNALITÉS AVANCÉES :
/// - XP adaptatif basé sur performance et difficulté
/// - Badges contextuels débloqués selon les patterns
/// - Système de streak sophistiqué avec multiplicateurs
/// - Récompenses personnalisées selon profil utilisateur
/// - Détection de progrès et encouragements ciblés
/// - Analytics de gamification pour optimisation
class AdaptiveGamificationService {
  final Logger _logger = Logger();
  
  static const String _profileBoxName = 'userGamificationProfileBox';
  static const String _badgesBoxName = 'badgesCollectionBox';
  
  // ========== CONFIGURATION XP ADAPTATIF ==========
  
  /// XP de base par performance (multiplicateurs contextuels appliqués ensuite)
  static final Map<double, int> _baseXPByPerformance = {
    0.95: 150, // Excellent (95%+)
    0.85: 120, // Très bon (85-94%)
    0.75: 100, // Bon (75-84%)
    0.65: 80,  // Correct (65-74%)
    0.50: 60,  // Faible (50-64%)
    0.0: 40,   // Très faible (0-49%)
  };
  
  /// Multiplicateurs de difficulté
  static const Map<String, double> _difficultyMultipliers = {
    'débutant': 1.0,
    'intermédiaire': 1.3,
    'avancé': 1.6,
    'expert': 2.0,
  };
  
  /// Multiplicateurs de streak (bonus consécutif)
  static const Map<int, double> _streakMultipliers = {
    1: 1.0,   // Pas de streak
    3: 1.1,   // 3 jours consécutifs
    7: 1.25,  // 1 semaine
    14: 1.4,  // 2 semaines
    30: 1.6,  // 1 mois
    60: 1.8,  // 2 mois
    90: 2.0,  // 3 mois
  };
  
  // ========== INITIALISATION ==========
  
  Future<void> initialize() async {
    try {
      _logger.i('🎮 Initialisation AdaptiveGamificationService...');
      
      await _initializeHiveBoxes();
      await _initializeBadgesCollection();
      
      _logger.i('✅ AdaptiveGamificationService initialisé avec succès');
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur initialisation gamification: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  Future<void> _initializeHiveBoxes() async {
    // Ouvrir les boîtes Hive si pas déjà ouvertes
    if (!Hive.isBoxOpen(_profileBoxName)) {
      await Hive.openBox<UserGamificationProfile>(_profileBoxName);
    }
    if (!Hive.isBoxOpen(_badgesBoxName)) {
      await Hive.openBox<Badge>(_badgesBoxName);
    }
  }
  
  Future<void> _initializeBadgesCollection() async {
    final badgesBox = Hive.box<Badge>(_badgesBoxName);
    
    // Initialiser la collection de badges si vide
    if (badgesBox.isEmpty) {
      await _createDefaultBadges();
    }
  }
  
  // ========== GESTION PROFIL UTILISATEUR ==========
  
  Future<UserGamificationProfile> getUserProfile(String userId) async {
    final profileBox = Hive.box<UserGamificationProfile>(_profileBoxName);
    
    UserGamificationProfile? profile = profileBox.get(userId);
    
    if (profile == null) {
      // Créer un nouveau profil
      profile = UserGamificationProfile(
        userId: userId,
        lastSessionDate: DateTime.now(),
      );
      await profileBox.put(userId, profile);
      _logger.i('🎮 Nouveau profil gamification créé pour $userId');
    }
    
    return profile;
  }
  
  Future<void> saveUserProfile(UserGamificationProfile profile) async {
    final profileBox = Hive.box<UserGamificationProfile>(_profileBoxName);
    await profileBox.put(profile.userId, profile);
  }
  
  // ========== CALCUL XP ADAPTATIF ==========
  
  Future<GamificationResult> calculateAdaptiveRewards({
    required String userId,
    required AnalysisResult analysisResult,
    required ConversationDifficulty difficulty,
    required Duration sessionDuration,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      _logger.i('🧮 Calcul des récompenses adaptatives pour $userId');
      
      final profile = await getUserProfile(userId);
      
      // 1. Calculer XP de base selon performance
      final baseXP = _calculateBaseXP(analysisResult);
      
      // 2. Appliquer multiplicateurs contextuels
      final multipliers = _calculateBonusMultipliers(
        profile: profile,
        difficulty: difficulty,
        sessionDuration: sessionDuration,
        analysisResult: analysisResult,
      );
      
      // 3. Calculer XP final avec multiplicateurs
      final finalXP = (baseXP * multipliers.performanceMultiplier * 
                       multipliers.streakMultiplier * 
                       multipliers.difficultyMultiplier * 
                       multipliers.timeMultiplier).round();
      
      // 4. Vérifier les nouveaux badges débloqués
      final newBadges = await _checkForNewBadges(profile, analysisResult, finalXP);
      
      // 5. Calculer le streak mis à jour
      final streakInfo = _calculateStreakInfo(profile);
      
      // 6. Mettre à jour le niveau et vérifier level up
      final updatedProfile = _updateProfileWithRewards(
        profile,
        finalXP,
        newBadges,
        streakInfo,
        analysisResult,
      );
      
      // 7. Sauvegarder le profil mis à jour
      await saveUserProfile(updatedProfile);
      
      final result = GamificationResult(
        earnedXP: finalXP,
        newBadges: newBadges,
        levelUp: updatedProfile.currentLevel > profile.currentLevel,
        newLevel: updatedProfile.currentLevel,
        xpInCurrentLevel: updatedProfile.xpInCurrentLevel,
        xpRequiredForNextLevel: updatedProfile.xpRequiredForNextLevel,
        streakInfo: streakInfo,
        bonusMultiplier: multipliers,
      );
      
      _logger.i('✅ Récompenses calculées: ${finalXP}XP, ${newBadges.length} badges, level ${updatedProfile.currentLevel}');
      
      return result;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur calcul récompenses: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  int _calculateBaseXP(AnalysisResult analysisResult) {
    // Prendre le score global de confiance comme référence
    final overallScore = analysisResult.overallConfidenceScore;
    
    // Trouver la tranche de performance correspondante
    for (final entry in _baseXPByPerformance.entries) {
      if (overallScore >= entry.key) {
        return entry.value;
      }
    }
    
    return _baseXPByPerformance[0.0]!; // Fallback
  }
  
  BonusMultiplier _calculateBonusMultipliers({
    required UserGamificationProfile profile,
    required ConversationDifficulty difficulty,
    required Duration sessionDuration,
    required AnalysisResult analysisResult,
  }) {
    // Multiplicateur de performance (bonus si amélioration)
    double performanceMultiplier = 1.0;
    if (analysisResult.overallConfidenceScore > 0.9) {
      performanceMultiplier = 1.2; // Bonus performance exceptionnelle
    } else if (analysisResult.overallConfidenceScore > 0.8) {
      performanceMultiplier = 1.1; // Bonus bonne performance
    }
    
    // Multiplicateur de difficulté
    final difficultyMultiplier = _difficultyMultipliers[difficulty.name.toLowerCase()] ?? 1.0;
    
    // Multiplicateur de streak
    double streakMultiplier = 1.0;
    for (final entry in _streakMultipliers.entries) {
      if (profile.currentStreak >= entry.key) {
        streakMultiplier = entry.value;
      }
    }
    
    // Multiplicateur de temps (bonus si session longue et qualitative)
    double timeMultiplier = 1.0;
    if (sessionDuration.inMinutes >= 5 && analysisResult.overallConfidenceScore > 0.7) {
      timeMultiplier = 1.1; // Bonus session longue de qualité
    }
    
    return BonusMultiplier(
      performanceMultiplier: performanceMultiplier,
      streakMultiplier: streakMultiplier,
      timeMultiplier: timeMultiplier,
      difficultyMultiplier: difficultyMultiplier,
    );
  }
  
  // ========== SYSTÈME DE BADGES CONTEXTUELS ==========
  
  Future<List<Badge>> _checkForNewBadges(
    UserGamificationProfile profile,
    AnalysisResult analysisResult,
    int earnedXP,
  ) async {
    final List<Badge> newBadges = [];
    final badgesBox = Hive.box<Badge>(_badgesBoxName);
    
    // Vérifier chaque type de badge
    for (final badge in badgesBox.values) {
      if (!profile.earnedBadgeIds.contains(badge.id)) {
        if (await _shouldEarnBadge(badge, profile, analysisResult, earnedXP)) {
          newBadges.add(badge);
        }
      }
    }
    
    return newBadges;
  }
  
  Future<bool> _shouldEarnBadge(
    Badge badge,
    UserGamificationProfile profile,
    AnalysisResult analysisResult,
    int earnedXP,
  ) async {
    switch (badge.id) {
      // Badges de performance
      case 'first_excellent':
        return analysisResult.overallConfidenceScore >= 0.95;
      case 'perfectionist':
        return analysisResult.overallConfidenceScore >= 0.98;
      case 'consistency_master':
        return profile.totalSessions >= 10 && 
               (profile.perfectSessions / profile.totalSessions) >= 0.8;
      
      // Badges de streak
      case 'streak_3':
        return profile.currentStreak >= 3;
      case 'streak_7':
        return profile.currentStreak >= 7;
      case 'streak_30':
        return profile.currentStreak >= 30;
      
      // Badges de milestone
      case 'level_5':
        return profile.currentLevel >= 5;
      case 'level_10':
        return profile.currentLevel >= 10;
      case 'xp_1000':
        return profile.totalXP >= 1000;
      
      // Badges spéciaux
      case 'early_bird':
        final hour = DateTime.now().hour;
        return hour >= 6 && hour <= 9; // Séance matinale
      case 'night_owl':
        final hour = DateTime.now().hour;
        return hour >= 21 || hour <= 5; // Séance nocturne
      case 'marathon':
        return earnedXP >= 200; // Session très productive
      
      default:
        return false;
    }
  }
  
  // ========== GESTION STREAK ==========
  
  StreakInfo _calculateStreakInfo(UserGamificationProfile profile) {
    final now = DateTime.now();
    final lastSession = profile.lastSessionDate;
    final daysDifference = now.difference(lastSession).inDays;
    
    bool streakBroken = false;
    bool newRecord = false;
    int currentStreak = profile.currentStreak;
    
    if (daysDifference == 0) {
      // Même jour, streak continue
      // Pas de changement
    } else if (daysDifference == 1) {
      // Jour suivant, increment streak
      currentStreak += 1;
      if (currentStreak > profile.longestStreak) {
        newRecord = true;
      }
    } else if (daysDifference > 1) {
      // Gap trop long, streak cassé
      streakBroken = true;
      currentStreak = 1; // Reset à 1 pour cette session
    }
    
    return StreakInfo(
      currentStreak: currentStreak,
      longestStreak: math.max(currentStreak, profile.longestStreak),
      streakBroken: streakBroken,
      newRecord: newRecord,
    );
  }
  
  // ========== MISE À JOUR PROFIL ==========
  
  UserGamificationProfile _updateProfileWithRewards(
    UserGamificationProfile profile,
    int earnedXP,
    List<Badge> newBadges,
    StreakInfo streakInfo,
    AnalysisResult analysisResult,
  ) {
    final newTotalXP = profile.totalXP + earnedXP;
    final newLevel = UserGamificationProfile.calculateLevel(newTotalXP);
    final xpRequiredForNext = UserGamificationProfile.calculateXPForNextLevel(newLevel);
    
    // Calculer XP dans le niveau actuel
    int xpInCurrentLevel = newTotalXP;
    for (int i = 1; i < newLevel; i++) {
      xpInCurrentLevel -= UserGamificationProfile.calculateXPForNextLevel(i);
    }
    
    final newBadgeIds = List<String>.from(profile.earnedBadgeIds);
    newBadgeIds.addAll(newBadges.map((badge) => badge.id));
    
    // Marquer session comme parfaite si score élevé
    final isPerfectSession = analysisResult.overallConfidenceScore >= 0.9;
    
    return profile.copyWith(
      totalXP: newTotalXP,
      currentLevel: newLevel,
      xpInCurrentLevel: xpInCurrentLevel,
      xpRequiredForNextLevel: xpRequiredForNext,
      earnedBadgeIds: newBadgeIds,
      currentStreak: streakInfo.currentStreak,
      longestStreak: streakInfo.longestStreak,
      lastSessionDate: DateTime.now(),
      totalSessions: profile.totalSessions + 1,
      perfectSessions: profile.perfectSessions + (isPerfectSession ? 1 : 0),
    );
  }
  
  // ========== CRÉATION BADGES PAR DÉFAUT ==========
  
  Future<void> _createDefaultBadges() async {
    final badgesBox = Hive.box<Badge>(_badgesBoxName);
    
    final defaultBadges = [
      // Badges de performance
      Badge(
        id: 'first_excellent',
        name: '🌟 Excellence',
        description: 'Premier score supérieur à 95%',
        iconPath: 'assets/badges/excellent.png',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.performance,
        xpReward: 50,
      ),
      Badge(
        id: 'perfectionist',
        name: '💎 Perfectionniste',
        description: 'Score parfait de 98%+',
        iconPath: 'assets/badges/perfect.png',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.performance,
        xpReward: 100,
      ),
      Badge(
        id: 'consistency_master',
        name: '🎯 Maître de la Consistance',
        description: '80% de sessions excellentes sur 10 essais',
        iconPath: 'assets/badges/consistency.png',
        rarity: BadgeRarity.legendary,
        category: BadgeCategory.performance,
        xpReward: 200,
      ),
      
      // Badges de streak
      Badge(
        id: 'streak_3',
        name: '🔥 En Forme',
        description: '3 jours consécutifs',
        iconPath: 'assets/badges/streak3.png',
        rarity: BadgeRarity.common,
        category: BadgeCategory.streak,
        xpReward: 30,
      ),
      Badge(
        id: 'streak_7',
        name: '⚡ Dédication',
        description: '1 semaine de pratique',
        iconPath: 'assets/badges/streak7.png',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.streak,
        xpReward: 75,
      ),
      Badge(
        id: 'streak_30',
        name: '🏆 Champion',
        description: '1 mois sans interruption',
        iconPath: 'assets/badges/streak30.png',
        rarity: BadgeRarity.legendary,
        category: BadgeCategory.streak,
        xpReward: 300,
      ),
      
      // Badges de milestone
      Badge(
        id: 'level_5',
        name: '📈 Progression',
        description: 'Atteindre le niveau 5',
        iconPath: 'assets/badges/level5.png',
        rarity: BadgeRarity.common,
        category: BadgeCategory.milestone,
        xpReward: 25,
      ),
      Badge(
        id: 'level_10',
        name: '🚀 Expert',
        description: 'Atteindre le niveau 10',
        iconPath: 'assets/badges/level10.png',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.milestone,
        xpReward: 150,
      ),
      Badge(
        id: 'xp_1000',
        name: '💫 Millénaire',
        description: '1000 XP accumulés',
        iconPath: 'assets/badges/xp1000.png',
        rarity: BadgeRarity.rare,
        category: BadgeCategory.milestone,
        xpReward: 100,
      ),
      
      // Badges spéciaux
      Badge(
        id: 'early_bird',
        name: '🌅 Lève-tôt',
        description: 'Séance avant 9h du matin',
        iconPath: 'assets/badges/early.png',
        rarity: BadgeRarity.common,
        category: BadgeCategory.special,
        xpReward: 20,
      ),
      Badge(
        id: 'night_owl',
        name: '🌙 Noctambule',
        description: 'Séance après 21h',
        iconPath: 'assets/badges/night.png',
        rarity: BadgeRarity.common,
        category: BadgeCategory.special,
        xpReward: 20,
      ),
      Badge(
        id: 'marathon',
        name: '🏃 Marathon',
        description: 'Session très productive (200+ XP)',
        iconPath: 'assets/badges/marathon.png',
        rarity: BadgeRarity.epic,
        category: BadgeCategory.special,
        xpReward: 50,
      ),
    ];
    
    for (final badge in defaultBadges) {
      await badgesBox.put(badge.id, badge);
    }
    
    _logger.i('✅ ${defaultBadges.length} badges par défaut créés');
  }
  
  // ========== UTILITAIRES ==========
  
  Future<List<Badge>> getAllBadges() async {
    final badgesBox = Hive.box<Badge>(_badgesBoxName);
    return badgesBox.values.toList();
  }
  
  Future<List<Badge>> getUserBadges(String userId) async {
    final profile = await getUserProfile(userId);
    final badgesBox = Hive.box<Badge>(_badgesBoxName);
    
    return profile.earnedBadgeIds
        .map((id) => badgesBox.get(id))
        .where((badge) => badge != null)
        .cast<Badge>()
        .toList();
  }
  
  /// Obtient des encouragements personnalisés selon le profil
  List<String> getPersonalizedEncouragements(UserGamificationProfile profile, AnalysisResult? lastResult) {
    final encouragements = <String>[];
    
    if (profile.currentStreak >= 7) {
      encouragements.add('🔥 Incroyable streak de ${profile.currentStreak} jours !');
    } else if (profile.currentStreak >= 3) {
      encouragements.add('⚡ Belle série de ${profile.currentStreak} jours !');
    }
    
    if (profile.currentLevel >= 10) {
      encouragements.add('🚀 Niveau ${profile.currentLevel} - Vous êtes un expert !');
    } else if (profile.currentLevel >= 5) {
      encouragements.add('📈 Niveau ${profile.currentLevel} - Excellent progrès !');
    }
    
    if (lastResult != null && lastResult.overallConfidenceScore >= 0.9) {
      encouragements.add('🌟 Performance excellente ! Continuez comme ça !');
    }
    
    return encouragements;
  }
}

/// Provider pour le service de gamification
final adaptiveGamificationServiceProvider = Provider<AdaptiveGamificationService>((ref) {
  return AdaptiveGamificationService();
});