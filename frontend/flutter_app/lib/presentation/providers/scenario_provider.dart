import 'dart:async';
// import 'dart:convert'; // Unused import
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eloquence_2_0/data/models/scenario_model.dart';
import 'package:eloquence_2_0/data/models/session_model.dart';
import 'package:eloquence_2_0/data/services/api_service.dart';
import 'package:eloquence_2_0/core/utils/logger_service.dart';
import 'package:eloquence_2_0/core/config/app_config.dart'; // Importez AppConfig
import 'package:eloquence_2_0/src/providers/clean_audio_provider.dart'; // Ajout de l'import pour CleanAudioProvider
// Importer les providers pour y accéder
// import 'package:eloquence_2_0/presentation/providers/audio_provider.dart'; // Supprimé
// import 'package:eloquence_2_0/presentation/providers/livekit_provider.dart'; // TODO: Remplacer ou supprimer
// import 'package:eloquence_2_0/presentation/providers/livekit_audio_provider.dart'; // Supprimé

// Provider pour le service API
final apiServiceProvider = Provider<ApiService>((ref) {
  // Pour le moment, nous n'avons pas d'authentification
  // Dans une implémentation réelle, vous récupéreriez le token d'un service d'authentification
  return ApiService(
    baseUrl: AppConfig.apiBaseUrl, // Utiliser l'URL configurée dans AppConfig
    authToken: null,
  );
});

// Liste des scénarios de démonstration
final List<ScenarioModel> _demoScenarios = [
  ScenarioModel(
    id: 'demo-1',
    name: 'Entretien d\'embauche',
    description: 'Préparez-vous à un entretien d\'embauche pour un poste de développeur.',
    type: 'entretien',
    difficulty: 'moyen',
    language: 'fr',
  ),
  ScenarioModel(
    id: 'demo-2',
    name: 'Présentation de projet',
    description: 'Entraînez-vous à présenter un projet devant une audience.',
    type: 'présentation',
    difficulty: 'facile',
    language: 'fr',
  ),
  ScenarioModel(
    id: 'demo-3',
    name: 'Négociation commerciale',
    description: 'Améliorez vos compétences en négociation commerciale.',
    type: 'négociation',
    difficulty: 'difficile',
    language: 'fr',
  ),
];

// Provider pour la liste des scénarios
final scenariosProvider = FutureProvider<List<ScenarioModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  
  // Afficher l'URL de l'API utilisée
  logger.i('ScenariosProvider', "URL de l'API: ${AppConfig.apiBaseUrl}");
  
  try {
    logger.i('ScenariosProvider', 'Récupération des scénarios depuis l\'API');
    
    // Tentative de récupération des scénarios depuis l'API
    final scenarios = await apiService.getScenarios();

    // Si la liste est vide, utiliser des scénarios de démonstration
    if (scenarios.isEmpty) {
      logger.w('ScenariosProvider', 'Aucun scénario récupéré, utilisation des scénarios de démonstration');
      return _demoScenarios;
    }

    logger.i('ScenariosProvider', '${scenarios.length} scénarios récupérés avec succès');
    return scenarios;
  } catch (e, stackTrace) {
    // En cas d'erreur, afficher des informations détaillées et utiliser des scénarios de démonstration
    logger.e('ScenariosProvider', 'Erreur lors de la récupération des scénarios: $e');
    logger.e('ScenariosProvider', 'StackTrace: $stackTrace');
    
    // Afficher des informations sur la configuration réseau
    logger.i('ScenariosProvider', 'Configuration réseau:');
    logger.i('ScenariosProvider', '- URL API: ${AppConfig.apiBaseUrl}');
    logger.i('ScenariosProvider', '- Mode production: ${AppConfig.isProduction}');
    
    // Construire l'URL WebSocket complète pour la session fictive
    final baseUri = Uri.parse(AppConfig.apiBaseUrl);
    final wsProtocol = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final mockWsUrl = Uri(
      scheme: wsProtocol,
      host: baseUri.host,
      port: baseUri.port,
      path: '/ws/session-mock',
    ).toString();

    logger.w('ScenariosProvider', 'Création d\'une session fictive avec URL: $mockWsUrl');
    logger.w('ScenariosProvider', 'Utilisation des scénarios de démonstration en mode hors ligne');

    return _demoScenarios;
  }
});

