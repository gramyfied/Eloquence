import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:eloquence_2_0/presentation/theme/eloquence_design_system.dart';
import 'package:eloquence_2_0/presentation/widgets/eloquence_components.dart';

class NewExerciseScreen extends StatefulWidget {
  final String exerciseTitle;
  final String exerciseType;
  
  const NewExerciseScreen({
    Key? key,
    required this.exerciseTitle,
    required this.exerciseType,
  }) : super(key: key);
  
  @override
  _NewExerciseScreenState createState() => _NewExerciseScreenState();
}

class _NewExerciseScreenState extends State<NewExerciseScreen> {
  bool _isRecording = false;
  bool _isAnalyzing = false;
  
  @override
  Widget build(BuildContext context) {
    return EloquenceScaffold(
      body: Padding(
        padding: const EdgeInsets.only(bottom: EloquenceSpacing.xxl),
        child: Column(
          children: [
            // HEADER OBLIGATOIRE - Zone difficile (acceptable)
            _buildHeader(),
            
            // CONTENU PRINCIPAL - Zone étirement/facile
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(EloquenceSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titre exercice
                    _buildExerciseTitle(),
                    
                    const Spacer(flex: 2),
                    
                    // Waveforms (si enregistrement)
                    if (_isRecording) _buildWaveforms(),
                    
                    const Spacer(),

                    // MICROPHONE CENTRAL - Zone facile (OBLIGATOIRE)
                    _buildMicrophone(),
                    
                    const Spacer(),

                    // Timer/Status
                    _buildStatus(),
                    
                    const Spacer(flex: 2),
                    
                    // Métriques (si disponibles)
                    if (!_isRecording && !_isAnalyzing) _buildMetrics(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavItems: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Exercices'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Progrès'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      currentIndex: 1,
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(EloquenceSpacing.md),
      child: EloquenceGlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: EloquenceSpacing.lg,
          vertical: EloquenceSpacing.md,
        ),
        child: Row(
          children: [
            const Text('Niveau 3', style: EloquenceTextStyles.headline2),
            const Spacer(),
            Container(
              width: 100,
              height: 6,
              decoration: BoxDecoration(
                gradient: EloquenceColors.cyanVioletGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: EloquenceSpacing.sm),
            const Text('75%', style: EloquenceTextStyles.body1),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExerciseTitle() {
    return EloquenceGlassCard(
      child: Center(
        child: Text(
          widget.exerciseTitle,
          style: EloquenceTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  Widget _buildWaveforms() {
    return EloquenceWaveforms(isActive: _isRecording);
  }
  
  Widget _buildMicrophone() {
    return EloquenceMicrophone(
      isRecording: _isRecording,
      onTap: _toggleRecording,
      size: 120,
    );
  }
  
  Widget _buildStatus() {
    return EloquenceGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: EloquenceSpacing.lg,
        vertical: EloquenceSpacing.sm,
      ),
      child: Text(
        _isRecording ? '02:45' : _isAnalyzing ? 'Analyse...' : 'Prêt',
        style: EloquenceTextStyles.headline1,
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: EloquenceSpacing.md,
      crossAxisSpacing: EloquenceSpacing.md,
      children: [
        _buildMetricCard('Clarté', 0.9, '90%'),
        _buildMetricCard('Rythme', 0.8, '80%'),
        _buildMetricCard('Volume', 0.85, '85%'),
        _buildMetricCard('Fluidité', 0.85, '85%'),
      ],
    );
  }
  
  Widget _buildMetricCard(String label, double value, String percentage) {
    return EloquenceGlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: EloquenceTextStyles.body1),
          const SizedBox(height: EloquenceSpacing.sm),
          EloquenceProgressBar(
            label: '',
            value: value,
            percentage: percentage,
          ),
        ],
      ),
    );
  }
  
  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }
}