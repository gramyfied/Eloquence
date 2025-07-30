import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EloquenceGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final double opacity;

  const EloquenceGlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 20.0,
    this.borderColor = EloquenceColors.glassBorder,
    this.opacity = 0.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EloquenceColors.navy.withAlpha((255 * opacity).round()),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor.withAlpha((255 * 0.3).round()),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}