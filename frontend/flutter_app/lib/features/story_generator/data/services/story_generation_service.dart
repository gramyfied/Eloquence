import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/story_models.dart';
import '../../../confidence_boost/domain/entities/virelangue_models.dart';
import '../../../confidence_boost/data/services/mistral_api_service.dart';
import 'story_prompt_templates_service.dart';
import '../../../../core/utils/logger_service.dart';

/// Service de génération d'éléments narratifs pour les histoires
class StoryGenerationService {
  static final StoryGenerationService _instance = StoryGenerationService._internal();
  factory StoryGenerationService() => _instance;
  StoryGenerationService._internal();

  final math.Random _random = math.Random();
  final IMistralApiService _mistralService = MistralApiService();
  final String _tag = 'StoryGenerationService';

  // Base de données des personnages
  static const List<Map<String, dynamic>> _characters = [
    {
      'name': 'Sorcier Mystérieux',
      'emoji': '🧙‍♂️',
      'description': 'Un vieux sorcier aux pouvoirs anciens',
      'difficulty': 0, // easy
      'keywords': ['magie', 'sortilège', 'baguette'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Princesse Courageuse',
      'emoji': '👸',
      'description': 'Une princesse qui n\'attend pas d\'être sauvée',
      'difficulty': 0,
      'keywords': ['courage', 'royaume', 'épée'],
      'genre': 6, // fairytale
    },
    {
      'name': 'Pirate Aventurier',
      'emoji': '🏴‍☠️',
      'description': 'Un capitaine pirate en quête de trésor',
      'difficulty': 1, // medium
      'keywords': ['trésor', 'navire', 'aventure'],
      'genre': 2, // adventure
    },
    {
      'name': 'Robot Futuriste',
      'emoji': '🤖',
      'description': 'Un androïde doté d\'intelligence artificielle',
      'difficulty': 1,
      'keywords': ['technologie', 'futur', 'intelligence'],
      'genre': 1, // science-fiction
    },
    {
      'name': 'Dragon Bienveillant',
      'emoji': '🐉',
      'description': 'Un grand dragon aux écailles dorées',
      'difficulty': 2, // hard
      'keywords': ['feu', 'vol', 'sagesse'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Détective Astucieux',
      'emoji': '🕵️',
      'description': 'Un enquêteur qui résout tous les mystères',
      'difficulty': 1,
      'keywords': ['enquête', 'indices', 'mystère'],
      'genre': 3, // mystery
    },
    {
      'name': 'Fée Malicieuse',
      'emoji': '🧚‍♀️',
      'description': 'Une petite fée pleine d\'espièglerie',
      'difficulty': 0,
      'keywords': ['magie', 'nature', 'malice'],
      'genre': 6, // fairytale
    },
    {
      'name': 'Chevalier Héroïque',
      'emoji': '⚔️',
      'description': 'Un brave chevalier défenseur des innocents',
      'difficulty': 1,
      'keywords': ['honneur', 'combat', 'protection'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Sorcière Mystique',
      'emoji': '🧙‍♀️',
      'description': 'Une enchanteresse aux potions magiques',
      'difficulty': 2,
      'keywords': ['potions', 'sortilèges', 'mystère'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Explorateur Spatial',
      'emoji': '👨‍🚀',
      'description': 'Un astronaute découvreur de mondes',
      'difficulty': 1,
      'keywords': ['espace', 'planète', 'découverte'],
      'genre': 1, // science-fiction
    },
  ];

  // Base de données des lieux
  static const List<Map<String, dynamic>> _locations = [
    {
      'name': 'Château Hanté',
      'emoji': '🏰',
      'description': 'Un vieux château plein de mystères',
      'difficulty': 1, // medium
      'keywords': ['fantôme', 'tour', 'donjon'],
      'genre': 5, // horror
    },
    {
      'name': 'Forêt Enchantée',
      'emoji': '🌲',
      'description': 'Une forêt magique aux arbres parlants',
      'difficulty': 0, // easy
      'keywords': ['nature', 'magie', 'animaux'],
      'genre': 6, // fairytale
    },
    {
      'name': 'Station Spatiale',
      'emoji': '🛸',
      'description': 'Une base flottant dans l\'espace',
      'difficulty': 2, // hard
      'keywords': ['technologie', 'étoiles', 'apesanteur'],
      'genre': 1, // science-fiction
    },
    {
      'name': 'Île au Trésor',
      'emoji': '🏝️',
      'description': 'Une île tropicale cachant des richesses',
      'difficulty': 1,
      'keywords': ['sable', 'palmier', 'trésor'],
      'genre': 2, // adventure
    },
    {
      'name': 'Laboratoire Secret',
      'emoji': '🧪',
      'description': 'Un laboratoire plein d\'expériences étranges',
      'difficulty': 2,
      'keywords': ['science', 'expérience', 'mystère'],
      'genre': 3, // mystery
    },
    {
      'name': 'Cirque Magique',
      'emoji': '🎪',
      'description': 'Un cirque où tout est possible',
      'difficulty': 0,
      'keywords': ['spectacle', 'magie', 'amusement'],
      'genre': 4, // comedy
    },
    {
      'name': 'Caverne de Cristal',
      'emoji': '💎',
      'description': 'Une grotte aux murs scintillants',
      'difficulty': 1,
      'keywords': ['cristal', 'lumière', 'écho'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Ville Flottante',
      'emoji': '☁️',
      'description': 'Une cité suspendue dans les nuages',
      'difficulty': 2,
      'keywords': ['nuages', 'altitude', 'merveille'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Désert de Sable',
      'emoji': '🏜️',
      'description': 'Un vaste désert aux dunes mouvantes',
      'difficulty': 1,
      'keywords': ['sable', 'soleil', 'oasis'],
      'genre': 2, // adventure
    },
    {
      'name': 'Manoir Victorien',
      'emoji': '🏚️',
      'description': 'Un ancien manoir aux secrets sombres',
      'difficulty': 2,
      'keywords': ['ancien', 'secret', 'mystère'],
      'genre': 5, // horror
    },
  ];

  // Base de données des objets magiques
  static const List<Map<String, dynamic>> _magicObjects = [
    {
      'name': 'Boule de Cristal',
      'emoji': '🔮',
      'description': 'Une sphère qui révèle l\'avenir',
      'difficulty': 1, // medium
      'keywords': ['voyance', 'avenir', 'magie'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Épée Légendaire',
      'emoji': '⚔️',
      'description': 'Une lame forgée par les dieux',
      'difficulty': 2, // hard
      'keywords': ['combat', 'légende', 'pouvoir'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Baguette Magique',
      'emoji': '🪄',
      'description': 'Un bâton concentrant la magie pure',
      'difficulty': 0, // easy
      'keywords': ['sortilège', 'incantation', 'magie'],
      'genre': 6, // fairytale
    },
    {
      'name': 'Clé Mystérieuse',
      'emoji': '🗝️',
      'description': 'Une clé ouvrant toutes les portes',
      'difficulty': 1,
      'keywords': ['ouverture', 'secret', 'accès'],
      'genre': 3, // mystery
    },
    {
      'name': 'Amulette Protectrice',
      'emoji': '🧿',
      'description': 'Un talisman contre le mal',
      'difficulty': 1,
      'keywords': ['protection', 'magie', 'défense'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Miroir Magique',
      'emoji': '🪞',
      'description': 'Un miroir qui ne ment jamais',
      'difficulty': 1,
      'keywords': ['vérité', 'reflet', 'réalité'],
      'genre': 6, // fairytale
    },
    {
      'name': 'Livre de Sorts',
      'emoji': '📜',
      'description': 'Un grimoire aux formules anciennes',
      'difficulty': 2,
      'keywords': ['savoir', 'sortilège', 'ancien'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Potion Mystique',
      'emoji': '🧪',
      'description': 'Une fiole aux effets imprévisibles',
      'difficulty': 1,
      'keywords': ['transformation', 'magie', 'surprise'],
      'genre': 0, // fantasy
    },
    {
      'name': 'Carte au Trésor',
      'emoji': '🗺️',
      'description': 'Un parchemin menant à la fortune',
      'difficulty': 0,
      'keywords': ['aventure', 'trésor', 'chemin'],
      'genre': 2, // adventure
    },
    {
      'name': 'Ring de Pouvoir',
      'emoji': '💍',
      'description': 'Un anneau aux pouvoirs immenses',
      'difficulty': 2,
      'keywords': ['pouvoir', 'corruption', 'magie'],
      'genre': 0, // fantasy
    },
  ];

  /// Génère 3 éléments aléatoirement (1 de chaque type)
  List<StoryElement> generateStoryElements() {
    final character = _generateRandomElement(StoryElementType.character);
    final location = _generateRandomElement(StoryElementType.location);
    final magicObject = _generateRandomElement(StoryElementType.magicObject);

    return [character, location, magicObject];
  }

  /// Génère des éléments selon un thème spécifique
  List<StoryElement> generateThemedElements(StoryGenre theme) {
    final filteredCharacters = _characters.where((c) => 
        c['genre'] == null || c['genre'] == theme.index).toList();
    final filteredLocations = _locations.where((l) => 
        l['genre'] == null || l['genre'] == theme.index).toList();
    final filteredObjects = _magicObjects.where((o) => 
        o['genre'] == null || o['genre'] == theme.index).toList();

    final character = _createElement(
      StoryElementType.character,
      filteredCharacters.isNotEmpty 
          ? filteredCharacters[_random.nextInt(filteredCharacters.length)]
          : _characters[_random.nextInt(_characters.length)]
    );

    final location = _createElement(
      StoryElementType.location,
      filteredLocations.isNotEmpty 
          ? filteredLocations[_random.nextInt(filteredLocations.length)]
          : _locations[_random.nextInt(_locations.length)]
    );

    final magicObject = _createElement(
      StoryElementType.magicObject,
      filteredObjects.isNotEmpty 
          ? filteredObjects[_random.nextInt(filteredObjects.length)]
          : _magicObjects[_random.nextInt(_magicObjects.length)]
    );

    return [character, location, magicObject];
  }

  /// Génère des éléments selon le niveau de difficulté utilisateur
  List<StoryElement> generateElementsByDifficulty(VirelangueDifficulty userLevel) {
    // Filtre les éléments par difficulté (max = niveau utilisateur)
    final maxDifficulty = userLevel.index;
    
    final suitableCharacters = _characters.where((c) => 
        c['difficulty'] <= maxDifficulty).toList();
    final suitableLocations = _locations.where((l) => 
        l['difficulty'] <= maxDifficulty).toList();
    final suitableObjects = _magicObjects.where((o) => 
        o['difficulty'] <= maxDifficulty).toList();

    final character = _createElement(
      StoryElementType.character,
      suitableCharacters.isNotEmpty 
          ? suitableCharacters[_random.nextInt(suitableCharacters.length)]
          : _characters.first
    );

    final location = _createElement(
      StoryElementType.location,
      suitableLocations.isNotEmpty 
          ? suitableLocations[_random.nextInt(suitableLocations.length)]
          : _locations.first
    );

    final magicObject = _createElement(
      StoryElementType.magicObject,
      suitableObjects.isNotEmpty 
          ? suitableObjects[_random.nextInt(suitableObjects.length)]
          : _magicObjects.first
    );

    return [character, location, magicObject];
  }

  /// Génère un élément aléatoire d'un type donné
  StoryElement _generateRandomElement(StoryElementType type) {
    List<Map<String, dynamic>> source;
    
    switch (type) {
      case StoryElementType.character:
        source = _characters;
        break;
      case StoryElementType.location:
        source = _locations;
        break;
      case StoryElementType.magicObject:
        source = _magicObjects;
        break;
    }

    final data = source[_random.nextInt(source.length)];
    return _createElement(type, data);
  }

  /// Crée un StoryElement à partir des données
  StoryElement _createElement(StoryElementType type, Map<String, dynamic> data) {
    return StoryElement(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      type: type,
      name: data['name'] as String,
      emoji: data['emoji'] as String,
      description: data['description'] as String,
      difficulty: VirelangueDifficulty.values[data['difficulty'] as int],
      keywords: List<String>.from(data['keywords'] as List),
      preferredGenre: data['genre'] != null 
          ? StoryGenre.values[data['genre'] as int]
          : null,
      isCustomGenerated: false,
    );
  }

  /// Obtient tous les éléments disponibles par type
  List<StoryElement> getAllElementsByType(StoryElementType type) {
    List<Map<String, dynamic>> source;
    
    switch (type) {
      case StoryElementType.character:
        source = _characters;
        break;
      case StoryElementType.location:
        source = _locations;
        break;
      case StoryElementType.magicObject:
        source = _magicObjects;
        break;
    }

    return source.map((data) => _createElement(type, data)).toList();
  }

  /// Génère des éléments personnalisés via notre backend API
  Future<List<StoryElement>> generateCustomElements({
    StoryGenre? theme,
    List<String>? keywords,
    VirelangueDifficulty difficulty = VirelangueDifficulty.medium,
  }) async {
    try {
      logger.i(_tag, 'Génération éléments personnalisés via backend API');
      logger.i(_tag, 'Paramètres: genre=$theme, difficulté=$difficulty, mots-clés=$keywords');
      
      // Préparer les données de la requête
      final requestData = {
        'genre': theme?.name,
        'difficulty': difficulty.name,
        'keywords': keywords ?? [],
        'count': 3,
      };
      
      // Appel à notre endpoint backend
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/story/generate-elements'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Parser la réponse de notre backend
        final elements = await _parseElementsFromBackendResponse(responseData);
        
        if (elements.isNotEmpty) {
          logger.i(_tag, 'Éléments générés avec succès: ${elements.length} éléments');
          return elements;
        } else {
          logger.w(_tag, 'Aucun élément généré, fallback vers éléments par défaut');
          return _generateFallbackElements(theme, difficulty);
        }
      } else {
        logger.e(_tag, 'Erreur HTTP ${response.statusCode}: ${response.body}');
        return _generateFallbackElements(theme, difficulty);
      }
      
    } catch (e) {
      logger.e(_tag, 'Erreur génération éléments personnalisés: $e');
      // En cas d'erreur, retour vers la génération par défaut
      return _generateFallbackElements(theme, difficulty);
    }
  }

  /// Obtient des éléments suggérés basés sur l'historique utilisateur
  List<StoryElement> getSuggestedElements({
    required List<Story> userHistory,
    required VirelangueDifficulty userLevel,
  }) {
    // Analyse l'historique pour suggérer de nouveaux éléments
    final usedElementIds = <String>{};
    final preferredGenres = <StoryGenre, int>{};

    for (final story in userHistory) {
      // Collecte les éléments déjà utilisés
      for (final element in story.elements) {
        usedElementIds.add(element.id);
      }
      
      // Analyse les genres préférés
      if (story.genre != null) {
        preferredGenres[story.genre!] = (preferredGenres[story.genre!] ?? 0) + 1;
      }
    }

    // Trouve le genre le plus utilisé
    StoryGenre? preferredGenre;
    if (preferredGenres.isNotEmpty) {
      preferredGenre = preferredGenres.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Génère des éléments selon les préférences
    List<StoryElement> candidates;
    if (preferredGenre != null) {
      candidates = generateThemedElements(preferredGenre);
    } else {
      candidates = generateElementsByDifficulty(userLevel);
    }

    // Filtre les éléments déjà utilisés récemment
    final recentlyUsed = userHistory.take(3)
        .expand((story) => story.elements.map((e) => e.id))
        .toSet();
    
    final filtered = candidates.where((element) => 
        !recentlyUsed.contains(element.id)).toList();

    return filtered.isNotEmpty ? filtered : candidates;
  }

  /// Valide qu'une combinaison d'éléments est cohérente
  bool validateElementCombination(List<StoryElement> elements) {
    if (elements.length != 3) return false;
    
    // Vérifie qu'on a bien un de chaque type
    final types = elements.map((e) => e.type).toSet();
    if (types.length != 3) return false;
    
    // Vérifie la cohérence des genres (optionnel)
    final genres = elements
        .where((e) => e.preferredGenre != null)
        .map((e) => e.preferredGenre!)
        .toSet();
    
    // Si on a des genres spécifiés, ils ne doivent pas être trop incompatibles
    if (genres.length > 2) return false;
    
    return true;
  }

  /// Obtient des statistiques sur les éléments disponibles
  Map<String, dynamic> getElementStatistics() {
    return {
      'total_characters': _characters.length,
      'total_locations': _locations.length,
      'total_magic_objects': _magicObjects.length,
      'difficulty_distribution': {
        'easy': _getAllElements().where((e) => e['difficulty'] == 0).length,
        'medium': _getAllElements().where((e) => e['difficulty'] == 1).length,
        'hard': _getAllElements().where((e) => e['difficulty'] == 2).length,
      },
      'genre_distribution': _calculateGenreDistribution(),
    };
  }

  List<Map<String, dynamic>> _getAllElements() {
    return [..._characters, ..._locations, ..._magicObjects];
  }

  Map<String, int> _calculateGenreDistribution() {
    final distribution = <String, int>{};
    for (final element in _getAllElements()) {
      if (element['genre'] != null) {
        final genre = StoryGenre.values[element['genre'] as int].displayName;
        distribution[genre] = (distribution[genre] ?? 0) + 1;
      }
    }
    return distribution;
  }

  /// Parse la réponse JSON de notre backend pour extraire les éléments narratifs
  Future<List<StoryElement>> _parseElementsFromBackendResponse(Map<String, dynamic> response) async {
    try {
      final elements = <StoryElement>[];
      
      // Notre backend retourne soit 'elements' soit 'generated_elements'
      final elementsData = (response['elements'] ?? response['generated_elements']) as List<dynamic>?;
      
      if (elementsData == null || elementsData.isEmpty) {
        logger.w(_tag, 'Aucun élément trouvé dans la réponse backend');
        return [];
      }
      
      for (final elementData in elementsData) {
        try {
          final elementMap = elementData as Map<String, dynamic>;
          final element = _createStoryElementFromBackendJson(elementMap);
          if (element != null) {
            elements.add(element);
          }
        } catch (e) {
          logger.w(_tag, 'Erreur parsing élément individuel: $e');
          continue; // Continue avec les autres éléments
        }
      }
      
      logger.i(_tag, 'Éléments parsés avec succès: ${elements.length}/${elementsData.length}');
      return elements;
      
    } catch (e) {
      logger.e(_tag, 'Erreur parsing réponse backend: $e');
      return [];
    }
  }

  /// Parse la réponse JSON de Mistral pour extraire les éléments narratifs (legacy)
  Future<List<StoryElement>> _parseElementsFromMistralResponse(Map<String, dynamic> response) async {
    try {
      final elements = <StoryElement>[];
      final elementsData = response['elements'] as List<dynamic>?;
      
      if (elementsData == null || elementsData.isEmpty) {
        logger.w(_tag, 'Aucun élément trouvé dans la réponse Mistral');
        return [];
      }
      
      for (final elementData in elementsData) {
        try {
          final elementMap = elementData as Map<String, dynamic>;
          final element = _createStoryElementFromJson(elementMap);
          if (element != null) {
            elements.add(element);
          }
        } catch (e) {
          logger.w(_tag, 'Erreur parsing élément individuel: $e');
          continue; // Continue avec les autres éléments
        }
      }
      
      logger.i(_tag, 'Éléments parsés avec succès: ${elements.length}/${elementsData.length}');
      return elements;
      
    } catch (e) {
      logger.e(_tag, 'Erreur parsing réponse Mistral: $e');
      return [];
    }
  }

  /// Crée un StoryElement à partir des données JSON de notre backend
  StoryElement? _createStoryElementFromBackendJson(Map<String, dynamic> data) {
    try {
      // Mapping des types d'éléments
      StoryElementType? elementType;
      switch (data['type']?.toString().toLowerCase()) {
        case 'character':
          elementType = StoryElementType.character;
          break;
        case 'location':
          elementType = StoryElementType.location;
          break;
        case 'magic_object':
        case 'magicobject':
          elementType = StoryElementType.magicObject;
          break;
        default:
          logger.w(_tag, 'Type d\'élément inconnu: ${data['type']}');
          return null;
      }
      
      // Extraction des données
      final name = data['name']?.toString() ?? 'Élément mystérieux';
      final emoji = data['emoji']?.toString() ?? '✨';
      final description = data['description']?.toString() ?? 'Un élément narratif unique';
      final keywords = List<String>.from(data['keywords'] ?? []);
      
      // Difficulté avec fallback - notre backend utilise des strings
      VirelangueDifficulty difficulty = VirelangueDifficulty.medium;
      if (data['difficulty'] != null) {
        try {
          final difficultyStr = data['difficulty'].toString().toLowerCase();
          switch (difficultyStr) {
            case 'easy':
              difficulty = VirelangueDifficulty.easy;
              break;
            case 'medium':
              difficulty = VirelangueDifficulty.medium;
              break;
            case 'hard':
              difficulty = VirelangueDifficulty.hard;
              break;
            case 'expert':
              difficulty = VirelangueDifficulty.expert;
              break;
          }
        } catch (e) {
          logger.w(_tag, 'Difficulté invalide, utilisation de medium par défaut');
        }
      }
      
      return StoryElement(
        id: '${elementType.name}_generated_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
        type: elementType,
        name: name,
        emoji: emoji,
        description: description,
        difficulty: difficulty,
        keywords: keywords,
        preferredGenre: null, // Sera défini par le contexte si nécessaire
        isCustomGenerated: true, // Marque comme généré par IA
      );
      
    } catch (e) {
      logger.e(_tag, 'Erreur création StoryElement: $e');
      return null;
    }
  }

  /// Crée un StoryElement à partir des données JSON de Mistral (legacy)
  StoryElement? _createStoryElementFromJson(Map<String, dynamic> data) {
    try {
      // Mapping des types d'éléments
      StoryElementType? elementType;
      switch (data['type']?.toString().toLowerCase()) {
        case 'character':
          elementType = StoryElementType.character;
          break;
        case 'location':
          elementType = StoryElementType.location;
          break;
        case 'magic_object':
        case 'magicobject':
          elementType = StoryElementType.magicObject;
          break;
        default:
          logger.w(_tag, 'Type d\'élément inconnu: ${data['type']}');
          return null;
      }
      
      // Extraction des données
      final name = data['name']?.toString() ?? 'Élément mystérieux';
      final emoji = data['emoji']?.toString() ?? '✨';
      final description = data['description']?.toString() ?? 'Un élément narratif unique';
      final keywords = List<String>.from(data['keywords'] ?? []);
      
      // Difficulté avec fallback
      VirelangueDifficulty difficulty = VirelangueDifficulty.medium;
      if (data['difficulty_level'] != null) {
        try {
          final difficultyIndex = int.parse(data['difficulty_level'].toString());
          if (difficultyIndex >= 0 && difficultyIndex < VirelangueDifficulty.values.length) {
            difficulty = VirelangueDifficulty.values[difficultyIndex];
          }
        } catch (e) {
          logger.w(_tag, 'Difficulté invalide, utilisation de medium par défaut');
        }
      }
      
      return StoryElement(
        id: '${elementType.name}_generated_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
        type: elementType,
        name: name,
        emoji: emoji,
        description: description,
        difficulty: difficulty,
        keywords: keywords,
        preferredGenre: null, // Sera défini par le contexte si nécessaire
        isCustomGenerated: true, // Marque comme généré par IA
      );
      
    } catch (e) {
      logger.e(_tag, 'Erreur création StoryElement: $e');
      return null;
    }
  }

  /// Génère des éléments de fallback en cas d'erreur Mistral
  List<StoryElement> _generateFallbackElements(StoryGenre? theme, VirelangueDifficulty difficulty) {
    logger.i(_tag, 'Génération éléments de fallback: theme=$theme, difficulté=$difficulty');
    
    if (theme != null) {
      // Utiliser la génération thématique existante
      return generateThemedElements(theme);
    } else {
      // Utiliser la génération par difficulté existante
      return generateElementsByDifficulty(difficulty);
    }
  }
}