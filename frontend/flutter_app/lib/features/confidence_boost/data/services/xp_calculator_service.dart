import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/gamification_models.dart';

class XPCalculatorService {
  Future<int> calculateXP({
    required ConfidenceAnalysis analysis,
    required ConfidenceScenario scenario,
    required TextSupport textSupport,
    required Duration sessionDuration,
    required UserGamificationProfile userProfile,
  }) async {
    // 1. XP de base selon le score
    int baseXP = calculateBaseXP(analysis.overallScore);

    // 2. Multiplicateur de performance
    double performanceMultiplier = calculatePerformanceMultiplier(analysis.overallScore);

    // 3. Multiplicateur de streak
    double streakMultiplier = calculateStreakMultiplier(userProfile.currentStreak);

    // 4. Multiplicateur temporel
    double timeMultiplier = calculateTimeMultiplier();

    // 5. Bonus de difficulté
    double difficultyBonus = calculateDifficultyBonus(textSupport);

    // 6. Calcul final
    final totalXP = (baseXP * performanceMultiplier * streakMultiplier * timeMultiplier * difficultyBonus).round();

    return totalXP;
  }

  int calculateBaseXP(double score) {
    if (score >= 90) return 150;
    if (score >= 80) return 120;
    if (score >= 70) return 100;
    if (score >= 60) return 80;
    return 50;
  }

  double calculatePerformanceMultiplier(double score) {
    if (score >= 90) return 1.5;
    if (score >= 80) return 1.2;
    if (score >= 70) return 1.1;
    return 1.0;
  }

  double calculateStreakMultiplier(int streak) {
    return 1.0 + (streak * 0.03).clamp(0.0, 0.5); // Max +50%
  }

  double calculateTimeMultiplier() {
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend = now.weekday >= 6;

    double multiplier = 1.0;
    if (isWeekend) multiplier += 0.2; // +20% weekend
    if (hour >= 22 || hour <= 6) multiplier += 0.1; // +10% soirée/nuit

    return multiplier;
  }

  double calculateDifficultyBonus(TextSupport textSupport) {
    switch (textSupport.type) {
      case SupportType.freeImprovisation:
        return 1.3; // +30%
      case SupportType.fillInBlanks:
        return 1.15; // +15%
      case SupportType.guidedStructure:
        return 1.1; // +10%
      case SupportType.keywordChallenge:
        return 1.2; // +20%
      case SupportType.fullText:
        return 1.0; // Pas de bonus
    }
  }
}