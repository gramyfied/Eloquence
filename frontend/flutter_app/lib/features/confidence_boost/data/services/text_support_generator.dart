import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import 'mistral_api_service.dart';
import '../../../../core/utils/logger_service.dart';

class TextSupportGenerator {
  final MistralApiService _mistralService;
  static const String _tag = 'TextSupportGenerator';

  // Constructeur avec injection de dépendance obligatoire
  TextSupportGenerator({required MistralApiService mistralService})
      : _mistralService = mistralService;

  // Factory pour la production (avec service par défaut)
  factory TextSupportGenerator.create() {
    return TextSupportGenerator(mistralService: MistralApiService());
  }

  Future<TextSupport> generateSupport({
    required ConfidenceScenario scenario,
    required SupportType type,
    required String difficulty,
  }) async {
    try {
      logger.i(_tag, 'Génération support: ${type.name} pour ${scenario.title}');
      
      final prompt = _buildPrompt(scenario, type, difficulty);
      final generatedContent = await _mistralService.generateText(
        prompt: prompt,
        maxTokens: _getMaxTokens(type),
        temperature: _getTemperature(type),
      );

      final processedContent = _processGeneratedContent(generatedContent, type);
      final suggestedWords = _extractSuggestedWords(scenario, type);

      logger.i(_tag, 'Support généré avec succès: ${processedContent.length} caractères');
      
      return TextSupport(
        type: type,
        content: processedContent,
        suggestedWords: suggestedWords,
      );
    } catch (e) {
      logger.e(_tag, 'Erreur génération support: $e');
      // Fallback vers contenu pré-généré
      return _getFallbackSupport(scenario, type);
    }
  }

  String _buildPrompt(ConfidenceScenario scenario, SupportType type, String difficulty) {
    final baseContext = '''
Tu es un expert en coaching vocal et prise de parole publique. 

CONTEXTE DE L'EXERCICE:
- Scénario: ${scenario.title}
- Description: ${scenario.description}
- Niveau: $difficulty
- Mots-clés importants: ${scenario.keywords.join(', ')}
- Conseils contextuels: ${scenario.tips.join(' | ')}

OBJECTIF: Aider l'utilisateur à pratiquer sa confiance en prise de parole.
''';

    switch (type) {
      case SupportType.fullText:
        return '''$baseContext

TÂCHE: Génère un discours complet de 200-350 mots adapté à ce scénario.

EXIGENCES:
- Ton professionnel mais accessible
- Structure claire: introduction, développement, conclusion
- Intégration naturelle des mots-clés suggérés
- Adapté au niveau de difficulté "$difficulty"
- Phrases variées et vocabulaire approprié
- Transitions fluides entre les idées

IMPORTANT: Génère UNIQUEMENT le discours, sans préambule ni explication.

Discours:''';

      case SupportType.fillInBlanks:
        return '''$baseContext

TÂCHE: Génère un texte à trous de 150-250 mots pour cet exercice.

EXIGENCES:
- Remplace 8-12 mots stratégiques par [BLANK]
- Les blancs doivent cibler: mots-clés, connecteurs logiques, verbes d'action
- Texte cohérent même avec les blancs
- Structure logique maintenue
- Plusieurs réponses possibles pour certains blancs

FORMAT: Texte normal avec [BLANK] aux endroits appropriés.

IMPORTANT: Génère UNIQUEMENT le texte à trous, sans explication.

Texte à trous:''';

      case SupportType.guidedStructure:
        return '''$baseContext

TÂCHE: Génère une structure guidée détaillée pour ce scénario.

EXIGENCES:
- 4-6 points principaux numérotés
- 2-3 sous-points par section avec exemples concrets
- Phrases de transition suggérées
- Conseils spécifiques au scénario
- Progression logique des idées

FORMAT:
1. Point principal
   - Sous-point avec exemple
   - Transition suggérée: "..."

IMPORTANT: Génère UNIQUEMENT la structure, sans préambule.

Structure guidée:''';

      case SupportType.keywordChallenge:
        return '''$baseContext

TÂCHE: Sélectionne 6-8 mots-clés ou expressions que l'utilisateur DOIT intégrer.

EXIGENCES:
- Mots pertinents au scénario et niveau
- Mélange: vocabulaire technique, expressions idiomatiques, verbes d'action
- Défi approprié au niveau "$difficulty"
- Mots variés (noms, verbes, adjectifs, expressions)
- Utilisables naturellement dans un discours

FORMAT: Liste séparée par des virgules, sans numérotation.

IMPORTANT: Génère UNIQUEMENT la liste de mots-clés.

Mots-clés imposés:''';

      case SupportType.freeImprovisation:
        return '''$baseContext

TÂCHE: Génère des conseils de coaching pour une improvisation libre.

EXIGENCES:
- 4-5 conseils stratégiques spécifiques au scénario
- Techniques de gestion du stress
- Points d'attention sur le langage corporel
- Objectifs de performance mesurables
- Conseils adaptés au niveau "$difficulty"

FORMAT:
• Conseil pratique et actionnable
• Technique spécifique avec exemple

IMPORTANT: Génère UNIQUEMENT les conseils, sans introduction.

Conseils d'improvisation:''';
    }
  }

  int _getMaxTokens(SupportType type) {
    switch (type) {
      case SupportType.fullText: return 450;
      case SupportType.fillInBlanks: return 350;
      case SupportType.guidedStructure: return 400;
      case SupportType.keywordChallenge: return 80;
      case SupportType.freeImprovisation: return 300;
    }
  }

