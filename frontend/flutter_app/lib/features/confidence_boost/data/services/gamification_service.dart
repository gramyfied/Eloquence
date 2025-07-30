import '../../data/repositories/gamification_repository.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_session.dart';
import '../../domain/entities/gamification_models.dart';
import 'badge_service.dart';
import 'streak_service.dart';
import 'xp_calculator_service.dart';

class GamificationService {
  final GamificationRepository _repository;
  final BadgeService _badgeService;
  final XPCalculatorService _xpCalculator;
  final StreakService _streakService;

  GamificationService(this._repository, this._badgeService, this._xpCalculator, this._streakService);

  Future<GamificationResult> processSessionCompletion({
    required String userId,
    required ConfidenceAnalysis analysis,
    required ConfidenceScenario scenario,
    required TextSupport textSupport,
    required Duration sessionDuration,
  }) async {
    // 1. Récupérer le profil utilisateur
    final userProfile = await _repository.getUserProfile(userId);

    // 2. Calculer l'XP gagné
    final earnedXP = await _xpCalculator.calculateXP(
      analysis: analysis,
      scenario: scenario,
      textSupport: textSupport,
      sessionDuration: sessionDuration,
      userProfile: userProfile,
    );

    // 3. Mettre à jour le streak
    final streakInfo = await _streakService.updateStreak(userId);

    // 4. Calculer le nouveau niveau
    final newTotalXP = userProfile.totalXP + earnedXP;
    final newLevel = UserGamificationProfile.calculateLevel(newTotalXP);
    final levelUp = newLevel > userProfile.currentLevel;
    final xpForNextLevel = UserGamificationProfile.calculateXPForNextLevel(newLevel);
    final xpInCurrentLevel = _calculateXPInCurrentLevel(newTotalXP, newLevel);


    // 5. Vérifier les badges
    final newBadges = await _badgeService.checkAndAwardBadges(
      userId: userId,
      analysis: analysis,
      scenario: scenario,
      earnedXP: earnedXP,
      levelResult: LevelUpResult(leveledUp: levelUp, newLevel: newLevel),
      streakInfo: streakInfo,
    );

    // 6. Mettre à jour le profil utilisateur
    final updatedProfile = userProfile.copyWith(
      totalXP: newTotalXP,
      currentLevel: newLevel,
      xpInCurrentLevel: xpInCurrentLevel,
      xpRequiredForNextLevel: xpForNextLevel,
      totalSessions: userProfile.totalSessions + 1,
      perfectSessions: analysis.overallScore >= 100 ? userProfile.perfectSessions + 1 : userProfile.perfectSessions,
    );

    await _repository.updateUserProfile(updatedProfile);

    // 7. Sauvegarder la session
    final sessionRecord = SessionRecord(
      userId: userId,
      analysis: analysis,
      scenario: scenario,
      textSupport: textSupport,
      earnedXP: earnedXP,
      newBadges: newBadges,
      timestamp: DateTime.now(),
      sessionDuration: sessionDuration,
    );

    await _repository.saveSession(sessionRecord);

    // 8. Retourner le résultat
    return GamificationResult(
      earnedXP: earnedXP,
      newBadges: newBadges,
      levelUp: levelUp,
      newLevel: newLevel,
      xpInCurrentLevel: xpInCurrentLevel,
      xpRequiredForNextLevel: xpForNextLevel,
      streakInfo: streakInfo,
      bonusMultiplier: BonusMultiplier(
        performanceMultiplier: _xpCalculator.calculatePerformanceMultiplier(analysis.overallScore),
        streakMultiplier: _xpCalculator.calculateStreakMultiplier(streakInfo.currentStreak),
        timeMultiplier: _xpCalculator.calculateTimeMultiplier(),
        difficultyMultiplier: _xpCalculator.calculateDifficultyBonus(textSupport),
      ),
    );
  }

  /// Calcule l'XP dans le niveau actuel
  int _calculateXPInCurrentLevel(int totalXP, int currentLevel) {
    // Calculer l'XP total requis pour atteindre le niveau actuel
    int xpRequiredForCurrentLevel = _calculateTotalXPForLevel(currentLevel - 1);
    
    // L'XP dans le niveau actuel = XP total - XP requis pour les niveaux précédents
    return totalXP - xpRequiredForCurrentLevel;
  }

  /// Calcule l'XP total requis pour atteindre un niveau donné
  int _calculateTotalXPForLevel(int level) {
    if (level <= 0) return 0;
    
    int totalXP = 0;
    
    // Niveaux 1-10: 100 XP chacun
    int level10XP = (level <= 10) ? level * 100 : 1000;
    totalXP += level10XP;
    
    if (level > 10) {
      // Niveaux 11-25: 150 XP chacun
      int level25XP = (level <= 25) ? (level - 10) * 150 : 15 * 150;
      totalXP += level25XP;
      
      if (level > 25) {
        // Niveaux 26-50: 200 XP chacun
        int level50XP = (level <= 50) ? (level - 25) * 200 : 25 * 200;
        totalXP += level50XP;
        
        if (level > 50) {
          // Niveaux 51+: 300 XP chacun
          int levelHighXP = (level - 50) * 300;
          totalXP += levelHighXP;
        }
      }
    }
    
    return totalXP;
  }
}