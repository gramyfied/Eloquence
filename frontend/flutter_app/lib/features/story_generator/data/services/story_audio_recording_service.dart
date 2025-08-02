import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../confidence_boost/data/services/emergency_audio_service.dart';

/// 🎤 SERVICE AUDIO ROBUSTE POUR HISTOIRES
///
/// Version corrigée basée sur SimpleAudioService pour résoudre le problème des fichiers de 44 bytes :
/// ✅ Configuration Flutter Sound optimisée pour Android Samsung
/// ✅ Gestion robuste des permissions microphone avancées
/// ✅ Détection des problèmes hardware avec tests réels
/// ✅ Système de fallback multicouche avec EmergencyAudioService
/// ✅ Validation audio en temps réel et diagnostic détaillé
class StoryAudioRecordingService {
  static const String _tag = 'StoryAudioRecording';
  
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  int _recordingAttempts = 0;
  
  // 🚨 SERVICE D'URGENCE POUR CONTOURNEMENT BLOCAGES ANDROID
  final EmergencyAudioService _emergencyService = EmergencyAudioService();
  bool _isEmergencyMode = false;
  bool _emergencyAvailable = false;
  
  // Configuration audio robuste pour Android + Vosk
  static const int _sampleRate = 16000;
  static const int _bitRate = 128000; // Réduit pour compatibilité Samsung
  static const Codec _primaryCodec = Codec.pcm16WAV;
  static const Codec _fallbackCodec = Codec.aacADTS; // Fallback si WAV échoue
  static const int _minValidFileSize = 1000; // 1KB minimum
  static const int _maxRecordingAttempts = 3;
  
  bool get isInitialized => _isInitialized;
  bool get isRecording => _recorder?.isRecording ?? false;

  /// 🎯 INITIALISATION ROBUSTE AVEC FALLBACK D'URGENCE
  Future<bool> initialize() async {
    try {
      logger.i(_tag, '🔧 INITIALISATION SERVICE AUDIO ROBUSTE...');
      
      if (_isInitialized) {
        logger.i(_tag, '♻️ Service déjà initialisé, nettoyage...');
        await dispose();
      }
      
      _recorder = FlutterSoundRecorder();
      logger.i(_tag, '✅ FlutterSoundRecorder créé');
      
      // ÉTAPE 1: Tentative initialisation standard avec vérifications avancées
      logger.i(_tag, '🎤 Tentative initialisation standard Samsung-compatible...');
      if (await _checkAndRequestPermissionsAdvanced()) {
        try {
          await _recorder!.openRecorder();
          logger.i(_tag, '✅ Recorder ouvert avec succès');
          
          // Test RÉEL d'accès microphone (critique pour Samsung)
          final realAccessTest = await _testRealMicrophoneAccess();
          if (realAccessTest) {
            // Test validation hardware strict
            final hardwareTest = await _validateMicrophoneHardwareStrict();
            if (hardwareTest) {
              _isInitialized = true;
              _recordingAttempts = 0;
              _isEmergencyMode = false;
              logger.i(_tag, '🎉 SERVICE AUDIO INITIALISÉ EN MODE STANDARD');
              return true;
            } else {
              logger.w(_tag, '⚠️ Test hardware microphone strict échoué');
            }
          } else {
            logger.e(_tag, '❌ CRITIQUE: Test accès microphone réel échoué');
          }
        } catch (e) {
          logger.w(_tag, '⚠️ Échec ouverture recorder standard: $e');
        }
      }
      
      // ÉTAPE 2: FALLBACK - Service d'urgence
      logger.i(_tag, '🚨 Tentative initialisation service d\'urgence...');
      final emergencyInitialized = await _initializeEmergencyService();
      if (emergencyInitialized) {
        _isEmergencyMode = true;
        _isInitialized = true;
        _recordingAttempts = 0;
        logger.i(_tag, '🎉 SERVICE AUDIO INITIALISÉ EN MODE D\'URGENCE');
        return true;
      }
      
      // ÉTAPE 3: Échec total
      logger.e(_tag, '❌ ÉCHEC CRITIQUE: Impossible d\'initialiser l\'audio (standard + urgence)');
      await dispose();
      return false;
      
    } catch (e) {
      logger.e(_tag, '💥 ERREUR FATALE INITIALISATION: $e');
      await dispose();
      return false;
    }
  }
  
