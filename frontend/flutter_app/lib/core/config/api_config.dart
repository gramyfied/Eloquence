import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  /// Obtient l'URL de base pour l'API Mistral selon l'environnement
  static String getMistralApiUrl() {
    // En mode debug, utiliser localhost pour tous les environnements locaux
    if (kDebugMode) {
      return 'http://localhost:8001/v1/chat/completions';
    }
    
    // Production ou défaut
    return 'https://api.eloquence.app/v1/chat/completions'; // URL de production
  }
  
  /// Obtient l'URL pour LiveKit
  static String getLiveKitUrl() {
    if (kDebugMode) {
      return 'ws://localhost:7880';
    }
    
    return 'wss://livekit.eloquence.app'; // URL de production
  }
  
  /// Obtient l'URL pour le WebSocket de streaming
  static String getStreamingWebSocketUrl() {
    if (kDebugMode) {
      return 'ws://localhost:8002/ws/conversation';
    }
    
    return 'wss://streaming.eloquence.app/ws/conversation'; // URL de production
  }
  
  /// Détecte si on est sur un émulateur Android
  static bool _isAndroidEmulator() {
    try {
      return Platform.isAndroid && 
             (Platform.environment['ANDROID_EMULATOR'] != null ||
              Platform.environment['ANDROID_AVD_HOME'] != null);
    } catch (e) {
      return false;
    }
  }
  
  /// Configuration pour le timeout des requêtes
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Headers par défaut pour les requêtes API
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
