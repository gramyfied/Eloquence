import 'dart:async';
import 'dart:io';
import '../../features/confidence_boost/domain/entities/confidence_models.dart';
import '../../features/confidence_boost/domain/entities/confidence_scenario.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:eloquence_2_0/core/config/app_config.dart'; // Import AppConfig

class CleanLiveKitService extends ChangeNotifier {
  Room? _room;
  bool _isConnected = false;
  EventsListener? _listener;

  // Déclaration du MethodChannel au niveau de la classe
  final MethodChannel _audioDiagnosticChannel = const MethodChannel('eloquence/audio');

  Room? get room => _room;
  bool get isConnected => _isConnected;
  LocalParticipant? get localParticipant => _room?.localParticipant;

  final _audioStreamController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get onAudioReceivedStream => _audioStreamController.stream;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  Future<bool> connect(String url, String token) async {
    _logger.i('Attempting to connect to LiveKit...');
    _logger.i('[DIAGNOSTIC] LiveKit URL: $url');
    _logger.i('[DIAGNOSTIC] Token (first 30 chars): ${token.length > 30 ? token.substring(0, 30) : token}...');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      _logger.i('[DIAGNOSTIC] LiveKit Connection Attempt $attempt of $maxRetries...');
      try {
        // ÉTAPE 1: Demander permissions microphone AVANT connexion
        _logger.i('[DIAGNOSTIC] Requesting microphone permissions...');
        
        if (kIsWeb) {
          // Pour le web, les permissions sont gérées automatiquement par le navigateur
          _logger.i('[DIAGNOSTIC] Web platform - permissions handled by browser');
        } else {
          final micPermission = await Permission.microphone.request();
          if (!micPermission.isGranted) {
            _logger.e('[DIAGNOSTIC] Microphone permission denied!');
            return false;
          }
          _logger.i('[DIAGNOSTIC] Microphone permission granted');
        }

        // Configuration pour mobile avec sensibilité réduite
        const roomOptions = RoomOptions(
          adaptiveStream: true, // Réactivé pour la performance
          dynacast: true, // Réactivé pour la performance
          // Configuration optimisée pour mobile avec sensibilité réduite
          defaultAudioPublishOptions: AudioPublishOptions(
            dtx: true, // Discontinuous Transmission pour réduire le bruit
          ),
          defaultVideoPublishOptions: VideoPublishOptions(),
        );
        _logger.i('[DIAGNOSTIC] RoomOptions: adaptiveStream et dynacast activés.');

        _room = Room(roomOptions: roomOptions);
        _listener = _room!.createListener();
        _setupRemoteTrackListener();

        _listener!
          ..on<RoomConnectedEvent>((event) async {
            _logger.i('Successfully connected to LiveKit room: ${event.room.name}');
            _isConnected = true;
                        
            // ÉTAPE 2: Attendre que localParticipant soit disponible
            _logger.i('[DIAGNOSTIC] Waiting for local participant...');
            await _waitForLocalParticipant();
            
            notifyListeners();
          })
          ..on<RoomDisconnectedEvent>((event) {
            _logger.e('Disconnected from LiveKit room. Reason: ${event.reason}', error: event.reason);
            _isConnected = false;
            _room = null;
            _listener?.dispose();
            _listener = null; // Ensure listener is nulled
            notifyListeners();
          })
          ..on<RoomReconnectedEvent>((event) {
            _logger.i('RoomReconnectedEvent: Reconnected to LiveKit room.');
          })
          ..on<RoomReconnectingEvent>((event) {
            _logger.w('RoomReconnectingEvent: Reconnecting to LiveKit room...');
          });

        final connectOptions = ConnectOptions(
          autoSubscribe: true,
          // Utilise les serveurs ICE définis dans AppConfig
          rtcConfiguration: RTCConfiguration(
            iceServers: AppConfig.iceServers.map((s) => RTCIceServer(
              urls: List<String>.from(s['urls']),
              username: s['username'],
              credential: s['credential'],
            )).toList(),
            iceTransportPolicy: RTCIceTransportPolicy.all,
          ),
        );

        _logger.i('Connecting with ICE servers configured in AppConfig.');
        _logger.i('[DIAGNOSTIC] Starting connection attempt...');
        
        await _room!.connect(
          AppConfig.livekitUrl, // Utilisation de AppConfig.livekitUrl
          token,
          connectOptions: connectOptions,
        );
        
        _logger.i('[DIAGNOSTIC] Connection successful!');
        return true; // Connexion réussie
      } catch (e, stackTrace) {
        _logger.e('LiveKit connection failed on attempt $attempt: $e', error: e, stackTrace: stackTrace);
        _logger.e('[DIAGNOSTIC] Error type: ${e.runtimeType}');
        _logger.e('[DIAGNOSTIC] Error details: ${e.toString()}');
        
        // Diagnostic spécifique pour les erreurs courantes
        if (e.toString().contains('SocketException')) {
          _logger.e('[DIAGNOSTIC] Network error - Check IP address and firewall');
        } else if (e.toString().contains('401') || e.toString().contains('403')) {
          _logger.e('[DIAGNOSTIC] Authentication error - Check token');
        } else if (e.toString().contains('timeout')) {
          _logger.e('[DIAGNOSTIC] Connection timeout - Service may be unreachable');
        }

        _isConnected = false;
        _room = null;
        _listener?.dispose();
        _listener = null;
        notifyListeners();

        if (attempt < maxRetries) {
          _logger.i('Retrying LiveKit connection in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        } else {
          _logger.e('All LiveKit connection retries failed.');
          return false; // Tous les essais ont échoué
        }
      }
    }
    return false; // Devrait être atteint si la boucle se termine sans succès
  }

