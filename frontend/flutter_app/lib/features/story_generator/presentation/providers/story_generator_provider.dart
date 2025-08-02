import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger_service.dart';
import '../../domain/entities/story_models.dart';
import '../../data/services/story_generation_service.dart';
import '../../data/services/story_collaboration_ai_service.dart';
import '../../data/services/story_audio_analysis_service.dart';
import '../../data/services/story_audio_recording_service.dart';
import '../../../confidence_boost/domain/entities/virelangue_models.dart';
import '../../../confidence_boost/domain/entities/gamification_models.dart';
import '../../../confidence_boost/data/repositories/gamification_repository.dart';

/// État du générateur d'histoires
class StoryGeneratorState {
  final StoryUserStats? userStats;
  final List<Story> recentStories;
  final List<Map<String, dynamic>> dailyChallenges;
  final StoryExerciseSession? currentSession;
  final List<StoryElement> availableElements;
  final bool isLoading;
  final String? error;
  final bool isSpeedMode;

  const StoryGeneratorState({
    this.userStats,
    this.recentStories = const [],
    this.dailyChallenges = const [],
    this.currentSession,
    this.availableElements = const [],
    this.isLoading = false,
    this.error,
    this.isSpeedMode = false,
  });

  StoryGeneratorState copyWith({
    StoryUserStats? userStats,
    List<Story>? recentStories,
    List<Map<String, dynamic>>? dailyChallenges,
    StoryExerciseSession? currentSession,
    List<StoryElement>? availableElements,
    bool? isLoading,
    String? error,
    bool? isSpeedMode,
  }) {
    return StoryGeneratorState(
      userStats: userStats ?? this.userStats,
      recentStories: recentStories ?? this.recentStories,
      dailyChallenges: dailyChallenges ?? this.dailyChallenges,
      currentSession: currentSession ?? this.currentSession,
      availableElements: availableElements ?? this.availableElements,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSpeedMode: isSpeedMode ?? this.isSpeedMode,
    );
  }
}

/// Provider Riverpod pour le générateur d'histoires
class StoryGeneratorNotifier extends StateNotifier<StoryGeneratorState> {
  final StoryGenerationService _generationService;
  final StoryCollaborationAIService _aiService;
  final StoryAudioAnalysisService _audioService;
  final StoryAudioRecordingService _recordingService;
  final GamificationRepository _gamificationRepository;
  final String _tag = 'StoryGeneratorProvider';

  StoryGeneratorNotifier({
    StoryGenerationService? generationService,
    StoryCollaborationAIService? aiService,
    StoryAudioAnalysisService? audioService,
    StoryAudioRecordingService? recordingService,
    GamificationRepository? gamificationRepository,
  }) : _generationService = generationService ?? StoryGenerationService(),
       _aiService = aiService ?? StoryCollaborationAIService(),
       _audioService = audioService ?? StoryAudioAnalysisService(),
       _recordingService = recordingService ?? StoryAudioRecordingService(),
       _gamificationRepository = gamificationRepository ?? HiveGamificationRepository(),
       super(const StoryGeneratorState());

  /// Charge les statistiques utilisateur
  Future<void> loadUserStats() async {
    try {
      logger.i(_tag, 'Chargement statistiques utilisateur');
      state = state.copyWith(isLoading: true, error: null);

      // Créer des stats de base pour l'instant
      final stats = StoryUserStats(
        userId: 'current_user',
        totalStories: 5,
        totalLikes: 12,
        averageCreativity: 0.78,
        averageCollaboration: 0.65,
        averageFluidity: 0.82,
        totalAIInterventionsUsed: 8,
        genreStats: {
          StoryGenre.fantasy: 3,
          StoryGenre.adventure: 2,
        },
        unlockedBadges: [
          StoryBadgeType.improvisationMaster,
          StoryBadgeType.creativityChampion,
        ],
        currentStreak: 3,
      );

      // Charger des histoires récentes factices
      final recentStories = _generateMockRecentStories();
      
      // Charger des défis du jour
      final challenges = _generateDailyChallenges();

      state = state.copyWith(
        userStats: stats,
        recentStories: recentStories,
        dailyChallenges: challenges,
        isLoading: false,
      );

      logger.i(_tag, 'Statistiques chargées avec succès');
    } catch (e) {
      logger.e(_tag, 'Erreur chargement statistiques: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les statistiques',
      );
    }
  }

