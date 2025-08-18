import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import '../models/simulation_models.dart';
import 'studio_livekit_service.dart';
import '../../../../core/utils/unified_logger_service.dart';
import '../../../../core/config/network_config.dart';

/// Événements multi-agents
abstract class MultiAgentEvent {}

class AgentJoinedEvent extends MultiAgentEvent {
  final AgentInfo agent;
  AgentJoinedEvent(this.agent);
}

class AgentLeftEvent extends MultiAgentEvent {
  final String agentId;
  AgentLeftEvent(this.agentId);
}

class SpeakerChangedEvent extends MultiAgentEvent {
  final String agentId;
  SpeakerChangedEvent(this.agentId);
}

class AgentStateUpdateEvent extends MultiAgentEvent {
  final String agentId;
  final bool isActive;
  final double participationRate;
  
  AgentStateUpdateEvent({
    required this.agentId,
    required this.isActive,
    required this.participationRate,
  });
}

/// Information sur un agent actif dans la simulation
class AgentInfo {
  final String id;
  final String name;
  final String role;
  final String avatarPath;
  final bool isActive;
  final double participationRate;
  
  const AgentInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarPath,
    this.isActive = false,
    this.participationRate = 0.0,
  });
  
  AgentInfo copyWith({
    String? id,
    String? name,
    String? role,
    String? avatarPath,
    bool? isActive,
    double? participationRate,
  }) {
    return AgentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      isActive: isActive ?? this.isActive,
      participationRate: participationRate ?? this.participationRate,
    );
  }
}

/// Message dans la conversation
class ConversationMessage {
  final String speakerId;
  final String speakerName;
  final String content;
  final DateTime timestamp;
  final bool isUser;
  final bool isReaction;
  
  const ConversationMessage({
    required this.speakerId,
    required this.speakerName,
    required this.content,
    required this.timestamp,
    this.isUser = false,
    this.isReaction = false,
  });
}

/// Métriques de performance
class PerformanceMetrics {
  final double clarity;
  final double confidence;
  final double engagement;
  final double fluency;
  final int totalInteractions;
  final Duration sessionDuration;
  
  const PerformanceMetrics({
    this.clarity = 0.0,
    this.confidence = 0.0,
    this.engagement = 0.0,
    this.fluency = 0.0,
    this.totalInteractions = 0,
    this.sessionDuration = Duration.zero,
  });
  
  PerformanceMetrics copyWith({
    double? clarity,
    double? confidence,
    double? engagement,
    double? fluency,
    int? totalInteractions,
    Duration? sessionDuration,
  }) {
    return PerformanceMetrics(
      clarity: clarity ?? this.clarity,
      confidence: confidence ?? this.confidence,
      engagement: engagement ?? this.engagement,
      fluency: fluency ?? this.fluency,
      totalInteractions: totalInteractions ?? this.totalInteractions,
      sessionDuration: sessionDuration ?? this.sessionDuration,
    );
  }
}

/// Service principal pour gérer les simulations Studio Situations Pro
class StudioSituationsProService extends ChangeNotifier {
  final StudioLiveKitService _livekitService;
  
  // État de la simulation
  SimulationType? _currentSimulation;
  List<AgentInfo> _activeAgents = [];
  String? _currentSpeaker;
  List<ConversationMessage> _conversationHistory = [];
  PerformanceMetrics _metrics = const PerformanceMetrics();
  DateTime? _sessionStartTime;
  bool _isRecording = false;
  bool _isSessionActive = false;
  
  // Stream controller pour les événements multi-agents
  final _multiAgentEventController = StreamController<MultiAgentEvent>.broadcast();
  Stream<MultiAgentEvent> get multiAgentEvents => _multiAgentEventController.stream;
  
  // Subscriptions
  StreamSubscription? _dataSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  
  // Timer pour les métriques
  Timer? _metricsTimer;
  
  StudioSituationsProService(this._livekitService);
  
