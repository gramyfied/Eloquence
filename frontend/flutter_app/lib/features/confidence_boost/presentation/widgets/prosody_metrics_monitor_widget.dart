/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../data/services/prosody_analysis_interface.dart';

class ProsodyMetricsMonitorWidget extends ConsumerWidget {
  final ProsodyAnalysisResult? analysisResult;

  const ProsodyMetricsMonitorWidget({
    Key? key,
    required this.analysisResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (analysisResult == null) {
      return const Center(
        child: Text(
          "En attente de l'analyse de la prosodie...",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyse de la Prosodie en Temps Réel',
            style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMetricCard(
                  context,
                  'Débit de Parole',
                  '${analysisResult!.speechRate.wordsPerMinute.toStringAsFixed(0)} mots/min',
                  _getSpeechRateCategoryText(analysisResult!.speechRate.category),
                  _getCategoryColor(analysisResult!.speechRate.category),
                  Icons.speed,
                ),
                _buildMetricCard(
                  context,
                  'Intonation',
                  _getIntonationPatternText(analysisResult!.intonation.pattern),
                  'Variété: ${(analysisResult!.intonation.pitchRange * 100).toStringAsFixed(1)}%',
                  _getCategoryColor(analysisResult!.intonation.pattern),
                  Icons.multiline_chart,
                ),
                _buildMetricCard(
                  context,
                  'Pauses',
                  '${analysisResult!.pauses.totalPauses} pauses',
                  'Durée moy: ${analysisResult!.pauses.averagePauseDuration.toStringAsFixed(2)}s',
                  _getCategoryColor(analysisResult!.pauses.pauseDistribution),
                  Icons.pause_circle_filled,
                ),
                _buildMetricCard(
                  context,
                  'Énergie Vocale',
                  _getEnergyProfileText(analysisResult!.energy.profile),
                  'Niveau: ${analysisResult!.energy.averageEnergy.toStringAsFixed(2)}',
                  _getCategoryColor(analysis_result.energy.profile),
                  Icons.flash_on,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailedAnalysis(context),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color indicatorColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: indicatorColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: indicatorColor, size: 28),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headline5?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyText2?.copyWith(color: indicatorColor),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(dynamic category) {
    if (category is SpeechRateCategory) {
      switch (category) {
        case SpeechRateCategory.tooSlow:
        case SpeechRateCategory.tooFast:
          return Colors.orangeAccent;
        case SpeechRateCategory.optimal:
          return Colors.greenAccent;
      }
    }
    if (category is IntonationPattern) {
      switch (category) {
        case IntonationPattern.monotone:
          return Colors.redAccent;
        case IntonationPattern.exaggerated:
        case IntonationPattern.irregular:
          return Colors.yellowAccent;
        case IntonationPattern.natural:
          return Colors.greenAccent;
      }
    }
    if (category is PauseDistribution) {
      switch (category) {
        case PauseDistribution.tooManyPauses:
        case PauseDistribution.tooFewPauses:
          return Colors.orangeAccent;
        case PauseDistribution.natural:
          return Colors.greenAccent;
      }
    }
    if (category is EnergyProfile) {
      switch (category) {
        case EnergyProfile.tooLow:
        case EnergyProfile.tooHigh:
          return Colors.redAccent;
        case EnergyProfile.inconsistent:
          return Colors.yellowAccent;
        case EnergyProfile.balanced:
          return Colors.greenAccent;
      }
    }
    return Colors.grey;
  }

  Widget _buildDetailedAnalysis(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails et Suggestions',
            style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildDetailedSpeechRate(analysisResult!.speechRate),
          const Divider(color: Colors.white24),
          _buildDetailedIntonation(analysisResult!.intonation),
          const Divider(color: Colors.white24),
          _buildDetailedPauses(analysisResult!.pauses),
          const Divider(color: Colors.white24),
          _buildDetailedEnergy(analysisResult!.energy),
          const Divider(color: Colors.white24),
          _buildDetailedDisfluencies(analysisResult!.disfluencies),
        ],
      ),
    );
  }

  Widget _buildDetailedSpeechRate(SpeechRateAnalysis speechRate) {
    return ListTile(
      leading: Icon(Icons.speed, color: _getCategoryColor(speechRate.category)),
      title: Text('Débit: ${speechRate.wordsPerMinute.toStringAsFixed(0)} mots/min', style: TextStyle(color: Colors.white)),
      subtitle: Text(speechRate.suggestion, style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildDetailedIntonation(IntonationAnalysis intonation) {
    return ListTile(
      leading: Icon(Icons.multiline_chart, color: _getCategoryColor(intonation.pattern)),
      title: Text('Intonation: ${_getIntonationPatternText(intonation.pattern)}', style: TextStyle(color: Colors.white)),
      subtitle: Text(intonation.suggestion, style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildDetailedPauses(PauseAnalysis pauses) {
    return ListTile(
      leading: Icon(Icons.pause_circle_filled, color: _getCategoryColor(pauses.pauseDistribution)),
      title: Text('Pauses: ${pauses.totalPauses} (${(pauses.totalPauseDuration * 1000).toStringAsFixed(0)}ms)', style: TextStyle(color: Colors.white)),
      subtitle: Text(pauses.suggestion, style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildDetailedEnergy(EnergyAnalysis energy) {
    return ListTile(
      leading: Icon(Icons.flash_on, color: _getCategoryColor(energy.profile)),
      title: Text('Énergie: ${_getEnergyProfileText(energy.profile)}', style: TextStyle(color: Colors.white)),
      subtitle: Text(energy.suggestion, style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildDetailedDisfluencies(DisfluencyAnalysis disfluency) {
    return ListTile(
      leading: Icon(Icons.record_voice_over, color: disfluency.count > 3 ? Colors.orangeAccent : Colors.greenAccent),
      title: Text('Hésitations: ${disfluency.count} (ex: ${disfluency.examples.join(", ")})', style: TextStyle(color: Colors.white)),
      subtitle: Text(disfluency.suggestion, style: TextStyle(color: Colors.white70)),
    );
  }

  String _getSpeechRateCategoryText(SpeechRateCategory category) {
    switch (category) {
      case SpeechRateCategory.tooSlow: return 'Trop lent';
      case SpeechRateCategory.tooFast: return 'Trop rapide';
      case SpeechRateCategory.optimal: return 'Optimal';
    }
  }

  String _getIntonationPatternText(IntonationPattern pattern) {
    switch (pattern) {
      case IntonationPattern.monotone: return 'Monotone';
      case IntonationPattern.exaggerated: return 'Exagéré';
      case IntonationPattern.irregular: return 'Irrégulier';
      case IntonationPattern.natural: return 'Naturel';
    }
  }

  String _getEnergyProfileText(EnergyProfile profile) {
    switch (profile) {
      case EnergyProfile.tooLow: return 'Trop faible';
      case EnergyProfile.tooHigh: return 'Trop élevé';
      case EnergyProfile.inconsistent: return 'Inconsistant';
      case EnergyProfile.balanced: return 'Équilibré';
    }
  }
}
*/