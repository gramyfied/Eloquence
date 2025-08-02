import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration centralisée pour les APIs d'Eloquence
/// CONFIGURATION: Basculement entre serveur local (192.168.1.44) et distant (51.159.110.4)
class ApiConfig {
  // URLs de base - SERVEUR LOCAL (IP locale)
  static const String _localApiUrl = 'http://192.168.1.44:8080';
  static const String _localVoskUrl = 'http://192.168.1.44:8012';
  static const String _localMistralUrl = 'http://192.168.1.44:8001';
  static const String _localLivekitUrl = 'ws://192.168.1.44:7880';
  static const String _localLivekitTokenUrl = 'http://192.168.1.44:8004';
  static const String _localEloquenceConversationUrl = 'http://192.168.1.44:8001';
  static const String _localExercisesUrl = 'http://192.168.1.44:8005';
  
  // URLs de base - SERVEUR DISTANT (sauvegardé pour réactivation)
  static const String _remoteApiUrl = 'http://51.159.110.4:8000';
  static const String _remoteVoskUrl = 'http://51.159.110.4:2700';
  static const String _remoteMistralUrl = 'http://51.159.110.4:8001';
  static const String _remoteLivekitUrl = 'ws://51.159.110.4:7880';
  static const String _remoteLivekitTokenUrl = 'http://51.159.110.4:8004';
  static const String _remoteEloquenceConversationUrl = 'http://51.159.110.4:8003';
  static const String _remoteExercisesUrl = 'http://51.159.110.4:8005';
  
  // Clé pour sauvegarder la préférence
  static const String _useRemoteServerKey = 'use_remote_server';
  
  /// Détermine si on utilise le serveur distant
  /// Par défaut: false (serveur local 192.168.1.44)
  static Future<bool> get useRemoteServer async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useRemoteServerKey) ?? false; // Par défaut: serveur local
  }
  
  /// Change le mode serveur (local/distant)
  static Future<void> setUseRemoteServer(bool useRemote) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useRemoteServerKey, useRemote);
    debugPrint('🔄 Configuration changée: ${useRemote ? "Serveur distant (51.159.110.4)" : "Serveur local (192.168.1.44)"}');
  }
  
  /// URL de base de l'API
  static Future<String> get baseUrl async {
    final useRemote = await useRemoteServer;
    return useRemote ? _remoteApiUrl : _localApiUrl;
  }
  
  /// URL de base synchrone (utilise la configuration par défaut locale)
  static String get baseUrlSync => _localApiUrl;
  
  /// URL complète de l'API
  static Future<String> get apiUrl async => await baseUrl;
  
  /// URLs spécifiques pour les endpoints
  static Future<String> get exercisesApiUrl async {
    final useRemote = await useRemoteServer;
    final baseUrl = useRemote ? _remoteExercisesUrl : _localExercisesUrl;
    return baseUrl;
  }
  
  static Future<String> get confidenceBoostApiUrl async {
    final baseUrl = await apiUrl;
    return '$baseUrl/api/confidence-boost';
  }
  
  static Future<String> get storyGeneratorApiUrl async {
    final baseUrl = await apiUrl;
    return '$baseUrl/api/story-generator';
  }
  
  static Future<String> get voskSttApiUrl async {
    final baseUrl = await apiUrl;
    return '$baseUrl/api/vosk-stt';
  }
  
  /// URL WebSocket pour le streaming
  static Future<String> get streamingApiUrl async {
    final baseUrl = await apiUrl;
    return baseUrl.replaceFirst('http', 'ws') + '/ws';
  }
  
  /// URLs des services additionnels
  static Future<String> get voskServiceUrl async {
    final useRemote = await useRemoteServer;
    return useRemote ? _remoteVoskUrl : _localVoskUrl;
  }
  
  static Future<String> get mistralServiceUrl async {
    final useRemote = await useRemoteServer;
    return useRemote ? _remoteMistralUrl : _localMistralUrl;
  }
  
  static Future<String> get livekitServiceUrl async {
    final useRemote = await useRemoteServer;
    return useRemote ? _remoteLivekitUrl : _localLivekitUrl;
  }
  
  static Future<String> get eloquenceConversationUrl async {
    final useRemote = await useRemoteServer;
    return useRemote ? _remoteEloquenceConversationUrl : _localEloquenceConversationUrl;
  }
  
  static Future<String> get livekitTokenUrl async {
    final useRemote = await useRemoteServer;
    return useRemote ? _remoteLivekitTokenUrl : _localLivekitTokenUrl;
  }
  
  /// Headers par défaut pour les requêtes API
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Configuration pour les timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  /// Informations de debug
  static Future<String> get serverInfo async {
    final useRemote = await useRemoteServer;
    return useRemote 
        ? 'Serveur distant: 51.159.110.4' 
        : 'Serveur local: 192.168.1.44';
  }
  
  /// Bascule entre serveur local et distant
  static Future<void> toggleServer() async {
    final currentUseRemote = await useRemoteServer;
    await setUseRemoteServer(!currentUseRemote);
    final newMode = !currentUseRemote ? "distant" : "local";
    debugPrint('🔄 Basculement vers serveur $newMode');
  }
  
  /// Initialise la configuration (à appeler au démarrage de l'app)
  static Future<void> initialize() async {
    final useRemote = await useRemoteServer;
    final serverType = useRemote ? "distant (51.159.110.4)" : "local (192.168.1.44)";
    debugPrint('🔧 ApiConfig initialisé: Serveur $serverType');
  }
  
  /// Teste la connectivité vers le serveur configuré
  static Future<bool> testConnectivity() async {
    try {
      final currentBaseUrl = await baseUrl;
      debugPrint('Test de connectivité vers: $currentBaseUrl');
      return true; // Placeholder - sera implémenté dans le service de connectivité
    } catch (e) {
      final currentBaseUrl = await baseUrl;
      debugPrint('Erreur de connectivité vers $currentBaseUrl: $e');
      return false;
    }
  }
  
  /// Méthodes utilitaires pour l'interface utilisateur
  static Future<String> get currentServerLabel async {
    final useRemote = await useRemoteServer;
    return useRemote ? 'Serveur Distant' : 'Serveur Local';
  }
  
  static Future<String> get currentServerDescription async {
    final useRemote = await useRemoteServer;
    return useRemote 
        ? 'Connecté au serveur de production (51.159.110.4)'
        : 'Connecté au serveur local de développement (192.168.1.44)';
  }
  
  /// Méthodes de configuration rapide
  static Future<void> useLocalServer() async {
    await setUseRemoteServer(false);
    debugPrint('🏠 Configuration: Serveur local activé (192.168.1.44)');
  }
  
  static Future<void> useRemoteServerConfig() async {
    await setUseRemoteServer(true);
    debugPrint('🌐 Configuration: Serveur distant activé (51.159.110.4)');
  }
}