  // Configuration des simulations avec leurs agents et vrais avatars
  static const Map<SimulationType, List<AgentInfo>> _simulationAgents = {
    SimulationType.debatPlateau: [
      AgentInfo(
        id: 'animateur_principal',
        name: 'Michel Dubois',
        role: 'Animateur TV',
        avatarPath: 'assets/images/avatars/avatar_animateur_tv_homme_caucasien.png',
      ),
      AgentInfo(
        id: 'journaliste_contradicteur',
        name: 'Sarah Johnson',
        role: 'Journaliste',
        avatarPath: 'assets/images/avatars/avatar_journaliste_femme_asiatique.png',
      ),
      AgentInfo(
        id: 'expert_specialise',
        name: 'Marcus Thompson',
        role: 'Expert',
        avatarPath: 'assets/images/avatars/avatar_expert_homme_africain.png',
      ),
    ],
    SimulationType.entretienEmbauche: [
      AgentInfo(
        id: 'manager_rh',
        name: 'Hiroshi Tanaka',
        role: 'Manager RH',
        avatarPath: 'assets/images/avatars/avatar_rh_homme_asiatique.png',
      ),
      AgentInfo(
        id: 'expert_technique',
        name: 'Carmen Rodriguez',
        role: 'Expert Technique',
        avatarPath: 'assets/images/avatars/avatar_rh_femme_hispanique.png',
      ),
    ],
    SimulationType.reunionDirection: [
      AgentInfo(
        id: 'pdg',
        name: 'Catherine Williams',
        role: 'PDG',
        avatarPath: 'assets/images/avatars/avatar_pdg_femme_caucasienne.png',
      ),
      AgentInfo(
        id: 'directeur_financier',
        name: 'Omar Al-Rashid',
        role: 'Directeur Financier',
        avatarPath: 'assets/images/avatars/avatar_client_homme_moyen_orient.png',
      ),
    ],
    SimulationType.conferenceVente: [
      AgentInfo(
        id: 'client_principal',
        name: 'Yuki Nakamura',
        role: 'Client Principal',
        avatarPath: 'assets/images/avatars/avatar_client_homme_moyen_orient.png',
      ),
      AgentInfo(
        id: 'partenaire_technique',
        name: 'David Chen',
        role: 'Partenaire Technique',
        avatarPath: 'assets/images/avatars/avatar_expert_homme_africain.png',
      ),
    ],
    SimulationType.conferencePublique: [
      AgentInfo(
        id: 'moderateur',
        name: 'Elena Petrov',
        role: 'Modératrice',
        avatarPath: 'assets/images/avatars/avatar_animateur_tv_femme_africaine.png',
      ),
      AgentInfo(
        id: 'expert_audience',
        name: 'James Wilson',
        role: 'Expert Audience',
        avatarPath: 'assets/images/avatars/avatar_expert_homme_africain.png',
      ),
    ],
  };
  
