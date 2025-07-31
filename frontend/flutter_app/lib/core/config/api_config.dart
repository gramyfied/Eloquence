import 'package:flutter/foundation.dart';

/// Configuration centralisée pour les APIs d'Eloquence
/// CONFIGURATION: Serveur distant uniquement (51.159.110.4)
class ApiConfig {
  // URLs de base - SERVEUR DISTANT UNIQUEMENT
  static const String _remoteApiUrl = 'http://51.159.110.4:8000';
  
  /// Détermine si on utilise le serveur distant
  /// CONFIGURATION: Toujours true (serveur distant forcé)
  static Future<bool> get useRemoteServer async => true;
  
  /// Change le mode serveur (local/distant)
  /// CONFIGURATION: Bloqué sur serveur distant
  static Future<void> setUseRemoteServer(bool useRemote) async {
    debugPrint('Configuration: Serveur distant forcé (51.159.110.4)');
  }
  
  /// URL de base de l'API - TOUJOURS SERVEUR DISTANT
  static Future<String> get baseUrl async => _remoteApiUrl;
  
  /// URL de base synchrone - TOUJOURS SERVEUR DISTANT
  static String get baseUrlSync => _remoteApiUrl;
  
  /// URL complète de l'API
  static Future<String> get apiUrl async => _remoteApiUrl;
  
  /// URLs spécifiques pour les endpoints
  static Future<String> get exercisesApiUrl async => '$_remoteApiUrl/api/exercises';
  static Future<String> get confidenceBoostApiUrl async => '$_remoteApiUrl/api/confidence-boost';
  static Future<String> get storyGeneratorApiUrl async => '$_remoteApiUrl/api/story-generator';
  static Future<String> get voskSttApiUrl async => '$_remoteApiUrl/api/vosk-stt';
  
  /// URL WebSocket pour le streaming
  static Future<String> get streamingApiUrl async {
    return _remoteApiUrl.replaceFirst('http', 'ws') + '/ws';
  }
  
  /// URLs des services additionnels - SERVEUR DISTANT UNIQUEMENT
  static Future<String> get voskServiceUrl async => 'http://51.159.110.4:2700';
  static Future<String> get mistralServiceUrl async => 'http://51.159.110.4:8001';
  static Future<String> get livekitServiceUrl async => 'ws://51.159.110.4:7880';
  static Future<String> get eloquenceConversationUrl async => 'http://51.159.110.4:8003';
  
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
  static Future<String> get serverInfo async => 'Serveur distant: 51.159.110.4';
  
  /// Bascule entre serveur local et distant (DÉSACTIVÉ)
  static Future<void> toggleServer() async {
    debugPrint('Basculement désactivé: Serveur distant forcé');
  }
  
  /// Initialise la configuration (à appeler au démarrage de l'app)
  static Future<void> initialize() async {
    debugPrint('🔧 ApiConfig initialisé: Serveur distant forcé (51.159.110.4)');
  }
  
  /// Teste la connectivité vers le serveur configuré
  static Future<bool> testConnectivity() async {
    try {
      debugPrint('Test de connectivité vers: $_remoteApiUrl');
      return true; // Placeholder - sera implémenté dans le service de connectivité
    } catch (e) {
      debugPrint('Erreur de connectivité vers $_remoteApiUrl: $e');
      return false;
    }
  }
  
  /// Méthodes utilitaires pour l'interface utilisateur
  static Future<String> get currentServerLabel async => 'Serveur Distant';
  
  static Future<String> get currentServerDescription async => 
      'Connecté au serveur de production (51.159.110.4)';
}
