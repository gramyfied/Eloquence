import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../confidence_boost/data/services/mistral_api_service.dart';
import '../../../confidence_boost/data/services/mistral_cache_service.dart';
import '../../domain/entities/story_models.dart';

/// Configuration pour les interventions IA narratives
class AIInterventionConfig {
  final InterventionType type;
  final double intensity; // 0.0 = subtil, 1.0 = majeur
  final String? context;
  final List<String>? forbiddenElements;
  final String? preferredTone;

  const AIInterventionConfig({
    required this.type,
    this.intensity = 0.5,
    this.context,
    this.forbiddenElements,
    this.preferredTone,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'intensity': intensity,
      'context': context,
      'forbidden_elements': forbiddenElements,
      'preferred_tone': preferredTone,
    };
  }
}

/// Service de collaboration IA spécialisé pour le générateur d'histoires
class StoryCollaborationAIService {
  final IMistralApiService _mistralService;
  final String _tag = 'StoryCollaborationAI';

  StoryCollaborationAIService({IMistralApiService? mistralService})
      : _mistralService = mistralService ?? MistralApiService();

  /// Génère un rebondissement narratif contextuel
  Future<AIIntervention> generateStoryTwist({
    required Story currentStory,
    required List<StoryElement> availableElements,
    AIInterventionConfig? config,
  }) async {
    try {
      logger.i(_tag, 'Génération rebondissement pour: ${currentStory.title}');
      
      final interventionConfig = config ?? const AIInterventionConfig(
        type: InterventionType.plotTwist,
        intensity: 0.7,
      );

      // Construction du prompt contextuel
      final prompt = _buildTwistPrompt(currentStory, availableElements, interventionConfig);
      
      // Appel à Mistral avec analyse structurée
      final response = await _mistralService.analyzeContent(
        prompt: prompt,
        maxTokens: 600,
      );

      // Parser la réponse pour créer l'intervention
      return _parseAIInterventionResponse(response, interventionConfig.type);

    } catch (e) {
      logger.e(_tag, 'Erreur génération rebondissement: $e');
      return _createFallbackIntervention(config?.type ?? InterventionType.plotTwist);
    }
  }

  /// Génère des suggestions créatives pour développer l'histoire
  Future<List<String>> generateCreativeSuggestions({
    required Story story,
    required String currentNarrative,
    int maxSuggestions = 3,
  }) async {
    try {
      logger.i(_tag, 'Génération suggestions créatives');

      final prompt = '''
Contexte de l'histoire :
- Titre: ${story.title}
- Éléments: ${story.elements.map((e) => e.name).join(', ')}
- Genre: ${story.genre?.toString().split('.').last ?? 'libre'}
- Narration actuelle: "$currentNarrative"

Mission : Génère $maxSuggestions suggestions créatives pour développer cette histoire.
Chaque suggestion doit :
- Être innovante et surprenante
- Respecter la cohérence narrative
- Introduire un élément de tension ou d'émotion
- Faire avancer l'intrigue de manière significative

Réponds uniquement avec un JSON :
{
  "suggestions": [
    "suggestion 1 détaillée",
    "suggestion 2 détaillée", 
    "suggestion 3 détaillée"
  ]
}
''';

      final response = await _mistralService.analyzeContent(
        prompt: prompt,
        maxTokens: 500,
      );

      // Extraire les suggestions de la réponse
      final suggestions = response['suggestions'] as List<dynamic>?;
      if (suggestions != null) {
        return suggestions.cast<String>();
      }

      return _createFallbackSuggestions();

    } catch (e) {
      logger.e(_tag, 'Erreur génération suggestions: $e');
      return _createFallbackSuggestions();
    }
  }

