import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'dart:io' show Platform;

class AppConfig {
  static const bool isProduction = false;

  // Fonction utilitaire pour substituer localhost avec l'IP correcte en mode debug
  static String _replaceLocalhostWithDevIp(String url) {
    if (kDebugMode && url.contains('localhost')) {
      // FIX: Utiliser l'IP machine hôte pour tous les cas car Docker expose sur 0.0.0.0
      const devIp = '192.168.1.44';
      final newUrl = url.replaceFirst('localhost', devIp);
      debugPrint('🌐 URL remplacée: $url → $newUrl');
      return newUrl;
    }
    return url;
  }

  // URLs des services
  static String get livekitUrl {
    final url = dotenv.env['LIVEKIT_URL'] ?? 'ws://localhost:7880';
    return isProduction ? "wss://your-prod-server.com" : _replaceLocalhostWithDevIp(url);
  }

  // Clés API LiveKit
  static String? get livekitApiKey {
    return dotenv.env['LIVEKIT_API_KEY'] ?? (kDebugMode ? 'devkey' : null);
  }

  static String? get livekitApiSecret {
    return dotenv.env['LIVEKIT_API_SECRET'] ?? (kDebugMode ? 'secret' : null);
  }

  // URL du serveur de tokens LiveKit
  static String get livekitTokenUrl {
    final url = dotenv.env['LIVEKIT_TOKEN_URL'] ?? 'http://localhost:8004';
    return isProduction ? "https://your-prod-server.com/livekit-tokens" : _replaceLocalhostWithDevIp(url);
  }

  static String get whisperUrl {
    final url = dotenv.env['WHISPER_STT_URL'] ?? 'http://localhost:8001';
    return isProduction ? "https://your-prod-server.com/stt" : _replaceLocalhostWithDevIp(url);
  }

  static String get azureTtsUrl {
    final url = dotenv.env['TTS_SERVICE_URL'] ?? 'http://localhost:5002'; // Ou OPENAI_TTS_SERVICE_URL
    return isProduction ? "https://your-prod-server.com/tts" : _replaceLocalhostWithDevIp(url);
  }

  static String get apiBaseUrl {
    final url = dotenv.env['LLM_SERVICE_URL'] ?? 'http://localhost:8000'; // BACKEND_URL ou LLM_SERVICE_URL
    return isProduction ? "https://api.eloquence.app" : _replaceLocalhostWithDevIp(url);
  }

  // Nouveau service unifié eloquence-streaming-api
  static String get eloquenceStreamingApiUrl {
    final url = dotenv.env['ELOQUENCE_STREAMING_API_URL'] ?? 'http://localhost:8003';
    // TEMPORARY FIX: Force IP machine hôte pour tous les cas
    if (kDebugMode) {
      const debugUrl = 'http://192.168.1.44:8003';
      debugPrint('🔧 DEBUG: Force eloquenceStreamingApiUrl = $debugUrl (IP machine hôte)');
      return debugUrl;
    }
    return isProduction ? "https://streaming.eloquence.app" : _replaceLocalhostWithDevIp(url);
  }

  static String get voskServiceUrl {
    final url = dotenv.env['VOSK_SERVICE_URL'] ?? 'http://localhost:2700';
    return isProduction ? "https://your-prod-server.com/vosk" : _replaceLocalhostWithDevIp(url);
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
