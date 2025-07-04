import 'dart:async';
import 'dart:convert';
// import 'dart:typed_data'; // Import inutilisé
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/core/theme/dark_theme.dart';
import 'package:eloquence_2_0/core/utils/logger_service.dart';
// import 'package:eloquence_2_0/core/config/app_config.dart'; // Import inutilisé
import 'package:eloquence_2_0/data/models/scenario_model.dart';
import 'package:eloquence_2_0/data/models/session_model.dart';
import 'package:eloquence_2_0/presentation/providers/scenario_provider.dart';
// import 'package:eloquence_2_0/presentation/providers/audio_provider.dart'; // Supprimé
// import 'package:eloquence_2_0/presentation/providers/livekit_provider.dart'; // Supprimé car remplacé par clean_audio_provider
// import 'package:eloquence_2_0/data/services/livekit_service_v2.dart'; // Supprimé
// import 'package:eloquence_2_0/data/services/realtime_ai_audio_streamer_service.dart'; // Supprimé
import 'package:eloquence_2_0/src/providers/clean_audio_provider.dart'; // Chemin corrigé avec convention package
// import 'package:eloquence_2_0/presentation/providers/livekit_audio_provider.dart'; // Remplacé
// import 'package:eloquence_2_0/presentation/providers/audio_recorder_provider.dart'; // Supprimé
import 'package:eloquence_2_0/presentation/providers/conversation_messages_provider.dart'; // Ajout du nouveau provider
import 'package:eloquence_2_0/presentation/widgets/glow_microphone_button.dart';
import 'package:eloquence_2_0/presentation/widgets/scenario_selection_modal.dart';
// import 'package:eloquence_2_0/presentation/widgets/livekit_control_panel.dart'; // Supprimé
// import 'package:eloquence_2_0/presentation/widgets/audio_recorder_control_panel.dart'; // Supprimé
import 'package:eloquence_2_0/presentation/widgets/conversation_messages_list.dart'; // Ajout du nouveau widget
// Pour aiProcessingStateProvider

// Définir un type pour AIResponse
class AIResponse {
  final String type;
  final String? text;
  final String? error;
  final int? timestamp; // Ajout d'un timestamp pour les messages
  AIResponse({required this.type, this.text, this.error, this.timestamp});

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      type: json['type'] as String,
      text: json['text'] as String?,
      error: json['error'] as String?,
      timestamp: json['timestamp'] != null ? int.parse(json['timestamp'].toString()) : null,
    );
  }
}

class ScenarioScreen extends ConsumerStatefulWidget {
  const ScenarioScreen({super.key});