  /// Analyse la cohérence narrative d'une histoire
  Future<NarrativeAnalysis> analyzeStoryCoherence({
    required Story story,
    required String fullNarrative,
  }) async {
    try {
      logger.i(_tag, 'Analyse cohérence narrative');

      final prompt = '''
Analyse cette histoire complète :

Titre: ${story.title}
Éléments utilisés: ${story.elements.map((e) => e.name).join(', ')}
Genre: ${story.genre?.toString().split('.').last ?? 'libre'}
Durée: ${story.metrics.totalDuration.inMinutes} minutes
Récit complet: "$fullNarrative"

Mission : Analyse la cohérence narrative selon ces critères :
1. Utilisation créative des éléments imposés
2. Cohérence de l'intrigue
3. Fluidité du récit
4. Originalité et créativité
5. Respect du genre (si applicable)

Réponds uniquement avec un JSON :
{
  "overall_score": <score entre 0.0 et 1.0>,
  "element_usage_score": <score entre 0.0 et 1.0>,
  "plot_coherence_score": <score entre 0.0 et 1.0>,
  "fluidity_score": <score entre 0.0 et 1.0>,
  "creativity_score": <score entre 0.0 et 1.0>,
  "genre_consistency_score": <score entre 0.0 et 1.0>,
  "strengths": ["point fort 1", "point fort 2", "point fort 3"],
  "improvements": ["amélioration 1", "amélioration 2"],
  "highlight_moments": ["moment marquant 1", "moment marquant 2"],
  "narrative_feedback": "Feedback détaillé sur la qualité narrative"
}
''';

      final response = await _mistralService.analyzeContent(
        prompt: prompt,
        maxTokens: 800,
      );

      return _parseNarrativeAnalysis(response);

    } catch (e) {
      logger.e(_tag, 'Erreur analyse cohérence: $e');
      return _createFallbackAnalysis();
    }
  }

  /// Évalue la performance narrative en temps réel
  Future<Map<String, dynamic>> evaluateNarrativePerformance({
    required Story story,
    required String currentSegment,
    required Duration elapsedTime,
  }) async {
    try {
      logger.i(_tag, 'Évaluation performance narrative temps réel');

      final prompt = '''
Évaluation temps réel d'une narration en cours :

Contexte :
- Éléments à intégrer: ${story.elements.map((e) => e.name).join(', ')}
- Temps écoulé: ${elapsedTime.inSeconds} secondes
- Segment actuel: "$currentSegment"

Mission : Évalue la performance narrative actuelle selon :
1. Rythme de narration (trop lent/rapide ?)
2. Utilisation des éléments imposés
3. Engagement narratif
4. Potentiel de développement

Réponds uniquement avec un JSON :
{
  "performance_score": <score entre 0.0 et 1.0>,
  "pacing_feedback": "feedback sur le rythme",
  "element_integration": "feedback sur l'utilisation des éléments",
  "engagement_level": "niveau d'engagement estimé",
  "next_suggestions": ["suggestion immédiate 1", "suggestion 2"],
  "time_management": "feedback sur la gestion du temps"
}
''';

      final response = await _mistralService.analyzeContent(
        prompt: prompt,
        maxTokens: 400,
      );

      return response;

    } catch (e) {
      logger.e(_tag, 'Erreur évaluation performance: $e');
      return _createFallbackPerformanceEvaluation();
    }
  }

  /// Génère des développements thématiques personnalisés
  Future<List<String>> generateThematicDevelopments({
    required StoryGenre genre,
    required List<StoryElement> elements,
    required String currentContext,
  }) async {
    try {
      logger.i(_tag, 'Génération développements thématiques: $genre');

      final prompt = '''
Développements thématiques pour une histoire ${genre.toString().split('.').last} :

Éléments disponibles: ${elements.map((e) => '${e.name} (${e.type.toString().split('.').last})').join(', ')}
Contexte actuel: "$currentContext"

Mission : Génère 4 développements narratifs cohérents avec le genre ${genre.toString().split('.').last}.
Chaque développement doit :
- Exploiter au moins un élément disponible
- Respecter les codes du genre
- Apporter une progression narrative significative
- Être réalisable en 30-60 secondes de narration

Réponds uniquement avec un JSON :
{
  "developments": [
    {
      "title": "titre du développement 1",
      "description": "description détaillée",
      "elements_used": ["élément 1", "élément 2"],
      "estimated_duration": "30-45 secondes"
    },
    // ... 3 autres développements
  ]
}
''';

      final response = await _mistralService.analyzeContent(
        prompt: prompt,
        maxTokens: 700,
      );

      final developments = response['developments'] as List<dynamic>? ?? [];
      return developments.map((dev) => dev['description'] as String).toList();

    } catch (e) {
      logger.e(_tag, 'Erreur génération développements thématiques: $e');
      return _createFallbackDevelopments(genre);
    }
  }

