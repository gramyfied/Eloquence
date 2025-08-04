import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/virelangue_models.dart';

part 'virelangue_reward_system.g.dart';

/// Système de récompenses variables pour les virelangues
/// 
/// 🎲 MÉCANISMES DE RÉCOMPENSES VARIABLES :
/// - Probabilités dynamiques basées sur la performance
/// - Système de "pity timer" pour garantir des récompenses rares
/// - Événements spéciaux avec multiplicateurs temporaires
/// - Combos et streaks pour augmenter les récompenses
/// - Distribution équilibrée des types de gemmes
/// - Adaptation en temps réel selon l'engagement utilisateur
class VirelangueRewardSystem {
  final Logger _logger = Logger();
  
  static const String _rewardHistoryBoxName = 'virelangueRewardHistoryBox';
  static const String _pityTimerBoxName = 'virelanguePityTimerBox';
  
  // Configuration des probabilités de base
  static const Map<GemType, double> _baseProbabilities = {
    GemType.ruby: 0.6,      // 60% - Commun
    GemType.emerald: 0.3,   // 30% - Rare
    GemType.diamond: 0.1,   // 10% - Légendaire
  };
  
  // Système de pity timer (garantie de récompenses rares)
  static const Map<GemType, int> _pityTimerLimits = {
    GemType.emerald: 8,     // Garantie d'émeraude après 8 sessions sans
    GemType.diamond: 20,    // Garantie de diamant après 20 sessions sans
  };
  
  // Multiplicateurs d'événements spéciaux
  static const Map<SpecialEventType, RewardMultiplier> _eventMultipliers = {
    SpecialEventType.weekend: RewardMultiplier(
      gemMultiplier: 2.0,
      probabilityBoost: 0.1,
      description: 'Weekend Magique',
    ),
    SpecialEventType.happyHour: RewardMultiplier(
      gemMultiplier: 1.5,
      probabilityBoost: 0.05,
      description: 'Happy Hour',
    ),
    SpecialEventType.newMonth: RewardMultiplier(
      gemMultiplier: 3.0,
      probabilityBoost: 0.2,
      description: 'Nouveau Mois',
    ),
    SpecialEventType.perfectStreak: RewardMultiplier(
      gemMultiplier: 2.5,
      probabilityBoost: 0.15,
      description: 'Série Parfaite',
    ),
  };

