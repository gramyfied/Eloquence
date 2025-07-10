import '../entities/confidence_models.dart';
import '../entities/confidence_scenario.dart';

/// Interface du repository pour les fonctionnalités Confidence Boost
abstract class ConfidenceRepository {
  /// Récupère tous les scénarios disponibles
  Future<List<ConfidenceScenario>> getScenarios();

  /// Récupère un scénario par son ID
  Future<ConfidenceScenario?> getScenarioById(String id);

  /// Récupère un scénario aléatoire
  Future<ConfidenceScenario> getRandomScenario();

  /// Lance l'analyse de la performance via le backend
  Future<ConfidenceAnalysis> analyzePerformance({
    required String audioFilePath,
    required ConfidenceScenario scenario,
    required Duration recordingDuration,
  });
}
