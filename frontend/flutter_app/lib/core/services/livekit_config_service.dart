/// Service de configuration LiveKit pour Eloquence
/// 
/// Ce service gère la configuration et la connexion à LiveKit
/// en utilisant la configuration d'environnement unifiée
import 'package:livekit_client/livekit_client.dart';
import '../config/environment_config.dart';

class LiveKitConfigService {
  static const String _roomName = 'eloquence-room';
  static const String _identity = 'eloquence-user';
  
  /// Configuration LiveKit avec les paramètres d'environnement
  static ConnectOptions get connectOptions {
    return ConnectOptions(
      autoSubscribe: true,
      // Configuration moderne pour Android
    );
  }
  
  /// Configuration WebRTC pour LiveKit
  static List<RTCIceServer> get iceServers {
    return EnvironmentConfig.webRtcIceServers
        .map((url) => RTCIceServer(urls: [url]))
        .toList();
  }
  
  /// URL du serveur LiveKit
  static String get serverUrl => EnvironmentConfig.livekitUrl;
  
  /// Clés API LiveKit
  static String get apiKey => EnvironmentConfig.livekitApiKey;
  static String get apiSecret => EnvironmentConfig.livekitApiSecret;
  
  /// Configuration de la salle
  static String get roomName => _roomName;
  static String get identity => _identity;
  
  /// Méthode pour diagnostiquer la configuration LiveKit
  static void debugLiveKitConfig() {
    if (EnvironmentConfig.isDebug) {
      print('🔧 === CONFIGURATION LIVEKIT ===');
      print('🌐 Serveur: $serverUrl');
      print('🔑 API Key: $apiKey');
      print('🔐 API Secret: ${apiSecret.substring(0, 8)}...');
      print('📱 Salle: $roomName');
      print('👤 Identité: $identity');
      print('⏱️ Timeout connexion: ${EnvironmentConfig.livekitConnectionTimeout.inSeconds}s');
      print('🔧 === FIN CONFIGURATION ===');
    }
  }
}
