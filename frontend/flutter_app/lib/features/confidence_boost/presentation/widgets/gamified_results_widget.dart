import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/entities/dragon_breath_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget de Résultats Gamifiés Générique (Version simplifiée)
/// 
/// Note: Pour l'exercice Dragon spécialisé, utilisez DragonResultsWidget
class GamifiedResultsWidget extends StatefulWidget {
  final int earnedXP;
  final bool showFullAnimation;
  final VoidCallback? onAnimationComplete;

  const GamifiedResultsWidget({
    Key? key,
    required this.earnedXP,
    this.showFullAnimation = true,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<GamifiedResultsWidget> createState() => _GamifiedResultsWidgetState();
}

class _GamifiedResultsWidgetState extends State<GamifiedResultsWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _xpAnimationController;
  late Animation<double> _xpScaleAnimation;
  late Animation<double> _xpOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.showFullAnimation) {
      _startAnimationSequence();
    }
  }

  void _initializeAnimations() {
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _xpScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: Curves.elasticOut),
    );
    
    _xpOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeOut),
    );
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _xpAnimationController.forward();
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EloquenceTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildXPDisplay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.emoji_events,
          size: 48,
          color: EloquenceTheme.celebrationGold,
        ),
        const SizedBox(height: 8),
        Text(
          '🎉 Récompenses gagnées !',
          style: EloquenceTheme.headline2.copyWith(
            color: EloquenceTheme.celebrationGold,
          ),
        ),
      ],
    );
  }

  Widget _buildXPDisplay() {
    return AnimatedBuilder(
      animation: _xpAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _xpScaleAnimation.value,
          child: Opacity(
            opacity: _xpOpacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    EloquenceTheme.cyan.withOpacity(0.8),
                    EloquenceTheme.cyan.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: EloquenceTheme.cyan.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '+${widget.earnedXP}',
                    style: EloquenceTheme.headline1.copyWith(
                      color: EloquenceTheme.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Points d\'expérience',
                    style: EloquenceTheme.bodyLarge.copyWith(
                      color: EloquenceTheme.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}