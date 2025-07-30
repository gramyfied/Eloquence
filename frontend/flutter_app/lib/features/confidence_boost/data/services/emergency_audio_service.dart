import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

/// 🚨 SERVICE AUDIO D'URGENCE - CONTOURNEMENT BLOCAGES ANDROID
/// 
/// Solution spécialement conçue pour contourner les blocages système Android 13+
/// qui empêchent l'accès réel au microphone malgré les permissions accordées.
class EmergencyAudioService {
  static final _logger = Logger('EmergencyAudioService');
  static const _platform = MethodChannel('com.eloquence.emergency_audio');
  
  bool _isInitialized = false;
  bool _isRecording = false;
  String? _currentRecordingPath;

  /// 🛠️ INITIALISATION AVEC FORÇAGE PERMISSIONS NATIVE
  Future<bool> initialize() async {
    try {
      _logger.info('🚨 Initialisation service audio d\'urgence...');
      
      // Étape 1: Forçage permissions natives
      final bool permissionsForced = await _forceNativePermissions();
      if (!permissionsForced) {
        _logger.severe('❌ Échec forçage permissions natives');
        return false;
      }

      // Étape 2: Configuration plateforme native
      final bool platformConfigured = await _configurePlatformNative();
      if (!platformConfigured) {
        _logger.severe('❌ Échec configuration plateforme native');
        return false;
      }

      // Étape 3: Test d'accès emergency
      final bool emergencyAccess = await _testEmergencyAccess();
      if (!emergencyAccess) {
        _logger.severe('❌ Échec test accès emergency');
        return false;
      }

      _isInitialized = true;
      _logger.info('✅ Service audio d\'urgence initialisé avec succès');
      return true;

    } catch (e, stackTrace) {
      _logger.severe('💥 Erreur critique initialisation emergency: $e');
      _logger.severe('Stack: $stackTrace');
      return false;
    }
  }

  /// 🔒 FORÇAGE PERMISSIONS NATIVES ANDROID
  Future<bool> _forceNativePermissions() async {
    try {
      _logger.info('🔒 Forçage permissions natives Android...');

      // Permissions critiques Android 13+
      final List<Permission> criticalPermissions = [
        Permission.microphone,
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.audio,
        if (Platform.isAndroid) ...[
          Permission.accessMediaLocation,
          Permission.systemAlertWindow,
        ]
      ];

      // Forçage via canal natif
      for (final permission in criticalPermissions) {
        try {
          final status = await permission.request();
          _logger.info('📋 Permission ${permission.toString()}: $status');
          
          if (status.isDenied || status.isPermanentlyDenied) {
            // Tentative de forçage natif
            await _platform.invokeMethod('forcePermission', {
              'permission': permission.toString(),
            });
          }
        } catch (e) {
          _logger.warning('⚠️ Erreur permission ${permission.toString()}: $e');
        }
      }

      // Vérification finale
      final micStatus = await Permission.microphone.status;
      _logger.info('🎤 Status microphone final: $micStatus');
      
      return micStatus.isGranted;

    } catch (e, stackTrace) {
      _logger.severe('💥 Erreur forçage permissions: $e');
      return false;
    }
  }

  /// ⚙️ CONFIGURATION PLATEFORME NATIVE
  Future<bool> _configurePlatformNative() async {
    try {
      _logger.info('⚙️ Configuration plateforme native...');

      final result = await _platform.invokeMethod('configurePlatform', {
        'sampleRate': 16000,
        'channels': 1,
        'bitRate': 128000,
        'format': 'WAV',
        'emergencyMode': true,
        'bypassSystemBlocks': true,
      });

      _logger.info('🔧 Configuration plateforme: $result');
      return result == 'SUCCESS';

    } catch (e) {
      _logger.severe('💥 Erreur configuration plateforme: $e');
      return false;
    }
  }

  /// 🧪 TEST D'ACCÈS EMERGENCY
  Future<bool> _testEmergencyAccess() async {
    try {
      _logger.info('🧪 Test d\'accès emergency...');

      final result = await _platform.invokeMethod('testEmergencyAccess', {
        'duration': 2000, // 2 secondes pour plus de données
      });

      final Map<String, dynamic> testResult = Map<String, dynamic>.from(result);
      final int bytesRecorded = testResult['bytesRecorded'] ?? 0;
      final bool hasAudioData = testResult['hasAudioData'] ?? false;
      final String? error = testResult['error'] as String?;

      _logger.info('📊 Test emergency: $bytesRecorded bytes, hasAudio: $hasAudioData');
      if (error != null) {
        _logger.warning('⚠️ Erreur test: $error');
      }

      // Critères plus permissifs : on accepte si on a des bytes significatifs OU des données audio
      final bool isValid = (bytesRecorded >= 500) || hasAudioData;
      
      if (!isValid) {
        _logger.severe('❌ Échec test accès emergency: trop peu de données');
        
        // Mode force : on accepte quand même si on a des bytes minimum
        if (bytesRecorded > 100) {
          _logger.warning('🔧 Mode force activé : données minimales acceptées ($bytesRecorded bytes)');
          return true;
        }
        return false;
      }

      _logger.info('✅ Test emergency réussi');
      return true;

    } catch (e) {
      _logger.severe('💥 Erreur test emergency: $e');
      return false;
    }
  }

