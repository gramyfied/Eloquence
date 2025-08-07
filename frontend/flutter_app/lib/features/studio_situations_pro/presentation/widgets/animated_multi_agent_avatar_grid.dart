import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../data/models/simulation_models.dart';
import '../../data/services/studio_situations_pro_service.dart';

class AnimatedMultiAgentAvatarGrid extends StatefulWidget {
  final List<AgentInfo> agents;
  final String? activeSpeakerId;
  final Function(AgentInfo) onAgentTap;
  final AnimationController animationController;

  const AnimatedMultiAgentAvatarGrid({
    Key? key,
    required this.agents,
    this.activeSpeakerId,
    required this.onAgentTap,
    required this.animationController,
  }) : super(key: key);

  @override
  State<AnimatedMultiAgentAvatarGrid> createState() => _AnimatedMultiAgentAvatarGridState();
}

class _AnimatedMultiAgentAvatarGridState extends State<AnimatedMultiAgentAvatarGrid> 
    with TickerProviderStateMixin {
  
  late List<AnimationController> _avatarAnimations;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    // Initialiser les animations individuelles pour chaque avatar
    _avatarAnimations = List.generate(
      widget.agents.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + (index * 100)),
      ),
    );
    
    _scaleAnimations = _avatarAnimations.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();
    
    _fadeAnimations = _avatarAnimations.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();
    
    // Animation de pulsation pour le speaker actif
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer les animations d'entrée
    for (int i = 0; i < _avatarAnimations.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _avatarAnimations[i].forward();
        }
      });
    }
    
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    for (var controller in _avatarAnimations) {
      controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarCount = widget.agents.length;
        final columns = avatarCount <= 2 ? avatarCount : 3;
        final rows = (avatarCount / columns).ceil();
        final avatarSize = math.min(
          constraints.maxWidth / columns - 20,
          constraints.maxHeight / rows - 20,
        );
        
        return Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(widget.agents.length, (index) {
              final agent = widget.agents[index];
              final isActive = agent.id == widget.activeSpeakerId;
              
              return AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleAnimations[index],
                  _fadeAnimations[index],
                  if (isActive) _pulseAnimation,
                ]),
                builder: (context, child) {
                  final scale = _scaleAnimations[index].value;
                  final fade = _fadeAnimations[index].value;
                  final pulse = isActive ? _pulseAnimation.value : 1.0;
                  
                  return Transform.scale(
                    scale: scale * pulse,
                    child: Opacity(
                      opacity: fade,
                      child: _buildAnimatedAvatar(
                        agent: agent,
                        size: avatarSize,
                        isActive: isActive,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedAvatar({
    required AgentInfo agent,
    required double size,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => widget.onAgentTap(agent),
      child: Container(
        width: size,
        height: size + 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isActive ? [
                  BoxShadow(
                    color: EloquenceTheme.cyan.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: EloquenceTheme.violet.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo animé pour le speaker actif
                  if (isActive)
                    ...List.generate(3, (i) {
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final value = (_pulseController.value + (i * 0.3)) % 1.0;
                          return Container(
                            width: size * (1 + value * 0.5),
                            height: size * (1 + value * 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: EloquenceTheme.cyan.withOpacity(0.5 * (1 - value)),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  
                  // Avatar principal
                  ClipOval(
                    child: Container(
                      width: size * 0.9,
                      height: size * 0.9,
                      decoration: BoxDecoration(
                        color: EloquenceTheme.navy.withOpacity(0.8),
                        border: Border.all(
                          color: isActive ? EloquenceTheme.cyan : Colors.white24,
                          width: isActive ? 3 : 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: agent.avatarPath.isNotEmpty
                        ? Image.asset(
                            agent.avatarPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackAvatar(agent);
                            },
                          )
                        : _buildFallbackAvatar(agent),
                    ),
                  ),
                  
                  // Indicateur de parole
                  if (isActive)
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: EloquenceTheme.cyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: EloquenceTheme.cyan.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  
                  // Badge de participation
                  if (agent.participationRate > 0.7)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: EloquenceTheme.violet,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              agent.name,
              style: EloquenceTheme.bodySmall.copyWith(
                color: isActive ? EloquenceTheme.cyan : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFallbackAvatar(AgentInfo agent) {
    final initials = agent.name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EloquenceTheme.violet,
            EloquenceTheme.cyan,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: EloquenceTheme.headline3.copyWith(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

class ActiveSpeakerIndicator extends StatefulWidget {
  final String speakerName;
  final Color color;
  
  const ActiveSpeakerIndicator({
    Key? key,
    required this.speakerName,
    required this.color,
  }) : super(key: key);
  
  @override
  State<ActiveSpeakerIndicator> createState() => _ActiveSpeakerIndicatorState();
}

class _ActiveSpeakerIndicatorState extends State<ActiveSpeakerIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.2 * _fadeAnimation.value),
            borderRadius: EloquenceTheme.borderRadiusLarge,
            border: Border.all(
              color: widget.color.withOpacity(_fadeAnimation.value),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic,
                color: widget.color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.speakerName,
                style: EloquenceTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_fadeAnimation.value),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}