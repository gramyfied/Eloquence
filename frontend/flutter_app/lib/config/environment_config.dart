// lib/config/environment_config.dart
import 'api_config.dart';

class EnvironmentConfig {
  static const String _envKey = 'ELOQUENCE_ENV';
  static const String _apiUrlKey = 'ELOQUENCE_API_URL';
  
  // Environnements disponibles
  static const String development = 'development';
  static const String production = 'production';
  static const String test = 'test';
  
  // Configuration par défaut
  static String _currentEnvironment = development;
  static String? _customApiUrl;
  
  // Initialisation de l'environnement
  static void initialize({
    String? environment,
    String? apiUrl,
  }) {
    // Définir l'environnement
    _currentEnvironment = environment ?? 
                         const String.fromEnvironment(_envKey, defaultValue: development);
    
    // Définir l'URL de l'API si fournie
    _customApiUrl = apiUrl ?? const String.fromEnvironment(_apiUrlKey);
    
    // Configurer l'URL de production si nécessaire
    if (_customApiUrl != null && _currentEnvironment == production) {
      ApiConfig.setProductionUrl(_customApiUrl!);
    }
  }
  
  // Getters
  static String get currentEnvironment => _currentEnvironment;
  static String? get customApiUrl => _customApiUrl;
  static bool get isProduction => _currentEnvironment == production;
  static bool get isDevelopment => _currentEnvironment == development;
  static bool get isTest => _currentEnvironment == test;
  
  // Configuration de l'URL de l'API selon l'environnement
  static String get apiUrl {
    if (_customApiUrl != null) {
      return _customApiUrl!;
    }
    return ApiConfig.getUrlForEnvironment(_currentEnvironment);
  }
  
  // Configuration pour Scaleway (production)
  static void configureForScaleway(String domain) {
    _currentEnvironment = production;
    _customApiUrl = 'https://$domain';
    ApiConfig.setProductionUrl(_customApiUrl!);
  }
  
  // Configuration pour développement local
  static void configureForLocalDevelopment({String? localIp}) {
    _currentEnvironment = development;
    if (localIp != null) {
      _customApiUrl = 'http://$localIp:8000';
    }
  }
  
  // Configuration pour test
  static void configureForTest() {
    _currentEnvironment = test;
    _customApiUrl = 'http://localhost:8000';
  }
  
  // Méthode pour obtenir la configuration complète
  static Map<String, dynamic> getConfig() {
    return {
      'environment': _currentEnvironment,
      'apiUrl': apiUrl,
      'customApiUrl': _customApiUrl,
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'isTest': isTest,
    };
  }
  
  // Méthode pour déboguer la configuration
  static void printConfig() {
    print('=== ELOQUENCE ENVIRONMENT CONFIG ===');
    print('Environment: $_currentEnvironment');
    print('API URL: $apiUrl');
    print('Custom API URL: $_customApiUrl');
    print('Is Production: $isProduction');
    print('Is Development: $isDevelopment');
    print('Is Test: $isTest');
    print('=====================================');
  }
}
