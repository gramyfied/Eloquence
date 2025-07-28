import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart'; // Nécessaire pour describeEnum
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/virelangue_models.dart';
import '../providers/mistral_api_service_provider.dart'; // Pour l'injection du provider Mistral
import 'mistral_api_service.dart'; // Pour le type IMistralApiService
import 'universal_audio_exercise_service.dart'; // Pour UniversalAudioExerciseService
import 'virelangue_reward_system.dart';


/// Service principal pour la gestion des virelangues et de la gamification
/// 
/// 🎯 RESPONSABILITÉS DU SERVICE :
/// - Gestion complète du cycle de vie des sessions de virelangues
/// - Coordination entre le système audio et le système de récompenses
/// - Persistance des données utilisateur (progression, collections, stats)
/// - Calcul et distribution des récompenses variables
/// - Gestion des combos, streaks et multiplicateurs
/// - Interface avec l'IA Mistral pour la génération personnalisée
/// - Synchronisation avec les classements et leaderboards
class VirelangueService {
  final Logger _logger;
  final VirelangueRewardSystem _rewardSystem;
  final IMistralApiService _mistralApiService;
  
  static const String _virelangueBoxName = 'virelangueBox';
  static const String _gemCollectionBoxName = 'gemCollectionBox';
  static const String _virelangueStatsBoxName = 'virelangueStatsBox';
  static const String _userProgressBoxName = 'virelangueUserProgressBox';
  
  // Base de données de virelangues prédéfinis
  static const List<Map<String, dynamic>> _predefinedVirelangues = [
    {
      'text': 'Les chaussettes de l\'archiduchesse sont-elles sèches, archi-sèches ?',
      'difficulty': 'medium',
      'theme': 'classique',
      'language': 'fr',
      'description': 'Classique français avec consonnes complexes',
    },
    {
      'text': 'Un chasseur sachant chasser doit savoir chasser sans son chien',
      'difficulty': 'easy',
      'theme': 'chasseur',
      'language': 'fr',
      'description': 'Virelangue traditionnel sur la chasse',
    },
    {
      'text': 'Ces six saucissons-ci sont si secs qu\'on ne sait si c\'en sont',
      'difficulty': 'hard',
      'theme': 'saucisson',
      'language': 'fr',
      'description': 'Allitération en S particulièrement difficile',
    },
    {
      'text': 'Trois tortues trottaient sur trois toits très étroits',
      'difficulty': 'medium',
      'theme': 'tortues',
      'language': 'fr',
      'description': 'Répétition de T et R',
    },
    {
      'text': 'Papa pend peu, papa paie peu, papa part peu',
      'difficulty': 'easy',
      'theme': 'papa',
      'language': 'fr',
      'description': 'Simple répétition de P',
    },
    {
      'text': 'Seize chaises séchaient dans seize sachets sales',
      'difficulty': 'hard',
      'theme': 'chaises',
      'language': 'fr',
      'description': 'Complexe mélange de S et CH',
    },
    {
      'text': 'Si six scies scient six cyprès, six cent scies scient six cent cyprès',
      'difficulty': 'expert',
      'theme': 'scies',
      'language': 'fr',
      'description': 'Expert - mélange S, C et nombres',
    },
    {
      'text': 'Cinq chiens chassent six chats',
      'difficulty': 'easy',
      'theme': 'animaux',
      'language': 'fr',
      'description': 'Simple pour débuter avec CH',
    },
    {
      'text': 'Didon dîna, dit-on, du dos d\'un dodu dindon',
      'difficulty': 'medium',
      'theme': 'dindon',
      'language': 'fr',
      'description': 'Allitération en D complexe',
    },
    {
      'text': 'Tonton, ton thé t\'a-t-il ôté ta toux ?',
      'difficulty': 'hard',
      'theme': 'toux',
      'language': 'fr',
      'description': 'Mélange T et TH difficile',
    },
  ];

  VirelangueService(this._mistralApiService) 
      : _logger = Logger(),
        _rewardSystem = VirelangueRewardSystem();

