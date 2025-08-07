import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/config/app_config.dart'; // Importer AppConfig
import '../../../../core/utils/logger_service.dart';
import '../../../../core/services/optimized_http_service.dart';
import 'mistral_cache_service.dart';

abstract class IMistralApiService {
  Future<String> generateText({
    required String prompt,
    int? maxTokens,
    double? temperature,
  });

  Future<Map<String, dynamic>> analyzeContent({
    required String prompt,
    int? maxTokens,
  });

  Map<String, dynamic> getCacheStatistics();
  Future<void> clearCache();
  Future<void> preloadCommonPrompts();
  void dispose();
}

class MistralApiService implements IMistralApiService {
  final OptimizedHttpService _httpService;
  final String _endpoint;
  final String _model;
  final String _apiKey;
  final bool _isEnabled;
  final String _tag = 'MistralApiService';

  MistralApiService({OptimizedHttpService? httpService})
      : _httpService = httpService ?? OptimizedHttpService(),
        // Utilise AppConfig.mistralBaseUrl au lieu de dotenv
        _endpoint = AppConfig.mistralBaseUrl,
        _model = dotenv.env['MISTRAL_MODEL'] ?? 'mistral-nemo-instruct-2407',
        _apiKey = dotenv.env['MISTRAL_API_KEY'] ?? '',
        _isEnabled = dotenv.env['MISTRAL_ENABLED']?.toLowerCase() == 'true';

  /// Initialise le service (incluant le cache)
  static Future<void> init() async {
    logger.i('MistralApiService', 'Initialisation du service Mistral...');
    await MistralCacheService.init();
  }

