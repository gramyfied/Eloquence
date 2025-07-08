import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/navigation/navigation_state.dart';
import '../layers/background/background_carousel.dart';
import '../layers/navigation/glassmorphism_overlay.dart';
import '../layers/navigation/main_navigation.dart';
import '../utils/constants.dart';

class LayeredScaffold extends StatefulWidget {
  final Widget content;
  final CarouselVisibilityState carouselState;
  final bool showNavigation;
  final VoidCallback? onCarouselTap;

  const LayeredScaffold({
    Key? key,
    required this.content,
    required this.carouselState,
    this.showNavigation = true,
    this.onCarouselTap,
  }) : super(key: key);

  @override
  _LayeredScaffoldState createState() => _LayeredScaffoldState();
}

class _LayeredScaffoldState extends State<LayeredScaffold>
    with TickerProviderStateMixin {
  late AnimationController _carouselController;
  late Animation<double> _carouselOpacity;
  late Animation<double> _carouselBlur;

  @override
  void initState() {
    super.initState();
    _carouselController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _carouselOpacity = Tween<double>(
      begin: 1.0,
      end: widget.carouselState.opacity,
    ).animate(CurvedAnimation(
      parent: _carouselController,
      curve: Curves.easeInOut,
    ));

    _carouselBlur = Tween<double>(
      begin: 0.0,
      end: _calculateBlur(widget.carouselState),
    ).animate(CurvedAnimation(
      parent: _carouselController,
      curve: Curves.easeInOut,
    ));
    _carouselController.value = 1.0; // Start at the initial state
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  double _calculateBlur(CarouselVisibilityState state) {
    switch (state) {
      case CarouselVisibilityState.full:
        return 0.0;
      case CarouselVisibilityState.medium:
        return 2.0;
      case CarouselVisibilityState.subtle:
        return 5.0;
      case CarouselVisibilityState.minimal:
        return 8.0;
    }
  }

  @override
  void didUpdateWidget(LayeredScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carouselState != widget.carouselState) {
      _updateCarouselState();
    }
  }

  void _updateCarouselState() {
    final newOpacity = widget.carouselState.opacity;
    final newBlur = _calculateBlur(widget.carouselState);

    _carouselOpacity = Tween<double>(
      begin: _carouselOpacity.value,
      end: newOpacity,
    ).animate(CurvedAnimation(
      parent: _carouselController,
      curve: Curves.easeInOut,
    ));

    _carouselBlur = Tween<double>(
      begin: _carouselBlur.value,
      end: newBlur,
    ).animate(CurvedAnimation(
      parent: _carouselController,
      curve: Curves.easeInOut,
    ));

    _carouselController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      body: Stack(
        children: [
          // Carrousel d'arrière-plan avec effets
          _buildBackgroundCarousel(),
          
          // Contenu principal avec filtre de flou
          _buildMainContent(),
          
          // Navigation principale (si activée)
          if (widget.showNavigation) _buildMainNavigation(),
        ],
      ),
    );
  }

  Widget _buildBackgroundCarousel() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _carouselController,
          builder: (context, child) {
            return Opacity(
              opacity: _carouselOpacity.value,
              child: BackgroundCarousel(
                isInteractive:
                    widget.carouselState == CarouselVisibilityState.full,
                autoScroll:
                    widget.carouselState != CarouselVisibilityState.minimal,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainNavigation() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: false, // La navigation doit être interactive
        child: GlassmorphismOverlay(
          opacity: _calculateNavigationOpacity(),
          child: MainNavigation(
            onNavigationChanged: (route, context) {
              context.read<NavigationState>().navigateTo(route, context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false, // Le contenu principal doit être interactif
        child: AnimatedBuilder(
          animation: _carouselController,
          builder: (context, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _carouselBlur.value,
                sigmaY: _carouselBlur.value,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: EloquenceColors.navy.withOpacity(0.1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: widget.content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateNavigationOpacity() {
    switch (widget.carouselState) {
      case CarouselVisibilityState.full:
        return 0.9;
      case CarouselVisibilityState.medium:
        return 0.7;
      case CarouselVisibilityState.subtle:
        return 0.5;
      case CarouselVisibilityState.minimal:
        return 0.3;
    }
  }
}