import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../domain/entities/exercise.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart';
import '../../../neuroscience/progression/adaptive_progression_system.dart';

// ========== TYPES POUR DIFFICULTÉ CONVERSATION ==========

/// Énumération pour les niveaux de difficulté de conversation
enum ConversationDifficulty {
  debutant,
  intermediaire,
  avance,
  expert
}

/// ✅ DIFFICULTY ADAPTER - SERVICE CENTRALISÉ D'ADAPTATION DYNAMIQUE
/// 
/// 🎯 FONCTIONNALITÉS AVANCÉES :
/// - Adaptation temps réel basée sur les performances utilisateur
/// - Unification des différents systèmes de difficulté (exercices, scénarios, gamification)
/// - Prédiction intelligente du niveau optimal pour chaque utilisateur
/// - Système d'apprentissage adaptatif avec détection de plateaux
/// - Ajustements contextuels selon l'objectif et les contraintes
/// - Fallback automatique avec recommandations personnalisées
class DifficultyAdapter {
  final Logger _logger = Logger();

  // ========== CONSTANTES D'ADAPTATION ==========
  
  /// Seuils de performance pour ajustement automatique
  static const Map<String, double> _performanceThresholds = {
    'plateau_detection': 0.05,     // Écart < 5% = plateau
    'excellent_performance': 0.90, // Score > 90% = excellent
    'good_performance': 0.75,      // Score > 75% = bon
    'struggling_performance': 0.50, // Score < 50% = difficulté
  };

  /// Ajustements de difficulté selon performance
  static const Map<String, double> _difficultyAdjustments = {
    'plateau_increase': 0.15,      // +15% si plateau détecté
    'excellent_increase': 0.10,    // +10% si performance excellente
    'struggling_decrease': -0.20,  // -20% si difficulté trop élevée
    'gradual_increase': 0.05,      // +5% progression graduelle
  };

  /// Mapping unifié des types de difficulté
  static const Map<String, double> _difficultyLevels = {
    'débutant': 0.2,
    'beginner': 0.2,
    'facile': 0.3,
    'easy': 0.3,
    'intermédiaire': 0.5,
    'intermediate': 0.5,
    'moyen': 0.6,
    'medium': 0.6,
    'avancé': 0.8,
    'advanced': 0.8,
    'difficile': 0.9,
    'hard': 0.9,
    'expert': 1.0,
  };

  // ========== ADAPTATION DYNAMIQUE PRINCIPALE ==========

  /// Adapte dynamiquement la difficulté basée sur le profil utilisateur et l'historique
  Future<AdaptedDifficultyResult> adaptDifficultyDynamically({
    required UserPerformanceProfile userProfile,
    required String targetSkill,
    required DifficultyContext context,
    List<PerformanceMetrics>? recentPerformances,
  }) async {
    try {
      _logger.i('🎯 Adaptation dynamique difficulté - Skill: $targetSkill');

      // 1. Analyser le profil utilisateur actuel
      final currentLevel = _analyzeCurrentLevel(userProfile, targetSkill);
      
      // 2. Détecter les patterns de performance
      final performancePattern = _analyzePerformancePattern(recentPerformances ?? []);
      
      // 3. Calculer le niveau optimal avec adaptations contextuelles
      final optimalLevel = _calculateOptimalDifficulty(
        currentLevel: currentLevel,
        performancePattern: performancePattern,
        context: context,
        userProfile: userProfile,
      );

      // 4. Appliquer les contraintes et validations
      final finalLevel = _applyConstraintsAndValidation(
        optimalLevel,
        context,
        userProfile,
      );

      // 5. Générer les recommandations personnalisées
      final recommendations = _generatePersonalizedRecommendations(
        finalLevel,
        performancePattern,
        context,
        userProfile,
      );

      // 6. Créer le résultat avec métadonnées
      final result = AdaptedDifficultyResult(
        numericLevel: finalLevel,
        stringLevel: _numericToStringDifficulty(finalLevel),
        exerciseDifficulty: _numericToExerciseDifficulty(finalLevel),
        conversationDifficulty: _numericToConversationDifficulty(finalLevel),
        adaptationReason: performancePattern.primaryReason,
        recommendations: recommendations,
        confidence: performancePattern.confidence,
        suggestedDuration: _calculateOptimalDuration(finalLevel, context),
        nextReviewInHours: _calculateNextReviewTime(performancePattern),
      );

      _logger.i('✅ Difficulté adaptée: ${finalLevel.toStringAsFixed(2)} (${result.stringLevel})');
      return result;

    } catch (e, stackTrace) {
      _logger.e('❌ Erreur adaptation difficulté: $e', error: e, stackTrace: stackTrace);
      return _createFallbackResult(context);
    }
  }

