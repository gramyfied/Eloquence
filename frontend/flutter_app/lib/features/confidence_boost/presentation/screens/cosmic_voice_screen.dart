// 🌌 L'ACCORDEUR VOCAL COSMIQUE - MODE RÉEL UNIQUEMENT
// Contrôle vocal gamifié d'un vaisseau spatial
// Flow state + Accomplissement + Personnalisation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../data/services/universal_audio_exercise_service.dart';
import '../providers/gamification_provider.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

class CosmicVoiceScreen extends ConsumerStatefulWidget {
  const CosmicVoiceScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<CosmicVoiceScreen> createState() => _CosmicVoiceScreenState();
}

class _CosmicVoiceScreenState extends ConsumerState<CosmicVoiceScreen>
    with TickerProviderStateMixin {
  
  // 🔧 Services
  late UniversalAudioExerciseService _audioService;
  String? _sessionId;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _metricsSubscription;
  
  // 🌐 État de connexion
  ConnectionState _connectionState = ConnectionState.connecting;
  String _statusMessage = 'Initialisation...';
  Timer? _connectionTimer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // 🎮 Gestionnaires de jeu
  late final PitchController _pitchController;
  late final CosmicGameManager _gameManager;
  
  // 🚀 État du vaisseau
  double _spaceshipY = 0.5; // Position verticale (0.0 = haut, 1.0 = bas)
  double _currentPitch = 150.0; // Fréquence actuelle en Hz
  
  // 💎 Cristaux et progression
  int _crystalsCollected = 0;
  int _totalCrystals = 0;
  int _currentLevel = 1;
  String _currentSystem = 'Système Alpha';
  
  // 🎯 Métriques de performance
  double _pitchStability = 0.0;
  double _vocalRange = 0.0;
  
  // 🎨 Animations
  late AnimationController _spaceshipAnimController;
  late AnimationController _crystalAnimController;
  late AnimationController _flowStateController;
  late Animation<double> _flowAnimation;
  
  // 🌟 État du flow
  bool _inFlowState = false;
  double _flowMeter = 0.0;
  DateTime? _flowStartTime;
  int _consecutiveGoodActions = 0;
  
  // Liste des obstacles et cristaux
  List<GameObject> _gameObjects = [];
  Timer? _gameTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGameManagers();
    
    // Initialisation propre avec addPostFrameCallback (pattern des exercices qui fonctionnent)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _isInitialized = true;
        _initializeCosmicExercise();
      }
    });
  }
  
  void _initializeGameManagers() {
    _pitchController = PitchController();
    _gameManager = CosmicGameManager();
  }
  
  void _initializeAnimations() {
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
  }
  
  /// Initialisation avec gestion d'erreurs robuste (pattern Dragon Breath)
  Future<void> _initializeCosmicExercise() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _connectionState = ConnectionState.connecting;
      _statusMessage = 'Connexion au système vocal cosmique...';
    });
    
    try {
      // Initialiser le service audio
      _audioService = UniversalAudioExerciseService();
      
      // Créer la configuration pour l'exercice cosmique avec timeout plus long
      final cosmicConfig = const AudioExerciseConfig(
        exerciseId: 'cosmic_voice_control',
        title: 'L\'Accordeur Vocal Cosmique',
        description: 'Contrôlez votre vaisseau spatial avec votre voix',
        scenario: 'cosmic_voice_navigation',
        maxDuration: Duration(minutes: 10),
        customSettings: {
          'exercise_type': 'cosmic_voice_control',
          'enable_pitch_tracking': true,
          'enable_real_time_feedback': true,
        },
      );
      
      // Tentative de connexion avec timeout plus généreux
      debugPrint('🔄 Tentative de connexion aux services vocaux...');
      
      final sessionId = await _audioService.startExercise(cosmicConfig)
          .timeout(const Duration(seconds: 15)); // Plus long que 5 secondes
      
      await _audioService.connectExerciseWebSocket(sessionId)
          .timeout(const Duration(seconds: 10));
      
      // Connexion réussie !
      setState(() {
        _isLoading = false;
        _connectionState = ConnectionState.connected;
        _sessionId = sessionId;
        _statusMessage = 'Mode vocal actif - Parlez pour contrôler !';
      });
      
      _setupAudioStreams();
      _startGameLoop();
      _showWelcomeMessage();
      
      debugPrint('✅ Connexion cosmique réussie ! Session: $sessionId');
      
    } catch (e) {
      debugPrint('❌ Échec connexion cosmique: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _connectionState = ConnectionState.failed;
        _errorMessage = e.toString();
        _statusMessage = 'Connexion impossible';
      });
    }
  }
  
  void _setupAudioStreams() {
    // S'abonner aux messages et métriques
    _messageSubscription = _audioService.messageStream.listen(
      _handleMessage,
      onError: (error) {
        debugPrint('❌ ERREUR MessageStream: $error');
      },
    );
    _metricsSubscription = _audioService.realTimeMetricsStream.listen(
      _handleMetrics,
      onError: (error) {
        debugPrint('❌ ERREUR MetricsStream: $error');
      },
    );
    
    debugPrint('🎤 Flux audio établis - Mode vocal réel activé !');
    debugPrint('🔍 DIAGNOSTIC: Streams configurés pour recevoir pitch data');
  }
  
  void _showWelcomeMessage() {
    Future.microtask(() {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.cyan),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🌌 Bienvenue, pilote cosmique ! Utilisez votre VOIX pour contrôler le vaisseau.\n'
                    '🎤 Mode vocal réel activé - Parlez pour diriger votre vaisseau !',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
  
  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          _updateGameObjects();
          _checkCollisions();
          _updateFlowState();
        });
      }
    });
  }
  
  void _updateGameObjects() {
    final objectsCountBefore = _gameObjects.length;
    
    // Difficulté progressive basée sur le niveau
    if (_gameObjects.isEmpty || _gameObjects.last.x > 0.8) {
      final random = math.Random();
      
      // Difficulté basée sur le niveau
      final crystalProbability = math.max(0.3, 0.7 - (_gameManager.currentLevel * 0.05));
      final isCrystal = random.nextDouble() < crystalProbability;
      
      _gameObjects.add(GameObject(
        x: 1.2,
        y: random.nextDouble(),
        type: isCrystal ? GameObjectType.crystal : GameObjectType.obstacle,
        value: isCrystal ? (10 + _gameManager.currentLevel * 2) : 0,
      ));
      
      debugPrint('💎 DIAGNOSTIC OBJETS: Nouvel objet ajouté - ${isCrystal ? "CRISTAL" : "OBSTACLE"} (Total: ${_gameObjects.length})');
    }
    
    // Vitesse augmente avec le niveau
    final speed = 0.02 + (_gameManager.currentLevel * 0.005);
    for (var obj in _gameObjects) {
      obj.x -= speed;
    }
    
    // Compter obstacles évités
    final objectsToRemove = _gameObjects.where((obj) => obj.x < -0.1).toList();
    for (var obj in objectsToRemove) {
      if (obj.type == GameObjectType.obstacle && !obj.hit) {
        _gameManager.onObstacleAvoided();
      }
    }
    
    _gameObjects.removeWhere((obj) => obj.x < -0.1);
    
    final objectsCountAfter = _gameObjects.length;
    if (objectsCountBefore != objectsCountAfter) {
      debugPrint('🗑️ DIAGNOSTIC OBJETS: Supprimés ${objectsCountBefore - objectsCountAfter} objets. Reste: $objectsCountAfter');
    }
    
    // Diagnostic si trop d'objets s'accumulent - seuil réduit
    if (_gameObjects.length > 10) {
      debugPrint('⚠️ PROBLÈME DÉTECTÉ: Trop d\'objets accumulés (${_gameObjects.length})!');
      debugPrint('🔍 États objets: ${_gameObjects.map((o) => '${o.type.name}@${o.x.toStringAsFixed(2)}').join(", ")}');
    }
  }
  
  void _checkCollisions() {
    for (var obj in _gameObjects) {
      final distanceX = (obj.x - 0.5).abs();
      final distanceY = (obj.y - _spaceshipY).abs();
      final isColliding = distanceX < 0.05 && distanceY < 0.1;
      
      if (isColliding) {
        if (obj.type == GameObjectType.crystal && !obj.collected) {
          obj.collected = true;
          debugPrint('💎 COLLISION CRISTAL: x=${obj.x.toStringAsFixed(2)}, y=${obj.y.toStringAsFixed(2)}, vaisseauY=${_spaceshipY.toStringAsFixed(2)}');
          _onCrystalCollected(obj);
        } else if (obj.type == GameObjectType.obstacle && !obj.hit) {
          obj.hit = true;
          debugPrint('💥 COLLISION OBSTACLE: x=${obj.x.toStringAsFixed(2)}, y=${obj.y.toStringAsFixed(2)}, vaisseauY=${_spaceshipY.toStringAsFixed(2)}');
          _onObstacleHit(obj);
        }
      }
    }
  }
  
  void _handleMessage(AudioExchangeMessage message) {
    debugPrint('📩 Message cosmique reçu: ${message.role} - ${message.text}');
    debugPrint('🔍 DIAGNOSTIC CONTRÔLE VOCAL: analysisData keys = ${message.analysisData.keys.toList()}');
    debugPrint('🔍 DIAGNOSTIC CONTRÔLE VOCAL: analysisData = ${message.analysisData}');
    
    if (message.analysisData.containsKey('pitch')) {
      final pitch = message.analysisData['pitch'] as double;
      debugPrint('🎤 PITCH DÉTECTÉ VIA MESSAGE: $pitch Hz');
      _handlePitchDetection(pitch);
    } else {
      debugPrint('⚠️ PROBLÈME: Aucune donnée pitch dans analysisData!');
      debugPrint('📋 DIAGNOSTIC: Clés disponibles dans message: ${message.analysisData.keys.join(", ")}');
      
      // Essayer d'autres noms de clés potentiels pour le pitch
      final altKeys = ['frequency', 'f0', 'fundamental_frequency', 'pitch_hz'];
      for (final key in altKeys) {
        if (message.analysisData.containsKey(key)) {
          final value = message.analysisData[key];
          debugPrint('🔍 PITCH ALTERNATIF TROUVÉ: $key = $value');
          if (value is num) {
            _handlePitchDetection(value.toDouble());
            return;
          }
        }
      }
    }
  }
  
  void _handleMetrics(Map<String, dynamic> metrics) {
    debugPrint('📊 DIAGNOSTIC MÉTRIQUES: keys = ${metrics.keys.toList()}');
    debugPrint('📊 DIAGNOSTIC MÉTRIQUES: values = $metrics');
    
    setState(() {
      if (metrics.containsKey('pitch')) {
        _currentPitch = metrics['pitch'] as double;
        debugPrint('🎤 PITCH DÉTECTÉ VIA MÉTRIQUES: $_currentPitch Hz → Position vaiseau mise à jour');
        _handlePitchDetection(_currentPitch);
      } else {
        debugPrint('⚠️ PROBLÈME: Aucune donnée pitch dans metrics!');
        debugPrint('📋 DIAGNOSTIC: Clés disponibles dans metrics: ${metrics.keys.join(", ")}');
        
        // Essayer d'autres noms de clés potentiels pour le pitch
        final altKeys = ['frequency', 'f0', 'fundamental_frequency', 'pitch_hz'];
        for (final key in altKeys) {
          if (metrics.containsKey(key)) {
            final value = metrics[key];
            debugPrint('🔍 PITCH ALTERNATIF TROUVÉ: $key = $value');
            if (value is num) {
              _currentPitch = value.toDouble();
              debugPrint('🎤 PITCH ALTERNATIF UTILISÉ: $_currentPitch Hz');
              _handlePitchDetection(_currentPitch);
              break;
            }
          }
        }
      }
      
      if (metrics.containsKey('pitch_stability')) {
        _pitchStability = metrics['pitch_stability'] as double;
        debugPrint('📈 Stabilité pitch: $_pitchStability');
      }
      
      if (metrics.containsKey('vocal_range')) {
        _vocalRange = metrics['vocal_range'] as double;
        debugPrint('📏 Range vocal: $_vocalRange');
      }
    });
  }
  
  void _handlePitchDetection(double pitchHz) {
    final oldPosition = _spaceshipY;
    setState(() {
      _currentPitch = pitchHz;
      _spaceshipY = _pitchController.updatePosition(pitchHz);
    });
    
    debugPrint('🚀 CONTRÔLE VAISEAU: $pitchHz Hz → Position ${oldPosition.toStringAsFixed(2)} → ${_spaceshipY.toStringAsFixed(2)}');
    
    _updateFlowState();
  }
  
  void _updateFlowState() {
    // Logique sophistiquée avec stabilité du pitch
    final pitchStability = _pitchController.getPitchStability();
    final isInGoodRange = pitchStability > 0.6;
    
    if (isInGoodRange) {
      _consecutiveGoodActions++;
      _flowMeter = math.min(_flowMeter + 0.02, 1.0);
      
      // Entrer en flow state après 5 secondes de stabilité
      if (_consecutiveGoodActions > 50 && !_inFlowState) {
        _enterFlowState();
      }
    } else {
      _consecutiveGoodActions = 0;
      _flowMeter = math.max(_flowMeter - 0.01, 0.0);
      
      if (_flowMeter < 0.3 && _inFlowState) {
        _exitFlowState();
      }
    }
  }
  
  void _enterFlowState() {
    setState(() {
      _inFlowState = true;
      _flowStartTime = DateTime.now();
    });
    
    _flowStateController.forward();
    HapticFeedback.lightImpact();
    
    _safeSendMessage("Excellent ! Vous êtes en parfaite harmonie avec le cosmos !");
  }
  
  void _exitFlowState() {
    setState(() {
      _inFlowState = false;
      
      // Calculer bonus XP pour le temps en flow
      if (_flowStartTime != null) {
        int flowDuration = DateTime.now().difference(_flowStartTime!).inSeconds;
        int bonusXP = flowDuration * 5;
        _addXP(bonusXP, reason: 'Flow State Bonus');
      }
    });
    
    _flowStateController.reverse();
  }
  
  void _onCrystalCollected(GameObject crystal) {
    setState(() {
      _crystalsCollected++;
      _totalCrystals += crystal.value;
      
      // Effet visuel
      _crystalAnimController.forward().then((_) {
        _crystalAnimController.reset();
      });
    });
    
    _gameManager.onCrystalCollected(crystal.value);
    HapticFeedback.lightImpact();
    
    // Feedback vocal adaptatif
    if (_gameManager.crystalsCollected % 10 == 0) {
      _safeSendMessage(
        "Magnifique ! ${_gameManager.crystalsCollected} cristaux collectés !"
      );
    }
  }
  
  void _onObstacleHit(GameObject obstacle) {
    setState(() {
      _flowMeter = math.max(_flowMeter - 0.2, 0.0);
      _consecutiveGoodActions = 0;
    });
    
    HapticFeedback.heavyImpact();
    
    _safeSendMessage("Attention aux astéroïdes ! Ajustez votre trajectoire.");
  }
  
  void _safeSendMessage(String message) {
    try {
      if (_connectionState == ConnectionState.connected && _audioService != null) {
        _audioService.sendTextMessage(message);
        debugPrint('📤 Message cosmique envoyé: $message');
      } else {
        debugPrint('🔇 Service vocal non disponible: $message');
      }
    } catch (e) {
      debugPrint('⚠️ Impossible d\'envoyer le message cosmique: $e');
    }
  }
  
  void _addXP(int amount, {String? reason}) {
    _gameManager.addXP(amount, reason: reason);
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1E3A5F),
            ],
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    return Stack(
      children: [
        // Background cosmique animé
        _buildCosmicBackground(),
        
        // Zone de jeu principale
        _buildGameArea(),
        
        // Overlay UI
        Column(
          children: [
            // Header avec infos
            _buildGameHeader(),
            
            // Indicateur de flow state
            if (_flowMeter > 0)
              _buildFlowStateIndicator(),
            
            const Spacer(),
            
            // Contrôles vocaux
            _buildVocalControls(),
          ],
        ),
        
        // Effets visuels
        if (_inFlowState)
          _buildFlowStateEffects(),
      ],
    );
  }
  
  /// Écran de chargement moderne (pattern des exercices qui fonctionnent)
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.cyan.withOpacity(0.8),
                  Colors.cyan.withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Accordeur Vocal Cosmique',
            style: EloquenceTheme.headline2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            style: EloquenceTheme.bodyLarge.copyWith(
              color: Colors.cyan,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Écran d'erreur avec bouton réessayer (pattern des exercices qui fonctionnent)
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Icon(
                Icons.error_outline, 
                color: Colors.red, 
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Connexion Impossible",
              style: EloquenceTheme.headline2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Impossible de se connecter aux services vocaux cosmiques',
              style: EloquenceTheme.bodyMedium.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez que les services Docker sont démarrés :\n'
              '• vosk-stt (port 8002)\n'
              '• livekit-server (port 7880)\n'
              '• eloquence-exercises-api (port 8005)',
              style: EloquenceTheme.bodySmall.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Retour"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _initializeCosmicExercise();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Réessayer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCosmicBackground() {
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
  }
  
  Widget _buildGameArea() {
    return Stack(
      children: [
        // Objets du jeu (cristaux et obstacles)
        ..._gameObjects.map((obj) => AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          left: MediaQuery.of(context).size.width * obj.x,
          top: MediaQuery.of(context).size.height * obj.y,
          child: Icon(
            obj.type == GameObjectType.crystal
                ? Icons.diamond
                : Icons.warning,
            color: obj.type == GameObjectType.crystal
                ? (obj.collected ? Colors.grey : Colors.cyan)
                : (obj.hit ? Colors.grey : Colors.red),
            size: 30,
          ),
        )),
        
        // Vaisseau spatial
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          left: MediaQuery.of(context).size.width * 0.5 - 25,
          top: MediaQuery.of(context).size.height * _spaceshipY - 25,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _inFlowState ? Colors.purple : Colors.cyan,
                  _inFlowState ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_inFlowState ? Colors.purple : Colors.cyan).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bouton retour
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EloquenceTheme.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EloquenceTheme.glassBorder,
                width: 1,
              ),
            ),
            child: IconButton(
              iconSize: 20,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Titre et niveau
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accordeur Vocal Cosmique',
                  style: EloquenceTheme.headline3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Niveau $_currentLevel - $_currentSystem',
                  style: EloquenceTheme.bodySmall.copyWith(
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ),
          
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
          
          // Statut de connexion
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getConnectionColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getConnectionColor()),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getConnectionIcon(), color: _getConnectionColor(), size: 16),
                const SizedBox(width: 4),
                Text(
                  _getConnectionText(),
                  style: TextStyle(
                    color: _getConnectionColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlowStateIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.purple.withOpacity(0.3),
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
          ),
        ),
      ),
    );
  }
  
  Widget _buildVocalControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Indicateur de position
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
          
          const SizedBox(height: 16),
          
          // Fréquence actuelle et instructions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, color: Colors.cyan),
              const SizedBox(width: 8),
              Text(
                '${_currentPitch.toInt()} Hz',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Parlez pour contrôler votre vaisseau',
            style: EloquenceTheme.bodySmall.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlowStateEffects() {
    return AnimatedBuilder(
      animation: _flowAnimation,
      builder: (context, child) {
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
      },
    );
  }
  
  // Méthodes helper pour l'état de connexion
  Color _getConnectionColor() {
    switch (_connectionState) {
      case ConnectionState.connected: return Colors.green;
      case ConnectionState.connecting: return Colors.orange;
      case ConnectionState.failed: return Colors.red;
    }
  }

  IconData _getConnectionIcon() {
    switch (_connectionState) {
      case ConnectionState.connected: return Icons.mic;
      case ConnectionState.connecting: return Icons.wifi_find;
      case ConnectionState.failed: return Icons.error;
    }
  }

  String _getConnectionText() {
    switch (_connectionState) {
      case ConnectionState.connected: return 'VOCAL';
      case ConnectionState.connecting: return 'CONN...';
      case ConnectionState.failed: return 'ERREUR';
    }
  }
  
  @override
  void dispose() {
    // Nettoyer tous les timers et subscriptions
    _gameTimer?.cancel();
    _connectionTimer?.cancel();
    _messageSubscription?.cancel();
    _metricsSubscription?.cancel();
    
    // Déconnecter le service audio
    try {
      if (_sessionId != null && _connectionState == ConnectionState.connected) {
        _audioService.completeExercise(_sessionId!);
        _audioService.disconnectWebSocket();
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la déconnexion cosmique: $e');
    }
    
    // Nettoyer les animations
    _spaceshipAnimController.dispose();
    _crystalAnimController.dispose();
    _flowStateController.dispose();
    
    // Nettoyer le service audio
    _audioService.dispose();
    
    super.dispose();
  }
}

// Classes de support pour le jeu
enum ConnectionState { connecting, connected, failed }

enum GameObjectType { crystal, obstacle }

class GameObject {
  double x;
  double y;
  final GameObjectType type;
  final int value;
  bool collected = false;
  bool hit = false;
  
  GameObject({
    required this.x,
    required this.y,
    required this.type,
    required this.value,
  });
}

// Painter pour le fond étoilé
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  
  StarfieldPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeCap = StrokeCap.round;
    
    // Dessiner des étoiles animées
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + animationValue * 100) % size.height;
      final radius = random.nextDouble() * 2;
      
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.8 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Contrôleur de pitch amélioré
class PitchController {
  static const double MIN_PITCH = 80.0;
  static const double MAX_PITCH = 300.0;
  static const double SMOOTHING_FACTOR = 0.3;
  
