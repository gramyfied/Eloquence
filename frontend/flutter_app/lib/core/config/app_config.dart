import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'dart:io' show Platform;

class AppConfig {
  static const bool isProduction = false;

  // Fonction utilitaire pour substituer localhost avec l'IP correcte en mode debug
  static String _replaceLocalhostWithDevIp(String url) {
    if (kDebugMode && url.contains('localhost')) {
      // 10.0.2.2 est l'alias de localhost pour l'émulateur Android
      // Pour iOS ou les appareils physiques, utilisez l'IP de votre machine de développement
      final devIp = Platform.isAndroid ? '10.0.2.2' : dotenv.env['DEV_SERVER_IP'] ?? '192.168.1.44';
      return url.replaceFirst('localhost', devIp);
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
  
  static String get mistralBaseUrl {
    // Utiliser MISTRAL_BASE_URL s'il est spécifié, sinon fallback
    final url = dotenv.env['MISTRAL_BASE_URL'] ?? 'http://localhost:8000/mistral';
    return isProduction ? "https://api.mistral.ai/v1/chat/completions" : _replaceLocalhostWithDevIp(url);
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
