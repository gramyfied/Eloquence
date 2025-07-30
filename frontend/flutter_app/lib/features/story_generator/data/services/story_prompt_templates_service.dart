import '../../domain/entities/story_models.dart';
import '../../../confidence_boost/domain/entities/virelangue_models.dart';

/// Service de gestion des templates de prompts pour la génération d'éléments narratifs
class StoryPromptTemplatesService {
  
  /// Génère un prompt pour créer des éléments narratifs personnalisés
  static String generateElementsPrompt({
    required StoryGenre? genre,
    required VirelangueDifficulty difficulty,
    required List<String>? keywords,
    required int elementsCount,
  }) {
    final genreContext = _getGenreContext(genre);
    final difficultyContext = _getDifficultyContext(difficulty);
    final keywordsContext = keywords?.isNotEmpty == true 
        ? '\n- Mots-clés à intégrer : ${keywords!.join(", ")}'
        : '';
    
    return '''
Tu es un créateur d'histoires spécialisé dans la génération d'éléments narratifs créatifs et cohérents.

MISSION : Génère exactement 3 éléments narratifs uniques :
1. UN PERSONNAGE principal
2. UN LIEU d'action  
3. UN OBJET MAGIQUE central

CONTRAINTES :
- Genre : ${genreContext.genreDescription}
- Niveau de difficulté : ${difficultyContext.description}
- Vocabulaire adapté : ${difficultyContext.vocabularyLevel}$keywordsContext

RÈGLES DE CRÉATION :
${genreContext.creationRules.map((rule) => '- $rule').join('\n')}

EXIGENCES TECHNIQUES :
- Chaque élément doit avoir un nom accrocheur (2-4 mots max)
- Description vivante et évocatrice (15-25 mots)
- Emoji représentatif pour chaque élément
- Cohérence entre les 3 éléments pour former une histoire potentielle
- Originalité : éviter les clichés trop répétitifs

RÉPONSE OBLIGATOIRE EN JSON :
{
  "elements": [
    {
      "type": "character",
      "name": "Nom du personnage",
      "emoji": "🧙‍♂️",
      "description": "Description captivante du personnage en 15-25 mots",
      "keywords": ["mot-clé1", "mot-clé2", "mot-clé3"],
      "difficulty_level": "${difficulty.index}"
    },
    {
      "type": "location", 
      "name": "Nom du lieu",
      "emoji": "🏰",
      "description": "Description immersive du lieu en 15-25 mots",
      "keywords": ["mot-clé1", "mot-clé2", "mot-clé3"],
      "difficulty_level": "${difficulty.index}"
    },
    {
      "type": "magic_object",
      "name": "Nom de l'objet magique", 
      "emoji": "🔮",
      "description": "Description mystérieuse de l'objet en 15-25 mots",
      "keywords": ["mot-clé1", "mot-clé2", "mot-clé3"],
      "difficulty_level": "${difficulty.index}"
    }
  ],
  "story_seed": "Phrase d'accroche décrivant comment ces 3 éléments pourraient s'articuler dans une histoire (20-30 mots)"
}

GÉNÈRE MAINTENANT ces 3 éléments uniques et cohérents !
''';
  }

