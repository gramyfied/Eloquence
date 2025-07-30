import 'dart:math' as math;
import 'package:hive/hive.dart';
import '../../../confidence_boost/domain/entities/virelangue_models.dart';

part 'story_models.g.dart';

/// Types d'éléments narratifs pour les histoires
@HiveType(typeId: 50)
enum StoryElementType {
  @HiveField(0)
  character,      // Personnage
  @HiveField(1)
  location,       // Lieu
  @HiveField(2)
  magicObject     // Objet magique
}

extension StoryElementTypeExtension on StoryElementType {
  String get displayName {
    switch (this) {
      case StoryElementType.character:
        return 'Personnage';
      case StoryElementType.location:
        return 'Lieu';
      case StoryElementType.magicObject:
        return 'Objet Magique';
    }
  }

  String get emoji {
    switch (this) {
      case StoryElementType.character:
        return '🧙‍♎';
      case StoryElementType.location:
        return '🏰';
      case StoryElementType.magicObject:
        return '🔮';
    }
  }
}

/// Genres d'histoires
@HiveType(typeId: 51)
enum StoryGenre {
  @HiveField(0)
  fantasy,        // Fantastique
  @HiveField(1)
  scienceFiction, // Science-Fiction
  @HiveField(2)
  adventure,      // Aventure
  @HiveField(3)
  mystery,        // Mystère
  @HiveField(4)
  comedy,         // Comédie
  @HiveField(5)
  horror,         // Horreur
  @HiveField(6)
  fairytale       // Conte de fées
}

extension StoryGenreExtension on StoryGenre {
  String get displayName {
    switch (this) {
      case StoryGenre.fantasy:
        return 'Fantastique';
      case StoryGenre.scienceFiction:
        return 'Science-Fiction';
      case StoryGenre.adventure:
        return 'Aventure';
      case StoryGenre.mystery:
        return 'Mystère';
      case StoryGenre.comedy:
        return 'Comédie';
      case StoryGenre.horror:
        return 'Horreur';
      case StoryGenre.fairytale:
        return 'Conte de Fées';
    }
  }

  String get emoji {
    switch (this) {
      case StoryGenre.fantasy:
        return '🏰';
      case StoryGenre.scienceFiction:
        return '🚀';
      case StoryGenre.adventure:
        return '⚔️';
      case StoryGenre.mystery:
        return '🔍';
      case StoryGenre.comedy:
        return '😂';
      case StoryGenre.horror:
        return '👻';
      case StoryGenre.fairytale:
        return '✨';
    }
  }
}