  /// Initialise le service des virelangues
  Future<void> initialize() async {
    try {
      _logger.i('🎯 Initialisation VirelangueService...');
      
      // Initialiser le système de récompenses
      await _rewardSystem.initialize();
      
      // Ouvrir les boîtes Hive
      if (!Hive.isBoxOpen(_virelangueBoxName)) {
        await Hive.openBox<Virelangue>(_virelangueBoxName);
      }
      if (!Hive.isBoxOpen(_gemCollectionBoxName)) {
        await Hive.openBox<GemCollection>(_gemCollectionBoxName);
      }
      if (!Hive.isBoxOpen(_virelangueStatsBoxName)) {
        await Hive.openBox<VirelangueStats>(_virelangueStatsBoxName);
      }
      if (!Hive.isBoxOpen(_userProgressBoxName)) {
        await Hive.openBox<VirelangueUserProgress>(_userProgressBoxName);
      }
      
      // Charger les virelangues prédéfinis si nécessaire
      await _loadPredefinedVirelangues();
      
      _logger.i('✅ VirelangueService initialisé avec succès');
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur initialisation VirelangueService: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Démarre une nouvelle session de virelangue avec la roulette
  Future<VirelangueExerciseState> startVirelangueSession({
    required String userId,
    VirelangueDifficulty? preferredDifficulty,
    String? customTheme,
    bool useAI = false,
  }) async {
    try {
      _logger.i('🎲 Démarrage session virelangue pour: $userId');
      
      // 1. Récupérer la progression utilisateur
      final userProgress = await getUserProgress(userId);
      
      // 2. Récupérer la collection de gemmes
      final userGems = await getGemCollection(userId);
      
      // 3. Récupérer tous les virelangues disponibles
      final availableVirelangues = await getAllVirelangues();
      
      // 4. Sélectionner un virelangue adapté
      final selectedVirelangue = await _selectOptimalVirelangue(
        userId: userId,
        preferredDifficulty: preferredDifficulty,
        customTheme: customTheme,
        useAI: useAI,
        userProgress: userProgress,
      );
      
      // 5. Créer l'état initial de l'exercice
      final exerciseState = VirelangueExerciseState(
        sessionId: _generateSessionId(),
        userId: userId,
        availableVirelangues: availableVirelangues,
        currentVirelangue: selectedVirelangue,
        userGems: userGems,
        startTime: DateTime.now(),
        currentAttempt: 0,
        maxAttempts: 3,
        isActive: true,
        currentCombo: userProgress.currentCombo,
        currentStreak: userProgress.currentStreak,
        pronunciationResults: [],
        collectedGems: [],
        sessionScore: 0.0,
      );
      
      _logger.i('🎯 Session créée: ${exerciseState.sessionId}');
      _logger.i('📝 Virelangue sélectionné: "${selectedVirelangue.text}"');
      _logger.i('🔥 Combo actuel: ${userProgress.currentCombo}, Streak: ${userProgress.currentStreak}');
      
      return exerciseState;
      
    } catch (e) {
      _logger.e('❌ Erreur démarrage session: $e');
      rethrow;
    }
  }

  /// Traite le résultat d'une tentative de prononciation
  Future<VirelangueExerciseState> processPronunciationAttempt({
    required VirelangueExerciseState currentState,
    required Map<String, dynamic> audioAnalysisResult,
  }) async {
    try {
      _logger.i('🎤 Traitement tentative prononciation...');
      
      // 1. Analyser les résultats audio
      final pronunciationResult = VirelanguePronunciationResult.fromAudioAnalysis(
        audioAnalysisResult,
        attemptNumber: currentState.currentAttempt + 1,
      );
      
      // 2. Mettre à jour l'état de l'exercice
      final updatedResults = List<VirelanguePronunciationResult>.from(currentState.pronunciationResults)
        ..add(pronunciationResult);
      
      final newAttempt = currentState.currentAttempt + 1;
      final isComplete = newAttempt >= currentState.maxAttempts || pronunciationResult.overallScore >= 0.8;
      
      // 3. Calculer le score de session
      final sessionScore = _calculateSessionScore(updatedResults);
      
      // 4. Calculer les récompenses si la session est terminée
      List<GemReward> sessionRewards = [];
      if (isComplete) {
        final rewardResult = await _rewardSystem.calculateVariableRewards(
          userId: currentState.userId,
          pronunciationScore: sessionScore,
          difficulty: currentState.currentVirelangue?.difficulty ?? VirelangueDifficulty.medium,
          currentCombo: currentState.currentCombo,
          currentStreak: currentState.currentStreak,
        );
        
        sessionRewards = rewardResult.gemRewards;
        
        // Mettre à jour la collection de gemmes
        await _updateGemCollection(currentState.userId, sessionRewards);
        
        // Mettre à jour les statistiques utilisateur
        await _updateUserProgress(currentState.userId, sessionScore, sessionRewards);
      }
      
      // 5. Créer l'état mis à jour
      final updatedState = currentState.copyWith(
        currentAttempt: newAttempt,
        pronunciationResults: updatedResults,
        collectedGems: sessionRewards,
        sessionScore: sessionScore,
        isActive: !isComplete,
        endTime: isComplete ? DateTime.now() : null,
      );
      
      _logger.i('📊 Tentative ${newAttempt}/${currentState.maxAttempts} - Score: ${pronunciationResult.overallScore.toStringAsFixed(2)}');
      if (isComplete) {
        _logger.i('🏁 Session terminée - Score final: ${sessionScore.toStringAsFixed(2)}');
        _logger.i('💎 Récompenses obtenues: ${sessionRewards.length} gemmes');
      }
      
      return updatedState;
      
    } catch (e) {
      _logger.e('❌ Erreur traitement prononciation: $e');
      rethrow;
    }
  }

  /// Sélectionne le virelangue optimal selon l'utilisateur et le contexte (méthode publique)
  Future<Virelangue> selectOptimalVirelangue({
    required String userId,
    VirelangueDifficulty? preferredDifficulty,
    String? customTheme,
    bool useAI = false,
    required VirelangueUserProgress userProgress,
  }) async {
    return await _selectOptimalVirelangue(
      userId: userId,
      preferredDifficulty: preferredDifficulty,
      customTheme: customTheme,
      useAI: useAI,
      userProgress: userProgress,
    );
  }

  /// Sélectionne le virelangue optimal selon l'utilisateur et le contexte (méthode privée)
  Future<Virelangue> _selectOptimalVirelangue({
    required String userId,
    VirelangueDifficulty? preferredDifficulty,
    String? customTheme,
    bool useAI = false,
    required VirelangueUserProgress userProgress,
  }) async {
    // Si l'IA est demandée, générer un virelangue personnalisé
    if (useAI) {
      return await _generateAIVirelangue(userId, preferredDifficulty, customTheme);
    }
    
    // Sinon, sélectionner depuis la base de données
    final availableVirelangues = await getAllVirelangues();
    
    // Filtrer par difficulté préférée
    var filteredVirelangues = availableVirelangues;
    if (preferredDifficulty != null) {
      filteredVirelangues = filteredVirelangues
          .where((v) => v.difficulty == preferredDifficulty)
          .toList();
    }
    
    // Filtrer par thème si spécifié
    if (customTheme != null && customTheme.isNotEmpty) {
      filteredVirelangues = filteredVirelangues
          .where((v) => v.theme.toLowerCase().contains(customTheme.toLowerCase()))
          .toList();
    }
    
    // Éviter les répétitions récentes
    final recentlyUsed = userProgress.recentVirelangueIds;
    filteredVirelangues = filteredVirelangues
        .where((v) => !recentlyUsed.contains(v.id))
        .toList();
    
    // Si aucun virelangue disponible, reset et reprendre tous
    if (filteredVirelangues.isEmpty) {
      filteredVirelangues = availableVirelangues;
    }
    
    // Vérification finale de sécurité
    if (filteredVirelangues.isEmpty) {
      _logger.w('⚠️ Aucun virelangue disponible, création d\'un fallback');
      return _createFallbackVirelangue();
    }
    
    // Sélection aléatoire pondérée (préférer difficulté adaptée)
    return _selectWeightedRandom(filteredVirelangues, userProgress);
  }

  /// Sélection aléatoire pondérée basée sur la progression utilisateur
  Virelangue _selectWeightedRandom(
    List<Virelangue> virelangues,
    VirelangueUserProgress userProgress,
  ) {
    // Vérification de sécurité
    if (virelangues.isEmpty) {
      _logger.w('⚠️ Liste de virelangues vide, retour au fallback par défaut');
      return _createFallbackVirelangue();
    }
    
    final random = math.Random();
    
    // Calculer les poids selon la difficulté et le niveau utilisateur
    final weights = virelangues.map((v) {
      double weight = 1.0;
      
      // Favoriser les difficultés appropriées au niveau
      final levelGap = (v.difficulty.index - userProgress.currentLevel.index).abs();
      weight = math.max(0.1, 1.0 - (levelGap * 0.3));
      
      // Bonus pour variété (difficultés peu jouées récemment)
      if (!userProgress.recentDifficulties.contains(v.difficulty)) {
        weight *= 1.5;
      }
      
      return weight;
    }).toList();
    
    // Sélection pondérée
    final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
    final randomValue = random.nextDouble() * totalWeight;
    
    double currentSum = 0.0;
    for (int i = 0; i < virelangues.length; i++) {
      currentSum += weights[i];
      if (randomValue <= currentSum) {
        return virelangues[i];
      }
    }
    
    // Fallback sécurisé
    return virelangues[random.nextInt(virelangues.length)];
  }

  /// Génère un virelangue personnalisé avec l'IA Mistral
  Future<Virelangue> _generateAIVirelangue(
    String userId,
    VirelangueDifficulty? difficulty,
    String? theme,
  ) async {
    try {
      _logger.i('🤖 Génération IA virelangue personnalisé...');
      
      final difficultyText = difficulty != null ? describeEnum(difficulty) : 'aléatoire';
      final themeText = theme != null && theme.isNotEmpty ? 'sur le thème "$theme"' : '';
      
      final prompt = 'Génère un virelangue difficile de niveau $difficultyText $themeText en français. Le virelangue doit être complexe et amusant. Réponds uniquement avec le virelangue, sans autre texte.';
      
      _logger.d('Prompt Mistral pour virelangue: $prompt');
      
      final aiResponse = await _mistralApiService.generateText(prompt: prompt);
      
      if (aiResponse.isEmpty) {
        _logger.w('La réponse de l\'IA était vide, retour à la sélection prédéfinie.');
        return _selectRandomPredefinedVirelangue();
      }
      
      // Nettoyage et formatage de la réponse
      final cleanedText = aiResponse.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '').trim();
      
      final generatedVirelangue = Virelangue(
        id: _generateVirelangueId(cleanedText),
        text: cleanedText,
        difficulty: difficulty ?? VirelangueDifficulty.medium, // Ou estimer la difficulté par l'IA
        targetScore: (difficulty ?? VirelangueDifficulty.medium).targetScore,
        theme: theme ?? 'IA Généré',
        language: 'fr',
        description: 'Virelangue généré par l\'IA Mistral',
        isCustom: true,
        createdAt: DateTime.now(),
      );
      
      // Sauvegarder le virelangue généré par l'IA pour future utilisation
      final box = Hive.box<Virelangue>(_virelangueBoxName);
      await box.put(generatedVirelangue.id, generatedVirelangue);
      
      _logger.i('✅ Virelangue IA généré: "${generatedVirelangue.text}"');
      return generatedVirelangue;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur génération IA: $e', error: e, stackTrace: stackTrace);
      // Fallback vers sélection standard en cas d'erreur
      return _selectRandomPredefinedVirelangue();
    }
  }

  Virelangue _selectRandomPredefinedVirelangue() {
    final virelangues = Hive.box<Virelangue>(_virelangueBoxName).values.toList();
    if (virelangues.isEmpty) {
      _logger.w('⚠️ Aucun virelangue prédéfini trouvé, création d\'un fallback');
      return _createFallbackVirelangue();
    }
    final random = math.Random();
    return virelangues[random.nextInt(virelangues.length)];
  }

  /// Crée un virelangue de fallback en cas d'erreur
  Virelangue _createFallbackVirelangue() {
    return Virelangue(
      id: 'fallback_default',
      text: 'Un très grand dromadaire dromadaire drôle',
      difficulty: VirelangueDifficulty.easy,
      targetScore: 0.5,
      theme: 'fallback',
      language: 'fr',
      description: 'Virelangue par défaut en cas d\'erreur critique',
      isCustom: false,
      createdAt: DateTime.now(),
    );
  }

  /// Calcule le score de session basé sur toutes les tentatives
  double _calculateSessionScore(List<VirelanguePronunciationResult> results) {
    if (results.isEmpty) return 0.0;

    // Prendre le meilleur score avec bonus pour amélioration
    final scores = results.map((r) => r.overallScore).toList();
    final bestScore = scores.reduce(math.max);

    // Bonus d'amélioration si progression visible
    double improvementBonus = 0.0;
    if (scores.length > 1) {
      final improvement = scores.last - scores.first;
      if (improvement > 0) {
        improvementBonus = math.min(0.1, improvement * 0.5); // Max 10% bonus
      }
    }

    // Bonus de consistance si score élevé maintenu
    double consistencyBonus = 0.0;
    if (scores.length > 1 && scores.every((s) => s >= 0.8)) {
      consistencyBonus = 0.05; // 5% bonus pour consistance
    }

    return math.min(1.0, bestScore + improvementBonus + consistencyBonus);
  }

  /// Met à jour la collection de gemmes de l'utilisateur
  Future<void> _updateGemCollection(String userId, List<GemReward> newRewards) async {
    try {
      final box = await _ensureBoxIsOpen<GemCollection>(_gemCollectionBoxName);
      var collection = box.get(userId) ?? GemCollection(
        userId: userId,
        gems: {},
        totalValue: 0,
        lastUpdated: DateTime.now(),
      );

      // Ajouter les nouvelles gemmes
      for (final reward in newRewards) {
        final currentCount = collection.gems[reward.type] ?? 0;
        collection.gems[reward.type] = currentCount + reward.finalCount;
      }

      // Recalculer la valeur totale
      collection.totalValue = collection.gems.entries.fold(0,
        (sum, entry) => sum + (entry.value * entry.key.baseValue));

      collection.lastUpdated = DateTime.now();

      await box.put(userId, collection);

      _logger.i('💎 Collection mise à jour: ${collection.totalValue} points de valeur');

    } catch (e) {
      _logger.e('❌ Erreur mise à jour collection: $e');
    }
  }

  /// Met à jour la progression utilisateur
  Future<void> _updateUserProgress(
    String userId,
    double sessionScore,
    List<GemReward> rewards,
  ) async {
    try {
      final box = await _ensureBoxIsOpen<VirelangueUserProgress>(_userProgressBoxName);
      var progress = box.get(userId) ?? VirelangueUserProgress(
        userId: userId,
        totalSessions: 0,
        bestScore: 0.0,
        averageScore: 0.0,
        currentCombo: 0,
        currentStreak: 0,
        totalGemValue: 0,
        currentLevel: VirelangueDifficulty.easy,
        lastSessionDate: DateTime.now(),
        recentVirelangueIds: [],
        recentDifficulties: [],
      );

      // Mettre à jour les statistiques
      progress.totalSessions += 1;
      progress.bestScore = math.max(progress.bestScore, sessionScore);

      // Calculer nouvelle moyenne
      final totalScore = (progress.averageScore * (progress.totalSessions - 1)) + sessionScore;
      progress.averageScore = totalScore / progress.totalSessions;

      // Gérer combo et streak
      if (sessionScore >= 0.7) {
        progress.currentCombo += 1;
        progress.currentStreak += 1;
      } else {
        progress.currentCombo = 0;
        // Le streak continue même avec performance moyenne
        if (sessionScore < 0.5) {
          progress.currentStreak = 0;
        }
      }

      // Ajouter valeur des récompenses
      final rewardValue = rewards.fold(0, (sum, r) => sum + (r.finalCount * r.type.baseValue));
      progress.totalGemValue += rewardValue;

      // Mettre à jour le niveau si nécessaire
      progress.currentLevel = _calculateUserLevel(progress);

      progress.lastSessionDate = DateTime.now();

      await box.put(userId, progress);

      _logger.i('📈 Progression mise à jour: niveau ${progress.currentLevel.name}, combo ${progress.currentCombo}');

    } catch (e) {
      _logger.e('❌ Erreur mise à jour progression: $e');
    }
  }

  /// Calcule le niveau utilisateur basé sur la progression
  VirelangueDifficulty _calculateUserLevel(VirelangueUserProgress progress) {
    // Critères combinés : sessions, score moyen, valeur gemmes
    final sessionFactor = math.min(1.0, progress.totalSessions / 50.0);
    final scoreFactor = progress.averageScore;
    final gemFactor = math.min(1.0, progress.totalGemValue / 1000.0);

    final overallProgress = (sessionFactor + scoreFactor + gemFactor) / 3.0;

    if (overallProgress >= 0.8) return VirelangueDifficulty.expert;
    if (overallProgress >= 0.6) return VirelangueDifficulty.hard;
    if (overallProgress >= 0.4) return VirelangueDifficulty.medium;
    return VirelangueDifficulty.easy;
  }

  /// Charge les virelangues prédéfinis dans la base de données
  Future<void> _loadPredefinedVirelangues() async {
    try {
      final box = await _ensureBoxIsOpen<Virelangue>(_virelangueBoxName);

      // Ne charger que si la base est vide
      if (box.isEmpty) {
        _logger.i('📥 Chargement virelangues prédéfinis...');

        for (final data in _predefinedVirelangues) {
          final difficulty = VirelangueDifficulty.values.firstWhere(
            (d) => d.name == data['difficulty'],
            orElse: () => VirelangueDifficulty.medium,
          );

          final virelangue = Virelangue(
            id: _generateVirelangueId(data['text']),
            text: data['text'],
            difficulty: difficulty,
            targetScore: difficulty.targetScore,
            theme: data['theme'],
            language: data['language'],
            description: data['description'],
            isCustom: false,
            createdAt: DateTime.now(),
          );

          await box.put(virelangue.id, virelangue);
        }

        _logger.i('✅ ${_predefinedVirelangues.length} virelangues chargés');
      }
    } catch (e) {
      _logger.e('❌ Erreur chargement virelangues: $e');
    }
  }

  /// Assure que la boîte Hive est ouverte
  Future<Box<T>> _ensureBoxIsOpen<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    } else {
      _logger.w('⚠️ Boîte $boxName fermée, ouverture automatique...');
      return await Hive.openBox<T>(boxName);
    }
  }

  /// Récupère tous les virelangues disponibles
  Future<List<Virelangue>> getAllVirelangues() async {
    try {
      final box = await _ensureBoxIsOpen<Virelangue>(_virelangueBoxName);
      // Charger les virelangues prédéfinis si la boîte est vide
      if (box.isEmpty) {
        await _loadPredefinedVirelangues();
      }
      return box.values.toList();
    } catch (e) {
      _logger.e('❌ Erreur récupération virelangues: $e');
      return [];
    }
  }

  /// Récupère la progression utilisateur
  Future<VirelangueUserProgress> getUserProgress(String userId) async {
    try {
      final box = await _ensureBoxIsOpen<VirelangueUserProgress>(_userProgressBoxName);
      return box.get(userId) ?? VirelangueUserProgress(
        userId: userId,
        totalSessions: 0,
        bestScore: 0.0,
        averageScore: 0.0,
        currentCombo: 0,
        currentStreak: 0,
        totalGemValue: 0,
        currentLevel: VirelangueDifficulty.easy,
        lastSessionDate: DateTime.now(),
        recentVirelangueIds: [],
        recentDifficulties: [],
      );
    } catch (e) {
      _logger.e('❌ Erreur récupération progression: $e');
      return VirelangueUserProgress(
        userId: userId,
        totalSessions: 0,
        bestScore: 0.0,
        averageScore: 0.0,
        currentCombo: 0,
        currentStreak: 0,
        totalGemValue: 0,
        currentLevel: VirelangueDifficulty.easy,
        lastSessionDate: DateTime.now(),
        recentVirelangueIds: [],
        recentDifficulties: [],
      );
    }
  }

  /// Récupère la collection de gemmes utilisateur
  Future<GemCollection> getGemCollection(String userId) async {
    try {
      final box = await _ensureBoxIsOpen<GemCollection>(_gemCollectionBoxName);
      return box.get(userId) ?? GemCollection(
        userId: userId,
        gems: {},
        totalValue: 0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _logger.e('❌ Erreur récupération collection: $e');
      return GemCollection(
        userId: userId,
        gems: {},
        totalValue: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Génère un ID unique pour un virelangue
  String _generateVirelangueId(String text) {
    return 'vir_${text.hashCode.abs().toString()}';
  }

  /// Génère un ID unique pour une session
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }
  

  /// Libère les ressources
  void dispose() {
    _rewardSystem.dispose();
    _logger.i('🗑️ VirelangueService disposé');
  }
}

// ========== PROVIDERS RIVERPOD ==========

/// Provider pour le service principal des virelangues
final virelangueServiceProvider = Provider<VirelangueService>((ref) {
  final mistralApiService = ref.watch(mistralApiServiceProvider);
  final service = VirelangueService(mistralApiService);
  
  // Initialisation asynchrone qui ne bloque pas la création du provider
  Timer.run(() async {
    try {
      await service.initialize();
    } catch (e) {
      Logger().e('❌ Erreur initialisation VirelangueService: $e');
    }
  });
  
  return service;
});

/// Provider pour le service audio universel
final universalAudioExerciseServiceProvider = Provider<UniversalAudioExerciseService>((ref) {
  return UniversalAudioExerciseService();
});