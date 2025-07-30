import 'package:flutter/material.dart';
import '../models/orator_model.dart';
import '../utils/constants.dart';
import 'glassmorphism_card.dart';

class QuoteDisplay extends StatefulWidget {
  final Orator orator;
  final bool isVisible;

  const QuoteDisplay({
    Key? key,
    required this.orator,
    this.isVisible = true,
  }) : super(key: key);

  @override
  QuoteDisplayState createState() => QuoteDisplayState();
}

class QuoteDisplayState extends State<QuoteDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(QuoteDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orator.id != widget.orator.id) {
      _controller.forward(from: 0);
    }
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: EloquenceGlassCard(
                borderRadius: 16,
                borderColor: widget.orator.accentColor,
                opacity: 0.15,
                child: Container(
                  padding: const EdgeInsets.all(16), // Réduit de 24 à 16
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône de citation
                      Icon(
                        Icons.format_quote,
                        size: 32,
                        color: widget.orator.accentColor,
                      ),
                      const SizedBox(height: 12), // Réduit de 16 à 12
                      // Citation principale
                      Text(
                        widget.orator.mainQuote,
                        style: EloquenceTextStyles.quote,
                        textAlign: TextAlign.center,
                        maxLines: 3, // Limite le nombre de lignes
                        overflow: TextOverflow.ellipsis, // Coupe si trop long
                      ),
                      const SizedBox(height: 12), // Réduit de 16 à 12
                      // Attribution
                      Container(
                        height: 1,
                        width: 60,
                        color: widget.orator.accentColor.withAlpha((255 * 0.5).round()),
                      ),
                      const SizedBox(height: 8), // Réduit de 12 à 8
                      Text(
                        widget.orator.name,
                        style: EloquenceTextStyles.oratorName.copyWith(
                          color: widget.orator.accentColor,
                        ),
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
