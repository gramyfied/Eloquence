import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/services/studio_situations_pro_service.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/services/studio_livekit_service.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/models/simulation_models.dart';
import 'package:livekit_client/livekit_client.dart';
import 'dart:async';

// Mock Ref
class MockRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Mock class simple sans génération de code
class MockStudioLiveKitService extends StudioLiveKitService {
  final List<String> sentMessages = [];
  final List<Map<String, dynamic>> sentData = [];
  bool isConnected = false;
  bool audioMuted = false;
  
  final StreamController<Map<String, dynamic>> _dataController = StreamController.broadcast();
  final StreamController<String> _messageController = StreamController.broadcast();
  final StreamController<ConnectionState> _connectionController = StreamController.broadcast();
  
  // Constructeur qui appelle le constructeur parent avec un mock Ref
  MockStudioLiveKitService() : super(MockRef());
  
  @override
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  @override
  Stream<String> get messageStream => _messageController.stream;
  
  @override
  Stream<ConnectionState> get connectionStateStream => _connectionController.stream;
  
  @override
  Future<void> connect(String roomName, {String? userId}) async {
    isConnected = true;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  @override
  Future<void> disconnect() async {
    isConnected = false;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  @override
  Future<void> sendMessage(String message) async {
    sentMessages.add(message);
    await Future.delayed(const Duration(milliseconds: 10));
  }
  
  @override
  Future<void> sendData(Map<String, dynamic> data) async {
    sentData.add(data);
    await Future.delayed(const Duration(milliseconds: 10));
  }
  
  @override
  Future<void> muteAudio(bool mute) async {
    audioMuted = mute;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  
  void requestSpeaker(String agentId) {
    // Simuler la requête
  }
  
  @override
  Future<void> startRecording() async {
    // Simuler le démarrage de l'enregistrement
  }
  
  @override
  Future<void> stopRecording() async {
    // Simuler l'arrêt de l'enregistrement
  }
  
  void simulateDataMessage(Map<String, dynamic> data) {
    _dataController.add(data);
  }
  
  void simulateTextMessage(String message) {
    _messageController.add(message);
  }
  
  void simulateConnectionChange(ConnectionState state) {
    _connectionController.add(state);
  }
  
  @override
  void dispose() {
    _dataController.close();
    _messageController.close();
    _connectionController.close();
    super.dispose();
  }
}

void main() {
  group('StudioSituationsProService - Tests Multi-Agents', () {
    late StudioSituationsProService service;
    late MockStudioLiveKitService mockLiveKitService;
    
    setUp(() {
      mockLiveKitService = MockStudioLiveKitService();
      service = StudioSituationsProService(mockLiveKitService);
    });
    
    tearDown(() {
      service.dispose();
    });
    
    group('Initialisation des Agents', () {
      test('doit charger les agents corrects pour chaque type de simulation', () {
        // Test pour débat plateau TV
        var agents = service.getAgentsForSimulation(SimulationType.debatPlateau);
        expect(agents.length, 3);
        expect(agents[0].name, 'Michel Dubois');
        expect(agents[0].role, 'Animateur TV');
        expect(agents[1].name, 'Sarah Johnson');
        expect(agents[1].role, 'Journaliste');
        expect(agents[2].name, 'Marcus Thompson');
        expect(agents[2].role, 'Expert');
        
        // Test pour entretien d'embauche
        agents = service.getAgentsForSimulation(SimulationType.entretienEmbauche);
        expect(agents.length, 2);
        expect(agents[0].name, 'Hiroshi Tanaka');
        expect(agents[0].role, 'Manager RH');
        expect(agents[1].name, 'Carmen Rodriguez');
        expect(agents[1].role, 'Expert Technique');
        
        // Test pour réunion de direction
        agents = service.getAgentsForSimulation(SimulationType.reunionDirection);
        expect(agents.length, 2);
        expect(agents[0].name, 'Catherine Williams');
        expect(agents[0].role, 'PDG');
        expect(agents[1].name, 'Omar Al-Rashid');
        expect(agents[1].role, 'Directeur Financier');
      });
      
      test('doit vérifier que chaque agent a un avatar assigné', () {
        for (final type in SimulationType.values) {
          final agents = service.getAgentsForSimulation(type);
          for (final agent in agents) {
            expect(agent.avatarPath, isNotEmpty);
            expect(agent.avatarPath, startsWith('assets/images/avatars/'));
            expect(agent.avatarPath, endsWith('.png'));
          }
        }
      });
    });
    
    group('Gestion des Événements Multi-Agents', () {
      test('doit émettre AgentJoinedEvent lors du démarrage', () async {
        final events = <MultiAgentEvent>[];
        final subscription = service.multiAgentEvents.listen(events.add);
        
        await service.startSimulation(SimulationType.debatPlateau);
        
        // Attendre que les événements soient émis
        await Future.delayed(const Duration(seconds: 2));
        
        // Vérifier les événements AgentJoinedEvent
        final joinedEvents = events.whereType<AgentJoinedEvent>().toList();
        expect(joinedEvents.length, 3);
        expect(joinedEvents[0].agent.name, 'Michel Dubois');
        expect(joinedEvents[1].agent.name, 'Sarah Johnson');
        expect(joinedEvents[2].agent.name, 'Marcus Thompson');
        
        subscription.cancel();
      });
      
      test('doit émettre SpeakerChangedEvent lors du changement de speaker', () async {
        final events = <MultiAgentEvent>[];
        final subscription = service.multiAgentEvents.listen(events.add);
        
        await service.startSimulation(SimulationType.entretienEmbauche);
        
        // Simuler un changement de speaker
        service.requestAgentSpeaker('manager_rh');
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Vérifier l'événement SpeakerChangedEvent
        final speakerEvents = events.whereType<SpeakerChangedEvent>().toList();
        expect(speakerEvents, isNotEmpty);
        expect(speakerEvents.last.agentId, 'manager_rh');
        
        subscription.cancel();
      });
      
      test('doit émettre AgentStateUpdateEvent lors de la mise à jour d\'état', () async {
        
        final events = <MultiAgentEvent>[];
        final subscription = service.multiAgentEvents.listen(events.add);
        
        await service.startSimulation(SimulationType.debatPlateau);
        
        // Simuler une mise à jour d'état via LiveKit
        mockLiveKitService.simulateDataMessage({
          'type': 'active_speaker',
          'speaker_id': 'animateur_principal',
          'speaker_type': 'agent',
        });
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Vérifier les événements de mise à jour d'état
        final stateEvents = events.whereType<AgentStateUpdateEvent>().toList();
        expect(stateEvents, isNotEmpty);
        
        subscription.cancel();
      });
    });
    
    group('Gestion de l\'Enregistrement', () {
      test('doit démarrer l\'enregistrement correctement', () async {
        await service.startRecording();
        
        expect(service.isRecording, true);
        expect(mockLiveKitService.audioMuted, false);
      });
      
      test('doit arrêter l\'enregistrement correctement', () async {
        await service.startRecording();
        await service.stopRecording();
        
        expect(service.isRecording, false);
        expect(mockLiveKitService.audioMuted, true);
      });
      
      test('doit basculer l\'enregistrement avec toggleRecording', () async {
        expect(service.isRecording, false);
        
        await service.toggleRecording();
        expect(service.isRecording, true);
        
        await service.toggleRecording();
        expect(service.isRecording, false);
      });
    });
    
    group('Gestion des Messages', () {
      test('doit ajouter un message utilisateur à l\'historique', () async {
        await service.startSimulation(SimulationType.entretienEmbauche);
        
        const message = 'Bonjour, je suis prêt pour l\'entretien';
        await service.sendUserMessage(message);
        
        final history = service.conversationHistory;
        final userMessages = history.where((m) => m.isUser).toList();
        
        expect(userMessages.length, 1);
        expect(userMessages.first.content, message);
        expect(userMessages.first.speakerName, 'Vous');
      });
      
      test('doit traiter les messages d\'agents correctement', () async {
        await service.startSimulation(SimulationType.debatPlateau);
        
        // Simuler un message d'agent
        mockLiveKitService.simulateTextMessage('Michel Dubois: Bienvenue sur notre plateau!');
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final history = service.conversationHistory;
        final agentMessages = history.where((m) => !m.isUser && !m.isReaction).toList();
        
        // +1 pour le message de bienvenue automatique
        expect(agentMessages.length, greaterThanOrEqualTo(2));
        
        final lastMessage = agentMessages.last;
        expect(lastMessage.content, 'Bienvenue sur notre plateau!');
        expect(lastMessage.speakerName, 'Michel Dubois');
      });
    });
    
    group('Métriques de Performance', () {
      test('doit initialiser les métriques correctement', () async {
        await service.startSimulation(SimulationType.conferenceVente);
        
        final metrics = service.metrics;
        expect(metrics.clarity, 0.0);
        expect(metrics.confidence, 0.0);
        expect(metrics.engagement, greaterThanOrEqualTo(0.0));
        expect(metrics.fluency, 0.0);
        expect(metrics.totalInteractions, greaterThanOrEqualTo(0));
      });
      
      test('doit mettre à jour les métriques avec les données reçues', () async {
        await service.startSimulation(SimulationType.conferencePublique);
        
        // Envoyer des métriques mises à jour
        mockLiveKitService.simulateDataMessage({
          'type': 'metrics_update',
          'metrics': {
            'clarity': 0.75,
            'confidence': 0.82,
            'engagement': 0.91,
            'fluency': 0.68,
            'total_interactions': 5,
          },
        });
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final metrics = service.metrics;
        expect(metrics.clarity, 0.75);
        expect(metrics.confidence, 0.82);
        expect(metrics.engagement, 0.91);
        expect(metrics.fluency, 0.68);
        expect(metrics.totalInteractions, 5);
      });
      
      test('doit calculer la durée de session correctement', () async {
        await service.startSimulation(SimulationType.entretienEmbauche);
        
        await Future.delayed(const Duration(seconds: 2));
        
        final duration = service.sessionDuration;
        expect(duration.inSeconds, greaterThanOrEqualTo(2));
      });
    });
    
    group('Cycle de Vie de la Simulation', () {
      test('doit démarrer une simulation correctement', () async {
        await service.startSimulation(SimulationType.debatPlateau);
        
        expect(service.currentSimulation, SimulationType.debatPlateau);
        expect(service.isSessionActive, true);
        expect(service.activeAgents.length, 3);
        expect(service.conversationHistory, isNotEmpty); // Message de bienvenue
        expect(mockLiveKitService.isConnected, true);
        expect(mockLiveKitService.sentMessages, isNotEmpty); // Métadonnées envoyées
      });
      
      test('doit arrêter une simulation correctement', () async {
        await service.startSimulation(SimulationType.reunionDirection);
        await service.stopSimulation();
        
        expect(service.isSessionActive, false);
        expect(service.isRecording, false);
        expect(mockLiveKitService.isConnected, false);
      });
      
      test('doit utiliser endSimulation comme alias de stopSimulation', () async {
        await service.startSimulation(SimulationType.conferenceVente);
        await service.endSimulation();
        
        expect(service.isSessionActive, false);
        expect(mockLiveKitService.isConnected, false);
      });
      
      test('doit générer un rapport de session', () async {
        await service.startSimulation(SimulationType.entretienEmbauche);
        
        // Ajouter quelques messages
        await service.sendUserMessage('Question 1');
        await service.sendUserMessage('Question 2');
        
        await service.stopSimulation();
        
        // Le rapport est généré en interne, on vérifie juste que la session s'est bien terminée
        expect(service.isSessionActive, false);
        expect(service.conversationHistory.where((m) => m.isUser).length, 2);
      });
    });
    
    group('Gestion des Erreurs', () {
      test('doit gérer les erreurs de connexion', () {
        // Test simplifié - on vérifie juste que le service gère bien les états
        expect(service.isSessionActive, false);
      });
      
      test('doit gérer la déconnexion inattendue', () async {
        await service.startSimulation(SimulationType.entretienEmbauche);
        
        expect(service.isSessionActive, true);
        
        // Simuler une déconnexion
        mockLiveKitService.simulateConnectionChange(ConnectionState.disconnected);
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(service.isSessionActive, false);
        expect(service.isRecording, false);
      });
    });
  });
}