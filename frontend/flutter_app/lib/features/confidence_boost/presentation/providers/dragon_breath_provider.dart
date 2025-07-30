import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../main.dart'; // Import pour le completer
import '../../domain/entities/dragon_breath_models.dart';

/// Provider pour l'exercice Souffle de Dragon
final dragonBreathProvider = StateNotifierProvider<DragonBreathNotifier, BreathingExerciseState>(
  (ref) => DragonBreathNotifier(),
);

/// Notifier pour gérer l'état de l'exercice de respiration Dragon
class DragonBreathNotifier extends StateNotifier<BreathingExerciseState> {
  Timer? _exerciseTimer;
  Timer? _phaseTimer;
  DateTime? _sessionStartTime;
  DateTime? _phaseStartTime;
  List<double> _cycleTimings = [];
  bool _isDisposed = false;
  
  // Constantes pour les clés Hive
  static const String _progressBoxName = 'dragon_progress';
  static const String _sessionsBoxName = 'dragon_sessions';
  static const String _achievementsBoxName = 'dragon_achievements';

  DragonBreathNotifier() : super(BreathingExerciseState.initial());

  @override
  void dispose() {
    _isDisposed = true;
    _exerciseTimer?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }

  /// Initialise le provider, y compris les boxes Hive et les données utilisateur.
  Future<void> initialize() async {
    // ---- VERROU DE SÉCURITÉ ----
    // Attendre que l'initialisation de Hive dans main.dart soit terminée.
    await hiveInitializationCompleter.future;
    // -------------------------
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _initializeHive();
      await _loadUserProgress();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Erreur fatale: ${e.toString()}', isLoading: false);
    }
  }

  /// Initialise les boxes Hive de manière sécurisée
  Future<void> _initializeHive() async {
    try {
      if (!Hive.isBoxOpen(_progressBoxName)) await Hive.openBox<DragonProgress>(_progressBoxName);
      if (!Hive.isBoxOpen(_sessionsBoxName)) await Hive.openBox<BreathingSession>(_sessionsBoxName);
      if (!Hive.isBoxOpen(_achievementsBoxName)) await Hive.openBox<DragonAchievement>(_achievementsBoxName);
    } catch (e) {
      print('❌ Erreur initialisation Hive Dragon: $e');
      // Propage l'erreur pour la gérer dans l'état global
      throw Exception('Impossible d\'ouvrir les bases de données locales.');
    }
  }

  /// Charge la progression de l'utilisateur
  Future<void> _loadUserProgress() async {
    const userId = 'user_eloquence'; // ID utilisateur fixe pour l'instant
    if (!Hive.isBoxOpen(_progressBoxName)) {
      throw HiveError('La box de progression n\'est pas ouverte.');
    }
    final progressBox = Hive.box<DragonProgress>(_progressBoxName);
    DragonProgress? progress = progressBox.get(userId);

    if (progress == null) {
      progress = DragonProgress(userId: userId);
      await progressBox.put(progress.userId, progress);
    }

    state = state.copyWith(userProgress: progress, isLoading: false);
  }

  /// Démarre un nouvel exercice
  Future<void> startExercise({BreathingExercise? customExercise}) async {
    if (state.userProgress == null) {
      state = state.copyWith(error: "Impossible de démarrer, les données utilisateur ne sont pas chargées.");
      return;
    }
    try {
      final exercise = customExercise ?? BreathingExercise.defaultExercise();
      final sessionId = 'dragon_${DateTime.now().millisecondsSinceEpoch}';
      
      _sessionStartTime = DateTime.now();
      _cycleTimings.clear();
      
      state = state.copyWith(
        sessionId: sessionId,
        exercise: exercise,
        currentPhase: BreathingPhase.preparation,
        currentCycle: 0,
        remainingSeconds: 3, // 3 secondes de préparation
        isActive: true,
        isPaused: false,
        error: null,
        clearError: true,
        motivationalMessages: ['🐉 Préparez-vous à libérer votre puissance intérieure !'],
      );
      
      _startPreparationPhase();
    } catch (e) {
      print('❌ Erreur démarrage exercice Dragon: $e');
      state = state.copyWith(
        error: 'Erreur lors du démarrage: $e',
        isLoading: false,
      );
    }
  }

  /// Phase de préparation
  void _startPreparationPhase() {
    _phaseStartTime = DateTime.now();
    
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      final remaining = state.remainingSeconds - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        _startBreathingCycle();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  /// Démarre un cycle de respiration
  void _startBreathingCycle() {
    if (state.currentCycle >= state.exercise.totalCycles) {
      _completeExercise();
      return;
    }
    
    state = state.copyWith(
      currentCycle: state.currentCycle + 1,
      motivationalMessages: _getPhaseMessage(BreathingPhase.inspiration),
    );
    
    _startInspirationPhase();
  }

  /// Phase d'inspiration
  void _startInspirationPhase() {
    _phaseStartTime = DateTime.now();
    
    state = state.copyWith(
      currentPhase: BreathingPhase.inspiration,
      remainingSeconds: state.exercise.inspirationDuration,
    );
    
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      final remaining = state.remainingSeconds - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        _recordPhaseComplete(BreathingPhase.inspiration);
        
        if (state.exercise.retentionDuration > 0) {
          _startRetentionPhase();
        } else {
          _startExpirationPhase();
        }
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  /// Phase de rétention (optionnelle)
  void _startRetentionPhase() {
    _phaseStartTime = DateTime.now();
    
    state = state.copyWith(
      currentPhase: BreathingPhase.retention,
      remainingSeconds: state.exercise.retentionDuration,
      motivationalMessages: _getPhaseMessage(BreathingPhase.retention),
    );
    
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      final remaining = state.remainingSeconds - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        _recordPhaseComplete(BreathingPhase.retention);
        _startExpirationPhase();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  /// Phase d'expiration
  void _startExpirationPhase() {
    _phaseStartTime = DateTime.now();
    
    state = state.copyWith(
      currentPhase: BreathingPhase.expiration,
      remainingSeconds: state.exercise.expirationDuration,
      motivationalMessages: _getPhaseMessage(BreathingPhase.expiration),
    );
    
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      final remaining = state.remainingSeconds - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        _recordPhaseComplete(BreathingPhase.expiration);
        _startPausePhase();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  /// Phase de pause entre cycles
  void _startPausePhase() {
    _phaseStartTime = DateTime.now();
    
    state = state.copyWith(
      currentPhase: BreathingPhase.pause,
      remainingSeconds: state.exercise.pauseDuration,
      motivationalMessages: _getPhaseMessage(BreathingPhase.pause),
    );
    
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      final remaining = state.remainingSeconds - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        _recordPhaseComplete(BreathingPhase.pause);
        _startBreathingCycle(); // Cycle suivant
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  /// Enregistre la complétion d'une phase
  void _recordPhaseComplete(BreathingPhase phase) {
    if (_phaseStartTime == null) return;
    
    final actualDuration = DateTime.now().difference(_phaseStartTime!).inSeconds;
    _cycleTimings.add(actualDuration.toDouble());
    
    // Mise à jour des messages motivants
    final messages = List<String>.from(state.motivationalMessages);
    messages.add(_getCompletionMessage(phase, actualDuration));
    
    if (messages.length > 3) {
      messages.removeAt(0); // Garder seulement les 3 derniers
    }
    
    state = state.copyWith(motivationalMessages: messages);
  }

  /// Termine l'exercice
  Future<void> _completeExercise() async {
    if (_sessionStartTime == null) return;
    
    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    
    // Calculer les métriques
    final metrics = _calculateMetrics(sessionDuration);
    
    // Créer la session
    final session = BreathingSession(
      id: state.sessionId,
      userId: state.userProgress!.userId,
      exerciseId: state.exercise.id,
      startTime: _sessionStartTime!,
    );
    
    session.complete(metrics);
    
    // Vérifier les achievements débloqués
    final newAchievements = await _checkAchievements(session);
    
    // Créer une nouvelle session avec les achievements débloqués
    final completedSession = BreathingSession(
      id: session.id,
      userId: session.userId,
      exerciseId: session.exerciseId,
      startTime: session.startTime,
      unlockedAchievements: newAchievements,
    );
    
    // Compléter la session avec les métriques
    completedSession.complete(session.metrics!);
    
    // Mettre à jour la progression avec la session terminée
    final updatedProgress = DragonProgress(
      userId: state.userProgress!.userId,
      currentLevel: state.userProgress!.currentLevel,
      totalSessions: state.userProgress!.totalSessions,
      totalXP: state.userProgress!.totalXP,
      currentStreak: state.userProgress!.currentStreak,
      longestStreak: state.userProgress!.longestStreak,
      averageQuality: state.userProgress!.averageQuality,
      bestQuality: state.userProgress!.bestQuality,
      totalPracticeTime: state.userProgress!.totalPracticeTime,
      lastSessionDate: state.userProgress!.lastSessionDate,
      achievements: List<DragonAchievement>.from(state.userProgress!.achievements),
      statistics: Map<String, dynamic>.from(state.userProgress!.statistics),
    );
    
    // Mettre à jour avec la session (ceci calcule l'XP automatiquement)
    updatedProgress.updateWithSession(completedSession);
    
    // Sauvegarder la session et la progression
    await _saveSession(completedSession);
    await _saveProgress(updatedProgress);
    
    // Afficher les XP gagnés dans les logs pour debug
    print('🎯 XP gagnés: ${completedSession.xpGained}');
    print('🎯 XP total: ${updatedProgress.totalXP}');
    print('🎯 Achievements débloqués: ${completedSession.unlockedAchievements.length}');
    
    state = state.copyWith(
      currentPhase: BreathingPhase.completed,
      isActive: false,
      currentMetrics: metrics,
      userProgress: updatedProgress,
      motivationalMessages: [completedSession.motivationalMessage],
    );
    
    _exerciseTimer?.cancel();
    _phaseTimer?.cancel();
  }

  /// Calcule les métriques de la session
  BreathingMetrics _calculateMetrics(Duration sessionDuration) {
    final expectedCycleDuration = state.exercise.cycleDuration.toDouble();
    final completedCycles = state.currentCycle;
    
    // Calcul de la consistance (régularité)
    double consistency = 1.0;
    if (_cycleTimings.isNotEmpty) {
      final avgTiming = _cycleTimings.reduce((a, b) => a + b) / _cycleTimings.length;
      final deviations = _cycleTimings.map((t) => (t - avgTiming).abs()).toList();
      final avgDeviation = deviations.reduce((a, b) => a + b) / deviations.length;
      consistency = math.max(0.0, 1.0 - (avgDeviation / expectedCycleDuration));
    }
    
    // Score de contrôle basé sur la completion
    final controlScore = completedCycles / state.exercise.totalCycles;
    
    // Score de qualité global
    final qualityScore = (consistency * 0.4 + controlScore * 0.6);
    
    return BreathingMetrics(
      averageBreathDuration: _cycleTimings.isNotEmpty 
          ? _cycleTimings.reduce((a, b) => a + b) / _cycleTimings.length 
          : 0.0,
      consistency: consistency,
      controlScore: controlScore,
      completedCycles: completedCycles,
      totalCycles: state.exercise.totalCycles,
      actualDuration: sessionDuration,
      expectedDuration: Duration(seconds: state.exercise.totalDuration),
      qualityScore: qualityScore,
      cycleDeviations: _cycleTimings.map((t) => (t - expectedCycleDuration).abs()).toList(),
    );
  }

  /// Vérifie les achievements débloqués
  Future<List<DragonAchievement>> _checkAchievements(BreathingSession session) async {
    final newAchievements = <DragonAchievement>[];
    final allAchievements = DragonAchievement.getAllAchievements();
    
    for (final achievement in allAchievements) {
      if (_shouldUnlockAchievement(achievement, session)) {
        // Créer une nouvelle instance au lieu de modifier l'objet statique
        final unlockedAchievement = DragonAchievement(
          id: achievement.id,
          name: achievement.name,
          description: achievement.description,
          emoji: achievement.emoji,
          requiredLevel: achievement.requiredLevel,
          requiredSessions: achievement.requiredSessions,
          requiredQuality: achievement.requiredQuality,
          xpReward: achievement.xpReward,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          category: achievement.category,
          currentValue: achievement.currentValue,
          targetValue: achievement.targetValue,
        );
        newAchievements.add(unlockedAchievement);
      }
    }
    
    return newAchievements;
  }

  /// Détermine si un achievement doit être débloqué
  bool _shouldUnlockAchievement(DragonAchievement achievement, BreathingSession session) {
    if (achievement.isUnlocked || state.userProgress == null) return false;
    
    switch (achievement.id) {
      case 'first_flame':
        return state.userProgress!.totalSessions == 0; // Première session
      case 'breath_master':
        return session.metrics != null && session.metrics!.qualityScore >= 0.9;
      case 'precision_master':
        return session.metrics != null && session.metrics!.consistency >= 0.9;
      case 'royal_series':
        return state.userProgress!.currentStreak >= 7;
      case 'legendary_dragon':
        return state.userProgress!.totalSessions >= 30;
      default:
        return false;
    }
  }

  /// Sauvegarde la session
  Future<void> _saveSession(BreathingSession session) async {
    try {
      final sessionsBox = Hive.box<BreathingSession>(_sessionsBoxName);
      await sessionsBox.put(session.id, session);
    } catch (e) {
      print('❌ Erreur sauvegarde session Dragon: $e');
    }
  }

  /// Sauvegarde la progression
  Future<void> _saveProgress(DragonProgress progress) async {
    try {
      final progressBox = Hive.box<DragonProgress>(_progressBoxName);
      await progressBox.put(progress.userId, progress);
    } catch (e) {
      print('❌ Erreur sauvegarde progression Dragon: $e');
    }
  }

  /// Arrête l'exercice
  void stopExercise() {
    _exerciseTimer?.cancel();
    _phaseTimer?.cancel();
    
    state = state.copyWith(
      isActive: false,
      currentPhase: BreathingPhase.completed,
      motivationalMessages: ['🐉 Exercice interrompu. Chaque dragon doit parfois reprendre son souffle !'],
    );
  }

  /// Met en pause/reprend l'exercice
  void togglePause() {
    if (state.isPaused) {
      _resumeExercise();
    } else {
      _pauseExercise();
    }
  }

  void _pauseExercise() {
    _phaseTimer?.cancel();
    state = state.copyWith(
      isPaused: true,
      motivationalMessages: [...state.motivationalMessages, '⏸️ Pause - Ton dragon récupère ses forces'],
    );
  }

  void _resumeExercise() {
    state = state.copyWith(
      isPaused: false,
      motivationalMessages: [...state.motivationalMessages, '▶️ Reprise - Libère de nouveau ta puissance !'],
    );
    
    // Reprendre la phase actuelle
    switch (state.currentPhase) {
      case BreathingPhase.inspiration:
        _startInspirationPhase();
        break;
      case BreathingPhase.retention:
        _startRetentionPhase();
        break;
      case BreathingPhase.expiration:
        _startExpirationPhase();
        break;
      case BreathingPhase.pause:
        _startPausePhase();
        break;
      default:
        break;
    }
  }

  /// Obtient les messages motivants pour chaque phase
  List<String> _getPhaseMessage(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inspiration:
        return ['🌬️ Aspire l\'énergie du dragon...'];
      case BreathingPhase.retention:
        return ['💎 Concentre ta puissance intérieure'];
      case BreathingPhase.expiration:
        return ['🔥 Libère les flammes de ton dragon !'];
      case BreathingPhase.pause:
        return ['⚡ Prépare la prochaine vague d\'énergie'];
      default:
        return ['🐉 Ta puissance grandit...'];
    }
  }

  /// Messages de completion pour chaque phase
  String _getCompletionMessage(BreathingPhase phase, int actualSeconds) {
    final messages = {
      BreathingPhase.inspiration: ['Inspiration parfaite !', 'Énergie absorbée !', 'Souffle majestueux !'],
      BreathingPhase.retention: ['Contrôle absolu !', 'Puissance maîtrisée !', 'Concentration de maître !'],
      BreathingPhase.expiration: ['Flammes libérées !', 'Puissance projetée !', 'Dragon en action !'],
      BreathingPhase.pause: ['Prêt pour la suite !', 'Énergie rechargée !', 'Dragon en éveil !'],
    };
    
    final phaseMessages = messages[phase] ?? ['Excellent !'];
    final randomMessage = phaseMessages[math.Random().nextInt(phaseMessages.length)];
    
    return '✨ $randomMessage';
  }

  /// Modifie la configuration de l'exercice
  void updateExerciseConfig({
    int? inspirationDuration,
    int? expirationDuration,
    int? retentionDuration,
    int? pauseDuration,
    int? totalCycles,
  }) {
    if (state.isActive) return; // Ne pas modifier pendant l'exercice
    
    final updatedExercise = BreathingExercise(
      id: state.exercise.id,
      name: state.exercise.name,
      description: state.exercise.description,
      inspirationDuration: inspirationDuration ?? state.exercise.inspirationDuration,
      expirationDuration: expirationDuration ?? state.exercise.expirationDuration,
      retentionDuration: retentionDuration ?? state.exercise.retentionDuration,
      pauseDuration: pauseDuration ?? state.exercise.pauseDuration,
      totalCycles: totalCycles ?? state.exercise.totalCycles,
      requiredLevel: state.exercise.requiredLevel,
      benefits: state.exercise.benefits,
      isCustom: true,
    );
    
    state = state.copyWith(exercise: updatedExercise);
  }

  /// Recharge la progression depuis le stockage
  Future<void> refreshProgress() async {
    await _loadUserProgress();
  }

  /// Remet à zéro l'exercice
  void resetExercise() {
    _exerciseTimer?.cancel();
    _phaseTimer?.cancel();
    
    state = BreathingExerciseState.initial(
      exercise: state.exercise,
    ).copyWith(
      userProgress: state.userProgress,
      isLoading: false, // On ne recharge pas
    );
  }
}