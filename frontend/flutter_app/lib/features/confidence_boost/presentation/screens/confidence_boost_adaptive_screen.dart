import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../providers/confidence_boost_provider.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_models.dart' as confidence_models;
import '../../domain/entities/gamification_models.dart' as gamification;
import '../../domain/entities/confidence_session.dart';
import '../../domain/entities/ai_character_models.dart' as ai_models;
import '../widgets/animated_microphone_button.dart';
import '../widgets/scenario_generation_animation.dart';
import '../widgets/confidence_results_view.dart';
import '../widgets/conversation_chat_widget.dart';
import '../../data/services/conversation_manager.dart';
import '../../data/services/conversation_engine.dart';
import '../../domain/entities/ai_character_models.dart';
import 'package:collection/collection.dart';

// PROVIDER POUR CONVERSATION MANAGER
final conversationManagerProvider = Provider<ConversationManager>((ref) {
  return ConversationManager();
});

/// Interface adaptative unifiée pour l'exercice Boost Confidence
/// 
/// ✅ NOUVELLES FONCTIONNALITÉS INTÉGRÉES :
/// - Design System Eloquence (navy, cyan, violet, glass)
/// - Personnages IA adaptatifs (Thomas & Marie)
/// - Système de gamification contextuel
/// - Animations optimisées mobile
/// - Interface unique fluide (remplace PageView fragmenté)
/// - Timeouts optimisés (6s Vosk, 8s global)
/// - Future.any() pour analyses parallèles
class ConfidenceBoostAdaptiveScreen extends ConsumerStatefulWidget {
  final ConfidenceScenario scenario;
  final confidence_models.TextSupport? initialTextSupport;

  const ConfidenceBoostAdaptiveScreen({
    Key? key,
    required this.scenario,
    this.initialTextSupport,
  }) : super(key: key);

  @override
  ConsumerState<ConfidenceBoostAdaptiveScreen> createState() => _ConfidenceBoostAdaptiveScreenState();
}

