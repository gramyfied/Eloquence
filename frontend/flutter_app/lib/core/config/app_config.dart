import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'dart:io' show Platform;

class AppConfig {
  static const bool isProduction = false;
  
  // 🌐 CONFIGURATION SERVEUR - Switcher entre local et distant
  static const bool useRemoteServer = false; // ✅ CORRIGÉ: Serveur local pour confidence boost
  static const String remoteServerIp = '51.159.110.4'; // IP du serveur distant
  static const String localServerIp = '192.168.1.44'; // IP locale pour développement

  // Fonction pour obtenir l'IP du serveur selon la configuration
  static String get currentServerIp {
    if (useRemoteServer) {
      debugPrint('🌐 Utilisation du serveur distant: $remoteServerIp');
      return remoteServerIp;
    } else {
      debugPrint('🌐 Utilisation du serveur local: $localServerIp');
      return localServerIp;
    }
  }

  // Fonction utilitaire pour substituer localhost avec l'IP correcte en mode debug
  static String _replaceLocalhostWithDevIp(String url) {
    if (kDebugMode && url.contains('localhost')) {
      final newUrl = url.replaceFirst('localhost', currentServerIp);
      debugPrint('🌐 URL remplacée: $url → $newUrl');
      return newUrl;
    }
    return url;
  }

  // Fonction pour construire une URL avec l'IP appropriée
  static String _buildUrl(String protocol, int port, [String path = '']) {
    final baseUrl = '$protocol://$currentServerIp:$port';
    return path.isNotEmpty ? '$baseUrl$path' : baseUrl;
  }

  // URLs des services
  static String get livekitUrl {
    if (isProduction) {
      return "wss://your-prod-server.com";
    }
    return _buildUrl('ws', 7880);
  }

  // Clés API LiveKit
  static String? get livekitApiKey {
    return dotenv.env['LIVEKIT_API_KEY'] ?? (kDebugMode ? 'devkey' : null);
  }

  static String? get livekitApiSecret {
    return dotenv.env['LIVEKIT_API_SECRET'] ?? (kDebugMode ? 'dev-local-secret-32chars-min-req' : null);
  }

  // URL du serveur de tokens LiveKit (confirmé par diagnostic)
  static String get livekitTokenUrl {
    if (isProduction) {
      return "https://your-prod-server.com/livekit-tokens";
    }
    return _buildUrl('http', 8004); // ✅ CORRIGÉ: Suppression du /health
  }

  static String get whisperUrl {
    if (isProduction) {
      return "https://your-prod-server.com/stt";
    }
    return _buildUrl('http', 8001); // Port 8001 confirmé (Mistral service)
  }

  static String get azureTtsUrl {
    if (isProduction) {
      return "https://your-prod-server.com/tts";
    }
    return _buildUrl('http', 5002);
  }

  // 🎯 API UNIFIÉE ELOQUENCE (selon diagnostic Scaleway réel)
  static String get apiBaseUrl {
    if (isProduction) {
      return "https://api.eloquence.app";
    }
    return _buildUrl('http', 8000); // ✅ CORRIGÉ: Port 8000 selon test exhaustif
  }

  // API des exercices vocaux (utilise l'API unifiée)
  static String get exercisesApiUrl {
    if (isProduction) {
      return "https://exercises.eloquence.app";
    }
    return _buildUrl('http', 8005); // ✅ CORRIGÉ: Port 8005 eloquence-exercises-api avec Vosk STT
  }

  // 🎤 SERVICE VOSK STT (selon documentation README-new.md)
  static String get voskServiceUrl {
    if (isProduction) {
      return "https://your-prod-server.com/vosk";
    }
    return _buildUrl('http', 8012); // ✅ CORRIGÉ: Port 8012 selon Docker
  }

  // Service de streaming (legacy - utiliser API unifiée)
  static String get eloquenceStreamingApiUrl {
    if (isProduction) {
      return "https://streaming.eloquence.app";
    }
    return _buildUrl('http', 8005); // ✅ CORRIGÉ: Port 8005 eloquence-exercises-api avec Vosk STT
  }
  
  static String get mistralBaseUrl {
    // URL Scaleway Mistral avec ID unique
    final url = dotenv.env['MISTRAL_BASE_URL'] ?? 'https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1';
    return isProduction ? "https://api.scaleway.ai/18f6cc9d-07fc-49c3-a142-67be9b59ac63/v1" : url;
  }

  static String get redisUrl {
    final host = dotenv.env['REDIS_HOST'] ?? 'localhost';
    if (isProduction) {
      return "redis://your-prod-server.com:6379";
    } else {
      final devHost = _replaceLocalhostWithDevIp(host);
      return "redis://$devHost:6379";
    }
  }

  // Configuration ICE pour LiveKit (nécessaire pour les appareils physiques)
  static const List<Map<String, dynamic>> iceServers = [
    {"urls": ["stun:stun.l.google.com:19302"]},
    {"urls": ["stun:stun1.l.google.com:19302"]},
  ];
}