  Future<void> disconnect() async {
    _logger.i('Attempting to disconnect from LiveKit...');
    if (_room != null) {
      await _room!.disconnect();
      // L'état _isConnected et notifyListeners sont gérés par RoomDisconnectedEvent
    }
    _room = null; // Assurer le nettoyage même si pas d'événement
    _isConnected = false; // Assurer l'état
    _listener?.dispose();
    _listener = null;
    notifyListeners(); // Notifier au cas où l'événement ne serait pas déclenché
    _logger.i('Disconnected from LiveKit.');
  }

  Future<void> _waitForLocalParticipant() async {
    _logger.i('[DIAGNOSTIC] Checking for local participant...');
    
    // Attendre jusqu'à 10 secondes pour que localParticipant soit disponible
    for (int i = 0; i < 50; i++) {
      if (_room?.localParticipant != null) {
        _logger.i('[DIAGNOSTIC] Local participant found after ${i * 200}ms');
        _logger.i('[DIAGNOSTIC] Local participant identity: ${_room!.localParticipant!.identity}');
        await _configureMicrophoneSensitivity(); // Configuration de la sensibilité
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    _logger.e('[DIAGNOSTIC] Local participant still null after 10 seconds!');
  }

  void _setupRemoteTrackListener() {
    if (_room == null || _listener == null) return;

    _listener!
      ..on<TrackSubscribedEvent>((event) async {
        final participantIdentity = event.participant.identity;
        
        // DIAGNOSTIC AMÉLIORÉ : Logger TOUS les détails du track
        _logger.i('[AUDIO DIAGNOSTIC] Track souscrit:');
        _logger.i('  - Participant: $participantIdentity');
        _logger.i('  - Track SID: ${event.track.sid}');
        _logger.i('  - Track Kind: ${event.track.kind}');
        _logger.i('  - Track Source: ${event.track.source}');
        _logger.i('  - Track Muted: ${event.track.muted}');
        
        // DIAGNOSTIC SPÉCIFIQUE : Audio de l'agent
        if (event.track is RemoteAudioTrack) {
          _logger.i('[AUDIO DIAGNOSTIC] Détection Réussie: C\'est bien un RemoteAudioTrack.');
          if (participantIdentity.contains('agent') ||
              participantIdentity.contains('eloquence') ||
              participantIdentity.contains('roomio')) {
            
            _logger.i('🔊 [CRITIQUE] Audio agent détecté - DIAGNOSTIC COMPLET');
            await _diagnosticAgentAudio(event.track as RemoteAudioTrack);
          } else {
            _logger.i('🎤 [INFO] Audio utilisateur détecté: $participantIdentity');
          }
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        _logger.i('[AUDIO DIAGNOSTIC] Track désouscrit: ${event.track.sid}');
      })
      ..on<TrackMutedEvent>((event) {
        _logger.w('[AUDIO WARNING] Track muté: ${event.publication.sid} par ${event.participant.identity}');
      })
      ..on<TrackUnmutedEvent>((event) {
        _logger.i('[AUDIO INFO] Track démuté: ${event.publication.sid} par ${event.participant.identity}');
      })
      ..on<LocalTrackPublishedEvent>((event) {
        _logger.i('[AUDIO INFO] Track local publié: ${event.publication.sid}');
      })
      ..on<DataReceivedEvent>((event) {
        // GARDER pour compatibilité mais ne pas utiliser pour l'audio
        final participantIdentity = event.participant?.identity ?? '';
        if (participantIdentity.contains('agent') && _audioStreamController.hasListener) {
          _logger.d('Data received from agent: ${event.data.length} bytes (legacy)');
          _audioStreamController.add(Uint8List.fromList(event.data));
        }
      })
      ..on<TrackPublishedEvent>((event) {
        if (event.participant.identity.contains('agent')) {
          _logger.i('🔊 [IMPORTANT] Track publié par agent - Type: ${event.publication.kind}');
          _logger.i('  - Source: ${event.publication.source}');
          _logger.i('  - Name: ${event.publication.name}');
        }
      });
  }

  Future<void> _diagnosticAgentAudio(RemoteAudioTrack audioTrack) async {
    _logger.i('🔊 [DIAGNOSTIC AGENT AUDIO] Début diagnostic...');
    
    try {
      // 1. VÉRIFIER ÉTAT DU TRACK
      _logger.i('🔊 [DIAGNOSTIC] État track:');
      _logger.i('  - Enabled: ${!audioTrack.muted}');
      _logger.i('  - Muted: ${audioTrack.muted}');
      _logger.i('  - SID: ${audioTrack.sid}');
      
      // 2. FORCER ACTIVATION - Note: Les RemoteAudioTrack ne peuvent pas être "enabled" manuellement
      if (audioTrack.muted) {
        _logger.i('🔊 [CORRECTION] Track muté détecté (normal pour RemoteAudioTrack)');
        _logger.i('✅ [CORRECTION] Les RemoteAudioTrack se démutent automatiquement');
      }
      
      // 3. FORCER DÉMUTAGE - Non applicable aux RemoteAudioTrack
      _logger.i('🔊 [CORRECTION] Démutage automatique par LiveKit');
      
      // 4. FORCER VOLUME MAXIMUM
      _logger.i('🔊 [CORRECTION] Configuration volume...');
      try {
        // L'API livekit_client gère le volume de lecture des tracks distants automatiquement.
        // Il n'y a pas de méthode directe pour forcer le volume d'un RemoteAudioTrack après sa souscription via son objet.
        _logger.i('✅ [CORRECTION] Volume des tracks distants géré automatiquement par LiveKit. Assurez-vous que le volume système de l\'appareil est suffisant.');
      } catch (e) {
        _logger.d('ℹ️ [CORRECTION] Erreur ou méthode setVolume non disponible pour RemoteAudioTrack: $e');
      }
      
      // Logique de forçage du haut-parleur retirée d'ici pour être centralisée dans _configureAndroidAudio
      // afin d'éviter les interférences et les problèmes de timing/état.

      // 5. DIAGNOSTIC SYSTÈME AUDIO (qui comprend la configuration Android/iOS)
      await _diagnosticSystemAudio();
      
      // 6. FORCER CONFIGURATION WEBRTC
      await _forceWebRTCAudioConfig();
      
      // 7. VÉRIFIER STATISTIQUES
      await _checkAudioStats(audioTrack);
      
      _logger.i('✅ [DIAGNOSTIC AGENT AUDIO] Diagnostic terminé');
      
    } catch (e) {
      _logger.e('❌ [DIAGNOSTIC AGENT AUDIO] Erreur: $e');
    }
  }

  Future<void> _diagnosticSystemAudio() async {
    _logger.i('🔊 [DIAGNOSTIC SYSTÈME] Vérification système audio...');
    
    try {
      // Vérifier permissions
      final micPermission = await Permission.microphone.status;
      _logger.i('🔊 [DIAGNOSTIC SYSTÈME] Permission micro: $micPermission');
      
      // Forcer permissions si nécessaire
      if (!micPermission.isGranted) {
        _logger.i('🔊 [CORRECTION] Demande permission micro...');
        await Permission.microphone.request();
      }
      
      // Configuration spécifique Android
      if (Platform.isAndroid) {
        await _configureAndroidAudio();
      }
      
      // Configuration spécifique iOS
      if (Platform.isIOS) {
        await _configureiOSAudio();
      }
      
    } catch (e) {
      _logger.e('❌ [DIAGNOSTIC SYSTÈME] Erreur: $e');
    }
  }

  Future<void> _configureAndroidAudio() async {
    _logger.i('🔊 [ANDROID] Configuration audio Android...');
    
    try {
      // Utiliser _audioDiagnosticChannel qui est maintenant un membre de la classe
      
      try {
        // Obtenir info audio
        final audioInfo = await _audioDiagnosticChannel.invokeMethod('getAudioInfo');
        _logger.i('🔊 [ANDROID] Info audio initiale: $audioInfo');
        
        // Forcer le mode audio à MODE_IN_COMMUNICATION et activer le haut-parleur
        // puis maximiser le volume du flux d'appel vocal.
        final currentAudioModeString = audioInfo['mode'] as String? ?? 'unknown'; // Récupérer comme String
        final isSpeakerphoneOnInitial = audioInfo['isSpeakerphoneOn'] as bool? ?? false; // Récupérer l'état initial du haut-parleur

        // Forcer le mode audio si ce n'est pas déjà 'in_communication'
        if (currentAudioModeString != 'in_communication') {
          _logger.i('🔊 [ANDROID] Forçage du mode audio à MODE_IN_COMMUNICATION (valeur int: 3)...');
          await _audioDiagnosticChannel.invokeMethod('setMode', 3); // 3 correspond à AudioManager.MODE_IN_COMMUNICATION
        } else {
          _logger.i('✅ [ANDROID] Mode audio déjà à MODE_IN_COMMUNICATION.');
        }

        // Toujours forcer le haut-parleur pour s'assurer qu'il est actif
        // Même si currentAudioModeString est "in_communication", isSpeakerphoneOn peut être false.
        if (!isSpeakerphoneOnInitial) {
           _logger.i('🔊 [ANDROID] Forçage du haut-parleur...');
           await _audioDiagnosticChannel.invokeMethod('setSpeakerphoneOn', {'on': true});
        } else {
           _logger.i('✅ [ANDROID] Haut-parleur déjà actif.'); // Log si déjà actif
        }

        // Toujours forcer le haut-parleur APRES avoir potentiellement changé le mode
        _logger.i('🔊 [ANDROID] Forçage du haut-parleur...');
        await _audioDiagnosticChannel.invokeMethod('setSpeakerphoneOn', {'on': true}); 
        
        // Maximiser le volume du STREAM_VOICE_CALL, souvent utilisé en MODE_IN_COMMUNICATION
        _logger.i('🔊 [ANDROID] Maximiser le volume du STREAM_VOICE_CALL...');
        final maxVoiceCallVolume = audioInfo['maxVoiceCallVolume'] as int? ?? 8;
        await _audioDiagnosticChannel.invokeMethod('setStreamVolume', {
          'streamType': 0, // AudioManager.STREAM_VOICE_CALL
          'volume': maxVoiceCallVolume,  
          'flags': 0       
        });

        final updatedAudioInfo = await _audioDiagnosticChannel.invokeMethod('getAudioInfo');
        _logger.i('💡 🔊 [ANDROID] Info audio POST-CONFIG: $updatedAudioInfo');

      } catch (e) {
        _logger.w('⚠️ [ANDROID] Platform channel non configuré ou erreur d\'appel: $e');
        _logger.i('ℹ️ [ANDROID] Configuration native requise pour diagnostics avancés');
      }
      
    } catch (e) {
      _logger.e('❌ [ANDROID] Erreur configuration: $e');
    }
  }

  Future<void> _configureiOSAudio() async {
    _logger.i('🔊 [iOS] Configuration audio iOS...');
    
    try {
      // Utiliser _audioDiagnosticChannel qui est maintenant un membre de la classe
      
      try {
        // Configurer session audio
        await _audioDiagnosticChannel.invokeMethod('configureAudioSession', {
          'category': 'playAndRecord',
          'mode': 'default',
          'options': ['defaultToSpeaker', 'allowBluetooth']
        });
        _logger.i('✅ [iOS] Session audio configurée');
        
        // Activer session
        await _audioDiagnosticChannel.invokeMethod('setActive', true);
        _logger.i('✅ [iOS] Session audio activée');
        
      } catch (e) {
        _logger.w('⚠️ [iOS] Platform channel non configuré: $e');
        _logger.i('ℹ️ [iOS] Configuration native requise pour diagnostics avancés');
      }
      
    } catch (e) {
      _logger.e('❌ [iOS] Erreur configuration: $e');
    }
  }

  Future<void> _forceWebRTCAudioConfig() async {
    _logger.i('🔊 [WEBRTC] Configuration WebRTC audio...');
    
    try {
      if (_room?.engine != null) {
        // Vérifier état connexion
        final connectionState = _room!.connectionState;
        _logger.i('🔊 [WEBRTC] État connexion: $connectionState');
        
        if (connectionState != ConnectionState.connected) {
          _logger.w('⚠️ [WEBRTC] Connexion non établie !');
        }
        
        // Note: Les options de lecture audio sont généralement configurées automatiquement
        _logger.i('✅ [WEBRTC] Configuration WebRTC par défaut active');
      }
      
    } catch (e) {
      _logger.e('❌ [WEBRTC] Erreur configuration: $e');
    }
  }

  Future<void> _checkAudioStats(RemoteAudioTrack audioTrack) async {
    _logger.i('🔊 [STATS] Vérification statistiques audio...');

    try {
      // Obtenir statistiques WebRTC basiques
      _logger.i('🔊 [STATS] Track SID: ${audioTrack.sid}');
      _logger.i('🔊 [STATS] Track muted: ${audioTrack.muted}');
      _logger.i('🔊 [STATS] Track kind: ${audioTrack.kind}');

      // Retarder la récupération des stats pour laisser le temps au flux de s'établir
      await Future.delayed(const Duration(seconds: 3));

      if (_room != null) {
        // ignore: invalid_use_of_internal_member
        final stats = await _room!.engine.subscriber?.pc.getStats() ?? [];
        _logger.i('🔊 [STATS] Stats complètes LiveKit (nombre de rapports: ${stats.length})');

        for (final report in stats) {
          _logger.i('   - Report ID: ${report.id}, Type: ${report.type}, Timestamp: ${report.timestamp}');
          final Map<String, dynamic> values = Map<String, dynamic>.from(report.values);

          if (report.type == 'inbound-rtp') {
            final String? kind = values['kind'] as String?;

            if (kind == 'audio') {
                _logger.i('   -> [STATS WEBRTC AUDIO INBOUND]');
                _logger.i('      - codecId: ${values['codecId'] ?? 'N/A'}');
                _logger.i('      - bytesReceived: ${values['bytesReceived'] ?? 'N/A'}');
                _logger.i('      - packetsReceived: ${values['packetsReceived'] ?? 'N/A'}');
                _logger.i('      - packetsLost: ${values['packetsLost'] ?? 'N/A'}');
                _logger.i('      - jitter: ${values['jitter'] ?? 'N/A'}');
                _logger.i('      - totalSamplesReceived: ${values['totalSamplesReceived'] ?? 'N/A'}');
                _logger.i('      - audioOutputLevel: ${values['audioOutputLevel'] ?? 'N/A'}');
                _logger.i('      - concealedSamples: ${values['concealedSamples'] ?? 'N/A'}');
                _logger.i('      - totalAudioEnergy: ${values['totalAudioEnergy'] ?? 'N/A'}');
            }
          } else if (report.type == 'outbound-rtp') {
              final String? kind = values['kind'] as String?;
              if (kind == 'audio') {
                _logger.i('   -> [STATS WEBRTC AUDIO OUTBOUND]');
                _logger.i('      - codecId: ${values['codecId'] ?? 'N/A'}');
                _logger.i('      - bytesSent: ${values['bytesSent'] ?? 'N/A'}');
                _logger.i('      - packetsSent: ${values['packetsSent'] ?? 'N/A'}');
              }
          }
        }
      }
      
      // Collect stats from publisher (if available)
      // ignore: invalid_use_of_internal_member
      final List<dynamic> publisherStats = await _room!.engine.publisher?.pc.getStats() ?? [];
      
      for (final report in publisherStats) {
        _logger.i('   - Publisher Report ID: ${report.id}, Type: ${report.type}, Timestamp: ${report.timestamp}');
        final Map<String, dynamic> values = Map<String, dynamic>.from(report.values);
        if (values['type'] == 'outbound-rtp') {
          final String? kind = values['kind'] as String?;
          if (kind == 'audio' || kind == 'video') { // Log both for now
            _logger.i('   -> [STATS WEBRTC AUDIO/VIDEO OUTBOUND FROM PUBLISHER]');
            _logger.i('      - codecId: ${values['codecId'] ?? 'N/A'}');
            _logger.i('      - bytesSent: ${values['bytesSent'] ?? 'N/A'}');
            _logger.i('      - packetsSent: ${values['packetsSent'] ?? 'N/A'}');
            _logger.i('      - retries: ${values['retransmittedBytesSent'] ?? 'N/A'}');
          }
        }
      }

      _logger.i('🔊 [STATS] Stats de base collectées');
      
      // Nouveau Timer périodique pour vérifier la continuité du track et les stats
      // Il va désormais logger les stats complètes à chaque itération
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (timer.tick <= 3) {
          _logger.d('🐛 🔊 [STATS - Périodique] Track actif: ${audioTrack.sid}, muted: ${audioTrack.muted}');
          if (_room != null) {
            // ignore: invalid_use_of_internal_member
            final newStats = await _room!.engine.subscriber?.pc.getStats() ?? [];
            for (final report in newStats) {
              final Map<String, dynamic> values =
                  Map<String, dynamic>.from(report.values);
              if (values['type'] == 'inbound-rtp') {
                final String? kind = values['kind'] as String?;
                if (kind == 'audio') {
                  _logger.i('   -> [STATS WEBRTC AUDIO INBOUND - Périodique]');
                  _logger.i('      - bytesReceived: ${values['bytesReceived'] ?? 'N/A'}');
                  _logger.i('      - packetsReceived: ${values['packetsReceived'] ?? 'N/A'}');
                  _logger.i('      - packetsLost: ${values['packetsLost'] ?? 'N/A'}');
                  _logger.i('      - audioOutputLevel: ${values['audioOutputLevel'] ?? 'N/A'}');
                  _logger.i('      - concealedSamples: ${values['concealedSamples'] ?? 'N/A'}');
                  _logger.i('      - totalAudioEnergy: ${values['totalAudioEnergy'] ?? 'N/A'}');
                }
              }
            }
          }
        } else {
          timer.cancel();
          _logger.i('🔊 [STATS] Monitoring des stats audio terminé.');
        }
      });
      
    } catch (e, stackTrace) {
      _logger.e('❌ [STATS] Erreur statistiques: $e', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> publishMyAudio() async {
    if (_room?.localParticipant != null) {
      try {
        _logger.i('Attempting to publish microphone...');
        final LocalTrackPublication<LocalTrack>? publication =
            await _room!.localParticipant!.setMicrophoneEnabled(true);

        if (publication != null) {
          _logger.i('Microphone publication state updated. SID: ${publication.sid}');
          _logger.i('Track Name: ${publication.name}, Source: ${publication.source}');
          _logger.i('Track Muted: ${publication.muted}');
        } else {
          _logger.w('Microphone publication returned null.');
        }
        notifyListeners(); // Notifier que l'état de publication a changé
      } catch (e) {
        _logger.e('Error publishing microphone: $e');
      }
    } else {
      _logger.w('Cannot publish audio, local participant is null.');
    }
  }

  Future<void> unpublishMyAudio() async {
    if (_room?.localParticipant != null) {
      try {
        await _room!.localParticipant!.setMicrophoneEnabled(false);
        _logger.i('Microphone unpublished successfully.');
        notifyListeners(); // Notifier que l'état de publication a changé
      } catch (e) {
        _logger.e('Error unpublishing microphone: $e');
      }
    } else {
      _logger.w('Cannot unpublish audio, local participant is null.');
    }
  }

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  @override
  void dispose() {
    _logger.i('Disposing CleanLiveKitService');
    _listener?.dispose();
    _room?.dispose();
    _audioStreamController.close();
    super.dispose();
  }

  Future<ConfidenceAnalysis> requestConfidenceAnalysis({
    required ConfidenceScenario scenario,
    required int recordingDurationSeconds,
  }) async {
    // Simule une analyse pour l'instant
    await Future.delayed(const Duration(seconds: 2));
    return ConfidenceAnalysis(
      overallScore: 0.85,
      confidenceScore: 0.8,
      fluencyScore: 0.88,
      clarityScore: 0.82,
      energyScore: 0.9,
      feedback: 'Excellente performance ! Votre confiance transparaît naturellement.',
    );
  }
  
  /// Configure la sensibilité du microphone pour réduire les captures de bruit
  Future<void> _configureMicrophoneSensitivity() async {
    try {
      _logger.i('🎤 Configuration de la sensibilité du microphone...');
      
      // Configuration via MethodChannel pour ajuster la sensibilité hardware
      await _audioDiagnosticChannel.invokeMethod('configureMicrophoneSensitivity', {
        'reducedSensitivity': true,
        'noiseGateThreshold': 0.3, // Seuil de bruit élevé (0.0-1.0)
        'gainReduction': 0.5, // Réduction du gain de 50%
        'voiceActivityThreshold': 0.4, // Seuil d'activité vocale plus strict
      });
      
      _logger.i('✅ Microphone sensitivity configured for reduced noise capture.');
    } catch (e) {
      _logger.w('⚠️ Could not configure microphone sensitivity via platform: $e');
      // Fallback: configuration via LiveKit uniquement
    }
  }
}