// Provider pour le scénario sélectionné
final selectedScenarioProvider = StateProvider<ScenarioModel?>((ref) => null);

// Provider pour la session en cours
final sessionProvider = StateNotifierProvider<SessionNotifier, AsyncValue<SessionModel?>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  // Passer la ref au SessionNotifier
  return SessionNotifier(apiService, ref);
});

// Notifier pour gérer l'état de la session
class SessionNotifier extends StateNotifier<AsyncValue<SessionModel?>> {
  static const String _tag = 'SessionNotifier';
  final ApiService _apiService;
  final Ref _ref; // Stocker la ref

  // Modifier le constructeur pour accepter et stocker la ref
  SessionNotifier(this._apiService, this._ref) : super(const AsyncValue.data(null));

  // Démarrer une session avec LiveKit
  Future<void> startSession(
    String scenarioId, {
    String? goal,
    String? agentProfileId,
    bool isMultiAgent = false,
  }) async {
    logger.i(_tag, 'Démarrage d\'une session LiveKit pour scenarioId: "$scenarioId"');
    
    try {
      // Vérifier si l'ID du scénario est valide
      if (scenarioId.isEmpty) {
        logger.w(_tag, 'ID de scénario vide');
        state = AsyncValue.error('ID de scénario invalide', StackTrace.current);
        return;
      }
      
      // Mettre à jour l'état pour indiquer le chargement
      state = const AsyncValue.loading();

      // Générer un ID utilisateur unique
      final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      
      try {
        // Appeler l'API pour démarrer une session avec les nouveaux paramètres LiveKit
        final session = await _apiService.startSession(
          scenarioId,
          userId,
          language: 'fr',
          goal: goal,
          agentProfileId: agentProfileId,
          isMultiAgent: isMultiAgent,
        );
        
        // Vérifier si la session a été créée avec succès
        logger.i(_tag, 'Session LiveKit créée avec succès: ${session.sessionId}');
        logger.i(_tag, 'Room LiveKit: ${session.roomName}');
        logger.i(_tag, 'URL LiveKit: ${session.livekitUrl}');
        
        // Mettre à jour l'état avec la session
        state = AsyncValue.data(session);
        
        // CORRECTION : Ne plus connecter à LiveKit ici, c'est maintenant géré par ScenarioScreen
        logger.i(_tag, '✅ Session créée, connexion LiveKit sera gérée par ScenarioScreen');
            } catch (apiError) {
        logger.e(_tag, 'Erreur API lors du démarrage de la session LiveKit: $apiError');

        // Vérifier si l'erreur est liée à l'authentification API
        if (_apiService.isApiAuthError(apiError)) {
          logger.w(_tag, 'Erreur d\'authentification API détectée, utilisation du mode démo/hors ligne');
          
          // Créer une session de démonstration
          createDemoSession();
          
          // Afficher un message à l'utilisateur
          // Note: Dans une application réelle, vous pourriez vouloir afficher une notification à l'utilisateur
          logger.i(_tag, 'Mode démo/hors ligne activé en raison d\'une erreur d\'authentification API');
          
          return;
        }

        // Mettre à jour l'état avec l'erreur
        state = AsyncValue.error(apiError.toString(), StackTrace.current);

        // Rethrow pour permettre à l'appelant de gérer l'erreur
        rethrow;
      }
    } catch (e, stackTrace) {
      logger.e(_tag, 'Exception non gérée lors du démarrage de la session LiveKit: $e');
      logger.e(_tag, 'StackTrace: $stackTrace');
      
      // Mettre à jour l'état avec l'erreur
      state = AsyncValue.error(e.toString(), stackTrace);
      
      // Rethrow pour permettre à l'appelant de gérer l'erreur
      rethrow;
    }
  }