  // ========== ANALYSE DU NIVEAU ACTUEL ==========

  double _analyzeCurrentLevel(UserPerformanceProfile userProfile, String targetSkill) {
    // Obtenir le niveau de base pour cette compétence
    final baseLevel = userProfile.skillLevels[targetSkill] ?? 0.5;
    
    // Ajuster selon l'expérience globale
    final experienceMultiplier = _calculateExperienceMultiplier(userProfile);
    
    // Prendre en compte la confiance globale
    final confidenceLevel = userProfile.overallConfidence / 100.0;
    
    // Calculer le niveau pondéré
    final weightedLevel = (baseLevel * 0.6) + 
                         (experienceMultiplier * 0.3) + 
                         (confidenceLevel * 0.1);
    
    return weightedLevel.clamp(0.1, 1.0);
  }

  double _calculateExperienceMultiplier(UserPerformanceProfile userProfile) {
    final totalSessions = userProfile.totalSessions;
    if (totalSessions < 5) return 0.3;      // Débutant
    if (totalSessions < 15) return 0.5;     // Intermédiaire
    if (totalSessions < 30) return 0.7;     // Avancé
    return 0.9;                             // Expert
  }

  // ========== ANALYSE PATTERN DE PERFORMANCE ==========

  PerformancePattern _analyzePerformancePattern(List<PerformanceMetrics> performances) {
    if (performances.isEmpty) {
      return PerformancePattern(
        trend: PerformanceTrend.stable,
        variance: 0.0,
        primaryReason: 'Données insuffisantes',
        confidence: 0.5,
        suggestedAdjustment: 0.0,
      );
    }

    // Calculer la tendance (amélioration, dégradation, stable)
    final trend = _calculatePerformanceTrend(performances);
    
    // Calculer la variance (consistance)
    final variance = _calculatePerformanceVariance(performances);
    
    // Détecter les plateaux
    final isAtPlateau = _detectPlateau(performances);
    
    // Détecter les difficultés
    final isStruggling = _detectStruggling(performances);

    String primaryReason;
    double suggestedAdjustment;
    double confidence;

    if (isAtPlateau) {
      primaryReason = 'Plateau détecté - Augmentation recommandée';
      suggestedAdjustment = _difficultyAdjustments['plateau_increase']!;
      confidence = 0.8;
    } else if (isStruggling) {
      primaryReason = 'Difficulté excessive - Réduction recommandée';
      suggestedAdjustment = _difficultyAdjustments['struggling_decrease']!;
      confidence = 0.9;
    } else if (trend == PerformanceTrend.improving) {
      final avgScore = performances.map((p) => p.overallScore).reduce((a, b) => a + b) / performances.length;
      if (avgScore > _performanceThresholds['excellent_performance']!) {
        primaryReason = 'Progression excellente - Augmentation modérée';
        suggestedAdjustment = _difficultyAdjustments['excellent_increase']!;
        confidence = 0.7;
      } else {
        primaryReason = 'Progression graduelle - Légère augmentation';
        suggestedAdjustment = _difficultyAdjustments['gradual_increase']!;
        confidence = 0.6;
      }
    } else {
      primaryReason = 'Performance stable - Maintien niveau actuel';
      suggestedAdjustment = 0.0;
      confidence = 0.5;
    }

    return PerformancePattern(
      trend: trend,
      variance: variance,
      primaryReason: primaryReason,
      confidence: confidence,
      suggestedAdjustment: suggestedAdjustment,
    );
  }

  PerformanceTrend _calculatePerformanceTrend(List<PerformanceMetrics> performances) {
    if (performances.length < 3) return PerformanceTrend.stable;

    final scores = performances.map((p) => p.overallScore).toList();
    final firstHalf = scores.sublist(0, scores.length ~/ 2);
    final secondHalf = scores.sublist(scores.length ~/ 2);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final difference = secondAvg - firstAvg;

    if (difference > 0.1) return PerformanceTrend.improving;
    if (difference < -0.1) return PerformanceTrend.declining;
    return PerformanceTrend.stable;
  }

