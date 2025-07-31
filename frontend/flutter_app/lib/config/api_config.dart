// lib/config/api_config.dart
class ApiConfig {
  // Configuration pour l'environnement de production
  static const String _productionBaseUrl = 'https://votre-domaine.com';
  
  // Configuration pour l'environnement de développement local
  static const String _developmentBaseUrl = 'http://192.168.1.44:8000';
  
  // Configuration pour l'environnement de test
  static const String _testBaseUrl = 'http://localhost:8000';
  
  // Détection automatique de l'environnement
  static String get baseUrl {
    // En production (web), utiliser l'URL de production
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _productionBaseUrl;
    }
    
    // En développement, utiliser l'URL locale
    return _developmentBaseUrl;
  }
  
  // URL WebSocket dérivée de l'URL de base
  static String get wsUrl => baseUrl.replaceFirst('http', 'ws');
  
  // Configuration des endpoints
  static const String healthEndpoint = '/health';
  static const String exercisesEndpoint = '/api/exercises';
  static const String sessionsEndpoint = '/api/sessions';
  static const String analysisEndpoint = '/analysis';
  
  // Configuration des timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Configuration WebSocket
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  static const int wsMaxReconnectAttempts = 3;
  
  // Headers par défaut
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Configuration pour différents environnements
  static String getUrlForEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'production':
        return _productionBaseUrl;
      case 'development':
        return _developmentBaseUrl;
      case 'test':
        return _testBaseUrl;
      default:
        return baseUrl;
    }
  }
  
  // Méthode pour configurer l'URL de production dynamiquement
  static String? _customProductionUrl;
  
  static void setProductionUrl(String url) {
    _customProductionUrl = url;
  }
  
  static String get productionBaseUrl {
    return _customProductionUrl ?? _productionBaseUrl;
  }
}
