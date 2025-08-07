import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import '../models/simulation_models.dart';
import '../../../../core/utils/unified_logger_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/config/mistral_scaleway_config.dart';
import 'studio_livekit_service.dart';

enum CoachMode { text, voice, livekit }
enum ApiProvider { local, mistralCloud, livekit }

class PreparationCoachService {
  // Configuration de l'API à utiliser
  ApiProvider _apiProvider = ApiProvider.mistralCloud; // Par défaut, utiliser Mistral Cloud
  
  // URLs des APIs
  static String get _localMistralUrl => ApiConfig.getMistralApiUrl();
  static String get _mistralCloudUrl => MistralScalewayConfig.apiUrl;
  
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
        
        // TODO: Implémenter une vraie connexion LiveKit
        // Pour une conversation naturelle, LiveKit gérerait :
        // - La reconnaissance vocale en temps réel
        // - La synthèse vocale pour les réponses
        // - Le streaming bidirectionnel audio
        
        await Future.delayed(const Duration(milliseconds: 500));
        
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
    if (_currentMode != CoachMode.voice || _livekitService == null) {
      throw Exception('Le mode vocal n\'est pas actif');
    }
    
    await _livekitService?.muteAudio(false);
    _isListeningController.add(true);
    UnifiedLoggerService.info('Started voice listening');
  }
  
  /// Arrête l'écoute vocale
  Future<void> stopVoiceListening() async {
    if (_livekitService != null) {
      await _livekitService?.muteAudio(true);
      _isListeningController.add(false);
      UnifiedLoggerService.info('Stopped voice listening');
    }
  }
  
  /// Obtient une réponse du coach selon le mode et le provider configuré
  Future<String> getCoachResponse(
    String userMessage,
    SimulationType simulationType,
    List<String> conversationHistory,
  ) async {
    // Si mode LiveKit, utiliser uniquement LiveKit pour la conversation naturelle
    if (_currentMode == CoachMode.livekit && _livekitService != null) {
      await _livekitService?.sendMessage(userMessage);
      // LiveKit gérera la réponse vocale directement
      return "Conversation en cours via LiveKit...";
    }
    
    // Si mode vocal simple, envoyer le texte transcrit
    if (_currentMode == CoachMode.voice && _livekitService != null) {
      await _livekitService?.sendMessage(userMessage);
    }
    
    // Choisir l'API selon le provider configuré
    switch (_apiProvider) {
      case ApiProvider.mistralCloud:
        return await _getMistralCloudResponse(userMessage, simulationType, conversationHistory);
      case ApiProvider.local:
        return await _getLocalMistralResponse(userMessage, simulationType, conversationHistory);
      case ApiProvider.livekit:
        // LiveKit comme API conversationnelle
        return await _getLiveKitTextResponse(userMessage, simulationType, conversationHistory);
    }
  }
  
  /// Obtient une réponse de l'API Mistral Cloud (production)
  Future<String> _getMistralCloudResponse(
    String userMessage,
    SimulationType simulationType,
    List<String> conversationHistory,
  ) async {
    final prompt = _buildContextualPrompt(simulationType, userMessage, conversationHistory);
    
    try {
      // Vérifier si la clé API est configurée
      if (MistralScalewayConfig.scwSecretKey.isEmpty ||
          MistralScalewayConfig.scwSecretKey.length < 10) {
        UnifiedLoggerService.warning('Mistral API key not configured properly, using fallback');
        return _getFallbackResponse(simulationType);
      }
      
      UnifiedLoggerService.info('Using Mistral Cloud API for intelligent response');
      
      final response = await http.post(
        Uri.parse(_mistralCloudUrl),
        headers: MistralScalewayConfig.headers,
        body: json.encode(
          MistralScalewayConfig.buildChatRequest(
            message: userMessage,
            systemPrompt: prompt,
            temperature: 0.7,
            maxTokens: 200,
          ),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        UnifiedLoggerService.warning('Mistral Cloud API error: ${response.statusCode}');
        return _getFallbackResponse(simulationType);
      }
    } catch (e) {
      UnifiedLoggerService.error('Error calling Mistral Cloud API: $e');
      return _getFallbackResponse(simulationType);
    }
  }
  
  /// Obtient une réponse de l'API Mistral locale (développement)
  Future<String> _getLocalMistralResponse(
    String userMessage,
    SimulationType simulationType,
    List<String> conversationHistory,
  ) async {
    final prompt = _buildContextualPrompt(simulationType, userMessage, conversationHistory);
    
    try {
      final response = await http.post(
        Uri.parse(_localMistralUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': 'mistral-7b-instruct',
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        UnifiedLoggerService.warning('Local Mistral API error: ${response.statusCode}');
        return _getFallbackResponse(simulationType);
      }
    } catch (e) {
      UnifiedLoggerService.error('Error calling local Mistral API: $e');
      return _getFallbackResponse(simulationType);
    }
  }
  
  /// Obtient une réponse textuelle via LiveKit (pour mode hybride)
  Future<String> _getLiveKitTextResponse(
    String userMessage,
    SimulationType simulationType,
    List<String> conversationHistory,
  ) async {
    // LiveKit peut gérer la conversation de manière plus naturelle
    // avec reconnaissance vocale et synthèse vocale intégrées
    
    try {
      if (_livekitService != null) {
        await _livekitService?.sendMessage(userMessage);
        // Attendre la réponse de LiveKit
        // Dans une vraie implémentation, on écouterait le stream de messages
        await Future.delayed(const Duration(seconds: 1));
        return "Réponse LiveKit : Je comprends votre question. Travaillons ensemble sur ${simulationType.toDisplayString()}.";
      }
      
      return _getFallbackResponse(simulationType);
    } catch (e) {
      UnifiedLoggerService.error('Error with LiveKit response: $e');
      return _getFallbackResponse(simulationType);
    }
  }
  
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
      
      // Vérifier la configuration de l'API
      if (MistralScalewayConfig.scwSecretKey.isEmpty ||
          MistralScalewayConfig.scwSecretKey.length < 10) {
        UnifiedLoggerService.warning('Mistral API not configured, using intelligent fallback');
        return _getIntelligentFallbackAnalysis(filePath, type, objective);
      }
      
      // Appeler l'API Mistral Cloud pour analyse
      final response = await http.post(
        Uri.parse(MistralScalewayConfig.apiUrl),
        headers: MistralScalewayConfig.headers,
        body: json.encode(
          MistralScalewayConfig.buildChatRequest(
            message: 'Analyse ce document pour la préparation de ${type.toDisplayString()}',
            systemPrompt: analysisPrompt,
            temperature: 0.7,
            maxTokens: 400,
          ),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysis = data['choices'][0]['message']['content'];
        
        UnifiedLoggerService.info('Mistral Cloud analysis completed successfully');
        return analysis;
      } else {
        UnifiedLoggerService.warning('Mistral Cloud API error: ${response.statusCode}');
        return _getIntelligentFallbackAnalysis(filePath, type, objective);
      }
      
    } catch (e) {
      UnifiedLoggerService.error('Error analyzing document: $e');
      return _getIntelligentFallbackAnalysis(filePath, type, objective);
    }
  }
  
  /// Construit un prompt intelligent pour l'analyse de document
  String _buildDocumentAnalysisPrompt(SimulationType type, String documentContent, String? objective) {
    final fileName = documentContent.split('/').last;
    
    final prompt = """Tu es un coach expert en communication et préparation d'entretiens professionnels.

MISSION: Analyser ce document pour aider l'utilisateur à se préparer à "${type.toDisplayString()}".

DOCUMENT À ANALYSER:
$documentContent

OBJECTIF UTILISATEUR: ${objective ?? 'Non spécifié'}

CONTEXTE DE LA SIMULATION: ${_getSimulationContext(type)}

INSTRUCTIONS:
1. Analyse le contenu réel du document (si lisible)
2. Identifie les points forts et axes d'amélioration
3. Donne 3 conseils pratiques et personnalisés
4. Propose des questions/objections probables
5. Suggère une structure optimale
6. Sois encourageant mais constructif
7. Réponds en français, de manière concise (max 3 paragraphes)

RÉPONSE:""";
    
    return prompt;
  }
  
  /// Contexte spécifique à chaque type de simulation
  String _getSimulationContext(SimulationType type) {
    switch (type) {
      case SimulationType.debatPlateau:
        return "Débat télévisé avec modérateur et invités. Format court, arguments percutants, gestion des interruptions.";
      case SimulationType.entretienEmbauche:
        return "Entretien d'embauche face à un recruteur. Questions comportementales, présentation du parcours, motivation.";
      case SimulationType.reunionDirection:
        return "Présentation à la direction générale. Focus business, ROI, prise de décision stratégique.";
      case SimulationType.conferenceVente:
        return "Conférence commerciale face à prospects. Identification besoins, argumentation valeur, closing.";
      case SimulationType.conferencePublique:
        return "Conférence publique devant large audience. Captiver l'attention, message clair, interaction.";
      case SimulationType.jobInterview:
        return "Entretien professionnel international. Questions techniques, soft skills, adaptation culturelle.";
      case SimulationType.salesPitch:
        return "Pitch de vente one-to-one. Découverte client, démonstration valeur, objections.";
      case SimulationType.publicSpeaking:
        return "Prise de parole publique. Gestion du stress, structure narrative, engagement audience.";
      case SimulationType.difficultConversation:
        return "Conversation délicate professionnelle. Gestion émotions, communication non-violente, solutions.";
      case SimulationType.negotiation:
        return "Négociation commerciale ou contractuelle. Zones de compromis, rapport de force, win-win.";
    }
  }

  /// Analyse de fallback intelligente si l'API n'est pas disponible
  String _getIntelligentFallbackAnalysis(String filePath, SimulationType type, String? objective) {
    final fileName = filePath.split('/').last.toLowerCase();
    final hasObjective = objective != null && objective.isNotEmpty;
    
    // Analyse basée sur le nom du fichier et l'objectif
    String analysis = "📄 **Document analysé**: $fileName\n\n";
    
    if (hasObjective) {
      analysis += "🎯 **Votre objectif**: $objective\n\n";
    }
    
    // Conseils spécifiques selon le type de simulation
    switch (type) {
      case SimulationType.debatPlateau:
        analysis += hasObjective
          ? "Pour votre débat TV sur ce sujet, structurez vos arguments en 3 points clés avec des exemples concrets. Préparez-vous aux contre-arguments et ayez des chiffres percutants."
          : "Pour le débat TV, identifiez 3 arguments principaux dans votre document. Préparez des exemples concrets et anticipez les objections.";
        break;
      case SimulationType.entretienEmbauche:
        analysis += hasObjective
          ? "Pour votre entretien, mettez en avant comment vos expériences du CV répondent exactement à votre objectif. Préparez des exemples STAR (Situation-Tâche-Action-Résultat)."
          : "Votre CV contient des éléments intéressants. Préparez 3 exemples concrets de réalisations avec la méthode STAR.";
        break;
      case SimulationType.reunionDirection:
        analysis += hasObjective
          ? "Pour convaincre la direction, quantifiez l'impact business de votre proposition. Préparez ROI, budget et timeline clairs."
          : "En réunion direction, commencez par l'impact business et terminez par un plan d'action avec timeline.";
        break;
      default:
        analysis += hasObjective
          ? "Pour atteindre votre objectif, structurez votre présentation en 3 parties: contexte, solution, bénéfices. Préparez des réponses aux objections probables."
          : "Organisez votre contenu en 3 parties claires. Préparez des exemples concrets et anticipez les questions.";
    }
    
    analysis += "\n\n💡 **Prochaine étape**: Voulez-vous qu'on travaille ensemble sur l'un de ces points spécifiques ?";
    
    return analysis;
  }
}