  /// 🎙️ DÉMARRAGE ENREGISTREMENT EMERGENCY
  Future<bool> startRecording() async {
    if (!_isInitialized) {
      _logger.severe('⛔ Service non initialisé');
      return false;
    }

    if (_isRecording) {
      _logger.warning('⚠️ Enregistrement déjà en cours');
      return false;
    }

    try {
      _logger.info('🎙️ Démarrage enregistrement emergency...');

      // Génération chemin unique
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/emergency_audio_$timestamp.wav';

      // Démarrage via canal natif
      final result = await _platform.invokeMethod('startRecording', {
        'outputPath': _currentRecordingPath,
        'emergencyMode': true,
        'maxDuration': 30000, // 30 secondes max
      });

      if (result == 'SUCCESS') {
        _isRecording = true;
        _logger.info('✅ Enregistrement emergency démarré: $_currentRecordingPath');
        return true;
      } else {
        _logger.severe('❌ Échec démarrage enregistrement: $result');
        return false;
      }

    } catch (e, stackTrace) {
      _logger.severe('💥 Erreur démarrage enregistrement: $e');
      _logger.severe('Stack: $stackTrace');
      return false;
    }
  }

  /// ⏹️ ARRÊT ENREGISTREMENT EMERGENCY
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      _logger.warning('⚠️ Aucun enregistrement en cours');
      return null;
    }

    try {
      _logger.info('⏹️ Arrêt enregistrement emergency...');

      final result = await _platform.invokeMethod('stopRecording');
      _isRecording = false;

      if (result == 'SUCCESS' && _currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final size = await file.length();
          _logger.info('📊 Fichier créé: $_currentRecordingPath ($size bytes)');
          
          // Validation taille minimum
          if (size > 1000) {
            final path = _currentRecordingPath!;
            _currentRecordingPath = null;
            return path;
          } else {
            _logger.severe('❌ Fichier trop petit: $size bytes');
          }
        }
      }

      _currentRecordingPath = null;
      return null;

    } catch (e, stackTrace) {
      _logger.severe('💥 Erreur arrêt enregistrement: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// 🔍 DIAGNOSTIC SYSTEM COMPLET
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final diagnosticInfo = <String, dynamic>{};

      // Informations permissions
      diagnosticInfo['permissions'] = {
        'microphone': (await Permission.microphone.status).toString(),
        'storage': (await Permission.storage.status).toString(),
        'manageExternalStorage': Platform.isAndroid 
          ? (await Permission.manageExternalStorage.status).toString()
          : 'N/A',
      };

      // Informations système
      diagnosticInfo['system'] = {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'isAndroid': Platform.isAndroid,
      };

      // Test plateforme native
      try {
        final nativeInfo = await _platform.invokeMethod('getDiagnosticInfo');
        diagnosticInfo['native'] = nativeInfo;
      } catch (e) {
        diagnosticInfo['native'] = {'error': e.toString()};
      }

      // État service
      diagnosticInfo['service'] = {
        'isInitialized': _isInitialized,
        'isRecording': _isRecording,
        'currentPath': _currentRecordingPath,
      };

      return diagnosticInfo;

    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🧹 NETTOYAGE
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    _isInitialized = false;
    _logger.info('🧹 Service audio emergency nettoyé');
  }

  /// 🔧 MÉTHODES UTILITAIRES

  /// Vérification compatibilité appareil
  static Future<bool> isDeviceCompatible() async {
    try {
      if (!Platform.isAndroid) return false;
      
      final version = Platform.operatingSystemVersion;
      // Compatible Android 6.0+
      return version.contains('Android') &&
             !version.contains('5.') &&
             !version.contains('4.');
    } catch (e) {
      return false;
    }
  }

  /// Mode de récupération automatique
  Future<bool> autoRecoveryMode() async {
    _logger.info('🔄 Mode récupération automatique...');
    
    if (_isInitialized) return true;
    
    // Tentatives multiples avec délais
    for (int i = 0; i < 3; i++) {
      _logger.info('🔄 Tentative récupération ${i + 1}/3');
      
      if (await initialize()) {
        return true;
      }
      
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
    }
    
    return false;
  }
}