  // Getters
  SimulationType? get currentSimulation => _currentSimulation;
  List<AgentInfo> get activeAgents => _activeAgents;
  String? get currentSpeaker => _currentSpeaker;
  List<ConversationMessage> get conversationHistory => _conversationHistory;
  PerformanceMetrics get metrics => _metrics;
  bool get isRecording => _isRecording;
  bool get isSessionActive => _isSessionActive;
  Duration get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!) 
      : Duration.zero;
  
  /// Obtenir les agents pour une simulation
  List<AgentInfo> getAgentsForSimulation(SimulationType type) {
    return List.from(_simulationAgents[type] ?? []);
  }
  
  /// Démarre l'enregistrement
  Future<void> startRecording() async {
    try {
      UnifiedLoggerService.info('Démarrage de l\'enregistrement');
      _isRecording = true;
      await _livekitService.muteAudio(false);
      notifyListeners();
    } catch (e) {
      UnifiedLoggerService.error('Erreur lors du démarrage de l\'enregistrement: $e');
      rethrow;
    }
  }
  
  /// Arrête l'enregistrement
  Future<void> stopRecording() async {
    try {
      UnifiedLoggerService.info('Arrêt de l\'enregistrement');
      _isRecording = false;
      await _livekitService.muteAudio(true);
      notifyListeners();
    } catch (e) {
      UnifiedLoggerService.error('Erreur lors de l\'arrêt de l\'enregistrement: $e');
      rethrow;
    }
  }
  
  /// Demande la prise de parole pour un agent
  void requestAgentSpeaker(String agentId) {
    try {
      UnifiedLoggerService.info('Demande de prise de parole pour l\'agent $agentId');
      
      // Envoyer la requête au backend
      final request = {
        'type': 'request_speaker',
        'agent_id': agentId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _livekitService.sendMessage(json.encode(request));
      
      // Émettre l'événement localement
      _multiAgentEventController.add(SpeakerChangedEvent(agentId));
      _currentSpeaker = agentId;
      notifyListeners();
    } catch (e) {
      UnifiedLoggerService.error('Erreur lors de la demande de prise de parole: $e');
    }
  }
  
  // Champs privés pour la connexion backend
  String? _currentRoomId;
  Timer? _agentCheckTimer;
  int _agentCheckAttempts = 0;
  static const int _maxAgentCheckAttempts = 10;
  
  // Stocker les données utilisateur
  String? _userName;
  String? _userSubject;
  
  /// Démarre une nouvelle simulation
  Future<void> startSimulation(
    SimulationType type, {
    String? userName,
    String? userSubject,
  }) async {
    try {
      UnifiedLoggerService.info('🎭 Démarrage simulation: ${type.name}');
      UnifiedLoggerService.info('👤 Utilisateur: ${userName ?? "Anonyme"}, Sujet: ${userSubject ?? "Non défini"}');
      
      _currentSimulation = type;
      _userName = userName;
      _userSubject = userSubject;
      _activeAgents = [];  // Vide initialement, sera rempli par les vrais agents
      _conversationHistory.clear();
      _metrics = const PerformanceMetrics();
      _sessionStartTime = DateTime.now();
      _isSessionActive = true;
      
      // Générer un room ID unique
      _currentRoomId = 'studio_${type.name}_${DateTime.now().millisecondsSinceEpoch}';
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      // Se connecter à LiveKit
      await _livekitService.connect(
        _currentRoomId!,
        userId: userId,
        userName: userName,
        userSubject: userSubject,
      );
      
      // Connecter au backend multi-agents avec les données utilisateur
      await _connectToMultiAgentBackend(type, userName: userName, userSubject: userSubject);
      
      // Écouter les événements
      _setupListeners();
      
      // Démarrer le timer des métriques
      _startMetricsTimer();
      
      // Attendre que les agents rejoignent
      await _waitForAgentsToJoin();
      
      notifyListeners();
      
      UnifiedLoggerService.info('✅ Simulation démarrée avec succès');
      
    } catch (e) {
      UnifiedLoggerService.error('❌ Erreur démarrage simulation: $e');
      _isSessionActive = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Connecte au backend multi-agents via HAProxy
  Future<void> _connectToMultiAgentBackend(
    SimulationType type, {
    String? userName,
    String? userSubject,
  }) async {
    try {
      UnifiedLoggerService.info('🔌 Connexion au backend multi-agents...');
      
      // URL du backend via HAProxy - utilise la configuration réseau
      final backendUrl = NetworkConfig.studioBackendUrl;
      
      // Configuration des agents pour le type de simulation
      final agentsConfig = _getAgentsConfig(type);
      
      // Requête de démarrage de session multi-agents
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'exercise_type': 'studio_${type.name}',
          'room_id': _currentRoomId,
          'simulation_type': type.name,
          'agents_config': agentsConfig,
          'max_agents': agentsConfig.length,
          'user_name': userName ?? 'Participant',
          'user_subject': userSubject ?? 'Sujet non défini',
          // Ajout explicite du champ topic pour éviter toute ambiguïté côté backend
          'topic': userSubject ?? 'Sujet non défini',
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout de connexion au backend multi-agents');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        UnifiedLoggerService.info('✅ Backend multi-agents connecté: ${data['message']}');
        
        // Envoyer les métadonnées via LiveKit avec les données utilisateur
        await _sendSimulationMetadata(type, userName: userName, userSubject: userSubject);
      } else {
        throw Exception('Erreur backend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      UnifiedLoggerService.error('❌ Erreur connexion backend multi-agents: $e');
      
      // Fallback : utiliser les agents locaux si le backend n'est pas disponible
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Timeout')) {
        UnifiedLoggerService.warning('⚠️ Backend indisponible, utilisation des agents locaux');
        await _fallbackToLocalAgents(type);
      } else {
        rethrow;
      }
    }
  }
  
  /// Obtient la configuration des agents pour un type de simulation
  List<Map<String, dynamic>> _getAgentsConfig(SimulationType type) {
    final agents = _simulationAgents[type] ?? [];
    return agents.map((agent) => {
      'id': agent.id,
      'name': agent.name,
      'role': agent.role,
      'avatar_path': agent.avatarPath,
      'personality': _getAgentPersonality(agent.id, type),
      'prompt': _getAgentPrompt(agent.id, type),
    }).toList();
  }
  
  /// Obtient la personnalité d'un agent
  String _getAgentPersonality(String agentId, SimulationType type) {
    final personalities = {
      'animateur_principal': 'Professionnel, charismatique, structuré',
      'journaliste_contradicteur': 'Critique, analytique, incisif',
      'expert_specialise': 'Pédagogue, précis, approfondi',
      'manager_rh': 'Bienveillant, évaluateur, structuré',
      'expert_technique': 'Rigoureux, technique, précis',
      'pdg': 'Visionnaire, décisif, stratégique',
      'directeur_financier': 'Analytique, prudent, factuel',
      'client_principal': 'Exigeant, intéressé, pragmatique',
      'partenaire_technique': 'Collaboratif, technique, solution-oriented',
      'moderateur': 'Neutre, facilitateur, inclusif',
      'expert_audience': 'Curieux, pertinent, engagé',
    };
    return personalities[agentId] ?? 'Professionnel et engagé';
  }
  
  /// Obtient le prompt système d'un agent
  String _getAgentPrompt(String agentId, SimulationType type) {
    final basePrompt = 'Tu es un agent IA dans une simulation professionnelle de type ${type.name}. ';
    final rolePrompts = {
      'animateur_principal': 'Tu animes le débat, poses des questions pertinentes et gères le temps de parole.',
      'journaliste_contradicteur': 'Tu challenges les arguments avec des questions critiques mais constructives.',
      'expert_specialise': 'Tu apportes une expertise technique approfondie sur le sujet discuté.',
      'manager_rh': 'Tu évalues les compétences et la personnalité du candidat avec bienveillance.',
      'expert_technique': 'Tu poses des questions techniques pour évaluer les connaissances.',
      'pdg': 'Tu diriges la réunion et prends des décisions stratégiques.',
      'directeur_financier': 'Tu analyses les aspects financiers et poses des questions sur les chiffres.',
      'client_principal': 'Tu représentes les besoins client et poses des questions pratiques.',
      'partenaire_technique': 'Tu apportes des solutions techniques et collabores sur les défis.',
      'moderateur': 'Tu facilites la discussion et assures que tous peuvent s\'exprimer.',
      'expert_audience': 'Tu poses des questions au nom du public et apportes des perspectives diverses.',
    };
    return basePrompt + (rolePrompts[agentId] ?? 'Participe activement à la simulation.');
  }
  
  /// Attendre que les agents rejoignent la room
  Future<void> _waitForAgentsToJoin() async {
    UnifiedLoggerService.info('⏳ En attente des agents...');
    
    _agentCheckAttempts = 0;
    final completer = Completer<void>();
    
    _agentCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _agentCheckAttempts++;
      
      if (_activeAgents.length >= (_simulationAgents[_currentSimulation!]?.length ?? 0)) {
        // Tous les agents ont rejoint
        timer.cancel();
        UnifiedLoggerService.info('✅ Tous les agents ont rejoint la simulation');
        _addWelcomeMessage();
        if (!completer.isCompleted) completer.complete();
      } else if (_agentCheckAttempts >= _maxAgentCheckAttempts) {
        // Timeout
        timer.cancel();
        UnifiedLoggerService.warning('⚠️ Timeout en attente des agents');
        
        // Si aucun agent n'a rejoint, utiliser le fallback
        if (_activeAgents.isEmpty) {
          _fallbackToLocalAgents(_currentSimulation!);
        }
        
        _addWelcomeMessage();
        if (!completer.isCompleted) completer.complete();
      } else {
        UnifiedLoggerService.debug('Agents connectés: ${_activeAgents.length}/${_simulationAgents[_currentSimulation!]?.length ?? 0}');
      }
    });
    
    return completer.future;
  }
  
  /// Fallback : utilise les agents locaux si le backend n'est pas disponible
  Future<void> _fallbackToLocalAgents(SimulationType type) async {
    UnifiedLoggerService.warning('📦 Utilisation des agents locaux (mode fallback)');
    
    _activeAgents = List.from(_simulationAgents[type] ?? []);
    
    // Simuler l'arrivée des agents localement
    for (var agent in _activeAgents) {
      await Future.delayed(const Duration(milliseconds: 300));
      _multiAgentEventController.add(AgentJoinedEvent(agent));
      
      // Activer le premier agent
      if (_activeAgents.indexOf(agent) == 0) {
        _multiAgentEventController.add(SpeakerChangedEvent(agent.id));
        _currentSpeaker = agent.id;
      }
    }
    
    notifyListeners();
  }
  
  /// Envoie les métadonnées de la simulation aux agents
  Future<void> _sendSimulationMetadata(
    SimulationType type, {
    String? userName,
    String? userSubject,
  }) async {
    final metadata = {
      'type': 'simulation_start',
      'exercise_type': 'studio_${type.name}',
      'simulation_type': type.name,
      'agents_count': _activeAgents.length,
      'agents': _activeAgents.map((agent) => {
        'id': agent.id,
        'name': agent.name,
        'role': agent.role,
      }).toList(),
      'user_id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'user_name': userName ?? 'Participant',
      'user_subject': userSubject ?? 'Sujet non défini',
      // Champ topic pour harmoniser la consommation côté agents
      'topic': userSubject ?? 'Sujet non défini',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _livekitService.sendMessage(json.encode(metadata));
  }
  
  /// Configure les listeners pour les événements LiveKit
  void _setupListeners() {
    // Écouter les données des agents
    _dataSubscription = _livekitService.dataStream.listen((data) {
      _handleAgentData(data);
    });
    
    // Écouter les messages
    _messageSubscription = _livekitService.messageStream.listen((message) {
      _handleAgentMessage(message);
    });
    
    // Écouter l'état de connexion
    _connectionSubscription = _livekitService.connectionStateStream.listen((state) {
      if (state == ConnectionState.disconnected) {
        _handleDisconnection();
      }
    });
  }
  
  /// Traite les données reçues des agents
  void _handleAgentData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    
    UnifiedLoggerService.debug('📨 Event reçu: $type');
    
    switch (type) {
      case 'agent_joined':
        _handleAgentJoined(data);
        break;
      case 'agent_left':
        _handleAgentLeft(data);
        break;
      case 'agent_speaking':
        _handleAgentSpeaking(data);
        break;
      case 'agent_message':
        _processAgentMessage(data);
        break;
      case 'agent_reaction':
        _processAgentReaction(data);
        break;
      case 'active_speaker':
        _updateActiveSpeaker(data);
        final speakerId = data['speaker_id'] ?? '';
        if (speakerId.isNotEmpty) {
          _multiAgentEventController.add(SpeakerChangedEvent(speakerId));
        }
        break;
      case 'metrics_update':
        _updateMetrics(data);
        break;
      default:
        UnifiedLoggerService.debug('Type d\'événement non géré: $type');
    }
  }
  
  /// Gère l'arrivée d'un agent
  void _handleAgentJoined(Map<String, dynamic> data) {
    try {
      final agentData = data['agent'] ?? {};
      final agent = AgentInfo(
        id: agentData['id'] ?? '',
        name: agentData['name'] ?? 'Agent',
        role: agentData['role'] ?? 'Participant',
        avatarPath: agentData['avatar_path'] ?? 'assets/images/avatars/avatar_expert_homme_africain.png',
        isActive: agentData['is_active'] ?? false,
        participationRate: (agentData['participation_rate'] ?? 0.0).toDouble(),
      );
      
      // Vérifier si l'agent n'est pas déjà dans la liste
      if (!_activeAgents.any((a) => a.id == agent.id)) {
        _activeAgents.add(agent);
        _multiAgentEventController.add(AgentJoinedEvent(agent));
        
        UnifiedLoggerService.info('✅ Agent rejoint: ${agent.name} (${agent.role})');
        
        // Si c'est le premier agent, le rendre actif
        if (_activeAgents.length == 1) {
          _currentSpeaker = agent.id;
          _multiAgentEventController.add(SpeakerChangedEvent(agent.id));
        }
        
        notifyListeners();
      }
    } catch (e) {
      UnifiedLoggerService.error('Erreur lors de l\'ajout de l\'agent: $e');
    }
  }
  
  /// Gère le départ d'un agent
  void _handleAgentLeft(Map<String, dynamic> data) {
    final agentId = data['agent_id'] ?? '';
    
    _activeAgents.removeWhere((a) => a.id == agentId);
    _multiAgentEventController.add(AgentLeftEvent(agentId));
    
    UnifiedLoggerService.info('👋 Agent parti: $agentId');
    
    // Si c'était le speaker actif, passer au suivant
    if (_currentSpeaker == agentId && _activeAgents.isNotEmpty) {
      _currentSpeaker = _activeAgents.first.id;
      _multiAgentEventController.add(SpeakerChangedEvent(_currentSpeaker!));
    }
    
    notifyListeners();
  }
  
  /// Gère le changement de speaker
  void _handleAgentSpeaking(Map<String, dynamic> data) {
    final agentId = data['agent_id'] ?? '';
    
    if (agentId.isNotEmpty && agentId != _currentSpeaker) {
      _currentSpeaker = agentId;
      _multiAgentEventController.add(SpeakerChangedEvent(agentId));
      
      // Mettre à jour l'état actif des agents
      _activeAgents = _activeAgents.map((agent) {
        final isActive = agent.id == agentId;
        if (agent.isActive != isActive) {
          _multiAgentEventController.add(AgentStateUpdateEvent(
            agentId: agent.id,
            isActive: isActive,
            participationRate: agent.participationRate,
          ));
        }
        return agent.copyWith(isActive: isActive);
      }).toList();
      
      UnifiedLoggerService.debug('🎤 Speaker actif: $agentId');
      notifyListeners();
    }
  }
  
  /// Traite un message d'agent
  void _processAgentMessage(Map<String, dynamic> data) {
    final agentId = data['agent_id'] ?? '';
    final agentName = data['agent_name'] ?? '';
    final message = data['message'] ?? '';
    
    final conversationMessage = ConversationMessage(
      speakerId: agentId,
      speakerName: agentName,
      content: message,
      timestamp: DateTime.now(),
      isUser: false,
      isReaction: false,
    );
    
    _conversationHistory.add(conversationMessage);
    notifyListeners();
  }
  
  /// Traite une réaction d'agent
  void _processAgentReaction(Map<String, dynamic> data) {
    final agentId = data['agent_id'] ?? '';
    final agentName = data['agent_name'] ?? '';
    final reaction = data['reaction'] ?? '';
    
    final reactionMessage = ConversationMessage(
      speakerId: agentId,
      speakerName: agentName,
      content: reaction,
      timestamp: DateTime.now(),
      isUser: false,
      isReaction: true,
    );
    
    _conversationHistory.add(reactionMessage);
    notifyListeners();
  }
  
  /// Met à jour le speaker actif
  void _updateActiveSpeaker(Map<String, dynamic> data) {
    final speakerId = data['speaker_id'] ?? '';
    
    _currentSpeaker = speakerId;
    
    // Mettre à jour l'état actif des agents
    _activeAgents = _activeAgents.map((agent) {
      final isActive = agent.id == speakerId;
      // Émettre un événement de mise à jour d'état si nécessaire
      if (agent.isActive != isActive) {
        _multiAgentEventController.add(AgentStateUpdateEvent(
          agentId: agent.id,
          isActive: isActive,
          participationRate: agent.participationRate,
        ));
      }
      return agent.copyWith(isActive: isActive);
    }).toList();
    
    notifyListeners();
  }
  
  /// Met à jour les métriques de performance
  void _updateMetrics(Map<String, dynamic> data) {
    final metricsData = data['metrics'] ?? {};
    
    _metrics = _metrics.copyWith(
      clarity: (metricsData['clarity'] ?? _metrics.clarity).toDouble(),
      confidence: (metricsData['confidence'] ?? _metrics.confidence).toDouble(),
      engagement: (metricsData['engagement'] ?? _metrics.engagement).toDouble(),
      fluency: (metricsData['fluency'] ?? _metrics.fluency).toDouble(),
      totalInteractions: metricsData['total_interactions'] ?? _metrics.totalInteractions,
      sessionDuration: sessionDuration,
    );
    
    notifyListeners();
  }
  
  /// Traite un message textuel d'agent
  void _handleAgentMessage(String message) {
    // Parser le nom de l'agent du message
    String agentName = 'Agent';
    String content = message;
    
    if (message.contains(':')) {
      final parts = message.split(':');
      agentName = parts[0].trim();
      content = parts.sublist(1).join(':').trim();
    }
    
    // Trouver l'agent correspondant
    final agent = _activeAgents.firstWhere(
      (a) => a.name == agentName,
      orElse: () => _activeAgents.first,
    );
    
    final conversationMessage = ConversationMessage(
      speakerId: agent.id,
      speakerName: agent.name,
      content: content,
      timestamp: DateTime.now(),
      isUser: false,
      isReaction: false,
    );
    
    _conversationHistory.add(conversationMessage);
    notifyListeners();
  }
  
  /// Démarre le timer pour mettre à jour les métriques
  void _startMetricsTimer() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateSessionMetrics();
    });
  }
  
  /// Met à jour les métriques de session
  void _updateSessionMetrics() {
    if (!_isSessionActive) return;
    
    // Calculer des métriques simulées basées sur l'activité
    final userMessages = _conversationHistory.where((m) => m.isUser).length;
    final agentMessages = _conversationHistory.where((m) => !m.isUser).length;
    
    // Simuler des métriques basées sur l'interaction
    final baseEngagement = userMessages > 0 ? 0.6 : 0.3;
    final interactionBonus = (userMessages / 10).clamp(0.0, 0.3);
    
    _metrics = _metrics.copyWith(
      engagement: (baseEngagement + interactionBonus).clamp(0.0, 1.0),
      totalInteractions: userMessages + agentMessages,
      sessionDuration: sessionDuration,
    );
    
    notifyListeners();
  }
  
  /// Ajoute le message de bienvenue
  void _addWelcomeMessage() {
    if (_activeAgents.isEmpty) return;
    
    // Le premier agent (généralement le modérateur) souhaite la bienvenue
    final welcomeAgent = _activeAgents.first;
    final simulationName = _getSimulationDisplayName(_currentSimulation!);
    
    // Personnaliser le message avec le nom et le sujet de l'utilisateur
    final userName = _userName ?? 'Participant';
    final userSubject = _userSubject ?? 'votre présentation';
    
    final welcomeMessage = ConversationMessage(
      speakerId: welcomeAgent.id,
      speakerName: welcomeAgent.name,
      content: '''Bonjour ${userName} et bienvenue dans cette simulation "$simulationName" !
      
Je suis ${welcomeAgent.name}, votre ${welcomeAgent.role}.

Je vois que vous souhaitez nous parler de : ${userSubject}

Nous allons recréer ensemble une situation professionnelle réaliste pour vous permettre de pratiquer et développer vos compétences de communication.

Mes collègues ${_activeAgents.skip(1).map((a) => a.name).join(' et ')} sont également présents pour enrichir cette expérience.

N'hésitez pas à vous exprimer naturellement. Nous sommes là pour vous accompagner !

Quand vous êtes prêt(e), commencez votre présentation sur ${userSubject}.''',
      timestamp: DateTime.now(),
      isUser: false,
      isReaction: false,
    );
    
    _conversationHistory.add(welcomeMessage);
  }
  
  /// Obtient le nom d'affichage de la simulation
  String _getSimulationDisplayName(SimulationType type) {
    switch (type) {
      case SimulationType.debatPlateau:
        return 'Débat en Plateau TV';
      case SimulationType.entretienEmbauche:
        return 'Entretien d\'Embauche';
      case SimulationType.reunionDirection:
        return 'Réunion de Direction';
      case SimulationType.conferenceVente:
        return 'Conférence de Vente';
      case SimulationType.conferencePublique:
        return 'Conférence Publique';
      case SimulationType.jobInterview:
        return 'Entretien d\'Embauche Classique';
      default:
        return 'Simulation Professionnelle';
    }
  }
  
  /// Envoie un message utilisateur
  Future<void> sendUserMessage(String message) async {
    if (!_isSessionActive || message.trim().isEmpty) return;
    
    try {
      // Ajouter le message à l'historique
      final userMessage = ConversationMessage(
        speakerId: 'user',
        speakerName: 'Vous',
        content: message,
        timestamp: DateTime.now(),
        isUser: true,
        isReaction: false,
      );
      
      _conversationHistory.add(userMessage);
      
      // Envoyer via LiveKit
      await _livekitService.sendMessage(message);
      
      // Mettre à jour les métriques
      _metrics = _metrics.copyWith(
        totalInteractions: _metrics.totalInteractions + 1,
      );
      
      notifyListeners();
      
    } catch (e) {
      UnifiedLoggerService.error('Erreur envoi message: $e');
    }
  }
  
  /// Active/désactive l'enregistrement
  Future<void> toggleRecording() async {
    _isRecording = !_isRecording;
    
    // Mute/unmute le micro
    await _livekitService.muteAudio(!_isRecording);
    
    notifyListeners();
    
    UnifiedLoggerService.info('Enregistrement ${_isRecording ? 'activé' : 'désactivé'}');
  }
  
  /// Gère la déconnexion
  void _handleDisconnection() {
    UnifiedLoggerService.warning('⚠️ Déconnexion détectée');
    _isSessionActive = false;
    _isRecording = false;
    notifyListeners();
  }
  
  /// Alias pour arrêter la simulation
  Future<void> endSimulation() async {
    await stopSimulation();
  }
  
  /// Arrête la simulation
  Future<void> stopSimulation() async {
    try {
      UnifiedLoggerService.info('🛑 Arrêt de la simulation');
      
      _isSessionActive = false;
      _isRecording = false;
      
      // Arrêter le timer
      _metricsTimer?.cancel();
      
      // Se déconnecter de LiveKit
      await _livekitService.disconnect();
      
      // Annuler les subscriptions
      await _dataSubscription?.cancel();
      await _messageSubscription?.cancel();
      await _connectionSubscription?.cancel();
      
      // Générer le rapport final
      final report = _generateSessionReport();
      UnifiedLoggerService.info('📊 Rapport de session: ${json.encode(report)}');
      
      notifyListeners();
      
    } catch (e) {
      UnifiedLoggerService.error('Erreur arrêt simulation: $e');
    }
  }
  
  /// Génère un rapport de session
  Map<String, dynamic> _generateSessionReport() {
    final userMessages = _conversationHistory.where((m) => m.isUser).length;
    final agentMessages = _conversationHistory.where((m) => !m.isUser).length;
    
    return {
      'simulation_type': _currentSimulation?.name,
      'duration_seconds': sessionDuration.inSeconds,
      'user_messages': userMessages,
      'agent_messages': agentMessages,
      'total_interactions': userMessages + agentMessages,
      'metrics': {
        'clarity': _metrics.clarity,
        'confidence': _metrics.confidence,
        'engagement': _metrics.engagement,
        'fluency': _metrics.fluency,
      },
      'agents_participation': _activeAgents.map((agent) => {
        'name': agent.name,
        'role': agent.role,
        'messages': _conversationHistory
            .where((m) => m.speakerId == agent.id)
            .length,
      }).toList(),
    };
  }
  
  @override
  void dispose() {
    _metricsTimer?.cancel();
    _agentCheckTimer?.cancel();
    _dataSubscription?.cancel();
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _multiAgentEventController.close();
    _livekitService.dispose();
    super.dispose();
  }
}

/// Provider pour le service
final studioSituationsProServiceProvider = Provider<StudioSituationsProService>((ref) {
  final livekitService = ref.watch(studioLiveKitServiceProvider);
  return StudioSituationsProService(livekitService);
});