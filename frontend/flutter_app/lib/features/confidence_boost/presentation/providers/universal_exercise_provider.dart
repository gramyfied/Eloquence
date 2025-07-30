import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/services/universal_audio_exercise_service.dart';
import '../../domain/entities/api_models.dart';

/// Provider pour le service universel d'exercices audio
final universalAudioExerciseServiceProvider = Provider<UniversalAudioExerciseService>((ref) {
  return UniversalAudioExerciseService();
});

/// Provider pour l'état de l'exercice universel
final universalExerciseProvider = ChangeNotifierProvider<UniversalExerciseProvider>((ref) {
  final service = ref.watch(universalAudioExerciseServiceProvider);
  return UniversalExerciseProvider(service: service);
});

/// Provider d'état pour l'exercice audio universel
class UniversalExerciseProvider with ChangeNotifier {
  final UniversalAudioExerciseService _service;
  final Logger _logger = Logger();

  UniversalExerciseProvider({required UniversalAudioExerciseService service}) : _service = service;

  // État de l'exercice
  ExercisePhase _currentPhase = ExercisePhase.setup;
  String? _sessionId;
  AudioExerciseConfig? _currentConfig;
  List<ConversationMessage> _messages = [];
  Map<String, dynamic> _metrics = {};
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  double _confidence = 0.0;

  // Getters
  ExercisePhase get currentPhase => _currentPhase;
  String? get sessionId => _sessionId;
  AudioExerciseConfig? get currentConfig => _currentConfig;
  List<ConversationMessage> get messages => _messages;
  Map<String, dynamic> get metrics => _metrics;
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  double get confidence => _confidence;

  /// Démarre un nouvel exercice avec la configuration donnée
  Future<void> startExercise(AudioExerciseConfig config) async {
    try {
      _updateStatus('🚀 Démarrage de l\'exercice...', ExercisePhase.setup);
      
      _currentConfig = config;
      _sessionId = await _service.startExercise(config);
      
      // CORRECTION: Connexion WebSocket après création de session
      _updateStatus('🔗 Connexion WebSocket...', ExercisePhase.setup);
      await _service.connectExerciseWebSocket(_sessionId!);
      
      // Écouter les messages de l'IA en temps réel
      _service.messageStream.listen((message) {
        _messages.add(ConversationMessage.now(
          text: message.text ?? 'Message reçu',
          role: message.role == 'assistant' ? ConversationRole.assistant : ConversationRole.user,
        ));
        notifyListeners();
        _logger.i('📩 Nouveau message IA: ${message.text}');
      });
      
      _updateStatus('✅ Exercice démarré !', ExercisePhase.ready);
      _logger.i('Exercice démarré avec succès: $_sessionId');
      
    } catch (e) {
      _logger.e('Erreur démarrage exercice: $e');
      _updateStatus('❌ Erreur: $e', ExercisePhase.error);
    }
  }

  /// Démarre l'écoute audio
  Future<void> startListening() async {
    if (_sessionId == null) {
      _logger.w('Tentative d\'écoute sans session active');
      return;
    }

    try {
      _updateStatus('🎤 Écoute en cours...', ExercisePhase.listening);
      _isRecording = true;
      
      // L'écoute se fait côté client, le service est prêt à recevoir
      _logger.i('Service prêt à recevoir l\'audio');
      
    } catch (e) {
      _logger.e('Erreur démarrage écoute: $e');
      _updateStatus('❌ Erreur écoute: $e', ExercisePhase.error);
      _isRecording = false;
    }
  }

  /// Arrête l'écoute audio et traite la réponse
  Future<void> stopListening() async {
    if (_sessionId == null || !_isRecording) return;

    try {
      _isRecording = false;
      _updateStatus('🔄 Traitement...', ExercisePhase.processing);
      _isProcessing = true;

      // Simule des données audio pour les tests
      final mockAudioData = Uint8List(1024);
      
      final response = await _service.sendCompleteAudio(
        sessionId: _sessionId!,
        audioData: mockAudioData,
      );
      
      // Ajouter le message utilisateur
      _messages.add(ConversationMessage.now(
        text: response['transcription'] ?? 'Transcription audio...',
        role: ConversationRole.user,
      ));

      // Ajouter la réponse IA
      _messages.add(ConversationMessage.now(
        text: response['ai_response'] ?? 'Réponse de l\'IA...',
        role: ConversationRole.assistant,
      ));

      // Mettre à jour les métriques
      _metrics.addAll(response['metrics'] ?? {});
      _confidence = (response['confidence_score'] ?? 0.0).toDouble();

      _updateStatus('✅ Réponse traitée', ExercisePhase.feedback);
      _isProcessing = false;
      
    } catch (e) {
      _logger.e('Erreur traitement audio: $e');
      _updateStatus('❌ Erreur traitement: $e', ExercisePhase.error);
      _isRecording = false;
      _isProcessing = false;
    }
  }

  /// Termine l'exercice et obtient le rapport final
  Future<void> finishExercise() async {
    if (_sessionId == null) return;

    try {
      _updateStatus('📊 Génération du rapport...', ExercisePhase.processing);
      
      final report = await _service.completeExercise(_sessionId!);
      
      _updateStatus('🎉 Exercice terminé !', ExercisePhase.completed);
      _logger.i('Exercice terminé avec score final: ${report.overallScore}');
      
    } catch (e) {
      _logger.e('Erreur finalisation exercice: $e');
      _updateStatus('❌ Erreur finalisation: $e', ExercisePhase.error);
    }
  }

  /// Réinitialise l'exercice
  void resetExercise() {
    _currentPhase = ExercisePhase.setup;
    _sessionId = null;
    _currentConfig = null;
    _messages.clear();
    _metrics.clear();
    _isRecording = false;
    _isProcessing = false;
    _statusMessage = '';
    _confidence = 0.0;
    
    notifyListeners();
    _logger.i('Exercice réinitialisé');
  }

  /// Met à jour le statut et notifie les listeners
  void _updateStatus(String message, ExercisePhase phase) {
    _statusMessage = message;
    _currentPhase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Phases de l'exercice
enum ExercisePhase {
  setup,      // Configuration initiale
  ready,      // Prêt à commencer
  listening,  // Écoute en cours
  processing, // Traitement de la réponse
  feedback,   // Affichage du feedback
  completed,  // Exercice terminé
  error,      // Erreur
}