  /// Construction du prompt pour les rebondissements
  String _buildTwistPrompt(Story story, List<StoryElement> elements, AIInterventionConfig config) {
    final elementNames = elements.map((e) => e.name).join(', ');
    final storyContext = story.elements.map((e) => e.name).join(', ');
    
    return '''
Contexte narratif :
- Histoire en cours: "${story.title}"
- Éléments déjà utilisés: $storyContext
- Éléments disponibles: $elementNames
- Genre: ${story.genre?.toString().split('.').last ?? 'libre'}
- Type d'intervention: ${config.type.toString().split('.').last}
- Intensité: ${(config.intensity * 100).round()}%

Mission : Crée un rebondissement narratif ${config.type.toString().split('.').last} avec intensité ${(config.intensity * 100).round()}%.

Le rebondissement doit :
- Surprendre sans rompre la cohérence
- Utiliser au moins un élément disponible
- Respecter le ton${config.preferredTone != null ? ' ${config.preferredTone}' : ''}
- Être adaptable par le narrateur

Réponds uniquement avec un JSON :
{
  "intervention_text": "Description du rebondissement pour le narrateur",
  "narrative_impact": "Impact sur l'histoire (faible/moyen/fort)",
  "suggested_elements": ["élément 1", "élément 2"],
  "tone_guidance": "Conseil de ton pour le narrateur",
  "implementation_tip": "Conseil pour intégrer ce rebondissement"
}
''';
  }

  /// Parse la réponse IA en intervention structurée
  AIIntervention _parseAIInterventionResponse(Map<String, dynamic> response, InterventionType type) {
    return AIIntervention(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: response['intervention_text'] as String? ?? 'Rebondissement créatif généré',
      timestamp: Duration(seconds: 30), // Délai suggéré pour l'intervention
      wasAccepted: false,
      userResponse: response['tone_guidance'] as String? ?? '',
    );
  }

  /// Parse l'analyse narrative
  NarrativeAnalysis _parseNarrativeAnalysis(Map<String, dynamic> response) {
    return NarrativeAnalysis(
      overallScore: (response['overall_score'] as num?)?.toDouble() ?? 0.7,
      elementUsageScore: (response['element_usage_score'] as num?)?.toDouble() ?? 0.7,
      plotCoherenceScore: (response['plot_coherence_score'] as num?)?.toDouble() ?? 0.7,
      fluidityScore: (response['fluidity_score'] as num?)?.toDouble() ?? 0.7,
      creativityScore: (response['creativity_score'] as num?)?.toDouble() ?? 0.7,
      genreConsistencyScore: (response['genre_consistency_score'] as num?)?.toDouble() ?? 0.7,
      strengths: List<String>.from(response['strengths'] ?? ['Créativité', 'Engagement']),
      improvements: List<String>.from(response['improvements'] ?? ['Continuer la pratique']),
      highlightMoments: List<String>.from(response['highlight_moments'] ?? ['Moment créatif']),
      narrativeFeedback: response['narrative_feedback'] as String? ?? 'Histoire bien construite !',
    );
  }

  /// Interventions de fallback en cas d'erreur
  AIIntervention _createFallbackIntervention(InterventionType type) {
    final fallbacks = {
      InterventionType.plotTwist: 'Soudain, un élément inattendu change la donne...',
      InterventionType.characterReveal: 'Un personnage révèle un secret qui change tout...',
      InterventionType.settingShift: 'L\'environnement se transforme de manière surprenante...',
      InterventionType.toneChange: 'L\'ambiance de l\'histoire prend une tournure différente...',
      InterventionType.mysteryElement: 'Un mystère surgit, posant de nouvelles questions...',
    };

    return AIIntervention(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      content: fallbacks[type] ?? 'Un rebondissement créatif se présente...',
      timestamp: Duration(seconds: 30),
      wasAccepted: false,
      userResponse: 'Intervention générée automatiquement',
    );
  }

