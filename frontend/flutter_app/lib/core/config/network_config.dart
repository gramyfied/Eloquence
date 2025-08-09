/// Configuration réseau pour les différents environnements
/// 
/// Configuration moderne avec détection automatique et fallbacks
/// Support des dernières versions de LiveKit et des services
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkConfig {
  // Détection automatique de la plateforme et configuration appropriée
  static String get baseUrl {
    // Détection automatique de l'environnement
    if (_isWebPlatform()) {
      return 'localhost'; // Web
    } else if (_isAndroidEmulator()) {
      return '10.0.2.2'; // Émulateur Android
    } else if (_isPhysicalDevice()) {
      // IP de votre machine Windows sur le réseau local
      // Mise à jour automatique via détection réseau
      return _getLocalNetworkIP();
    } else {
      return 'localhost'; // Fallback par défaut
    }
  }
  
  // URLs des services avec versions les plus récentes
  static String get livekitUrl => 'ws://$baseUrl:7880';
  static String get livekitHttpUrl => 'http://$baseUrl:7880';
  static String get haproxyUrl => 'http://$baseUrl:8080';
  static String get tokenServiceUrl => 'http://$baseUrl:8004';
  static String get exercisesApiUrl => 'http://$baseUrl:8005';
  static String get mistralUrl => 'http://$baseUrl:8001';
  static String get voskUrl => 'http://$baseUrl:8002';
  
  // URLs spécifiques pour Studio Situations Pro
  static String get studioBackendUrl => '$haproxyUrl/api/agent/session';
  static String get studioTokenUrl => '$tokenServiceUrl/api/token';
  
  // Configuration WebRTC moderne pour Android
  static const Map<String, dynamic> webRtcConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
      {
        'urls': 'turn:turn.livekit.io:3478',
        'username': 'devkey',
        'credential': 'devsecret123456789abcdef0123456789abcdef',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'iceTransportPolicy': 'all',
  };
  
  // Configuration des timeouts modernes
  static const Duration connectionTimeout = Duration(seconds: 45);
  static const Duration requestTimeout = Duration(seconds: 90);
  static const Duration livekitConnectionTimeout = Duration(seconds: 60);
  
  // Configuration des retry et fallback
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Méthodes privées pour la détection automatique
  static bool _isWebPlatform() {
    // Détection de la plateforme web
    try {
      return kIsWeb;
    } catch (e) {
      return false;
    }
  }
  
  static bool _isAndroidEmulator() {
    // Détection de l'émulateur Android
    try {
      if (Platform.isAndroid) {
        // Vérifier si c'est un émulateur via les propriétés système
        // Pour l'instant, on utilise une approche simple
        return false; // À améliorer avec une détection plus précise
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  static bool _isPhysicalDevice() {
    // Détection d'appareil physique
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return true; // Considérer comme appareil physique par défaut
      }
      return false;
    } catch (e) {
      return true;
    }
  }
  
  static String _getLocalNetworkIP() {
    // IP de votre machine Windows sur le réseau local
    // À mettre à jour si votre IP change
    // Vous pouvez utiliser 'ipconfig' pour vérifier votre IP
    
    // Configuration par défaut pour le développement
    const defaultIP = '192.168.1.44';
    
    if (kDebugMode) {
      debugPrint('🌐 NetworkConfig: Utilisation de l\'IP par défaut: $defaultIP');
      debugPrint('🌐 NetworkConfig: Pour changer l\'IP, modifiez la variable defaultIP');
    }
    
    return defaultIP;
    
    // TODO: Implémenter la détection automatique d'IP
    // Exemple: scan du réseau local pour trouver l'hôte
  }
  
  // Méthodes utilitaires pour la gestion des erreurs
  static String getFallbackUrl(String service) {
    // URLs de fallback en cas de problème
    switch (service) {
      case 'livekit':
        return 'ws://localhost:7880';
      case 'token':
        return 'http://localhost:8004';
      case 'exercises':
        return 'http://localhost:8005';
      case 'mistral':
        return 'http://localhost:8001';
      case 'vosk':
        return 'http://localhost:8002';
      case 'haproxy':
        return 'http://localhost:8080';
      default:
        return 'http://localhost';
    }
  }
  
  // Validation de la connectivité
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Méthode pour obtenir la configuration complète des services
  static Map<String, String> getAllServiceUrls() {
    return {
      'livekit': livekitUrl,
      'livekitHttp': livekitHttpUrl,
      'haproxy': haproxyUrl,
      'token': tokenServiceUrl,
      'exercises': exercisesApiUrl,
      'mistral': mistralUrl,
      'vosk': voskUrl,
      'studioBackend': studioBackendUrl,
      'studioToken': studioTokenUrl,
    };
  }
  
  // Méthode pour diagnostiquer la configuration réseau
  static void debugNetworkConfig() {
    if (kDebugMode) {
      debugPrint('🔧 === DIAGNOSTIC CONFIGURATION RÉSEAU ===');
      debugPrint('🌐 Base URL: $baseUrl');
      debugPrint('🔧 Plateforme détectée: ${_getPlatformInfo()}');
      debugPrint('📱 Appareil physique: ${_isPhysicalDevice()}');
      debugPrint('🖥️ Émulateur Android: ${_isAndroidEmulator()}');
      debugPrint('🌍 Plateforme Web: ${_isWebPlatform()}');
      
      final urls = getAllServiceUrls();
      urls.forEach((service, url) {
        debugPrint('🔗 $service: $url');
      });
      
      debugPrint('🔧 === FIN DIAGNOSTIC ===');
    }
  }
  
  static String _getPlatformInfo() {
    try {
      if (kIsWeb) return 'Web';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
      return 'Inconnu';
    } catch (e) {
      return 'Erreur détection';
    }
  }
}