class _ConfidenceBoostAdaptiveScreenState extends ConsumerState<ConfidenceBoostAdaptiveScreen>
    with TickerProviderStateMixin {
  
  final Logger _logger = Logger();

  // NOUVELLES VARIABLES CONVERSATIONNELLES
  List<ConversationMessage> _conversationMessages = [];
  bool _isAISpeaking = false;
  bool _isUserSpeaking = false;
  String? _currentTranscription;
  late ScrollController _conversationScrollController;
  
  // CONVERSATION MANAGER INTÉGRATION
  ConversationManager? _conversationManager;
  StreamSubscription<ConversationEvent>? _conversationEventsSubscription;
  StreamSubscription<TranscriptionSegment>? _transcriptionSubscription;
  StreamSubscription<ConversationMetrics>? _metricsSubscription;
  bool _isConversationInitialized = false;
  
  // === CONTRÔLEURS D'ANIMATION OPTIMISÉS ===
  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _aiCharacterController;
  late AnimationController _gamificationController;
  
  // === ANIMATIONS AVEC COURBES SPÉCIALISÉES ===
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _aiCharacterSlide;
  
  // === ÉTAT ADAPTATIF DE L'INTERFACE ===
  AdaptiveScreenPhase _currentPhase = AdaptiveScreenPhase.scenarioPresentation;
  ai_models.AICharacterType _activeCharacter = ai_models.AICharacterType.thomas;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  
  // === DESIGN SYSTEM ELOQUENCE ===
  static const _eloquencePalette = {
    'navy': Color(0xFF1E293B),
    'navyLight': Color(0xFF334155),
    'cyan': Color(0xFF06B6D4),
    'cyanLight': Color(0xFF67E8F9),
    'violet': Color(0xFF8B5CF6),
    'violetLight': Color(0xFFA78BFA),
    // CORRECTION CRITIQUE : Arrière-plans avec contraste optimal pour texte blanc
    'glass': Color(0x40334155), // Navy semi-transparent pour meilleur contraste
    'glassAccent': Color(0x60475569), // Accent plus foncé pour bordures
    'textSupportBg': Color(0x80334155), // Arrière-plan spécial pour support textuel
    'dialogueBg': Color(0x90475569), // Arrière-plan optimisé pour dialogues IA
  };
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startBackgroundAnimations();
    _logAdaptiveScreenInit();

    // NOUVELLE INITIALISATION CONVERSATIONNELLE
    _conversationScrollController = ScrollController();
    _initializeConversation();
  }
  
  void _initializeAnimations() {
    // Animation principale pour les transitions de phase
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation d'arrière-plan continue
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Animation des personnages IA
    _aiCharacterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animation de gamification
    _gamificationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Définir les animations avec courbes optimisées
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _aiCharacterSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _aiCharacterController,
      curve: Curves.easeOutBack,
    ));
    
  }
  
  void _startBackgroundAnimations() {
    _mainAnimationController.forward();
    _aiCharacterController.forward();
  }
  
  void _logAdaptiveScreenInit() {
    _logger.i('🎭 ConfidenceBoostAdaptiveScreen initialisé');
    _logger.i('   📊 Scénario: ${widget.scenario.title}');
    _logger.i('   🎯 Phase initiale: ${_currentPhase.name}');
    _logger.i('   🤖 Personnage actif: ${_activeCharacter.name}');
    _logger.i('   ✨ Design System Eloquence activé');
  }

  Future<void> _initializeConversation() async {
    _logger.i('🤖 Initialisation du ConversationManager pour conversation temps réel');
    
    try {
      // Obtenir le ConversationManager depuis le provider
      _conversationManager = ref.read(conversationManagerProvider);
      
      // Écouter les événements de conversation
      _conversationEventsSubscription = _conversationManager!.events.listen(
        _handleConversationEvent,
        onError: (error) {
          _logger.e('❌ Erreur stream événements: $error');
        },
      );
      
      // Écouter les transcriptions en temps réel
      _transcriptionSubscription = _conversationManager!.transcriptions.listen(
        _handleTranscriptionUpdate,
        onError: (error) {
          _logger.e('❌ Erreur stream transcriptions: $error');
        },
      );
      
      // Écouter les métriques de conversation
      _metricsSubscription = _conversationManager!.metrics.listen(
        _handleMetricsUpdate,
        onError: (error) {
          _logger.e('❌ Erreur stream métriques: $error');
        },
      );
      
      // Message d'accueil initial (avant initialisation ConversationManager)
      final welcomeMessage = ConversationMessage(
        text: _getWelcomeMessage(),
        role: ConversationRole.assistant,
        metadata: {'character': _activeCharacter.name},
      );
      
      setState(() {
        _conversationMessages.add(welcomeMessage);
        _isConversationInitialized = true;
      });
      
      _logger.i('✅ ConversationManager initialisé avec succès');
      
    } catch (e) {
      _logger.e('❌ Erreur initialisation ConversationManager: $e');
      _handleConversationError(e);
    }
  }
  
  String _getWelcomeMessage() {
    switch (widget.scenario.type) {
      case confidence_models.ConfidenceScenarioType.presentation:
        return "Bonjour ! Je suis Marie, votre cliente. Je suis curieuse de découvrir votre présentation. Commencez quand vous êtes prêt !";
      case confidence_models.ConfidenceScenarioType.interview:
        return "Bonjour ! Je suis Thomas, votre recruteur. Présentez-vous et expliquez-moi pourquoi vous souhaitez rejoindre notre équipe.";
      default:
        return "Bonjour ! Je suis votre interlocuteur IA. Commençons cet exercice ensemble !";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculer la hauteur de la barre de navigation système
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    final systemNavigationHeight = math.max(bottomPadding, bottomInsets);
    
    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan animé avec glassmorphisme
          _buildAnimatedBackground(),
          
          // Interface principale adaptative avec padding Android optimisé
          Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: MediaQuery.of(context).padding.top + 16.0,
              bottom: systemNavigationHeight + 80.0, // +80 pour l'espace des icônes
            ),
            child: AnimatedBuilder(
              animation: _mainAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildMainContent(),
                  ),
                );
              },
            ),
          ),
          
          // Overlay de gamification
          _buildGamificationOverlay(),
          
          // Personnages IA adaptatifs
          _buildAICharactersOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_backgroundAnimationController.value * 2 * math.pi / 10),
              colors: [
                _eloquencePalette['navy']!,
                _eloquencePalette['navyLight']!,
                _eloquencePalette['violet']!.withAlpha(77),
                _eloquencePalette['cyan']!.withAlpha(51),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Particules flottantes
              ..._buildFloatingParticles(),
            ],
          ),
        );
      },
    );
  }
  
  List<Widget> _buildFloatingParticles() {
    return List.generate(8, (index) {
      final delay = index * 0.2;
      final size = 20.0 + (index % 3) * 15.0;
      
      return AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, child) {
          final progress = (_backgroundAnimationController.value + delay) % 1.0;
          return Positioned(
            left: MediaQuery.of(context).size.width * (0.1 + (index % 4) * 0.2),
            top: MediaQuery.of(context).size.height * progress,
            child: Opacity(
              opacity: (math.sin(progress * math.pi) * 0.3).clamp(0.0, 0.3),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _eloquencePalette['glass']!,
                  boxShadow: [
                    BoxShadow(
                      color: _eloquencePalette['cyan']!.withAlpha(51),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
  
  Widget _buildMainContent() {
    switch (_currentPhase) {
      case AdaptiveScreenPhase.scenarioPresentation:
        return _buildScenarioPresentationPhase();
      case AdaptiveScreenPhase.textSupportSelection:
        return _buildTextSupportSelectionPhase();
      case AdaptiveScreenPhase.recordingPreparation:
        return _buildRecordingPreparationPhase();
      case AdaptiveScreenPhase.activeRecording:
        return _buildActiveRecordingPhase();
      case AdaptiveScreenPhase.analysisInProgress:
        return _buildAnalysisProgressPhase();
      case AdaptiveScreenPhase.resultsAndGamification:
        return _buildResultsPhase();
    }
  }
  
  Widget _buildScenarioPresentationPhase() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // En-tête avec titre élégant
          _buildEloquenceHeader(),
          
          const SizedBox(height: 32),
          
          // Carte de scénario avec glassmorphisme
          Expanded(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildScenarioCard(),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Bouton de progression élégant
          _buildPhaseProgressButton(
            label: 'Choisir le support textuel',
            icon: Icons.text_fields_rounded,
            onPressed: () => _transitionToPhase(AdaptiveScreenPhase.textSupportSelection),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEloquenceHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _eloquencePalette['glass']!,
        border: Border.all(
          color: _eloquencePalette['glassAccent']!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology_rounded,
            color: _eloquencePalette['cyan']!,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Boost Confidence',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildConfidenceIndicator(),
        ],
      ),
    );
  }

  Widget _buildCleanHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Icône Eloquence
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Titre clair et lisible
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boost Confidence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Conversation avec ${_activeCharacter.name}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Indicateur de niveau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF8B5CF6),
                width: 1,
              ),
            ),
            child: const Text(
              'Niveau Facile',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A1F2E), // Fond conversation
        border: Border.all(
          color: const Color(0xFF2A3441),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header de la conversation
          _buildConversationHeader(),
          
          // Messages de conversation
          Expanded(
            child: _buildMessagesList(),
          ),
          
          // Indicateur de saisie
          _buildTypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildConversationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Color(0xFF2A3441),
      ),
      child: Row(
        children: [
          // Avatar Marie/Thomas
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF00D4FF),
            child: Text(
              _activeCharacter.name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Nom et statut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeCharacter.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getCharacterStatus(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Indicateur d'état
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  String _getCharacterStatus() {
    if (_isAISpeaking) return 'En train de parler...';
    if (_isUserSpeaking) return 'Vous écoute...';
    return 'En ligne';
  }

  Widget _buildStatusIndicator() {
    Color statusColor = const Color(0xFF10B981); // Vert par défaut
    if (_isAISpeaking) statusColor = const Color(0xFF3B82F6); // Bleu
    if (_isUserSpeaking) statusColor = const Color(0xFFF59E0B); // Orange
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: statusColor,
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _conversationScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _conversationMessages.length + (_currentTranscription != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Message de transcription en cours
        if (index == _conversationMessages.length && _currentTranscription != null) {
          return _buildTranscriptionMessage(_currentTranscription!);
        }
        
        final message = _conversationMessages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ConversationMessage message) {
    final isUser = message.role == ConversationRole.user;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar IA
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00D4FF),
              child: Text(
                _activeCharacter.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Bulle de message
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isUser
                    ? const Color(0xFF8B5CF6) // Violet pour utilisateur
                    : const Color(0xFF2A3441), // Gris pour IA
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du locuteur
                  Text(
                    isUser ? 'Vous' : _activeCharacter.name,
                    style: TextStyle(
                      color: isUser ? Colors.white.withOpacity(0.8) : const Color(0xFF00D4FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Texte du message
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  
                  // Métadonnées (scores, feedback)
                  if (message.metadata != null && message.metadata!.isNotEmpty)
                    _buildMessageMetadata(message.metadata!),
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            // Avatar utilisateur
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8B5CF6),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranscriptionMessage(String transcription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF8B5CF6).withOpacity(0.5),
                border: Border.all(
                  color: const Color(0xFF8B5CF6),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Vous (en cours)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transcription,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF8B5CF6),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isAISpeaking) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF00D4FF),
            child: Text(
              _activeCharacter.name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_activeCharacter.name} est en train d\'écrire',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          _buildTypingAnimation(),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 600 + (index * 200)),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D4FF).withOpacity(0.7),
          ),
        );
      }),
    );
  }

  Widget _buildMessageMetadata(Map<String, dynamic> metadata) {
    // TODO: Implémenter l'affichage des métadonnées (scores, etc.)
    return const SizedBox.shrink();
  }

  Widget _buildCleanTextSupport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1F2E),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du support textuel
          Row(
            children: [
              Icon(
                _getTextSupportIcon(),
                color: const Color(0xFF00D4FF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _getTextSupportTitle(),
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Bouton pour masquer/afficher
              GestureDetector(
                onTap: _toggleTextSupport,
                child: Icon(
                  _isTextSupportExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
          
          if (_isTextSupportExpanded) ...[
            const SizedBox(height: 12),
            
            // Contenu du support textuel
            Expanded(
              child: SingleChildScrollView(
                child: _buildTextSupportContent(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getTextSupportIcon() {
    final provider = ref.read(confidenceBoostProvider);
    switch (provider.selectedSupportType) {
      case confidence_models.SupportType.fullText:
        return Icons.text_snippet_outlined;
      case confidence_models.SupportType.fillInBlanks:
        return Icons.edit_outlined;
      case confidence_models.SupportType.guidedStructure:
        return Icons.account_tree_outlined;
      case confidence_models.SupportType.keywordChallenge:
        return Icons.key_outlined;
      case confidence_models.SupportType.freeImprovisation:
        return Icons.visibility_off_outlined;
    }
  }

  String _getTextSupportTitle() {
    final provider = ref.read(confidenceBoostProvider);
    switch (provider.selectedSupportType) {
      case confidence_models.SupportType.fullText:
        return 'Support textuel complet';
      case confidence_models.SupportType.fillInBlanks:
        return 'Texte à compléter';
      case confidence_models.SupportType.guidedStructure:
        return 'Structure guidée';
      case confidence_models.SupportType.keywordChallenge:
        return 'Défi de mots-clés';
      case confidence_models.SupportType.freeImprovisation:
        return 'Aucun support';
    }
  }

  Widget _buildTextSupportContent() {
    final provider = ref.read(confidenceBoostProvider);
    final currentPhaseText = _getCurrentPhaseText();
    
    switch (provider.selectedSupportType) {
      case confidence_models.SupportType.fullText:
        return Text(
          currentPhaseText,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            height: 1.5,
          ),
        );
        
      case confidence_models.SupportType.fillInBlanks:
        return _buildGappedTextContent(currentPhaseText);
        
      case confidence_models.SupportType.guidedStructure:
      case confidence_models.SupportType.keywordChallenge:
      case confidence_models.SupportType.freeImprovisation:
      default:
        return Text(
          'Vous avez choisi de parler sans support textuel. Faites confiance à votre instinct !',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildGappedTextContent(String fullText) {
    final gappedText = _createGappedText(fullText);
    final spans = _buildGappedTextSpans(gappedText);
    
    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  // Variables d'état pour le support textuel
  bool _isTextSupportExpanded = true;

  void _toggleTextSupport() {
    setState(() {
      _isTextSupportExpanded = !_isTextSupportExpanded;
    });
  }
  
  Widget _buildConfidenceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _eloquencePalette['violet']!.withAlpha(51),
        border: Border.all(
          color: _eloquencePalette['violet']!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: _eloquencePalette['violet']!,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Niveau ${widget.scenario.difficulty}',
            style: TextStyle(
              color: _eloquencePalette['violet']!,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScenarioCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _eloquencePalette['glass']!,
        border: Border.all(
          color: _eloquencePalette['glassAccent']!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _eloquencePalette['navy']!.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du scénario
          Text(
            widget.scenario.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description avec formatting
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                widget.scenario.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withAlpha(230),
                  height: 1.6,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tags de difficulté et conseils
          _buildScenarioTags(),
        ],
      ),
    );
  }
  
  Widget _buildScenarioTags() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildTag(
          label: widget.scenario.difficulty,
          icon: Icons.bar_chart_rounded,
          color: _eloquencePalette['cyan']!,
        ),
        if (widget.scenario.tips.isNotEmpty)
          _buildTag(
            label: '${widget.scenario.tips.length} conseils',
            icon: Icons.lightbulb_rounded,
            color: _eloquencePalette['violet']!,
          ),
        _buildTag(
          label: 'IA Adaptive',
          icon: Icons.smart_toy_rounded,
          color: _eloquencePalette['cyanLight']!,
        ),
      ],
    );
  }
  
  Widget _buildTag({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withAlpha(38),
        border: Border.all(
          color: color.withAlpha(128),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextSupportSelectionPhase() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildEloquenceHeader(),
          const SizedBox(height: 32),
          
          // Sélection de support textuel
          Expanded(
            child: _buildTextSupportOptions(),
          ),
          
          const SizedBox(height: 24),
          
          Consumer(
            builder: (context, ref, child) {
              final provider = ref.watch(confidenceBoostProvider);
              return _buildPhaseProgressButton(
                label: 'Préparer l\'enregistrement',
                icon: Icons.mic_rounded,
                onPressed: provider.currentTextSupport != null
                    ? () => _transitionToPhase(AdaptiveScreenPhase.recordingPreparation)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextSupportOptions() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: confidence_models.SupportType.values.length,
      itemBuilder: (context, index) {
        final supportType = confidence_models.SupportType.values[index];
        return _buildSupportTypeCard(supportType);
      },
    );
  }
  
  Widget _buildSupportTypeCard(confidence_models.SupportType supportType) {
    return Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(confidenceBoostProvider);
        final isSelected = provider.selectedSupportType == supportType;
        final isGenerating = provider.isGeneratingSupport;
        
        return GestureDetector(
          onTap: isGenerating ? null : () => _selectSupportType(supportType),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // CORRECTION : Améliorer le contraste pour les cartes de sélection
              color: isSelected
                  ? _eloquencePalette['violet']!.withAlpha(80)
                  : _eloquencePalette['glass']!,
              border: Border.all(
                color: isSelected
                    ? _eloquencePalette['violet']!
                    : _eloquencePalette['glassAccent']!,
                width: isSelected ? 2 : 1,
              ),
              // Ajout d'une ombre pour améliorer la lisibilité
              boxShadow: [
                BoxShadow(
                  color: _eloquencePalette['navy']!.withAlpha(60),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getSupportTypeIcon(supportType),
                  color: isSelected 
                      ? _eloquencePalette['violet']!
                      : _eloquencePalette['cyan']!,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  _getSupportTypeName(supportType),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isSelected && isGenerating) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_eloquencePalette['violet']!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRecordingPreparationPhase() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildEloquenceHeader(),
          const SizedBox(height: 32),
          
          // Instructions avec le personnage IA
          Expanded(
            child: _buildRecordingInstructions(),
          ),
          
          const SizedBox(height: 24),
          
          _buildPhaseProgressButton(
            label: 'Commencer l\'enregistrement',
            icon: Icons.fiber_manual_record_rounded,
            onPressed: () => _startRecording(),
            isPrimary: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordingInstructions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _eloquencePalette['glass']!,
        border: Border.all(
          color: _eloquencePalette['glassAccent']!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar du personnage IA actif
          _buildAICharacterAvatar(_activeCharacter),
          
          const SizedBox(height: 20),
          
          // Dialogue adaptatif
          _buildAICharacterDialogue(),
          
          const SizedBox(height: 24),
          
          // Support textuel généré
          Expanded(
            child: _buildGeneratedTextSupport(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveRecordingPhase() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A), // Fond sombre Eloquence
      body: SafeArea(
        child: Column(
          children: [
            // HEADER PROPRE ET LISIBLE
            _buildCleanHeader(),
            
            // ZONE CONVERSATION PRINCIPALE (70% de l'écran)
            Expanded(
              flex: 7,
              child: _buildConversationArea(),
            ),
            
            // SUPPORT TEXTUEL CONDITIONNEL (15% si activé)
            if (_shouldShowTextSupport())
              Expanded(
                flex: 2,
                child: _buildCleanTextSupport(),
              ),
            
            // CONTRÔLES CONVERSATION (15% de l'écran)
            Expanded(
              flex: 2,
              child: _buildCleanConversationControls(),
            ),
          ],
        ),
      ),
    );
  }

bool _shouldShowTextSupport() {
  final provider = ref.read(confidenceBoostProvider);
  return provider.selectedSupportType != confidence_models.SupportType.freeImprovisation && provider.selectedSupportType != null;
}

Widget _buildIntelligentTextSupport() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      // CORRECTION CRITIQUE : Utiliser le nouvel arrière-plan pour support textuel
      color: _eloquencePalette['textSupportBg']!,
      border: Border.all(
        color: _eloquencePalette['cyan']!.withAlpha(180),
        width: 1.5,
      ),
      // Ajout d'une ombre pour améliorer la profondeur
      boxShadow: [
        BoxShadow(
          color: _eloquencePalette['navy']!.withAlpha(100),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(confidenceBoostProvider);
        // Correction: Utiliser selectedSupportType
        return _buildAdaptiveTextSupport(provider.selectedSupportType ?? confidence_models.SupportType.fullText);
      },
    ),
  );
}

Widget _buildAdaptiveTextSupport(confidence_models.SupportType supportType) {
  switch (supportType) {
    case confidence_models.SupportType.fullText:
      return _buildFullTextSupport();
    case confidence_models.SupportType.fillInBlanks:
      return _buildGappedTextSupport();
    // Ajout des cas manquants pour être exhaustif
    case confidence_models.SupportType.guidedStructure:
    case confidence_models.SupportType.keywordChallenge:
    case confidence_models.SupportType.freeImprovisation:
    default:
      return const SizedBox.shrink();
  }
}

Widget _buildConversationalRecordingControls() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      // Bouton microphone conversationnel
      _buildConversationalMicButton(),
      
      // Indicateur d'état conversationnel
      _buildConversationStateIndicator(),
      
      // Bouton terminer conversation
      _buildEndConversationButton(),
    ],
  );
}
  
  Widget _buildAnalysisProgressPhase() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildEloquenceHeader(),
          const SizedBox(height: 32),
          
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final provider = ref.watch(confidenceBoostProvider);
                return ScenarioGenerationAnimation(
                  currentStage: provider.currentStageDescription,
                  stageDescription: provider.currentStageDescription,
                  isUsingMobileOptimization: provider.isUsingMobileOptimization,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsPhase() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildEloquenceHeader(),
          const SizedBox(height: 24),
          
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final provider = ref.watch(confidenceBoostProvider);
                return ConfidenceResultsView(
                  session: _createSessionRecord(provider),
                  onRetry: () => _transitionToPhase(AdaptiveScreenPhase.scenarioPresentation),
                  onComplete: () => Navigator.of(context).pop(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGamificationOverlay() {
    return Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(confidenceBoostProvider);
        final gamificationResult = provider.lastGamificationResult;
        
        if (gamificationResult == null || !_shouldShowGamificationOverlay()) {
          return const SizedBox.shrink();
        }
        
        return _buildGamificationAnimation(gamificationResult);
      },
    );
  }
  
  Widget _buildAICharactersOverlay() {
    return SlideTransition(
      position: _aiCharacterSlide,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildAICharacterSelector(),
        ),
      ),
    );
  }
  
  // === MÉTHODES UTILITAIRES ===
  
  void _transitionToPhase(AdaptiveScreenPhase newPhase) {
    setState(() {
      _currentPhase = newPhase;
    });
    
    _mainAnimationController.reset();
    _mainAnimationController.forward();
    
    _logger.i('🎭 Transition vers phase: ${newPhase.name}');
  }
  
  Future<void> _selectSupportType(confidence_models.SupportType supportType) async {
    final provider = ref.read(confidenceBoostProvider);
    await provider.generateTextSupport(
      scenario: widget.scenario,
      type: supportType,
    );
  }
  
  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
    
    _transitionToPhase(AdaptiveScreenPhase.activeRecording);
    
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
    
    _logger.i('🎤 Enregistrement démarré');
  }
  
  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
    
    _transitionToPhase(AdaptiveScreenPhase.analysisInProgress);
    
    // Démarrer l'analyse avec les corrections optimisées
    _startOptimizedAnalysis();
    
    _logger.i('🎤 Enregistrement terminé: ${_recordingDuration.inSeconds}s');
  }
  
  Future<void> _startOptimizedAnalysis() async {
    final provider = ref.read(confidenceBoostProvider);
    final textSupport = provider.currentTextSupport;
    
    if (textSupport == null) return;
    
    try {
      // Utiliser les nouvelles corrections optimisées
      await provider.analyzePerformance(
        scenario: widget.scenario,
        textSupport: textSupport,
        recordingDuration: _recordingDuration,
        audioData: null, // Simulated for now
      );
      
      _transitionToPhase(AdaptiveScreenPhase.resultsAndGamification);
      
      // Animer la gamification si résultats disponibles
      if (provider.lastGamificationResult != null) {
        _animateGamificationEntry();
      }
      
    } catch (e) {
      _logger.e('Erreur lors de l\'analyse: $e');
    }
  }
  
  void _animateGamificationEntry() {
    _gamificationController.forward();
  }
  
  bool _shouldShowGamificationOverlay() {
    return _currentPhase == AdaptiveScreenPhase.resultsAndGamification;
  }
  
  /// Créer un SessionRecord à partir des données du provider
  SessionRecord _createSessionRecord(ConfidenceBoostProvider provider) {
    final analysis = provider.lastAnalysis;
    final gamificationResult = provider.lastGamificationResult;
    final textSupport = provider.currentTextSupport;
    
    // Valeurs par défaut si les données sont manquantes
    final defaultAnalysis = analysis ?? confidence_models.ConfidenceAnalysis(
      overallScore: 70.0,
      confidenceScore: 0.70,
      fluencyScore: 0.65,
      clarityScore: 0.75,
      energyScore: 0.70,
      feedback: 'Session complétée avec succès !',
    );
    
    final defaultTextSupport = textSupport ?? confidence_models.TextSupport(
      type: confidence_models.SupportType.freeImprovisation,
      content: 'Support par défaut',
      suggestedWords: [],
    );
    
    return SessionRecord(
      userId: 'current_user', // TODO: Récupérer l'ID utilisateur réel
      analysis: defaultAnalysis,
      scenario: widget.scenario,
      textSupport: defaultTextSupport,
      earnedXP: gamificationResult?.earnedXP ?? 50,
      newBadges: gamificationResult?.newBadges ?? [],
      timestamp: DateTime.now(),
      sessionDuration: _recordingDuration,
    );
  }
  
  // === WIDGETS HELPERS ===
  
  Widget _buildPhaseProgressButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: onPressed != null
            ? LinearGradient(
                colors: isPrimary
                    ? [_eloquencePalette['violet']!, _eloquencePalette['violetLight']!]
                    : [_eloquencePalette['cyan']!, _eloquencePalette['cyanLight']!],
              )
            : null,
        color: onPressed == null ? Colors.grey.withAlpha(77) : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
  
  // Méthodes de style et helpers
  IconData _getSupportTypeIcon(confidence_models.SupportType type) {
    switch (type) {
      case confidence_models.SupportType.fullText:
        return Icons.text_snippet_rounded;
      case confidence_models.SupportType.fillInBlanks:
        return Icons.text_fields_rounded;
      case confidence_models.SupportType.guidedStructure:
        return Icons.account_tree_rounded;
      case confidence_models.SupportType.keywordChallenge:
        return Icons.key_rounded;
      case confidence_models.SupportType.freeImprovisation:
        return Icons.auto_awesome_rounded;
    }
  }
  
  String _getSupportTypeName(confidence_models.SupportType type) {
    switch (type) {
      case confidence_models.SupportType.fullText:
        return 'Texte Complet';
      case confidence_models.SupportType.fillInBlanks:
        return 'Texte à Trous';
      case confidence_models.SupportType.guidedStructure:
        return 'Structure Guidée';
      case confidence_models.SupportType.keywordChallenge:
        return 'Défi de Mots-Clés';
      case confidence_models.SupportType.freeImprovisation:
        return 'Improvisation Libre';
    }
  }
  
  // Widgets temporaires pour les fonctionnalités à implémenter
  Widget _buildAICharacterAvatar(ai_models.AICharacterType character) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: _eloquencePalette['violet']!,
      child: Icon(
        character == ai_models.AICharacterType.thomas 
            ? Icons.business_rounded 
            : Icons.person_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
  
  Widget _buildAICharacterDialogue() {
    final message = _activeCharacter == ai_models.AICharacterType.thomas
        ? "Excellent choix de scénario ! En tant que manager, je recommande de vous concentrer sur la clarté et la confiance."
        : "C'est un scénario intéressant ! En tant que cliente, j'apprécie quand on me parle avec assurance et empathie.";
        
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // CORRECTION : Utiliser le nouvel arrière-plan pour dialogues
        color: _eloquencePalette['dialogueBg']!,
        border: Border.all(
          color: _eloquencePalette['cyan']!.withAlpha(120),
          width: 1,
        ),
        // Ajout d'une ombre pour améliorer la lisibilité
        boxShadow: [
          BoxShadow(
            color: _eloquencePalette['navy']!.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontStyle: FontStyle.italic,
          // Améliorer la lisibilité avec une hauteur de ligne optimisée
          height: 1.5,
        ),
      ),
    );
  }
  
  Widget _buildGeneratedTextSupport() {
    return Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(confidenceBoostProvider);
        final textSupport = provider.currentTextSupport;
        
        if (textSupport == null) {
          return const Center(
            child: Text(
              'Sélectionnez un type de support textuel',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        
        // CORRECTION CRITIQUE : Système de fallback d'urgence pour garantir l'affichage du contenu
        final supportContent = textSupport.content.isEmpty
            ? _getEmergencyFallbackContent(textSupport.type)
            : textSupport.content;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // CORRECTION : Utiliser l'arrière-plan optimisé pour le support textuel
            color: _eloquencePalette['textSupportBg']!,
            border: Border.all(
              color: _eloquencePalette['cyan']!.withAlpha(150),
              width: 1,
            ),
            // Ajout d'une ombre pour la profondeur
            boxShadow: [
              BoxShadow(
                color: _eloquencePalette['navy']!.withAlpha(120),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Text(
              supportContent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6, // Améliorer l'interlignage pour la lisibilité
                fontWeight: FontWeight.w400, // Assurer une épaisseur de police suffisante
                letterSpacing: 0.2, // Améliorer l'espacement des lettres
              ),
            ),
          ),
        );
      },
    );
  }

  /// Système de fallback d'urgence pour garantir l'affichage de contenu adaptatif
  /// même si le TextSupportGenerator échoue ou retourne du contenu vide
  String _getEmergencyFallbackContent(confidence_models.SupportType type) {
    final scenarioTitle = widget.scenario.title;
    final scenarioContext = widget.scenario.description.length > 100
        ? widget.scenario.description.substring(0, 100) + "..."
        : widget.scenario.description;
    
    switch (type) {
      case confidence_models.SupportType.fullText:
        return '''Bienvenue dans cet exercice : "$scenarioTitle"

$scenarioContext

Pour cet exercice, concentrez-vous sur :
• Exprimer vos idées avec clarté et confiance
• Adapter votre discours au contexte présenté
• Maintenir un ton professionnel et engageant
• Structurer votre intervention de manière logique

Commencez par vous présenter brièvement, puis développez votre réponse en vous appuyant sur le scénario proposé. N'hésitez pas à donner des exemples concrets pour illustrer vos propos.

Bonne chance !''';

      case confidence_models.SupportType.fillInBlanks:
        return '''Exercice : "$scenarioTitle"

Complétez les phrases suivantes avec vos propres mots :

"Dans cette situation, je pense que _________ serait la meilleure approche car _________."

"Mon expérience m'a appris que _________, c'est pourquoi je propose de _________."

"Pour résoudre ce défi, nous devons d'abord _________, puis _________ et finalement _________."

"Ce qui me semble le plus important ici, c'est _________ parce que _________."

Utilisez ces structures pour développer votre réponse complète !''';

      case confidence_models.SupportType.guidedStructure:
        return '''Plan pour "$scenarioTitle" :

1. **Introduction (30 secondes)**
   - Présentez-vous brièvement
   - Annoncez votre approche

2. **Développement (60-90 secondes)**
   - Point principal n°1 : Votre analyse de la situation
   - Point principal n°2 : Votre proposition de solution
   - Point principal n°3 : Les bénéfices attendus

3. **Conclusion (20-30 secondes)**
   - Résumez votre message clé
   - Proposez une action concrète

**Conseils :**
• Gardez un débit naturel
• Utilisez des exemples
• Montrez votre conviction''';

      case confidence_models.SupportType.keywordChallenge:
        return '''Défi de mots-clés pour "$scenarioTitle" :

**Mots obligatoires à intégrer :**
• INNOVATION
• COLLABORATION
• RÉSULTATS
• CONFIANCE
• SOLUTION

**Mission :**
Créez un discours de 2 minutes qui intègre naturellement ces 5 mots-clés tout en répondant au scénario présenté.

**Astuce :** Préparez mentalement comment relier chaque mot-clé au contexte avant de commencer à parler.

C'est un excellent exercice pour développer votre agilité verbale !''';

      case confidence_models.SupportType.freeImprovisation:
        return '''Improvisation libre sur "$scenarioTitle" !

**Votre mission :** Laissez libre cours à votre créativité et exprimez-vous naturellement sur ce sujet.

**Quelques suggestions pour vous lancer :**
• Commencez par votre première réaction au scénario
• Partagez une anecdote personnelle si pertinente
• Exprimez votre point de vue unique
• N'ayez pas peur des silences, ils font partie du discours

**Rappel :** Il n'y a pas de "bonne" ou "mauvaise" réponse. L'objectif est de vous exprimer avec authenticité et confiance.

Marie sera là pour vous accompagner pendant votre performance !''';
    }
  }
  
  Widget _buildRecordingTimer() {
    return Text(
      '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: _eloquencePalette['cyan']!,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
  
  Widget _buildSoundWaveVisualizer() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _eloquencePalette['glass']!,
      ),
      child: const Center(
        child: Text(
          'Visualisateur d\'onde sonore',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
  
  Widget _buildGamificationAnimation(gamification.GamificationResult result) {
    return const Center(
      child: Text(
        'Animation de gamification',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
  
  Widget _buildAICharacterSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCharacterButton(ai_models.AICharacterType.thomas),
        const SizedBox(width: 8),
        _buildCharacterButton(ai_models.AICharacterType.marie),
      ],
    );
  }
  
  Widget _buildCharacterButton(ai_models.AICharacterType character) {
    final isActive = _activeCharacter == character;
    return GestureDetector(
      onTap: () => setState(() => _activeCharacter = character),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive 
              ? _eloquencePalette['violet']! 
              : _eloquencePalette['glass']!,
        ),
        child: Icon(
          character == ai_models.AICharacterType.thomas 
              ? Icons.business_rounded 
              : Icons.person_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _mainAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _aiCharacterController.dispose();
    _gamificationController.dispose();
    _recordingTimer?.cancel();
    _conversationScrollController.dispose();
    
    // Nettoyer les subscriptions ConversationManager
    _conversationEventsSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    _metricsSubscription?.cancel();
    _conversationManager?.dispose();
    
    super.dispose();
  }

  // === CALLBACKS CONVERSATIONMANAGER ===
  
  /// Gère les événements du ConversationManager
  void _handleConversationEvent(ConversationEvent event) {
    _logger.d('📡 Événement conversation: ${event.type.name}');
    
    switch (event.type) {
      case ConversationEventType.initialized:
        _logger.i('✅ ConversationManager initialisé');
        break;
        
      case ConversationEventType.conversationStarted:
        setState(() {
          _isConversationInitialized = true;
        });
        _logger.i('🎬 Conversation démarrée');
        break;
        
      case ConversationEventType.listeningStarted:
        setState(() {
          _isUserSpeaking = true;
          _isAISpeaking = false;
        });
        break;
        
      case ConversationEventType.processingStarted:
        setState(() {
          _isUserSpeaking = false;
          _isAISpeaking = true;
        });
        break;
        
      case ConversationEventType.aiMessage:
        _handleAIMessage(event.data);
        break;
        
      case ConversationEventType.userMessage:
        _handleUserMessage(event.data);
        break;
        
      case ConversationEventType.stateChanged:
        _handleConversationStateChange(event.data);
        break;
        
      case ConversationEventType.error:
        _handleConversationError(event.data);
        break;
        
      default:
        _logger.d('Événement non géré: ${event.type.name}');
    }
  }
  
  /// Gère les mises à jour de transcription temps réel
  void _handleTranscriptionUpdate(TranscriptionSegment segment) {
    setState(() {
      if (segment.isFinal) {
        // Transcription finale - ajouter comme message utilisateur
        _addUserMessage(segment.text);
        _currentTranscription = null;
      } else {
        // Transcription en cours - mettre à jour l'affichage
        _currentTranscription = segment.text;
      }
    });
    
    _logger.d('📝 Transcription: "${segment.text}" (final: ${segment.isFinal})');
  }
  
  /// Gère les mises à jour de métriques de conversation
  void _handleMetricsUpdate(ConversationMetrics metrics) {
    _logger.d('📊 Métriques: ${metrics.turnCount} tours, ${metrics.averageResponseTime.inMilliseconds}ms moyenne');
    // TODO: Mettre à jour l'interface avec les métriques si nécessaire
  }
  
  /// Gère les messages IA reçus du ConversationManager
  void _handleAIMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      final character = data['character'] as String?;
      final emotion = data['emotion'] as String?;
      
      if (message != null) {
        final aiMessage = ConversationMessage(
          text: message,
          role: ConversationRole.assistant,
          metadata: {
            'character': character ?? _activeCharacter.name,
            'emotion': emotion ?? 'neutral',
          },
        );
        
        setState(() {
          _conversationMessages.add(aiMessage);
          _isAISpeaking = false;
        });
        
        _scrollToBottom();
      }
    }
  }
  
  /// Gère les messages utilisateur reçus du ConversationManager
  void _handleUserMessage(dynamic data) {
    if (data is String) {
      _addUserMessage(data);
    }
  }
  
  /// Gère les changements d'état de conversation
  void _handleConversationStateChange(dynamic data) {
    if (data is String) {
      _logger.d('🔄 État conversation: $data');
      // Mettre à jour l'interface selon l'état
      switch (data) {
        case 'userSpeaking':
          setState(() {
            _isUserSpeaking = true;
            _isAISpeaking = false;
          });
          break;
        case 'aiSpeaking':
          setState(() {
            _isUserSpeaking = false;
            _isAISpeaking = true;
          });
          break;
        case 'aiThinking':
          setState(() {
            _isUserSpeaking = false;
            _isAISpeaking = true;
          });
          break;
        case 'ready':
          setState(() {
            _isUserSpeaking = false;
            _isAISpeaking = false;
          });
          break;
      }
    }
  }

  // === MÉTHODES DE GESTION CONVERSATIONNELLE (implémentations de base) ===

  void _onMessageTap() {
    _logger.d('Message tap');
  }

  Widget _buildFullTextSupport() {
    return Consumer(
      builder: (context, ref, child) {
        final currentPhaseText = _getCurrentPhaseText();
        return _buildSupportContainer(
          title: 'Support textuel',
          icon: Icons.text_snippet_outlined,
          color: _eloquencePalette['cyan']!,
          child: Text(
            currentPhaseText,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        );
      },
    );
  }

  Widget _buildGappedTextSupport() {
    return Consumer(
      builder: (context, ref, child) {
        final currentPhaseText = _getCurrentPhaseText();
        final gappedText = _createGappedText(currentPhaseText);
        return _buildSupportContainer(
          title: 'Texte à compléter',
          icon: Icons.edit_outlined,
          color: _eloquencePalette['violet']!,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              children: _buildGappedTextSpans(gappedText),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSupportContainer({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ],
    );
  }

  String _getCurrentPhaseText() {
    final messageCount = _conversationMessages.length;
    if (messageCount <= 2) return _getIntroductionText();
    if (messageCount <= 6) return _getDevelopmentText();
    return _getConclusionText();
  }

  String _getIntroductionText() {
    switch (widget.scenario.type) {
      case confidence_models.ConfidenceScenarioType.presentation:
        return "Commencez par vous présenter brièvement, puis introduisez le sujet de votre présentation. Captez l'attention de Marie dès les premiers mots.";
      case confidence_models.ConfidenceScenarioType.interview:
        return "Présentez-vous de manière professionnelle. Mentionnez votre parcours, vos compétences clés et votre motivation pour ce poste.";
      default:
        return "Commencez par une introduction claire et engageante. Établissez le contact avec votre interlocuteur.";
    }
  }

  String _getDevelopmentText() => "Développez votre point principal. Fournissez des exemples concrets et structurez votre argumentation.";
  String _getConclusionText() => "Concluez votre intervention. Résumez les points clés et terminez sur une note positive et mémorable.";

  String _createGappedText(String fullText) {
    return fullText
        .replaceAll(RegExp(r'\b(présenter|expliquer|mentionner)\b'), '______')
        .replaceAll(RegExp(r'\b(compétences|motivation|expérience)\b'), '______');
  }

  List<TextSpan> _buildGappedTextSpans(String gappedText) {
    // CORRECTION CRITIQUE : Améliorer la visibilité des espaces à compléter
    final List<TextSpan> spans = [];
    final parts = gappedText.split('______');
    
    for (int i = 0; i < parts.length; i++) {
      // Ajouter le texte normal
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ));
      }
      
      // Ajouter l'espace à compléter avec un style distinctif
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: '______',
          style: TextStyle(
            color: _eloquencePalette['cyan']!,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.bold,
            backgroundColor: _eloquencePalette['navy']!.withAlpha(120),
            decoration: TextDecoration.underline,
            decorationColor: _eloquencePalette['cyan']!,
          ),
        ));
      }
    }
    
    return spans;
  }

  Widget _buildConversationalMicButton() {
    return AnimatedMicrophoneButton(
      isRecording: _isRecording,
      onPressed: _isRecording ? _stopConversationalRecording : _startConversationalRecording,
    );
  }

  Widget _buildConversationStateIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _eloquencePalette['glass']!,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _isAISpeaking ? 'IA parle...' : (_isUserSpeaking ? 'Vous parlez...' : 'Prêt'),
        style: TextStyle(color: _eloquencePalette['cyan'], fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEndConversationButton() {
    return ElevatedButton(
      onPressed: _stopRecording, // Reuse stop logic for now
      child: const Text('Terminer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _eloquencePalette['violet'],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _startConversationalRecording() async {
    if (!_isConversationInitialized || _conversationManager == null) {
      _logger.w('⚠️ ConversationManager non initialisé, initialisation...');
      await _initializeRealTimeConversation();
    }
    
    setState(() {
      _isUserSpeaking = true;
      _isRecording = true;
    });
    
    _logger.i('🎤 Démarrage écoute conversationnelle - ConversationManager gère automatiquement');
    // Le ConversationManager démarre automatiquement l'écoute après startConversation()
  }

  void _stopConversationalRecording() {
    setState(() {
      _isUserSpeaking = false;
      _isRecording = false;
    });
    
    // Le ConversationManager gère automatiquement la fin de l'écoute
    // et la génération de la réponse IA via les streams
    _logger.i('🛑 Arrêt écoute conversationnelle');
  }

  /// Initialise la conversation temps réel avec ConversationManager
  Future<void> _initializeRealTimeConversation() async {
    if (_conversationManager == null) {
      _logger.e('❌ ConversationManager null, impossible d\'initialiser');
      return;
    }
    
    try {
      // Obtenir les vraies clés LiveKit depuis l'API backend
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/livekit/token'),
        headers: {'Content-Type': 'application/json'},
      );
      
      String livekitUrl = 'ws://192.168.1.44:7880';
      String livekitToken = 'temp_token';
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        livekitUrl = data['url'] ?? livekitUrl;
        livekitToken = data['token'] ?? livekitToken;
        _logger.i('✅ Clés LiveKit obtenues depuis backend');
      } else {
        _logger.w('⚠️ Utilisation clés LiveKit par défaut');
      }
      
      final success = await _conversationManager!.initializeConversation(
        scenario: widget.scenario,
        userProfile: ai_models.UserAdaptiveProfile(
          userId: 'current_user',
          confidenceLevel: 5,
          experienceLevel: 5,
          strengths: [],
          weaknesses: [],
          preferredTopics: [],
          preferredCharacter: _activeCharacter,
          lastSessionDate: DateTime.now(),
          totalSessions: 0,
          averageScore: 0.0,
        ),
        livekitUrl: livekitUrl,
        livekitToken: livekitToken,
        preferredCharacter: _activeCharacter,
      );
      
      if (success) {
        _isConversationInitialized = true;
        
        // Démarrer la conversation
        await _conversationManager!.startConversation();
        _logger.i('✅ Conversation temps réel initialisée et démarrée');
        
        // Mettre à jour l'interface avec le message d'introduction
        setState(() {
          _currentPhase = AdaptiveScreenPhase.activeRecording;
        });
        
      } else {
        _logger.e('❌ Échec initialisation conversation temps réel');
      }
      
    } catch (e) {
      _logger.e('❌ Erreur initialisation conversation: $e');
      _handleConversationError(e);
    }
  }

  void _addUserMessage(String text) {
    final userMessage = ConversationMessage(
      text: text,
      role: ConversationRole.user,
    );
    setState(() {
      _conversationMessages.add(userMessage);
      _isUserSpeaking = false;
      _currentTranscription = null;
    });
    _scrollToBottom();
  }

  void _generateAIResponse(String userInput) async {
    setState(() { _isAISpeaking = true; });
    try {
      final conversationManager = ref.read(conversationManagerProvider);
      final aiResponse = await conversationManager.generateResponse(
        userInput: userInput,
        character: _activeCharacter,
        scenario: widget.scenario,
        conversationHistory: [], // TODO: Map history
      );
      
      final aiMessage = ConversationMessage(
        text: aiResponse.text,
        role: ConversationRole.assistant,
        metadata: {'character': _activeCharacter.name},
      );
      
      setState(() {
        _conversationMessages.add(aiMessage);
        _isAISpeaking = false;
      });
      _scrollToBottom();
      
      if (aiResponse.audioUrl != null) {
        // _playAIAudio(aiResponse.audioUrl!);
      }
    } catch (e) {
      _handleConversationError(e);
    }
  }

  void _handleConversationError(Object e) {
    _logger.e("Erreur de conversation: $e");
    setState(() { _isAISpeaking = false; });
    final errorMessage = ConversationMessage(
      text: "Désolé, une erreur est survenue. Veuillez réessayer.",
      role: ConversationRole.assistant,
      metadata: {'error': true},
    );
    setState(() { _conversationMessages.add(errorMessage); });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_conversationScrollController.hasClients) {
        _conversationScrollController.animateTo(
          _conversationScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildCleanConversationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton Pause/Reprendre (56x56)
          _buildPauseButton(),
          
          // Bouton Microphone Principal (80x80)
          _buildMainMicrophoneButton(),
          
          // Bouton Terminer (56x56)
          _buildEndButton(),
        ],
      ),
    );
  }

  Widget _buildMainMicrophoneButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopConversationalRecording : _startConversationalRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isRecording
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? const Color(0xFFEF4444) : const Color(0xFF00D4FF))
                  .withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    final isPaused = !_isRecording && _conversationMessages.length > 1;
    
    return GestureDetector(
      onTap: () {
        // TODO: Implémenter logique pause/reprendre
        _logger.d('Pause/Reprendre conversation');
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1F2E),
          border: Border.all(
            color: const Color(0xFFF59E0B),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: const Color(0xFFF59E0B),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEndButton() {
    return GestureDetector(
      onTap: () {
        _stopRecording();
        _logger.d('Terminer conversation');
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1F2E),
          border: Border.all(
            color: const Color(0xFF8B5CF6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.stop_circle_outlined,
          color: Color(0xFF8B5CF6),
          size: 24,
        ),
      ),
    );
  }
}


// === ÉNUMÉRATIONS ===

// ENUM POUR LES PHASES DE CONVERSATION
enum BoostConfidencePhase {
  initializing,
  ready,
  recording,
  conversing,
  analyzing,
  completed,
  error
}

enum AdaptiveScreenPhase {
  scenarioPresentation,
  textSupportSelection,
  recordingPreparation,
  activeRecording,
  analysisInProgress,
  resultsAndGamification,
}

extension AdaptiveScreenPhaseExtension on AdaptiveScreenPhase {
  String get name {
    switch (this) {
      case AdaptiveScreenPhase.scenarioPresentation:
        return 'Présentation du scénario';
      case AdaptiveScreenPhase.textSupportSelection:
        return 'Sélection du support';
      case AdaptiveScreenPhase.recordingPreparation:
        return 'Préparation enregistrement';
      case AdaptiveScreenPhase.activeRecording:
        return 'Enregistrement actif';
      case AdaptiveScreenPhase.analysisInProgress:
        return 'Analyse en cours';
      case AdaptiveScreenPhase.resultsAndGamification:
        return 'Résultats et gamification';
    }
  }
}
