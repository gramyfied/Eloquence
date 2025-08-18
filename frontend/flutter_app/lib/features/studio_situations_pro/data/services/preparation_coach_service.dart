import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import '../models/simulation_models.dart';
import '../../../../core/utils/unified_logger_service.dart';
import '../../../../core/config/api_config.dart';
import 'studio_livekit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import for Ref

enum CoachMode { text, voice, livekit }
enum ApiProvider { local, mistralCloud, livekit }

class PreparationCoachService {
  final Ref _ref; // Add Ref
  
  PreparationCoachService(this._ref); // Constructor to initialize Ref

  // Configuration de l'API à utiliser
  ApiProvider _apiProvider = ApiProvider.mistralCloud; // Par défaut, utiliser Mistral Cloud
  
  // LiveKit pour le mode vocal naturel
  StudioLiveKitService? _livekitService;
  Room? _room;
  CoachMode _currentMode = CoachMode.text;
  
  // Stream controllers pour le mode vocal
  final StreamController<String> _voiceResponseController = StreamController<String>.broadcast();
  Stream<String> get voiceResponseStream => _voiceResponseController.stream;
  
  final StreamController<bool> _isListeningController = StreamController<bool>.broadcast();
  Stream<bool> get isListeningStream => _isListeningController.stream;
  
  CoachMode get currentMode => _currentMode;
  
  /// Bascule entre le mode texte, vocal et LiveKit
  Future<void> switchMode(CoachMode mode) async {
    if (_currentMode == mode) return;
    
    if (mode == CoachMode.voice || mode == CoachMode.livekit) {
      await _initializeVoiceMode(useLiveKit: mode == CoachMode.livekit);
    } else {
      await _cleanupVoiceMode();
    }
    
    _currentMode = mode;
    UnifiedLoggerService.info('Switched to $mode mode');
  }
  
  /// Configure le provider d'API à utiliser
  void setApiProvider(ApiProvider provider) {
    _apiProvider = provider;
    UnifiedLoggerService.info('API provider set to: $provider');
  }
  
  /// Initialise le mode vocal avec LiveKit ou reconnaissance vocale simple
  Future<void> _initializeVoiceMode({bool useLiveKit = false}) async {
    try {
      if (useLiveKit) {
        // Mode LiveKit pour conversation naturelle
        UnifiedLoggerService.info('Initializing LiveKit for natural conversation');
        
        _livekitService = _ref.read(studioLiveKitServiceProvider);
        await _livekitService?.connect(
          'eloquence-coach-room', // Room name
          userId: 'coach-user', // User ID for the coach
        );
        
        // Écouter les réponses vocales de LiveKit
        _livekitService?.messageStream.listen((message) {
          _voiceResponseController.add(message);
        });
        
        UnifiedLoggerService.info('LiveKit mode initialized for natural conversation');
      } else {
        // Mode vocal simple avec reconnaissance vocale
        UnifiedLoggerService.info('Initializing simple voice mode');
        
        // Ce mode utilise la reconnaissance vocale du navigateur/device
        // et envoie le texte transcrit à l'API Mistral
        await Future.delayed(const Duration(milliseconds: 500));
        
        UnifiedLoggerService.info('Simple voice mode initialized');
      }
    } catch (e) {
      UnifiedLoggerService.error('Failed to initialize voice mode: $e');
      throw Exception('Impossible d\'activer le mode vocal. Vérifiez votre connexion.');
    }
  }
  
  /// Nettoie les ressources du mode vocal
  Future<void> _cleanupVoiceMode() async {
    await _livekitService?.disconnect();
    _livekitService = null;
    UnifiedLoggerService.info('Voice mode cleaned up');
  }
  
  /// Démarre l'écoute vocale
  Future<void> startVoiceListening() async {
    if (_currentMode == CoachMode.livekit) {
      _isListeningController.add(true);
      UnifiedLoggerService.info('Started LiveKit voice listening');
    } else {
      // Mode vocal simple
      _isListeningController.add(true);
      UnifiedLoggerService.info('Started simple voice listening');
    }
  }
  
  /// Arrête l'écoute vocale
  Future<void> stopVoiceListening() async {
    _isListeningController.add(false);
    UnifiedLoggerService.info('Stopped voice listening');
  }
  
