import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/unified_logger_service.dart';
import '../../data/services/universal_audio_exercise_service.dart';
import '../../data/services/simple_audio_service.dart';
import '../../domain/entities/virelangue_models.dart';
import '../../data/services/virelangue_service.dart';

// Ce provider a été déplacé dans virelangue_service.dart
// final virelangueServiceProvider = Provider...

/// Provider principal pour l'état de l'exercice virelangue
///
/// 🎯 RESPONSABILITÉS DU PROVIDER/NOTIFIER :
/// - Gérer l'état de l'interface utilisateur (UI state) pour la session virelangue.
/// - Agir comme un médiateur (ViewModel) entre l'UI et les services métier.
/// - Démarrer, arrêter l'enregistrement et déclencher l'analyse.
/// - Contenir la logique de l'UI (ex: états de chargement, erreurs, etc.).
final virelangueExerciseProvider = StateNotifierProvider<VirelangueExerciseNotifier, VirelangueExerciseState>((ref) {
  return VirelangueExerciseNotifier(
    virelangueService: ref.watch(virelangueServiceProvider),
    universalAudioService: ref.watch(universalAudioExerciseServiceProvider),
    simpleAudioService: ref.watch(simpleAudioServiceProvider),
  );
});

/// Provider pour SimpleAudioService
final simpleAudioServiceProvider = Provider<SimpleAudioService>((ref) {
  return SimpleAudioService();
});


/// StateNotifier pour gérer l'état de l'exercice virelangue.
class VirelangueExerciseNotifier extends StateNotifier<VirelangueExerciseState> {
  final VirelangueService _virelangueService;
  final UniversalAudioExerciseService _universalAudioService;
  final SimpleAudioService _simpleAudioService;
  final _logger = UnifiedLoggerService();
  String? _currentRecordingPath;

  VirelangueExerciseNotifier({
    required VirelangueService virelangueService,
    required UniversalAudioExerciseService universalAudioService,
    required SimpleAudioService simpleAudioService,
  }) : _virelangueService = virelangueService,
       _universalAudioService = universalAudioService,
       _simpleAudioService = simpleAudioService,
       super(VirelangueExerciseState.initial(userId: const Uuid().v4())) {
    // Initialiser le service audio
    _initializeAudioService();
  }

  /// Initialise le service audio réel
  Future<void> _initializeAudioService() async {
    try {
      final initialized = await _simpleAudioService.initialize();
      if (!initialized) {
        UnifiedLoggerService.error('Échec initialisation SimpleAudioService', null, null);
      } else {
        UnifiedLoggerService.info('SimpleAudioService initialisé avec succès');
      }
    } catch (e, stackTrace) {
      UnifiedLoggerService.error('Erreur initialisation audio', e, stackTrace);
    }
  }

