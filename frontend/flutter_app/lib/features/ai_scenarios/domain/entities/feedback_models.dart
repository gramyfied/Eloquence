import 'package:flutter/material.dart';
import 'scenario_models.dart';

/// Résultats d'analyse de performance
class PerformanceAnalysis {
  final int overallScore; // 0-100
  final Map<String, double> strengths; // Nom -> Score (0.0-1.0)
  final Map<String, double> improvements; // Nom -> Score (0.0-1.0)
  final List<String> keyInsights;
  final double confidenceLevel;
  final double clarityScore;
  final double paceScore;
  final double engagementScore;

  const PerformanceAnalysis({
    required this.overallScore,
    required this.strengths,
    required this.improvements,
    required this.keyInsights,
    required this.confidenceLevel,
    required this.clarityScore,
    required this.paceScore,
    required this.engagementScore,
  });

  String get scoreMessage {
    if (overallScore >= 90) return "Excellent!";
    if (overallScore >= 80) return "Good Job!";
    if (overallScore >= 70) return "Well Done!";
    if (overallScore >= 60) return "Keep Going!";
    return "Practice More!";
  }

  Color get scoreColor {
    if (overallScore >= 80) return const Color(0xFF10B981); // Success green
    if (overallScore >= 60) return const Color(0xFFF59E0B); // Warning orange
    return const Color(0xFFEF4444); // Error red
  }
}

/// Feedback personnalisé du coach IA
class CoachFeedback {
  final String message;
  final String tone; // encouraging, constructive, challenging
  final List<String> specificTips;
  final String motivationalQuote;

  const CoachFeedback({
    required this.message,
    required this.tone,
    required this.specificTips,
    required this.motivationalQuote,
  });

  static CoachFeedback generateForScore(int score, ScenarioType scenarioType) {
    if (score >= 85) {
      return CoachFeedback(
        message: "Outstanding performance! Your confidence and clarity really shone through.",
        tone: "encouraging",
        specificTips: [
          "Maintain this excellent pace",
          "Your engagement level was perfect",
          "Consider challenging yourself with harder scenarios"
        ],
        motivationalQuote: "Excellence is not a skill, it's an attitude.",
      );
    } else if (score >= 70) {
      return CoachFeedback(
        message: "Great job! You're showing real improvement in your communication skills.",
        tone: "constructive",
        specificTips: [
          "Focus on maintaining consistent pace",
          "Work on reducing filler words",
          "Practice more complex scenarios"
        ],
        motivationalQuote: "Progress, not perfection, is the goal.",
      );
    } else {
      return CoachFeedback(
        message: "Good effort! Every practice session brings you closer to mastery.",
        tone: "encouraging",
        specificTips: [
          "Take your time to organize thoughts",
          "Practice breathing exercises",
          "Start with easier scenarios"
        ],
        motivationalQuote: "Every expert was once a beginner.",
      );
    }
  }
}

/// Recommandations pour les prochaines étapes
class NextStepsRecommendation {
  final List<String> immediateActions;
  final List<String> weeklyGoals;
  final ScenarioType? suggestedNextScenario;
  final int recommendedDuration;
  final double recommendedDifficulty;

  const NextStepsRecommendation({
    required this.immediateActions,
    required this.weeklyGoals,
    this.suggestedNextScenario,
    required this.recommendedDuration,
    required this.recommendedDifficulty,
  });

  static NextStepsRecommendation generateForSession(ExerciseSession session, PerformanceAnalysis analysis) {
    final config = session.configuration;
    final score = analysis.overallScore;
    
    List<String> immediateActions = [];
    List<String> weeklyGoals = [];
    
    if (score >= 80) {
      immediateActions = [
        "Try a more challenging scenario",
        "Increase session duration to ${config.durationMinutes + 5} minutes",
        "Practice with different AI personalities"
      ];
      weeklyGoals = [
        "Complete 3 advanced scenarios",
        "Maintain 80+ score consistently",
        "Explore new topic areas"
      ];
    } else if (score >= 60) {
      immediateActions = [
        "Focus on identified improvement areas",
        "Practice breathing exercises",
        "Review session recordings"
      ];
      weeklyGoals = [
        "Practice 4-5 times this week",
        "Improve score by 10 points",
        "Work on specific weaknesses"
      ];
    } else {
      immediateActions = [
        "Start with easier scenarios",
        "Practice basic speaking exercises",
        "Focus on confidence building"
      ];
      weeklyGoals = [
        "Complete daily 5-minute sessions",
        "Build speaking confidence",
        "Master current difficulty level"
      ];
    }

    return NextStepsRecommendation(
      immediateActions: immediateActions,
      weeklyGoals: weeklyGoals,
      suggestedNextScenario: _suggestNextScenario(config.type, score),
      recommendedDuration: _suggestDuration(config.durationMinutes, score),
      recommendedDifficulty: _suggestDifficulty(config.difficulty, score),
    );
  }