  /// Initialise le système de récompenses
  Future<void> initialize() async {
    try {
      _logger.i('🎁 Initialisation VirelangueRewardSystem...');
      
      // Ouvrir les boîtes Hive pour l'historique et pity timer
      if (!Hive.isBoxOpen(_rewardHistoryBoxName)) {
        await Hive.openBox<RewardHistory>(_rewardHistoryBoxName);
      }
      if (!Hive.isBoxOpen(_pityTimerBoxName)) {
        await Hive.openBox<PityTimerState>(_pityTimerBoxName);
      }
      
      _logger.i('✅ VirelangueRewardSystem initialisé avec succès');
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur initialisation reward system: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Calcule les récompenses de gemmes avec toute la logique variable
  Future<VariableRewardResult> calculateVariableRewards({
    required String userId,
    required double pronunciationScore,
    required VirelangueDifficulty difficulty,
    required int currentCombo,
    required int currentStreak,
    bool isSpecialEvent = false,
  }) async {
    try {
      _logger.i('🎲 Calcul récompenses variables pour: $userId');
      _logger.i('📊 Score: $pronunciationScore, Combo: $currentCombo, Streak: $currentStreak');
      
      // 1. Déterminer les événements spéciaux actifs
      final activeEvents = await _getActiveSpecialEvents(currentStreak);
      
      // 2. Récupérer l'état du pity timer
      final pityState = await _getPityTimerState(userId);
      
      // 3. Calculer les probabilités ajustées
      final adjustedProbabilities = _calculateAdjustedProbabilities(
        baseScore: pronunciationScore,
        difficulty: difficulty,
        combo: currentCombo,
        activeEvents: activeEvents,
        pityState: pityState,
      );
      
      // 4. Déterminer le nombre de gemmes de base
      final baseGemCount = _calculateBaseGemCount(pronunciationScore, difficulty);
      
      // 5. Appliquer les multiplicateurs
      final totalMultiplier = _calculateTotalMultiplier(
        difficulty: difficulty,
        combo: currentCombo,
        activeEvents: activeEvents,
        score: pronunciationScore,
      );
      
      // 6. Générer les récompenses avec variabilité
      final rewardDistribution = await _generateVariableRewards(
        baseCount: baseGemCount,
        multiplier: totalMultiplier,
        probabilities: adjustedProbabilities,
        pityState: pityState,
      );
      
      // 7. Mettre à jour le pity timer
      final updatedPityState = _updatePityTimer(pityState, rewardDistribution);
      await _savePityTimerState(userId, updatedPityState);
      
      // 8. Enregistrer l'historique des récompenses
      await _recordRewardHistory(userId, rewardDistribution, activeEvents);
      
      // 9. Créer le résultat final
      final result = VariableRewardResult(
        gemRewards: rewardDistribution.rewards,
        totalGems: rewardDistribution.totalCount,
        totalValue: rewardDistribution.totalValue,
        activeEvents: activeEvents,
        totalMultiplier: totalMultiplier,
        wasLucky: rewardDistribution.containsRareGems,
        pityTimerTriggered: rewardDistribution.pityTimerUsed,
        bonusReason: _generateBonusReason(activeEvents, currentCombo, pronunciationScore),
      );
      
      _logger.i('✅ Récompenses calculées: ${result.totalGems} gemmes (valeur: ${result.totalValue})');
      if (result.wasLucky) _logger.i('🍀 Récompense chanceuse obtenue !');
      if (result.pityTimerTriggered) _logger.i('⏰ Pity timer déclenché !');
      
      return result;
      
    } catch (e) {
      _logger.e('❌ Erreur calcul récompenses variables: $e');
      rethrow;
    }
  }

  /// Vérifie et retourne les événements spéciaux actifs
  Future<List<SpecialEventType>> _getActiveSpecialEvents(int currentStreak) async {
    final now = DateTime.now();
    final activeEvents = <SpecialEventType>[];
    
    // Weekend (vendredi soir à dimanche soir)
    if (now.weekday >= DateTime.friday && 
        (now.weekday < DateTime.monday || 
         (now.weekday == DateTime.friday && now.hour >= 18))) {
      activeEvents.add(SpecialEventType.weekend);
    }
    
    // Happy Hour (18h-21h)
    if (now.hour >= 18 && now.hour <= 21) {
      activeEvents.add(SpecialEventType.happyHour);
    }
    
    // Nouveau mois (premiers 3 jours)
    if (now.day <= 3) {
      activeEvents.add(SpecialEventType.newMonth);
    }
    
    // Série parfaite (7+ de suite)
    if (currentStreak >= 7) {
      activeEvents.add(SpecialEventType.perfectStreak);
    }
    
    return activeEvents;
  }

  /// Calcule les probabilités ajustées selon le contexte
  Map<GemType, double> _calculateAdjustedProbabilities({
    required double baseScore,
    required VirelangueDifficulty difficulty,
    required int combo,
    required List<SpecialEventType> activeEvents,
    required PityTimerState pityState,
  }) {
    var probabilities = Map<GemType, double>.from(_baseProbabilities);
    
    // Ajustement basé sur la performance
    if (baseScore >= 0.95) {
      // Performance exceptionnelle : boost des gemmes rares
      probabilities[GemType.diamond] = probabilities[GemType.diamond]! * 2.0;
      probabilities[GemType.emerald] = probabilities[GemType.emerald]! * 1.5;
    } else if (baseScore >= 0.85) {
      // Bonne performance : boost modéré
      probabilities[GemType.emerald] = probabilities[GemType.emerald]! * 1.3;
    }
    
    // Ajustement basé sur la difficulté
    final difficultyBoost = difficulty.multiplier - 1.0; // 0.0 à 1.0
    probabilities[GemType.diamond] = probabilities[GemType.diamond]! * (1.0 + difficultyBoost);
    
    // Ajustement basé sur le combo
    if (combo >= 5) {
      final comboBoost = math.min(0.5, combo * 0.05); // Max 50% boost
      probabilities[GemType.diamond] = probabilities[GemType.diamond]! * (1.0 + comboBoost);
      probabilities[GemType.emerald] = probabilities[GemType.emerald]! * (1.0 + comboBoost * 0.5);
    }
    
    // Ajustement pour les événements spéciaux
    for (final event in activeEvents) {
      final multiplier = _eventMultipliers[event]!;
      probabilities[GemType.diamond] = probabilities[GemType.diamond]! + multiplier.probabilityBoost;
      probabilities[GemType.emerald] = probabilities[GemType.emerald]! + (multiplier.probabilityBoost * 0.5);
    }
    
    // Pity timer : force les probabilités si nécessaire
    if (pityState.emeraldTimer >= _pityTimerLimits[GemType.emerald]!) {
      probabilities[GemType.emerald] = 1.0; // Garantie d'émeraude
      probabilities[GemType.ruby] = 0.0;
      probabilities[GemType.diamond] = 0.0;
    } else if (pityState.diamondTimer >= _pityTimerLimits[GemType.diamond]!) {
      probabilities[GemType.diamond] = 1.0; // Garantie de diamant
      probabilities[GemType.ruby] = 0.0;
      probabilities[GemType.emerald] = 0.0;
    }
    
    // Normaliser les probabilités pour qu'elles totalisent 1.0
    return _normalizeProbabilities(probabilities);
  }

  /// Génère les récompenses variables avec distribution aléatoire
  Future<RewardDistribution> _generateVariableRewards({
    required int baseCount,
    required double multiplier,
    required Map<GemType, double> probabilities,
    required PityTimerState pityState,
  }) async {
    final random = math.Random();
    final rewards = <GemReward>[];
    final distribution = <GemType, int>{
      GemType.ruby: 0,
      GemType.emerald: 0,
      GemType.diamond: 0,
    };
    
    bool pityTimerUsed = false;
    final totalGems = math.max(1, (baseCount * multiplier).round());
    
    // Générer chaque gemme individuellement pour plus de variabilité
    for (int i = 0; i < totalGems; i++) {
      final randomValue = random.nextDouble();
      GemType selectedType;
      
      // Vérifier d'abord le pity timer
      if (pityState.diamondTimer >= _pityTimerLimits[GemType.diamond]! && !pityTimerUsed) {
        selectedType = GemType.diamond;
        pityTimerUsed = true;
      } else if (pityState.emeraldTimer >= _pityTimerLimits[GemType.emerald]! && !pityTimerUsed) {
        selectedType = GemType.emerald;
        pityTimerUsed = true;
      } else {
        // Distribution normale basée sur les probabilités
        if (randomValue < probabilities[GemType.diamond]!) {
          selectedType = GemType.diamond;
        } else if (randomValue < probabilities[GemType.diamond]! + probabilities[GemType.emerald]!) {
          selectedType = GemType.emerald;
        } else {
          selectedType = GemType.ruby;
        }
      }
      
      distribution[selectedType] = distribution[selectedType]! + 1;
    }
    
    // Créer les récompenses
    for (final entry in distribution.entries) {
      if (entry.value > 0) {
        rewards.add(GemReward(
          type: entry.key,
          count: entry.value,
          multiplier: multiplier,
          reason: 'Récompense virelangue',
        ));
      }
    }
    
    final totalValue = rewards.fold(0, (sum, reward) => 
        sum + (reward.finalCount * reward.type.baseValue));
    
    final containsRareGems = distribution[GemType.emerald]! > 0 || 
                            distribution[GemType.diamond]! > 0;
    
    return RewardDistribution(
      rewards: rewards,
      totalCount: totalGems,
      totalValue: totalValue,
      containsRareGems: containsRareGems,
      pityTimerUsed: pityTimerUsed,
    );
  }

  /// Calcule le multiplicateur total des récompenses
  double _calculateTotalMultiplier({
    required VirelangueDifficulty difficulty,
    required int combo,
    required List<SpecialEventType> activeEvents,
    required double score,
  }) {
    double multiplier = 1.0;
    
    // Multiplicateur de difficulté
    multiplier *= difficulty.multiplier;
    
    // Multiplicateur de combo
    if (combo > 0) {
      multiplier += (combo * 0.1); // 10% par combo
    }
    
    // Multiplicateur de performance
    if (score >= 0.95) {
      multiplier *= 1.5;
    } else if (score >= 0.85) {
      multiplier *= 1.2;
    }
    
    // Multiplicateurs d'événements spéciaux
    for (final event in activeEvents) {
      multiplier *= _eventMultipliers[event]!.gemMultiplier;
    }
    
    return multiplier;
  }

  /// Calcule le nombre de base de gemmes selon le score et la difficulté
  int _calculateBaseGemCount(double score, VirelangueDifficulty difficulty) {
    int baseCount = 1; // Minimum garanti
    
    // Basé sur le score
    if (score >= 0.95) {
      baseCount = 4;
    } else if (score >= 0.85) {
      baseCount = 3;
    } else if (score >= 0.75) {
      baseCount = 2;
    }
    
    // Bonus pour difficulté élevée
    if (difficulty == VirelangueDifficulty.expert) {
      baseCount += 1;
    } else if (difficulty == VirelangueDifficulty.hard) {
      baseCount += 1;
    }
    
    return math.max(1, baseCount);
  }

  /// Normalise les probabilités pour qu'elles totalisent 1.0
  Map<GemType, double> _normalizeProbabilities(Map<GemType, double> probabilities) {
    final total = probabilities.values.fold(0.0, (sum, prob) => sum + prob);
    if (total <= 0) return _baseProbabilities; // Fallback
    
    return probabilities.map((key, value) => MapEntry(key, value / total));
  }

  /// Met à jour l'état du pity timer
  PityTimerState _updatePityTimer(PityTimerState current, RewardDistribution distribution) {
    int emeraldTimer = current.emeraldTimer + 1;
    int diamondTimer = current.diamondTimer + 1;
    
    // Reset si une gemme rare a été obtenue
    if (distribution.rewards.any((r) => r.type == GemType.emerald)) {
      emeraldTimer = 0;
    }
    if (distribution.rewards.any((r) => r.type == GemType.diamond)) {
      diamondTimer = 0;
    }
    
    return PityTimerState(
      emeraldTimer: emeraldTimer,
      diamondTimer: diamondTimer,
      lastUpdated: DateTime.now(),
    );
  }

  /// Récupère l'état du pity timer pour un utilisateur avec lazy initialization
  Future<PityTimerState> _getPityTimerState(String userId) async {
    try {
      _logger.w('🚨 DIAGNOSTIC: _getPityTimerState appelé pour userId: $userId');
      
      // SOLUTION: Lazy initialization automatique
      if (!Hive.isBoxOpen(_pityTimerBoxName)) {
        _logger.w('🔧 CORRECTION: Box $_pityTimerBoxName fermée - Ouverture automatique (lazy init)');
        await Hive.openBox<PityTimerState>(_pityTimerBoxName);
        _logger.i('✅ CORRECTION: Box $_pityTimerBoxName ouverte automatiquement');
      }
      
      final box = Hive.box<PityTimerState>(_pityTimerBoxName);
      _logger.i('✅ DIAGNOSTIC: Box $_pityTimerBoxName accessible');
      
      return box.get(userId) ?? PityTimerState(
        emeraldTimer: 0,
        diamondTimer: 0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _logger.e('❌ DIAGNOSTIC: Erreur récupération pity timer: $e');
      return PityTimerState(
        emeraldTimer: 0,
        diamondTimer: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Sauvegarde l'état du pity timer avec lazy initialization
  Future<void> _savePityTimerState(String userId, PityTimerState state) async {
    try {
      _logger.w('🚨 DIAGNOSTIC: _savePityTimerState appelé pour userId: $userId');
      
      // SOLUTION: Lazy initialization automatique
      if (!Hive.isBoxOpen(_pityTimerBoxName)) {
        _logger.w('🔧 CORRECTION: Box $_pityTimerBoxName fermée - Ouverture automatique (lazy init)');
        await Hive.openBox<PityTimerState>(_pityTimerBoxName);
        _logger.i('✅ CORRECTION: Box $_pityTimerBoxName ouverte automatiquement');
      }
      
      final box = Hive.box<PityTimerState>(_pityTimerBoxName);
      await box.put(userId, state);
      _logger.d('💾 DIAGNOSTIC: État pity timer sauvegardé avec succès');
    } catch (e) {
      _logger.e('❌ DIAGNOSTIC: Erreur sauvegarde pity timer: $e');
    }
  }

  /// Enregistre l'historique des récompenses avec lazy initialization
  Future<void> _recordRewardHistory(
    String userId,
    RewardDistribution distribution,
    List<SpecialEventType> activeEvents,
  ) async {
    try {
      _logger.w('🚨 DIAGNOSTIC: _recordRewardHistory appelé pour userId: $userId');
      
      // SOLUTION: Lazy initialization automatique
      if (!Hive.isBoxOpen(_rewardHistoryBoxName)) {
        _logger.w('🔧 CORRECTION: Box $_rewardHistoryBoxName fermée - Ouverture automatique (lazy init)');
        await Hive.openBox<RewardHistory>(_rewardHistoryBoxName);
        _logger.i('✅ CORRECTION: Box $_rewardHistoryBoxName ouverte automatiquement');
      }
      
      final box = Hive.box<RewardHistory>(_rewardHistoryBoxName);
      final history = RewardHistory(
        userId: userId,
        timestamp: DateTime.now(),
        rewards: distribution.rewards,
        activeEvents: activeEvents,
        totalValue: distribution.totalValue,
      );
      
      final key = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      await box.put(key, history);
      _logger.d('💾 DIAGNOSTIC: Historique récompenses sauvegardé avec succès');
    } catch (e) {
      _logger.e('❌ DIAGNOSTIC: Erreur enregistrement historique: $e');
    }
  }

  /// Génère une raison pour le bonus
  String _generateBonusReason(
    List<SpecialEventType> activeEvents,
    int combo,
    double score,
  ) {
    final reasons = <String>[];
    
    if (score >= 0.95) {
      reasons.add('Performance Exceptionnelle');
    } else if (score >= 0.85) {
      reasons.add('Excellente Prononciation');
    }
    
    if (combo >= 5) {
      reasons.add('Super Combo x$combo');
    }
    
    for (final event in activeEvents) {
      reasons.add(_eventMultipliers[event]!.description);
    }
    
    return reasons.isEmpty ? 'Bonne Performance' : reasons.join(' + ');
  }

  /// Libère les ressources
  void dispose() {
    _logger.i('🗑️ VirelangueRewardSystem disposé');
  }
}

// ========== CLASSES DE SUPPORT ==========

/// Types d'événements spéciaux
enum SpecialEventType {
  weekend,
  happyHour,
  newMonth,
  perfectStreak,
}

/// Multiplicateur de récompenses pour un événement
class RewardMultiplier {
  final double gemMultiplier;
  final double probabilityBoost;
  final String description;

  const RewardMultiplier({
    required this.gemMultiplier,
    required this.probabilityBoost,
    required this.description,
  });
}

/// Distribution des récompenses générées
class RewardDistribution {
  final List<GemReward> rewards;
  final int totalCount;
  final int totalValue;
  final bool containsRareGems;
  final bool pityTimerUsed;

  const RewardDistribution({
    required this.rewards,
    required this.totalCount,
    required this.totalValue,
    required this.containsRareGems,
    required this.pityTimerUsed,
  });
}

/// Résultat complet du calcul de récompenses variables
class VariableRewardResult {
  final List<GemReward> gemRewards;
  final int totalGems;
  final int totalValue;
  final List<SpecialEventType> activeEvents;
  final double totalMultiplier;
  final bool wasLucky;
  final bool pityTimerTriggered;
  final String bonusReason;

  const VariableRewardResult({
    required this.gemRewards,
    required this.totalGems,
    required this.totalValue,
    required this.activeEvents,
    required this.totalMultiplier,
    required this.wasLucky,
    required this.pityTimerTriggered,
    required this.bonusReason,
  });
}

/// État du pity timer pour garantir les récompenses rares
@HiveType(typeId: 33)
class PityTimerState extends HiveObject {
  @HiveField(0)
  int emeraldTimer;
  
  @HiveField(1)
  int diamondTimer;
  
  @HiveField(2)
  DateTime lastUpdated;

  PityTimerState({
    required this.emeraldTimer,
    required this.diamondTimer,
    required this.lastUpdated,
  });
}

/// Historique des récompenses obtenues
@HiveType(typeId: 34)
class RewardHistory extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  DateTime timestamp;
  
  @HiveField(2)
  List<GemReward> rewards;
  
  @HiveField(3)
  List<SpecialEventType> activeEvents;
  
  @HiveField(4)
  int totalValue;

  RewardHistory({
    required this.userId,
    required this.timestamp,
    required this.rewards,
    required this.activeEvents,
    required this.totalValue,
  });
}

/// Provider pour le système de récompenses
final virelangueRewardSystemProvider = Provider<VirelangueRewardSystem>((ref) {
  return VirelangueRewardSystem();
});