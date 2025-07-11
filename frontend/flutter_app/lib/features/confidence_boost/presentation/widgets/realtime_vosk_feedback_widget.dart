import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/services/prosody_analysis_interface.dart';
import '../../data/services/hybrid_speech_evaluation_service.dart';
import '../../domain/entities/confidence_scenario.dart' as confidence_scenarios;

/// Widget pour afficher le feedback VOSK temps réel pendant l'enregistrement
/// 
/// Fonctionnalités :
/// - Connexion WebSocket temps réel avec le service VOSK
/// - Visualisation des métriques prosodiques en direct
/// - Indicateurs visuels de qualité de parole
/// - Transcription partielle temps réel
class RealtimeVoskFeedbackWidget extends ConsumerStatefulWidget {
  final confidence_scenarios.ConfidenceScenario scenario;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingStop;
  final Function(Uint8List audioData)? onAudioData;

  const RealtimeVoskFeedbackWidget({
    Key? key,
    required this.scenario,
    this.onRecordingStart,
    this.onRecordingStop,
    this.onAudioData,
  }) : super(key: key);

  @override
  ConsumerState<RealtimeVoskFeedbackWidget> createState() => _RealtimeVoskFeedbackWidgetState();
}

class _RealtimeVoskFeedbackWidgetState extends ConsumerState<RealtimeVoskFeedbackWidget>
    with TickerProviderStateMixin {
  final Logger logger = Logger();
  
  // États d'enregistrement et de feedback
  bool _isRecording = false;
  bool _isConnected = false;
  String _connectionStatus = 'Déconnecté';
  
  // Données temps réel VOSK
  String _realtimeTranscript = '';
  double _currentWPM = 0.0;
  double _currentConfidence = 0.0;
  double _currentEnergyLevel = 0.0;
  int _pauseCount = 0;
  List<String> _detectedHesitations = [];
  
  // Services et streams
  HybridSpeechEvaluationService? _hybridService;
  StreamSubscription? _realtimeSubscription;
  Timer? _connectionTimer;
  String? _currentSessionId;
  
  // Animations
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeHybridService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  void _initializeHybridService() {
    try {
      _hybridService = HybridSpeechEvaluationService(
        baseUrl: 'http://localhost:8002',
        timeout: const Duration(seconds: 30),
      );
      _checkServiceConnection();
    } catch (e) {
      logger.e('Erreur initialisation service hybride: $e');
      setState(() {
        _connectionStatus = 'Erreur de connexion';
      });
    }
  }

  Future<void> _checkServiceConnection() async {
    if (_hybridService == null) return;
    
    try {
      final isAvailable = await _hybridService!.isAvailable();
      setState(() {
        _isConnected = isAvailable;
        _connectionStatus = isAvailable ? 'Service hybride connecté' : 'Service indisponible';
      });
      
      if (isAvailable) {
        logger.i('✅ Service hybride VOSK + Whisper disponible');
      } else {
        logger.w('⚠️ Service hybride indisponible, fallback requis');
      }
    } catch (e) {
      logger.e('Erreur vérification connexion: $e');
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Erreur de connexion';
      });
    }
  }

  Future<void> _startRealtimeRecording() async {
    if (_hybridService == null || !_isConnected) {
      logger.w('Service hybride non disponible pour l\'enregistrement temps réel');
      return;
    }

    try {
      setState(() {
        _isRecording = true;
        _realtimeTranscript = '';
        _currentWPM = 0.0;
        _currentConfidence = 0.0;
        _currentEnergyLevel = 0.0;
        _pauseCount = 0;
        _detectedHesitations.clear();
      });

      // Démarrer l'évaluation temps réel avec WebSocket
      _currentSessionId = await _hybridService!.startRealtimeEvaluation(
        scenario: widget.scenario,
        language: 'fr',
      );

      if (_currentSessionId == null) {
        throw Exception('Impossible de créer une session temps réel');
      }

      // S'abonner au stream temps réel
      _realtimeSubscription = _hybridService!.realtimeUpdates.listen(
        (realtimeData) {
          _updateRealtimeMetrics(realtimeData);
        },
        onError: (error) {
          logger.e('Erreur stream temps réel: $error');
          _stopRealtimeRecording();
        },
      );

      widget.onRecordingStart?.call();
      logger.i('🎤 Évaluation temps réel VOSK démarrée - Session: $_currentSessionId');
      
    } catch (e) {
      logger.e('Erreur démarrage évaluation temps réel: $e');
      setState(() {
        _isRecording = false;
        _currentSessionId = null;
      });
    }
  }

  void _updateRealtimeMetrics(Map<String, dynamic> realtimeData) {
    if (!mounted) return;

    setState(() {
      // Transcription partielle
      if (realtimeData['partial_transcript'] != null) {
        _realtimeTranscript = realtimeData['partial_transcript'];
      }
      
      // Métriques prosodiques temps réel
      if (realtimeData['speech_rate'] != null) {
        _currentWPM = (realtimeData['speech_rate']['wpm'] ?? 0.0).toDouble();
      }
      
      if (realtimeData['confidence'] != null) {
        _currentConfidence = (realtimeData['confidence'] ?? 0.0).toDouble();
      }
      
      if (realtimeData['energy'] != null) {
        _currentEnergyLevel = (realtimeData['energy']['normalized_level'] ?? 0.0).toDouble();
      }
      
      if (realtimeData['pauses'] != null) {
        _pauseCount = realtimeData['pauses']['count'] ?? 0;
      }
      
      if (realtimeData['hesitations'] != null) {
        _detectedHesitations = List<String>.from(realtimeData['hesitations']);
      }
    });
  }

  Future<void> _stopRealtimeRecording() async {
    if (_hybridService == null || !_isRecording || _currentSessionId == null) return;

    try {
      // Terminer l'évaluation temps réel et récupérer les résultats finaux
      final finalResult = await _hybridService!.finishRealtimeEvaluation(_currentSessionId!);
      await _realtimeSubscription?.cancel();
      _realtimeSubscription = null;
      
      setState(() {
        _isRecording = false;
      });

      widget.onRecordingStop?.call();
      
      if (finalResult != null) {
        logger.i('🛑 Évaluation temps réel VOSK complétée avec résultats finaux');
      } else {
        logger.w('🛑 Évaluation temps réel VOSK arrêtée sans résultats finaux');
      }
      
    } catch (e) {
      logger.e('Erreur arrêt évaluation temps réel: $e');
      setState(() {
        _isRecording = false;
      });
    } finally {
      _currentSessionId = null;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _realtimeSubscription?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 8.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildConnectionStatus(),
            const SizedBox(height: 20),
            _buildRecordingControls(),
            if (_isRecording) ...[
              const SizedBox(height: 20),
              _buildRealtimeMetrics(),
              const SizedBox(height: 20),
              _buildTranscriptSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.mic_external_on, color: Colors.blue, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Feedback VOSK Temps Réel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Scénario: ${widget.scenario.title}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.warning,
            color: _isConnected ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _connectionStatus,
            style: TextStyle(
              color: _isConnected ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? _pulseAnimation.value : 1.0,
            child: ElevatedButton.icon(
              onPressed: _isConnected
                  ? (_isRecording ? _stopRealtimeRecording : _startRealtimeRecording)
                  : null,
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 28,
              ),
              label: Text(
                _isRecording ? 'Arrêter l\'enregistrement' : 'Démarrer l\'enregistrement',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRealtimeMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métriques Temps Réel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Débit', '${_currentWPM.toStringAsFixed(0)} mots/min', Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Confiance', '${(_currentConfidence * 100).toStringAsFixed(0)}%', Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Énergie', '${(_currentEnergyLevel * 100).toStringAsFixed(0)}%', Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Pauses', '$_pauseCount', Colors.purple)),
          ],
        ),
        if (_detectedHesitations.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildHesitationsCard(),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _getDarkerColor(color),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getDarkestColor(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    if (color == Colors.blue) return Colors.blue[700]!;
    if (color == Colors.green) return Colors.green[700]!;
    if (color == Colors.orange) return Colors.orange[700]!;
    if (color == Colors.purple) return Colors.purple[700]!;
    if (color == Colors.red) return Colors.red[700]!;
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
  }

  Color _getDarkestColor(Color color) {
    if (color == Colors.blue) return Colors.blue[800]!;
    if (color == Colors.green) return Colors.green[800]!;
    if (color == Colors.orange) return Colors.orange[800]!;
    if (color == Colors.purple) return Colors.purple[800]!;
    if (color == Colors.red) return Colors.red[800]!;
    return Color.fromRGBO(
      (color.red * 0.6).round(),
      (color.green * 0.6).round(),
      (color.blue * 0.6).round(),
      1.0,
    );
  }

  Widget _buildHesitationsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hésitations détectées',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: _detectedHesitations.map((hesitation) => Chip(
              label: Text(hesitation, style: const TextStyle(fontSize: 10)),
              backgroundColor: Colors.red.withOpacity(0.2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transcription Temps Réel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isRecording 
                      ? Colors.blue.withOpacity(0.5 + 0.5 * _waveAnimation.value)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                _realtimeTranscript.isEmpty 
                    ? 'Commencez à parler...'
                    : _realtimeTranscript,
                style: TextStyle(
                  fontSize: 14,
                  color: _realtimeTranscript.isEmpty ? Colors.grey[600] : Colors.black87,
                  fontStyle: _realtimeTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}