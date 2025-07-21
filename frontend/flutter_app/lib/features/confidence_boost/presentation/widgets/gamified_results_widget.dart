import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/gamification_models.dart';
import '../../data/services/adaptive_gamification_service.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// Widget de Résultats Gamifiés Sophistiqué
/// 
/// ✅ FONCTIONNALITÉS AVANCÉES :
/// - Affichage spectaculaire des récompenses XP
/// - Animation de montée de niveau avec confettis
/// - Badges débloqués avec effets visuels
/// - Progression de streak avec flammes animées
/// - Encouragements personnalisés contextuels
/// - Design system Eloquence parfaitement intégré
class GamifiedResultsWidget extends ConsumerStatefulWidget {
  final GamificationResult gamificationResult;
  final UserGamificationProfile userProfile;
  final bool showFullAnimation;
  final VoidCallback? onAnimationComplete;

  const GamifiedResultsWidget({
    Key? key,
    required this.gamificationResult,
    required this.userProfile,
    this.showFullAnimation = true,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  ConsumerState<GamifiedResultsWidget> createState() => _GamifiedResultsWidgetState();
}

class _GamifiedResultsWidgetState extends ConsumerState<GamifiedResultsWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _xpAnimationController;
  late AnimationController _badgeAnimationController;
  late AnimationController _levelUpAnimationController;
  late AnimationController _streakAnimationController;
  
  late Animation<double> _xpScaleAnimation;
  late Animation<double> _xpOpacityAnimation;
  late Animation<double> _badgeSlideAnimation;
  late Animation<double> _levelUpExplosionAnimation;
  late Animation<double> _streakFlameAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.showFullAnimation) {
      _startAnimationSequence();
    }
  }

  void _initializeAnimations() {
    // Animation XP (durée Design System : medium)
    _xpAnimationController = AnimationController(
      duration: EloquenceTheme.animationMedium,
      vsync: this,
    );
    
    _xpScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: EloquenceTheme.curveElastic),
    );
    
    _xpOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: EloquenceTheme.curveEnter),
    );

    // Animation badges (durée : slow pour effet dramatique)
    _badgeAnimationController = AnimationController(
      duration: EloquenceTheme.animationSlow,
      vsync: this,
    );
    
    _badgeSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _badgeAnimationController, curve: EloquenceTheme.curveBounce),
    );

    // Animation level up (si applicable)
    _levelUpAnimationController = AnimationController(
      duration: EloquenceTheme.animationXSlow,
      vsync: this,
    );
    
    _levelUpExplosionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpAnimationController, curve: EloquenceTheme.curveEmphasized),
    );

    // Animation streak
    _streakAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _streakFlameAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _streakAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startAnimationSequence() async {
    // Séquence d'animations avec timing optimal
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 1. Animation XP
    await _xpAnimationController.forward();
    
    // 2. Animation badges (si nouveaux badges)
    if (widget.gamificationResult.newBadges.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _badgeAnimationController.forward();
    }
    
    // 3. Animation level up (si montée de niveau)
    if (widget.gamificationResult.levelUp) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _levelUpAnimationController.forward();
    }
    
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    _badgeAnimationController.dispose();
    _levelUpAnimationController.dispose();
    _streakAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EloquenceComponents.glassContainer(
      padding: const EdgeInsets.all(EloquenceTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(),
          const SizedBox(height: EloquenceTheme.spacingLg),
          _buildXPDisplay(),
          const SizedBox(height: EloquenceTheme.spacingLg),
          if (widget.gamificationResult.levelUp) ...[
            _buildLevelUpCelebration(),
            const SizedBox(height: EloquenceTheme.spacingLg),
          ],
          if (widget.gamificationResult.newBadges.isNotEmpty) ...[
            _buildNewBadges(),
            const SizedBox(height: EloquenceTheme.spacingLg),
          ],
          _buildProgressSection(),
          const SizedBox(height: EloquenceTheme.spacingLg),
          _buildStreakSection(),
          const SizedBox(height: EloquenceTheme.spacingLg),
          _buildEncouragements(),
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
        const SizedBox(height: EloquenceTheme.spacingSm),
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
              padding: const EdgeInsets.all(EloquenceTheme.spacingLg),
              decoration: const BoxDecoration(
                gradient: EloquenceTheme.primaryGradient,
                borderRadius: EloquenceTheme.borderRadiusLarge,
                boxShadow: EloquenceTheme.shadowGlow,
              ),
              child: Column(
                children: [
                  Text(
                    '+${widget.gamificationResult.earnedXP}',
                    style: EloquenceTheme.scoreDisplay,
                  ),
                  const SizedBox(height: EloquenceTheme.spacingSm),
                  Text(
                    'Points d\'expérience',
                    style: EloquenceTheme.bodyLarge.copyWith(
                      color: EloquenceTheme.withOpacity(EloquenceTheme.white, 0.9),
                    ),
                  ),
                  const SizedBox(height: EloquenceTheme.spacingMd),
                  _buildBonusMultiplierBreakdown(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusMultiplierBreakdown() {
    final multiplier = widget.gamificationResult.bonusMultiplier;
    final bonuses = <String, double>{
      'Performance': multiplier.performanceMultiplier,
      'Streak': multiplier.streakMultiplier,
      'Difficulté': multiplier.difficultyMultiplier,
      'Temps': multiplier.timeMultiplier,
    };

    return Column(
      children: [
        Text(
          'Multiplicateurs de bonus',
          style: EloquenceTheme.caption.copyWith(
            color: EloquenceTheme.withOpacity(EloquenceTheme.white, 0.8),
          ),
        ),
        const SizedBox(height: EloquenceTheme.spacingSm),
        Wrap(
          spacing: EloquenceTheme.spacingSm,
          children: bonuses.entries
              .where((entry) => entry.value > 1.0)
              .map((entry) => EloquenceComponents.coloredBadge(
                    text: '${entry.key} x${entry.value.toStringAsFixed(1)}',
                    color: EloquenceTheme.successGreen,
                    icon: Icons.trending_up,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLevelUpCelebration() {
    return AnimatedBuilder(
      animation: _levelUpAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.3 * _levelUpExplosionAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(EloquenceTheme.spacingXl),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  EloquenceTheme.withOpacity(EloquenceTheme.celebrationGold, 0.3),
                  EloquenceTheme.withOpacity(EloquenceTheme.violet, 0.1),
                ],
              ),
              borderRadius: EloquenceTheme.borderRadiusXLarge,
              border: Border.all(
                color: EloquenceTheme.celebrationGold,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: EloquenceTheme.withOpacity(EloquenceTheme.celebrationGold, 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '🎊 NIVEAU SUPÉRIEUR ! 🎊',
                  style: EloquenceTheme.headline2.copyWith(
                    color: EloquenceTheme.celebrationGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: EloquenceTheme.spacingSm),
                Text(
                  'Niveau ${widget.gamificationResult.newLevel}',
                  style: EloquenceTheme.headline1.copyWith(
                    color: EloquenceTheme.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏆 Nouveaux badges débloqués',
          style: EloquenceTheme.headline3.copyWith(
            color: EloquenceTheme.cyan,
          ),
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
        AnimatedBuilder(
          animation: _badgeAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_badgeSlideAnimation.value, 0),
              child: Wrap(
                spacing: EloquenceTheme.spacingMd,
                runSpacing: EloquenceTheme.spacingMd,
                children: widget.gamificationResult.newBadges
                    .map((badge) => _buildBadgeCard(badge))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    Color rarityColor = _getBadgeRarityColor(badge.rarity);
    
    return EloquenceComponents.glassContainer(
      padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
      width: 120,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  EloquenceTheme.withOpacity(rarityColor, 0.8),
                  rarityColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: EloquenceTheme.withOpacity(rarityColor, 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getBadgeEmoji(badge),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: EloquenceTheme.spacingSm),
          Text(
            badge.name,
            style: EloquenceTheme.bodySmall.copyWith(
              color: rarityColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: EloquenceTheme.spacingXs),
          EloquenceComponents.coloredBadge(
            text: '+${badge.xpReward} XP',
            color: EloquenceTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progressPercentage = widget.gamificationResult.xpInCurrentLevel / 
                              widget.gamificationResult.xpRequiredForNextLevel;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Niveau ${widget.gamificationResult.newLevel}',
              style: EloquenceTheme.headline3,
            ),
            Text(
              '${widget.gamificationResult.xpInCurrentLevel}/${widget.gamificationResult.xpRequiredForNextLevel} XP',
              style: EloquenceTheme.bodyMedium.copyWith(
                color: EloquenceTheme.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: EloquenceTheme.spacingSm),
        Container(
          height: 12,
          decoration: const BoxDecoration(
            color: EloquenceTheme.glassBackground,
            borderRadius: EloquenceTheme.borderRadiusMedium,
            border: EloquenceTheme.borderThin,
          ),
          child: LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(EloquenceTheme.cyan),
            borderRadius: EloquenceTheme.borderRadiusMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection() {
    final streakInfo = widget.gamificationResult.streakInfo;
    
    return AnimatedBuilder(
      animation: _streakAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                EloquenceTheme.withOpacity(EloquenceTheme.warningOrange, 0.2),
                EloquenceTheme.withOpacity(EloquenceTheme.errorRed, 0.1),
              ],
            ),
            borderRadius: EloquenceTheme.borderRadiusMedium,
            border: Border.all(
              color: EloquenceTheme.withOpacity(EloquenceTheme.warningOrange, 0.5),
            ),
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: _streakFlameAnimation.value,
                child: const Text('🔥', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: EloquenceTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Série de ${streakInfo.currentStreak} jours',
                      style: EloquenceTheme.bodyLarge.copyWith(
                        color: EloquenceTheme.warningOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (streakInfo.newRecord) ...[
                      const SizedBox(height: EloquenceTheme.spacingXs),
                      EloquenceComponents.coloredBadge(
                        text: '🏆 Nouveau record !',
                        color: EloquenceTheme.celebrationGold,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEncouragements() {
    final gamificationService = ref.read(adaptiveGamificationServiceProvider);
    final encouragements = gamificationService.getPersonalizedEncouragements(
      widget.userProfile,
      null, // lastResult peut être null ici
    );

    if (encouragements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💬 Encouragements',
          style: EloquenceTheme.headline3.copyWith(
            color: EloquenceTheme.violet,
          ),
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
        ...encouragements.map((encouragement) => Padding(
              padding: const EdgeInsets.only(bottom: EloquenceTheme.spacingSm),
              child: EloquenceComponents.glassContainer(
                padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
                child: Text(
                  encouragement,
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: EloquenceTheme.withOpacity(EloquenceTheme.white, 0.9),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Color _getBadgeRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.rare:
        return EloquenceTheme.cyan;
      case BadgeRarity.epic:
        return EloquenceTheme.violet;
      case BadgeRarity.legendary:
        return EloquenceTheme.celebrationGold;
    }
  }

  String _getBadgeEmoji(Badge badge) {
    // Mapper les badges aux emojis selon leur ID
    switch (badge.id) {
      case 'first_excellent': return '🌟';
      case 'perfectionist': return '💎';
      case 'consistency_master': return '🎯';
      case 'streak_3': return '🔥';
      case 'streak_7': return '⚡';
      case 'streak_30': return '🏆';
      case 'level_5': return '📈';
      case 'level_10': return '🚀';
      case 'xp_1000': return '💫';
      case 'early_bird': return '🌅';
      case 'night_owl': return '🌙';
      case 'marathon': return '🏃';
      default: return '🏅';
    }
  }
}