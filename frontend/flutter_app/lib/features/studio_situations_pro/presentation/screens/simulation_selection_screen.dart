import 'package:flutter/material.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/models/simulation_configs.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/presentation/widgets/simulation_card.dart';
import 'package:eloquence_2_0/core/theme/eloquence_unified_theme.dart';
import 'dart:ui';

class SimulationSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceTheme.navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: EloquenceTheme.spacingLg,
        horizontal: EloquenceTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        gradient: EloquenceTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: EloquenceTheme.shadowLarge,
      ),
      child: Text(
        'Studio Situations Pro',
        style: EloquenceTheme.headline1.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0, 
          crossAxisSpacing: EloquenceTheme.spacingMd,
          mainAxisSpacing: EloquenceTheme.spacingMd,
        ),
        itemCount: SimulationConfigs.all.length,
        itemBuilder: (context, index) {
          final config = SimulationConfigs.all[index];
          return SimulationCard(config: config);
        },
      ),
    );
  }
}