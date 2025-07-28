import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/virelangue_models.dart';
import '../theme/virelangue_roulette_theme.dart';

/// Widget d'affichage des gemmes simplifié selon le design des images
/// Design épuré avec gemmes circulaires et scores visibles
class VirelangueGemDisplay extends StatefulWidget {
  final GemCollection gemCollection;
  final bool showScores;
  final EdgeInsets padding;
  final MainAxisAlignment alignment;

  const VirelangueGemDisplay({
    super.key,
    required this.gemCollection,
    this.showScores = true,
    this.padding = const EdgeInsets.all(16),
    this.alignment = MainAxisAlignment.spaceEvenly,
  });

  @override
  State<VirelangueGemDisplay> createState() => _VirelangueGemDisplayState();
}

class _VirelangueGemDisplayState extends State<VirelangueGemDisplay>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Map<GemType, int> _previousCounts = {};

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializePreviousCounts();
  }

  @override
  void didUpdateWidget(VirelangueGemDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForNewGems(oldWidget.gemCollection);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializePreviousCounts() {
    _previousCounts = Map.from(widget.gemCollection.gems);
  }

  void _checkForNewGems(GemCollection oldCollection) {
    bool hasAnyNewGems = false;
    
    for (final type in GemType.values) {
      final oldCount = oldCollection.gems[type] ?? 0;
      final newCount = widget.gemCollection.gems[type] ?? 0;
      
      if (newCount > oldCount) {
        hasAnyNewGems = true;
      }
    }
    
    if (hasAnyNewGems) {
      HapticFeedback.lightImpact();
    }
    
    _previousCounts = Map.from(widget.gemCollection.gems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: widget.alignment,
        children: [
          _buildGemWithScore(GemType.diamond, '💎', '+10'),
          _buildGemWithScore(GemType.emerald, '💚', '+15'),
          _buildGemWithScore(GemType.ruby, '💖', '+20'),
        ],
      ),
    );
  }

  /// Construit une gemme avec son score selon les images
  Widget _buildGemWithScore(GemType type, String emoji, String score) {
    final count = widget.gemCollection.gems[type] ?? 0;
    final gemColor = _getGemColor(type);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: count > 0 ? _pulseAnimation.value : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gemme circulaire
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: gemColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gemColor.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Nombre de gemmes
              Text(
                '$count',
                style: TextStyle(
                  color: VirelangueRouletteTheme.whiteText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Score si activé
              if (widget.showScores) ...[
                const SizedBox(height: 4),
                Text(
                  score,
                  style: TextStyle(
                    color: gemColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Obtient la couleur associée à un type de gemme
  Color _getGemColor(GemType type) {
    switch (type) {
      case GemType.ruby:
        return VirelangueRouletteTheme.rubyGem;
      case GemType.emerald:
        return VirelangueRouletteTheme.emeraldGem;
      case GemType.diamond:
        return VirelangueRouletteTheme.diamondGem;
    }
  }
}

/// Widget compact pour affichage minimal des gemmes selon les images
class CompactGemDisplay extends StatelessWidget {
  final GemCollection gemCollection;
  final GemType? highlightType;

  const CompactGemDisplay({
    super.key,
    required this.gemCollection,
    this.highlightType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactGem(GemType.diamond, '💎'),
        const SizedBox(width: 12),
        _buildCompactGem(GemType.emerald, '💚'),
        const SizedBox(width: 12),
        _buildCompactGem(GemType.ruby, '💖'),
      ],
    );
  }

  Widget _buildCompactGem(GemType type, String emoji) {
    final count = gemCollection.gems[type] ?? 0;
    final isHighlighted = highlightType == type;
    final gemColor = _getGemColor(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? gemColor.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(
          color: gemColor,
          width: 1,
        ) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? gemColor : VirelangueRouletteTheme.whiteText,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGemColor(GemType type) {
    switch (type) {
      case GemType.ruby:
        return VirelangueRouletteTheme.rubyGem;
      case GemType.emerald:
        return VirelangueRouletteTheme.emeraldGem;
      case GemType.diamond:
        return VirelangueRouletteTheme.diamondGem;
    }
  }
}

/// Widget d'animation simplifiée pour les nouvelles gemmes obtenues
class NewGemAnimation extends StatefulWidget {
  final GemType gemType;
  final int count;
  final VoidCallback? onAnimationComplete;

  const NewGemAnimation({
    super.key,
    required this.gemType,
    required this.count,
    this.onAnimationComplete,
  });

  @override
  State<NewGemAnimation> createState() => _NewGemAnimationState();
}

class _NewGemAnimationState extends State<NewGemAnimation>
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGemColor(widget.gemType),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getGemColor(widget.gemType).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.gemType.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGemColor(GemType type) {
    switch (type) {
      case GemType.ruby:
        return VirelangueRouletteTheme.rubyGem;
      case GemType.emerald:
        return VirelangueRouletteTheme.emeraldGem;
      case GemType.diamond:
        return VirelangueRouletteTheme.diamondGem;
    }
  }
}