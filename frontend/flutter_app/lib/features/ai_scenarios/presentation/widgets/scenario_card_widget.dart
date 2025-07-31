import 'package:flutter/material.dart';
import '../../domain/entities/scenario_models.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget de carte pour sélectionner un type de scénario
class ScenarioCardWidget extends StatefulWidget {
  final ScenarioType type;
  final bool isSelected;
  final VoidCallback onTap;

  const ScenarioCardWidget({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ScenarioCardWidget> createState() => _ScenarioCardWidgetState();
}

class _ScenarioCardWidgetState extends State<ScenarioCardWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: EloquenceTheme.animationMedium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: EloquenceTheme.curveStandard,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: EloquenceTheme.curveStandard,
    ));
  }

  @override
  void didUpdateWidget(ScenarioCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.isSelected 
                    ? LinearGradient(
                        colors: [
                          EloquenceTheme.cyan.withOpacity(0.2),
                          EloquenceTheme.violet.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isSelected ? null : EloquenceTheme.glassBackground,
                borderRadius: EloquenceTheme.borderRadiusLarge,
                border: Border.all(
                  color: widget.isSelected 
                      ? EloquenceTheme.cyan 
                      : EloquenceTheme.glassBorder,
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected 
                    ? [
                        BoxShadow(
                          color: EloquenceTheme.cyan.withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : EloquenceTheme.shadowSmall,
              ),
              child: Padding(
                padding: const EdgeInsets.all(EloquenceTheme.spacingXs),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculer les tailles dynamiquement selon l'espace disponible
                    final availableHeight = constraints.maxHeight;
                    final availableWidth = constraints.maxWidth;
                    
                    // Tailles plus conservatrices pour éviter le débordement
                    final emojiSize = (availableHeight * 0.25).clamp(12.0, 24.0);
                    final titleFontSize = (availableHeight * 0.08).clamp(7.0, 10.0);
                    final descriptionFontSize = (availableHeight * 0.06).clamp(6.0, 8.0);
                    
                    // Vérifier si l'espace est très limité
                    final isVerySmall = availableHeight < 80 || availableWidth < 100;
                    
                    if (isVerySmall) {
                      // Layout simplifié pour les très petits espaces
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Emoji seulement
                          Text(
                            widget.type.emoji,
                            style: TextStyle(fontSize: emojiSize),
                          ),
                          
                          // Titre compact
                          if (availableHeight > 50) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.type.displayName,
                              textAlign: TextAlign.center,
                              style: EloquenceTheme.bodySmall.copyWith(
                                color: widget.isSelected 
                                    ? EloquenceTheme.cyan 
                                    : EloquenceTheme.white,
                                fontWeight: FontWeight.w600,
                                fontSize: titleFontSize,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      );
                    }
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Emoji du scénario - toujours affiché
                        Text(
                          widget.type.emoji,
                          style: TextStyle(fontSize: emojiSize),
                        ),
                        
                        // Espacement minimal seulement si nécessaire
                        if (availableHeight > 60) 
                          SizedBox(height: 2),
                        
                        // Titre du scénario - adaptatif
                        if (availableHeight > 45)
                          Flexible(
                            child: Text(
                              widget.type.displayName,
                              textAlign: TextAlign.center,
                              style: EloquenceTheme.bodyMedium.copyWith(
                                color: widget.isSelected 
                                    ? EloquenceTheme.cyan 
                                    : EloquenceTheme.white,
                                fontWeight: FontWeight.w600,
                                fontSize: titleFontSize,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        
                        // Description seulement si beaucoup d'espace
                        if (availableHeight > 100) ...[
                          const SizedBox(height: 1),
                          
                          Flexible(
                            child: Text(
                              widget.type.description,
                              textAlign: TextAlign.center,
                              style: EloquenceTheme.bodySmall.copyWith(
                                fontSize: descriptionFontSize,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
