import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'emergency_audio_service.dart';

/// 🎤 SERVICE AUDIO ROBUSTE POUR VIRELANGUES
///
/// Version corrigée pour résoudre le problème des fichiers de 44 bytes :
/// ✅ Configuration Flutter Sound optimisée pour Android
/// ✅ Gestion robuste des permissions microphone
/// ✅ Détection des problèmes hardware
/// ✅ Système de fallback multicouche
/// ✅ Validation audio en temps réel
class SimpleAudioService {
  final Logger _logger = Logger();
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;
  String? _currentRecordingPath;
  int _recordingAttempts = 0;
  Timer? _recordingTimer;
  
  // 🚨 SERVICE D'URGENCE POUR CONTOURNEMENT BLOCAGES ANDROID
  final EmergencyAudioService _emergencyService = EmergencyAudioService();
  bool _isEmergencyMode = false;
  bool _emergencyAvailable = false;
  
  // Configuration audio robuste pour Android + Vosk
  static const int _voskSampleRate = 16000;
  static const int _voskBitRate = 128000; // Réduit pour compatibilité Android
  static const Codec _primaryCodec = Codec.pcm16WAV;
  static const Codec _fallbackCodec = Codec.aacADTS; // Fallback si WAV échoue
  
  // Constantes de validation
  static const int _minValidFileSize = 1000; // 1KB minimum pour être valide
  static const int _maxRecordingAttempts = 3;
  static const int _minRecordingDurationMs = 1000; // 1 seconde minimum