  @override
  ConsumerState<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends ConsumerState<ScenarioScreen> {
  static const String _tag = 'ScenarioScreen';
  String _currentPrompt = '"Merci à tous d\'être présents aujourd\'hui."';
  bool _showFeedback = false;
  bool _isDisposed = false;
  bool _isStreamingMode = true; // Mode streaming continu ACTIVÉ PAR DÉFAUT
  
  // _messages est maintenant géré par conversationMessagesProvider
  
  // Utiliser des ProviderSubscription pour pouvoir les annuler proprement
  ProviderSubscription<AsyncValue<SessionModel?>>? _sessionSubscription;
  StreamSubscription? _aiResponseSubscriptionFromService; // Type AIResponse à définir ou supprimer

  // Variable pour suivre si un scénario a déjà été sélectionné
  bool _hasSelectedScenario = false;

  // Track the actual current prompt based on conversation flow, not just initial
  String _currentDisplayedPrompt = '"Merci à tous d\'être présents aujourd\'hui."';

  @override
  void initState() {
    super.initState();
    logger.i(_tag, '🎵 [AUDIO_FIX] Initialisation de la page de scénario');
    
    // Configurer l'écouteur de session une seule fois avec une référence à l'abonnement
    _sessionSubscription = ref.listenManual(sessionProvider, (previous, next) {
      if (!mounted || _isDisposed) return;

      if (next.hasError) {
        logger.e(_tag, 'Erreur dans sessionProvider (écouté par ScenarioScreen): ${next.error}', next.error, next.stackTrace);
        // Optionnel: afficher une SnackBar ou un message d'erreur à l'utilisateur ici
        return;
      }

      if (next.isLoading) {
        logger.i(_tag, 'sessionProvider est en chargement (écouté par ScenarioScreen)');
        return;
      }
      
      if (next.value != null) {
        final currentSession = next.value!;
        // Vérifier si c'est une nouvelle session ou une mise à jour pertinente
        if (previous?.value?.sessionId != currentSession.sessionId || previous?.value?.livekitUrl != currentSession.livekitUrl || previous?.value?.token != currentSession.token) {
          logger.i(_tag, 'Nouvelle session ou session mise à jour détectée par ScenarioScreen: ${currentSession.sessionId}');
          logger.i(_tag, '  Room: ${currentSession.roomName}');
          logger.i(_tag, '  URL LiveKit dans SessionModel: ${currentSession.livekitUrl}');
          logger.i(_tag, '  Token dans SessionModel: ${currentSession.token.isNotEmpty ? "PRESENT" : "VIDE OU NULL"}');

          // CORRECTION : Connecter via le nouveau CleanAudioProvider
          logger.i(_tag, '🔧 Connexion via CleanAudioProvider...');
          Future.microtask(() async {
            try {
              final cleanAudioNotifier = ref.read(cleanAudioProvider.notifier);
              await cleanAudioNotifier.connect(currentSession); // Utiliser la méthode connect de CleanAudioProvider
              logger.i(_tag, '✅ Connexion LiveKit réussie via CleanAudioProvider');
            } catch (e) {
              logger.e(_tag, '❌ Erreur connexion LiveKit via CleanAudioProvider: $e');
            }
          });

          // Mettre à jour le prompt si le message initial est disponible
          if (currentSession.initialMessage != null && currentSession.initialMessage!.containsKey('text')) {
            final initialMessageText = currentSession.initialMessage!['text'];
            logger.i(_tag, 'Message initial pour le prompt: $initialMessageText');
            if (mounted && !_isDisposed) {
              setState(() {
                _currentPrompt = initialMessageText!;
              });
              // Ajouter le message initial à la conversation via le provider
              ref.read(conversationMessagesProvider.notifier).addMessage("IA", initialMessageText!);
            }
          } else {
            logger.w(_tag, 'Pas de message initial dans la session ou format incorrect');
          }
        }
        // Marquer qu'un scénario a été sélectionné pour éviter de rouvrir la modale
        // si la session est déjà active au démarrage de l'écran.
        if (!_hasSelectedScenario) {
           _hasSelectedScenario = true;
        }
        // logger.performance(_tag, 'scenarioSelection', end: true); // Déplacé ou à revoir
      }

      // NOUVEAU : Déclencher le démarrage du streaming quand une nouvelle session est établie
      if (next.value != null && previous?.value?.sessionId != next.value!.sessionId) {
        logger.i(_tag, 'Nouvelle session détectée, démarrage du streaming automatique activé.');
        if (mounted && !_isDisposed) { // _isStreamingMode est déjà true par défaut
          // Délai pour permettre à la connexion LiveKit de s'établir
          Timer(const Duration(seconds: 4), () {
            if (mounted && !_isDisposed) {
              _startStreamingAfterConnection();
            }
          });
        }
      }
    });

    // TODO: Remplacer ou supprimer la logique de liveKitConversationProvider
    // Écouter les réponses IA pour les ajouter aux messages
    // ref.listenManual(liveKitConversationProvider, (previous, next) {
    //   if (!mounted || _isDisposed) return;
      
    //   // Si on a reçu un nouveau message de l'IA
    //   if (next.lastMessage != null &&
    //       next.lastMessage!.isNotEmpty &&
    //       next.lastMessage != previous?.lastMessage) {
    //     ref.read(conversationMessagesProvider.notifier).addMessage("IA", next.lastMessage!);
    //   }
      
    //   // Détecter quand l'utilisateur commence/arrête de parler en mode streaming
    //   if (_isStreamingMode && previous != null) {
    //     if (next.isRecording && !previous.isRecording) {
    //       // L'utilisateur commence à parler
    //       ref.read(conversationMessagesProvider.notifier).addMessage("Système", "🎙️ Vous parlez...");
    //     } else if (!next.isRecording && previous.isRecording) {
    //       // L'utilisateur a fini de parler
    //       ref.read(conversationMessagesProvider.notifier).addMessage("Système", "⏳ Traitement de votre message...");
    //     }
    //   }
    // });

    // Écouter les réponses IA directement depuis le stream de CleanLiveKitService (via CleanAudioProvider)
    final cleanAudioService = ref.read(cleanAudioProvider).service;
    _aiResponseSubscriptionFromService = cleanAudioService.onAudioReceivedStream.listen((data) {
      if (!mounted || _isDisposed) return;
      if (data.isEmpty) {
        logger.v(_tag, 'Chunk audio vide ignoré');
        return;
      }
      // Les données sont maintenant des Uint8List. Nous devons les interpréter.
      // Pour l'instant, nous supposons que c'est du texte encodé, ou nous en ferons un message simple.
      // Une implémentation plus robuste inclurait un parser pour différents types de messages (JSON, etc.).
      try {
        final String messageContent = String.fromCharCodes(data);
        // Si le contenu est un JSON, essayez de le parser en AIResponse
        if (messageContent.startsWith('{') && messageContent.endsWith('}')) {
          final Map<String, dynamic> jsonData = json.decode(messageContent);
          final aiResponse = AIResponse.fromJson(jsonData);

          if (aiResponse.type == 'transcription' || aiResponse.type == 'transcription_final') {
            // Un message de transcription indique que l'IA a fini de "calculer" et est prête à parler (ou a déjà parlé).
            // Donc, on peut réinitialiser l'état de traitement.
            ref.read(aiProcessingStateProvider.notifier).state = false;
            if (aiResponse.text != null && aiResponse.text!.isNotEmpty) {
              ref.read(conversationMessagesProvider.notifier).addMessage("Transcription", aiResponse.text!);
            }
          } else if (aiResponse.type == 'ai_response') {
            // Une réponse de l'IA indique également la fin du traitement.
            ref.read(aiProcessingStateProvider.notifier).state = false;
            if (aiResponse.text != null && aiResponse.text!.isNotEmpty) {
              ref.read(conversationMessagesProvider.notifier).addMessage("IA", aiResponse.text!);
              // Mettre à jour le prompt affiché avec la dernière réponse de l'IA
              if (mounted && !_isDisposed) {
                setState(() {
                  _currentDisplayedPrompt = aiResponse.text!;
                });
              }
            }
          } else if (aiResponse.type.contains('processing_started')) {
            // Message indiquant que l'IA a commencé à traiter la demande
            ref.read(aiProcessingStateProvider.notifier).state = true;
            ref.read(conversationMessagesProvider.notifier).addMessage("Système", "⏳ L'IA traite votre demande...");
          } else if (aiResponse.type.contains('processing_finished')) {
            // Message indiquant que l'IA a fini de traiter (avant potentielle transcription/réponse)
            ref.read(aiProcessingStateProvider.notifier).state = false;
            ref.read(conversationMessagesProvider.notifier).addMessage("Système", "✅ L'IA a terminé le traitement.");
          } else if (aiResponse.type.contains('error')) {
            ref.read(aiProcessingStateProvider.notifier).state = false; // Réinitialiser le traitement en cas d'erreur
            if (aiResponse.error != null && aiResponse.error!.isNotEmpty) {
              ref.read(conversationMessagesProvider.notifier).addMessage("Erreur IA", aiResponse.error!);
            }
          } else {
            logger.w(_tag, 'Type de réponse IA non géré: ${aiResponse.type}');
          }
        } else {
          // Traiter comme un message texte simple s'il n'est pas au format JSON (peut arriver pour des logs internes)
          // Ne pas impacter le aiProcessingStateProvider ici à moins de logique spécifique
          ref.read(conversationMessagesProvider.notifier).addMessage("IA Stream (texte brut)", messageContent);
        }
      } catch (e, s) {
        logger.e(_tag, 'Erreur de traitement des données audio reçues: $e', null, s);
        ref.read(conversationMessagesProvider.notifier).addMessage("Système (Erreur)", "Erreur de traitement du stream audio: $e");
      }
    });

    logger.i(_tag, 'Abonné au stream de données de CleanLiveKitService.');


    // Écouter les réponses IA directement depuis le stream de LiveKitServiceV2
    // Assurez-vous que liveKitServiceProvider expose bien une instance de LiveKitServiceV2
    // et que LiveKitServiceV2 expose bien aiResponseStream.
    // Le provider liveKitServiceProvider doit être celui qui contient l'instance de LiveKitServiceV2.
    // Si liveKitServiceProvider est de type LiveKitServiceV2 directement :
    // final liveKitService = ref.read(liveKitServiceProvider);
    // Si c'est un NotifierProvider qui expose LiveKitServiceV2 dans son état, la logique est différente.
    // Supposons pour l'instant que liveKitServiceProvider est l'instance directe pour simplifier.
    // Il est probable que vous ayez un StateNotifierProvider pour LiveKitServiceV2.
    // Dans ce cas, il faudrait écouter le stream DANS le StateNotifier et exposer les messages via l'état du notifier.
    // Pour une intégration directe ici (moins idéale mais pour démonstration) :
    // Nous allons utiliser liveKitProvider, en supposant qu'il fournit une instance de LiveKitServiceV2
    // ou un Notifier qui expose cette instance ou son stream.
    // Pour l'instant, on accède directement au service via le provider.
    // Il est crucial que liveKitProvider soit configuré pour fournir LiveKitServiceV2.
    // Correction: Le type AIResponse vient de realtime_ai_audio_streamer_service.dart
    // L'ancienne logique de stream de LiveKitServiceV2 est supprimée car remplacée par CleanLiveKitService.onAudioReceived

    // Afficher la modale de sélection de scénario après le build initial
    // seulement si aucun scénario n'a été sélectionné
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed && !_hasSelectedScenario) {
        logger.i(_tag, 'Affichage de la modale de sélection de scénario');
        _showScenarioSelectionModal();
      }
    });
  }
  
  // La méthode dispose() est définie plus bas dans le fichier

  // La méthode _connectToWebSocket a été supprimée car la connexion est
  // maintenant gérée par SessionNotifier après la mise à jour de son état.

  void _showScenarioSelectionModal() {
    // Vérifier si le widget est toujours monté
    if (_isDisposed || !mounted) {
      logger.w(_tag, 'Tentative d\'ouverture de modale sur un widget détruit');
      return;
    }
    
    // Vérifier si un scénario a déjà été sélectionné
    if (_hasSelectedScenario) {
      logger.i(_tag, 'Un scénario a déjà été sélectionné, pas besoin de rouvrir la modale');
      return;
    }
    
    logger.i(_tag, 'Ouverture de la modale de sélection de scénario');
    logger.performance(_tag, 'showScenarioModal', start: true);

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ScenarioSelectionModal(
          onScenarioSelected: _onScenarioSelected,
        ),
      ).then((_) {
        // Vérifier si le widget est toujours monté avant de logger
        if (!_isDisposed) {
          logger.performance(_tag, 'showScenarioModal', end: true);
        }
      });
    } catch (e) {
      logger.e(_tag, 'Erreur lors de l\'affichage de la modale: $e');
      
      // Marquer comme si un scénario avait été sélectionné pour éviter de rouvrir la modale
      _hasSelectedScenario = true;
    }
  }

  void _onScenarioSelected(ScenarioModel scenario) {
    // Vérifier si le widget est toujours monté
    if (_isDisposed || !mounted) {
      logger.w(_tag, 'Tentative de sélection de scénario sur un widget détruit');
      return;
    }
    
    logger.i(_tag, 'Scénario sélectionné: ${scenario.id} - ${scenario.name}');
    logger.performance(_tag, 'scenarioSelection', start: true);

    // Marquer qu'un scénario a été sélectionné pour éviter de rouvrir la modale
    _hasSelectedScenario = true;

    try {
      // Mettre à jour le scénario sélectionné dans le provider
      ref.read(selectedScenarioProvider.notifier).state = scenario;

      // Démarrer une session avec ce scénario
      final sessionNotifier = ref.read(sessionProvider.notifier);
      sessionNotifier.startSession(scenario.id);

      // Mettre à jour le prompt (pour cet exemple, nous utilisons simplement le nom du scénario)
      if (mounted && !_isDisposed) {
        setState(() {
          _currentPrompt = '"${scenario.name}"';
          _showFeedback = false;
          _isStreamingMode = true; // S'assurer que le mode streaming est activé
        });
      }

      // Fermer immédiatement la modale si possible
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Démarrer automatiquement le streaming après un court délai
      // Le démarrage du streaming sera déclenché par la détection de la piste audio de l'IA
      // via le liveKitConversationProvider.
      
    } catch (e) {
      logger.e(_tag, 'Erreur lors de la sélection du scénario: $e');
      
      // Fermer la modale même en cas d'erreur
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
  // _addMessage est maintenant géré par conversationMessagesProvider

  Future<void> _toggleStreamingMode() async {
    // Vérifier si le widget est toujours monté
    if (_isDisposed || !mounted) {
      logger.w(_tag, '[DEBUG] Tentative de toggle streaming sur un widget détruit');
      return;
    }

    logger.performance(_tag, 'userInteraction', start: true);
    logger.i(_tag, '[DEBUG] ===== DÉBUT TOGGLE STREAMING =====');

    setState(() {
      _isStreamingMode = !_isStreamingMode;
    });

    if (_isStreamingMode) {
      // Démarrer le mode streaming continu
      ref.read(conversationMessagesProvider.notifier).addMessage("Système", "🎤 Mode streaming activé - Écoute continue");
      
      try {
        // Récupérer le notifier et l'état LiveKit - TODO: Adapter ou supprimer
        // final liveKitNotifier = ref.read(liveKitConversationProvider.notifier);
        // final conversationState = ref.read(liveKitConversationProvider);

        final cleanAudio = ref.read(cleanAudioProvider);
        if (!cleanAudio.isConnected /* && !cleanAudio.isConnecting - à ajouter si pertinent */) {
          ref.read(conversationMessagesProvider.notifier).addMessage("Système", "❌ Pas de connexion au serveur");
          setState(() {
            _isStreamingMode = false;
          });
          return;
        }

        // TODO: La logique de startRecording/stopRecording doit être adaptée au CleanLiveKitService
        // Pour l'instant, on commente les appels à liveKitNotifier.
        await ref.read(cleanAudioProvider.notifier).service.publishMyAudio();
        ref.read(conversationMessagesProvider.notifier).addMessage("IA", "👂 Je vous écoute en continu... Parlez quand vous voulez !");
        
        // Démarrer une boucle de streaming continu
        _startContinuousStreaming();
        
      } catch (e) {
        ref.read(conversationMessagesProvider.notifier).addMessage("Système", "❌ Erreur: ${e.toString()}");
        setState(() {
          _isStreamingMode = false;
        });
      }
    } else {
      // Arrêter le mode streaming
      ref.read(conversationMessagesProvider.notifier).addMessage("Système", "⏹️ Mode streaming désactivé");
      
      try {
        // final liveKitNotifier = ref.read(liveKitConversationProvider.notifier); // TODO: Adapter ou supprimer
        await ref.read(cleanAudioProvider.notifier).service.unpublishMyAudio();
        _stopContinuousStreaming();
      } catch (e) {
        ref.read(conversationMessagesProvider.notifier).addMessage("Système", "❌ Erreur lors de l'arrêt: ${e.toString()}");
      }
    }

    logger.i(_tag, '[DEBUG] ===== FIN TOGGLE STREAMING =====');
    logger.performance(_tag, 'userInteraction', end: true);
  }

  Timer? _streamingTimer;
  
  void _startContinuousStreaming() {
    // Arrêter le timer existant s'il y en a un
    _stopContinuousStreaming();
    
    // Démarrer un timer qui maintient l'enregistrement actif
    _streamingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isStreamingMode || _isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      
      try {
        // final liveKitNotifier = ref.read(liveKitConversationProvider.notifier); // TODO: Adapter ou supprimer
        // final conversationState = ref.read(liveKitConversationProvider); // TODO: Adapter ou supprimer
        
        // Vérifier si l'enregistrement est toujours actif - TODO: Adapter la logique
        // if (!conversationState.isRecording) { // Remplacé par la vérification de _isStreamingMode et l'état du service
        final cleanAudioService = ref.read(cleanAudioProvider).service;
        // On pourrait ajouter un getter isPublishing dans CleanLiveKitService basé sur localParticipant.isMicrophoneEnabled()
        // Pour l'instant, on se fie à _isStreamingMode pour relancer si besoin.
        if (_isStreamingMode && !(cleanAudioService.localParticipant?.isMicrophoneEnabled() ?? false)) {
           logger.i(_tag, 'Redémarrage automatique de la publication audio en mode streaming');
           await cleanAudioService.publishMyAudio();
        }
        // }
      } catch (e) {
        logger.e(_tag, 'Erreur lors du maintien du streaming: $e');
      }
    });
  }
  
  void _stopContinuousStreaming() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
  }
  
  /// Démarre le streaming automatiquement après la connexion
  Future<void> _startStreamingAfterConnection() async {
    if (_isDisposed || !mounted || !_isStreamingMode) {
      return;
    }
    
    logger.i(_tag, 'Démarrage automatique du streaming continu');
    
    try {
      // Récupérer le notifier et l'état LiveKit - TODO: Adapter ou supprimer
      // final liveKitNotifier = ref.read(liveKitConversationProvider.notifier);
      // final conversationState = ref.read(liveKitConversationProvider);

      final cleanAudio = ref.read(cleanAudioProvider);
      if (!cleanAudio.isConnected /* && !cleanAudio.isConnecting */) {
        logger.w(_tag, 'Pas de connexion au serveur pour le streaming automatique');
        return;
      }

      // Démarrer l'enregistrement continu - TODO: Adapter la logique à CleanLiveKitService
      await ref.read(cleanAudioProvider.notifier).service.publishMyAudio();
      ref.read(conversationMessagesProvider.notifier).addMessage("Système", "🎤 Mode streaming activé automatiquement - Écoute continue");
      ref.read(conversationMessagesProvider.notifier).addMessage("IA", "👂 Je vous écoute en continu... Parlez quand vous voulez !");
      
      // Démarrer la boucle de streaming continu
      _startContinuousStreaming();
      
    } catch (e) {
      logger.e(_tag, 'Erreur lors du démarrage automatique du streaming: $e');
      ref.read(conversationMessagesProvider.notifier).addMessage("Système", "❌ Erreur lors du démarrage automatique: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.v(_tag, 'Construction de l\'interface');
    logger.performance(_tag, 'build', start: true);

    final textTheme = Theme.of(context).textTheme;
    final selectedScenario = ref.watch(selectedScenarioProvider);
    // final conversationState = ref.watch(conversationProvider); // TODO: Vérifier si ce provider est toujours pertinent et le remplacer/supprimer
    
    // Écouter les réponses IA en temps réel pour le prompt principal - TODO: Adapter ou supprimer
    // final lastIaMessage = ref.watch(liveKitConversationProvider.select((s) => s.lastMessage));
    const String lastIaMessage = ""; // Placeholder
    final messages = ref.watch(conversationMessagesProvider); // Écouter la liste des messages

    // Utiliser l'état de CleanAudioProvider pour isRecording
    final cleanAudioState = ref.watch(cleanAudioProvider);
    final isActuallyRecording = cleanAudioState.service.localParticipant?.isMicrophoneEnabled() ?? false;
    
    // Gérer isProcessing via un provider dédié, mis à jour par les messages AIResponse
    final isProcessing = ref.watch(aiProcessingStateProvider);
    
    // Le prompt affiché est maintenant géré par _currentDisplayedPrompt, mis à jour par les messages de l'IA
    // Et le chat est géré par conversationMessagesProvider pour les messages de l'IA.
    final displayPrompt = _currentDisplayedPrompt;

    // Afficher le feedback si disponible et si on n'est pas en train d'enregistrer ou de traiter
    final showFeedback = _showFeedback && !isActuallyRecording && !isProcessing; // Adapté

    final result = Scaffold(
      backgroundColor: Colors.transparent,
      // Ajout d'un bouton flottant pour changer d'exercice
      floatingActionButton: FloatingActionButton(
        onPressed: _showScenarioSelectionModal,
        backgroundColor: DarkTheme.primaryPurple.withOpacity(0.8),
        mini: true,
        tooltip: 'Changer d\'exercice', // Bouton plus petit pour être moins intrusif
        child: const Icon(Icons.swap_horiz, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop, // Positionné en haut à droite
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Titre et scénario
              Column(
                children: [
                  // Bouton de retour et titre du scénario
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        color: DarkTheme.textPrimary,
                        onPressed: () {
                          logger.i(_tag, 'Navigation vers l\'écran précédent');
                          Navigator.of(context).pop();
                        },
                      ),
                      if (selectedScenario != null)
                        Expanded(
                          child: Text(
                            selectedScenario.name,
                            style: textTheme.titleSmall?.copyWith(
                              color: DarkTheme.textSecondary,
                              fontFamily: 'Montserrat',
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mode streaming indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isStreamingMode
                            ? DarkTheme.accentCyan.withOpacity(0.5)
                            : DarkTheme.primaryBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isStreamingMode ? Icons.mic : Icons.mic_off,
                          color: _isStreamingMode
                              ? DarkTheme.accentCyan
                              : DarkTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isStreamingMode ? 'Streaming Actif' : 'Mode Push-to-Talk',
                          style: textTheme.bodySmall?.copyWith(
                            color: _isStreamingMode
                                ? DarkTheme.accentCyan
                                : DarkTheme.textSecondary,
                            fontWeight: _isStreamingMode
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Messages de conversation - GRANDE ZONE
              Expanded(
                flex: 4, // Donner encore plus d'espace à la zone de conversation
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DarkTheme.primaryBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ConversationMessagesList(
                    messages: messages.map((msg) => {
                      'sender': msg.sender,
                      'text': msg.text,
                      'timestamp': msg.timestamp,
                    }).toList(), // Convertir List<ConversationMessage> en List<Map<String, dynamic>>
                    displayPrompt: displayPrompt,
                    isStreamingMode: _isStreamingMode,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton de contrôle
              GlowMicrophoneButton(
                isRecording: _isStreamingMode || isActuallyRecording, // Utilise l'état réel du micro si possible
                isProcessing: isProcessing,
                onPressed: _toggleStreamingMode,
                size: 80,
              ),
              
              const SizedBox(height: 16),
              
              // Texte d'instruction
              Text(
                _isStreamingMode
                    ? (isActuallyRecording ? '🎤 Écoute en continu...' : '🎤 Mode streaming actif - Prêt')
                    : 'Appuyez pour basculer en mode streaming',
                style: textTheme.bodyMedium?.copyWith(
                  color: DarkTheme.textSecondary,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    logger.performance(_tag, 'build', end: true);
    return result;
  }

  /// Construit le widget de feedback
  Widget _buildFeedbackWidget(Map<String, dynamic> feedback) {
    logger.v(_tag, 'Construction du widget de feedback');
    logger.performance(_tag, 'buildFeedback', start: true);

    final result = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkTheme.backgroundMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarkTheme.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyse de votre performance',
            style: TextStyle(
              color: DarkTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 16),

          // Prononciation
          if (feedback.containsKey('pronunciation_scores'))
            _buildScoreSection(
              'Prononciation',
              (feedback['pronunciation_scores'] as Map<String, dynamic>)['overall'] ?? 0.0,
              DarkTheme.accentCyan,
            ),

          // Fluidité
          if (feedback.containsKey('fluency_metrics'))
            _buildScoreSection(
              'Fluidité',
              (feedback['fluency_metrics'] as Map<String, dynamic>)['speech_rate'] != null
                  ? (feedback['fluency_metrics'] as Map<String, dynamic>)['speech_rate'] / 5.0
                  : 0.0,
              DarkTheme.primaryBlue,
            ),

          // Prosodie
          if (feedback.containsKey('prosody_metrics'))
            _buildScoreSection(
              'Prosodie',
              (feedback['prosody_metrics'] as Map<String, dynamic>)['pitch_variation'] != null
                  ? (feedback['prosody_metrics'] as Map<String, dynamic>)['pitch_variation'] * 5.0
                  : 0.0,
              DarkTheme.primaryPurple,
            ),
        ],
      ),
    );

    logger.performance(_tag, 'buildFeedback', end: true);
    return result;
  }

  /// Construit une section de score
  Widget _buildScoreSection(String title, double score, Color color) {
    // Limiter le score entre 0 et 1
    final normalizedScore = score.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DarkTheme.textSecondary,
              fontSize: 14,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: normalizedScore,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(normalizedScore * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    logger.i(_tag, '🎵 [AUDIO_FIX] Destruction de la page de scénario');
    
    // Marquer le widget comme détruit avant toute opération
    _isDisposed = true;
    
    try {
      // Arrêter le streaming continu
      _stopContinuousStreaming();
      
      // Annuler l'abonnement à la session en premier
      if (_sessionSubscription != null) {
        _sessionSubscription!.close();
        _sessionSubscription = null;
        logger.i(_tag, 'Abonnement à la session annulé');
      }
      if (_aiResponseSubscriptionFromService != null) {
        _aiResponseSubscriptionFromService!.cancel(); // Revenir à cancel() pour StreamSubscription
        _aiResponseSubscriptionFromService = null;
        logger.i(_tag, 'Abonnement à aiResponseStream annulé');
      }
      
      // Capturer les références nécessaires de manière sécurisée
      SessionModel? session;
      try {
        final sessionAsync = ref.read(sessionProvider);
        session = sessionAsync.value;
      } catch (e) {
        // Ignorer les erreurs de ref après la destruction
        logger.i(_tag, 'Impossible d\'accéder au provider de session: widget déjà détruit');
      }
      
      // Terminer la session si elle est active et si on a pu récupérer l'ID
      if (session?.sessionId != null) {
        final sessionId = session!.sessionId;
        logger.i(_tag, 'Fin de la session: $sessionId');
        
        try {
          // Tenter de terminer la session de manière sécurisée
          final sessionNotifier = ref.read(sessionProvider.notifier);
          sessionNotifier.endSession();
        } catch (e) {
          // Ignorer les erreurs de ref après la destruction
          logger.i(_tag, 'Impossible de terminer la session: widget déjà détruit');
        }
      }
    } catch (e) {
      logger.e(_tag, 'Erreur dans dispose(): $e');
    }

    super.dispose();
  }
}
