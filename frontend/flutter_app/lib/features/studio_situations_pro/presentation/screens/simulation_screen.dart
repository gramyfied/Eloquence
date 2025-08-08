import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../data/models/simulation_models.dart';
import '../../data/services/studio_situations_pro_service.dart';
import '../widgets/multi_agent_avatar_widget.dart' hide ActiveSpeakerIndicator;
import '../widgets/animated_multi_agent_avatar_grid.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  final SimulationType simulationType;
  final String? userName;
  final String? userSubject;

  const SimulationScreen({
    Key? key,
    required this.simulationType,
    this.userName,
    this.userSubject,
  }) : super(key: key);

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> with TickerProviderStateMixin {
  late Timer _timer;
  int _seconds = 0;
  bool _isPaused = false;
  bool _isRecording = false;
  
  // Multi-agents state
  List<AgentInfo> _agents = [];
  String? _activeSpeakerId;
  String _activeSpeakerName = '';
  StreamSubscription<MultiAgentEvent>? _eventSubscription;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _entranceController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideInAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeMultiAgents();

    // Initialiser les animations
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowAnimation = Tween<double>(begin: 5.0, end: 15.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    
    _slideInAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));
    
    // Démarrer les animations
    _glowController.repeat(reverse: true);
    _entranceController.forward();
  }
  
  void _initializeMultiAgents() async {
    final service = ref.read(studioSituationsProServiceProvider);
    
    // Initialiser la simulation avec les données utilisateur
    await service.startSimulation(
      widget.simulationType,
      userName: widget.userName ?? 'Participant',
      userSubject: widget.userSubject ?? 'Sujet non défini',
    );
    
    // Écouter les événements multi-agents
    _eventSubscription = service.multiAgentEvents.listen((event) {
      // ✅ CORRECTION CRITIQUE : Vérifier si le widget est encore monté
      if (!mounted) return;
      
      setState(() {
        if (event is AgentJoinedEvent) {
          _agents.add(event.agent);
        } else if (event is AgentLeftEvent) {
          _agents.removeWhere((a) => a.id == event.agentId);
        } else if (event is SpeakerChangedEvent) {
          _activeSpeakerId = event.agentId;
          _activeSpeakerName = _agents.firstWhere(
            (a) => a.id == event.agentId,
            orElse: () => AgentInfo(
              id: '',
              name: 'Inconnu',
              role: '',
              avatarPath: '',
              isActive: false,
              participationRate: 0.0,
            ),
          ).name;
        } else if (event is AgentStateUpdateEvent) {
          final index = _agents.indexWhere((a) => a.id == event.agentId);
          if (index != -1) {
            _agents[index] = AgentInfo(
              id: event.agentId,
              name: _agents[index].name,
              role: _agents[index].role,
              avatarPath: _agents[index].avatarPath,
              isActive: event.isActive,
              participationRate: event.participationRate,
            );
          }
        }
      });
    });
    
    // Obtenir les agents initiaux pour ce type de simulation
    final initialAgents = service.getAgentsForSimulation(widget.simulationType);
    
    // ✅ CORRECTION CRITIQUE : Vérifier si le widget est encore monté
    if (!mounted) return;
    
    setState(() {
      _agents = initialAgents;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _eventSubscription?.cancel();
    _glowController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // ✅ CORRECTION CRITIQUE : Vérifier si le widget est encore monté
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (!_isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _togglePause() {
    // ✅ CORRECTION CRITIQUE : Vérifier si le widget est encore monté
    if (!mounted) return;
    
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _toggleRecording() async {
    // ✅ CORRECTION CRITIQUE : Vérifier si le widget est encore monté
    if (!mounted) return;
    
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
      }
    });
    
    // Démarrer/arrêter l'enregistrement LiveKit
    if (_isRecording) {
      final service = ref.read(studioSituationsProServiceProvider);
      await service.startRecording();
    } else {
      final service = ref.read(studioSituationsProServiceProvider);
      await service.stopRecording();
    }
  }
  
  void _onAgentTap(AgentInfo agent) {
    // Gérer le tap sur un agent (par exemple, forcer la prise de parole)
    final service = ref.read(studioSituationsProServiceProvider);
    service.requestAgentSpeaker(agent.id);
  }

  String get _timerText {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceTheme.navy,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildMultiAgentSection(),
            _buildMetrics(),
            const Spacer(),
            if (_activeSpeakerName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EloquenceTheme.spacingMd,
                  vertical: EloquenceTheme.spacingSm,
                ),
                child: Center(
                  child: ActiveSpeakerIndicator(
                    speakerName: _activeSpeakerName,
                    color: EloquenceTheme.cyan,
                  ),
                ),
              ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        widget.simulationType.toDisplayString(),
        style: EloquenceTheme.headline3,
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: EloquenceTheme.spacingMd),
          child: Center(
            child: Text(
              _timerText,
              style: EloquenceTheme.bodyLarge.copyWith(color: EloquenceTheme.cyan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiAgentSection() {
    return SlideTransition(
      position: _slideInAnimation,
      child: FadeTransition(
        opacity: _fadeInAnimation,
        child: Container(
          height: 320,
          margin: const EdgeInsets.all(EloquenceTheme.spacingMd),
          child: Stack(
            children: [
              // Image d'environnement avec effet de parallaxe
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  decoration: BoxDecoration(
                    borderRadius: EloquenceTheme.borderRadiusLarge,
                    image: DecorationImage(
                      image: AssetImage(_getEnvironmentImage()),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),
              // Overlay glassmorphisme avec animation
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  decoration: BoxDecoration(
                    borderRadius: EloquenceTheme.borderRadiusLarge,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        EloquenceTheme.navy.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Grille d'avatars avec animations individuelles
              if (_agents.isNotEmpty)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
                    child: AnimatedMultiAgentAvatarGrid(
                      agents: _agents,
                      activeSpeakerId: _activeSpeakerId,
                      onAgentTap: _onAgentTap,
                      animationController: _entranceController,
                    ),
                  ),
                ),
              
              // Loading avec animation
              if (_agents.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: EloquenceTheme.cyan,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connexion aux agents...',
                        style: EloquenceTheme.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEnvironmentImage() {
    switch (widget.simulationType) {
      case SimulationType.entretienEmbauche:
        return 'assets/images/avatars/environnement_bureau_entretien.png';
      case SimulationType.debatPlateau:
        return 'assets/images/avatars/environnement_plateau_tv.png';
      case SimulationType.reunionDirection:
        return 'assets/images/avatars/environnement_salle_reunion.png';
      case SimulationType.conferenceVente:
        return 'assets/images/avatars/environnement_salle_conference.png';
      case SimulationType.conferencePublique:
        return 'assets/images/avatars/environnement_auditorium.png';
      case SimulationType.jobInterview:
        return 'assets/images/avatars/environnement_bureau_entretien.png';
      case SimulationType.salesPitch:
        return 'assets/images/avatars/environnement_salle_conference.png';
      case SimulationType.publicSpeaking:
        return 'assets/images/avatars/environnement_auditorium.png';
      case SimulationType.difficultConversation:
        return 'assets/images/avatars/environnement_bureau_entretien.png';
      case SimulationType.negotiation:
        return 'assets/images/avatars/environnement_salle_reunion.png';
      default:
        return 'assets/images/avatars/environnement_bureau_entretien.png';
    }
  }

  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EloquenceTheme.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricCard("Confiance", "84", EloquenceTheme.cyan),
          _buildMetricCard("Concision", "76", EloquenceTheme.violet),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: EloquenceTheme.headline1.copyWith(color: color, fontSize: 48),
        ),
        const SizedBox(height: EloquenceTheme.spacingXs),
        Text(
          title.toUpperCase(),
          style: EloquenceTheme.bodySmall.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: EloquenceTheme.spacingLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 32),
            onPressed: _togglePause,
          ),
          _buildMicButton(),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.redAccent, size: 32),
            onPressed: () async {
              _timer.cancel();
              // Arrêter la simulation
              final service = ref.read(studioSituationsProServiceProvider);
              await service.endSimulation();
              if (mounted) {
                context.pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EloquenceTheme.cyan,
          boxShadow: _isRecording ? [
            BoxShadow(
              color: EloquenceTheme.violet.withOpacity(0.7),
              blurRadius: _glowAnimation.value,
              spreadRadius: _glowAnimation.value / 2,
            ),
            BoxShadow(
              color: EloquenceTheme.cyan.withOpacity(0.5),
              blurRadius: _glowAnimation.value * 2,
              spreadRadius: _glowAnimation.value,
            ),
          ] : [],
        ),
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}
