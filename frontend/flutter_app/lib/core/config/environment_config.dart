/// Configuration d'environnement pour l'application Eloquence
/// 
/// Ce fichier remplace le fichier .env qui est bloqué par le système
/// Toutes les variables d'environnement sont définies ici
class EnvironmentConfig {
  // Configuration de l'environnement
  static const bool isProduction = false;
  static const bool isDevelopment = true;
  static const bool isDebug = true;
  
  // IP de développement (machine Windows sur le réseau local)
  static const String devHostIP = '192.168.1.44';
  
  // Configuration LiveKit
  static const String livekitApiKey = 'devkey';
  static const String livekitApiSecret = 'devsecret123456789abcdef0123456789abcdef';
  
  // URLs des services de développement
  static String get livekitUrl => 'ws://$devHostIP:7880';
  static String get livekitHttpUrl => 'http://$devHostIP:7880';
  static String get livekitTokenUrl => 'http://$devHostIP:8004';
  
  // API des exercices vocaux
  static String get exercisesApiUrl => 'http://$devHostIP:8005';
  static String get eloquenceStreamingApiUrl => 'http://$devHostIP:8005';
  
  // Service Mistral/LLM
  static String get mistralBaseUrl => 'https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1';
  static String get llmServiceUrl => 'http://$devHostIP:8001';
  
  // Service Vosk STT
  static String get voskServiceUrl => 'http://$devHostIP:8002';
  
  // Service TTS
  static String get ttsServiceUrl => 'http://$devHostIP:5002';
  
  // HAProxy
  static String get haproxyUrl => 'http://$devHostIP:8080';
  
  // Redis
  static String get redisHost => devHostIP;
  static String get redisUrl => 'redis://$devHostIP:6379';
  
  // Configuration WebRTC
  static const List<String> webRtcIceServers = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
  ];
  
  // Configuration des timeouts
  static const Duration connectionTimeout = Duration(seconds: 45);
  static const Duration requestTimeout = Duration(seconds: 90);
  static const Duration livekitConnectionTimeout = Duration(seconds: 60);
  
  // Configuration des retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Méthode pour obtenir la configuration complète
  static Map<String, dynamic> getAllConfig() {
    return {
      'environment': {
        'isProduction': isProduction,
        'isDevelopment': isDevelopment,
        'isDebug': isDebug,
      },
      'network': {
        'devHostIP': devHostIP,
        'livekitUrl': livekitUrl,
        'livekitHttpUrl': livekitHttpUrl,
        'livekitTokenUrl': livekitTokenUrl,
        'exercisesApiUrl': exercisesApiUrl,
        'mistralBaseUrl': mistralBaseUrl,
        'voskServiceUrl': voskServiceUrl,
        'ttsServiceUrl': ttsServiceUrl,
        'haproxyUrl': haproxyUrl,
        'redisUrl': redisUrl,
      },
      'livekit': {
        'apiKey': livekitApiKey,
        'apiSecret': livekitApiSecret,
        'iceServers': webRtcIceServers,
        'connectionTimeout': livekitConnectionTimeout.inSeconds,
      },
      'timeouts': {
        'connection': connectionTimeout.inSeconds,
        'request': requestTimeout.inSeconds,
        'livekit': livekitConnectionTimeout.inSeconds,
      },
      'retry': {
        'maxRetries': maxRetries,
        'retryDelay': retryDelay.inSeconds,
      },
    };
  }
  
  // Méthode pour diagnostiquer la configuration
  static void debugConfig() {
    if (isDebug) {
      print('🔧 === DIAGNOSTIC CONFIGURATION ENVIRONNEMENT ===');
      print('🌍 Environnement: ${isProduction ? "Production" : "Développement"}');
      print('🔧 Mode Debug: $isDebug');
      print('🌐 IP Hôte: $devHostIP');
      
      final config = getAllConfig();
      config.forEach((category, settings) {
        print('📋 $category:');
        if (settings is Map) {
          settings.forEach((key, value) {
            print('   $key: $value');
          });
        } else {
          print('   $settings');
        }
      });
      
      print('🔧 === FIN DIAGNOSTIC ===');
    }
  }
  
  // Méthode pour valider la configuration
  static List<String> validateConfig() {
    final errors = <String>[];
    
    // Vérifier que l'IP n'est pas vide
    if (devHostIP.isEmpty) {
      errors.add('IP de développement manquante');
    }
    
    // Vérifier que les ports sont valides
    if (!_isValidPort(7880)) errors.add('Port LiveKit invalide: 7880');
    if (!_isValidPort(8004)) errors.add('Port Token Service invalide: 8004');
    if (!_isValidPort(8005)) errors.add('Port Exercises API invalide: 8005');
    
    // Vérifier que les clés API ne sont pas vides
    if (livekitApiKey.isEmpty) errors.add('Clé API LiveKit manquante');
    if (livekitApiSecret.isEmpty) errors.add('Secret API LiveKit manquant');
    
    return errors;
  }
  
  static bool _isValidPort(int port) {
    return port > 0 && port <= 65535;
  }
}
