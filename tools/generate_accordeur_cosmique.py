#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🌌 GÉNÉRATEUR - L'ACCORDEUR VOCAL COSMIQUE
============================================

Exercice de contrôle de la hauteur vocale gamifié
où l'utilisateur guide un vaisseau spatial avec sa voix.

Concept: Flow state + Accomplissement
Mécanisme: Voix grave = descente, voix aiguë = montée
"""

import json
import sys
import os
import io
from datetime import datetime

# Forcer l'encodage UTF-8 pour Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from eloquence_generator_ultimate import EloquenceGeneratorUltimate

# Configuration spécifique pour l'Accordeur Vocal Cosmique
COSMIC_VOICE_CONFIG = {
    'description': """
    🌌 L'Accordeur Vocal Cosmique - Exercice de contrôle vocal gamifié
    
    Guidez votre vaisseau spatial à travers un champ d'astéroïdes en utilisant 
    uniquement votre voix ! Voix grave pour descendre, voix aiguë pour monter.
    Collectez des cristaux d'énergie et évitez les obstacles dans cette aventure
    spatiale immersive.
    
    Caractéristiques:
    • Contrôle vocal direct pour un flow state immersif
    • Niveaux progressifs avec nouveaux systèmes solaires
    • Personnalisation du vaisseau avec les cristaux collectés
    • Classements communautaires et défis quotidiens
    • Mode coopératif parent-enfant pour missions à deux voix
    
    Bénéfice thérapeutique: Développement naturel de la tessiture vocale
    """,
    
    'custom_config': {
        'game_mechanics': {
            'pitch_control': {
                'low_pitch_hz': 80,    # Hz pour descente
                'high_pitch_hz': 300,   # Hz pour montée
                'neutral_zone': [150, 200],  # Zone neutre
                'sensitivity': 0.8
            },
            'crystal_types': [
                {'name': 'Cristal d\'Énergie', 'xp': 10, 'color': '#00FFFF'},
                {'name': 'Cristal de Puissance', 'xp': 25, 'color': '#FF00FF'},
                {'name': 'Cristal Légendaire', 'xp': 100, 'color': '#FFD700'},
                {'name': 'Cristal Harmonique', 'xp': 50, 'color': '#7FFF00'}
            ],
            'obstacles': [
                {'name': 'Astéroïde', 'damage': 10},
                {'name': 'Champ de météorites', 'damage': 20},
                {'name': 'Trou noir', 'damage': 50}
            ],
            'spaceship_upgrades': [
                {'name': 'Bouclier Renforcé', 'cost': 100, 'effect': 'damage_reduction'},
                {'name': 'Collecteur Magnétique', 'cost': 200, 'effect': 'crystal_attraction'},
                {'name': 'Turbo Vocal', 'cost': 300, 'effect': 'response_boost'},
                {'name': 'Scanner Harmonique', 'cost': 500, 'effect': 'crystal_detection'}
            ]
        },
        
        'progression_system': {
            'solar_systems': [
                {'name': 'Système Alpha', 'level': 1, 'crystals_required': 0},
                {'name': 'Nébuleuse Orion', 'level': 5, 'crystals_required': 500},
                {'name': 'Galaxie Andromède', 'level': 10, 'crystals_required': 1500},
                {'name': 'Trou de Ver Quantique', 'level': 15, 'crystals_required': 3000},
                {'name': 'Dimension Parallèle', 'level': 20, 'crystals_required': 5000}
            ],
            'achievements': [
                {'id': 'first_flight', 'name': 'Premier Vol', 'xp': 50},
                {'id': 'crystal_collector', 'name': 'Collectionneur de Cristaux', 'xp': 100},
                {'id': 'asteroid_dodger', 'name': 'Éviteur d\'Astéroïdes', 'xp': 150},
                {'id': 'pitch_master', 'name': 'Maître de la Tessiture', 'xp': 200},
                {'id': 'cosmic_explorer', 'name': 'Explorateur Cosmique', 'xp': 500},
                {'id': 'harmonizer', 'name': 'Harmoniseur Galactique', 'xp': 1000}
            ]
        },
        
        'multiplayer': {
            'coop_mode': {
                'enabled': True,
                'roles': [
                    {'name': 'Pilote', 'control': 'vertical_movement'},
                    {'name': 'Navigateur', 'control': 'horizontal_movement'}
                ],
                'sync_bonus': 2.0,  # Multiplicateur XP quand synchronisés
                'harmony_threshold': 0.8  # Seuil de synchronisation
            },
            'leaderboards': [
                {'type': 'daily', 'name': 'Défi Quotidien'},
                {'type': 'weekly', 'name': 'Champion de la Semaine'},
                {'type': 'all_time', 'name': 'Légendes Cosmiques'},
                {'type': 'family', 'name': 'Familles Stellaires'}
            ]
        }
    }
}

def generate_cosmic_voice_exercise():
    """Génère l'exercice Accordeur Vocal Cosmique complet"""
    
    print("[COSMOS] Génération de l'Accordeur Vocal Cosmique...")
    print("=" * 60)
    
    try:
        # Initialiser le générateur
        generator = EloquenceGeneratorUltimate()
        
        # Générer l'exercice de base
        base_exercise = generator.generate_ultimate_exercise(
            "Exercice d'accordeur vocal cosmique pour harmoniser ma voix avec les fréquences de l'univers"
        )
        
        # Enrichir avec notre configuration spécifique
        enhanced_exercise = enhance_with_cosmic_features(base_exercise)
        
        # Générer le code Flutter spécialisé
        flutter_code = generate_cosmic_flutter_code(enhanced_exercise)
        enhanced_exercise['flutter_implementation'] = flutter_code
        
        # Sauvegarder les fichiers
        save_exercise_files(enhanced_exercise)
        
        print("\n[OK] Exercice Accordeur Vocal Cosmique généré avec succès !")
        print_exercise_summary(enhanced_exercise)
        
        return enhanced_exercise
        
    except Exception as e:
        print(f"[ERREUR] Erreur lors de la génération: {e}")
        return None

