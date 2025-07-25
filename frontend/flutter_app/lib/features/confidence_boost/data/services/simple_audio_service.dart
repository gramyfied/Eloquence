import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// 🎤 SERVICE AUDIO SIMPLIFIÉ POUR REST
/// 
/// Remplace l'UnifiedLiveKitService complexe par une approche simple :
/// ✅ flutter_sound pour enregistrement local
/// ✅ Fichiers WAV temporaires
/// ✅ Upload direct vers API REST
/// ✅ Gestion permissions microphone
class SimpleAudioService {
  final Logger _logger = Logger();
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;
  String? _currentRecordingPath;

  /// 🎯 INITIALISATION
  Future<bool> initialize() async {
    try {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      _isInitialized = true;
      _logger.i('✅ SimpleAudioService initialisé');
      return true;
    } catch (e) {
      _logger.e('❌ Erreur initialisation audio: $e');
      return false;
    }
  }

  /// 🎤 DÉMARRER ENREGISTREMENT
  Future<String?> startRecording() async {
    try {
      if (!_isInitialized) {
        _logger.e('Service non initialisé');
        return null;
      }

      // Vérifier permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _logger.e('Permission microphone refusée');
        return null;
      }

      // Créer fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/audio_$timestamp.wav';

      // Démarrer enregistrement
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000, // Optimal pour analyse vocale
        bitRate: 64000,
      );

      _logger.i('🎤 Enregistrement démarré: $_currentRecordingPath');
      return _currentRecordingPath;

    } catch (e) {
      _logger.e('❌ Erreur démarrage enregistrement: $e');
      return null;
    }
  }

  /// 🛑 ARRÊTER ENREGISTREMENT
  Future<File?> stopRecording() async {
    try {
      if (!_isInitialized || _currentRecordingPath == null) {
        return null;
      }

      await _recorder!.stopRecorder();
      
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        _logger.i('✅ Enregistrement terminé: ${file.lengthSync()} bytes');
        return file;
      }

      return null;

    } catch (e) {
      _logger.e('❌ Erreur arrêt enregistrement: $e');
      return null;
    }
  }

  /// 📊 VÉRIFIER PERMISSIONS
  Future<bool> checkPermissions() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// 🧹 NETTOYER RESSOURCES
  Future<void> dispose() async {
    try {
      await _recorder?.closeRecorder();
      _isInitialized = false;
      _logger.i('🧹 SimpleAudioService nettoyé');
    } catch (e) {
      _logger.e('❌ Erreur nettoyage: $e');
    }
  }

  /// 📁 NETTOYER FICHIERS TEMPORAIRES
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file.path.contains('audio_') && file.path.endsWith('.wav')) {
          await file.delete();
        }
      }
      
      _logger.i('🧹 Fichiers temporaires nettoyés');
    } catch (e) {
      _logger.e('❌ Erreur nettoyage fichiers: $e');
    }
  }

  /// 📏 OBTENIR TAILLE FICHIER
  Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      _logger.e('❌ Erreur taille fichier: $e');
      return 0;
    }
  }

  /// ⏱️ CALCULER DURÉE AUDIO (approximation)
  Duration estimateAudioDuration(int fileSizeBytes, {int sampleRate = 16000, int bitRate = 64000}) {
    // Calcul approximatif basé sur la taille du fichier
    final seconds = (fileSizeBytes * 8) / bitRate;
    return Duration(seconds: seconds.round());
  }
}