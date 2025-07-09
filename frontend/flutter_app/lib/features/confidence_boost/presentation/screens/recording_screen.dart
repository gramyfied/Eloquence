import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';

class RecordingScreen extends StatefulWidget {
  final ConfidenceScenario scenario;
  final TextSupport textSupport;
  final String sessionId;
  final Function(Duration) onRecordingComplete;

  const RecordingScreen({
    Key? key,
    required this.scenario,
    required this.textSupport,
    required this.sessionId,
    required this.onRecordingComplete,
  }) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.scenario.title,
          style: EloquenceTextStyles.headline2,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(EloquenceSpacing.lg),
        child: Column(
          children: [
            // Support texte affiché
            _buildTextSupportDisplay(),

            SizedBox(height: EloquenceSpacing.xl),

            // Timer
            Text(
              _formatDuration(_recordingDuration),
              style: ConfidenceBoostTextStyles.timerDisplay,
            ),

            SizedBox(height: EloquenceSpacing.xl),

            // Waveform visualizer
            _buildWaveformVisualizer(),

            Spacer(),

            // Bouton d'enregistrement
            _buildRecordButton(),

            SizedBox(height: EloquenceSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSupportDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EloquenceSpacing.lg),
      decoration: BoxDecoration(
        color: EloquenceColors.glassBackground,
        borderRadius: EloquenceRadii.card,
        border: EloquenceBorders.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_snippet, color: EloquenceColors.cyan, size: 20),
              SizedBox(width: EloquenceSpacing.sm),
              Text(
                'Support : ${_getSupportTypeName(widget.textSupport.type)}',
                style: EloquenceTextStyles.body1.copyWith(
                  color: EloquenceColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: EloquenceSpacing.md),
          _buildSupportContent(),
        ],
      ),
    );
  }

  Widget _buildSupportContent() {
    switch (widget.textSupport.type) {
      case SupportType.fillInBlanks:
        return _buildFillInBlanksContent();
      // TODO: Implement other cases
      // case SupportType.guidedStructure:
      //   return _buildStructureContent();
      // case SupportType.keywordChallenge:
      //   return _buildKeywordContent();
      default:
        return Text(
          widget.textSupport.content,
          style: EloquenceTextStyles.body1,
        );
    }
  }

  Widget _buildFillInBlanksContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: EloquenceTextStyles.body1,
            children: _parseTextWithBlanks(widget.textSupport.content),
          ),
        ),
        if (widget.textSupport.suggestedWords.isNotEmpty) ...[
          SizedBox(height: EloquenceSpacing.md),
          Text(
            '💡 Suggestions disponibles:',
            style: EloquenceTextStyles.body1.copyWith(
              color: EloquenceColors.cyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: EloquenceSpacing.sm),
          Wrap(
            spacing: EloquenceSpacing.sm,
            runSpacing: EloquenceSpacing.sm,
            children: widget.textSupport.suggestedWords.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EloquenceSpacing.sm,
                  vertical: EloquenceSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: EloquenceColors.violet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EloquenceColors.violet.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  word,
                  style: EloquenceTextStyles.caption.copyWith(
                    color: EloquenceColors.violet,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  List<TextSpan> _parseTextWithBlanks(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('___');

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));

      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: '_____',
          style: TextStyle(
            backgroundColor: EloquenceColors.cyan.withOpacity(0.3),
            color: EloquenceColors.cyan,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }

    return spans;
  }

  Widget _buildWaveformVisualizer() {
    return Container(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(25, (index) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final height = _isRecording
                  ? (20 + (Random().nextDouble() * 40)).clamp(8.0, 60.0)
                  : 8.0;

              final color = Color.lerp(
                EloquenceColors.cyan,
                EloquenceColors.violet,
                index / 25,
              )!;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: _isRecording && height > 30
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? (1.0 + (_pulseController.value * 0.1)) : 1.0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isRecording
                    ? RadialGradient(
                        colors: [Colors.red, Colors.red.shade700],
                      )
                    : EloquenceColors.cyanVioletGradient,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : EloquenceColors.cyan)
                        .withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  void _startRecording() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopRecording() {
    _pulseController.stop();
    _waveController.stop();
    _timer?.cancel();

    widget.onRecordingComplete(_recordingDuration);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
  }

  String _getSupportTypeName(SupportType type) {
    switch (type) {
      case SupportType.fullText:
        return 'Texte complet';
      case SupportType.fillInBlanks:
        return 'Texte à trous';
      case SupportType.guidedStructure:
        return 'Structure guidée';
      case SupportType.keywordChallenge:
        return 'Mots-clés imposés';
      case SupportType.freeImprovisation:
        return 'Improvisation libre';
    }
  }
}