  double _calculatePerformanceVariance(List<PerformanceMetrics> performances) {
    if (performances.isEmpty) return 0.0;

    final scores = performances.map((p) => p.overallScore).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((score) => math.pow(score - mean, 2)).reduce((a, b) => a + b) / scores.length;
    
    return variance;
  }

  bool _detectPlateau(List<PerformanceMetrics> performances) {
    if (performances.length < 5) return false;

    final recentScores = performances.takeLast(5).map((p) => p.overallScore).toList();
    final variance = _calculateVarianceFromList(recentScores);
    
    return variance < _performanceThresholds['plateau_detection']!;
  }

  bool _detectStruggling(List<PerformanceMetrics> performances) {
    if (performances.length < 3) return false;

    final recentScores = performances.takeLast(3).map((p) => p.overallScore).toList();
    final avgScore = recentScores.reduce((a, b) => a + b) / recentScores.length;
    
    return avgScore < _performanceThresholds['struggling_performance']!;
  }

  double _calculateVarianceFromList(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    return scores.map((score) => math.pow(score - mean, 2)).reduce((a, b) => a + b) / scores.length;
  }

  // ========== CALCUL NIVEAU OPTIMAL ==========

  double _calculateOptimalDifficulty({
    required double currentLevel,
    required PerformancePattern performancePattern,
    required DifficultyContext context,
    required UserPerformanceProfile userProfile,
  }) {
    // Niveau de base avec ajustement pattern
    double adjustedLevel = currentLevel + performancePattern.suggestedAdjustment;

    // Ajustement contextuel selon l'objectif
    switch (context.objective) {
      case LearningObjective.rapidProgress:
        adjustedLevel += 0.1; // Plus agressif
        break;
      case LearningObjective.confidence:
        adjustedLevel -= 0.05; // Plus conservateur
        break;
      case LearningObjective.mastery:
        // Maintenir niveau actuel jusqu'à maîtrise complète
        if (performancePattern.trend != PerformanceTrend.improving) {
          adjustedLevel = currentLevel;
        }
        break;
      case LearningObjective.exploration:
        adjustedLevel += 0.05; // Légèrement plus challengeant
        break;
    }

    // Ajustement selon contraintes de temps
    switch (context.timeConstraint) {
      case TimeConstraint.high:
        adjustedLevel = math.min(adjustedLevel, currentLevel + 0.05); // Progression prudente
        break;
      case TimeConstraint.low:
        adjustedLevel += 0.05; // Plus de défis possibles
        break;
      case TimeConstraint.medium:
        // Pas d'ajustement spécial
        break;
    }

    // Ajustement selon fatigue perçue
    if (context.fatigueLevel > 0.7) {
      adjustedLevel -= 0.1; // Réduire si fatigué
    }

    return adjustedLevel.clamp(0.1, 1.0);
  }

  // ========== CONTRAINTES ET VALIDATION ==========

  double _applyConstraintsAndValidation(
    double proposedLevel,
    DifficultyContext context,
    UserPerformanceProfile userProfile,
  ) {
    double finalLevel = proposedLevel;

    // Contrainte: éviter sauts trop importants
    final currentAverage = userProfile.skillLevels.values.isEmpty 
        ? 0.5 
        : userProfile.skillLevels.values.reduce((a, b) => a + b) / userProfile.skillLevels.length;
    
    final maxJump = context.objective == LearningObjective.rapidProgress ? 0.2 : 0.15;
    final maxIncrease = currentAverage + maxJump;
    final maxDecrease = math.max(0.1, currentAverage - 0.2);
    
    finalLevel = finalLevel.clamp(maxDecrease, maxIncrease);

    // Contrainte: niveau minimum selon expérience
    final minLevelByExperience = userProfile.totalSessions < 5 ? 0.1 : 0.2;
    finalLevel = math.max(finalLevel, minLevelByExperience);

    // Contrainte: niveau maximum selon confiance
    final maxLevelByConfidence = userProfile.overallConfidence / 100.0 + 0.1;
    finalLevel = math.min(finalLevel, maxLevelByConfidence);

    return finalLevel.clamp(0.1, 1.0);
  }

  // ========== GÉNÉRATION RECOMMANDATIONS ==========