def enhance_with_cosmic_features(exercise):
    """Enrichit l'exercice avec les fonctionnalités cosmiques spécifiques"""
    
    # Mise à jour des informations de base
    exercise['name'] = "L'Accordeur Vocal Cosmique 🌌"
    exercise['description'] = COSMIC_VOICE_CONFIG['description']
    
    # Ajout de la configuration de jeu
    exercise['game_config'] = COSMIC_VOICE_CONFIG['custom_config']['game_mechanics']
    exercise['progression_config'] = COSMIC_VOICE_CONFIG['custom_config']['progression_system']
    exercise['multiplayer_config'] = COSMIC_VOICE_CONFIG['custom_config']['multiplayer']
    
    # Configuration de gamification avancée
    exercise['gamification_config'].update({
        'xp_base': 100,
        'xp_multiplier': 1.5,
        'flow_state_bonus': 2.0,
        'badges': [
            'pilote_novice', 'collecteur_cristaux', 'maitre_tessiture',
            'explorateur_galactique', 'harmoniseur_cosmique', 'duo_stellaire'
        ],
        'achievements': COSMIC_VOICE_CONFIG['custom_config']['progression_system']['achievements'],
        'crystal_economy': True,
        'spaceship_customization': True
    })
    
    # Configuration LiveKit spécialisée
    exercise['livekit_config'].update({
        'room_type': 'cosmic_voice_control',
        'ai_agent': 'cosmic_navigator_agent',
        'metrics': ['pitch', 'pitch_stability', 'vocal_range', 'response_time'],
        'audio_processing': {
            'pitch_detection': 'enhanced',
            'latency_mode': 'ultra_low',
            'frequency_analysis': True
        }
    })
    
    # Personnage IA spécialisé
    exercise['ai_character'] = 'Commandant Stellaris'
    exercise['voice_profile'] = {
        'voice': 'nova',  # Voix futuriste
        'speed': 1.0,
        'personality': 'cosmic_guide',
        'emotions': ['encourageant', 'mystérieux', 'aventurier', 'triomphant']
    }
    
    return exercise