  @override
  Future<String> generateText({
    required String prompt,
    int? maxTokens = 500,
    double? temperature = 0.7,
  }) async {
    // === CACHE CHECK PRIORITAIRE POUR PERFORMANCE MOBILE ===
    final cachedResult = await MistralCacheService.getCachedResponse(
      prompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
    
    if (cachedResult != null) {
      return cachedResult; // Retour instantané depuis le cache !
    }
    
    // Vérifier si Mistral est activé
    if (!_isEnabled) {
      logger.i(_tag, 'Mistral désactivé, utilisation des sujets fallback créatifs');
      
      // Collection de 30 sujets hilarants et complètement absurdes pour le Tribunal des Idées Impossibles
      final fallbackTopics = [
        'Les licornes devraient-elles passer un permis de vol avant de voler ?',
        'Faut-il créer un syndicat pour défendre les droits des monstres sous le lit ?',
        'Les pizza hawaïennes constituent-elles un crime contre l\'humanité ?',
        'Est-ce que les poissons rouges ont le droit de changer de couleur par caprice ?',
        'Faut-il instaurer une taxe sur les mauvaises blagues de papa ?',
        'Les zombies devraient-ils avoir accès à la sécurité sociale ?',
        'Est-il légal pour les chats de nous ignorer aussi ouvertement ?',
        'Faut-il créer des feux de circulation pour les fourmis en file indienne ?',
        'Les extraterrestres ont-ils l\'obligation de déclarer leurs visites aux impôts ?',
        'Doit-on poursuivre en justice les nuages qui cachent le soleil le weekend ?',
        'Les plantes carnivores méritent-elles une pension alimentaire ?',
        'Faut-il interdire aux vampires de critiquer les films de vampire ?',
        'Est-ce que les kangourous peuvent être poursuivis pour excès de vitesse ?',
        'Les dragons devraient-ils avoir une assurance incendie obligatoire ?',
        'Faut-il créer un permis de conduire spécial pour les sorcières sur balai ?',
        'Les fantômes ont-ils le droit de hanter sans autorisation municipale ?',
        'Est-il légal pour les pingouins de porter un smoking sans cravate ?',
        'Faut-il instaurer un couvre-feu pour les monstres du placard ?',
        'Les sirènes devraient-elles avoir une licence pour chanter sous l\'eau ?',
        'Est-ce que les robots ont le droit de tomber en panne volontairement ?',
        'Faut-il poursuivre les magiciens qui font vraiment disparaître les objets ?',
        'Les centaures peuvent-ils conduire ou sont-ils déjà des véhicules ?',
        'Est-il légal de nourrir les trolls de pont sans permis de restauration ?',
        'Faut-il créer des toilettes publiques pour les géants ?',
        'Les elfes devraient-ils payer des impôts sur la magie qu\'ils utilisent ?',
        'Est-ce que les yétis ont besoin d\'un certificat médical pour hiberner ?',
        'Faut-il interdire aux sorcières de voler en état d\'ébriété ?',
        'Les aliens peuvent-ils être expulsés pour séjour irrégulier sur Terre ?',
        'Est-il légal pour les dinosaures de revenir sans visa temporel ?',
        'Faut-il créer un code de la route pour les tapis volants en ville ?',
      ];
      
      // Sélectionner un sujet aléatoire basé sur le timestamp + hash du prompt
      final randomIndex = (DateTime.now().millisecondsSinceEpoch + prompt.hashCode) % fallbackTopics.length;
      final simulatedResult = fallbackTopics[randomIndex];
      
      await MistralCacheService.cacheResponse(
        prompt,
        simulatedResult,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      return simulatedResult;
    }
    
    // Vérifier si la clé API est présente
    if (_apiKey.isEmpty || _apiKey == 'your_mistral_api_key') {
      logger.w(_tag, 'Clé API Mistral invalide, utilisation du feedback simulé');
      const simulatedResult = 'Feedback simulé: Très bonne performance ! Votre élocution était claire et votre message était bien structuré.';
      await MistralCacheService.cacheResponse(
        prompt,
        simulatedResult,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      return simulatedResult;
    }
    
    try {
      logger.i(_tag, 'Appel API Mistral: $_endpoint');
      
      // Utilisation du service HTTP optimisé pour bénéficier automatiquement de :
      // - Pool de connexions persistantes
      // - Compression gzip
      // - Retry logic avec backoff exponentiel
      // - Timeouts optimisés
      final response = await _httpService.post(
        _endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
          'stream': false, // Pas de streaming pour l'instant
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['choices']?[0]?['message']?['content'] ?? '';
        
        // Mettre en cache la réponse réussie
        await MistralCacheService.cacheResponse(
          prompt,
          result,
          maxTokens: maxTokens,
          temperature: temperature,
          metadata: {
            'model': _model,
            'tokens_used': data['usage']?['total_tokens'] ?? 0,
          },
        );
        
        return result;
      } else {
        logger.e(_tag, 'Erreur API Mistral: ${response.statusCode} - ${response.body}');
        // En cas d'erreur API, retourner un feedback de fallback
        const fallbackResult = 'Feedback simulé: Performance solide ! Votre présentation était engageante et bien articulée.';
        await MistralCacheService.cacheResponse(
          prompt,
          fallbackResult,
          maxTokens: maxTokens,
          temperature: temperature,
        );
        return fallbackResult;
      }
    } catch (e) {
      logger.e(_tag, 'Erreur communication Mistral: $e');
      // En cas d'exception, retourner un feedback de fallback
      const exceptionResult = 'Feedback simulé: Bonne prestation ! Votre confiance transparaît dans votre façon de vous exprimer.';
      await MistralCacheService.cacheResponse(
        prompt,
        exceptionResult,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      return exceptionResult;
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeContent({
    required String prompt,
    int? maxTokens = 800,
  }) async {
    // === CACHE CHECK PRIORITAIRE POUR ANALYSES RÉPÉTÉES ===
    final cachedResult = await MistralCacheService.getCachedResponse(
      prompt,
      maxTokens: maxTokens,
      temperature: 0.7,
    );
    
    if (cachedResult != null) {
      // Tenter de parser le JSON depuis le cache
      try {
        return jsonDecode(cachedResult) as Map<String, dynamic>;
      } catch (e) {
        // Si ce n'est pas du JSON, créer une structure
        return {
          'content_score': 0.75,
          'feedback': cachedResult,
          'strengths': ['Expression naturelle'],
          'improvements': ['Continuer la pratique'],
          'cached': true,
        };
      }
    }
    
    // Vérifier si Mistral est activé
    if (!_isEnabled) {
      logger.i(_tag, 'Mistral désactivé, utilisation de l\'analyse simulée');
      const simulatedAnalysis = {
        'content_score': 0.8,
        'feedback': 'Analyse simulée: Excellente présentation ! Votre ton était confiant et votre message était clair.',
        'strengths': ['Clarté du message', 'Confiance dans le ton', 'Structure cohérente'],
        'improvements': ['Continuer la pratique régulière', 'Explorer de nouveaux sujets'],
      };
      await MistralCacheService.cacheResponse(
        prompt,
        jsonEncode(simulatedAnalysis),
        maxTokens: maxTokens,
        temperature: 0.7,
      );
      return simulatedAnalysis;
    }
    
    // Vérifier si la clé API est présente
    if (_apiKey.isEmpty || _apiKey == 'your_mistral_api_key') {
      logger.w(_tag, 'Clé API Mistral invalide, utilisation de l\'analyse simulée');
      const fallbackAnalysis = {
        'content_score': 0.75,
        'feedback': 'Analyse simulée: Très bonne performance ! Votre expression était naturelle et engageante.',
        'strengths': ['Expression naturelle', 'Engagement du public', 'Gestion du stress'],
        'improvements': ['Travailler la gestuelle', 'Varier l\'intonation'],
      };
      await MistralCacheService.cacheResponse(
        prompt,
        jsonEncode(fallbackAnalysis),
        maxTokens: maxTokens,
        temperature: 0.7,
      );
      return fallbackAnalysis;
    }
    
    try {
      logger.i(_tag, 'Analyse avec Mistral: $_endpoint');
      
      // Prompt structuré pour obtenir une réponse JSON
      final structuredPrompt = '''
$prompt

Réponds uniquement avec un objet JSON valide contenant ces champs :
{
  "content_score": <nombre entre 0 et 1>,
  "feedback": "<texte de feedback>",
  "strengths": ["<point fort 1>", "<point fort 2>", ...],
  "improvements": ["<amélioration 1>", "<amélioration 2>", ...]
}
''';
      
      // Utilisation du service HTTP optimisé pour l'analyse
      final response = await _httpService.post(
        _endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': structuredPrompt,
            }
          ],
          'max_tokens': maxTokens,
          'temperature': 0.7,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysisText = data['choices']?[0]?['message']?['content'] ?? '{}';
        
        // Tenter de parser le JSON de l'analyse
        try {
          final parsedResult = jsonDecode(analysisText) as Map<String, dynamic>;
          
          // Mettre en cache le résultat JSON
          await MistralCacheService.cacheResponse(
            prompt,
            jsonEncode(parsedResult),
            maxTokens: maxTokens,
            temperature: 0.7,
            metadata: {
              'model': _model,
              'tokens_used': data['usage']?['total_tokens'] ?? 0,
            },
          );
          
          return parsedResult;
        } catch (e) {
          logger.w(_tag, 'Erreur parsing JSON de l\'analyse: $e');
          // Si le parsing JSON échoue, créer une structure de base
          final fallbackStructure = {
            'content_score': 0.7,
            'feedback': analysisText,
            'strengths': ['Expression naturelle'],
            'improvements': ['Continuer la pratique'],
          };
          
          await MistralCacheService.cacheResponse(
            prompt,
            jsonEncode(fallbackStructure),
            maxTokens: maxTokens,
            temperature: 0.7,
          );
          
          return fallbackStructure;
        }
      } else {
        logger.e(_tag, 'Erreur API Mistral: ${response.statusCode} - ${response.body}');
        // En cas d'erreur API, retourner une analyse de fallback
        final apiErrorResult = {
          'content_score': 0.7,
          'feedback': 'Analyse simulée: Performance satisfaisante ! Votre présentation montrait de la préparation.',
          'strengths': ['Préparation visible', 'Effort d\'articulation'],
          'improvements': ['Continuer l\'entraînement', 'Renforcer la confiance'],
        };
        await MistralCacheService.cacheResponse(
          prompt,
          jsonEncode(apiErrorResult),
          maxTokens: maxTokens,
          temperature: 0.7,
        );
        return apiErrorResult;
      }
    } catch (e) {
      logger.e(_tag, 'Erreur analyse Mistral: $e');
      // En cas d'exception, retourner une analyse de fallback
      final exceptionResult = {
        'content_score': 0.65,
        'feedback': 'Analyse simulée: Bonne tentative ! Chaque pratique vous aide à progresser.',
        'strengths': ['Courage de pratiquer', 'Volonté d\'amélioration'],
        'improvements': ['Persévérer dans l\'entraînement', 'Gagner en assurance'],
      };
      await MistralCacheService.cacheResponse(
        prompt,
        jsonEncode(exceptionResult),
        maxTokens: maxTokens,
        temperature: 0.7,
      );
      return exceptionResult;
    }
  }
  
  @override
  Map<String, dynamic> getCacheStatistics() {
    return MistralCacheService.getStatistics();
  }
  
  @override
  Future<void> clearCache() async {
    await MistralCacheService.clearCache();
  }
  
  @override
  Future<void> preloadCommonPrompts() async {
    final commonPrompts = [
      'Analyse ma présentation orale et donne-moi un feedback constructif',
      'Évalue ma confiance en prise de parole publique',
      'Comment puis-je améliorer ma présentation ?',
      'Quels sont mes points forts en communication orale ?',
    ];
    
    await MistralCacheService.preloadCommonPrompts(commonPrompts);
  }
  
  @override
  void dispose() {
    // Le service HTTP optimisé gère automatiquement ses ressources
    // via le pattern Singleton, pas besoin de close explicite
  }
}