  /// Envoie un message vocal à l'API
  Future<String> sendVoiceMessage(String audioData) async {
    try {
      // Pour l'instant, on simule une réponse vocale
      // Dans une implémentation complète, on enverrait l'audio à l'API
      await Future.delayed(const Duration(seconds: 2));
      
      final response = "J'ai bien reçu votre message vocal. Comment puis-je vous aider dans votre préparation ?";
      _voiceResponseController.add(response);
      
      return response;
    } catch (e) {
      UnifiedLoggerService.error('Error sending voice message: $e');
      throw Exception('Erreur lors de l\'envoi du message vocal');
    }
  }
  
  /// Envoie un message texte au coach IA
  Future<String> sendMessage(String message, SimulationType simulationType, {List<String>? conversationHistory}) async {
    try {
      UnifiedLoggerService.info('Sending message to coach: $message');
      
      // Construire le prompt contextuel
      final history = conversationHistory ?? [];
      final prompt = _buildContextualPrompt(simulationType, message, history);
      
      // Appeler l'API appropriée selon le provider configuré
      String response;
      switch (_apiProvider) {
        case ApiProvider.mistralCloud:
          response = await _callMistralCloudAPI(prompt, message);
          break;
        case ApiProvider.local:
          response = await _callLocalAPI(prompt, message);
          break;
        case ApiProvider.livekit:
          response = await _callLiveKitAPI(prompt, message);
          break;
      }
      
      UnifiedLoggerService.info('Coach response received: $response');
      return response;
      
    } catch (e) {
      UnifiedLoggerService.error('Error sending message to coach: $e');
      return _getFallbackResponse(simulationType);
    }
  }
  