def generate_cosmic_flutter_code(exercise):
    """Génère le code Flutter spécialisé pour l'Accordeur Vocal Cosmique"""
    
    return f'''
// 🌌 L'ACCORDEUR VOCAL COSMIQUE - INTERFACE FLUTTER
// Contrôle vocal gamifié d'un vaisseau spatial
// Flow state + Accomplissement + Personnalisation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../../core/services/universal_livekit_audio_service.dart';
import '../../features/confidence_boost/data/services/gamification_service.dart';
import '../../features/confidence_boost/domain/entities/gamification_models.dart';

class CosmicVoiceScreen extends StatefulWidget {{
  const CosmicVoiceScreen({{Key? key}}) : super(key: key);
  
  @override
  _CosmicVoiceScreenState createState() => _CosmicVoiceScreenState();
}}

class _CosmicVoiceScreenState extends State<CosmicVoiceScreen>
    with TickerProviderStateMixin {{
  
  // 🎮 Game Engine
  late final SpaceshipGame _game;
  late final GameWidget _gameWidget;
  
  // 🔧 Services
  late final UniversalLiveKitAudioService _audioService;
  late final GamificationService _gamificationService;
  
  // 🚀 État du vaisseau
  double _spaceshipY = 0.5; // Position verticale (0.0 = haut, 1.0 = bas)
  double _currentPitch = 150.0; // Fréquence actuelle en Hz
  double _targetPitch = 150.0;
  
  // 💎 Cristaux et progression
  int _crystalsCollected = 0;
  int _totalCrystals = 0;
  int _currentLevel = 1;
  String _currentSystem = 'Système Alpha';
  
  // 🎯 Métriques de performance
  double _pitchStability = 0.0;
  double _vocalRange = 0.0;
  int _obstaclesAvoided = 0;
  int _perfectCollects = 0;
  
  // 🎨 Animations
  late AnimationController _spaceshipAnimController;
  late AnimationController _crystalAnimController;
  late AnimationController _flowStateController;
  late Animation<double> _flowAnimation;
  late ConfettiController _confettiController;
  
  // 🌟 État du flow
  bool _inFlowState = false;
  double _flowMeter = 0.0;
  DateTime? _flowStartTime;
  
  // 👨‍👩‍👧 Mode coopératif
  bool _isCoopMode = false;
  String? _partnerName;
  double _harmonyLevel = 0.0;
  
  // 🏆 Classements
  List<LeaderboardEntry> _dailyLeaderboard = [];
  int? _userRank;
  
  @override
  void initState() {{
    super.initState();
    _initializeGame();
    _initializeServices();
    _initializeAnimations();
    _startCosmicAdventure();
  }}
  
  void _initializeGame() {{
    _game = SpaceshipGame(
      onCrystalCollected: _onCrystalCollected,
      onObstacleHit: _onObstacleHit,
      onLevelComplete: _onLevelComplete,
    );
    
    _gameWidget = GameWidget(game: _game);
  }}
  
  void _initializeServices() {{
    _audioService = UniversalLiveKitAudioService();
    _gamificationService = context.read<GamificationService>();
    
    // Configuration du traitement audio pour détection de pitch
    _audioService.onPitchDetected = _handlePitchDetection;
    _audioService.onMetricsReceived = _handleAudioMetrics;
  }}
  
  void _initializeAnimations() {{
    _spaceshipAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _crystalAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _flowStateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _flowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flowStateController,
      curve: Curves.easeInOut,
    ));
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
  }}
  
  Future<void> _startCosmicAdventure() async {{
    // Connexion au service audio
    await _audioService.connectToExercise(
      exerciseType: 'cosmic_voice_control',
      userId: 'cosmic_pilot_${{DateTime.now().millisecondsSinceEpoch}}',
      exerciseConfig: {{
        'pitch_detection': true,
        'frequency_analysis': true,
        'latency_mode': 'ultra_low',
      }},
    );
    
    // Message d'introduction du Commandant
    _playCommanderVoice(
      "Bienvenue à bord, pilote ! Je suis le Commandant Stellaris. "
      "Utilisez votre voix pour contrôler le vaisseau. "
      "Voix grave pour descendre, voix aiguë pour monter. "
      "Collectons ces cristaux cosmiques !",
      emotion: 'welcoming',
    );
    
    // Démarrer le jeu
    _game.start();
  }}
  
  void _handlePitchDetection(double pitchHz) {{
    setState(() {{
      _currentPitch = pitchHz;
      
      // Calcul de la position du vaisseau basée sur le pitch
      // Pitch bas (80Hz) = position 1.0 (bas)
      // Pitch haut (300Hz) = position 0.0 (haut)
      double normalizedPitch = (pitchHz - 80) / (300 - 80);
      normalizedPitch = normalizedPitch.clamp(0.0, 1.0);
      
      _targetPitch = 1.0 - normalizedPitch; // Inverser pour que aigu = haut
      
      // Smooth movement avec interpolation
      _spaceshipY += (_targetPitch - _spaceshipY) * 0.1;
      
      // Mise à jour de la position dans le jeu
      _game.updateSpaceshipPosition(_spaceshipY);
      
      // Vérification du flow state
      _updateFlowState();
    }});
  }}
  
  void _updateFlowState() {{
    // Le flow state est atteint quand :
    // - La stabilité du pitch est bonne
    // - Les cristaux sont collectés régulièrement
    // - Les obstacles sont évités
    
    if (_pitchStability > 0.7 && _crystalsCollected > 5) {{
      if (!_inFlowState) {{
        _enterFlowState();
      }}
      _flowMeter = math.min(_flowMeter + 0.01, 1.0);
    }} else {{
      _flowMeter = math.max(_flowMeter - 0.005, 0.0);
      if (_flowMeter == 0 && _inFlowState) {{
        _exitFlowState();
      }}
    }}
  }}
  
  void _enterFlowState() {{
    setState(() {{
      _inFlowState = true;
      _flowStartTime = DateTime.now();
    }});
    
    _flowStateController.forward();
    HapticFeedback.lightImpact();
    
    _playCommanderVoice(
      "Excellent ! Vous êtes en parfaite harmonie avec le cosmos !",
      emotion: 'triumphant',
    );
  }}
  
  void _exitFlowState() {{
    setState(() {{
      _inFlowState = false;
      
      // Calculer bonus XP pour le temps en flow
      if (_flowStartTime != null) {{
        int flowDuration = DateTime.now().difference(_flowStartTime!).inSeconds;
        int bonusXP = flowDuration * 5;
        _addXP(bonusXP, reason: 'Flow State Bonus');
      }}
    }});
    
    _flowStateController.reverse();
  }}
  
  void _onCrystalCollected(CrystalType crystal) {{
    setState(() {{
      _crystalsCollected++;
      _totalCrystals += crystal.value;
      
      // Effet visuel et sonore
      _crystalAnimController.forward().then((_) {{
        _crystalAnimController.reset();
      }});
    }});
    
    HapticFeedback.lightImpact();
    
    // Feedback vocal adaptatif
    if (_crystalsCollected % 10 == 0) {{
      _playCommanderVoice(
        "Magnifique ! ${{_crystalsCollected}} cristaux collectés !",
        emotion: 'celebrating',
      );
    }}
    
    // Vérifier les achievements
    _checkAchievements();
  }}
  
  void _onObstacleHit(ObstacleType obstacle) {{
    setState(() {{
      // Réduire l'énergie ou les points
      _flowMeter = math.max(_flowMeter - 0.2, 0.0);
    }});
    
    HapticFeedback.heavyImpact();
    
    _playCommanderVoice(
      "Attention aux astéroïdes ! Ajustez votre trajectoire.",
      emotion: 'warning',
    );
  }}
  
  void _onLevelComplete() {{
    setState(() {{
      _currentLevel++;
      
      // Débloquer nouveau système solaire
      if (_currentLevel == 5) {{
        _currentSystem = 'Nébuleuse Orion';
        _unlockNewSystem();
      }}
    }});
    
    _confettiController.play();
    
    _playCommanderVoice(
      "Mission accomplie ! Préparez-vous pour le niveau suivant !",
      emotion: 'triumphant',
    );
    
    // Calculer et afficher les résultats
    _showLevelResults();
  }}
  
  void _checkAchievements() {{
    // Vérifier les différents achievements
    if (_crystalsCollected == 1) {{
      _unlockAchievement('first_crystal', 'Premier Cristal');
    }}
    
    if (_crystalsCollected >= 100) {{
      _unlockAchievement('crystal_collector', 'Collectionneur de Cristaux');
    }}
    
    if (_obstaclesAvoided >= 50) {{
      _unlockAchievement('asteroid_dodger', 'Éviteur d\'Astéroïdes');
    }}
    
    if (_vocalRange > 200) {{
      _unlockAchievement('pitch_master', 'Maître de la Tessiture');
    }}
  }}
  
  void _unlockAchievement(String id, String name) {{
    // Débloquer achievement via le service de gamification
    _gamificationService.unlockAchievement(id);
    
    // Afficher notification
    _showAchievementNotification(name);
  }}
  
  void _showAchievementNotification(String name) {{
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Achievement débloqué : $name'),
          ],
        ),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }}
  
  void _unlockNewSystem() {{
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.cyan, width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/galaxy_unlock.json',
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              '🌌 NOUVEAU SYSTÈME DÉBLOQUÉ !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currentSystem,
              style: const TextStyle(
                color: Colors.cyan,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
            ),
            onPressed: () {{
              Navigator.of(context).pop();
              _startNewSystem();
            }},
            child: const Text('Explorer !'),
          ),
        ],
      ),
    );
  }}
  
  void _startNewSystem() {{
    // Charger le nouveau système avec ses défis spécifiques
    _game.loadSystem(_currentSystem);
  }}
  
  void _showLevelResults() {{
    final int earnedXP = (_crystalsCollected * 10 * (_inFlowState ? 2 : 1)).toInt();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyan, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🚀 MISSION ACCOMPLIE !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Statistiques
              _buildStatRow('💎 Cristaux collectés', '$_crystalsCollected'),
              _buildStatRow('⚡ XP gagné', '+$earnedXP'),
              _buildStatRow('🎯 Précision vocale', '${{(_pitchStability * 100).toInt()}}%'),
              _buildStatRow('🌊 Tessiture vocale', '${{_vocalRange.toInt()}} Hz'),
              
              if (_inFlowState) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.star, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'BONUS FLOW STATE x2',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {{
                      Navigator.of(context).pop();
                      _shareResults();
                    }},
                    child: const Text('Partager', style: TextStyle(color: Colors.cyan)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                    ),
                    onPressed: () {{
                      Navigator.of(context).pop();
                      _game.nextLevel();
                    }},
                    child: const Text('Niveau Suivant'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }}
  
  Widget _buildStatRow(String label, String value) {{
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }}
  
  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background cosmique animé
          _buildCosmicBackground(),
          
          // Zone de jeu principale
          _gameWidget,
          
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Header avec infos
                _buildGameHeader(),
                
                // Indicateur de flow state
                if (_flowMeter > 0)
                  _buildFlowStateIndicator(),
                
                const Spacer(),
                
                // Contrôles et indicateurs vocaux
                _buildVocalControls(),
              ],
            ),
          ),
          
          // Effets visuels
          if (_inFlowState)
            _buildFlowStateEffects(),
          
          // Confetti pour célébrations
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.cyan, Colors.purple, Colors.pink],
              numberOfParticles: 50,
            ),
          ),
        ],
      ),
    );
  }}
  
  Widget _buildCosmicBackground() {{
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000428),
            Color(0xFF004E92),
          ],
        ),
      ),
      child: CustomPaint(
        painter: StarfieldPainter(
          animationValue: _crystalAnimController.value,
        ),
        child: Container(),
      ),
    );
  }}
  
  Widget _buildGameHeader() {{
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Niveau et système
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentSystem,
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Niveau $_currentLevel',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Cristaux collectés
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyan),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.cyan, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_totalCrystals',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Menu
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: _showGameMenu,
          ),
        ],
      ),
    );
  }}
  
  Widget _buildFlowStateIndicator() {{
    return AnimatedBuilder(
      animation: _flowAnimation,
      builder: (context, child) {{
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.3),
                Colors.pink.withOpacity(0.3),
              ],
            ),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _flowMeter,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      }},
    );
  }}
  
  Widget _buildVocalControls() {{
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Indicateur de pitch
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _inFlowState ? Colors.purple : Colors.cyan,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Zone neutre
                Positioned(
                  left: 0,
                  right: 0,
                  top: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                // Indicateur de position actuelle
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  left: 10,
                  right: 10,
                  top: (1 - _spaceshipY) * 40 + 10,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: _inFlowState ? Colors.purple : Colors.cyan,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: (_inFlowState ? Colors.purple : Colors.cyan)
                              .withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Fréquence actuelle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.graphic_eq, color: Colors.cyan),
              const SizedBox(width: 8),
              Text(
                '${{_currentPitch.toInt()}} Hz',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }}
  
  Widget _buildFlowStateEffects() {{
    return AnimatedBuilder(
      animation: _flowAnimation,
      builder: (context, child) {{
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                Colors.purple.withOpacity(0.1 * _flowAnimation.value),
                Colors.transparent,
              ],
            ),
          ),
        );
      }},
    );
  }}
  
  void _showGameMenu() {{
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.rocket_launch, color: Colors.cyan),
              title: const Text('Améliorer le Vaisseau',
                  style: TextStyle(color: Colors.white)),
              onTap: _showSpaceshipUpgrades,
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard, color: Colors.amber),
              title: const Text('Classements',
                  style: TextStyle(color: Colors.white)),
              onTap: _showLeaderboards,
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.green),
              title: const Text('Mode Coopératif',
                  style: TextStyle(color: Colors.white)),
              onTap: _startCoopMode,
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.purple),
              title: const Text('Achievements',
                  style: TextStyle(color: Colors.white)),
              onTap: _showAchievements,
            ),
          ],
        ),
      ),
    );
  }}
  
  void _showSpaceshipUpgrades() {{
    // Afficher l'interface d'amélioration du vaisseau
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceshipUpgradeScreen(
          crystals: _totalCrystals,
          onUpgrade: (upgrade) {{
            setState(() {{
              _totalCrystals -= upgrade.cost;
              // Appliquer l'amélioration
            }});
          }},
        ),
      ),
    );
  }}
  
  void _showLeaderboards() {{
    // Afficher les classements
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaderboardScreen(
          dailyLeaderboard: _dailyLeaderboard,
          userRank: _userRank,
        ),
      ),
    );
  }}
  
  void _startCoopMode() {{
    // Démarrer le mode coopératif
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Mode Coopératif',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Invitez un partenaire pour une mission à deux voix !',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Code de la salle',
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {{
              Navigator.pop(context);
              _connectToCoopPartner();
            }},
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }}
  
  void _connectToCoopPartner() {{
    // Logique de connexion au partenaire
    setState(() {{
      _isCoopMode = true;
      _partnerName = 'Partenaire Cosmique';
    }});
    
    _playCommanderVoice(
      "Mode coopératif activé ! Synchronisez vos voix pour un bonus maximum !",
      emotion: 'excited',
    );
  }}
  
  void _showAchievements() {{
    // Afficher les achievements
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }}
  
  void _shareResults() {{
    // Partager les résultats sur les réseaux sociaux
    // ou dans la communauté Eloquence
  }}
  
  void _handleAudioMetrics(Map<String, dynamic> metrics) {{
    setState(() {{
      _pitchStability = metrics['pitch_stability'] ?? 0.0;
      _vocalRange = metrics['vocal_range'] ?? 0.0;
    }});
  }}
  
  void _addXP(int amount, {{String? reason}}) {{
    // Ajouter XP via le service de gamification
    _gamificationService.addXP(amount, reason: reason);
  }}
  
  Future<void> _playCommanderVoice(String text, {{String emotion = 'neutral'}}) async {{
    // Jouer la voix du commandant avec TTS
    await _audioService.playTTS(
      text: text,
      voice: 'nova',
      speed: 1.0,
      emotion: emotion,
    );
  }}
  
  @override
  void dispose() {{
    _spaceshipAnimController.dispose();
    _crystalAnimController.dispose();
    _flowStateController.dispose();
    _confettiController.dispose();
    _game.dispose();
    _audioService.dispose();
    super.dispose();
  }}
}}

// 🎮 Classe du jeu Flame
class SpaceshipGame extends FlameGame {{
  final Function(CrystalType) onCrystalCollected;
  final Function(ObstacleType) onObstacleHit;
  final Function() onLevelComplete;
  
  late SpaceshipComponent spaceship;
  
  SpaceshipGame({{
    required this.onCrystalCollected,
    required this.onObstacleHit,
    required this.onLevelComplete,
  }});
  
  @override
  Future<void> onLoad() async {{
    // Initialiser les composants du jeu
    spaceship = SpaceshipComponent();
    add(spaceship);
    
    // Générer cristaux et obstacles
    _generateLevel();
  }}
  
  void updateSpaceshipPosition(double y) {{
    spaceship.position.y = size.y * y;
  }}
  
  void _generateLevel() {{
    // Générer le niveau avec cristaux et obstacles
  }}
  
  void loadSystem(String systemName) {{
    // Charger un nouveau système solaire
  }}
  
  void nextLevel() {{
    // Passer au niveau suivant
  }}
}}

// Composants du jeu
class SpaceshipComponent extends PositionComponent {{
  // Logique du vaisseau spatial
}}

class CrystalType {{
  final String name;
  final int value;
  final Color color;
  
  CrystalType({{required this.name, required this.value, required this.color}});
}}

class ObstacleType {{
  final String name;
  final int damage;
  
  ObstacleType({{required this.name, required this.damage}});
}}

// Painter pour le fond étoilé
class StarfieldPainter extends CustomPainter {{
  final double animationValue;
  
  StarfieldPainter({{required this.animationValue}});
  
  @override
  void paint(Canvas canvas, Size size) {{
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeCap = StrokeCap.round;
    
    // Dessiner des étoiles animées
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {{
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + animationValue * 100) % size.height;
      final radius = random.nextDouble() * 2;
      
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.8 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }}
  }}
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}}

// Écrans supplémentaires (à implémenter)
class SpaceshipUpgradeScreen extends StatelessWidget {{
  final int crystals;
  final Function(dynamic) onUpgrade;
  
  const SpaceshipUpgradeScreen({{
    Key? key,
    required this.crystals,
    required this.onUpgrade,
  }}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Améliorer le Vaisseau'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text('Interface d\'amélioration'),
      ),
    );
  }}
}}

class LeaderboardScreen extends StatelessWidget {{
  final List<LeaderboardEntry> dailyLeaderboard;
  final int? userRank;
  
  const LeaderboardScreen({{
    Key? key,
    required this.dailyLeaderboard,
    this.userRank,
  }}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Classements'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text('Classements'),
      ),
    );
  }}
}}

class AchievementsScreen extends StatelessWidget {{
  const AchievementsScreen({{Key? key}}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text('Achievements'),
      ),
    );
  }}
}}

class LeaderboardEntry {{
  final String playerName;
  final int score;
  final int rank;
  
  LeaderboardEntry({{
    required this.playerName,
    required this.score,
    required this.rank,
  }});
}}
'''

