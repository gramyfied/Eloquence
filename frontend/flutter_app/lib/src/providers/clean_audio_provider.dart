import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ajout de l'import Riverpod
import '../services/clean_livekit_service.dart';
import '../../data/models/session_model.dart'; // Assurez-vous que ce chemin est correct

final cleanAudioProvider = ChangeNotifierProvider<CleanAudioProvider>((ref) {
  final provider = CleanAudioProvider(ref.watch(cleanLiveKitServiceProvider)); // Dépendance au service
  // Écouter les changements du service pour notifier les auditeurs de ce provider
  ref.onDispose(() => provider.disposeCleanAudioProvider());
  return provider;
});

// Provider pour CleanLiveKitService lui-même, s'il doit être accessible indépendamment
final cleanLiveKitServiceProvider = Provider<CleanLiveKitService>((ref) {
  final service = CleanLiveKitService();
  ref.onDispose(() => service.dispose());
  return service;
});


class CleanAudioProvider extends ChangeNotifier {
  final CleanLiveKitService _service;

  CleanAudioProvider(this._service) {
    _service.addListener(_onServiceUpdate); // Écouter les changements du service
  }

  CleanLiveKitService get service => _service;

  bool get isConnected => _service.isConnected;

  Future<bool> connect(SessionModel session) async {
    final result = await _service.connect(session.livekitUrl, session.token);
    // notifyListeners(); // Le service notifiera, et _onServiceUpdate s'en chargera
    return result;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    // notifyListeners(); // Le service notifiera
  }
  
  void _onServiceUpdate() {
    notifyListeners(); // Répercuter les notifications du service
  }

  void disposeCleanAudioProvider() { // Renommé pour éviter la confusion avec ChangeNotifier.dispose
    _service.removeListener(_onServiceUpdate);
    // Le service lui-même sera disposé par son propre provider (cleanLiveKitServiceProvider)
    super.dispose();
  }
}