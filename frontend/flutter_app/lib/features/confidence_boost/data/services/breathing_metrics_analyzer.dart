import 'dart:math' as math;
import '../../domain/entities/dragon_breath_models.dart';

/// Service d'analyse avancée des métriques de respiration
class BreathingMetricsAnalyzer {
  // Historique des cycles pour l'analyse
  final List<BreathingCycleData> _cycleHistory = [];
  
  // Paramètres d'analyse
  static const double _idealConsistencyThreshold = 0.85;
  static const double _goodConsistencyThreshold = 0.70;
  static const int _minCyclesForAnalysis = 3;

  /// Ajoute un nouveau cycle pour l'analyse
  void addCycle(BreathingCycleData cycle) {
    _cycleHistory.add(cycle);
    
    // Limiter l'historique pour éviter une surcharge mémoire
    if (_cycleHistory.length > 20) {
      _cycleHistory.removeAt(0);
    }
  }

  /// Calcule les métriques complètes de la session
  BreathingMetrics calculateSessionMetrics({
    required BreathingExercise exercise,
    required int completedCycles,
    required Duration actualDuration,
  }) {
    if (_cycleHistory.isEmpty) {
      return _createDefaultMetrics(exercise, completedCycles, actualDuration);
    }

    final averageBreathDuration = _calculateAverageBreathDuration();
    final consistency = _calculateConsistency();
    final controlScore = _calculateControlScore(exercise);
    final cycleDeviations = _calculateCycleDeviations(exercise);
    final qualityScore = _calculateOverallQuality(consistency, controlScore, completedCycles / exercise.totalCycles);

    return BreathingMetrics(
      averageBreathDuration: averageBreathDuration,
      consistency: consistency,
      controlScore: controlScore,
      completedCycles: completedCycles,
      totalCycles: exercise.totalCycles,
      actualDuration: actualDuration,
      expectedDuration: Duration(seconds: exercise.totalDuration),
      qualityScore: qualityScore,
      cycleDeviations: cycleDeviations,
    );
  }

  /// Analyse en temps réel du cycle actuel
  RealTimeBreathingAnalysis analyzeCurrentCycle(
    BreathingPhase currentPhase,
    int elapsedSeconds,
    int expectedDuration,
  ) {
    final deviation = _calculatePhaseDeviation(elapsedSeconds, expectedDuration);
    final quality = _calculatePhaseQuality(deviation);
    final recommendations = _generateRecommendations(currentPhase, deviation, quality);

    return RealTimeBreathingAnalysis(
      phase: currentPhase,
      deviation: deviation,
      quality: quality,
      recommendations: recommendations,
      isOnTrack: deviation.abs() < 0.2,
    );
  }

  /// Calcule la durée moyenne des respirations
  double _calculateAverageBreathDuration() {
    if (_cycleHistory.isEmpty) return 0.0;
    
    final totalDuration = _cycleHistory
        .map((cycle) => cycle.totalDuration)
        .reduce((a, b) => a + b);
    
    return totalDuration / _cycleHistory.length;
  }

  /// Calcule la régularité de la respiration (0.0 à 1.0)
  double _calculateConsistency() {
    if (_cycleHistory.length < _minCyclesForAnalysis) return 0.0;

    // Calculer l'écart type des durées de cycles
    final durations = _cycleHistory.map((cycle) => cycle.totalDuration).toList();
    final mean = durations.reduce((a, b) => a + b) / durations.length;
    final variance = durations
        .map((duration) => math.pow(duration - mean, 2))
        .reduce((a, b) => a + b) / durations.length;
    final standardDeviation = math.sqrt(variance);

    // Convertir en score de consistance (moins d'écart = meilleure consistance)
    final coefficientOfVariation = standardDeviation / mean;
    final consistency = math.max(0.0, 1.0 - (coefficientOfVariation * 2));
    
    return consistency.clamp(0.0, 1.0);
  }