  double _getTemperature(SupportType type) {
    switch (type) {
      case SupportType.fullText: return 0.7;
      case SupportType.fillInBlanks: return 0.6;
      case SupportType.guidedStructure: return 0.5;
      case SupportType.keywordChallenge: return 0.8;
      case SupportType.freeImprovisation: return 0.7;
    }
  }

  String _processGeneratedContent(String content, SupportType type) {
    String processed = content.trim();
    
    // Supprimer les préfixes indésirables
    final prefixes = [
      'Discours:', 'Texte à trous:', 'Structure guidée:', 
      'Mots-clés imposés:', 'Conseils d\'improvisation:',
      'Voici', 'Voilà', 'Ci-dessous'
    ];
    
    for (final prefix in prefixes) {
      processed = processed.replaceAll(RegExp('^$prefix\\s*', caseSensitive: false), '');
    }
    
    // Nettoyer les sauts de ligne excessifs
    processed = processed.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Validation spécifique par type
    if (type == SupportType.fillInBlanks && !processed.contains('[BLANK]')) {
      // Si pas de blancs détectés, en ajouter quelques-uns
      processed = _addBlanksToText(processed);
    }
    
    return processed.trim();
  }

  String _addBlanksToText(String text) {
    // Ajouter des blancs sur des mots stratégiques si Mistral n'en a pas généré
    final words = text.split(' ');
    if (words.length < 10) return text;
    
    final strategicPositions = [
      words.length ~/ 4,
      words.length ~/ 2,
      (words.length * 3) ~/ 4,
    ];
    
    for (final pos in strategicPositions.reversed) {
      if (pos < words.length && words[pos].length > 3) {
        words[pos] = '[BLANK]';
      }
    }
    
    return words.join(' ');
  }

  List<String> _extractSuggestedWords(ConfidenceScenario scenario, SupportType type) {
    List<String> words = List.from(scenario.keywords);
    
    // Ajouter des mots contextuels selon le type
    switch (type) {
      case SupportType.fullText:
        words.addAll(['introduction', 'développement', 'conclusion']);
        break;
      case SupportType.fillInBlanks:
        words.addAll(['complétez', 'intégrez', 'adaptez']);
        break;
      case SupportType.guidedStructure:
        words.addAll(['premièrement', 'ensuite', 'finalement']);
        break;
      case SupportType.keywordChallenge:
        words.addAll(['défi', 'créativité', 'intégration']);
        break;
      case SupportType.freeImprovisation:
        words.addAll(['spontanéité', 'adaptation', 'fluidité']);
        break;
    }
    
    return words.take(6).toList();
  }

  TextSupport _getFallbackSupport(ConfidenceScenario scenario, SupportType type) {
    logger.w(_tag, 'Utilisation du contenu de secours pour ${type.name}');
    
    final fallbackContent = {
      SupportType.fullText: '''Mesdames et messieurs, je suis ravi de vous présenter aujourd'hui un projet qui me tient particulièrement à cœur. Cette initiative représente une opportunité unique de créer un impact positif et durable dans notre domaine. 

Permettez-moi de vous expliquer les enjeux principaux et les bénéfices concrets de cette démarche innovante. Grâce à une approche méthodique et à l'engagement de toute l'équipe, nous avons développé une solution qui répond aux défis actuels.

En conclusion, je suis convaincu que ce projet apportera une valeur ajoutée significative et contribuera à notre succès collectif.''',

      SupportType.fillInBlanks: '''Bonjour à tous, je suis [BLANK] de vous présenter les résultats de notre [BLANK] trimestre. Malgré quelques [BLANK] rencontrés, nous avons atteint [BLANK]% de nos objectifs grâce à [BLANK] et à l'engagement remarquable de toute l'équipe. Ces [BLANK] nous permettent d'envisager l'avenir avec [BLANK] et de nous projeter vers de nouveaux [BLANK] ambitieux.''',

      SupportType.guidedStructure: '''1. Introduction et contexte
   - Présentation personnelle et crédibilité
   - Annonce du plan de présentation
   - Transition: "Commençons par examiner..."

2. Présentation des enjeux principaux
   - Analyse de la situation actuelle
   - Identification des défis clés
   - Transition: "Face à ces constats..."

3. Solutions proposées et bénéfices
   - Présentation des recommandations
   - Avantages concrets et mesurables
   - Transition: "Pour conclure..."

4. Conclusion et prochaines étapes
   - Synthèse des points clés
   - Appel à l'action
   - Ouverture aux questions''',

      SupportType.keywordChallenge: 'innovation, performance, collaboration, excellence, impact, transformation, stratégie, résultats',

      SupportType.freeImprovisation: '''• Restez authentique et naturel dans votre expression
• Adaptez votre discours à votre audience en temps réel
• Utilisez des exemples concrets et des anecdotes personnelles
• Maintenez un contact visuel régulier avec l'audience
• Gérez votre respiration pour contrôler le stress
• Variez votre intonation pour maintenir l'attention
• Structurez vos idées avec des transitions claires''',
    };

    return TextSupport(
      type: type,
      content: fallbackContent[type] ?? 'Contenu de secours pour ${scenario.title}',
      suggestedWords: scenario.keywords.take(3).toList(),
    );
  }
}