  /// Génère un prompt pour un type d'élément spécifique
  static String generateSpecificElementPrompt({
    required StoryElementType elementType,
    required StoryGenre? genre,
    required VirelangueDifficulty difficulty,
    required List<String>? keywords,
    String? contextualHint,
  }) {
    final genreContext = _getGenreContext(genre);
    final difficultyContext = _getDifficultyContext(difficulty);
    final elementContext = _getElementTypeContext(elementType);
    final keywordsContext = keywords?.isNotEmpty == true 
        ? '\n- Mots-clés à intégrer : ${keywords!.join(", ")}'
        : '';
    final hintContext = contextualHint?.isNotEmpty == true
        ? '\n- Contexte narratif : $contextualHint'
        : '';
    
    return '''
Tu es un expert en création d'éléments narratifs pour histoires interactives.

MISSION : Crée UN ${elementContext.typeName} exceptionnel pour une histoire ${genreContext.genreDescription.toLowerCase()}.

SPÉCIFICATIONS DU ${elementContext.typeName.toUpperCase()} :
${elementContext.specifications.map((spec) => '- $spec').join('\n')}

CONTRAINTES :
- Genre : ${genreContext.genreDescription}
- Difficulté : ${difficultyContext.description}
- Vocabulaire : ${difficultyContext.vocabularyLevel}$keywordsContext$hintContext

INSPIRATION ${elementContext.typeName.toUpperCase()} :
${elementContext.inspirations.map((insp) => '- $insp').join('\n')}

RÉPONSE JSON OBLIGATOIRE :
{
  "element": {
    "type": "${elementType.name}",
    "name": "Nom créatif du ${elementContext.typeName} (2-4 mots)",
    "emoji": "${elementContext.defaultEmoji}",
    "description": "Description captivante et immersive (20-30 mots)",
    "keywords": ["mot-clé1", "mot-clé2", "mot-clé3", "mot-clé4"],
    "special_ability": "Pouvoir ou caractéristique unique (10-15 mots)",
    "story_potential": "Comment cet élément peut enrichir une narration (15-20 mots)",
    "difficulty_level": "${difficulty.index}",
    "genre_tags": ["${genre?.name ?? 'libre'}"]
  },
  "usage_suggestions": [
    "Suggestion d'utilisation narrative 1",
    "Suggestion d'utilisation narrative 2", 
    "Suggestion d'utilisation narrative 3"
  ]
}

CRÉE MAINTENANT ce ${elementContext.typeName} unique et mémorable !
''';
  }

  /// Obtient le contexte du genre
  static _GenreContext _getGenreContext(StoryGenre? genre) {
    switch (genre) {
      case StoryGenre.fantasy:
        return _GenreContext(
          genreDescription: 'Fantastique épique',
          creationRules: [
            'Intégrer des éléments magiques subtils mais présents',
            'Créer un univers cohérent avec ses propres règles',
            'Mélanger familier et extraordinaire de manière naturelle',
            'Privilégier l\'émerveillement et le mystère',
          ],
        );
      
      case StoryGenre.scienceFiction:
        return _GenreContext(
          genreDescription: 'Science-Fiction immersive',
          creationRules: [
            'Intégrer des technologies avancées mais plausibles',
            'Créer un futur cohérent et réfléchi',
            'Équilibrer innovation et humanité',
            'Privilégier l\'exploration et la découverte',
          ],
        );
      
      case StoryGenre.adventure:
        return _GenreContext(
          genreDescription: 'Aventure palpitante',
          creationRules: [
            'Créer des éléments orientés action et exploration',
            'Intégrer des défis et obstacles potentiels',
            'Privilégier le mouvement et la dynamique',
            'Favoriser l\'héroïsme et le courage',
          ],
        );
      
      case StoryGenre.mystery:
        return _GenreContext(
          genreDescription: 'Mystère intriguant',
          creationRules: [
            'Intégrer des éléments énigmatiques et ambigus',
            'Créer des indices subtils et des secrets',
            'Privilégier l\'atmosphère et la tension',
            'Favoriser la curiosité et la déduction',
          ],
        );
      
      case StoryGenre.comedy:
        return _GenreContext(
          genreDescription: 'Comédie divertissante',
          creationRules: [
            'Créer des éléments décalés et amusants',
            'Intégrer des situations cocasses potentielles',
            'Privilégier la légèreté et l\'humour',
            'Favoriser l\'originalité et la surprise',
          ],
        );
      
      case StoryGenre.horror:
        return _GenreContext(
          genreDescription: 'Horreur atmosphérique',
          creationRules: [
            'Créer une atmosphère inquiétante mais adaptée',
            'Intégrer des éléments mystérieux et sombres',
            'Privilégier la tension et le suspense',
            'Éviter la violence explicite, favoriser le psychologique',
          ],
        );
      
      case StoryGenre.fairytale:
        return _GenreContext(
          genreDescription: 'Conte merveilleux',
          creationRules: [
            'Créer des éléments magiques et bienveillants',
            'Intégrer des leçons de vie subtiles',
            'Privilégier l\'émerveillement et la poésie',
            'Favoriser les archétypes positifs et inspirants',
          ],
        );
      
      default:
        return _GenreContext(
          genreDescription: 'Histoire créative libre',
          creationRules: [
            'Créer des éléments originaux et polyvalents',
            'Intégrer de la diversité narrative',
            'Privilégier l\'adaptabilité et la créativité',
            'Favoriser l\'imagination sans contraintes spécifiques',
          ],
        );
    }
  }