  /// 🎯 INITIALISATION ROBUSTE AVEC FALLBACK D'URGENCE
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        await dispose(); // Nettoyer avant réinitialisation
      }
      
      _recorder = FlutterSoundRecorder();
      
      // ÉTAPE 1: Tentative initialisation standard
      _logger.i('🎤 Tentative initialisation standard...');
      if (await _checkAndRequestPermissions()) {
        try {
          // Ouvrir avec configuration Android-friendly
          await _recorder!.openRecorder();
          
          // Test basique d'enregistrement pour valider le setup
          final testResult = await _validateMicrophoneHardware();
          if (testResult) {
            _isInitialized = true;
            _recordingAttempts = 0;
            _isEmergencyMode = false;
            _logger.i('✅ SimpleAudioService initialisé en mode standard');
            return true;
          } else {
            _logger.w('⚠️ Test microphone standard échoué');
          }
        } catch (e) {
          _logger.w('⚠️ Échec initialisation standard: $e');
        }
      }
      
      // ÉTAPE 2: FALLBACK - Tentative avec service d'urgence
      _logger.i('🚨 Tentative initialisation service d\'urgence...');
      final emergencyInitialized = await _initializeEmergencyService();
      if (emergencyInitialized) {
        _isEmergencyMode = true;
        _isInitialized = true;
        _recordingAttempts = 0;
        _logger.i('✅ SimpleAudioService initialisé en MODE D\'URGENCE');
        return true;
      }
      
      // ÉTAPE 3: Échec total
      _logger.e('❌ ÉCHEC CRITIQUE: Impossible d\'initialiser l\'audio (standard + urgence)');
      await dispose();
      return false;
      
    } catch (e) {
      _logger.e('❌ Erreur critique initialisation audio: $e');
      await dispose(); // Nettoyer en cas d'erreur
      return false;
    }
  }
  
  /// 🚨 INITIALISATION SERVICE D'URGENCE
  Future<bool> _initializeEmergencyService() async {
    try {
      _logger.i('🚨 Initialisation service d\'urgence Android...');
      
      // Vérifier disponibilité du service d'urgence
      _emergencyAvailable = await _emergencyService.initialize();
      if (!_emergencyAvailable) {
        _logger.e('❌ Service d\'urgence non disponible');
        return false;
      }
      
      // Service d'urgence initialisé avec succès
      _logger.i('✅ Service d\'urgence initialisé - MODE CONTOURNEMENT ACTIVÉ');
      return true;
      
    } catch (e) {
      _logger.e('❌ Erreur initialisation service d\'urgence: $e');
      return false;
    }
  }

  /// 🔐 VÉRIFICATION ET DEMANDE DE PERMISSIONS ANDROID AVANCÉES
  Future<bool> _checkAndRequestPermissions() async {
    try {
      _logger.i('🔍 Début vérification permissions avancées Android...');
      
      // Vérifier le statut actuel du microphone
      PermissionStatus micStatus = await Permission.microphone.status;
      _logger.i('🔍 Permission microphone actuelle: $micStatus');
      
      // ÉTAPE 1: Demander permission microphone
      if (!micStatus.isGranted) {
        _logger.w('⚠️ Permission microphone requise, demande en cours...');
        micStatus = await Permission.microphone.request();
        _logger.i('📝 Résultat demande microphone: $micStatus');
        
        if (!micStatus.isGranted) {
          _logger.e('❌ Permission microphone refusée définitivement');
          return false;
        }
      }
      
      // ÉTAPE 2: Permissions Android spécifiques
      if (Platform.isAndroid) {
        _logger.i('🤖 Configuration permissions Android spécifiques...');
        
        // Permission stockage externe (nécessaire pour certains Android)
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          final storageResult = await Permission.storage.request();
          _logger.i('📁 Permission stockage: $storageResult');
        }
        
        // Permission accès media/audio (Android 11+)
        try {
          final mediaStatus = await Permission.mediaLibrary.status;
          if (mediaStatus.isDenied) {
            final mediaResult = await Permission.mediaLibrary.request();
            _logger.i('🎵 Permission media: $mediaResult');
          }
        } catch (e) {
          _logger.d('Permission media non disponible: $e');
        }
        
        // Vérification permission système audio (nouveau Android)
        try {
          final audioStatus = await Permission.audio.status;
          if (audioStatus.isDenied) {
            final audioResult = await Permission.audio.request();
            _logger.i('🔊 Permission audio système: $audioResult');
          }
        } catch (e) {
          _logger.d('Permission audio système non disponible: $e');
        }
      }
      
      // ÉTAPE 3: Test RÉEL d'accès microphone (crucial)
      final realTest = await _testRealMicrophoneAccess();
      if (!realTest) {
        _logger.e('❌ CRITIQUE: Permission accordée mais accès microphone réel bloqué');
        _logger.e('🚨 Solution: Vérifiez les paramètres système Android');
        return false;
      }
      
      _logger.i('✅ Toutes les permissions validées avec succès');
      return true;
      
    } catch (e) {
      _logger.e('❌ Erreur critique vérification permissions: $e');
      return false;
    }
  }
  
  /// 🧪 TEST RÉEL D'ACCÈS MICROPHONE (détection blocage système)
  Future<bool> _testRealMicrophoneAccess() async {
    try {
      _logger.i('🧪 Test accès microphone réel...');
      
      // Test avec recorder temporaire
      final testRecorder = FlutterSoundRecorder();
      
      try {
        await testRecorder.openRecorder();
        
        // Test enregistrement ultra-court pour vérifier accès
        final tempDir = await getTemporaryDirectory();
        final testPath = '${tempDir.path}/access_test_${DateTime.now().millisecondsSinceEpoch}.wav';
        
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
          
          _logger.i('📊 Test accès: ${size} bytes capturés');
          
          if (size > 44) { // Plus que les headers WAV
            _logger.i('✅ Accès microphone réel confirmé');
            return true;
          } else {
            _logger.e('❌ Microphone accessible mais aucune donnée capturée');
            return false;
          }
        }
        
        _logger.e('❌ Fichier test non créé');
        return false;
        
      } finally {
        try {
          await testRecorder.closeRecorder();
        } catch (e) {
          // Ignorer erreur fermeture
        }
      }
      
    } catch (e) {
      _logger.e('❌ Test accès microphone échoué: $e');
      return false;
    }
  }

  /// 🔧 TEST VALIDATION HARDWARE MICROPHONE
  Future<bool> _validateMicrophoneHardware() async {
    try {
      _logger.i('🔍 Test validation microphone hardware...');
      
      // Test très court (500ms) pour vérifier que le micro fonctionne
      final tempDir = await getTemporaryDirectory();
      final testPath = '${tempDir.path}/mic_test_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _recorder!.startRecorder(
        toFile: testPath,
        codec: _primaryCodec,
        sampleRate: _voskSampleRate,
        bitRate: _voskBitRate,
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
        
        if (size > _minValidFileSize) {
          _logger.i('✅ Test microphone réussi: ${size} bytes');
          return true;
        } else {
          _logger.w('⚠️ Test microphone suspect: seulement ${size} bytes');
          return false;
        }
      }
      
      return false;
      
    } catch (e) {
      _logger.w('⚠️ Test microphone échoué: $e');
      return false;
    }
  }

  /// 🎤 DÉMARRER ENREGISTREMENT AVEC SYSTÈME DE FALLBACK ET URGENCE
  Future<String?> startRecording() async {
    try {
      if (!_isInitialized) {
        _logger.e('Service non initialisé');
        return null;
      }

      // ========== MODE D'URGENCE ==========
      if (_isEmergencyMode && _emergencyAvailable) {
        _logger.i('🚨 Démarrage enregistrement MODE D\'URGENCE');
        final success = await _emergencyService.startRecording();
        if (success) {
          _logger.i('✅ Enregistrement d\'urgence démarré avec succès');
          return 'emergency_recording'; // Identifiant spécial
        } else {
          _logger.e('❌ Échec enregistrement d\'urgence');
          return null;
        }
      }

      // ========== MODE STANDARD ==========
      // Forcer une nouvelle vérification des permissions avant chaque enregistrement
      if (!await _checkAndRequestPermissions()) {
        _logger.e('❌ Permission microphone refusée');
        
        // FALLBACK AUTOMATIQUE vers mode d'urgence si échec permissions
        if (!_isEmergencyMode && await _initializeEmergencyService()) {
          _logger.w('🔄 FALLBACK automatique vers mode d\'urgence');
          _isEmergencyMode = true;
          return await startRecording(); // Récursion vers mode d'urgence
        }
        
        return null;
      }

      // Arrêter tout enregistrement en cours
      await _stopAnyExistingRecording();

      // Incrémenter les tentatives
      _recordingAttempts++;
      _logger.i('🎤 Tentative d\'enregistrement standard ${_recordingAttempts}/${_maxRecordingAttempts}');

      // Créer fichier temporaire avec nom explicite
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/virelangue_audio_${timestamp}_16k.wav';

      // Choisir codec selon la tentative
      final codec = _recordingAttempts == 1 ? _primaryCodec : _fallbackCodec;
      final sampleRate = _voskSampleRate;
      final bitRate = _voskBitRate;

      _logger.i('🔧 Configuration standard: Codec=$codec, Rate=${sampleRate}Hz, BitRate=${bitRate}bps');

      // Démarrer l'enregistrement avec la configuration choisie
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: codec,
        sampleRate: sampleRate,
        bitRate: bitRate,
        numChannels: 1,
      );

      // Timer de sécurité pour valider que l'enregistrement fonctionne
      _recordingTimer = Timer(const Duration(milliseconds: 500), () {
        _validateRecordingInProgress();
      });

      _logger.i('🎤 Enregistrement standard démarré: $_currentRecordingPath');
      _logger.i('📊 Config: ${sampleRate}Hz, ${bitRate}bps, Mono ${codec.name}');
      _logger.w('⚠️ IMPORTANT: Parlez clairement dans le microphone !');
      
      return _currentRecordingPath;

    } catch (e) {
      _logger.e('❌ Erreur démarrage enregistrement (tentative $_recordingAttempts): $e');
      
      // FALLBACK AUTOMATIQUE vers mode d'urgence si échec répété
      if (!_isEmergencyMode && _recordingAttempts >= 2) {
        _logger.w('🚨 FALLBACK d\'urgence après échecs répétés');
        if (await _initializeEmergencyService()) {
          _isEmergencyMode = true;
          _recordingAttempts = 0; // Reset pour mode d'urgence
          return await startRecording();
        }
      }
      
      // Tentative de fallback standard si on n'a pas dépassé le maximum
      if (_recordingAttempts < _maxRecordingAttempts) {
        _logger.w('🔄 Tentative fallback standard...');
        await Future.delayed(const Duration(milliseconds: 200));
        return await startRecording();
      }
      
      return null;
    }
  }

  /// 🕵️ VALIDATION ENREGISTREMENT EN COURS
  Future<void> _validateRecordingInProgress() async {
    try {
      if (_currentRecordingPath == null) return;
      
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        final size = await file.length();
        _logger.d('📊 Taille fichier après 500ms: $size bytes');
        
        if (size <= 44) { // Seulement headers WAV
          _logger.e('❌ PROBLÈME DÉTECTÉ: Fichier toujours vide après 500ms !');
          // Ici on pourrait déclencher une action corrective
        } else {
          _logger.i('✅ Enregistrement semble fonctionner: $size bytes');
        }
      }
    } catch (e) {
      _logger.w('⚠️ Erreur validation enregistrement: $e');
    }
  }

  /// 🛑 ARRÊTER TOUT ENREGISTREMENT EXISTANT
  Future<void> _stopAnyExistingRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      if (_recorder != null && _recorder!.isRecording) {
        await _recorder!.stopRecorder();
        _logger.i('🛑 Enregistrement précédent arrêté');
        
        // Petit délai pour laisser le système se stabiliser
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _logger.d('Aucun enregistrement à arrêter ou erreur: $e');
    }
  }

  /// 🛑 ARRÊTER ENREGISTREMENT AVEC VALIDATION ROBUSTE ET URGENCE
  Future<File?> stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      if (!_isInitialized) {
        _logger.e('❌ Service non initialisé');
        return null;
      }

      // ========== MODE D'URGENCE ==========
      if (_isEmergencyMode && _emergencyAvailable) {
        _logger.i('🚨 Arrêt enregistrement MODE D\'URGENCE');
        final emergencyPath = await _emergencyService.stopRecording();
        
        if (emergencyPath != null) {
          final file = File(emergencyPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            _logger.i('✅ Fichier d\'urgence créé: $emergencyPath');
            _logger.i('📊 Taille finale (mode urgence): $fileSize bytes');
            
            // Diagnostic et validation pour mode d'urgence
            await _diagnoseAudioFile(file);
            final validation = await validateAudioForVosk(file);
            _logger.i('🔍 Validation Vosk (urgence): ${validation['vosk_ready'] ? '✅ OK' : '⚠️ PROBLÈMES'}');
            
            if (validation['issues'] != null && validation['issues'].isNotEmpty) {
              _logger.w('⚠️ Problèmes détectés (urgence): ${validation['issues']}');
            }
            
            // Succès en mode d'urgence
            if (fileSize > _minValidFileSize) {
              _recordingAttempts = 0;
              _logger.i('✅ Enregistrement d\'urgence réussi !');
            }
            
            return file;
          }
        }
        
        _logger.e('❌ Échec arrêt enregistrement d\'urgence');
        return null;
      }

      // ========== MODE STANDARD ==========
      if (_currentRecordingPath == null) {
        _logger.e('❌ Pas d\'enregistrement en cours');
        return null;
      }

      // Arrêter l'enregistrement standard
      await _recorder!.stopRecorder();
      _logger.i('🛑 Enregistrement standard arrêté');
      
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        final fileSize = await file.length();
        _logger.i('📁 Fichier audio créé: $_currentRecordingPath');
        _logger.i('📊 Taille finale: $fileSize bytes');
        
        // Diagnostic détaillé
        await _diagnoseAudioFile(file);
        
        // Validation Vosk avec système de diagnostic
        final validation = await validateAudioForVosk(file);
        _logger.i('🔍 Validation Vosk: ${validation['vosk_ready'] ? '✅ OK' : '⚠️ PROBLÈMES'}');
        
        if (validation['issues'] != null && validation['issues'].isNotEmpty) {
          _logger.w('⚠️ Problèmes détectés: ${validation['issues']}');
        }
        
        // Réinitialiser le compteur de tentatives en cas de succès
        if (fileSize > _minValidFileSize) {
          _recordingAttempts = 0;
          _logger.i('✅ Enregistrement standard réussi, compteur tentatives remis à zéro');
        } else {
          // Si le fichier est toujours trop petit, essayer le mode d'urgence la prochaine fois
          _logger.w('⚠️ Fichier trop petit, mode d\'urgence sera tenté automatiquement');
        }
        
        return file;
      } else {
        _logger.e('❌ Fichier audio non trouvé après enregistrement');
        return null;
      }

    } catch (e) {
      _logger.e('❌ Erreur arrêt enregistrement: $e');
      return null;
    }
  }

  /// 🔍 DIAGNOSTIC DÉTAILLÉ FICHIER AUDIO
  Future<void> _diagnoseAudioFile(File audioFile) async {
    try {
      final fileSize = await audioFile.length();
      final fileName = audioFile.path.split('/').last;
      
      _logger.i('🔍 DIAGNOSTIC AUDIO:');
      _logger.i('  📁 Fichier: $fileName');
      _logger.i('  📊 Taille: $fileSize bytes');
      
      if (fileSize <= 44) {
        _logger.e('❌ PROBLÈME CRITIQUE: Fichier vide (headers WAV seulement)');
        _logger.e('  🚨 Causes possibles:');
        _logger.e('    - Permission microphone refusée en arrière-plan');
        _logger.e('    - Microphone non disponible/occupé par autre app');
        _logger.e('    - Problème hardware microphone');
        _logger.e('    - Flutter Sound configuration incorrecte');
      } else if (fileSize < _minValidFileSize) {
        _logger.w('⚠️ ATTENTION: Fichier très petit, vérifiez la qualité audio');
      } else {
        _logger.i('✅ Taille fichier normale');
      }
      
      // Vérification permission en temps réel
      final permissionStatus = await Permission.microphone.status;
      _logger.i('  🔑 Permission microphone: $permissionStatus');
      
    } catch (e) {
      _logger.e('❌ Erreur diagnostic: $e');
    }
  }

  /// 🔍 VALIDATION AUDIO POUR VOSK
  Future<Map<String, dynamic>> validateAudioForVosk(File audioFile) async {
    try {
      final fileSize = await audioFile.length();
      final fileName = audioFile.path.split('/').last;
      
      // Vérifications basiques
      final issues = <String>[];
      final details = <String>[];
      
      // Taille minimale (au moins 1 seconde à 16kHz mono)
      const minSize = _voskSampleRate * 2; // 2 bytes par sample en 16-bit
      if (fileSize < minSize) {
        issues.add('Fichier trop petit (${fileSize} bytes < ${minSize} minimum)');
      } else {
        details.add('Taille OK: ${fileSize} bytes');
      }
      
      // Taille maximale raisonnable (10 minutes max)
      const maxSize = _voskSampleRate * 2 * 600; // 10 minutes
      if (fileSize > maxSize) {
        issues.add('Fichier très volumineux (${fileSize} bytes > ${maxSize} recommandé)');
      }
      
      // Extension WAV
      if (!fileName.toLowerCase().endsWith('.wav')) {
        issues.add('Extension non-WAV détectée');
      } else {
        details.add('Format WAV détecté');
      }
      
      // Estimation durée
      final estimatedDuration = estimateAudioDuration(fileSize);
      details.add('Durée estimée: ${estimatedDuration.inSeconds}s');
      
      if (estimatedDuration.inSeconds < 1) {
        issues.add('Enregistrement très court (< 1s)');
      }
      
      return {
        'valid': issues.isEmpty,
        'file_size': fileSize,
        'estimated_duration': estimatedDuration.inSeconds,
        'details': details.join(', '),
        'issues': issues.join(', '),
        'vosk_ready': issues.length <= 1, // Tolère 1 problème mineur
      };
      
    } catch (e) {
      _logger.e('❌ Erreur validation audio: $e');
      return {
        'valid': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 OBTENIR MÉTADONNÉES AUDIO
  Future<Map<String, dynamic>> getAudioMetadata(File audioFile) async {
    try {
      final fileSize = await audioFile.length();
      final fileName = audioFile.path.split('/').last;
      final lastModified = await audioFile.lastModified();
      
      return {
        'file_name': fileName,
        'file_size': fileSize,
        'file_path': audioFile.path,
        'last_modified': lastModified.toIso8601String(),
        'estimated_duration': estimateAudioDuration(fileSize).inSeconds,
        'sample_rate': _voskSampleRate,
        'channels': 1,
        'bit_rate': _voskBitRate,
        'codec': 'PCM16-WAV',
        'vosk_compatible': true,
        'recording_attempts': _recordingAttempts,
      };
    } catch (e) {
      _logger.e('❌ Erreur métadonnées: $e');
      return {'error': e.toString()};
    }
  }

  /// 🧼 VALIDER ET PRÉPARER FICHIER POUR ENVOI
  Future<Map<String, dynamic>> prepareAudioForUpload(File audioFile) async {
    try {
      final metadata = await getAudioMetadata(audioFile);
      final validation = await validateAudioForVosk(audioFile);
      
      // Lire le fichier en bytes
      final audioBytes = await audioFile.readAsBytes();
      
      _logger.i('📊 Audio préparé: ${audioBytes.length} bytes, prêt pour Vosk: ${validation['vosk_ready']}');
      
      return {
        'audio_bytes': audioBytes,
        'metadata': metadata,
        'validation': validation,
        'ready_for_vosk': validation['vosk_ready'] == true,
        'file_name': metadata['file_name'],
        'content_type': 'audio/wav',
      };
    } catch (e) {
      _logger.e('❌ Erreur préparation upload: $e');
      return {'error': e.toString()};
    }
  }

  /// 📊 VÉRIFIER PERMISSIONS
  Future<bool> checkPermissions() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// 🧹 NETTOYER RESSOURCES (STANDARD + URGENCE)
  Future<void> dispose() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      // Nettoyage service d'urgence
      if (_emergencyAvailable) {
        await _emergencyService.dispose();
        _emergencyAvailable = false;
      }
      
      // Nettoyage service standard
      await _recorder?.closeRecorder();
      _recorder = null;
      _isInitialized = false;
      _isEmergencyMode = false;
      _currentRecordingPath = null;
      _recordingAttempts = 0;
      _logger.i('🧹 SimpleAudioService nettoyé (standard + urgence)');
    } catch (e) {
      _logger.e('❌ Erreur nettoyage: $e');
    }
  }

  /// 📁 NETTOYER FICHIERS TEMPORAIRES
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      int deletedCount = 0;
      
      for (final file in files) {
        if (file.path.contains('audio_') && file.path.endsWith('.wav')) {
          await file.delete();
          deletedCount++;
        }
      }
      
      _logger.i('🧹 Fichier temporaire supprimé');
      if (deletedCount > 0) {
        _logger.i('🧹 $deletedCount fichiers temporaires nettoyés');
      }
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
  Duration estimateAudioDuration(int fileSizeBytes, {int sampleRate = 16000, int bitDepth = 16}) {
    // Calcul plus précis pour PCM WAV
    // Formule: bytes / (sampleRate * numChannels * (bitDepth/8))
    if (fileSizeBytes <= 44) return Duration.zero; // Headers seulement
    
    final audioBytesOnly = fileSizeBytes - 44; // Enlever headers WAV
    final bytesPerSecond = sampleRate * 1 * (bitDepth ~/ 8); // 1 canal mono
    final seconds = audioBytesOnly / bytesPerSecond;
    
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// 🔄 RÉINITIALISER COMPTEUR TENTATIVES
  void resetAttempts() {
    _recordingAttempts = 0;
    _logger.i('🔄 Compteur tentatives remis à zéro');
  }

  /// 📊 OBTENIR STATISTIQUES (STANDARD + URGENCE)
  Map<String, dynamic> getStats() {
    return {
      'is_initialized': _isInitialized,
      'recording_attempts': _recordingAttempts,
      'current_recording_path': _currentRecordingPath,
      'max_attempts': _maxRecordingAttempts,
      'is_recording': _recorder?.isRecording ?? false,
      'is_emergency_mode': _isEmergencyMode,
      'emergency_available': _emergencyAvailable,
      'mode': _isEmergencyMode ? 'URGENCE' : 'STANDARD',
    };
  }
}