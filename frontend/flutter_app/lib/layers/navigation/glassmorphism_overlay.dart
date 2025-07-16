import 'package:flutter/material.dart';

class GlassmorphismOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;

  const GlassmorphismOverlay({
    Key? key,
    required this.child,
    required this.opacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: opacity,
      child: Container(
        color: Colors.black.withAlpha((255 * 0.1).round()),
        child: child,
      ),
    );
  }
}