  /// Obtient le contexte de difficulté
  static _DifficultyContext _getDifficultyContext(VirelangueDifficulty difficulty) {
    switch (difficulty) {
      case VirelangueDifficulty.easy:
        return _DifficultyContext(
          description: 'Facile - Vocabulaire simple et accessible',
          vocabularyLevel: 'Mots courants, phrases courtes, concepts familiers',
        );
      
      case VirelangueDifficulty.medium:
        return _DifficultyContext(
          description: 'Moyen - Vocabulaire enrichi avec nuances',
          vocabularyLevel: 'Mots variés, phrases élaborées, concepts intermédiaires',
        );
      
      case VirelangueDifficulty.hard:
        return _DifficultyContext(
          description: 'Difficile - Vocabulaire sophistiqué et riche',
          vocabularyLevel: 'Mots recherchés, phrases complexes, concepts avancés',
        );
      
      case VirelangueDifficulty.expert:
        return _DifficultyContext(
          description: 'Expert - Vocabulaire littéraire et technique',
          vocabularyLevel: 'Mots rares, phrases élaborées, concepts sophistiqués',
        );
    }
  }

  /// Obtient le contexte du type d'élément
  static _ElementTypeContext _getElementTypeContext(StoryElementType elementType) {
    switch (elementType) {
      case StoryElementType.character:
        return _ElementTypeContext(
          typeName: 'personnage',
          defaultEmoji: '🧙‍♂️',
          specifications: [
            'Personnalité distincte et mémorable',
            'Motivation claire et compréhensible',
            'Apparence évocatrice sans être stéréotypée',
            'Potentiel de développement narratif',
            'Trait distinctif qui le rend unique',
          ],
          inspirations: [
            'Héros de légendes avec une touche moderne',
            'Personnages archétypaux réinventés',
            'Professions inattendues dans des contextes fantastiques',
            'Contradictions intéressantes (ex: dragon végétarien)',
          ],
        );
      
      case StoryElementType.location:
        return _ElementTypeContext(
          typeName: 'lieu',
          defaultEmoji: '🏰',
          specifications: [
            'Atmosphère distinctive et immersive',
            'Caractéristiques visuelles marquantes',
            'Potentiel d\'action et d\'interaction',
            'Histoire ou mystère sous-jacent',
            'Éléments sensoriels (sons, odeurs, textures)',
          ],
          inspirations: [
            'Lieux familiers transformés par la magie',
            'Architectures impossibles ou oniriques',
            'Environnements naturels aux propriétés spéciales',
            'Espaces hybrides mélangeant plusieurs univers',
          ],
        );
      
      case StoryElementType.magicObject:
        return _ElementTypeContext(
          typeName: 'objet magique',
          defaultEmoji: '🔮',
          specifications: [
            'Pouvoir unique et bien défini',
            'Apparence distinctive et mémorable',
            'Origine mystérieuse ou intéressante',
            'Avantages ET limitations/contraintes',
            'Potentiel d\'évolution narrative',
          ],
          inspirations: [
            'Objets du quotidien aux pouvoirs extraordinaires',
            'Artefacts anciens aux secrets oubliés',
            'Créations magiques aux effets inattendus',
            'Objets symbiotiques qui évoluent avec leur utilisateur',
          ],
        );
    }
  }
}

/// Contexte de genre pour la génération
class _GenreContext {
  final String genreDescription;
  final List<String> creationRules;

  const _GenreContext({
    required this.genreDescription,
    required this.creationRules,
  });
}

/// Contexte de difficulté pour la génération  
class _DifficultyContext {
  final String description;
  final String vocabularyLevel;

  const _DifficultyContext({
    required this.description,
    required this.vocabularyLevel,
  });
}

/// Contexte de type d'élément pour la génération
class _ElementTypeContext {
  final String typeName;
  final String defaultEmoji;
  final List<String> specifications;
  final List<String> inspirations;

  const _ElementTypeContext({
    required this.typeName,
    required this.defaultEmoji,
    required this.specifications,
    required this.inspirations,
  });
}