  /// Appelle l'API Mistral Cloud
  Future<String> _callMistralCloudAPI(String prompt, String message) async {
    try {
      final requestBody = {
        'model': 'mistral-nemo-instruct-2407',
        'messages': [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': message},
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      };
      
      final response = await http.post(
        Uri.parse(ApiConfig.getMistralApiUrl()),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      UnifiedLoggerService.error('Mistral Cloud API error: $e');
      throw e;
    }
  }
  
  /// Appelle l'API locale (pour développement)
  Future<String> _callLocalAPI(String prompt, String message) async {
    // Simulation d'une réponse locale
    await Future.delayed(const Duration(milliseconds: 500));
    return "Réponse locale simulée pour le développement.";
  }
  
  /// Appelle l'API LiveKit
  Future<String> _callLiveKitAPI(String prompt, String message) async {
    if (_livekitService != null) {
      await _livekitService!.sendMessage(message);
      // Pour l'instant, on retourne une réponse simulée
      // Dans une implémentation complète, on écouterait le stream de réponses
      return "Message envoyé via LiveKit. Réponse en cours...";
    } else {
      throw Exception('LiveKit service not initialized');
    }
  }
  
  /// Construit un prompt contextuel pour l'IA
  String _buildContextualPrompt(SimulationType type, String message, List<String> history) {
    final basePrompt = """Tu es un coach expert en communication pour l'exercice "${type.toDisplayString()}".
    
Ton rôle :
- Donner des conseils pratiques et personnalisés
- Aider à structurer les arguments
- Anticiper les objections possibles
- Être encourageant mais constructif
- Répondre en français, de manière concise (max 2 phrases)
    
Contexte de la simulation : ${_getSimulationContext(type)}
    
Historique de conversation : ${history.join(' | ')}""";
    
    return basePrompt;
  }
  
  /// Obtient le contexte de simulation
  String _getSimulationContext(SimulationType type) {
    final contexts = {
      SimulationType.debatPlateau: "Débat télévisé en direct avec des experts et un public",
      SimulationType.entretienEmbauche: "Entretien d'embauche avec un recruteur senior",
      SimulationType.reunionDirection: "Réunion de direction avec des décideurs",
      SimulationType.conferenceVente: "Présentation commerciale devant des prospects",
      SimulationType.conferencePublique: "Conférence publique devant un large auditoire",
      SimulationType.jobInterview: "Entretien d'embauche avec questions techniques",
      SimulationType.salesPitch: "Pitch de vente en 2 minutes",
      SimulationType.publicSpeaking: "Prise de parole en public",
      SimulationType.difficultConversation: "Conversation difficile avec un collègue",
      SimulationType.negotiation: "Négociation commerciale",
    };
    
    return contexts[type] ?? "Communication professionnelle";
  }
  
  /// Réponse de fallback générique
  String _getFallbackResponse(SimulationType type) {
    final responses = {
      SimulationType.debatPlateau: "Excellente question ! Pour un débat TV, structure tes arguments en 3 points clés et prépare des exemples concrets.",
      SimulationType.entretienEmbauche: "Bonne réflexion ! Pour l'entretien, prépare des exemples STAR (Situation, Tâche, Action, Résultat) qui démontrent tes compétences.",
      SimulationType.reunionDirection: "Très pertinent ! En réunion de direction, commence par l'impact business et termine par un plan d'action clair.",
      SimulationType.conferenceVente: "Parfait ! Pour la vente, identifie d'abord les besoins du client, puis présente ta solution comme LA réponse à ses défis.",
      SimulationType.conferencePublique: "Excellent point ! Pour captiver ton audience, commence par une accroche forte et utilise la règle des 3 : 3 idées max, 3 exemples par idée.",
      SimulationType.jobInterview: "Bonne approche ! Pour l'entretien, mets en avant tes réalisations concrètes et montre comment tu peux apporter de la valeur à l'entreprise.",
      SimulationType.salesPitch: "C'est une excellente stratégie ! Focus sur les bénéfices pour le client, pas sur les caractéristiques du produit.",
      SimulationType.publicSpeaking: "Très bien ! Pour ta prise de parole, pense à varier ton rythme et utilise des pauses pour créer de l'impact.",
      SimulationType.difficultConversation: "Sage approche ! Dans une conversation difficile, écoute d'abord, reformule pour montrer ta compréhension, puis propose des solutions.",
      SimulationType.negotiation: "Stratégie pertinente ! En négociation, identifie les intérêts communs et propose des options créatives qui satisfont les deux parties.",
    };
    
    return responses[type] ?? "C'est une excellente question ! Continue à réfléchir à tes arguments principaux et à la façon de les présenter clairement.";
  }
  
  /// Fallback amélioré avec analyse du message utilisateur
  String _getEnhancedFallbackResponse(SimulationType type, String userMessage) {
    final lowercaseMessage = userMessage.toLowerCase();
    
    // Réponses contextuelles basées sur les mots-clés
    if (lowercaseMessage.contains('argument') || lowercaseMessage.contains('point')) {
      return "Excellent ! Pour structurer tes arguments, utilise la règle des 3 : 3 points clés maximum, chacun avec un exemple concret. Quel est ton argument le plus fort ?";
    }
    
    if (lowercaseMessage.contains('stress') || lowercaseMessage.contains('nerveux') || lowercaseMessage.contains('peur')) {
      return "Je comprends le stress ! Technique rapide : respire profondément 3 fois, visualise ta réussite, et rappelle-toi que tu maîtrises ton sujet. Qu'est-ce qui t'inquiète le plus ?";
    }
    
    if (lowercaseMessage.contains('question') || lowercaseMessage.contains('objection')) {
      return "Très bonne anticipation ! Pour chaque objection, prépare : 1) Écoute et reformule, 2) Reconnais le point valide, 3) Apporte ta contre-argumentation avec des faits. Quelle objection redoutes-tu ?";
    }
    
    if (lowercaseMessage.contains('introduction') || lowercaseMessage.contains('commencer')) {
      return "L'introduction est cruciale ! Formule d'impact : Accroche (statistique/question), Contexte (pourquoi maintenant), Annonce du plan (3 parties max). Tu as une idée d'accroche ?";
    }
    
    // Fallback général avec encouragement
    return "${_getFallbackResponse(type)} Peux-tu me dire ce qui te préoccupe le plus dans ta préparation ?";
  }
  
  /// Analyse intelligente d'un document téléchargé avec l'API Mistral Cloud
  Future<String> analyzeDocument(String filePath, SimulationType type, {String? objective}) async {
    try {
      UnifiedLoggerService.info('Analyzing document: $filePath for ${type.toDisplayString()}');
      
      // Lire le contenu du fichier
      final file = File(filePath);
      String documentContent = '';
      
      if (await file.exists()) {
        try {
          // Essayer de lire le fichier comme texte (pour PDF simple et TXT)
          documentContent = await file.readAsString();
          
          // Si le fichier est trop gros, prendre les premiers 3000 caractères
          if (documentContent.length > 3000) {
            documentContent = documentContent.substring(0, 3000) + '... [document tronqué]';
          }
        } catch (e) {
          // Si la lecture directe échoue (fichier binaire), extraire ce qu'on peut
          UnifiedLoggerService.warning('Cannot read file as text, using filename analysis: $e');
          documentContent = 'Fichier: $filePath (analyse basée sur le nom du fichier)';
        }
      } else {
        documentContent = 'Fichier: $filePath (fichier non trouvé, analyse basée sur le nom)';
      }
      
      // Construire le prompt d'analyse intelligent
      final analysisPrompt = _buildDocumentAnalysisPrompt(type, documentContent, objective);
      
      UnifiedLoggerService.info('Calling Mistral API for document analysis');
      
      final requestBody = {
        'model': 'mistral-nemo-instruct-2407',
        'messages': [
          {'role': 'system', 'content': analysisPrompt},
          {'role': 'user', 'content': 'Analyse ce document pour la préparation de ${type.toDisplayString()}'},
        ],
        'max_tokens': 400,
        'temperature': 0.7,
      };
      
      // Appeler l'API Mistral Cloud pour analyse
      final response = await http.post(
        Uri.parse(ApiConfig.getMistralApiUrl()),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(requestBody),
      );
      
      UnifiedLoggerService.info('Document analysis response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysis = data['choices'][0]['message']['content'];
        
        UnifiedLoggerService.info('Mistral Cloud analysis completed successfully');
        return analysis;
      } else {
        UnifiedLoggerService.error('Mistral Cloud API error: ${response.statusCode} - ${response.body}');
        return _getIntelligentFallbackAnalysis(filePath, type, objective);
      }
      
    } catch (e) {
      UnifiedLoggerService.error('Error analyzing document: $e');
      UnifiedLoggerService.error('Document analysis stack trace: ${StackTrace.current}');
      return _getIntelligentFallbackAnalysis(filePath, type, objective);
    }
  }
  
  /// Construit un prompt intelligent pour l'analyse de document
  String _buildDocumentAnalysisPrompt(SimulationType type, String documentContent, String? objective) {
    final basePrompt = """Tu es un coach expert en communication qui analyse des documents pour aider à la préparation de l'exercice "${type.toDisplayString()}".

Ton rôle :
- Analyser le contenu du document fourni
- Identifier les points clés pertinents pour l'exercice
- Suggérer des améliorations ou des éléments à développer
- Donner des conseils pratiques basés sur le contenu
- Répondre en français, de manière structurée et constructive

Contexte de la simulation : ${_getSimulationContext(type)}

Objectif spécifique : ${objective ?? 'Améliorer la préparation générale'}

Document à analyser :
$documentContent

Analyse ce document et donne des conseils spécifiques pour améliorer la préparation.""";
    
    return basePrompt;
  }
  
  /// Analyse de fallback intelligente basée sur le nom du fichier
  String _getIntelligentFallbackAnalysis(String filePath, SimulationType type, String? objective) {
    final fileName = filePath.split('/').last.toLowerCase();
    
    if (fileName.contains('cv') || fileName.contains('resume')) {
      return "Analyse de CV détectée ! Pour ${type.toDisplayString()}, concentre-toi sur les expériences les plus pertinentes et prépare des exemples concrets de tes réalisations.";
    }
    
    if (fileName.contains('presentation') || fileName.contains('slide')) {
      return "Document de présentation identifié ! Vérifie que chaque slide a un message clair et que ta structure suit une logique narrative cohérente.";
    }
    
    if (fileName.contains('script') || fileName.contains('texte')) {
      return "Script détecté ! Pratique ta diction, varie ton rythme, et prévois des pauses stratégiques pour maintenir l'attention.";
    }
    
    return "Document analysé ! Pour ${type.toDisplayString()}, assure-toi que ton contenu est bien structuré et que tes arguments sont clairs et convaincants.";
  }
  
  /// Construit un prompt pour l'analyse documentaire
  String _buildDocumentualPrompt(SimulationType type, String documentContent, String? objective) {
    return _buildDocumentAnalysisPrompt(type, documentContent, objective);
  }
  
  /// Dispose des ressources
  void dispose() {
    _voiceResponseController.close();
    _isListeningController.close();
    _cleanupVoiceMode();
  }
}

// Provider pour le service
final preparationCoachServiceProvider = Provider<PreparationCoachService>((ref) {
  return PreparationCoachService(ref);
});
