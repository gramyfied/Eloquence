import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../data/services/studio_situations_pro_service.dart';

/// Widget pour afficher un avatar d'agent avec effet de lueur animé
class MultiAgentAvatarWidget extends StatefulWidget {
  final AgentInfo agent;
  final bool isActive;
  final double size;
  final VoidCallback? onTap;
  
  const MultiAgentAvatarWidget({
    super.key,
    required this.agent,
    this.isActive = false,
    this.size = 80,
    this.onTap,
  });
  
  @override
  State<MultiAgentAvatarWidget> createState() => _MultiAgentAvatarWidgetState();
}

class _MultiAgentAvatarWidgetState extends State<MultiAgentAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Animation de lueur (glow)
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Animation de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Animation de rotation subtile pour l'effet halo
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Démarrer les animations si l'agent est actif
    _updateAnimations();
  }
  
  @override
  void didUpdateWidget(MultiAgentAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    if (widget.isActive) {
      _glowController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    } else {
      _glowController.stop();
      _pulseController.stop();
      _rotationController.stop();
      _glowController.reset();
      _pulseController.reset();
      _rotationController.reset();
    }
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  
  Color _getAgentColor() {
    // Couleurs uniques par rôle d'agent
    final roleColors = {
      'Animateur TV': EloquenceTheme.cyan,
      'Journaliste': EloquenceTheme.violet,
      'Expert': EloquenceTheme.successGreen,
      'Manager RH': EloquenceTheme.cyanDark,
      'Expert Technique': EloquenceTheme.successGreen,
      'PDG': EloquenceTheme.errorRed,
      'Directeur Financier': EloquenceTheme.warningOrange,
      'Client Principal': EloquenceTheme.violetLight,
      'Partenaire Technique': EloquenceTheme.violetDark,
      'Modératrice': EloquenceTheme.celebrationGold,
      'Expert Audience': EloquenceTheme.cyanLight,
    };
    
    return roleColors[widget.agent.role] ?? EloquenceTheme.cyan;
  }
  
  @override
  Widget build(BuildContext context) {
    final agentColor = _getAgentColor();
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _glowAnimation,
          _pulseAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          return Container(
            width: widget.size * _pulseAnimation.value,
            height: widget.size * _pulseAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Effet de halo rotatif (arrière-plan)
                if (widget.isActive)
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: widget.size * 1.5,
                      height: widget.size * 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            agentColor.withOpacity(0.3 * _glowAnimation.value),
                            agentColor.withOpacity(0.1 * _glowAnimation.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                
                // Cercles de lueur concentrique
                if (widget.isActive) ...[
                  _buildGlowRing(
                    size: widget.size * 1.3,
                    color: agentColor,
                    opacity: 0.2 * _glowAnimation.value,
                  ),
                  _buildGlowRing(
                    size: widget.size * 1.15,
                    color: agentColor,
                    opacity: 0.3 * _glowAnimation.value,
                  ),
                ],
                
                // Avatar principal avec bordure
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isActive 
                          ? agentColor 
                          : agentColor.withOpacity(0.3),
                      width: widget.isActive ? 3 : 2,
                    ),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: agentColor.withOpacity(0.6 * _glowAnimation.value),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: agentColor.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: ClipOval(
                    child: _buildAvatarContent(),
                  ),
                ),
                
                // Badge d'activité
                if (widget.isActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildActivityBadge(agentColor),
                  ),
                
                // Indicateur de participation
                if (widget.agent.participationRate > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildParticipationIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGlowRing({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }
  
  Widget _buildAvatarContent() {
    // Utiliser les vraies images d'avatars copiées depuis Downloads
    if (widget.agent.avatarPath.isNotEmpty && 
        widget.agent.avatarPath.startsWith('assets/')) {
      return Image.asset(
        widget.agent.avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // En cas d'erreur de chargement, afficher l'avatar par défaut
          debugPrint('Erreur chargement avatar: ${widget.agent.avatarPath}');
          return _buildFallbackAvatar();
        },
      );
    }
    
    // Avatar par défaut si pas d'image
    return _buildFallbackAvatar();
  }
  
  Widget _buildFallbackAvatar() {
    final initials = widget.agent.name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    
    final agentColor = _getAgentColor();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            agentColor.withOpacity(0.8),
            agentColor.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.3,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
  
  Widget _buildActivityBadge(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildParticipationIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${(widget.agent.participationRate * 100).toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget pour afficher la grille d'avatars multi-agents
class MultiAgentAvatarGrid extends StatelessWidget {
  final List<AgentInfo> agents;
  final String? activeSpeakerId;
  final Function(AgentInfo)? onAgentTap;
  
  const MultiAgentAvatarGrid({
    super.key,
    required this.agents,
    this.activeSpeakerId,
    this.onAgentTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Adapter la disposition selon le nombre d'agents
    if (agents.length <= 3) {
      // Disposition horizontale pour peu d'agents
      return _buildHorizontalLayout();
    } else {
      // Grille pour plus d'agents
      return _buildGridLayout();
    }
  }
  
  Widget _buildHorizontalLayout() {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: agents.map((agent) {
          return Expanded(
            child: Column(
              children: [
                MultiAgentAvatarWidget(
                  agent: agent,
                  isActive: agent.id == activeSpeakerId || agent.isActive,
                  size: 70,
                  onTap: () => onAgentTap?.call(agent),
                ),
                const SizedBox(height: 8),
                Text(
                  agent.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: agent.isActive 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    color: agent.isActive 
                        ? EloquenceTheme.cyan
                        : Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  agent.role,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildGridLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MultiAgentAvatarWidget(
              agent: agent,
              isActive: agent.id == activeSpeakerId || agent.isActive,
              size: 60,
              onTap: () => onAgentTap?.call(agent),
            ),
            const SizedBox(height: 4),
            Text(
              agent.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: agent.isActive 
                    ? FontWeight.bold 
                    : FontWeight.normal,
                color: agent.isActive 
                    ? EloquenceTheme.cyan
                    : Colors.white70,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              agent.role,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}

/// Widget indicateur de speaker actif avec animation de parole
class ActiveSpeakerIndicator extends StatefulWidget {
  final String speakerName;
  final Color color;
  
  const ActiveSpeakerIndicator({
    super.key,
    required this.speakerName,
    this.color = EloquenceTheme.cyan,
  });
  
  @override
  State<ActiveSpeakerIndicator> createState() => _ActiveSpeakerIndicatorState();
}

class _ActiveSpeakerIndicatorState extends State<ActiveSpeakerIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withOpacity(0.5 + 0.5 * _animation.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _animation.value),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône de micro animée
              Icon(
                Icons.mic,
                color: widget.color,
                size: 16,
              ),
              const SizedBox(width: 8),
              // Barres de son animées
              ...List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 3,
                  height: 12 + (8 * _animation.value * ((index + 1) / 3)),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 8),
              // Nom du speaker
              Text(
                widget.speakerName,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}