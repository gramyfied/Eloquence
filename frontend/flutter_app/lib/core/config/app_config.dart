// Configuration générée automatiquement le 2025-06-23 21:13:01
// IP de la machine hôte: 192.168.1.44

class AppConfig {
  static const bool isProduction = false;

  // IP de votre machine de développement
  static const String devServerIP = "192.168.1.44";

  // Clé API (utilisant LIVEKIT_API_KEY comme fallback pour l'instant)
  static const String apiKey = "devkey"; // TODO: Vérifier si c'est la bonne clé pour l'API backend

  // URLs des services
  static String get livekitUrl =>
      isProduction ? "wss://your-prod-server.com" : "ws://$devServerIP:7880";

  static String get whisperUrl =>
      isProduction ? "https://your-prod-server.com/stt" : "http://$devServerIP:8001";

  static String get azureTtsUrl =>
      isProduction ? "https://your-prod-server.com/tts" : "http://$devServerIP:5002";

  // URL de base pour l'API backend
  static String get apiBaseUrl =>
      isProduction ? "https://your-prod-server.com/api" : "http://$devServerIP:8000";

  static String get redisUrl =>
      isProduction ? "redis://your-prod-server.com:6379" : "redis://$devServerIP:6379";

  // Configuration ICE pour LiveKit (nécessaire pour les appareils physiques)
  static const List<Map<String, dynamic>> iceServers = [
    {"urls": ["stun:stun.l.google.com:19302"]},
    {"urls": ["stun:stun1.l.google.com:19302"]},
  ];
}