  /// Vérification et demande de permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      logger.i(_tag, '🔍 Vérification statut actuel permissions...');
      final micStatus = await Permission.microphone.status;
      logger.i(_tag, 'Statut microphone: $micStatus');
      
      // Diagnostics détaillés des permissions
      logger.i(_tag, '🔍 DIAGNOSTIC PERMISSIONS DÉTAILLÉ:');
      logger.i(_tag, '   - isDenied: ${micStatus.isDenied}');
      logger.i(_tag, '   - isGranted: ${micStatus.isGranted}');
      logger.i(_tag, '   - isRestricted: ${micStatus.isRestricted}');
      logger.i(_tag, '   - isPermanentlyDenied: ${micStatus.isPermanentlyDenied}');
      logger.i(_tag, '   - isLimited: ${micStatus.isLimited}');
      logger.i(_tag, '   - Platform: ${Platform.operatingSystem}');
      
      if (!micStatus.isGranted) {
        logger.i(_tag, '📋 Demande de permission microphone...');
        final result = await Permission.microphone.request();
        logger.i(_tag, 'Résultat demande: $result');
        
        if (!result.isGranted) {
          logger.e(_tag, '❌ Permission microphone refusée par utilisateur');
          return false;
        }
        logger.i(_tag, '✅ Permission microphone accordée');
      } else {
        logger.i(_tag, '✅ Permission microphone déjà accordée');
      }
      
      // Permissions supplémentaires pour Android
      if (Platform.isAndroid) {
        logger.i(_tag, '🤖 Android détecté, vérification storage...');
        final storageStatus = await Permission.storage.status;
        logger.i(_tag, 'Statut storage: $storageStatus');
        
        if (storageStatus.isDenied) {
          logger.i(_tag, '📋 Demande permission storage...');
          final result = await Permission.storage.request();
          logger.i(_tag, 'Résultat storage: $result');
        }
      }
      
