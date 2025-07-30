import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configuration pour différents environnements
  static const String _localApiUrl = 'http://localhost:8000';
  static const String _productionApiUrl = 'http://51.159.110.4:8000';
  
  // Détection automatique de l'environnement
  static String get baseUrl {
    if (kDebugMode) {
      // En mode debug, essayer d'abord le serveur distant, puis local en fallback
      return _productionApiUrl;
    } else {
      // En mode release, utiliser le serveur de production
      return _productionApiUrl;
    }
  }
  
  // URL complète de l'API
  static String get apiUrl => baseUrl;
  
  // URLs spécifiques pour les endpoints
  static String get itemsEndpoint => '$apiUrl/api/items';
  static String get usersEndpoint => '$apiUrl/api/users';
  static String get healthEndpoint => '$apiUrl/health';
  
  // Configuration pour les timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Headers par défaut
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Méthode pour tester la connectivité
  static String getApiUrlForEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'local':
        return _localApiUrl;
      case 'production':
      case 'remote':
        return _productionApiUrl;
      default:
        return baseUrl;
    }
  }
}