/// Élément narratif (personnage, lieu, objet)
@HiveType(typeId: 52)
class StoryElement extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  StoryElementType type;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  String emoji;
  
  @HiveField(4)
  String description;
  
  @HiveField(5)
  VirelangueDifficulty difficulty;
  
  @HiveField(6)
  List<String> keywords;
  
  @HiveField(7)
  StoryGenre? preferredGenre;
  
  @HiveField(8)
  bool isCustomGenerated;
  
  @HiveField(9)
  DateTime createdAt;

  StoryElement({
    required this.id,
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.difficulty,
    this.keywords = const [],
    this.preferredGenre,
    this.isCustomGenerated = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StoryElement.fromJson(Map<String, dynamic> json) {
    return StoryElement(
      id: json['id'] as String,
      type: StoryElementType.values[json['type'] as int],
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      description: json['description'] as String,
      difficulty: VirelangueDifficulty.values[json['difficulty'] as int],
      keywords: List<String>.from(json['keywords'] ?? []),
      preferredGenre: json['preferred_genre'] != null 
          ? StoryGenre.values[json['preferred_genre'] as int]
          : null,
      isCustomGenerated: json['is_custom_generated'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'emoji': emoji,
      'description': description,
      'difficulty': difficulty.index,
      'keywords': keywords,
      'preferred_genre': preferredGenre?.index,
      'is_custom_generated': isCustomGenerated,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Types d'interventions IA dans les histoires
@HiveType(typeId: 58)
enum InterventionType {
  @HiveField(0)
  plotTwist,          // Rebondissement d'intrigue
  @HiveField(1)
  characterReveal,    // Révélation de personnage
  @HiveField(2)
  settingShift,       // Changement d'environnement
  @HiveField(3)
  toneChange,         // Changement de ton
  @HiveField(4)
  mysteryElement,     // Élément mystérieux
  @HiveField(5)
  creativeBoost,      // Boost créatif
  @HiveField(6)
  narrativeChallenge  // Défi narratif
}

extension InterventionTypeExtension on InterventionType {
  String get displayName {
    switch (this) {
      case InterventionType.plotTwist:
        return 'Rebondissement';
      case InterventionType.characterReveal:
        return 'Révélation';
      case InterventionType.settingShift:
        return 'Changement de décor';
      case InterventionType.toneChange:
        return 'Changement de ton';
      case InterventionType.mysteryElement:
        return 'Mystère';
      case InterventionType.creativeBoost:
        return 'Boost créatif';
      case InterventionType.narrativeChallenge:
        return 'Défi narratif';
    }
  }

  String get emoji {
    switch (this) {
      case InterventionType.plotTwist:
        return '🌪️';
      case InterventionType.characterReveal:
        return '🎭';
      case InterventionType.settingShift:
        return '🌍';
      case InterventionType.toneChange:
        return '🎵';
      case InterventionType.mysteryElement:
        return '❓';
      case InterventionType.creativeBoost:
        return '💡';
      case InterventionType.narrativeChallenge:
        return '⚡';
    }
  }
}

/// Intervention de l'IA pendant l'histoire
@HiveType(typeId: 53)
class AIIntervention extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String content;
  
  @HiveField(2)
  Duration timestamp;
  
  @HiveField(3)
  bool wasAccepted;
  
  @HiveField(4)
  String? userResponse;
  
  @HiveField(5)
  DateTime createdAt;

  AIIntervention({
    required this.id,
    required this.content,
    required this.timestamp,
    this.wasAccepted = false,
    this.userResponse,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AIIntervention.fromJson(Map<String, dynamic> json) {
    return AIIntervention(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: Duration(milliseconds: json['timestamp_ms'] as int),
      wasAccepted: json['was_accepted'] as bool? ?? false,
      userResponse: json['user_response'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp_ms': timestamp.inMilliseconds,
      'was_accepted': wasAccepted,
      'user_response': userResponse,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Métriques de performance d'une histoire
@HiveType(typeId: 54)
class StoryMetrics extends HiveObject {
  @HiveField(0)
  double creativity;      // Score de créativité (0-100%)
  
  @HiveField(1)
  double collaboration;   // Utilisation des suggestions IA (0-100%)
  
  @HiveField(2)
  double fluidity;       // Fluidité narrative (0-100%)
  
  @HiveField(3)
  Duration totalDuration;
  
  @HiveField(4)
  int wordCount;
  
  @HiveField(5)
  int pauseCount;
  
  @HiveField(6)
  double averagePauseDuration;
  
  @HiveField(7)
  int aiInterventionsUsed;
  
  @HiveField(8)
  double overallScore;

  StoryMetrics({
    required this.creativity,
    required this.collaboration,
    required this.fluidity,
    required this.totalDuration,
    required this.wordCount,
    this.pauseCount = 0,
    this.averagePauseDuration = 0.0,
    this.aiInterventionsUsed = 0,
    double? overallScore,
  }) : overallScore = overallScore ?? _calculateOverallScore(creativity, collaboration, fluidity);

  static double _calculateOverallScore(double creativity, double collaboration, double fluidity) {
    return (creativity * 0.4 + collaboration * 0.3 + fluidity * 0.3);
  }

  factory StoryMetrics.fromJson(Map<String, dynamic> json) {
    return StoryMetrics(
      creativity: (json['creativity'] as num).toDouble(),
      collaboration: (json['collaboration'] as num).toDouble(),
      fluidity: (json['fluidity'] as num).toDouble(),
      totalDuration: Duration(milliseconds: json['total_duration_ms'] as int),
      wordCount: json['word_count'] as int,
      pauseCount: json['pause_count'] as int? ?? 0,
      averagePauseDuration: (json['average_pause_duration'] as num?)?.toDouble() ?? 0.0,
      aiInterventionsUsed: json['ai_interventions_used'] as int? ?? 0,
      overallScore: (json['overall_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creativity': creativity,
      'collaboration': collaboration,
      'fluidity': fluidity,
      'total_duration_ms': totalDuration.inMilliseconds,
      'word_count': wordCount,
      'pause_count': pauseCount,
      'average_pause_duration': averagePauseDuration,
      'ai_interventions_used': aiInterventionsUsed,
      'overall_score': overallScore,
    };
  }
}

/// Histoire complète créée par l'utilisateur
@HiveType(typeId: 55)
class Story extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  List<StoryElement> elements;
  
  @HiveField(4)
  List<String> audioSegmentUrls;  // URLs des enregistrements audio
  
  @HiveField(5)
  List<AIIntervention> aiInterventions;
  
  @HiveField(6)
  StoryMetrics metrics;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  StoryGenre? genre;
  
  @HiveField(9)
  int likes;
  
  @HiveField(10)
  bool isPublic;
  
  @HiveField(11)
  String? transcription;  // Transcription de l'histoire
  
  @HiveField(12)
  List<String> tags;
  
  @HiveField(13)
  bool isFavorite;

  Story({
    required this.id,
    required this.userId,
    required this.title,
    required this.elements,
    required this.audioSegmentUrls,
    required this.aiInterventions,
    required this.metrics,
    DateTime? createdAt,
    this.genre,
    this.likes = 0,
    this.isPublic = false,
    this.transcription,
    this.tags = const [],
    this.isFavorite = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Durée totale formatée
  String get formattedDuration {
    final minutes = metrics.totalDuration.inMinutes;
    final seconds = metrics.totalDuration.inSeconds % 60;
    return '${minutes}min ${seconds.toString().padLeft(2, '0')}s';
  }

  /// Score total avec étoiles
  int get starRating => (metrics.overallScore / 20).round().clamp(1, 5);

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      elements: (json['elements'] as List)
          .map((e) => StoryElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      audioSegmentUrls: List<String>.from(json['audio_segment_urls'] ?? []),
      aiInterventions: (json['ai_interventions'] as List)
          .map((e) => AIIntervention.fromJson(e as Map<String, dynamic>))
          .toList(),
      metrics: StoryMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      genre: json['genre'] != null 
          ? StoryGenre.values[json['genre'] as int]
          : null,
      likes: json['likes'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? false,
      transcription: json['transcription'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'elements': elements.map((e) => e.toJson()).toList(),
      'audio_segment_urls': audioSegmentUrls,
      'ai_interventions': aiInterventions.map((e) => e.toJson()).toList(),
      'metrics': metrics.toJson(),
      'created_at': createdAt.toIso8601String(),
      'genre': genre?.index,
      'likes': likes,
      'is_public': isPublic,
      'transcription': transcription,
      'tags': tags,
      'is_favorite': isFavorite,
    };
  }
}

/// Session d'exercice de génération d'histoires
class StoryExerciseSession {
  final String sessionId;
  final String userId;
  final List<StoryElement> availableElements;
  final List<StoryElement>? selectedElements;
  final Story? currentStory;
  final DateTime startTime;
  final DateTime? endTime;
  final int maxDuration; // en secondes
  final bool isActive;
  final bool isRecording;
  final Duration currentDuration;
  final List<AIIntervention> pendingInterventions;
  final StorySessionPhase phase;
  final StoryNarrativeAnalysis? analysisResult;

  const StoryExerciseSession({
    required this.sessionId,
    required this.userId,
    required this.availableElements,
    this.selectedElements,
    this.currentStory,
    required this.startTime,
    this.endTime,
    this.maxDuration = 90, // 90 secondes par défaut
    this.isActive = true,
    this.isRecording = false,
    this.currentDuration = Duration.zero,
    this.pendingInterventions = const [],
    this.phase = StorySessionPhase.elementSelection,
    this.analysisResult,
  });

  /// Constructor pour session initiale
  factory StoryExerciseSession.initial({required String userId}) {
    return StoryExerciseSession(
      sessionId: 'story_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      availableElements: [],
      selectedElements: null,
      currentStory: null,
      startTime: DateTime.now(),
      endTime: null,
      maxDuration: 90,
      isActive: false,
      isRecording: false,
      currentDuration: Duration.zero,
      pendingInterventions: [],
      phase: StorySessionPhase.elementSelection,
      analysisResult: null,
    );
  }

  StoryExerciseSession copyWith({
    String? sessionId,
    String? userId,
    List<StoryElement>? availableElements,
    List<StoryElement>? selectedElements,
    Story? currentStory,
    DateTime? startTime,
    DateTime? endTime,
    int? maxDuration,
    bool? isActive,
    bool? isRecording,
    Duration? currentDuration,
    List<AIIntervention>? pendingInterventions,
    StorySessionPhase? phase,
    StoryNarrativeAnalysis? analysisResult,
  }) {
    return StoryExerciseSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      availableElements: availableElements ?? this.availableElements,
      selectedElements: selectedElements ?? this.selectedElements,
      currentStory: currentStory ?? this.currentStory,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxDuration: maxDuration ?? this.maxDuration,
      isActive: isActive ?? this.isActive,
      isRecording: isRecording ?? this.isRecording,
      currentDuration: currentDuration ?? this.currentDuration,
      pendingInterventions: pendingInterventions ?? this.pendingInterventions,
      phase: phase ?? this.phase,
      analysisResult: analysisResult ?? this.analysisResult,
    );
  }
}

/// Phases de la session d'histoire
enum StorySessionPhase {
  elementSelection,  // Sélection des 3 éléments
  narration,        // Narration en cours
  aiIntervention,   // Intervention IA
  analysis,         // Analyse en cours
  completed         // Histoire terminée
}

/// Badge spécifique aux histoires
@HiveType(typeId: 56)
enum StoryBadgeType {
  @HiveField(0)
  improvisationMaster,    // Maître de l'Improvisation
  @HiveField(1)
  aiCollaborator,         // Collaborateur IA
  @HiveField(2)
  librarian,              // Bibliothécaire
  @HiveField(3)
  popularStoryteller,     // Conteur Populaire
  @HiveField(4)
  narrativeLegend,        // Légende Narrative
  @HiveField(5)
  genreMaster,            // Maître d'un genre
  @HiveField(6)
  creativityChampion,     // Champion de Créativité
  @HiveField(7)
  fluentNarrator         // Narrateur Fluide
}

extension StoryBadgeTypeExtension on StoryBadgeType {
  String get displayName {
    switch (this) {
      case StoryBadgeType.improvisationMaster:
        return 'Maître de l\'Improvisation';
      case StoryBadgeType.aiCollaborator:
        return 'Collaborateur IA';
      case StoryBadgeType.librarian:
        return 'Bibliothécaire';
      case StoryBadgeType.popularStoryteller:
        return 'Conteur Populaire';
      case StoryBadgeType.narrativeLegend:
        return 'Légende Narrative';
      case StoryBadgeType.genreMaster:
        return 'Maître du Genre';
      case StoryBadgeType.creativityChampion:
        return 'Champion de Créativité';
      case StoryBadgeType.fluentNarrator:
        return 'Narrateur Fluide';
    }
  }

  String get emoji {
    switch (this) {
      case StoryBadgeType.improvisationMaster:
        return '🎭';
      case StoryBadgeType.aiCollaborator:
        return '🤖';
      case StoryBadgeType.librarian:
        return '📚';
      case StoryBadgeType.popularStoryteller:
        return '❤️';
      case StoryBadgeType.narrativeLegend:
        return '🏆';
      case StoryBadgeType.genreMaster:
        return '⭐';
      case StoryBadgeType.creativityChampion:
        return '💡';
      case StoryBadgeType.fluentNarrator:
        return '🗣️';
    }
  }

  String get description {
    switch (this) {
      case StoryBadgeType.improvisationMaster:
        return '10 histoires créées';
      case StoryBadgeType.aiCollaborator:
        return '50 suggestions IA acceptées';
      case StoryBadgeType.librarian:
        return '25 histoires sauvegardées';
      case StoryBadgeType.popularStoryteller:
        return '100 likes reçus';
      case StoryBadgeType.narrativeLegend:
        return 'Top 1% des créateurs';
      case StoryBadgeType.genreMaster:
        return 'Expert d\'un genre spécifique';
      case StoryBadgeType.creativityChampion:
        return 'Score créativité >90% sur 5 histoires';
      case StoryBadgeType.fluentNarrator:
        return 'Score fluidité >90% sur 5 histoires';
    }
  }

  int get requiredCount {
    switch (this) {
      case StoryBadgeType.improvisationMaster:
        return 10;
      case StoryBadgeType.aiCollaborator:
        return 50;
      case StoryBadgeType.librarian:
        return 25;
      case StoryBadgeType.popularStoryteller:
        return 100;
      case StoryBadgeType.narrativeLegend:
        return 1; // Top 1%
      case StoryBadgeType.genreMaster:
        return 5; // 5 histoires du même genre
      case StoryBadgeType.creativityChampion:
        return 5;
      case StoryBadgeType.fluentNarrator:
        return 5;
    }
  }
}

/// Collection de statistiques utilisateur pour les histoires
@HiveType(typeId: 57)
class StoryUserStats extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  int totalStories;
  
  @HiveField(2)
  int totalLikes;
  
  @HiveField(3)
  double averageCreativity;
  
  @HiveField(4)
  double averageCollaboration;
  
  @HiveField(5)
  double averageFluidity;
  
  @HiveField(6)
  int totalAIInterventionsUsed;
  
  @HiveField(7)
  Map<StoryGenre, int> genreStats;
  
  @HiveField(8)
  List<StoryBadgeType> unlockedBadges;
  
  @HiveField(9)
  DateTime lastStoryDate;
  
  @HiveField(10)
  int currentStreak;

  StoryUserStats({
    required this.userId,
    this.totalStories = 0,
    this.totalLikes = 0,
    this.averageCreativity = 0.0,
    this.averageCollaboration = 0.0,
    this.averageFluidity = 0.0,
    this.totalAIInterventionsUsed = 0,
    Map<StoryGenre, int>? genreStats,
    List<StoryBadgeType>? unlockedBadges,
    DateTime? lastStoryDate,
    this.currentStreak = 0,
  }) : genreStats = genreStats ?? {},
       unlockedBadges = unlockedBadges ?? [],
       lastStoryDate = lastStoryDate ?? DateTime.now();
}


/// Métriques audio détaillées
@HiveType(typeId: 59)
class AudioMetrics extends HiveObject {
  @HiveField(0)
  final double articulationScore;
  @HiveField(1)
  final double fluencyScore;
  @HiveField(2)
  final double emotionScore;
  @HiveField(3)
  final double volumeVariation;
  @HiveField(4)
  final double speakingRate;
  @HiveField(5)
  final List<String> fillerWords;

  AudioMetrics({
    required this.articulationScore,
    required this.fluencyScore,
    required this.emotionScore,
    required this.volumeVariation,
    required this.speakingRate,
    required this.fillerWords,
  });

  factory AudioMetrics.fromJson(Map<String, dynamic> json) {
    return AudioMetrics(
      articulationScore: (json['articulation_score'] as num? ?? 0.0).toDouble(),
      fluencyScore: (json['fluency_score'] as num? ?? 0.0).toDouble(),
      emotionScore: (json['emotion_score'] as num? ?? 0.0).toDouble(),
      volumeVariation: (json['volume_variation'] as num? ?? 0.0).toDouble(),
      speakingRate: (json['speaking_rate'] as num? ?? 0.0).toDouble(),
      fillerWords: List<String>.from(json['filler_words'] ?? []),
    );
  }
}

/// Analyse complète de la narration
@HiveType(typeId: 60)
class StoryNarrativeAnalysis extends HiveObject {
  @HiveField(0)
  final String storyId;
  @HiveField(1)
  final double overallScore;
  @HiveField(2)
  final double creativityScore;
  @HiveField(3)
  final double relevanceScore;
  @HiveField(4)
  final double structureScore;
  @HiveField(5)
  final String positiveFeedback;
  @HiveField(6)
  final String improvementSuggestions;
  @HiveField(7)
  final AudioMetrics audioMetrics;
  @HiveField(8)
  final String transcription;
  @HiveField(9)
  final String titleSuggestion;
  @HiveField(10)
  final List<String> detectedKeywords;

  StoryNarrativeAnalysis({
    required this.storyId,
    required this.overallScore,
    required this.creativityScore,
    required this.relevanceScore,
    required this.structureScore,
    required this.positiveFeedback,
    required this.improvementSuggestions,
    required this.audioMetrics,
    required this.transcription,
    required this.titleSuggestion,
    required this.detectedKeywords,
  });

  factory StoryNarrativeAnalysis.fromJson(Map<String, dynamic> json) {
    return StoryNarrativeAnalysis(
      storyId: json['story_id'] as String,
      overallScore: (json['overall_score'] as num? ?? 0.0).toDouble(),
      creativityScore: (json['creativity_score'] as num? ?? 0.0).toDouble(),
      relevanceScore: (json['relevance_score'] as num? ?? 0.0).toDouble(),
      structureScore: (json['structure_score'] as num? ?? 0.0).toDouble(),
      positiveFeedback: json['positive_feedback'] as String? ?? '',
      improvementSuggestions: json['improvement_suggestions'] as String? ?? '',
      audioMetrics: AudioMetrics.fromJson(json['audio_metrics'] as Map<String, dynamic>? ?? {}),
      transcription: json['transcription'] as String? ?? '',
      titleSuggestion: json['title_suggestion'] as String? ?? '',
      detectedKeywords: List<String>.from(json['detected_keywords'] ?? []),
    );
  }

  factory StoryNarrativeAnalysis.fallback() {
    return StoryNarrativeAnalysis(
      storyId: 'fallback_story_${DateTime.now().millisecondsSinceEpoch}',
      overallScore: 75.0,
      creativityScore: 80.0,
      relevanceScore: 70.0,
      structureScore: 78.0,
      positiveFeedback: "Excellente énergie ! Votre voix captive l'auditeur et on sent votre implication dans l'histoire.",
      improvementSuggestions: "Essayez de varier un peu plus le rythme de votre narration pour créer des moments de suspense.",
      audioMetrics: AudioMetrics(
        articulationScore: 85.0,
        fluencyScore: 90.0,
        emotionScore: 75.0,
        volumeVariation: 60.0,
        speakingRate: 150.0,
        fillerWords: ["euh", "donc"],
      ),
      transcription: "Ceci est une transcription de secours de votre histoire...",
      titleSuggestion: "Le Mystère de la Forêt Oubliée",
      detectedKeywords: ["forêt", "mystère", "trésor"],
    );
  }

  /// Crée un objet Story à partir de l'analyse et de la session
  factory StoryNarrativeAnalysis.fromSession(StoryExerciseSession session, Map<String, dynamic> analysisData) {
      final analysis = StoryNarrativeAnalysis.fromJson(analysisData);
      final interventions = session.currentStory?.aiInterventions ?? [];

      final metrics = StoryMetrics(
        creativity: analysis.creativityScore,
        collaboration: (interventions.where((i) => i.wasAccepted).length / math.max(1, interventions.length)) * 100,
        fluidity: analysis.audioMetrics.fluencyScore,
        totalDuration: session.currentDuration,
        wordCount: analysis.transcription.split(' ').where((s) => s.isNotEmpty).length,
        pauseCount: 0, // A remplir plus tard si disponible
        averagePauseDuration: 0.0, // A remplir plus tard si disponible
        aiInterventionsUsed: interventions.where((i) => i.wasAccepted).length,
      );

      // Note: This factory currently only creates the analysis part.
      // The calling service is responsible for creating the full Story object with these metrics.
      return analysis;
  }
}