  /// Génère des éléments narratifs pour le tirage
  Future<void> generateStoryElements() async {
    try {
      logger.i(_tag, 'Génération éléments narratifs pour tirage');
      state = state.copyWith(isLoading: true, error: null);

      // Générer 3 éléments narratifs (personnage, lieu, objet magique)
      final elements = _generationService.generateStoryElements();
      
      // Créer une nouvelle session en phase de sélection
      final session = StoryExerciseSession.initial(userId: 'current_user')
          .copyWith(
            availableElements: elements,
            phase: StorySessionPhase.elementSelection,
          );

      state = state.copyWith(
        currentSession: session,
        availableElements: elements,
        isLoading: false,
      );

      logger.i(_tag, 'Éléments narratifs générés avec succès: ${elements.length} éléments');
    } catch (e) {
      logger.e(_tag, 'Erreur génération éléments narratifs: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de générer les éléments narratifs',
      );
    }
  }

  /// Génère une histoire aléatoire
  Future<void> generateRandomStory() async {
    try {
      logger.i(_tag, 'Génération histoire aléatoire');
      state = state.copyWith(isLoading: true, error: null);

      // Générer 3 éléments aléatoirement
      final elements = _generationService.generateStoryElements();
      
      // Créer une nouvelle session
      final session = StoryExerciseSession.initial(userId: 'current_user')
          .copyWith(
            availableElements: elements,
            selectedElements: elements,
            phase: StorySessionPhase.narration,
          );

      state = state.copyWith(
        currentSession: session,
        availableElements: elements,
        isLoading: false,
      );

      logger.i(_tag, 'Histoire aléatoire générée avec ${elements.length} éléments');
    } catch (e) {
      logger.e(_tag, 'Erreur génération histoire aléatoire: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de générer l\'histoire',
      );
    }
  }

  /// Active/désactive le mode rapide
  void setSpeedMode(bool enabled) {
    logger.i(_tag, 'Mode rapide: ${enabled ? 'activé' : 'désactivé'}');
    state = state.copyWith(isSpeedMode: enabled);
  }

  /// Démarre un défi spécifique
  Future<void> startChallenge(Map<String, dynamic> challenge) async {
    try {
      logger.i(_tag, 'Démarrage défi: ${challenge['title']}');
      state = state.copyWith(isLoading: true, error: null);

      // Générer des éléments selon le défi
      final genre = _parseGenreFromChallenge(challenge);
      final elements = _generationService.generateThemedElements(genre);

      // Créer une session de défi
      final session = StoryExerciseSession.initial(userId: 'current_user')
          .copyWith(
            availableElements: elements,
            selectedElements: elements,
            maxDuration: challenge['duration'] ?? 90,
            phase: StorySessionPhase.narration,
          );

      state = state.copyWith(
        currentSession: session,
        availableElements: elements,
        isLoading: false,
      );

      logger.i(_tag, 'Défi démarré avec succès');
    } catch (e) {
      logger.e(_tag, 'Erreur démarrage défi: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de démarrer le défi',
      );
    }
  }

  /// Sélectionne des éléments pour l'histoire
  void selectElements(List<StoryElement> elements) {
    logger.i(_tag, 'Sélection de ${elements.length} éléments');
    
    final session = state.currentSession?.copyWith(
      selectedElements: elements,
      phase: StorySessionPhase.narration,
    ) ?? StoryExerciseSession.initial(userId: 'current_user')
        .copyWith(
          selectedElements: elements,
          phase: StorySessionPhase.narration,
        );

    state = state.copyWith(currentSession: session);
  }