  /// Démarre une nouvelle session 'roulette' de virelangue.
  Future<void> startNewSession({
    String? userId,
    VirelangueDifficulty? preferredDifficulty,
    String? customTheme,
    bool useAI = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newSessionState = await _virelangueService.startVirelangueSession(
        userId: userId ?? state.userId,
        preferredDifficulty: preferredDifficulty,
        customTheme: customTheme,
        useAI: useAI,
      );
      state = newSessionState.copyWith(isLoading: false);
      UnifiedLoggerService.info('Nouvelle session démarrée: ${state.sessionId} pour user ${state.userId}');
    } catch (e, stackTrace) {
      UnifiedLoggerService.error('Erreur démarrage nouvelle session', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Démarre l'enregistrement audio réel avec SimpleAudioService.
  Future<void> startRecording() async {
    if (state.currentVirelangue == null) {
      UnifiedLoggerService.warning("Tentative d'enregistrement sans virelangue actif.");
      return;
    }

    try {
      state = state.copyWith(isRecording: true, error: null);
      
      // Démarrer l'enregistrement audio réel optimisé pour Vosk
      _currentRecordingPath = await _simpleAudioService.startRecording();
      
      if (_currentRecordingPath != null) {
        UnifiedLoggerService.info('🎤 Enregistrement audio réel démarré: $_currentRecordingPath');
      } else {
        throw Exception('Échec démarrage enregistrement SimpleAudioService');
      }
    } catch (e, stackTrace) {
      UnifiedLoggerService.error('Erreur démarrage enregistrement', e, stackTrace);
      state = state.copyWith(isRecording: false, error: e);
    }
  }

  /// Arrête l'enregistrement réel, analyse l'audio et traite le résultat.
  Future<void> stopRecording() async {
    if (!state.isRecording) return;
    state = state.copyWith(isRecording: false, isLoading: true);
    UnifiedLoggerService.info('🛑 Arrêt enregistrement réel et début analyse...');

    try {
      // 1. Arrêter l'enregistrement et récupérer le fichier audio réel
      final audioFile = await _simpleAudioService.stopRecording();
      
      if (audioFile == null) {
        throw Exception('Aucun fichier audio retourné par SimpleAudioService');
      }

      UnifiedLoggerService.info('📁 Fichier audio créé: ${audioFile.path}');
      
      // 🔍 DIAGNOSTIC APPROFONDI DU FICHIER AUDIO
      final fileSize = await audioFile.length();
      final audioFileName = audioFile.path.split('/').last;
      UnifiedLoggerService.info('🔍 DIAGNOSTIC AUDIO:');
      UnifiedLoggerService.info('  📁 Fichier: $audioFileName');
      UnifiedLoggerService.info('  📊 Taille: $fileSize bytes');
      
      if (fileSize <= 44) {
        UnifiedLoggerService.error('❌ PROBLÈME CRITIQUE: Fichier vide (headers WAV seulement)');
        UnifiedLoggerService.error('  🚨 Causes possibles:');
        UnifiedLoggerService.error('    - Permission microphone refusée en arrière-plan');
        UnifiedLoggerService.error('    - Microphone non disponible/occupé par autre app');
        UnifiedLoggerService.error('    - Problème hardware microphone');
        UnifiedLoggerService.error('    - Flutter Sound configuration incorrecte');
        
        // Tester permission à nouveau
        final hasPermission = await _simpleAudioService.checkPermissions();
        UnifiedLoggerService.error('  🔑 Permission microphone: $hasPermission');
      } else if (fileSize < 16000) {
        UnifiedLoggerService.warning('⚠️ AUDIO SUSPECT: Fichier très petit (< 1 seconde d\'audio)');
      } else {
        UnifiedLoggerService.info('✅ Taille fichier normale');
      }
      
      // 2. Préparer l'audio pour l'upload (validation + conversion en bytes)
      final preparedAudio = await _simpleAudioService.prepareAudioForUpload(audioFile);
      
      if (preparedAudio.containsKey('error')) {
        throw Exception('Erreur préparation audio: ${preparedAudio['error']}');
      }

      final audioBytes = preparedAudio['audio_bytes'] as Uint8List;
      final fileName = preparedAudio['file_name'] as String;
      
      UnifiedLoggerService.info('📊 Audio préparé: ${audioBytes.length} bytes, prêt pour Vosk: ${preparedAudio['ready_for_vosk']}');

      // 3. Analyser la prononciation avec l'audio réel
      final analysisResult = await _universalAudioService.analyzeVirelanguePronunciation(
        sessionId: state.sessionId,
        audioData: audioBytes,
        virelangueText: state.currentVirelangue!.text,
        targetSounds: state.currentVirelangue!.problemSounds,
        fileName: fileName,
      );

      // 4. Traiter le résultat de la tentative via le service principal
      final updatedState = await _virelangueService.processPronunciationAttempt(
        currentState: state,
        audioAnalysisResult: analysisResult,
      );

      state = updatedState.copyWith(isLoading: false);
      UnifiedLoggerService.info("✅ Analyse terminée avec audio réel. Score: ${updatedState.pronunciationResults.last.overallScore}");

      // 5. Nettoyer le fichier temporaire
      try {
        await audioFile.delete();
        UnifiedLoggerService.debug('🧹 Fichier temporaire supprimé');
      } catch (cleanupError) {
        UnifiedLoggerService.warning('Échec suppression fichier temporaire: $cleanupError');
      }

    } catch (e, stackTrace) {
      UnifiedLoggerService.error('Erreur durant l\'arrêt et l\'analyse avec audio réel', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e);
    }
  }


  /// Sélectionne un nouveau virelangue sans terminer la session.
  Future<void> spinWheelForNewVirelangue({
    VirelangueDifficulty? preferredDifficulty,
    String? customTheme,
    bool useAI = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userProgress = await _virelangueService.getUserProgress(state.userId);
      final newVirelangue = await _virelangueService.selectOptimalVirelangue(
        userId: state.userId,
        preferredDifficulty: preferredDifficulty,
        customTheme: customTheme,
        useAI: useAI,
        userProgress: userProgress,
      );
      state = state.copyWith(
        currentVirelangue: newVirelangue,
        currentAttempt: 0, // Réinitialise les tentatives pour le nouveau virelangue
        pronunciationResults: [], // Nettoie les résultats précédents
        isLoading: false,
      );
       UnifiedLoggerService.info("Nouveau virelangue par la roue: ${newVirelangue.text}");
      } catch (e, stackTrace) {
      UnifiedLoggerService.error('Erreur lors de la sélection d\'un nouveau virelangue', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Réinitialise l'état pour une nouvelle partie complète.
  void resetGame() {
    state = VirelangueExerciseState.initial(userId: state.userId);
    UnifiedLoggerService.info("Jeu de virelangue réinitialisé pour l'utilisateur ${state.userId}.");
  }

  @override
  void dispose() {
    UnifiedLoggerService.info('VirelangueExerciseNotifier est disposé.');
    super.dispose();
  }
}