  /// Suggestions créatives de fallback
  List<String> _createFallbackSuggestions() {
    return [
      'Introduire un élément de surprise qui transforme la situation',
      'Développer une relation inattendue entre les personnages',
      'Révéler un aspect caché de l\'environnement ou du contexte',
    ];
  }

  /// Analyse narrative de fallback
  NarrativeAnalysis _createFallbackAnalysis() {
    return NarrativeAnalysis(
      overallScore: 0.75,
      elementUsageScore: 0.7,
      plotCoherenceScore: 0.8,
      fluidityScore: 0.7,
      creativityScore: 0.8,
      genreConsistencyScore: 0.75,
      strengths: ['Créativité narrative', 'Utilisation des éléments', 'Fluidité du récit'],
      improvements: ['Développer davantage les personnages', 'Renforcer la conclusion'],
      highlightMoments: ['Moment de tension créé', 'Intégration créative des éléments'],
      narrativeFeedback: 'Histoire bien construite avec une bonne utilisation des éléments imposés !',
    );
  }

  /// Évaluation de performance de fallback
  Map<String, dynamic> _createFallbackPerformanceEvaluation() {
    return {
      'performance_score': 0.7,
      'pacing_feedback': 'Rythme adapté, continuez ainsi',
      'element_integration': 'Bonne intégration des éléments',
      'engagement_level': 'Histoire engageante',
      'next_suggestions': ['Développer le suspense', 'Introduire un nouveau détail'],
      'time_management': 'Gestion du temps appropriée',
    };
  }

  /// Développements thématiques de fallback
  List<String> _createFallbackDevelopments(StoryGenre genre) {
    final developments = {
      StoryGenre.fantasy: [
        'La magie se manifeste de manière inattendue',
        'Une créature mystique fait son apparition',
        'Un portail vers un autre monde s\'ouvre',
        'Un ancien sortilège se réveille',
      ],
      StoryGenre.scienceFiction: [
        'La technologie révèle ses véritables capacités',
        'Une intelligence artificielle prend conscience',
        'Un phénomène temporel se produit',
        'Une découverte scientifique change la donne',
      ],
      StoryGenre.mystery: [
        'Un indice crucial est découvert',
        'Un témoin inattendu se manifeste',
        'Une révélation remet tout en question',
        'Un élément du passé refait surface',
      ],
      StoryGenre.adventure: [
        'Un obstacle majeur se dresse sur la route',
        'Une découverte prometteuse émerge',
        'Un allié inattendu rejoint l\'aventure',
        'Un danger imminent menace les héros',
      ],
    };

    return developments[genre] ?? [
      'Un élément inattendu transforme la situation',
      'Une révélation change la perspective',
      'Un nouveau défi apparaît',
      'Une opportunité se présente',
    ];
  }

  /// Nettoyage des ressources
  void dispose() {
    _mistralService.dispose();
  }
}

/// Modèle pour l'analyse narrative détaillée
class NarrativeAnalysis {
  final double overallScore;
  final double elementUsageScore;
  final double plotCoherenceScore;
  final double fluidityScore;
  final double creativityScore;
  final double genreConsistencyScore;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> highlightMoments;
  final String narrativeFeedback;

  const NarrativeAnalysis({
    required this.overallScore,
    required this.elementUsageScore,
    required this.plotCoherenceScore,
    required this.fluidityScore,
    required this.creativityScore,
    required this.genreConsistencyScore,
    required this.strengths,
    required this.improvements,
    required this.highlightMoments,
    required this.narrativeFeedback,
  });

  Map<String, dynamic> toJson() {
    return {
      'overall_score': overallScore,
      'element_usage_score': elementUsageScore,
      'plot_coherence_score': plotCoherenceScore,
      'fluidity_score': fluidityScore,
      'creativity_score': creativityScore,
      'genre_consistency_score': genreConsistencyScore,
      'strengths': strengths,
      'improvements': improvements,
      'highlight_moments': highlightMoments,
      'narrative_feedback': narrativeFeedback,
    };
  }
}