  static ScenarioType? _suggestNextScenario(ScenarioType current, int score) {
    if (score < 60) return current; // Stay with same type
    
    // Suggest progression path
    switch (current) {
      case ScenarioType.networking:
        return ScenarioType.presentation;
      case ScenarioType.presentation:
        return ScenarioType.jobInterview;
      case ScenarioType.jobInterview:
        return ScenarioType.salesPitch;
      case ScenarioType.salesPitch:
        return ScenarioType.networking; // Cycle back
    }
  }

  static int _suggestDuration(int current, int score) {
    if (score >= 80 && current < 15) return current + 5;
    if (score < 60 && current > 5) return current - 5;
    return current;
  }

  static double _suggestDifficulty(double current, int score) {
    if (score >= 85) return (current + 0.2).clamp(0.0, 1.0);
    if (score < 60) return (current - 0.2).clamp(0.0, 1.0);
    return current;
  }
}

/// Résultats complets de la session
class SessionResults {
  final ExerciseSession session;
  final PerformanceAnalysis analysis;
  final CoachFeedback coachFeedback;
  final NextStepsRecommendation nextSteps;
  final DateTime completedAt;

  const SessionResults({
    required this.session,
    required this.analysis,
    required this.coachFeedback,
    required this.nextSteps,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': session.id,
      'overallScore': analysis.overallScore,
      'strengths': analysis.strengths,
      'improvements': analysis.improvements,
      'coachMessage': coachFeedback.message,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  static SessionResults generateFromSession(ExerciseSession session) {
    final analysis = _generateAnalysis(session);
    final coachFeedback = CoachFeedback.generateForScore(
      analysis.overallScore,
      session.configuration.type,
    );
    final nextSteps = NextStepsRecommendation.generateForSession(session, analysis);

    return SessionResults(
      session: session,
      analysis: analysis,
      coachFeedback: coachFeedback,
      nextSteps: nextSteps,
      completedAt: DateTime.now(),
    );
  }

  static PerformanceAnalysis _generateAnalysis(ExerciseSession session) {
    final metrics = session.metrics;
    final config = session.configuration;
    
    // Calcul du score basé sur les métriques
    int baseScore = 70;
    
    // Ajustements basés sur les métriques
    if (metrics.averageWpm > 120 && metrics.averageWpm < 180) baseScore += 10;
    if (metrics.confidenceScore > 0.7) baseScore += 10;
    if (session.helpUsedCount <= 1) baseScore += 5;
    if (metrics.pauseCount < 3) baseScore += 5;
    
    // Ajustements basés sur la difficulté
    baseScore += (config.difficulty * 10).round();
    
    final overallScore = baseScore.clamp(0, 100);
    
    return PerformanceAnalysis(
      overallScore: overallScore,
      strengths: {
        "Clarity": 0.8,
        "Pace": metrics.averageWpm > 120 ? 0.9 : 0.6,
        "Confidence": metrics.confidenceScore,
      },
      improvements: {
        "Intonation": 0.6,
        "Pauses": metrics.pauseCount > 3 ? 0.4 : 0.8,
      },
      keyInsights: [
        "Strong opening and closing",
        "Good use of examples",
        "Maintained good eye contact"
      ],
      confidenceLevel: metrics.confidenceScore,
      clarityScore: 0.8,
      paceScore: metrics.averageWpm > 120 ? 0.9 : 0.6,
      engagementScore: 0.75,
    );
  }
}

/// Données pour les graphiques et visualisations
class VisualizationData {
  final List<double> progressOverTime;
  final Map<String, double> skillRadarChart;
  final List<ChartDataPoint> improvementTrend;

  const VisualizationData({
    required this.progressOverTime,
    required this.skillRadarChart,
    required this.improvementTrend,
  });
}

class ChartDataPoint {
  final DateTime date;
  final double value;
  final String label;

  const ChartDataPoint({
    required this.date,
    required this.value,
    required this.label,
  });
}
