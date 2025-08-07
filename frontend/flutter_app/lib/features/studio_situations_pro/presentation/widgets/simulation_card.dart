import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/models/simulation_models.dart';
import 'package:eloquence_2_0/core/theme/eloquence_unified_theme.dart';
import 'dart:ui'; // Import pour ImageFilter

class SimulationCard extends StatelessWidget {
  final SimulationConfig config;
  
  const SimulationCard({Key? key, required this.config}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToPreparation(context),
      child: ClipRRect(
        borderRadius: EloquenceTheme.borderRadiusLarge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: EloquenceTheme.glassBackground,
              borderRadius: EloquenceTheme.borderRadiusLarge,
              border: Border.all(
                color: EloquenceTheme.glassBorder,
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  config.accentColor.withOpacity(0.1),
                  EloquenceTheme.glassBackground.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  config.icon,
                  size: 48,
                  color: config.accentColor,
                ),
                const SizedBox(height: EloquenceTheme.spacingMd),
                Text(
                  config.title,
                  style: EloquenceTheme.headline3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _navigateToPreparation(BuildContext context) {
    context.push('/preparation/${config.type.toRouteString()}');
  }
}