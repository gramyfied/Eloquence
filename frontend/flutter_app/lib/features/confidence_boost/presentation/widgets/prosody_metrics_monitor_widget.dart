import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/services/prosody_analysis_interface.dart';
import '../../domain/entities/confidence_models.dart';

/// Widget de monitoring avancé des métriques prosodiques
/// 
/// Affiche en temps réel :
/// - Débit de parole avec indicateurs visuels
/// - Analyse d'intonation avec graphique F0
/// - Détection et analyse des pauses
/// - Niveau d'énergie vocale
/// - Analyse des disfluences
class ProsodyMetricsMonitorWidget extends ConsumerStatefulWidget {
  final ProsodyAnalysisResult? analysisResult;
  final bool showRealtimeMetrics;
  final VoidCallback? onRefreshRequested;

  const ProsodyMetricsMonitorWidget({
    Key? key,
    this.analysisResult,
    this.showRealtimeMetrics = false,
    this.onRefreshRequested,
  }) : super(key: key);

  @override
  ConsumerState<ProsodyMetricsMonitorWidget> createState() => _ProsodyMetricsMonitorWidgetState();
}

class _ProsodyMetricsMonitorWidgetState extends ConsumerState<ProsodyMetricsMonitorWidget>
    with TickerProviderStateMixin {
  final Logger logger = Logger();
  
  // Contrôleurs d'animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  
  // État des métriques
  bool _isExpanded = true;
  bool _showDetailedView = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.showRealtimeMetrics) {
      _startRealtimeRefresh();
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );
    
    // Démarrer les animations
    _fadeController.forward();
    _slideController.forward();
    if (widget.analysisResult != null) {
      _progressController.forward();
    }
  }

  void _startRealtimeRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    });
  }

  @override
  void didUpdateWidget(ProsodyMetricsMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.analysisResult != null && oldWidget.analysisResult == null) {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  if (_isExpanded) ...[
                    _buildMetricsOverview(),
                    const Divider(),
                    if (_showDetailedView) ...[
                      _buildDetailedMetrics(),
                    ] else ...[
                      _buildSummaryMetrics(),
                    ],
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoring Prosodique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.analysisResult != null
                      ? 'Analyse complétée • ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'
                      : 'En attente d\'analyse',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview() {
    if (widget.analysisResult == null) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Analyse en cours...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final result = widget.analysisResult!;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildOverallScoreIndicator(result.overallProsodyScore),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildQuickMetric('Débit', '${result.speechRate.wordsPerMinute.toStringAsFixed(0)} mots/min', result.speechRate.fluencyScore)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickMetric('Clarté', '${(result.intonation.clarityScore * 100).toStringAsFixed(0)}%', result.intonation.clarityScore)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildQuickMetric('Énergie', '${(result.energy.normalizedEnergyScore * 100).toStringAsFixed(0)}%', result.energy.normalizedEnergyScore)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickMetric('Pauses', '${result.pauses.totalPauses}', result.pauses.rhythmScore)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreIndicator(double score) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            const Text(
              'Score Prosodique Global',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progressAnimation.value * (score / 100),
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(score),
                    ),
                  ),
                  Text(
                    '${(score * _progressAnimation.value).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickMetric(String title, String value, double score) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getScoreColor(score * 100).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getScoreColor(score * 100).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _getScoreColor(score * 100),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score * 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    if (widget.analysisResult == null) return const SizedBox.shrink();
    
    final result = widget.analysisResult!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de l\'Analyse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryItem('🎯 Débit de parole', result.speechRate.feedback),
          _buildSummaryItem('🎵 Intonation', result.intonation.feedback),
          _buildSummaryItem('⏸️ Pauses', result.pauses.feedback),
          _buildSummaryItem('🔊 Énergie vocale', result.energy.feedback),
          if (result.disfluency.events.isNotEmpty)
            _buildSummaryItem('💫 Disfluences', result.disfluency.feedback),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    if (widget.analysisResult == null) return const SizedBox.shrink();
    
    final result = widget.analysisResult!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildDetailedSpeechRate(result.speechRate),
          const SizedBox(height: 16),
          _buildDetailedIntonation(result.intonation),
          const SizedBox(height: 16),
          _buildDetailedPauses(result.pauses),
          const SizedBox(height: 16),
          _buildDetailedEnergy(result.energy),
          if (result.disfluency.events.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailedDisfluencies(result.disfluency),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedSpeechRate(SpeechRateAnalysis speechRate) {
    return _buildDetailedSection(
      title: '🎯 Analyse du Débit',
      children: [
        _buildDetailRow('Mots par minute', '${speechRate.wordsPerMinute.toStringAsFixed(1)} WPM'),
        _buildDetailRow('Syllabes par seconde', '${speechRate.syllablesPerSecond.toStringAsFixed(2)} syll/s'),
        _buildDetailRow('Score de fluidité', '${(speechRate.fluencyScore * 100).toStringAsFixed(0)}%'),
        _buildDetailRow('Catégorie', _getSpeechRateCategoryText(speechRate.category)),
      ],
    );
  }

  Widget _buildDetailedIntonation(IntonationAnalysis intonation) {
    return _buildDetailedSection(
      title: '🎵 Analyse d\'Intonation',
      children: [
        _buildDetailRow('F0 Moyenne', '${intonation.f0Mean.toStringAsFixed(1)} Hz'),
        _buildDetailRow('Variation F0', '${intonation.f0Range.toStringAsFixed(1)} Hz'),
        _buildDetailRow('Score de clarté', '${(intonation.clarityScore * 100).toStringAsFixed(0)}%'),
        _buildDetailRow('Motif', _getIntonationPatternText(intonation.pattern)),
      ],
    );
  }

  Widget _buildDetailedPauses(PauseAnalysis pauses) {
    return _buildDetailedSection(
      title: '⏸️ Analyse des Pauses',
      children: [
        _buildDetailRow('Nombre total', '${pauses.totalPauses} pauses'),
        _buildDetailRow('Durée moyenne', '${pauses.averagePauseDuration.toStringAsFixed(2)}s'),
        _buildDetailRow('Taux de pause', '${(pauses.pauseRate * 100).toStringAsFixed(1)}%'),
        _buildDetailRow('Score de rythme', '${(pauses.rhythmScore * 100).toStringAsFixed(0)}%'),
      ],
    );
  }

  Widget _buildDetailedEnergy(EnergyAnalysis energy) {
    return _buildDetailedSection(
      title: '🔊 Analyse d\'Énergie',
      children: [
        _buildDetailRow('Énergie moyenne', '${energy.averageEnergy.toStringAsFixed(2)} dB'),
        _buildDetailRow('Variance', '${energy.energyVariance.toStringAsFixed(2)}'),
        _buildDetailRow('Score normalisé', '${(energy.normalizedEnergyScore * 100).toStringAsFixed(0)}%'),
        _buildDetailRow('Profil', _getEnergyProfileText(energy.profile)),
      ],
    );
  }

  Widget _buildDetailedDisfluencies(DisfluencyAnalysis disfluency) {
    return _buildDetailedSection(
      title: '💫 Analyse des Disfluences',
      children: [
        _buildDetailRow('Hésitations', '${disfluency.hesitationCount}'),
        _buildDetailRow('Mots de remplissage', '${disfluency.fillerWordsCount}'),
        _buildDetailRow('Répétitions', '${disfluency.repetitionCount}'),
        _buildDetailRow('Score de sévérité', '${(disfluency.severityScore * 100).toStringAsFixed(0)}%'),
      ],
    );
  }

  Widget _buildDetailedSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showDetailedView = !_showDetailedView;
              });
            },
            icon: Icon(_showDetailedView ? Icons.visibility_off : Icons.visibility),
            label: Text(_showDetailedView ? 'Vue simple' : 'Vue détaillée'),
          ),
          if (widget.onRefreshRequested != null)
            TextButton.icon(
              onPressed: widget.onRefreshRequested,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
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