import 'dart:convert';
import 'dart:async'; // Ajout de l'import pour StreamController
import 'dart:typed_data'; // Import pour Uint8List
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart'; // Supprimé car non utilisé
import '../../core/config/app_config.dart';
import '../../core/config/mobile_timeout_constants.dart'; // ✅ Import timeouts mobiles
import '../../core/utils/logger_service.dart';
import '../models/scenario_model.dart';
import '../models/session_model.dart';
// import 'package:flutter/foundation.dart'; // Supprimé car non utilisé

class ApiService {
  static const String _tag = 'ApiService';

  final String baseUrl;
  final String? authToken; // Token d'authentification
  final String? apiKey; // Clé API rendue optionnelle

  ApiService({String? baseUrl, this.authToken, this.apiKey}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl {
    logger.i(_tag, 'Service API initialisé avec URL: $baseUrl');
  }

  // Construire les en-têtes HTTP avec authentification si disponible
  Map<String, String> get headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!; // Utiliser la clé API configurable si elle existe
      logger.i(_tag, '🔑 Clé API utilisée dans les en-têtes: $apiKey');
    } else {
      logger.i(_tag, '🔑 Aucune clé API spécifiée ou elle est vide.');
    }

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
      logger.v(_tag, 'En-têtes avec authentification');
    } else {
      logger.v(_tag, 'En-têtes sans authentification');
    }

    return headers;
  }

  // Récupérer la liste des scénarios
  Future<List<ScenarioModel>> getScenarios({
    String? type,
    String? difficulty,
    String language = 'fr',
  }) async {
    logger.i(_tag, 'Récupération des scénarios');
    logger.performance(_tag, 'getScenarios', start: true);

    // Construire l'URL avec les paramètres de requête
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (difficulty != null) queryParams['difficulty'] = difficulty;
    queryParams['language'] = language;

    // Utiliser l'URL avec le slash à la fin
    final uri = Uri.parse('$baseUrl/api/scenarios').replace(queryParameters: queryParams);
    logger.i(_tag, 'URL de requête: $uri');
    logger.i(_tag, 'Adresse IP et port utilisés: ${uri.host}:${uri.port}');

    // Ajouter les en-têtes d'authentification
    final response = await http.get(uri, headers: headers)
        .timeout(MobileTimeoutConstants.mediumRequestTimeout); // ✅ 6s optimal mobile

    if (response.statusCode == 200) {
      logger.i(_tag, 'Scénarios récupérés avec succès');

      // Vérifier si la réponse est vide
      if (response.body.isEmpty) {
        logger.e(_tag, 'Réponse vide du serveur');
        throw Exception('Le serveur a retourné une réponse vide');
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['scenarios'] ?? [];
      logger.i(_tag, '${data.length} scénarios récupérés');

      final scenarios = data.map((json) => ScenarioModel.fromJson(json)).toList();
      logger.performance(_tag, 'getScenarios', end: true);
      return scenarios;
    } else if (response.statusCode == 401) {
      logger.e(_tag, 'Erreur 401 (Non autorisé) lors de la récupération des scénarios: ${response.body}');
      throw Exception('Accès non autorisé. Veuillez vérifier votre clé API.');
    } else if (response.statusCode == 403) {
      logger.e(_tag, 'Erreur 403 (Interdit) lors de la récupération des scénarios: ${response.body}');
      throw Exception('Accès interdit. Vous n\'avez pas les permissions nécessaires.');
    } else if (response.statusCode == 429) {
      logger.e(_tag, 'Erreur 429 (Trop de requêtes) lors de la récupération des scénarios: ${response.body}');
      throw Exception('Trop de requêtes. Veuillez réessayer plus tard.');
    }
    else {
      // Pour le débogage, afficher le corps de la réponse
      logger.e(_tag, 'Erreur ${response.statusCode} lors de la récupération des scénarios: ${response.body}');
      logger.performance(_tag, 'getScenarios', end: true);
      throw Exception('Erreur ${response.statusCode} lors de la récupération des scénarios');
    }
  }

  // Récupérer un scénario spécifique
  Future<ScenarioModel?> getScenario(String scenarioId) async {
    try {
      logger.i(_tag, 'Récupération du scénario: $scenarioId');
      logger.performance(_tag, 'getScenario', start: true);

      // Utiliser l'URL avec le slash à la fin
      final response = await http.get(
        Uri.parse('$baseUrl/api/scenarios/$scenarioId'),
        headers: headers
      );

      if (response.statusCode == 200) {
        logger.i(_tag, 'Scénario récupéré avec succès');
        final scenario = ScenarioModel.fromJson(json.decode(response.body));
        logger.performance(_tag, 'getScenario', end: true);
        return scenario;
      } else if (response.statusCode == 401) {
        logger.e(_tag, 'Erreur 401 (Non autorisé) lors de la récupération du scénario: ${response.body}');
        throw Exception('Accès non autorisé. Veuillez vérifier votre clé API.');
      } else if (response.statusCode == 403) {
        logger.e(_tag, 'Erreur 403 (Interdit) lors de la récupération du scénario: ${response.body}');
        throw Exception('Accès interdit. Vous n\'avez pas les permissions nécessaires.');
      } else if (response.statusCode == 429) {
        logger.e(_tag, 'Erreur 429 (Trop de requêtes) lors de la récupération du scénario: ${response.body}');
        throw Exception('Trop de requêtes. Veuillez réessayer plus tard.');
      }
      else {
        logger.e(_tag, 'Erreur ${response.statusCode} lors de la récupération du scénario: ${response.body}');
        logger.performance(_tag, 'getScenario', end: true);
        return null;
      }
    } catch (e) {
      logger.e(_tag, 'Exception lors de la récupération du scénario: $e');
      logger.performance(_tag, 'getScenario', end: true);
      return null;
    }
  }

  // Vérifier si une erreur est liée à l'authentification API
  bool isApiAuthError(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      return errorString.contains('api key') || 
             errorString.contains('apikey') || 
             errorString.contains('non autorisé') || 
             errorString.contains('unauthorized') || 
             errorString.contains('401');
    }
    return false;
  }

  // Démarrer une session de coaching avec support pour l'ancien et le nouveau backend
  Future<SessionModel> startSession(
    String scenarioId,
    String userId, {
    String language = 'fr',
    String? goal,
    String? agentProfileId,
    bool isMultiAgent = false,
  }) async {
    // Préparer le corps de la requête pour le nouveau format
    final Map<String, dynamic> newRequestBody = {
      'user_id': userId,
      'language': language,
      'scenario_id': scenarioId,
    };
    
    // Ajouter les champs optionnels s'ils sont fournis
    if (goal != null) newRequestBody['goal'] = goal;
    if (agentProfileId != null) newRequestBody['agent_profile_id'] = agentProfileId;
    newRequestBody['is_multi_agent'] = isMultiAgent;
    
    final newFormatBody = json.encode(newRequestBody);
    
    // Préparer le corps de la requête pour l'ancien format
    final oldFormatBody = json.encode({
      'scenario_id': scenarioId,
      'user_id': userId,
      'language': language,
    });

    // Les en-têtes de base incluent déjà X-API-Key
    final Map<String, String> requestHeaders = {...headers};

    // Essayer d'abord le nouvel endpoint
    final newUrl = '$baseUrl/api/sessions';
    logger.i(_tag, 'Tentative avec le nouvel endpoint: URL=$newUrl, Body=$newFormatBody');
    logger.performance(_tag, 'startSession', start: true);

    try {
      final response = await http.post(
        Uri.parse(newUrl),
        headers: requestHeaders,
        body: newFormatBody,
      ).timeout(MobileTimeoutConstants.mediumRequestTimeout); // ✅ 6s optimal mobile

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i(_tag, 'Session LiveKit démarrée avec succès (Code: ${response.statusCode})');
        
        // Vérifier si la réponse est vide
        if (response.body.isEmpty) {
          logger.e(_tag, 'Réponse vide du serveur');
          throw Exception('Le serveur a retourné une réponse vide');
        }

        // Log AGRESSIF du corps de la réponse BRUTE
        logger.e(_tag, '[AGRESSIF LOG] Response body AVANT json.decode: ${response.body}');
        
        final sessionData = json.decode(response.body);
        // Log AGRESSIF des données décodées
        logger.e(_tag, '[AGRESSIF LOG] sessionData APRÈS json.decode: $sessionData');
        logger.i(_tag, 'Données de session JSON décodées (nouveau format)');
        
        // Vérifier que les champs requis sont présents
        if (!sessionData.containsKey('session_id') ||
            !sessionData.containsKey('room_name') ||
            !sessionData.containsKey('livekit_token') ||
            !sessionData.containsKey('livekit_url')) {
          logger.e(_tag, 'Données de session incomplètes (attend livekit_token, livekit_url): ${sessionData.keys.join(', ')}');
          logger.e(_tag, 'Valeurs reçues: session_id=${sessionData['session_id']}, room_name=${sessionData['room_name']}, livekit_token=${sessionData['livekit_token']}, livekit_url=${sessionData['livekit_url']}');
          throw Exception('Données de session incomplètes');
        }
        
        final sessionId = sessionData['session_id'];
        final roomName = sessionData['room_name'];
        final livekitUrl = sessionData['livekit_url'];
        
        logger.i(_tag, 'Session ID: $sessionId, Room: $roomName, LiveKit URL (depuis sessionData): $livekitUrl');
        
        final session = SessionModel.fromJson(sessionData);
        // Log AGRESSIF de l'objet SessionModel créé
        logger.e(_tag, '[AGRESSIF LOG] SessionModel créé: sessionId=${session.sessionId}, roomName=${session.roomName}, token=${session.token}, livekitUrl=${session.livekitUrl}');
        logger.i(_tag, 'Session LiveKit créée avec succès: ${session.sessionId}');
        
        logger.performance(_tag, 'startSession', end: true);
        return session;
      } else if (response.statusCode == 404) {
        // Si le nouvel endpoint n'existe pas, essayer l'ancien endpoint
        logger.w(_tag, 'Nouvel endpoint non trouvé (404), essai avec l\'ancien endpoint');
      } else if (response.statusCode == 401) {
        logger.e(_tag, 'Erreur 401 (Non autorisé) lors du démarrage de la session: ${response.body}');
        throw Exception('Accès non autorisé. Veuillez vérifier votre clé API.');
      } else if (response.statusCode == 403) {
        logger.e(_tag, 'Erreur 403 (Interdit) lors du démarrage de la session: ${response.body}');
        throw Exception('Accès interdit. Vous n\'avez pas les permissions nécessaires.');
      } else if (response.statusCode == 429) {
        logger.e(_tag, 'Erreur 429 (Trop de requêtes) lors du démarrage de la session: ${response.body}');
        throw Exception('Trop de requêtes. Veuillez réessayer plus tard.');
      }
      else {
        logger.e(_tag, 'Erreur HTTP (${response.statusCode}): ${response.body}');
        logger.performance(_tag, 'startSession', end: true);
        throw Exception('Erreur ${response.statusCode} lors du démarrage de la session LiveKit');
      }
    } catch (e) {
      if (e is! Exception || e.toString().contains('404')) {
        logger.w(_tag, 'Erreur avec le nouvel endpoint: $e, essai avec l\'ancien endpoint');
      } else {
        logger.e(_tag, 'Erreur lors de la connexion au nouvel endpoint: $e');
        logger.performance(_tag, 'startSession', end: true);
        rethrow;
      }
    }

    // Essayer l'ancien endpoint
    final oldUrl = '$baseUrl/api/session/start';
    logger.i(_tag, 'Utilisation de l\'ancien endpoint: URL=$oldUrl, Body=$oldFormatBody');

    try {
      final response = await http.post(
        Uri.parse(oldUrl),
        headers: headers,
        body: oldFormatBody,
      ).timeout(MobileTimeoutConstants.mediumRequestTimeout); // ✅ 6s optimal mobile

      if (response.statusCode == 200) {
        logger.i(_tag, 'Session démarrée avec succès via l\'ancien endpoint (Code: ${response.statusCode})');
        
        // Vérifier si la réponse est vide
        if (response.body.isEmpty) {
          logger.e(_tag, 'Réponse vide du serveur');
          throw Exception('Le serveur a retourné une réponse vide');
        }
        
        final sessionData = json.decode(response.body);
        logger.i(_tag, 'Données de session JSON décodées (ancien format)');
        
        // Vérifier que les champs requis sont présents pour l'ancien format
        if (!sessionData.containsKey('session_id') ||
            !sessionData.containsKey('websocket_url') ||
            !sessionData.containsKey('initial_message')) {
          logger.e(_tag, 'Données de session incomplètes: ${sessionData.keys.join(', ')}');
          throw Exception('Données de session incomplètes');
        }
        
        // Créer une session compatible avec le nouveau format à partir de l'ancien format
        final sessionId = sessionData['session_id'];
        final websocketUrl = sessionData['websocket_url'];
        
        logger.i(_tag, 'Session ID: $sessionId, WebSocket URL: $websocketUrl');
        
        // Extraire l'URL de base pour LiveKit (utiliser l'URL configurée)
        final livekitUrl = AppConfig.livekitUrl; // Correction: livekitWsUrl -> livekitUrl
        
        // Créer un modèle de session compatible avec LiveKit
        final session = SessionModel(
          sessionId: sessionId,
          roomName: 'eloquence-$sessionId', // Générer un nom de salle basé sur l'ID de session
          token: '', // Token vide, sera généré par le service LiveKit
          livekitUrl: livekitUrl,
          initialMessage: Map<String, String>.from(sessionData['initial_message'] ?? {}),
        );
        
        logger.i(_tag, 'Session créée avec succès via l\'ancien endpoint: ${session.sessionId}');
        logger.i(_tag, 'URL LiveKit (configurée): ${session.livekitUrl}');
        
        logger.performance(_tag, 'startSession', end: true);
        return session;
      } else {
        logger.e(_tag, 'Erreur HTTP avec l\'ancien endpoint (${response.statusCode}): ${response.body}');
        logger.performance(_tag, 'startSession', end: true);
        throw Exception('Erreur ${response.statusCode} lors du démarrage de la session');
      }
    } catch (e) {
      logger.e(_tag, 'Erreur lors de la connexion à l\'ancien endpoint: $e');
      logger.performance(_tag, 'startSession', end: true);
      throw Exception('Erreur lors du démarrage de la session: $e');
    }
  }

  // Cette méthode est désormais obsolète car remplacée par LiveKit
  // Elle est conservée pour la rétrocompatibilité mais lève une exception
  @Deprecated('Utilisez LiveKit au lieu de WebSocket')
  Future<WebSocketChannel> connectWebSocket(String sessionId) async {
    logger.e(_tag, 'La méthode connectWebSocket est obsolète. Utilisez LiveKit à la place.');
    throw Exception('La méthode connectWebSocket est obsolète. Utilisez LiveKit à la place.');
  }

  // Terminer une session de coaching avec support pour l'ancien et le nouveau backend
  Future<bool> endSession(String sessionId) async {
    logger.i(_tag, 'Fin de la session: $sessionId');
    logger.performance(_tag, 'endSession', start: true);

    // Les en-têtes de base incluent déjà X-API-Key
    final Map<String, String> requestHeaders = {...headers};

    // Essayer d'abord le nouvel endpoint
    final newUrl = '$baseUrl/api/sessions/$sessionId';
    logger.i(_tag, 'Tentative avec le nouvel endpoint: URL=$newUrl');

    try {
      final response = await http.delete(
        Uri.parse(newUrl),
        headers: requestHeaders,
      ).timeout(MobileTimeoutConstants.mediumRequestTimeout); // ✅ 6s optimal mobile

      if (response.statusCode == 200) {
        logger.i(_tag, 'Session terminée avec succès via le nouvel endpoint');
        logger.performance(_tag, 'endSession', end: true);
        return true;
      } else if (response.statusCode == 404) {
        // Si le nouvel endpoint n'existe pas, essayer l'ancien endpoint
        logger.w(_tag, 'Nouvel endpoint non trouvé (404), essai avec l\'ancien endpoint');
      } else if (response.statusCode == 401) {
        logger.e(_tag, 'Erreur 401 (Non autorisé) lors de la fin de la session: ${response.body}');
        throw Exception('Accès non autorisé. Veuillez vérifier votre clé API.');
      } else if (response.statusCode == 403) {
        logger.e(_tag, 'Erreur 403 (Interdit) lors de la fin de la session: ${response.body}');
        throw Exception('Accès interdit. Vous n\'avez pas les permissions nécessaires.');
      } else if (response.statusCode == 429) {
        logger.e(_tag, 'Erreur 429 (Trop de requêtes) lors de la fin de la session: ${response.body}');
        throw Exception('Trop de requêtes. Veuillez réessayer plus tard.');
      }
      else {
        logger.e(_tag, 'Erreur HTTP avec le nouvel endpoint (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      logger.w(_tag, 'Erreur avec le nouvel endpoint: $e, essai avec l\'ancien endpoint');
    }

    // Essayer l'ancien endpoint
    final oldUrl = '$baseUrl/api/session/$sessionId/end';
    logger.i(_tag, 'Utilisation de l\'ancien endpoint: URL=$oldUrl');

    try {
      final response = await http.post(
        Uri.parse(oldUrl),
        headers: headers,
      ).timeout(MobileTimeoutConstants.mediumRequestTimeout); // ✅ 6s optimal mobile

      final success = response.statusCode == 200;
      if (success) {
        logger.i(_tag, 'Session terminée avec succès via l\'ancien endpoint');
      } else {
        logger.e(_tag, 'Erreur lors de la fin de la session via l\'ancien endpoint: ${response.statusCode} - ${response.body}');
      }

      logger.performance(_tag, 'endSession', end: true);
      return success;
    } catch (e) {
      logger.e(_tag, 'Erreur lors de la connexion à l\'ancien endpoint: $e');
      logger.performance(_tag, 'endSession', end: true);
      return false;
    }
  }

  // Générer une réponse avec Mistral
  Future<String> generateResponse(String prompt) async {
    logger.i(_tag, 'Génération de réponse avec Mistral');
    logger.performance(_tag, 'generateResponse', start: true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: headers,
        body: json.encode({
          'prompt': prompt,
          'model': 'mistral',
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      ).timeout(MobileTimeoutConstants.mistralAnalysisTimeout); // ✅ 8s optimal pour IA Mistral mobile

      if (response.statusCode == 200) {
        logger.i(_tag, 'Réponse générée avec succès');
        
        final responseData = json.decode(response.body);
        final generatedText = responseData['response'] ?? '';
        
        logger.performance(_tag, 'generateResponse', end: true);
        return generatedText;
      } else {
        logger.e(_tag, 'Erreur ${response.statusCode} lors de la génération: ${response.body}');
        logger.performance(_tag, 'generateResponse', end: true);
        throw Exception('Erreur lors de la génération de réponse');
      }
    } catch (e) {
      logger.e(_tag, 'Exception lors de la génération: $e');
      logger.performance(_tag, 'generateResponse', end: true);
      rethrow;
    }
  }

  // Synthétiser de l'audio à partir du texte
  Future<Uint8List> synthesizeAudio(String text) async {
    logger.i(_tag, 'Synthèse audio pour le texte: "${text.substring(0, (text.length > 50) ? 50 : text.length)}..."');
    logger.performance(_tag, 'synthesizeAudio', start: true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/synthesize'),
        headers: headers,
        body: json.encode({
          'text': text,
          'voice': 'eloquence-voice', // Voix personnalisée
        }),
      ).timeout(MobileTimeoutConstants.heavyRequestTimeout); // ✅ 8s optimal pour synthèse audio mobile

      if (response.statusCode == 200) {
        logger.i(_tag, 'Synthèse audio réussie');
        logger.performance(_tag, 'synthesizeAudio', end: true);
        return response.bodyBytes;
      } else {
        logger.e(_tag, 'Erreur ${response.statusCode} lors de la synthèse audio: ${response.body}');
        logger.performance(_tag, 'synthesizeAudio', end: true);
        throw Exception('Erreur lors de la synthèse audio');
      }
    } catch (e) {
      logger.e(_tag, 'Exception lors de la synthèse audio: $e');
      logger.performance(_tag, 'synthesizeAudio', end: true);
      rethrow;
    }
  }
}