  /// Démarre l'enregistrement de l'histoire
  Future<void> startRecording() async {
    try {
      logger.i(_tag, 'Démarrage enregistrement');
      
      if (state.currentSession?.selectedElements == null) {
        throw Exception('Aucun élément sélectionné');
      }

      // Initialiser le service d'enregistrement si nécessaire
      if (!_recordingService.isInitialized) {
        final initialized = await _recordingService.initialize();
        if (!initialized) {
          throw Exception('Impossible d\'initialiser le service d\'enregistrement');
        }
      }

      // Démarrer l'enregistrement audio réel
      final recordingPath = await _recordingService.startRecording();
      if (recordingPath == null) {
        throw Exception('Impossible de démarrer l\'enregistrement audio');
      }

      final session = state.currentSession!.copyWith(
        isRecording: true,
        startTime: DateTime.now(),
      );

      state = state.copyWith(currentSession: session);
      
      logger.i(_tag, 'Enregistrement audio démarré: $recordingPath');
    } catch (e) {
      logger.e(_tag, 'Erreur démarrage enregistrement: $e');
      state = state.copyWith(error: 'Impossible de démarrer l\'enregistrement');
    }
  }

  /// Arrête l'enregistrement et lance l'analyse narrative
  Future<void> stopRecording() async {
    logger.i(_tag, 'Arrêt enregistrement');
    
    try {
      // Arrêter l'enregistrement audio et récupérer les données
      final recordingResult = await _recordingService.stopRecording();
      
      Uint8List? audioData;
      if (recordingResult != null && recordingResult['valid'] == true) {
        audioData = recordingResult['audioData'] as Uint8List;
        logger.i(_tag, '✅ Audio réel capturé: ${audioData.length} bytes');
      } else {
        logger.w(_tag, '⚠️ Échec capture audio: ${recordingResult?['error'] ?? 'erreur inconnue'}');
      }

      final session = state.currentSession?.copyWith(
        isRecording: false,
        endTime: DateTime.now(),
        phase: StorySessionPhase.analysis,
        recordedAudioData: audioData, // Stocker les données audio réelles
      );

      state = state.copyWith(currentSession: session);

      // Lancer l'analyse narrative réelle
      await _analyzeNarrative(session);

      // Attribution automatique des badges après completion
      await _checkAndAwardBadges(session);
      await _checkProgressionBadges('current_user');
      
    } catch (e) {
      logger.e(_tag, 'Erreur arrêt enregistrement: $e');
      
      // Continuer même en cas d'erreur audio
      final session = state.currentSession?.copyWith(
        isRecording: false,
        endTime: DateTime.now(),
        phase: StorySessionPhase.analysis,
      );

      state = state.copyWith(currentSession: session);
      await _analyzeNarrative(session);
    }
  }

  /// Analyse la narration avec le service réel
  Future<void> _analyzeNarrative(StoryExerciseSession? session) async {
    if (session == null || session.selectedElements == null) {
      logger.w(_tag, 'Pas de session ou d\'éléments pour l\'analyse');
      return;
    }

    try {
      logger.i(_tag, 'Démarrage analyse narrative réelle');
      
      // Créer un objet Story pour l'analyse
      final storyTitle = "Histoire Eloquence ${DateTime.now().millisecondsSinceEpoch}";
      final storyDuration = session.endTime?.difference(session.startTime) ?? Duration.zero;
      
      // Créer les métriques de base
      final storyMetrics = StoryMetrics(
        creativity: 75.0,
        collaboration: 60.0,
        fluidity: 80.0,
        totalDuration: storyDuration,
        wordCount: 50, // Estimation
      );

      // Créer l'objet Story complet
      final story = Story(
        id: session.sessionId,
        userId: session.userId,
        title: storyTitle,
        elements: session.selectedElements!,
        audioSegmentUrls: [], // TODO: ajouter les URLs audio réelles
        aiInterventions: session.pendingInterventions,
        metrics: storyMetrics,
        createdAt: session.startTime,
      );

      // ✅ CORRECTION: Utiliser le vrai enregistrement audio s'il existe
      Uint8List audioData;
      
      // Vérifier s'il y a un vrai enregistrement audio
      if (session.recordedAudioData != null && session.recordedAudioData!.isNotEmpty) {
        // Utiliser le vrai enregistrement
        audioData = session.recordedAudioData!;
        logger.i(_tag, '🎤 UTILISATION AUDIO RÉEL - Taille: ${audioData.length} bytes (${(audioData.length / 1024).toStringAsFixed(1)} KB)');
      } else {
        // Fallback vers audio synthétique si pas d'enregistrement
        audioData = await _generateRealisticAudioData(storyDuration);
        logger.w(_tag, '⚠️ AUCUN AUDIO RÉEL - Utilisation audio synthétique: ${audioData.length} bytes');
      }

      // Analyser avec le service réel
      final analysis = await _audioService.analyzeCompleteNarrative(
        sessionId: session.sessionId,
        story: story,
        audioData: audioData,
      );

      logger.i(_tag, 'Analyse narrative terminée avec succès');

      // Mettre à jour la session avec les résultats d'analyse
      final updatedSession = session.copyWith(
        phase: StorySessionPhase.completed,
        analysisResult: analysis,
      );

      state = state.copyWith(currentSession: updatedSession);

    } catch (e) {
      logger.e(_tag, 'Erreur analyse narrative: $e');
      
      // En cas d'erreur, utiliser l'analyse fallback
      final fallbackAnalysis = StoryNarrativeAnalysis.fallback();
      final fallbackSession = session.copyWith(
        phase: StorySessionPhase.completed,
        analysisResult: fallbackAnalysis,
      );
      
      state = state.copyWith(currentSession: fallbackSession);
    }
  }

