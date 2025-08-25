/// Configuration réseau pour les différents environnements
///
/// Sur Android physique, 'localhost' pointe vers le téléphone lui-même.
/// Il faut utiliser l'adresse IP de la machine hôte sur le réseau local.
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration réseau pour les différents environnements
class NetworkConfig {
  // Base URL pour le développement local (Docker Compose)
  // Utilise 'localhost' pour les plateformes qui le supportent (Web, iOS, Desktop)
  // Pour Android, utilise 10.0.2.2 sur émulateur, et permet un override via .env pour appareil physique
  static String get _baseHost {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'localhost';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Permettre un override via .env (MOBILE_HOST_IP) pour appareil physique
      final envHost = dotenv.env['MOBILE_HOST_IP'];
      if (envHost != null && envHost.isNotEmpty) {
        return envHost;
      }
      // Émulateur Android
      return '10.0.2.2';
    }
    return 'localhost'; // Fallback
  }

  // URLs des services (lecture .env si présent)
  static String get livekitUrl {
    final envUrl = dotenv.env['LIVEKIT_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'ws://$_baseHost:7880';
  }

  static String get livekitHttpUrl {
    // HTTP(s) équivalent de livekitUrl si non fourni
    final envUrl = dotenv.env['LIVEKIT_HTTP_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://$_baseHost:7880';
  }

  static String get haproxyUrl => 'http://$_baseHost:8080';

  static String get tokenServiceUrl {
    final envUrl = dotenv.env['LIVEKIT_TOKEN_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://$_baseHost:8804';
  }

  static String get exercisesApiUrl {
    final envUrl = dotenv.env['EXERCISES_API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://$_baseHost:8005';
  }

  static String get mistralUrl {
    final envUrl = dotenv.env['MISTRAL_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://$_baseHost:8001';
  }

  static String get voskUrl {
    final envUrl = dotenv.env['VOSK_SERVICE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://$_baseHost:8002';
  }
  
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