  List<String> _generatePersonalizedRecommendations(
    double finalLevel,
    PerformancePattern pattern,
    DifficultyContext context,
    UserPerformanceProfile userProfile,
  ) {
    final recommendations = <String>[];

    // Recommandations basées sur le pattern
    switch (pattern.trend) {
      case PerformanceTrend.improving:
        recommendations.add('📈 Excellente progression ! Continuez à ce rythme.');
        if (finalLevel > 0.7) {
          recommendations.add('🎯 Vous êtes prêt pour des défis plus avancés.');
        }
        break;
      case PerformanceTrend.declining:
        recommendations.add('🔄 Prenez le temps de consolider vos acquis.');
        recommendations.add('💪 Concentrez-vous sur les fondamentaux.');
        break;
      case PerformanceTrend.stable:
        if (pattern.variance < 0.01) {
          recommendations.add('🚀 Temps de sortir de votre zone de confort !');
        } else {
          recommendations.add('⚖️ Travaillez sur la consistance de vos performances.');
        }
        break;
    }

    // Recommandations contextuelles
    if (context.fatigueLevel > 0.7) {
      recommendations.add('😴 Vous semblez fatigué - privilégiez des sessions plus courtes.');
    }

    if (context.timeConstraint == TimeConstraint.high) {
      recommendations.add('⏰ Sessions courtes mais fréquentes recommandées.');
    }

    // Recommandations basées sur expérience
    if (userProfile.totalSessions < 5) {
      recommendations.add('🌱 Explorez différents types d\'exercices pour découvrir vos préférences.');
    } else if (userProfile.totalSessions > 30) {
      recommendations.add('🎓 Votre expérience vous permet d\'aborder des défis complexes.');
    }

    return recommendations;
  }

  // ========== CALCULS AUXILIAIRES ==========

  Duration _calculateOptimalDuration(double difficultyLevel, DifficultyContext context) {
    // Durée de base selon difficulté
    int baseDuration = ((difficultyLevel * 10) + 5).round(); // 5-15 minutes

    // Ajustement selon contraintes
    switch (context.timeConstraint) {
      case TimeConstraint.high:
        baseDuration = math.min(baseDuration, 8); // Max 8 minutes
        break;
      case TimeConstraint.low:
        baseDuration += 5; // +5 minutes
        break;
      case TimeConstraint.medium:
        // Pas d'ajustement
        break;
    }

    // Ajustement selon fatigue
    if (context.fatigueLevel > 0.7) {
      baseDuration = (baseDuration * 0.7).round(); // -30%
    }

    return Duration(minutes: baseDuration.clamp(3, 20));
  }

  int _calculateNextReviewTime(PerformancePattern pattern) {
    switch (pattern.trend) {
      case PerformanceTrend.improving:
        return 48; // Revoir dans 2 jours
      case PerformanceTrend.declining:
        return 24; // Revoir dans 1 jour
      case PerformanceTrend.stable:
        return pattern.variance < 0.01 ? 72 : 48; // 3 jours si plateau, 2 jours sinon
    }
  }

  // ========== CONVERSIONS TYPES DE DIFFICULTÉ ==========

  String _numericToStringDifficulty(double level) {
    if (level <= 0.25) return 'débutant';
    if (level <= 0.4) return 'facile';
    if (level <= 0.65) return 'intermédiaire';
    if (level <= 0.85) return 'avancé';
    return 'expert';
  }

  ExerciseDifficulty _numericToExerciseDifficulty(double level) {
    if (level <= 0.35) return ExerciseDifficulty.beginner;
    if (level <= 0.65) return ExerciseDifficulty.intermediate;
    if (level <= 0.85) return ExerciseDifficulty.advanced;
    return ExerciseDifficulty.expert;
  }

  ConversationDifficulty _numericToConversationDifficulty(double level) {
    if (level <= 0.35) return ConversationDifficulty.debutant;
    if (level <= 0.65) return ConversationDifficulty.intermediaire;
    if (level <= 0.85) return ConversationDifficulty.avance;
    return ConversationDifficulty.expert;
  }

  /// Convertit une difficulté string vers numérique
  static double stringToNumericDifficulty(String difficulty) {
    return _difficultyLevels[difficulty.toLowerCase()] ?? 0.5;
  }

  // ========== FALLBACK ==========