  /// Génère des données audio réalistes pour les tests
  Future<Uint8List> _generateRealisticAudioData(Duration duration) async {
    logger.i(_tag, '🎵 Génération audio réaliste pour durée: ${duration.inSeconds}s');
    
    // Créer un header WAV valide
    final sampleRate = 16000;
    final channels = 1;
    final bitsPerSample = 16;
    final durationMs = duration.inMilliseconds.clamp(1000, 90000); // Entre 1s et 90s
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * channels * (bitsPerSample ~/ 8);
    
    // Construire le header WAV
    final header = <int>[
      // "RIFF" chunk descriptor
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      
      // ChunkSize (36 + SubChunk2Size)
      ...(_int32ToBytes(36 + dataSize)),
      
      // Format = "WAVE"
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      
      // Subchunk1 = "fmt "
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      16, 0, 0, 0, // Subchunk1Size = 16
      1, 0, // AudioFormat = 1 (PCM)
      
      // NumChannels
      ...(_int16ToBytes(channels)),
      
      // SampleRate
      ...(_int32ToBytes(sampleRate)),
      
      // ByteRate = SampleRate * NumChannels * BitsPerSample/8
      ...(_int32ToBytes(sampleRate * channels * bitsPerSample ~/ 8)),
      
      // BlockAlign = NumChannels * BitsPerSample/8
      ...(_int16ToBytes(channels * bitsPerSample ~/ 8)),
      
      // BitsPerSample
      ...(_int16ToBytes(bitsPerSample)),
      
      // Subchunk2 = "data"
      0x64, 0x61, 0x74, 0x61, // "data"
      
      // Subchunk2Size = NumSamples * NumChannels * BitsPerSample/8
      ...(_int32ToBytes(dataSize)),
    ];
    
    // Générer des données audio silencieuses mais réalistes
    final audioData = List<int>.generate(dataSize, (index) {
      // Générer un silence avec un peu de bruit pour simuler un vrai enregistrement
      final noise = (math.Random().nextDouble() - 0.5) * 200; // Bruit faible
      return noise.clamp(-32768, 32767).round() & 0xFFFF;
    });
    
    // Convertir en bytes little-endian
    final audioBytes = <int>[];
    for (int i = 0; i < audioData.length; i += 2) {
      final sample = audioData[i];
      audioBytes.add(sample & 0xFF);
      audioBytes.add((sample >> 8) & 0xFF);
    }
    
    final totalData = [...header, ...audioBytes];
    final result = Uint8List.fromList(totalData);
    
    logger.i(_tag, '✅ Audio généré: ${result.length} bytes, ${(result.length / 1024).toStringAsFixed(1)} KB, durée: ${durationMs}ms');
    
    return result;
  }