  /// Calcule le score de contrôle basé sur l'adhérence aux timings prévus
  double _calculateControlScore(BreathingExercise exercise) {
    if (_cycleHistory.isEmpty) return 0.0;

    double totalControlScore = 0.0;
    
    for (final cycle in _cycleHistory) {
      final inspirationControl = _calculatePhaseControl(
        cycle.inspirationDuration, 
        exercise.inspirationDuration.toDouble()
      );
      final retentionControl = exercise.retentionDuration > 0 
          ? _calculatePhaseControl(cycle.retentionDuration, exercise.retentionDuration.toDouble())
          : 1.0;
      final expirationControl = _calculatePhaseControl(
        cycle.expirationDuration, 
        exercise.expirationDuration.toDouble()
      );
      
      final cycleControl = (inspirationControl + retentionControl + expirationControl) / 3;
      totalControlScore += cycleControl;
    }

    return totalControlScore / _cycleHistory.length;
  }

  /// Calcule le contrôle pour une phase spécifique
  double _calculatePhaseControl(double actual, double expected) {
    if (expected == 0) return 1.0;
    
    final deviation = (actual - expected).abs() / expected;
    return math.max(0.0, 1.0 - deviation).clamp(0.0, 1.0);
  }

  /// Calcule les déviations par cycle
  List<double> _calculateCycleDeviations(BreathingExercise exercise) {
    final expectedCycleDuration = exercise.cycleDuration.toDouble();
    
    return _cycleHistory.map((cycle) {
      final deviation = (cycle.totalDuration - expectedCycleDuration).abs() / expectedCycleDuration;
      return deviation;
    }).toList();
  }

  /// Calcule la qualité globale de la session
  double _calculateOverallQuality(double consistency, double control, double completion) {
    // Pondération : 40% consistance, 40% contrôle, 20% completion
    final quality = (consistency * 0.4) + (control * 0.4) + (completion * 0.2);
    return quality.clamp(0.0, 1.0);
  }

  /// Calcule la déviation d'une phase
  double _calculatePhaseDeviation(int actual, int expected) {
    if (expected == 0) return 0.0;
    return (actual - expected) / expected.toDouble();
  }

  /// Calcule la qualité d'une phase
  double _calculatePhaseQuality(double deviation) {
    return math.max(0.0, 1.0 - deviation.abs()).clamp(0.0, 1.0);
  }

  /// Génère des recommandations en temps réel
  List<String> _generateRecommendations(
    BreathingPhase phase, 
    double deviation, 
    double quality
  ) {
    final recommendations = <String>[];

    if (quality < 0.5) {
      switch (phase) {
        case BreathingPhase.inspiration:
          if (deviation > 0.2) {
            recommendations.add("Inspirez plus lentement et régulièrement");
          } else if (deviation < -0.2) {
            recommendations.add("Prenez le temps d'inspirer complètement");
          }
          break;
        case BreathingPhase.retention:
          recommendations.add("Maintenez le souffle de façon détendue");
          break;
        case BreathingPhase.expiration:
          if (deviation > 0.2) {
            recommendations.add("Expirez plus progressivement");
          } else if (deviation < -0.2) {
            recommendations.add("Prolongez votre expiration");
          }
          break;
        default:
          break;
      }
    } else if (quality > 0.8) {
      recommendations.add("Excellent contrôle ! Continuez ainsi");
    }

    return recommendations;
  }

  /// Crée des métriques par défaut pour les sessions sans données
  BreathingMetrics _createDefaultMetrics(
    BreathingExercise exercise,
    int completedCycles,
    Duration actualDuration,
  ) {
    return BreathingMetrics(
      averageBreathDuration: exercise.cycleDuration.toDouble(),
      consistency: 0.0,
      controlScore: 0.0,
      completedCycles: completedCycles,
      totalCycles: exercise.totalCycles,
      actualDuration: actualDuration,
      expectedDuration: Duration(seconds: exercise.totalDuration),
      qualityScore: 0.0,
      cycleDeviations: [],
    );
  }

  /// Remet à zéro l'analyseur pour une nouvelle session
  void reset() {
    _cycleHistory.clear();
  }