  // Méthode pour créer une session de démonstration en mode hors ligne
  void createDemoSession() {
    logger.i(_tag, 'Création d\'une session de démonstration LiveKit (mode hors ligne)');
    
    // Générer un ID de session unique
    final demoSessionId = 'demo-${DateTime.now().millisecondsSinceEpoch}';
    final demoRoomName = 'eloquence-$demoSessionId';
    
    // Utiliser l'URL LiveKit configurée
    final livekitUrl = AppConfig.livekitUrl; // Correction: livekitWsUrl -> livekitUrl
    
    logger.i(_tag, 'URL LiveKit pour la session de démonstration: $livekitUrl');
    logger.i(_tag, 'Room LiveKit pour la session de démonstration: $demoRoomName');

    // Créer un token fictif pour la démonstration
    final demoToken = 'demo-token-${DateTime.now().millisecondsSinceEpoch}';

    // Créer une session de démonstration avec les nouveaux champs LiveKit
    final demoSession = SessionModel(
      sessionId: demoSessionId,
      roomName: demoRoomName,
      token: demoToken,
      livekitUrl: livekitUrl,
      initialMessage: {
        'text': 'Mode démonstration hors ligne activé. Vous pouvez tester l\'application sans connexion au serveur. Note: Cette session est en mode démo car le serveur a renvoyé une erreur d\'authentification API.',
        'type': 'system',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    
    // Mettre à jour l'état avec la session de démonstration
    state = AsyncValue.data(demoSession);
    
    // Notifier que nous sommes en mode démonstration
    logger.i(_tag, 'Session de démonstration LiveKit créée: $demoSessionId');
  }

  // // Connecter à LiveKit // Supprimé car inutilisé et la logique est dans ScenarioScreen/CleanAudioProvider
  // Future<void> _connectToLiveKit(SessionModel session) async {
  //   try {
  //     logger.i(_tag, 'Connexion à LiveKit pour la session: ${session.sessionId}');
  //     logger.i(_tag, 'Room LiveKit: ${session.roomName}, URL: ${session.livekitUrl}');

  //     // Récupérer le provider LiveKit audio - TODO: Remplacer par CleanAudioProvider
  //     // final liveKitAudioNotifier = _ref.read(liveKitConversationProvider.notifier);
      
  //     // Vérifier si nous avons un token valide
  //     if (session.token.isEmpty) {
  //       logger.i(_tag, 'Pas de token LiveKit fourni, utilisation de l\'ancien flux de travail');
        
  //       // Utiliser l'ancienne méthode de connexion WebSocket
  //       if (session.sessionId.isNotEmpty) {
  //         // Extraire l'URL WebSocket à partir de l'ID de session
  //         final baseUri = Uri.parse(AppConfig.apiBaseUrl);
  //         final wsProtocol = baseUri.scheme == 'https' ? 'wss' : 'ws';
  //         final wsUrl = '$wsProtocol://${baseUri.host}:${baseUri.port}/ws/simple/${session.sessionId}';
          
  //         logger.i(_tag, 'URL WebSocket générée: $wsUrl');
          
  //         // Déconnecter toute connexion existante avant d'en établir une nouvelle
  //         await _disconnectExistingConnections();
          
  //         // Attendre un court délai pour s'assurer que la déconnexion est complète
  //         await Future.delayed(const Duration(milliseconds: 500));
          
  //         // Connecter au WebSocket - TODO: Remplacer par CleanAudioProvider
  //         // await liveKitAudioNotifier.connectWebSocket(wsUrl);
  //         logger.i(_tag, 'Connexion WebSocket (ancienne méthode) serait établie ici pour la session: ${session.sessionId}');
  //       } else {
  //         throw Exception('ID de session invalide');
  //       }
  //     } else {
  //       // Déconnecter toute connexion existante avant d'en établir une nouvelle
  //       await _disconnectExistingConnections();
        
  //       // Attendre un court délai pour s'assurer que la déconnexion est complète
  //       await Future.delayed(const Duration(milliseconds: 500));
        
  //       // Connecter à LiveKit avec les informations de la session et délai de synchronisation
  //       // Utiliser un délai de synchronisation de 1000ms pour permettre à l'agent de se connecter - TODO: Remplacer par CleanAudioProvider
  //       // await liveKitAudioNotifier.connectWithSession(session, syncDelayMs: 1000);
  //       final cleanAudioNotifier = _ref.read(cleanAudioProvider.notifier);
  //       await cleanAudioNotifier.connect(session);
  //       logger.i(_tag, 'Connexion LiveKit établie avec succès via CleanAudioProvider pour la session: ${session.sessionId}');
  //     }
  //   } catch (e) {
  //     logger.e(_tag, 'Exception lors de la connexion LiveKit/WebSocket: $e');
  //     throw Exception('Erreur de connexion: $e');
  //   }
  // }
  
  // Supprimé: _connectWebSocket (anciennement 319-344)
  
  // Supprimé: _processWebSocketMessage (anciennement 347-391)
  // Supprimé: _handleWebSocketClosure (anciennement 393-417)
  // Supprimé: sendAudioMessage (anciennement 419-431)

  // Terminer la session LiveKit
  Future<void> endSession() async {
    if (state.value != null) {
      try {
        logger.i(_tag, 'Fin de la session LiveKit: ${state.value!.sessionId}');
        
        // Stocker l'ID de session pour les logs
        final sessionId = state.value!.sessionId;
        
        // Récupérer le provider LiveKit audio pour déconnecter - TODO: Remplacer par CleanAudioProvider
        // final liveKitAudioNotifier = _ref.read(liveKitConversationProvider.notifier);
        
        // Appeler l'API pour terminer la session si ce n'est pas une session de démonstration
        if (!sessionId.startsWith('demo-') && !sessionId.startsWith('mock-')) {
          try {
            await _apiService.endSession(sessionId);
            logger.i(_tag, 'Session LiveKit terminée avec succès via API: $sessionId');
          } catch (apiError) {
            logger.e(_tag, 'Erreur lors de la fin de session LiveKit via API: $apiError');
            // Continuer malgré l'erreur pour nettoyer les ressources
          }
        } else {
          logger.i(_tag, 'Session de démonstration LiveKit, pas d\'appel API pour endSession: $sessionId');
        }
      } catch (e) {
        logger.e(_tag, 'Erreur lors de la fin de la session LiveKit: $e');
      } finally {
        // Fermer la connexion LiveKit - TODO: Remplacer par CleanAudioProvider
        try {
          // final liveKitNotifier = _ref.read(liveKitConnectionProvider.notifier);
          // await liveKitNotifier.disconnect();
          final cleanAudioNotifier = _ref.read(cleanAudioProvider.notifier);
          await cleanAudioNotifier.disconnect();
          logger.i(_tag, 'Connexion LiveKit fermée avec succès via CleanAudioProvider lors de la fin de session');
        } catch (lkError) {
          logger.e(_tag, 'Erreur lors de la fermeture de la connexion LiveKit: $lkError');
        }
        
        // Réinitialiser l'état
        state = const AsyncValue.data(null);
        logger.i(_tag, 'État de session réinitialisé');
      }
    } else {
      logger.i(_tag, 'Aucune session LiveKit active à terminer');
    }
  }

  @override
  void dispose() {
    logger.i(_tag, 'Destruction du notifier de session');
    super.dispose();
  }
}

// Provider pour l'état d'enregistrement
final recordingStateProvider = StateProvider<RecordingState>((ref) => RecordingState.idle);

// Enum pour l'état d'enregistrement
enum RecordingState {
idle,
recording,
processing,
}

// Provider pour l'état de traitement de l'IA (si l'IA est en train de générer une réponse)
final aiProcessingStateProvider = StateProvider<bool>((ref) => false);