  double _currentPosition = 0.5;
  final List<double> _pitchHistory = [];
  static const int HISTORY_SIZE = 5;
  
  double updatePosition(double pitchHz) {
    _pitchHistory.add(pitchHz);
    if (_pitchHistory.length > HISTORY_SIZE) {
      _pitchHistory.removeAt(0);
    }
    
    final avgPitch = _pitchHistory.reduce((a, b) => a + b) / _pitchHistory.length;
    double normalizedPitch = (avgPitch - MIN_PITCH) / (MAX_PITCH - MIN_PITCH);
    normalizedPitch = normalizedPitch.clamp(0.0, 1.0);
    
    final targetPosition = 1.0 - normalizedPitch; // Inversé pour que aigu = haut
    _currentPosition += (targetPosition - _currentPosition) * SMOOTHING_FACTOR;
    
    return _currentPosition;
  }
  
  double getPitchStability() {
    if (_pitchHistory.length < 3) return 0.0;
    
    final mean = _pitchHistory.reduce((a, b) => a + b) / _pitchHistory.length;
    final variance = _pitchHistory
        .map((pitch) => math.pow(pitch - mean, 2))
        .reduce((a, b) => a + b) / _pitchHistory.length;
    
    final stability = math.max(0.0, 1.0 - (variance / 1000.0));
    return stability.clamp(0.0, 1.0);
  }
}

// Gestionnaire de jeu et XP
class CosmicGameManager {
  int _totalXP = 0;
  int _crystalsCollected = 0;
  int _obstaclesAvoided = 0;
  int _currentLevel = 1;
  final List<String> _unlockedAchievements = [];
  
  int get totalXP => _totalXP;
  int get crystalsCollected => _crystalsCollected;
  int get obstaclesAvoided => _obstaclesAvoided;
  int get currentLevel => _currentLevel;
  List<String> get unlockedAchievements => List.unmodifiable(_unlockedAchievements);
  
  void addXP(int xp, {String? reason}) {
    _totalXP += xp;
    debugPrint('💎 XP cosmique ajouté: +$xp (Total: $_totalXP)${reason != null ? ' - $reason' : ''}');
  }
  
  void onCrystalCollected(int value) {
    _crystalsCollected++;
    final totalXP = value + _currentLevel * 2;
    addXP(totalXP, reason: 'Cristal cosmique collecté');
  }
  
  void onObstacleAvoided() {
    _obstaclesAvoided++;
    addXP(5, reason: 'Astéroïde évité');
  }
}
