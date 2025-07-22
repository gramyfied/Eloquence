import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../data/services/conversation_manager.dart';

/// Widget d'affichage des métriques comportementales temps réel
/// 
/// ✅ FONCTIONNALITÉS :
/// - Affichage temps réel des scores de confiance, fluidité, clarté, énergie
/// - Animations fluides et indicateurs visuels
/// - Design Eloquence avec dégradés cyan/violet
/// - Mise à jour automatique via ConversationMetrics
class RealTimeMetricsWidget extends StatefulWidget {
  final ConversationMetrics? metrics;
  final bool isActive;
  final VoidCallback? onTap;

  const RealTimeMetricsWidget({
    Key? key,
    this.metrics,
    this.isActive = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<RealTimeMetricsWidget> createState() => _RealTimeMetricsWidgetState();
}

class _RealTimeMetricsWidgetState extends State<RealTimeMetricsWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Métriques simulées pour l'affichage temps réel
  double _confidenceScore = 0.0;
  double _fluencyScore = 0.0;
  double _clarityScore = 0.0;
  double _energyScore = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startMetricsSimulation();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(RealTimeMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
      } else {
        _pulseController.stop();
        _rotationController.stop();
      }
    }

    // Mettre à jour les métriques si disponibles
    if (widget.metrics != null) {
      _updateMetricsFromConversation();
    }
  }

  void _updateMetricsFromConversation() {
    // Pour l'instant, utiliser des valeurs simulées basées sur la durée
    // TODO: Intégrer les vraies métriques comportementales depuis ConversationManager
    if (widget.metrics != null) {
      final duration = widget.metrics!.totalDuration.inSeconds;
      final turns = widget.metrics!.turnCount;
      
      setState(() {
        // Simuler progression réaliste des métriques
        _confidenceScore = (0.5 + (duration * 0.01) + (turns * 0.05)).clamp(0.0, 1.0);
        _fluencyScore = (0.6 + (duration * 0.008) + (turns * 0.04)).clamp(0.0, 1.0);
        _clarityScore = (0.7 + (duration * 0.006) + (turns * 0.03)).clamp(0.0, 1.0);
        _energyScore = (0.65 + (duration * 0.007) + (turns * 0.035)).clamp(0.0, 1.0);
      });
    }
  }

  void _startMetricsSimulation() {
    // Simulation en temps réel pour l'affichage même sans vraies métriques
    if (widget.isActive) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && widget.isActive) {
          setState(() {
            _confidenceScore = (_confidenceScore + (Random().nextDouble() * 0.02 - 0.01)).clamp(0.0, 1.0);
            _fluencyScore = (_fluencyScore + (Random().nextDouble() * 0.015 - 0.0075)).clamp(0.0, 1.0);
            _clarityScore = (_clarityScore + (Random().nextDouble() * 0.01 - 0.005)).clamp(0.0, 1.0);
            _energyScore = (_energyScore + (Random().nextDouble() * 0.018 - 0.009)).clamp(0.0, 1.0);
          });
          _startMetricsSimulation();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EloquenceColors.glassBackground,
              EloquenceColors.glassBackground.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isActive ? EloquenceColors.cyan : EloquenceColors.glassBackground,
            width: 2,
          ),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: EloquenceColors.cyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: widget.isActive ? _rotationAnimation.value : 0,
                      child: Icon(
                        Icons.analytics_outlined,
                        color: widget.isActive ? EloquenceColors.cyan : Colors.grey,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Métriques Temps Réel',
                  style: EloquenceTextStyles.body1.copyWith(
                    color: widget.isActive ? EloquenceColors.cyan : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.metrics != null) ...[
                  Icon(
                    Icons.timer_outlined,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(widget.metrics!.totalDuration),
                    style: EloquenceTextStyles.caption.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            
            if (widget.isActive) ...[
              const SizedBox(height: 16),
              
              // Grille des métriques
              Row(
                children: [
                  Expanded(
                    child: _buildMetricIndicator(
                      'Confiance',
                      _confidenceScore,
                      EloquenceColors.cyan,
                      Icons.emoji_events_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricIndicator(
                      'Fluidité',
                      _fluencyScore,
                      EloquenceColors.violet,
                      Icons.water_drop_outlined,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildMetricIndicator(
                      'Clarté',
                      _clarityScore,
                      EloquenceColors.cyan,
                      Icons.visibility_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricIndicator(
                      'Énergie',
                      _energyScore,
                      EloquenceColors.violet,
                      Icons.bolt_outlined,
                    ),
                  ),
                ],
              ),
              
              if (widget.metrics != null) ...[
                const SizedBox(height: 12),
                _buildConversationStats(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricIndicator(String label, double score, Color color, IconData icon) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: score > 0.8 ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(score > 0.7 ? 0.6 : 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: EloquenceTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(score * 100).round()}%',
                  style: EloquenceTextStyles.caption.copyWith(
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: score,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationStats() {
    final metrics = widget.metrics!;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EloquenceColors.navy.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.chat_outlined,
            '${metrics.turnCount}',
            'Tours',
          ),
          _buildStatItem(
            Icons.speed_outlined,
            '${metrics.averageResponseTime.inMilliseconds}ms',
            'Réponse moy.',
          ),
          _buildStatItem(
            Icons.trending_up_outlined,
            _getStateEmoji(metrics.currentState),
            'État',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.grey,
          size: 14,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: EloquenceTextStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        Text(
          label,
          style: EloquenceTextStyles.caption.copyWith(
            color: Colors.grey,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  String _getStateEmoji(ConversationState state) {
    switch (state) {
      case ConversationState.aiSpeaking:
        return '🤖';
      case ConversationState.userSpeaking:
        return '🎤';
      case ConversationState.processing:
        return '⚡';
      case ConversationState.aiThinking:
        return '🧠';
      case ConversationState.paused:
        return '⏸️';
      case ConversationState.ended:
        return '✅';
      default:
        return '🔄';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
  }
}