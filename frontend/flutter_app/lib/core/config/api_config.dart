import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  /// Obtient l'URL de base pour l'API Mistral selon l'environnement
  static String getMistralApiUrl() {
    // En mode debug sur web, utiliser localhost
    if (kIsWeb && kDebugMode) {
      return 'http://localhost:8001/v1/chat/completions';
    }
    
    // Sur mobile (Android/iOS), utiliser l'IP de la machine hôte
    if (!kIsWeb) {
      // Pour Android émulateur
      if (kDebugMode && _isAndroidEmulator()) {
        return 'http://10.0.2.2:8001/v1/chat/completions';
      }
      
      // Pour appareil physique ou iOS, utiliser l'IP locale
      // IMPORTANT: Cette IP est celle de votre machine sur le réseau local
      // Pour trouver votre IP:
      // - Windows: ipconfig
      // - Mac/Linux: ifconfig ou ip addr
      const String localNetworkIP = '192.168.1.44'; // IP de votre machine
      
      return 'http://$localNetworkIP:8001/v1/chat/completions';
    }
    
    // Production ou défaut
    return 'https://api.eloquence.app/v1/chat/completions'; // URL de production
  }
  
  /// Obtient l'URL pour LiveKit
  static String getLiveKitUrl() {
    if (kIsWeb && kDebugMode) {
      return 'ws://localhost:7880';
    }
    
    if (!kIsWeb) {
      if (kDebugMode && _isAndroidEmulator()) {
        return 'ws://10.0.2.2:7880';
      }
      
      const String localNetworkIP = '192.168.1.44'; // IP de votre machine
      return 'ws://$localNetworkIP:7880';
    }
    
    return 'wss://livekit.eloquence.app'; // URL de production
  }
  
  /// Obtient l'URL pour le WebSocket de streaming
  static String getStreamingWebSocketUrl() {
    if (kIsWeb && kDebugMode) {
      return 'ws://localhost:8002/ws/conversation';
    }
    
    if (!kIsWeb) {
      if (kDebugMode && _isAndroidEmulator()) {
        return 'ws://10.0.2.2:8002/ws/conversation';
      }
      
      const String localNetworkIP = '192.168.1.44'; // IP de votre machine
      return 'ws://$localNetworkIP:8002/ws/conversation';
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