  AdaptedDifficultyResult _createFallbackResult(DifficultyContext context) {
    final fallbackLevel = 0.5; // Niveau moyen par défaut

    return AdaptedDifficultyResult(
      numericLevel: fallbackLevel,
      stringLevel: 'intermédiaire',
      exerciseDifficulty: ExerciseDifficulty.intermediate,
      conversationDifficulty: ConversationDifficulty.intermediaire,
      adaptationReason: 'Adaptation automatique avec paramètres par défaut',
      recommendations: [
        '⚠️ Utilisation des paramètres par défaut',
        '🔄 Plus de données nécessaires pour une adaptation précise',
      ],
      confidence: 0.3,
      suggestedDuration: const Duration(minutes: 8),
      nextReviewInHours: 48,
    );
  }

  // ========== UTILITAIRES PUBLICS ==========

  /// Évalue si un utilisateur est prêt pour une difficulté spécifique
  Future<bool> isUserReadyForDifficulty({
    required UserPerformanceProfile userProfile,
    required double targetDifficulty,
    required String skill,
  }) async {
    final currentLevel = userProfile.skillLevels[skill] ?? 0.5;
    final difference = targetDifficulty - currentLevel;
    
    // Prêt si écart < 20% et confiance suffisante
    return difference <= 0.2 && userProfile.overallConfidence >= 60;
  }

  /// Obtient le prochain niveau recommandé pour un skill
  Future<double> getNextRecommendedLevel({
    required UserPerformanceProfile userProfile,
    required String skill,
    required DifficultyContext context,
  }) async {
    final result = await adaptDifficultyDynamically(
      userProfile: userProfile,
      targetSkill: skill,
      context: context,
    );
    
    return result.numericLevel;
  }
}

// ========== MODÈLES DE DONNÉES ==========

/// Résultat de l'adaptation de difficulté
class AdaptedDifficultyResult {
  final double numericLevel;
  final String stringLevel;
  final ExerciseDifficulty exerciseDifficulty;
  final ConversationDifficulty conversationDifficulty;
  final String adaptationReason;
  final List<String> recommendations;
  final double confidence;
  final Duration suggestedDuration;
  final int nextReviewInHours;

  const AdaptedDifficultyResult({
    required this.numericLevel,
    required this.stringLevel,
    required this.exerciseDifficulty,
    required this.conversationDifficulty,
    required this.adaptationReason,
    required this.recommendations,
    required this.confidence,
    required this.suggestedDuration,
    required this.nextReviewInHours,
  });
}

/// Profil de performance utilisateur
class UserPerformanceProfile {
  final String userId;
  final Map<String, double> skillLevels;
  final int totalSessions;
  final double overallConfidence;
  final DateTime lastSessionDate;
  final LearningRhythm preferredRhythm;

  const UserPerformanceProfile({
    required this.userId,
    required this.skillLevels,
    required this.totalSessions,
    required this.overallConfidence,
    required this.lastSessionDate,
    this.preferredRhythm = LearningRhythm.moderate,
  });
}

/// Contexte de difficulté
class DifficultyContext {
  final LearningObjective objective;
  final TimeConstraint timeConstraint;
  final double fatigueLevel; // 0.0-1.0
  final String? specificGoal;
  final Map<String, dynamic> additionalParams;

  const DifficultyContext({
    required this.objective,
    required this.timeConstraint,
    this.fatigueLevel = 0.0,
    this.specificGoal,
    this.additionalParams = const {},
  });
}

/// Métriques de performance
class PerformanceMetrics {
  final double overallScore;
  final Map<String, double> skillScores;
  final DateTime timestamp;
  final Duration sessionDuration;
  final String exerciseType;

  const PerformanceMetrics({
    required this.overallScore,
    required this.skillScores,
    required this.timestamp,
    required this.sessionDuration,
    required this.exerciseType,
  });
}

/// Pattern de performance détecté
class PerformancePattern {
  final PerformanceTrend trend;
  final double variance;
  final String primaryReason;
  final double confidence;
  final double suggestedAdjustment;

  const PerformancePattern({
    required this.trend,
    required this.variance,
    required this.primaryReason,
    required this.confidence,
    required this.suggestedAdjustment,
  });
}

// ========== ENUMS ==========

enum PerformanceTrend { improving, declining, stable }

enum LearningObjective { rapidProgress, confidence, mastery, exploration }

enum TimeConstraint { low, medium, high }

/// Extension pour faciliter les opérations sur les listes
extension ListExtensions<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}