def save_exercise_files(exercise):
    """Sauvegarde les fichiers générés"""
    
    # Nom de fichier basé sur l'ID
    exercise_id = exercise['id']
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # Sauvegarder la configuration JSON
    json_file = f"cosmic_voice_exercise_{timestamp}.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(exercise, f, indent=2, ensure_ascii=False)
    
    # Sauvegarder le code Flutter
    flutter_file = f"cosmic_voice_screen_{timestamp}.dart"
    with open(flutter_file, 'w', encoding='utf-8') as f:
        f.write(exercise['flutter_implementation'])
    
    print(f"\n[FICHIERS] Fichiers générés:")
    print(f"   - Configuration: {json_file}")
    print(f"   - Code Flutter: {flutter_file}")
    
    return json_file, flutter_file

def print_exercise_summary(exercise):
    """Affiche un résumé de l'exercice généré"""
    
    print("\n" + "=" * 60)
    print("[RESUME] RÉSUMÉ DE L'EXERCICE")
    print("=" * 60)
    print(f"[NOM] {exercise['name']}")
    print(f"[PERSONNAGE IA] {exercise['ai_character']}")
    print(f"[VOIX] {exercise['voice_profile']['voice']}")
    print(f"[XP BASE] {exercise['gamification_config']['xp_base']}")
    print(f"[MECANIQUES DE JEU]:")
    
    if 'game_config' in exercise:
        print(f"   - Cristaux: {len(exercise['game_config']['crystal_types'])} types")
        print(f"   - Obstacles: {len(exercise['game_config']['obstacles'])} types")
        print(f"   - Améliorations: {len(exercise['game_config']['spaceship_upgrades'])} disponibles")
    
    if 'progression_config' in exercise:
        print(f"[SYSTEMES SOLAIRES] {len(exercise['progression_config']['solar_systems'])}")
        print(f"[ACHIEVEMENTS] {len(exercise['progression_config']['achievements'])}")
    
    if 'multiplayer_config' in exercise:
        print(f"[MODE COOP] {'Activé' if exercise['multiplayer_config']['coop_mode']['enabled'] else 'Désactivé'}")
        print(f"[CLASSEMENTS] {len(exercise['multiplayer_config']['leaderboards'])} types")
    
    print(f"\n[SERVICES UTILISES]:")
    for service in exercise.get('existing_services', []):
        print(f"   - {service}")
    
    print("\n[CARACTERISTIQUES SPECIALES]:")
    print("   - Contrôle vocal direct par détection de pitch")
    print("   - Flow state avec bonus XP")
    print("   - Progression multi-niveaux")
    print("   - Personnalisation du vaisseau")
    print("   - Mode coopératif parent-enfant")
    print("   - Classements communautaires")

if __name__ == "__main__":
    # Générer l'exercice Accordeur Vocal Cosmique
    exercise = generate_cosmic_voice_exercise()
    
    if exercise:
        print("\n[SUCCES] L'Accordeur Vocal Cosmique est prêt !")
        print("Lancez l'exercice dans Flutter pour commencer l'aventure spatiale !")