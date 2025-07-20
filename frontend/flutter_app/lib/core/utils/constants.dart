import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration API dynamique pour mobile et développement
class ApiConstants {
  // Configuration de base
  static const String defaultPort = '8000';
  static const String defaultVoskPort = '8003';
  static const String defaultLiveKitPort = '7880';
  static const String defaultMistralPort = '8000';
  
  /// Obtenir l'IP de la machine hôte dynamiquement
  static String get hostIP {
    // Priorité 1 : Variable d'environnement MOBILE_HOST_IP
    final envIP = dotenv.env['MOBILE_HOST_IP'];
    if (envIP != null && envIP.isNotEmpty) {
      return envIP;
    }
    
    // Priorité 2 : IP depuis app_config.dart (fallback)
    if (kDebugMode && Platform.isAndroid) {
      // Pour Android émulateur : 10.0.2.2
      // Pour device physique : utiliser l'IP locale
      return '192.168.1.44'; // TODO: Remplacer par votre IP locale
    }
    
    // Priorité 3 : localhost pour web/desktop
    return 'localhost';
  }
  
  /// URL de base pour l'API backend
  static String get baseUrl {
    const protocol = kIsWeb ? 'http' : 'http'; // HTTPS en production
    final host = hostIP;
    final port = dotenv.env['API_PORT'] ?? defaultPort;
    return '$protocol://$host:$port';
  }
  
  /// URL pour VOSK STT
  static String get voskUrl {
    const protocol = kIsWeb ? 'http' : 'http';
    final host = hostIP;
    final port = dotenv.env['VOSK_PORT'] ?? defaultVoskPort;
    return '$protocol://$host:$port';
  }
  
  
  /// URL pour LiveKit
  static String get liveKitUrl {
    const protocol = kIsWeb ? 'ws' : 'ws'; // WSS en production
    final host = hostIP;
    final port = dotenv.env['LIVEKIT_PORT'] ?? defaultLiveKitPort;
    return '$protocol://$host:$port';
  }
  
  /// URL pour le service Mistral/LLM
  static String get llmServiceUrl {
    // Utiliser l'URL complète depuis .env si disponible
    final envUrl = dotenv.env['LLM_SERVICE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Sinon construire l'URL
    const protocol = kIsWeb ? 'http' : 'http';
    final host = hostIP;
    final port = dotenv.env['LLM_PORT'] ?? defaultMistralPort;
    return '$protocol://$host:$port/api/v1/eloquence/llm/analyze';
  }
  
  /// Configuration ICE pour WebRTC/LiveKit
  static const List<Map<String, dynamic>> iceServers = [
    {"urls": ["stun:stun.l.google.com:19302"]},
    {"urls": ["stun:stun1.l.google.com:19302"]},
    {"urls": ["stun:stun2.l.google.com:19302"]},
    {"urls": ["stun:stun3.l.google.com:19302"]},
  ];
  
  /// Timeouts optimisés pour mobile
  static const Duration apiTimeout = Duration(seconds: 4); // Réduit de 15s
  static const Duration voskTimeout = Duration(seconds: 6); // Timeout VOSK optimisé mobile
  static const Duration mistralTimeout = Duration(seconds: 4); // Optimisé
  static const Duration liveKitConnectTimeout = Duration(seconds: 3);
  
  /// Mode debug
  static bool get isDebugMode => kDebugMode;
  
  /// Platform detection
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isWeb => kIsWeb;
  
  /// Afficher la configuration actuelle (pour debug)
  static void printConfiguration() {
    if (kDebugMode) {
      print('=== Configuration API ===');
      print('Host IP: $hostIP');
      print('Base URL: $baseUrl');
      print('VOSK URL: $voskUrl');
      print('LiveKit URL: $liveKitUrl');
      print('LLM Service URL: $llmServiceUrl');
      print('Platform: ${Platform.operatingSystem}');
      print('Is Mobile: $isMobile');
      print('======================');
    }
  }
}

/// Configuration de cache optimisée
class CacheConstants {
  static const Duration memoryExpiration = Duration(minutes: 10);
  static const Duration diskExpiration = Duration(hours: 24);
  static const int maxMemoryCacheSize = 100;
  static const int maxDiskCacheSize = 500;
  static const String cachePrefix = 'eloquence_cache_';
}

/// Configuration de performance
class PerformanceConstants {
  static const int maxTokensMistral = 500; // Limité pour réduire latence
  static const double temperatureMistral = 0.3; // Plus déterministe pour cache
  static const int audioChunkSize = 10; // Secondes par chunk audio
  static const int audioSampleRate = 16000; // 16kHz pour mobile
  static const int audioBitrate = 64000; // 64kbps pour mobile
}