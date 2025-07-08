import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../../../presentation/widgets/eloquence_components.dart';

class ConfidenceTipsCarousel extends StatefulWidget {
  final List<String> tips;
  
  const ConfidenceTipsCarousel({
    Key? key,
    required this.tips,
  }) : super(key: key);
  
  @override
  State<ConfidenceTipsCarousel> createState() => _ConfidenceTipsCarouselState();
}

class _ConfidenceTipsCarouselState extends State<ConfidenceTipsCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }
  
  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < widget.tips.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Titre
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: EloquenceColors.cyan,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Conseils',
              style: EloquenceTextStyles.headline2.copyWith(
                fontSize: 18,
                color: EloquenceColors.cyan,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Carousel
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.tips.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: EloquenceGlassCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getTipIcon(index),
                            size: 48,
                            color: EloquenceColors.violet.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.tips[index],
                            style: EloquenceTextStyles.body1.copyWith(
                              fontSize: 16,
                              height: 1.5,
                            ),
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
        ),
        
        const SizedBox(height: 16),
        
        // Indicateurs de page
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.tips.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? EloquenceColors.cyan
                    : EloquenceColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getTipIcon(int index) {
    final icons = [
      Icons.record_voice_over,
      Icons.psychology,
      Icons.favorite,
      Icons.star,
      Icons.trending_up,
    ];
    return icons[index % icons.length];
  }
}