      return true;
    } catch (e) {
      logger.e(_tag, '💥 Erreur vérification permissions: $e');
      return false;
    }
  }
  
  /// Test d'accès microphone ROBUSTE avec diagnostics détaillés
  Future<bool> _validateMicrophoneAccess() async {
    try {
      logger.i(_tag, '🧪 Test de validation microphone (500ms)...');
      
      final tempDir = await getTemporaryDirectory();
      final testPath = '${tempDir.path}/test_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _recorder!.startRecorder(
        toFile: testPath,
        codec: _primaryCodec,
        sampleRate: _sampleRate,
        bitRate: 64000, // Bitrate réduit pour test
        numChannels: 1,
      );
      
      // Test plus long pour s'assurer d'avoir du contenu
      await Future.delayed(const Duration(milliseconds: 500));
      await _recorder!.stopRecorder();
      
      final testFile = File(testPath);
      if (await testFile.exists()) {
        final size = await testFile.length();
        logger.i(_tag, '📏 Taille fichier test: ${size} bytes');
        
        // Nettoyage
        await testFile.delete();
        
        // Test STRICT - arrêter de retourner true quand ça échoue !
        if (size > 100) {  // Headers WAV (44) + au moins 56 bytes de données
          logger.i(_tag, '✅ Test microphone réussi (${size} bytes)');
          return true;
        } else {
          logger.e(_tag, '❌ ÉCHEC CRITIQUE: Fichier test petit (${size} bytes) - microphone Samsung défaillant');
          return false; // 🚨 CORRECTION: Ne plus accepter les échecs !
        }
      } else {
        logger.e(_tag, '❌ ÉCHEC CRITIQUE: Fichier test non créé - problème Samsung détecté');
        return false; // 🚨 CORRECTION: Ne plus accepter les échecs !
      }
      
    } catch (e) {
      logger.e(_tag, '❌ ÉCHEC CRITIQUE Test microphone: $e');
      return false; // 🚨 CORRECTION: Ne plus masquer les vrais problèmes !
    }
  }
  
  /// Démarre l'enregistrement d'une histoire
  Future<String?> startRecording() async {
    try {
      logger.i(_tag, '🎯 DÉMARRAGE ENREGISTREMENT...');
      
      if (!_isInitialized) {
        logger.e(_tag, '❌ Service non initialisé');
        return null;
      }
      logger.i(_tag, '✅ Service initialisé');
      
      // 🚨 SÉLECTION SERVICE SELON MODE
      if (_isEmergencyMode) {
        logger.i(_tag, '🚨 MODE D\'URGENCE: Utilisation EmergencyAudioService');
        
        logger.i(_tag, '🚨 Démarrage enregistrement avec service d\'urgence Samsung...');

        // Utiliser le service d'urgence (génère automatiquement son propre path)
        final bool started = await _emergencyService.startRecording();
        if (!started) {
          throw Exception('Échec démarrage service d\'urgence');
        }
        
        // 🚨 CRITIQUE: Définir _currentRecordingPath pour que stopRecording() fonctionne
        _currentRecordingPath = 'emergency_recording_in_progress';
        
        logger.i(_tag, '🎉 ENREGISTREMENT EMERGENCY DÉMARRÉ AVEC SUCCÈS');
        return 'emergency_recording_in_progress'; // Path temporaire, le vrai sera retourné par stopRecording()
        
      } else {
        logger.i(_tag, '🎤 MODE STANDARD: Utilisation FlutterSound');
        
        // Diagnostics pré-enregistrement
        logger.i(_tag, '🔍 DIAGNOSTICS PRE-ENREGISTREMENT:');
        logger.i(_tag, '   - Recorder initialisé: ${_recorder != null}');
        logger.i(_tag, '   - Recorder arrêté: ${_recorder!.isStopped}');
        logger.i(_tag, '   - Recorder en cours: ${_recorder!.isRecording}');
        logger.i(_tag, '   - Platform: ${Platform.operatingSystem}');
        
        if (_recorder!.isRecording) {
          logger.w(_tag, '⚠️ Enregistrement en cours, arrêt...');
          await _recorder!.stopRecorder();
        }
        
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = '${tempDir.path}/story_audio_${timestamp}.wav';
        logger.i(_tag, '📁 Chemin: $_currentRecordingPath');
        
        logger.i(_tag, '🎬 Démarrage enregistrement avec config:');
        logger.i(_tag, '   📊 Sample Rate: ${_sampleRate}Hz');
        logger.i(_tag, '   🎵 Bit Rate: ${_bitRate}bps');
        logger.i(_tag, '   🔊 Channels: 1 (Mono)');
        logger.i(_tag, '   🎛️ Codec: $_primaryCodec');
        
        final result = await _recorder!.startRecorder(
          toFile: _currentRecordingPath,
          codec: _primaryCodec,
          sampleRate: _sampleRate,
          bitRate: _bitRate,
          numChannels: 1,
        );
        
        logger.i(_tag, '📝 startRecorder() terminé');
        logger.i(_tag, '🎉 ENREGISTREMENT STANDARD DÉMARRÉ AVEC SUCCÈS');
        return _currentRecordingPath;
      }
      
    } catch (e) {
      logger.e(_tag, '💥 ERREUR DÉMARRAGE ENREGISTREMENT: $e');
      return null;
    }
  }
  
  /// Arrête l'enregistrement et retourne les données audio
  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      logger.i(_tag, '🛑 ARRÊT ENREGISTREMENT...');
      
      // 🚨 CORRECTION CRITIQUE: Vérification adaptée au mode d'urgence
      if (!_isInitialized) {
        logger.e(_tag, '❌ Service non initialisé');
        return {
          'valid': false,
          'error': 'Service non initialisé',
        };
      }
      
      // En mode d'urgence, on n'a pas besoin de _currentRecordingPath car EmergencyService gère ses propres paths
      if (!_isEmergencyMode && _currentRecordingPath == null) {
        logger.e(_tag, '❌ Pas d\'enregistrement standard en cours');
        return {
          'valid': false,
          'error': 'Pas d\'enregistrement en cours',
        };
      }
      
      // 🚨 ARRÊT SELON MODE
      if (_isEmergencyMode) {
        logger.i(_tag, '🚨 MODE D\'URGENCE: Arrêt EmergencyAudioService');
        
        // Arrêter le service d'urgence et récupérer le path
        final String? emergencyPath = await _emergencyService.stopRecording();
        logger.i(_tag, '✅ Enregistrement emergency arrêté');
        
        if (emergencyPath != null) {
          _currentRecordingPath = emergencyPath;
          logger.i(_tag, '📁 Path emergency récupéré: $_currentRecordingPath');
        } else {
          logger.e(_tag, '❌ Aucun path retourné par service d\'urgence');
        }
        
      } else {
        logger.i(_tag, '🎤 MODE STANDARD: Arrêt FlutterSound');
        
        // Diagnostics avant arrêt
        logger.i(_tag, '🔍 ÉTAT AVANT ARRÊT:');
        logger.i(_tag, '   - Recorder en cours: ${_recorder!.isRecording}');
        logger.i(_tag, '   - Recorder initialisé: ${_recorder != null}');
        
        logger.i(_tag, '🎤 Arrêt du recorder...');
        await _recorder!.stopRecorder();
        logger.i(_tag, '✅ Recorder standard arrêté');
      }
      
      final file = File(_currentRecordingPath!);
      logger.i(_tag, '📁 Vérification fichier: $_currentRecordingPath');
      
      final fileExists = await file.exists();
      logger.i(_tag, '📋 Fichier existe: $fileExists');
      
      if (fileExists) {
        final fileSize = await file.length();
        logger.i(_tag, '📊 Taille fichier: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
        
        // Informations détaillées sur le fichier
        final fileStat = await file.stat();
        logger.i(_tag, '📋 INFORMATIONS FICHIER DÉTAILLÉES:');
        logger.i(_tag, '   - Taille: ${fileSize} bytes');
        logger.i(_tag, '   - Modifié: ${fileStat.modified}');
        logger.i(_tag, '   - Type: ${fileStat.type}');
        logger.i(_tag, '   - Chemin: ${file.path}');
        logger.i(_tag, '   - Mode: ${_isEmergencyMode ? "🚨 URGENCE" : "🎤 STANDARD"}');
        
        // Diagnostic spécial pour fichiers 44 bytes (headers WAV seulement)
        if (fileSize == 44) {
          logger.w(_tag, '⚠️ PROBLÈME DÉTECTÉ: Fichier = 44 bytes (headers WAV seulement)');
          logger.w(_tag, '⚠️ CAUSES POSSIBLES:');
          logger.w(_tag, '   - Microphone hardware non fonctionnel');
          logger.w(_tag, '   - Émulateur sans support microphone');
          logger.w(_tag, '   - Permissions insuffisantes (même si accordées)');
          logger.w(_tag, '   - Problème driver audio Android');
        }
        
        if (fileSize > _minValidFileSize) {
          logger.i(_tag, '✅ Fichier valide (>${_minValidFileSize} bytes)');
          
          // Lire les données audio
          logger.i(_tag, '📖 Lecture données audio...');
          final audioBytes = await file.readAsBytes();
          
          // Diagnostic détaillé
          final duration = _estimateAudioDuration(fileSize);
          logger.i(_tag, '🎵 AUDIO CAPTURÉ AVEC SUCCÈS:');
          logger.i(_tag, '   📏 Taille: ${audioBytes.length} bytes');
          logger.i(_tag, '   ⏱️ Durée estimée: ${duration.inSeconds}s');
          logger.i(_tag, '   🎛️ Sample Rate: ${_sampleRate}Hz');
          logger.i(_tag, '   🚨 Service: ${_isEmergencyMode ? "Emergency" : "Standard"}');
          
          // Nettoyer le fichier temporaire
          await file.delete();
          logger.i(_tag, '🗑️ Fichier temporaire supprimé');
          
          return {
            'audioData': audioBytes,
            'fileSize': fileSize,
            'duration': duration,
            'sampleRate': _sampleRate,
            'valid': true,
          };
        } else {
          logger.w(_tag, '⚠️ FICHIER TROP PETIT: ${fileSize} bytes (minimum: ${_minValidFileSize})');
          logger.w(_tag, '⚠️ POSSIBLE CAUSE: Microphone non fonctionnel ou émulateur sans hardware audio');
          await file.delete();
          return {
            'valid': false,
            'error': 'Enregistrement trop court: ${fileSize} bytes < ${_minValidFileSize} bytes minimum',
          };
        }
      } else {
        logger.e(_tag, '❌ FICHIER AUDIO NON TROUVÉ: $_currentRecordingPath');
        
        // Essayer de lister les fichiers dans le dossier pour diagnostic
        try {
          final tempDir = await getTemporaryDirectory();
          final files = await tempDir.list().toList();
          logger.i(_tag, '🔍 Fichiers dans temp:');
          for (final f in files) {
            logger.i(_tag, '   - ${f.path}');
          }
        } catch (e) {
          logger.e(_tag, '❌ Erreur listage temp: $e');
        }
        
        return {
          'valid': false,
          'error': 'Fichier audio non créé',
        };
      }
      
    } catch (e) {
      logger.e(_tag, '💥 ERREUR ARRÊT ENREGISTREMENT: $e');
      return {
        'valid': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Estime la durée audio basée sur la taille du fichier
  Duration _estimateAudioDuration(int fileSizeBytes) {
    if (fileSizeBytes <= 44) return Duration.zero;
    
    final audioBytesOnly = fileSizeBytes - 44; // Enlever headers WAV
    final bytesPerSecond = _sampleRate * 1 * 2; // 16-bit mono
    final seconds = audioBytesOnly / bytesPerSecond;
    
    return Duration(milliseconds: (seconds * 1000).round());
  }
  
  /// 🚨 INITIALISATION SERVICE D'URGENCE
  Future<bool> _initializeEmergencyService() async {
    try {
      logger.i(_tag, '🚨 Initialisation service d\'urgence Samsung...');
      
      _emergencyAvailable = await _emergencyService.initialize();
      if (!_emergencyAvailable) {
        logger.e(_tag, '❌ Service d\'urgence non disponible');
        return false;
      }
      
      logger.i(_tag, '✅ Service d\'urgence initialisé - MODE CONTOURNEMENT SAMSUNG ACTIVÉ');
      return true;
      
    } catch (e) {
      logger.e(_tag, '❌ Erreur initialisation service d\'urgence: $e');
      return false;
    }
  }
  
  /// 🔐 VÉRIFICATION ET DEMANDE DE PERMISSIONS ANDROID AVANCÉES
  Future<bool> _checkAndRequestPermissionsAdvanced() async {
    try {
      logger.i(_tag, '🔍 DÉBUT VÉRIFICATION PERMISSIONS AVANCÉES SAMSUNG...');
      
      // Diagnostic détaillé des permissions actuelles
      final micStatus = await Permission.microphone.status;
      logger.i(_tag, '🔍 DIAGNOSTIC PERMISSIONS DÉTAILLÉ:');
      logger.i(_tag, '   - Statut microphone: $micStatus');
      logger.i(_tag, '   - isDenied: ${micStatus.isDenied}');
      logger.i(_tag, '   - isGranted: ${micStatus.isGranted}');
      logger.i(_tag, '   - isRestricted: ${micStatus.isRestricted}');
      logger.i(_tag, '   - isPermanentlyDenied: ${micStatus.isPermanentlyDenied}');
      logger.i(_tag, '   - isLimited: ${micStatus.isLimited}');
      logger.i(_tag, '   - Platform: ${Platform.operatingSystem}');
      
      // ÉTAPE 1: Permission microphone
      if (!micStatus.isGranted) {
        logger.i(_tag, '📋 Demande permission microphone...');
        final result = await Permission.microphone.request();
        logger.i(_tag, 'Résultat demande microphone: $result');
        
        if (!result.isGranted) {
          logger.e(_tag, '❌ Permission microphone refusée définitivement');
          return false;
        }
        logger.i(_tag, '✅ Permission microphone accordée');
      } else {
        logger.i(_tag, '✅ Permission microphone déjà accordée');
      }
      
      // ÉTAPE 2: Permissions Android spécifiques (crucial pour Samsung)
      if (Platform.isAndroid) {
        logger.i(_tag, '🤖 Configuration permissions Samsung/Android spécifiques...');
        
        // Permission stockage externe
        final storageStatus = await Permission.storage.status;
        logger.i(_tag, 'Statut storage: $storageStatus');
        if (storageStatus.isDenied) {
          logger.i(_tag, '📋 Demande permission storage...');
          final result = await Permission.storage.request();
          logger.i(_tag, 'Résultat storage: $result');
        }
        
        // Permission accès media/audio (Android 11+)
        try {
          final mediaStatus = await Permission.mediaLibrary.status;
          if (mediaStatus.isDenied) {
            final mediaResult = await Permission.mediaLibrary.request();
            logger.i(_tag, '🎵 Permission media: $mediaResult');
          }
        } catch (e) {
          logger.d(_tag, 'Permission media non disponible: $e');
        }
        
        // Permission audio système (nouveau Android)
        try {
          final audioStatus = await Permission.audio.status;
          if (audioStatus.isDenied) {
            final audioResult = await Permission.audio.request();
            logger.i(_tag, '🔊 Permission audio système: $audioResult');
          }
        } catch (e) {
          logger.d(_tag, 'Permission audio système non disponible: $e');
        }
      }
      
      // ÉTAPE 3: Test RÉEL d'accès microphone (CRUCIAL pour Samsung)
      logger.i(_tag, '🧪 LANCEMENT TEST ACCÈS MICROPHONE RÉEL...');
      final realTest = await _testRealMicrophoneAccess();
      if (!realTest) {
        logger.e(_tag, '❌ CRITIQUE: Permission accordée mais accès microphone réel bloqué sur Samsung');
        logger.e(_tag, '🚨 Solution: Vérifiez les paramètres système Android/One UI');
        return false;
      }
      
      logger.i(_tag, '✅ Toutes les permissions Samsung validées avec succès');
      return true;
      
    } catch (e) {
      logger.e(_tag, '💥 Erreur critique vérification permissions: $e');
      return false;
    }
  }
  
  /// 🧪 TEST RÉEL D'ACCÈS MICROPHONE (détection blocage système Samsung)
  Future<bool> _testRealMicrophoneAccess() async {
    try {
      logger.i(_tag, '🧪 Test accès microphone réel Samsung...');
      
      // Test avec recorder temporaire
      final testRecorder = FlutterSoundRecorder();
      
      try {
        await testRecorder.openRecorder();
        
        // Test enregistrement ultra-court pour vérifier accès
        final tempDir = await getTemporaryDirectory();
        final testPath = '${tempDir.path}/samsung_access_test_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        await testRecorder.startRecorder(
          toFile: testPath,
          codec: Codec.pcm16WAV,
          sampleRate: 16000,
          bitRate: 64000, // Bitrate très bas pour test
          numChannels: 1,
        );
        
        // Attendre 200ms minimum
        await Future.delayed(const Duration(milliseconds: 200));
        
        await testRecorder.stopRecorder();
        await testRecorder.closeRecorder();
        
        // Vérifier si on a capturé quelque chose
        final testFile = File(testPath);
        if (await testFile.exists()) {
          final size = await testFile.length();
          await testFile.delete(); // Nettoyer
          
          logger.i(_tag, '📊 Test accès Samsung: ${size} bytes capturés');
          
          if (size > 44) { // Plus que les headers WAV
            logger.i(_tag, '✅ Accès microphone Samsung réel confirmé');
            return true;
          } else {
            logger.e(_tag, '❌ Samsung: Microphone accessible mais aucune donnée capturée');
            return false;
          }
        }
        
        logger.e(_tag, '❌ Samsung: Fichier test non créé');
        return false;
        
      } finally {
        try {
          await testRecorder.closeRecorder();
        } catch (e) {
          // Ignorer erreur fermeture
        }
      }
      
    } catch (e) {
      logger.e(_tag, '❌ Test accès microphone Samsung échoué: $e');
      return false;
    }
  }
  
  /// 🔧 TEST VALIDATION HARDWARE MICROPHONE STRICT
  Future<bool> _validateMicrophoneHardwareStrict() async {
    try {
      logger.i(_tag, '🔍 Test validation microphone hardware STRICT...');
      
      // Test plus long (500ms) pour vérifier que le micro fonctionne vraiment
      final tempDir = await getTemporaryDirectory();
      final testPath = '${tempDir.path}/samsung_mic_test_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _recorder!.startRecorder(
        toFile: testPath,
        codec: _primaryCodec,
        sampleRate: _sampleRate,
        bitRate: _bitRate,
        numChannels: 1,
      );
      
      // Attendre 500ms
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _recorder!.stopRecorder();
      
      // Vérifier si le fichier contient des données
      final testFile = File(testPath);
      if (await testFile.exists()) {
        final size = await testFile.length();
        await testFile.delete(); // Nettoyer
        
        logger.i(_tag, '📊 Test hardware Samsung: ${size} bytes');
        
        if (size > _minValidFileSize) {
          logger.i(_tag, '✅ Test microphone Samsung RÉUSSI: ${size} bytes');
          return true;
        } else if (size == 44) {
          logger.e(_tag, '❌ PROBLÈME SAMSUNG DÉTECTÉ: Fichier = 44 bytes (headers seulement)');
          logger.e(_tag, '🚨 CAUSES SAMSUNG PROBABLES:');
          logger.e(_tag, '   1. 🎤 Microphone Samsung défaillant/occupé');
          logger.e(_tag, '   2. 🔧 Driver audio One UI non fonctionnel');
          logger.e(_tag, '   3. 🔒 Permissions niveau système insuffisantes');
          logger.e(_tag, '   4. 🎮 Autre app Samsung utilise microphone exclusivement');
          return false;
        } else {
          logger.w(_tag, '⚠️ Test microphone Samsung suspect: seulement ${size} bytes');
          return false;
        }
      }
      
      logger.e(_tag, '❌ Samsung: Fichier test non créé');
      return false;
      
    } catch (e) {
      logger.e(_tag, '❌ Test microphone Samsung échoué: $e');
      return false;
    }
  }

  /// Vérifie l'état des permissions
  Future<bool> checkPermissions() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
  
  /// 🧹 NETTOYER RESSOURCES SAMSUNG (STANDARD + URGENCE)
  Future<void> dispose() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      // Nettoyage service d'urgence Samsung
      if (_emergencyAvailable) {
        await _emergencyService.dispose();
        _emergencyAvailable = false;
      }
      
      // Nettoyage service standard Samsung
      if (_recorder != null) {
        if (_recorder!.isRecording) {
          await _recorder!.stopRecorder();
        }
        await _recorder!.closeRecorder();
        _recorder = null;
      }
      
      _isInitialized = false;
      _isEmergencyMode = false;
      _currentRecordingPath = null;
      _recordingAttempts = 0;
      
      logger.i(_tag, '🧹 StoryAudioRecordingService Samsung nettoyé (standard + urgence)');
    } catch (e) {
      logger.e(_tag, '❌ Erreur nettoyage Samsung: $e');
    }
  }
}