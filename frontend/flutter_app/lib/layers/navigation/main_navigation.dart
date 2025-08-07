import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/navigation_state.dart';
import '../../core/theme/eloquence_unified_theme.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final Function(String) onNavigationChanged;

  const MainNavigation({
    Key? key,
    required this.onNavigationChanged,
  }) : super(key: key);

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _pressedRoute;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ref.watch(navigationStateProvider).currentRoute;

    // Masquer la barre de navigation si sur l'écran virelangue_roulette
    if (currentRoute == '/virelangue_roulette') {
      return const SizedBox.shrink(); // Widget vide pour masquer
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: EloquenceTheme.navy.withAlpha((255 * 0.5).round()),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: EloquenceTheme.cyan.withAlpha((255 * 0.3).round()),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  route: '/home',
                  isActive: currentRoute == '/home',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercices',
                  route: '/exercises',
                  isActive: currentRoute == '/exercises',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  route: '/profile',
                  isActive: currentRoute == '/profile',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.movie_filter_rounded,
                  label: 'Scénario',
                  route: '/scenarios',
                  isActive: currentRoute == '/scenarios',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.business_center_rounded,
                  label: 'Studio Pro',
                  route: '/studio_situations_pro',
                  isActive: currentRoute == '/studio_situations_pro',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final scale = _pressedRoute == route ? _scaleAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Feedback tactile
                HapticFeedback.lightImpact();
                widget.onNavigationChanged(route);
                // Navigation gérée par NavigationState via onNavigationChanged
              },
              onTapDown: (_) {
                setState(() {
                  _pressedRoute = route;
                });
                _animationController.forward();
              },
              onTapUp: (_) {
                _animationController.reverse();
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) {
                    setState(() {
                      _pressedRoute = null;
                    });
                  }
                });
              },
              onTapCancel: () {
                _animationController.reverse();
                setState(() {
                  _pressedRoute = null;
                });
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: EloquenceTheme.cyan.withAlpha((255 * 0.3).round()),
              highlightColor: EloquenceTheme.cyan.withAlpha((255 * 0.1).round()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                    ? EloquenceTheme.cyan.withAlpha((255 * 0.2).round())
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                    ? Border.all(
                        color: EloquenceTheme.cyan.withAlpha((255 * 0.5).round()),
                        width: 1,
                      )
                    : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        icon,
                        color: isActive ? EloquenceTheme.cyan : EloquenceTheme.white,
                        size: 24,
                      ),
                    ),
                    if (isActive)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 8,
                      ),
                    if (isActive)
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: 1.0,
                          child: Text(
                            label,
                            style: EloquenceTheme.bodySmall.copyWith(
                              color: EloquenceTheme.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
}
