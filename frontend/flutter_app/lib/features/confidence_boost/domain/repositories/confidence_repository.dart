import '../entities/confidence_scenario.dart';
import '../entities/confidence_session.dart';

/// Interface du repository pour les fonctionnalités Confidence Boost
abstract class ConfidenceRepository {
  /// Récupère tous les scénarios disponibles
  Future<List<ConfidenceScenario>> getScenarios();

  /// Récupère un scénario par son ID
  Future<ConfidenceScenario?> getScenarioById(String id);

  /// Récupère un scénario aléatoire
  Future<ConfidenceScenario> getRandomScenario();

  /// Démarre une nouvelle session
  Future<ConfidenceSession> startSession({
    required String userId,
    required ConfidenceScenario scenario,
  });

  /// Met à jour une session existante
  Future<void> updateSession(ConfidenceSession session);

  /// Termine une session et sauvegarde l'analyse
  Future<ConfidenceSession> completeSession({
    required String sessionId,
    required String audioFilePath,
    required int recordingDurationSeconds,
    required ConfidenceAnalysis analysis,
  });

  /// Récupère l'historique des sessions d'un utilisateur
  Future<List<ConfidenceSession>> getUserSessions(String userId);

  /// Récupère les statistiques de progression
  Future<ConfidenceStats> getUserStats(String userId);

  /// Vérifie et attribue les badges
  Future<List<String>> checkAndAwardBadges({
    required String userId,
    required ConfidenceSession session,
  });
}

/// Statistiques de progression pour Confidence Boost
class ConfidenceStats {
  final int totalSessions;
  final int consecutiveDays;
  final double averageConfidenceScore;
  final double averageFluencyScore;
  final double averageClarityScore;
  final double averageEnergyScore;
  final int totalRecordingSeconds;
  final List<String> unlockedBadges;
  final Map<ConfidenceScenarioType, int> scenarioTypeCount;
  final DateTime? lastSessionDate;

  const ConfidenceStats({
    required this.totalSessions,
    required this.consecutiveDays,
    required this.averageConfidenceScore,
    required this.averageFluencyScore,
    required this.averageClarityScore,
    required this.averageEnergyScore,
    required this.totalRecordingSeconds,
    required this.unlockedBadges,
    required this.scenarioTypeCount,
    this.lastSessionDate,
  });

  /// Score de progression global
  double get progressScore {
    final sessionScore = (totalSessions / 100).clamp(0.0, 1.0);
    final streakScore = (consecutiveDays / 30).clamp(0.0, 1.0);
    final performanceScore = (averageConfidenceScore + averageFluencyScore + 
                             averageClarityScore + averageEnergyScore) / 4;
    
    return (sessionScore * 0.3 + streakScore * 0.3 + performanceScore * 0.4);
  }
}