  /// Statistiques avancées pour le debug et l'analyse
  BreathingAnalysisStats getAdvancedStats() {
    if (_cycleHistory.isEmpty) {
      return BreathingAnalysisStats.empty();
    }

    final durations = _cycleHistory.map((c) => c.totalDuration).toList();
    final inspirationDurations = _cycleHistory.map((c) => c.inspirationDuration).toList();
    final expirationDurations = _cycleHistory.map((c) => c.expirationDuration).toList();

    return BreathingAnalysisStats(
      cycleCount: _cycleHistory.length,
      averageCycleDuration: durations.reduce((a, b) => a + b) / durations.length,
      minCycleDuration: durations.reduce(math.min),
      maxCycleDuration: durations.reduce(math.max),
      averageInspirationDuration: inspirationDurations.reduce((a, b) => a + b) / inspirationDurations.length,
      averageExpirationDuration: expirationDurations.reduce((a, b) => a + b) / expirationDurations.length,
      consistencyTrend: _calculateConsistencyTrend(),
    );
  }

  /// Calcule la tendance de consistance (amélioration/dégradation)
  double _calculateConsistencyTrend() {
    if (_cycleHistory.length < 4) return 0.0;

    final firstHalf = _cycleHistory.take(_cycleHistory.length ~/ 2).toList();
    final secondHalf = _cycleHistory.skip(_cycleHistory.length ~/ 2).toList();

    final firstHalfConsistency = _calculateConsistencyForCycles(firstHalf);
    final secondHalfConsistency = _calculateConsistencyForCycles(secondHalf);

    return secondHalfConsistency - firstHalfConsistency;
  }

  /// Calcule la consistance pour un sous-ensemble de cycles
  double _calculateConsistencyForCycles(List<BreathingCycleData> cycles) {
    if (cycles.length < 2) return 0.0;

    final durations = cycles.map((cycle) => cycle.totalDuration).toList();
    final mean = durations.reduce((a, b) => a + b) / durations.length;
    final variance = durations
        .map((duration) => math.pow(duration - mean, 2))
        .reduce((a, b) => a + b) / durations.length;
    final standardDeviation = math.sqrt(variance);
    final coefficientOfVariation = standardDeviation / mean;
    
    return math.max(0.0, 1.0 - (coefficientOfVariation * 2)).clamp(0.0, 1.0);
  }
}

/// Données d'un cycle de respiration pour l'analyse
class BreathingCycleData {
  final double inspirationDuration;
  final double retentionDuration;
  final double expirationDuration;
  final double pauseDuration;
  final DateTime timestamp;

  const BreathingCycleData({
    required this.inspirationDuration,
    required this.retentionDuration,
    required this.expirationDuration,
    required this.pauseDuration,
    required this.timestamp,
  });

  double get totalDuration => 
      inspirationDuration + retentionDuration + expirationDuration + pauseDuration;
}

/// Analyse en temps réel d'un cycle de respiration
class RealTimeBreathingAnalysis {
  final BreathingPhase phase;
  final double deviation;
  final double quality;
  final List<String> recommendations;
  final bool isOnTrack;

  const RealTimeBreathingAnalysis({
    required this.phase,
    required this.deviation,
    required this.quality,
    required this.recommendations,
    required this.isOnTrack,
  });
}

/// Statistiques avancées d'analyse de respiration
class BreathingAnalysisStats {
  final int cycleCount;
  final double averageCycleDuration;
  final double minCycleDuration;
  final double maxCycleDuration;
  final double averageInspirationDuration;
  final double averageExpirationDuration;
  final double consistencyTrend;

  const BreathingAnalysisStats({
    required this.cycleCount,
    required this.averageCycleDuration,
    required this.minCycleDuration,
    required this.maxCycleDuration,
    required this.averageInspirationDuration,
    required this.averageExpirationDuration,
    required this.consistencyTrend,
  });

  factory BreathingAnalysisStats.empty() {
    return const BreathingAnalysisStats(
      cycleCount: 0,
      averageCycleDuration: 0.0,
      minCycleDuration: 0.0,
      maxCycleDuration: 0.0,
      averageInspirationDuration: 0.0,
      averageExpirationDuration: 0.0,
      consistencyTrend: 0.0,
    );
  }

  String get consistencyTrendDescription {
    if (consistencyTrend > 0.1) return "En amélioration 📈";
    if (consistencyTrend < -0.1) return "En baisse 📉";
    return "Stable ➡️";
  }
}