import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/navigation/navigation_state.dart';
import '../layers/background/background_carousel.dart';
import '../layers/navigation/glassmorphism_overlay.dart';
import '../layers/navigation/main_navigation.dart';

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
      body: AnimatedBuilder(
        animation: _carouselController,
        builder: (context, child) {
          return Stack(
            children: [
              // Layer 1: Carrousel d'arrière-plan (sans flou direct)
              _buildBackgroundCarousel(),

              // Layer 2: Filtre de flou appliqué sur le carrousel
              Positioned.fill(
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _carouselBlur.value,
                      sigmaY: _carouselBlur.value,
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0.0),
                    ),
                  ),
                ),
              ),

              // Layer 3: Contenu principal
              _buildMainContent(),

              // Layer 4: Navigation principale (si activée)
              if (widget.showNavigation) _buildMainNavigation(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundCarousel() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onCarouselTap,
        child: AnimatedOpacity(
          opacity: _carouselOpacity.value,
          duration: const Duration(milliseconds: 800),
          child: BackgroundCarousel(
            isInteractive:
                widget.carouselState == CarouselVisibilityState.full,
            autoScroll:
                widget.carouselState != CarouselVisibilityState.minimal,
          ),
        ),
      ),
    );
  }

  Widget _buildMainNavigation() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GlassmorphismOverlay(
        opacity: _calculateNavigationOpacity(),
        child: MainNavigation(
          onNavigationChanged: (route) {
            context.read<NavigationState>().navigateTo(route);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Positioned.fill(
      child: widget.content,
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