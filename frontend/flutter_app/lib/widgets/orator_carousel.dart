import 'dart:async';
import 'package:flutter/material.dart';
import '../models/orator_model.dart';
import '../utils/constants.dart';
import 'glassmorphism_card.dart';

class OratorCarousel extends StatefulWidget {
  final List<Orator> orators;
  final Function(Orator) onOratorChanged;

  const OratorCarousel({
    Key? key,
    required this.orators,
    required this.onOratorChanged,
  }) : super(key: key);

  @override
  _OratorCarouselState createState() => _OratorCarouselState();
}

class _OratorCarouselState extends State<OratorCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentIndex < widget.orators.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280, // Réduit drastiquement de 320 à 280
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          widget.onOratorChanged(widget.orators[index]);
          _animationController.forward(from: 0);
        },
        itemCount: widget.orators.length,
        itemBuilder: (context, index) {
          final orator = widget.orators[index];
          final isActive = index == _currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.scale(
              scale: isActive ? 1.0 : 0.85,
              child: EloquenceGlassCard(
                borderRadius: 20,
                borderColor: isActive ? orator.accentColor : EloquenceColors.cyan,
                opacity: isActive ? 0.2 : 0.1,
                child: Container(
                  padding: const EdgeInsets.all(8), // Réduit encore de 12 à 8
                  child: Column(
                    children: [
                      // Portrait avec effet de halo
                      Container(
                        width: 120, // Réduit encore de 140 à 120
                        height: 120, // Réduit encore de 140 à 120
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: orator.accentColor.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            orator.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey,
                                child: const Icon(Icons.person, color: Colors.white, size: 100),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8), // Réduit encore de 12 à 8
                      // Nom de l'orateur
                      Text(
                        orator.name,
                        style: EloquenceTextStyles.oratorName.copyWith(
                          color: isActive ? orator.accentColor : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2, // Permet 2 lignes maximum
                        overflow: TextOverflow.ellipsis, // Coupe avec ... si trop long
                      ),
                      const SizedBox(height: 4), // Réduit encore de 6 à 4
                      // Domaine et période
                      Text(
                        '${orator.domain} • ${orator.period}',
                        style: EloquenceTextStyles.metadata,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}