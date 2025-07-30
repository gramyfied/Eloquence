import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../presentation/widgets/gradient_container.dart';
import '../../domain/entities/story_models.dart';
import '../providers/story_generator_provider.dart';
import '../widgets/animated_ai_avatar_widget.dart';
import 'story_results_screen.dart';

/// Écran de narration avec timer et enregistrement audio
class StoryNarrationScreen extends ConsumerStatefulWidget {
  const StoryNarrationScreen({super.key});

  @override
  ConsumerState<StoryNarrationScreen> createState() => _StoryNarrationScreenState();
}

class _StoryNarrationScreenState extends ConsumerState<StoryNarrationScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _mainAnimationController;
  late AnimationController _timerAnimationController;
  late AnimationController _recordingAnimationController;
  late AnimationController _interventionAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _timerAnimation;
  late Animation<double> _recordingPulseAnimation;
  late Animation<double> _interventionSlideAnimation;
  
  Timer? _narrativeTimer;
  int _remainingSeconds = 90;
  bool _isRecording = false;
  bool _isFinished = false;
  bool _showIntervention = false;
  AIIntervention? _currentIntervention;
  
  // Interventions préprogrammées pour la démo
  final List<Map<String, dynamic>> _demoInterventions = [
    {
      'time': 30, // 30 secondes
      'content': 'Et soudain, un mystérieux visiteur apparaît...',
      'type': InterventionType.plotTwist,
    },
    {
      'time': 60, // 60 secondes  
      'content': 'Votre personnage découvre un secret sur le lieu...',
      'type': InterventionType.characterReveal,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Animation principale pour l'entrée
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animation du timer circulaire
    _timerAnimationController = AnimationController(
      duration: Duration(seconds: _remainingSeconds),
      vsync: this,
    );
    
    // Animation d'enregistrement (pulsation)
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animation des interventions IA
    _interventionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _timerAnimationController,
      curve: Curves.linear,
    ));
    
    _recordingPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _interventionSlideAnimation = Tween<double>(
      begin: -300.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _interventionAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Démarrer les animations
    _startAnimations();
  }

  void _startAnimations() {
    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _narrativeTimer?.cancel();
    _mainAnimationController.dispose();
    _timerAnimationController.dispose();
    _recordingAnimationController.dispose();
    _interventionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyGeneratorProvider);
    final selectedElements = storyState.currentSession?.selectedElements ?? [];
    
    return Scaffold(
      body: GradientContainer(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _mainAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    children: [
                       _buildHeader(context),
                       Expanded(
                         child: Stack(
                           children: [
                             // Contenu principal
                             SingleChildScrollView(
                               physics: const BouncingScrollPhysics(),
                               padding: const EdgeInsets.symmetric(horizontal: 24.0),
                               child: Column(
                                 children: [
                                   const SizedBox(height: 24),
                                   _buildSelectedElements(selectedElements),
                                   const SizedBox(height: 32),
                                   _buildNarrationArea(),
                                   const SizedBox(height: 32),
                                   _buildInstructions(),
                                   const SizedBox(height: 32),
                                 ],
                               ),
                             ),
                             
                             // Overlay d'intervention IA
                             if (_showIntervention)
                               _buildInterventionOverlay(),
                           ],
                         ),
                       ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isRecording ? null : () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Narration',
                  style: EloquenceTheme.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                 Text(
                   _isFinished ? 'Histoire terminée ! 🎉' : 'Racontez votre histoire 📚',
                   style: EloquenceTheme.bodyMedium.copyWith(
                     color: Colors.white.withOpacity(0.8),
                   ),
                 ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Timer compact dans le header
          _buildCompactTimer(),
        ],
      ),
    );
  }

  Widget _buildCompactTimer() {
    return Container(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Cercle de background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EloquenceTheme.glassBackground,
              border: Border.all(color: EloquenceTheme.glassBorder, width: 2),
            ),
          ),
          // Progression du timer
          AnimatedBuilder(
            animation: _timerAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(80, 80),
                painter: _TimerProgressPainter(
                  progress: _timerAnimation.value,
                  color: _getTimerColor(),
                ),
              );
            },
          ),
          // Temps restant
          Center(
            child: Text(
              '${_remainingSeconds}s',
              style: EloquenceTheme.timerDisplay.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedElements(List<StoryElement> elements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: EloquenceTheme.glassBackground,
        border: Border.all(color: EloquenceTheme.glassBorder),
        boxShadow: EloquenceTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: EloquenceTheme.cyan,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Vos Éléments',
                style: EloquenceTheme.headline3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: elements.map((element) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildElementChip(element),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildElementChip(StoryElement element) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            EloquenceTheme.cyan.withOpacity(0.2),
            EloquenceTheme.violet.withOpacity(0.2),
          ],
        ),
        border: Border.all(color: EloquenceTheme.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            element.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            element.name,
            style: EloquenceTheme.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNarrationArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Grand timer central
          _buildMainTimer(),
          
          const SizedBox(height: 32),
          
          // Bouton d'enregistrement
          _buildRecordingButton(),
          
          if (_isRecording) ...[
            const SizedBox(height: 24),
            _buildRecordingIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildMainTimer() {
    return AnimatedBuilder(
      animation: _timerAnimation,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          child: Stack(
            children: [
              // Cercle de background
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EloquenceTheme.glassBackground,
                  border: Border.all(color: EloquenceTheme.glassBorder, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: EloquenceTheme.cyan.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              // Progression du timer
              CustomPaint(
                size: const Size(200, 200),
                painter: _TimerProgressPainter(
                  progress: _timerAnimation.value,
                  color: _getTimerColor(),
                  strokeWidth: 8,
                ),
              ),
              // Temps restant au centre
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_remainingSeconds',
                      style: EloquenceTheme.scoreDisplay.copyWith(
                        fontSize: 48,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'secondes',
                      style: EloquenceTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordingButton() {
    return AnimatedBuilder(
      animation: _recordingPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRecording ? _recordingPulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _isFinished ? null : _toggleRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isFinished
                      ? [Colors.grey, Colors.grey.shade600]
                      : _isRecording
                          ? [Colors.red, Colors.red.shade700]
                          : [EloquenceTheme.cyan, EloquenceTheme.violet],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : EloquenceTheme.cyan).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isFinished ? Icons.check : _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.red.withOpacity(0.2),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Enregistrement en cours...',
            style: EloquenceTheme.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: EloquenceTheme.glassBackground,
        border: Border.all(color: EloquenceTheme.glassBorder),
        boxShadow: EloquenceTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: EloquenceTheme.violet,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Conseils de Narration',
                style: EloquenceTheme.headline3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('🎭', 'Utilisez vos 3 éléments dans l\'histoire'),
          _buildInstructionItem('🗣️', 'Parlez clairement et avec enthousiasme'),
          _buildInstructionItem('⚡', 'Soyez créatif avec les interventions IA'),
          _buildInstructionItem('🎯', 'Visez une histoire complète en 90 secondes'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: EloquenceTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionOverlay() {
    return AnimatedBuilder(
      animation: _interventionSlideAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Avatar IA flottant
            Positioned(
              top: 120,
              right: 24,
              child: Transform.translate(
                offset: Offset(_interventionSlideAnimation.value, 0),
                child: Column(
                  children: [
                    StoryAIAvatarWidget(
                      isActive: true,
                      isSpeaking: true,
                      onTap: _acceptIntervention,
                      message: "💡 Idée !",
                    ),
                    const SizedBox(height: 12),
                    // Bouton "Écouter"
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton.icon(
                        onPressed: _acceptIntervention,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EloquenceTheme.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.hearing, size: 16),
                        label: const Text(
                          'Écouter',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bulle de dialogue avec le contenu
            Positioned(
              top: 100,
              left: 24,
              right: 120, // Espace pour l'avatar
              child: Transform.translate(
                offset: Offset(_interventionSlideAnimation.value * 0.8, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        EloquenceTheme.violet.withOpacity(0.95),
                        EloquenceTheme.cyan.withOpacity(0.95),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: EloquenceTheme.violet.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Suggestion IA',
                              style: EloquenceTheme.headline3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                            onPressed: _hideIntervention,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentIntervention?.content ?? '',
                        style: EloquenceTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _acceptIntervention,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Utiliser', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _hideIntervention,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Ignorer', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getTimerColor() {
    if (_remainingSeconds > 60) return EloquenceTheme.cyan;
    if (_remainingSeconds > 30) return Colors.orange;
    if (_remainingSeconds > 10) return Colors.orange.shade700;
    return Colors.red;
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    logger.i('StoryNarration', 'Démarrage enregistrement');
    
    setState(() {
      _isRecording = true;
    });
    
    // Démarrer les animations
    _recordingAnimationController.repeat(reverse: true);
    _timerAnimationController.forward();
    
    // Démarrer le provider
    await ref.read(storyGeneratorProvider.notifier).startRecording();
    
    // Démarrer le timer de narration
    _startNarrativeTimer();
  }

  Future<void> _stopRecording() async {
    logger.i('StoryNarration', 'Arrêt enregistrement');
    
    setState(() {
      _isRecording = false;
      _isFinished = true;
    });
    
    // Arrêter les animations et timer
    _recordingAnimationController.stop();
    _timerAnimationController.stop();
    _narrativeTimer?.cancel();
    
    // Arrêter le provider et attendre l'attribution des badges
    await ref.read(storyGeneratorProvider.notifier).stopRecording();
    
    // Navigation vers les résultats après un délai
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const StoryResultsScreen(),
          ),
        );
      }
    });
  }

  void _startNarrativeTimer() {
    _narrativeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
      
      // Vérifier les interventions IA programmées
      _checkForInterventions();
      
      // Fin du temps
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _checkForInterventions() {
    final elapsedSeconds = 90 - _remainingSeconds;
    
    for (final intervention in _demoInterventions) {
      if (intervention['time'] == elapsedSeconds && !_showIntervention) {
        _showInterventionFromData(intervention);
        break;
      }
    }
  }

  void _showInterventionFromData(Map<String, dynamic> data) {
    setState(() {
      _currentIntervention = AIIntervention(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        content: data['content'],
        timestamp: Duration(seconds: 90 - _remainingSeconds),
      );
      _showIntervention = true;
    });
    
    _interventionAnimationController.forward();
    
    // Masquer automatiquement après 5 secondes si pas d'action
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showIntervention) {
        _hideIntervention();
      }
    });
  }

  void _hideIntervention() {
    setState(() {
      _showIntervention = false;
    });
    _interventionAnimationController.reverse();
  }

  void _acceptIntervention() {
    if (_currentIntervention != null) {
      // Marquer l'intervention comme acceptée
      _currentIntervention = _currentIntervention!.copyWith(wasAccepted: true);
      
      logger.i('StoryNarration', 'Intervention IA acceptée: ${_currentIntervention!.content}');
    }
    
    _hideIntervention();
  }
}

/// Painter pour le timer circulaire
class _TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  
  _TimerProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    
    // Cercle de background
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Arc de progression
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -math.pi / 2; // Démarrer en haut
    final sweepAngle = 2 * math.pi * (1 - progress); // Inverse pour compte à rebours
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension pour copier AIIntervention avec de nouveaux params
extension AIInterventionCopyWith on AIIntervention {
  AIIntervention copyWith({
    String? id,
    String? content,
    Duration? timestamp,
    bool? wasAccepted,
    String? userResponse,
    DateTime? createdAt,
  }) {
    return AIIntervention(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      wasAccepted: wasAccepted ?? this.wasAccepted,
      userResponse: userResponse ?? this.userResponse,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}