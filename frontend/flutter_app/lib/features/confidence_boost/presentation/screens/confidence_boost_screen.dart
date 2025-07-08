import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../../../presentation/widgets/eloquence_components.dart';
import '../../../../presentation/widgets/gradient_container.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../providers/confidence_boost_provider.dart';
import '../widgets/confidence_timer_widget.dart';
import '../widgets/confidence_scenario_card.dart';
import '../widgets/confidence_tips_carousel.dart';
import '../widgets/confidence_results_view.dart';

class ConfidenceBoostScreen extends ConsumerStatefulWidget {
  final String userId;

  const ConfidenceBoostScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ConfidenceBoostScreen> createState() => _ConfidenceBoostScreenState();
}

class _ConfidenceBoostScreenState extends ConsumerState<ConfidenceBoostScreen>
    with TickerProviderStateMixin {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  Timer? _recordingTimer;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  bool _isInitialized = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkPermissions() async {
    // Ouvrir la session d'enregistrement
    await _audioRecorder.openRecorder();
    
    // Vérifier et demander les permissions
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      setState(() => _isInitialized = true);
    } else {
      // Gérer le cas où la permission est refusée
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone requise pour cet exercice'),
            backgroundColor: EloquenceColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.closeRecorder();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startRecording(ConfidenceScenario scenario) async {
    final sessionNotifier = ref.read(confidenceSessionProvider(widget.userId).notifier);
    final analysisService = ref.read(confidenceAnalysisServiceProvider);
    
    // Démarrer une nouvelle session
    await sessionNotifier.startSession(scenario);
    
    // Essayer d'abord avec LiveKit
    if (analysisService.isLiveKitAvailable) {
      // Démarrer session LiveKit
      final livekitSessionId = await analysisService.startLiveKitSession(
        userId: widget.userId,
        scenario: scenario,
      );
      
      if (livekitSessionId != null) {
        // Démarrer l'enregistrement via LiveKit
        final started = await analysisService.startLiveKitRecording();
        if (started) {
          sessionNotifier.startRecording();
          _startRecordingTimer(scenario);
          return;
        }
      }
    }
    
    // Fallback vers l'enregistrement local
    await _startLocalRecording(scenario, sessionNotifier);
  }

  Future<void> _startLocalRecording(ConfidenceScenario scenario, sessionNotifier) async {
    // Préparer le chemin du fichier audio
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'confidence_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _audioPath = path.join(appDir.path, fileName);

    // Démarrer l'enregistrement local
    await _audioRecorder.startRecorder(
      toFile: _audioPath,
      codec: Codec.aacMP4,
    );
    sessionNotifier.startRecording();
    _startRecordingTimer(scenario);
  }

  void _startRecordingTimer(ConfidenceScenario scenario) {
    // Démarrer le timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final seconds = timer.tick;
      final sessionNotifier = ref.read(confidenceSessionProvider(widget.userId).notifier);
      sessionNotifier.updateRecordingTime(seconds);
      
      // Arrêter automatiquement à la fin du temps imparti
      if (seconds >= scenario.durationSeconds) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final sessionNotifier = ref.read(confidenceSessionProvider(widget.userId).notifier);
    final analysisService = ref.read(confidenceAnalysisServiceProvider);
    
    // Arrêter l'enregistrement selon le mode utilisé
    if (analysisService.isLiveKitAvailable) {
      // Arrêter l'enregistrement LiveKit
      await analysisService.stopLiveKitRecording();
      
      // L'analyse sera faite via LiveKit directement
      await sessionNotifier.stopRecordingAndAnalyze('livekit_session');
    } else {
      // Arrêter l'enregistrement local
      await _audioRecorder.stopRecorder();
      
      if (_audioPath != null) {
        // Analyser et sauvegarder
        await sessionNotifier.stopRecordingAndAnalyze(_audioPath!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(confidenceSessionProvider(widget.userId));
    final scenariosAsync = ref.watch(confidenceScenariosProvider);

    return Scaffold(
      body: GradientContainer(
        child: SafeArea(
          child: Column(
            children: [
              // Header avec titre
              _buildHeader(context),
              
              // Contenu principal
              Expanded(
                child: scenariosAsync.when(
                  data: (scenarios) => _buildContent(
                    context,
                    scenarios,
                    sessionState,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: EloquenceColors.cyan,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Erreur: $error',
                      style: EloquenceTextStyles.bodyMedium.copyWith(
                        color: EloquenceColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: EloquenceColors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Confidence Boost Express',
              style: EloquenceTextStyles.h2.copyWith(
                color: EloquenceColors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Pour équilibrer avec le bouton retour
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ConfidenceScenario> scenarios,
    ConfidenceSessionState sessionState,
  ) {
    if (sessionState.currentSession == null && !sessionState.isRecording) {
      // Sélection du scénario
      return _buildScenarioSelection(scenarios);
    } else if (sessionState.isRecording) {
      // Enregistrement en cours
      return _buildRecordingView(sessionState);
    } else if (sessionState.isAnalyzing) {
      // Analyse en cours
      return _buildAnalyzingView();
    } else if (sessionState.currentSession?.isCompleted == true) {
      // Résultats
      return _buildResultsView(sessionState);
    } else {
      // Vue de préparation
      return _buildPreparationView(sessionState);
    }
  }

  Widget _buildScenarioSelection(List<ConfidenceScenario> scenarios) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Choisissez votre défi du jour',
            style: EloquenceTextStyles.h3.copyWith(
              color: EloquenceColors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              final scenario = scenarios[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ConfidenceScenarioCard(
                  scenario: scenario,
                  onTap: () => _showScenarioDetails(scenario),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreparationView(ConfidenceSessionState sessionState) {
    final scenario = sessionState.currentSession!.scenario;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Carte du scénario
          EloquenceGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        scenario.type.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          scenario.title,
                          style: EloquenceTextStyles.h3.copyWith(
                            color: EloquenceColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    scenario.prompt,
                    style: EloquenceTextStyles.bodyLarge.copyWith(
                      color: EloquenceColors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: EloquenceColors.cyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${scenario.durationSeconds} secondes',
                        style: EloquenceTextStyles.bodyMedium.copyWith(
                          color: EloquenceColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Conseils
          Expanded(
            child: ConfidenceTipsCarousel(tips: scenario.tips),
          ),
          
          const SizedBox(height: 24),
          
          // Zone du microphone (thumb zone - minimum 200px du bas)
          SizedBox(
            height: 200,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: EloquenceMicrophone(
                      isRecording: false,
                      onTap: () => _startRecording(scenario),
                      size: 120,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView(ConfidenceSessionState sessionState) {
    final scenario = sessionState.currentSession!.scenario;
    final remainingSeconds = scenario.durationSeconds - sessionState.recordingSeconds;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Timer
          ConfidenceTimerWidget(
            totalSeconds: scenario.durationSeconds,
            elapsedSeconds: sessionState.recordingSeconds,
          ),
          
          const SizedBox(height: 40),
          
          // Prompt
          EloquenceGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    scenario.prompt,
                    style: EloquenceTextStyles.h3.copyWith(
                      color: EloquenceColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Temps restant: $remainingSeconds secondes',
                    style: EloquenceTextStyles.bodyLarge.copyWith(
                      color: EloquenceColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Waveforms animées
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return EloquenceWaveforms(
                  isActive: true,
                );
              },
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Bouton stop (thumb zone)
          SizedBox(
            height: 200,
            child: Center(
              child: EloquenceMicrophone(
                isRecording: true,
                onTap: _stopRecording,
                size: 120,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: EloquenceColors.cyan,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Analyse en cours...',
            style: EloquenceTextStyles.h3.copyWith(
              color: EloquenceColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Votre performance est en cours d\'évaluation',
            style: EloquenceTextStyles.bodyLarge.copyWith(
              color: EloquenceColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(ConfidenceSessionState sessionState) {
    return ConfidenceResultsView(
      session: sessionState.currentSession!,
      onRetry: () {
        // Recommencer avec le même scénario
        final scenario = sessionState.currentSession!.scenario;
        ref.read(confidenceSessionProvider(widget.userId).notifier).reset();
        _showScenarioDetails(scenario);
      },
      onComplete: () {
        // Retourner à la liste des exercices
        Navigator.of(context).pop();
      },
    );
  }

  void _showScenarioDetails(ConfidenceScenario scenario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: EloquenceColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: EloquenceColors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EloquenceColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  scenario.type.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.title,
                        style: EloquenceTextStyles.h3.copyWith(
                          color: EloquenceColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${scenario.durationSeconds} secondes',
                        style: EloquenceTextStyles.bodyMedium.copyWith(
                          color: EloquenceColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              scenario.description,
              style: EloquenceTextStyles.bodyLarge.copyWith(
                color: EloquenceColors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final sessionNotifier = ref.read(
                    confidenceSessionProvider(widget.userId).notifier,
                  );
                  sessionNotifier.startSession(scenario);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EloquenceColors.cyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Commencer',
                  style: EloquenceTextStyles.buttonLarge.copyWith(
                    color: EloquenceColors.backgroundDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}