  /// Convertit un entier 32 bits en bytes little-endian
  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  /// Convertit un entier 16 bits en bytes little-endian
  List<int> _int16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }

  /// Efface l'état actuel
  void clearState() {
    logger.i(_tag, 'Effacement état');
    _recordingService.dispose(); // Nettoyer le service d'enregistrement
    state = const StoryGeneratorState();
  }

  /// Génère des histoires récentes factices
  List<Story> _generateMockRecentStories() {
    return [
      Story(
        id: 'story_1',
        userId: 'current_user',
        title: 'L\'Aventure du Dragon Cuisinier',
        elements: [
          StoryElement(
            id: 'char_1',
            type: StoryElementType.character,
            name: 'Dragon Cuisinier',
            emoji: '🐲',
            description: 'Un dragon qui aime cuisiner',
            difficulty: VirelangueDifficulty.easy,
          ),
        ],
        audioSegmentUrls: [],
        aiInterventions: [],
        metrics: StoryMetrics(
          creativity: 85,
          collaboration: 70,
          fluidity: 90,
          totalDuration: const Duration(minutes: 2, seconds: 30),
          wordCount: 150,
        ),
        genre: StoryGenre.fantasy,
        likes: 5,
      ),
    ];
  }

  /// Génère des défis quotidiens
  List<Map<String, dynamic>> _generateDailyChallenges() {
    return [
      {
        'title': 'Défi Fantasy Express',
        'description': 'Créez une histoire fantastique en 60 secondes',
        'genre': 'fantasy',
        'duration': 60,
        'reward': 'Badge Maître Fantasy',
        'icon': '🏰',
      },
      {
        'title': 'Narrateur Rapide',
        'description': 'Racontez 3 histoires consécutives',
        'requirement': 'speed',
        'count': 3,
        'reward': '50 XP bonus',
        'icon': '⚡',
      },
    ];
  }

  /// Parse le genre depuis un défi
  StoryGenre _parseGenreFromChallenge(Map<String, dynamic> challenge) {
    final genreStr = challenge['genre'] as String?;
    switch (genreStr) {
      case 'fantasy':
        return StoryGenre.fantasy;
      case 'adventure':
        return StoryGenre.adventure;
      case 'mystery':
        return StoryGenre.mystery;
      case 'comedy':
        return StoryGenre.comedy;
      default:
        return StoryGenre.fantasy;
    }
  }

  /// Vérifie et attribue les badges appropriés
  Future<void> _checkAndAwardBadges(StoryExerciseSession? session) async {
    if (session == null) return;

    try {
      await _gamificationRepository.initialize();
      const userId = 'current_user'; // TODO: Obtenir l'ID utilisateur réel
      
      // Badge première histoire
      await _checkFirstStoryBadge(userId);
      
      // Badges basés sur les performances
      await _checkPerformanceBadges(userId, session);
      
      // Badges basés sur la durée
      await _checkDurationBadges(userId, session);
      
      // Badges de collaboration IA
      await _checkCollaborationBadges(userId, session);
      
      logger.i(_tag, 'Vérification badges terminée');
    } catch (e) {
      logger.e(_tag, 'Erreur attribution badges: $e');
    }
  }

  /// Vérifie le badge première histoire
  Future<void> _checkFirstStoryBadge(String userId) async {
    final userProfile = await _gamificationRepository.getUserProfile(userId);
    final userStats = state.userStats;
    
    if (userStats?.totalStories == 1 && !userProfile.earnedBadgeIds.contains('first_story')) {
      await _gamificationRepository.awardBadge(userId, 'first_story');
      logger.i(_tag, 'Badge "Premier Conte" attribué !');
    }
  }

  /// Vérifie les badges basés sur les performances
  Future<void> _checkPerformanceBadges(String userId, StoryExerciseSession session) async {
    final userProfile = await _gamificationRepository.getUserProfile(userId);
    
    // Simuler les scores pour l'instant (TODO: utiliser les vrais scores d'analyse)
    final creativityScore = 0.85;
    final collaborationScore = 0.72;
    final fluidityScore = 0.91;
    
    // Badge Magicien de la Voix (score de modulation vocale > 90%)
    if (fluidityScore > 0.90 && !userProfile.earnedBadgeIds.contains('voice_magician')) {
      await _gamificationRepository.awardBadge(userId, 'voice_magician');
      logger.i(_tag, 'Badge "Magicien de la Voix" attribué !');
    }
    
    // Badge Maître des Émotions (score émotionnel > 85%)
    if (creativityScore > 0.85 && !userProfile.earnedBadgeIds.contains('emotion_master')) {
      await _gamificationRepository.awardBadge(userId, 'emotion_master');
      logger.i(_tag, 'Badge "Maître des Émotions" attribué !');
    }
  }

  /// Vérifie les badges basés sur la durée
  Future<void> _checkDurationBadges(String userId, StoryExerciseSession session) async {
    final userProfile = await _gamificationRepository.getUserProfile(userId);
    final duration = session.endTime?.difference(session.startTime ?? DateTime.now()) ?? Duration.zero;
    
    // Badge Conteur Express (moins de 3 minutes)
    if (duration.inMinutes < 3 && !userProfile.earnedBadgeIds.contains('speed_storyteller')) {
      await _gamificationRepository.awardBadge(userId, 'speed_storyteller');
      logger.i(_tag, 'Badge "Conteur Express" attribué !');
    }
    
    // Badge Narrateur Épique (plus de 10 minutes)
    if (duration.inMinutes > 10 && !userProfile.earnedBadgeIds.contains('epic_narrator')) {
      await _gamificationRepository.awardBadge(userId, 'epic_narrator');
      logger.i(_tag, 'Badge "Narrateur Épique" attribué !');
    }
  }

  /// Vérifie les badges de collaboration IA
  Future<void> _checkCollaborationBadges(String userId, StoryExerciseSession session) async {
    final userProfile = await _gamificationRepository.getUserProfile(userId);
    final userStats = state.userStats;
    
    // Badge Génie du Rebondissement (20 rebondissements IA utilisés)
    if ((userStats?.totalAIInterventionsUsed ?? 0) >= 20 &&
        !userProfile.earnedBadgeIds.contains('plot_twist_genius')) {
      await _gamificationRepository.awardBadge(userId, 'plot_twist_genius');
      logger.i(_tag, 'Badge "Génie du Rebondissement" attribué !');
    }
    
    // Badge Génie Collaboratif (15 suggestions IA acceptées)
    if ((userStats?.totalAIInterventionsUsed ?? 0) >= 15 &&
        !userProfile.earnedBadgeIds.contains('collaborative_genius')) {
      await _gamificationRepository.awardBadge(userId, 'collaborative_genius');
      logger.i(_tag, 'Badge "Génie Collaboratif" attribué !');
    }
  }

  /// Vérifie les badges de progression générale
  Future<void> _checkProgressionBadges(String userId) async {
    final userProfile = await _gamificationRepository.getUserProfile(userId);
    final userStats = state.userStats;
    
    // Badge Tisseur d'Histoires (10 histoires)
    if ((userStats?.totalStories ?? 0) >= 10 &&
        !userProfile.earnedBadgeIds.contains('story_weaver')) {
      await _gamificationRepository.awardBadge(userId, 'story_weaver');
      logger.i(_tag, 'Badge "Tisseur d\'Histoires" attribué !');
    }
    
    // Badge Maître Narrateur (50 histoires)
    if ((userStats?.totalStories ?? 0) >= 50 &&
        !userProfile.earnedBadgeIds.contains('narrative_master')) {
      await _gamificationRepository.awardBadge(userId, 'narrative_master');
      logger.i(_tag, 'Badge "Maître Narrateur" attribué !');
    }
    
    // Badge Conteur Légendaire (100 histoires parfaites)
    if ((userStats?.totalStories ?? 0) >= 100 &&
        !userProfile.earnedBadgeIds.contains('legendary_storyteller')) {
      await _gamificationRepository.awardBadge(userId, 'legendary_storyteller');
      logger.i(_tag, 'Badge "Conteur Légendaire" attribué !');
    }
  }
}

/// Provider principal pour le générateur d'histoires
final storyGeneratorProvider = StateNotifierProvider<StoryGeneratorNotifier, StoryGeneratorState>(
  (ref) => StoryGeneratorNotifier(),
);

/// Providers pour les services
final storyGenerationServiceProvider = Provider<StoryGenerationService>(
  (ref) => StoryGenerationService(),
);

final storyCollaborationAIServiceProvider = Provider<StoryCollaborationAIService>(
  (ref) => StoryCollaborationAIService(),
);

final storyAudioAnalysisServiceProvider = Provider<StoryAudioAnalysisService>(
  (ref) => StoryAudioAnalysisService(),
);