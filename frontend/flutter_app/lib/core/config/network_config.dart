/// Configuration réseau pour les différents environnements
/// 
/// Sur Android physique, 'localhost' pointe vers le téléphone lui-même.
/// Il faut utiliser l'adresse IP de la machine hôte sur le réseau local.
class NetworkConfig {
  // Détection automatique de la plateforme et configuration appropriée
  static String get baseUrl {
    // Pour Android physique, utiliser l'IP de votre machine Windows
    // Pour l'émulateur Android, utiliser 10.0.2.2
    // Pour iOS simulateur/physique et web, utiliser localhost
    
    const bool isPhysicalDevice = true; // Mettre à false pour émulateur
    
    if (isPhysicalDevice) {
      // IP de votre machine Windows sur le réseau local
      // À mettre à jour si votre IP change
      return '192.168.1.44';
    } else {
      // Pour émulateur Android ou développement local
      return '10.0.2.2'; // Alias de l'émulateur Android pour localhost de l'hôte
    }
  }
  
  // URLs des services
  static String get livekitUrl => 'ws://$baseUrl:8780';
  static String get livekitHttpUrl => 'http://$baseUrl:8780';
  static String get haproxyUrl => 'http://$baseUrl:8080';
  static String get tokenServiceUrl => 'http://$baseUrl:8804';
  static String get exercisesApiUrl => 'http://$baseUrl:8005';
  static String get mistralUrl => 'http://$baseUrl:8001';
  static String get voskUrl => 'http://$baseUrl:8002';
  
  // URLs spécifiques pour Studio Situations Pro
  static String get studioBackendUrl => '$haproxyUrl/api/agent/session';
  static String get studioTokenUrl => '$tokenServiceUrl/api/token';
  
  // Configuration WebRTC pour Android
  static const Map<String, dynamic> webRtcConfig = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302'],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };
  
  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration requestTimeout = Duration(seconds: 60);
}