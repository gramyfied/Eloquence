import '../../data/repositories/gamification_repository.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/gamification_models.dart';

class BadgeService {
  final GamificationRepository _repository;

  BadgeService(this._repository);

  Future<List<Badge>> checkAndAwardBadges({
    required String userId,
    required ConfidenceAnalysis analysis,
    required ConfidenceScenario scenario,
    required int earnedXP,
    required LevelUpResult levelResult,
    required StreakInfo streakInfo,
  }) async {
    final newBadges = <Badge>[];
    final userProfile = await _repository.getUserProfile(userId);
    final earnedBadgeIds = userProfile.earnedBadgeIds;

    // Vérifier tous les types de badges
    newBadges.addAll(await _checkPerformanceBadges(analysis, earnedBadgeIds));
    newBadges.addAll(await _checkStreakBadges(streakInfo, earnedBadgeIds));
    newBadges.addAll(await _checkMilestoneBadges(userProfile, earnedBadgeIds, levelResult));
    newBadges.addAll(await _checkSpecialBadges(userProfile, earnedBadgeIds, scenario));

    // Attribuer les nouveaux badges
    for (final badge in newBadges) {
      await _repository.awardBadge(userId, badge.id);
    }

    return newBadges;
  }

  Future<List<Badge>> _checkPerformanceBadges(ConfidenceAnalysis analysis, List<String> earnedIds) async {
    final badges = <Badge>[];
    final allBadges = await _repository.getAllBadges();

    // Premier Excellence (85%+)
    if (analysis.overallScore >= 85 && !earnedIds.contains('first_excellent')) {
      badges.add(allBadges.firstWhere((b) => b.id == 'first_excellent'));
    }

    // Perfectionniste (100%)
    if (analysis.overallScore >= 100 && !earnedIds.contains('perfectionist')) {
      badges.add(allBadges.firstWhere((b) => b.id == 'perfectionist'));
    }
    
    return badges;
  }

  Future<List<Badge>> _checkStreakBadges(StreakInfo streakInfo, List<String> earnedIds) async {
    final badges = <Badge>[];
    final allBadges = await _repository.getAllBadges();

    if (streakInfo.currentStreak >= 3 && !earnedIds.contains('streak_3')) {
      badges.add(allBadges.firstWhere((b) => b.id == 'streak_3'));
    }
    if (streakInfo.currentStreak >= 7 && !earnedIds.contains('streak_7')) {
      badges.add(allBadges.firstWhere((b) => b.id == 'streak_7'));
    }
    if (streakInfo.currentStreak >= 30 && !earnedIds.contains('streak_30')) {
      badges.add(allBadges.firstWhere((b) => b.id == 'streak_30'));
    }

    return badges;
  }

  Future<List<Badge>> _checkMilestoneBadges(UserGamificationProfile profile, List<String> earnedIds, LevelUpResult levelResult) async {
    final badges = <Badge>[];
    final allBadges = await _repository.getAllBadges();

    if (profile.totalSessions == 1 && !earnedIds.contains('first_session')) {
        badges.add(allBadges.firstWhere((b) => b.id == 'first_session'));
    }
    if (profile.totalSessions >= 100 && !earnedIds.contains('centurion')) {
        badges.add(allBadges.firstWhere((b) => b.id == 'centurion'));
    }
    if (levelResult.newLevel >= 5 && !earnedIds.contains('novice')) {
        badges.add(allBadges.firstWhere((b) => b.id == 'novice'));
    }
    if (levelResult.newLevel >= 10 && !earnedIds.contains('adept')) {
        badges.add(allBadges.firstWhere((b) => b.id == 'adept'));
    }
    if (profile.totalXP >= 10000 && !earnedIds.contains('xp_10000')) {
        badges.add(allBadges.firstWhere((b) => b.id == 'xp_10000'));
    }
    
    return badges;
  }

  Future<List<Badge>> _checkSpecialBadges(UserGamificationProfile profile, List<String> earnedIds, ConfidenceScenario scenario) async {
      final badges = <Badge>[];
      final allBadges = await _repository.getAllBadges();
      final hour = DateTime.now().hour;

      if (hour >= 22 && !earnedIds.contains('night_owl')) {
          badges.add(allBadges.firstWhere((b) => b.id == 'night_owl'));
      }
      if (hour <= 7 && !earnedIds.contains('early_bird')) {
          badges.add(allBadges.firstWhere((b) => b.id == 'early_bird'));
      }
      
      return badges;
  }
}