import 'package:flutter/material.dart';
import '../../domain/entities/confidence_scenario.dart';
import 'confidence_boost_rest_screen.dart';
import 'confidence_boost_adaptive_screen.dart';
import 'universal_exercise_screen.dart';
import 'confidence_boost_livekit_screen.dart';
import 'virelangue_roulette_screen.dart';
import '../../data/services/universal_audio_exercise_service.dart';
import '../providers/universal_exercise_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🚦 POINT D'ENTRÉE POUR EXERCICE BOOST CONFIDENCE
///
/// Permet de choisir entre :
/// - L'écran REST simplifié (legacy)
/// - L'écran LiveKit moderne (NOUVEAU - recommandé)
/// - L'écran complexe LiveKit (pour tests/développement)
/// - L'API universelle d'exercices (nouvelle fonctionnalité)
class ConfidenceBoostEntry {
  
  /// 🎯 LANCER ÉCRAN REST SIMPLIFIÉ (Legacy)
  static Widget restScreen(ConfidenceScenario scenario) {
    return ConfidenceBoostRestScreen(scenario: scenario);
  }
  
  /// ⚡ NOUVEAU - LANCER ÉCRAN LIVEKIT MODERNE (Recommandé)
  static Widget livekitScreen(ConfidenceScenario scenario) {
    return ConfidenceBoostLiveKitScreen(scenario: scenario);
  }
  
  /// 🔧 LANCER ÉCRAN COMPLEXE (Développement)
  static Widget adaptiveScreen(ConfidenceScenario scenario) {
    return ConfidenceBoostAdaptiveScreen(scenario: scenario);
  }
  
  /// 🌟 API UNIVERSELLE - Lancer exercice universel avec template
  static Widget universalExercise(String templateId) {
    return _UniversalExerciseLauncher(templateId: templateId);
  }
  
  /// 🌟 API UNIVERSELLE - Lancer exercice universel avec configuration custom
  static Widget customExercise(AudioExerciseConfig config) {
    return _UniversalExerciseLauncher.withConfig(config: config);
  }
  
  /// 🎲 ROULETTE DES VIRELANGUES MAGIQUES - Nouvel exercice gamifié
  static Widget virelangueRoulette() {
    return const VirelangueRouletteScreen();
  }
  
  /// 📱 ÉCRAN DE CHOIX MODE (Pour tests)
  static Widget choiceScreen(ConfidenceScenario scenario) {
    return _ConfidenceBoostChoiceScreen(scenario: scenario);
  }
}

/// 🌟 LAUNCHER UNIVERSEL POUR EXERCICES
///
/// Cette classe facilite l'intégration de nouveaux exercices :
/// - Utilise des templates prédéfinis ou configuration custom
/// - Initialise automatiquement le provider
/// - Lance l'écran d'exercice universel
class _UniversalExerciseLauncher extends ConsumerStatefulWidget {
  final String? templateId;
  final AudioExerciseConfig? config;
  
  const _UniversalExerciseLauncher({this.templateId}) : config = null;
  const _UniversalExerciseLauncher.withConfig({required this.config}) : templateId = null;

  @override
  ConsumerState<_UniversalExerciseLauncher> createState() => _UniversalExerciseLauncherState();
}

class _UniversalExerciseLauncherState extends ConsumerState<_UniversalExerciseLauncher> {
  late AudioExerciseConfig _exerciseConfig;

  @override
  void initState() {
    super.initState();
    
    // Obtenir la configuration d'exercice
    _exerciseConfig = widget.config ?? _getTemplateById(widget.templateId ?? 'job_interview');
  }

  /// Obtient un template par son ID
  AudioExerciseConfig _getTemplateById(String templateId) {
    switch (templateId) {
      case 'job_interview':
        return AudioExerciseTemplates.jobInterview;
      case 'public_speaking':
        return AudioExerciseTemplates.publicSpeaking;
      case 'casual_conversation':
        return AudioExerciseTemplates.casualConversation;
      case 'debate':
        return AudioExerciseTemplates.debate;
      default:
        return AudioExerciseTemplates.jobInterview; // Par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return UniversalExerciseScreen(exerciseConfig: _exerciseConfig);
  }
}

class _ConfidenceBoostChoiceScreen extends StatelessWidget {
  final ConfidenceScenario scenario;

  const _ConfidenceBoostChoiceScreen({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text(
          'Choisir le mode',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Description scénario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1A1F2E),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scenario.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Mode REST (Recommandé)
            _buildModeCard(
              context: context,
              title: '🚀 Mode REST Simplifié',
              description: 'Approche HTTP simple avec flutter_sound\nOptimisé mobile (300 lignes)',
              isRecommended: true,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfidenceBoostRestScreen(scenario: scenario),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mode Complexe
            _buildModeCard(
              context: context,
              title: '🔧 Mode LiveKit Complexe',
              description: 'Architecture WebRTC complète\nDéveloppement (2318 lignes)',
              isRecommended: false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfidenceBoostAdaptiveScreen(scenario: scenario),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mode API Universelle
            _buildModeCard(
              context: context,
              title: '🌟 API Universelle',
              description: 'Système d\'exercices modulaire\nFacile à étendre et intégrer',
              isRecommended: false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfidenceBoostEntry.universalExercise('job_interview'),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mode Roulette des Virelangues
            _buildModeCard(
              context: context,
              title: '🎲 Roulette des Virelangues Magiques',
              description: 'Exercice gamifié avec collection de gemmes\nSystème de récompenses variables',
              isRecommended: true,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfidenceBoostEntry.virelangueRoulette(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A1F2E),
          border: Border.all(
            color: isRecommended ? const Color(0xFF00D4FF) : const Color(0xFF2A3441),
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isRecommended ? const Color(0xFF00D4FF) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF00D4FF).withOpacity(0.2),
                    ),
                    child: const Text(
                      'RECOMMANDÉ',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}