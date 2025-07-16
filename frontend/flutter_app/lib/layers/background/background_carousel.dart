import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orator_model.dart';
import '../../services/orator_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/quote_display.dart';
import '../../core/navigation/navigation_state.dart';

class BackgroundCarousel extends ConsumerStatefulWidget {
  final bool isInteractive;
  final bool autoScroll;

  const BackgroundCarousel({
    Key? key,
    required this.isInteractive,
    required this.autoScroll,
  }) : super(key: key);

  @override
  ConsumerState<BackgroundCarousel> createState() => _BackgroundCarouselState();
}

class _BackgroundCarouselState extends ConsumerState<BackgroundCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );

    if (widget.autoScroll) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !widget.autoScroll) {
        timer.cancel();
        return;
      }

      if (_currentIndex < orators.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(BackgroundCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.autoScroll != widget.autoScroll) {
      if (widget.autoScroll) {
        _startAutoScroll();
      } else {
        _autoScrollTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            EloquenceColors.navy,
            EloquenceColors.navy.withBlue(40),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 100), // Espace pour la navigation
          // Carrousel principal
          Expanded(
            flex: 3,
            child: IgnorePointer(
              ignoring: !widget.isInteractive,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: widget.isInteractive
                    ? (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        _notifyOratorChanged(orators[index]);
                      }
                    : null,
                physics: widget.isInteractive
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: orators.length,
                itemBuilder: (context, index) {
                  return _buildOratorCard(orators[index], index == _currentIndex);
                },
              ),
            ),
          ),

          // Citation de l'orateur actuel
          if (widget.isInteractive)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: QuoteDisplay(
                  orator: orators[_currentIndex],
                  isVisible: widget.isInteractive,
                ),
              ),
            ),

          const SizedBox(height: 100), // Espace pour la navigation bottom
        ],
      ),
    );
  }

  Widget _buildOratorCard(Orator orator, bool isActive) {
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Portrait avec halo
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: orator.accentColor.withAlpha((255 * 0.4).round()),
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
                      cacheWidth: 400,
                      cacheHeight: 400,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white, size: 100),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Nom de l'orateur
                Text(
                  orator.name,
                  style: EloquenceTextStyles.oratorName.copyWith(
                    color: isActive ? orator.accentColor : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Métadonnées
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
  }

  void _notifyOratorChanged(Orator orator) {
    // Notifier le changement d'orateur au niveau global
    ref.read(navigationStateProvider.notifier).updateCurrentOrator(orator);
  }
}