import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:eloquence_2_0/core/theme/eloquence_unified_theme.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/models/simulation_models.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/services/preparation_coach_service.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  final SimulationType simulationType;

  const PreparationScreen({
    Key? key,
    required this.simulationType,
  }) : super(key: key);

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen> with TickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  // Contrôleurs supprimés : plus besoin de prénom/sujet
  late PreparationCoachService _coachService;
  // (supprimé) _isLoadingResponse non utilisé
  // Plus besoin de _canContinue
  
  // Animation controllers
  late AnimationController _micAnimationController;
  // (supprimé) _micPulseAnimation non utilisé

  @override
  void initState() {
    super.initState();
    _coachService = ref.read(preparationCoachServiceProvider);
    
    // Initialiser l'animation du micro
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    // (supprimé) _micPulseAnimation non utilisé
    
    // Message d'accueil contextuel direct
    _messages.add(
      Message(sender: Sender.ai, text: _getWelcomeMessage()),
    );
  }

  // Méthode supprimée : plus besoin de vérification

  String _getWelcomeMessage() {
    switch (widget.simulationType) {
      case SimulationType.debatPlateau:
        return "🎬 Prêt pour le débat TV ? Je suis ton coach ! Tu peux me parler en tapant du texte ou en activant le mode vocal avec le micro. Je vais t'aider à structurer tes arguments et anticiper les questions difficiles !";
      case SimulationType.entretienEmbauche:
        return "💼 Préparons ton entretien d'embauche ! Tu peux échanger avec moi par écrit ou vocalement. Parle-moi de tes compétences clés et de tes motivations.";
      case SimulationType.reunionDirection:
        return "📊 Réunion de direction en vue ! Chat ou vocal, à toi de choisir. Quel sujet vas-tu présenter ? Je t'aide à convaincre la direction.";
      case SimulationType.conferenceVente:
        return "🚀 Conférence de vente ! Mode texte ou vocal disponible. Dis-moi quel produit/service tu présentes et à qui tu t'adresses.";
      case SimulationType.conferencePublique:
        return "🎯 Conférence publique ! Tu peux me parler ou écrire. Quel est ton message principal ? Je t'aide à captiver ton audience.";
      case SimulationType.jobInterview:
        return "👔 Préparons ton entretien ! Chat textuel ou vocal, comme tu préfères. Parle-moi du poste que tu vises et de tes points forts.";
      case SimulationType.salesPitch:
        return "💡 Prêt pour ton pitch de vente ? Écris ou parle-moi. Décris-moi ton produit et ton client cible.";
      case SimulationType.publicSpeaking:
        return "🎤 Prise de parole en public ! Mode texte ou vocal à ta disposition. Quel est ton sujet ? Je vais t'aider à structurer ton discours.";
      case SimulationType.difficultConversation:
        return "💬 Une conversation difficile à préparer ? Tu peux écrire ou parler. Explique-moi le contexte, je t'aide à trouver les bons mots.";
      case SimulationType.negotiation:
        return "🤝 Préparons ta négociation ! Chat ou vocal, c'est toi qui choisis. Quels sont tes objectifs et tes marges de manœuvre ?";
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _subjectController.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(Message(sender: Sender.user, text: text));
    });
    _textController.clear();
    
    try {
      // Construire l'historique de conversation
      final conversationHistory = _messages
          .map((msg) => "${msg.sender == Sender.user ? 'User' : 'AI'}: ${msg.text}")
          .toList();
      
      // Obtenir la réponse du coach IA
      final response = await _coachService.sendMessage(
        text,
        widget.simulationType,
        conversationHistory: conversationHistory,
      );
      
      setState(() {
        _messages.add(Message(sender: Sender.ai, text: response));
      });
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            sender: Sender.ai,
            text: "Désolé, je n'ai pas pu traiter votre message. Réessayez ou continuez la préparation.",
          ),
        );
      });
    }
  }

  void _handleFileUpload() async {
    try {
      // Ouvrir le sélecteur de fichiers
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        
        // Afficher un message de chargement
        setState(() {
          _messages.add(
            Message(
              sender: Sender.user,
              text: "📎 Document téléchargé : ${file.name}",
            ),
          );
          _messages.add(
            Message(
              sender: Sender.ai,
              text: "🔍 Analyse du document en cours...",
            ),
          );
        });

        // Analyser le document avec le service coach
        final analysis = await _coachService.analyzeDocument(
          file.path!,
          widget.simulationType,
        );

        // Afficher le résultat de l'analyse
        setState(() {
          _messages.removeLast(); // Enlever le message de chargement
          _messages.add(
            Message(
              sender: Sender.ai,
              text: "✅ Document analysé avec succès !\n\n$analysis",
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            sender: Sender.ai,
            text: "❌ Erreur lors du téléchargement : ${e.toString()}",
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceTheme.navy,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: _buildChatInterface(), // Toujours afficher le chat
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: EloquenceTheme.navy.withOpacity(0.5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Preparation',
        style: EloquenceTheme.headline3.copyWith(color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  Widget _buildChatBubble(Message message) {
    final bool isUser = message.sender == Sender.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EloquenceTheme.spacingSm),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: EloquenceTheme.violet,
              child: Icon(Icons.psychology, color: Colors.white),
            ),
            const SizedBox(width: EloquenceTheme.spacingSm),
          ],
          Flexible(
            child: ClipRRect(
              borderRadius: EloquenceTheme.borderRadiusLarge,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: EloquenceTheme.spacingSm,
                    horizontal: EloquenceTheme.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? EloquenceTheme.cyan.withOpacity(0.2) 
                        : EloquenceTheme.glassBackground,
                    borderRadius: EloquenceTheme.borderRadiusLarge,
                    border: Border.all(color: EloquenceTheme.glassBorder),
                  ),
                  child: Text(
                    message.text,
                    style: EloquenceTheme.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              _buildSuggestionChip("Plan"),
              _buildSuggestionChip("Arguments"),
              _buildSuggestionChip("Objections"),
            ],
          ),
          const SizedBox(height: EloquenceTheme.spacingMd),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.white70),
                onPressed: _handleFileUpload,
              ),
              const SizedBox(width: EloquenceTheme.spacingSm),
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: EloquenceTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Got it? What else?',
                    hintStyle: EloquenceTheme.bodyMedium.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: EloquenceTheme.glassBackground,
                    border: OutlineInputBorder(
                      borderRadius: EloquenceTheme.borderRadiusLarge,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _handleSendMessage,
                ),
              ),
              const SizedBox(width: EloquenceTheme.spacingSm),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _handleSendMessage(_textController.text),
                style: IconButton.styleFrom(
                  backgroundColor: EloquenceTheme.cyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: EloquenceTheme.borderRadiusCircle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: EloquenceTheme.spacingSm),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _handleSendMessage(label),
        backgroundColor: EloquenceTheme.violet.withOpacity(0.3),
        labelStyle: EloquenceTheme.bodySmall.copyWith(color: Colors.white),
      ),
    );
  }
  // Méthode _buildInfoForm() supprimée - plus besoin de formulaire prénom/sujet
  
  Widget _buildChatInterface() {
    return Column(
      children: [
        // Info bar simplifiée avec type de simulation
        Container(
          padding: const EdgeInsets.all(EloquenceTheme.spacingSm),
          decoration: BoxDecoration(
            color: EloquenceTheme.violet.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(color: EloquenceTheme.glassBorder),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.psychology, color: Colors.white70, size: 16),
              const SizedBox(width: EloquenceTheme.spacingXs),
              Text(
                'Coach ${widget.simulationType.toDisplayString()}',
                style: EloquenceTheme.bodySmall.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        // Sélection du sujet (débat/exercice)
        _buildSubjectPicker(),
        
        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildChatBubble(_messages[index]);
            },
          ),
        ),
        
        // Input area
        _buildInputArea(),
        
        const SizedBox(height: EloquenceTheme.spacingMd),
        
        // Bouton pour commencer la simulation
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EloquenceTheme.cyan,
            shape: RoundedRectangleBorder(
              borderRadius: EloquenceTheme.borderRadiusLarge,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          onPressed: () {
            // Aller directement à la simulation
            context.push(
              '/simulation/${widget.simulationType.toRouteString()}',
              extra: {
                'userName': 'Utilisateur',
                'userSubject': _subjectController.text.isNotEmpty
                    ? _subjectController.text
                    : 'Sujet préparé avec le coach',
              },
            );
          },
          child: const Text(
            'Commencer la Simulation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: EloquenceTheme.spacingMd),
      ],
    );
  }

  Widget _buildSubjectPicker() {
    final suggestions = _getTopicSuggestions(widget.simulationType);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EloquenceTheme.spacingMd,
        vertical: EloquenceTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sujet (optionnel)',
            style: EloquenceTheme.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: EloquenceTheme.spacingXs),
          TextField(
            controller: _subjectController,
            style: EloquenceTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: _subjectHintFor(widget.simulationType),
              hintStyle: EloquenceTheme.bodyMedium.copyWith(color: Colors.white54),
              filled: true,
              fillColor: EloquenceTheme.glassBackground,
              border: OutlineInputBorder(
                borderRadius: EloquenceTheme.borderRadiusLarge,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: EloquenceTheme.spacingSm),
            Wrap(
              spacing: EloquenceTheme.spacingSm,
              runSpacing: EloquenceTheme.spacingSm,
              children: suggestions.map((s) {
                return ActionChip(
                  label: Text(s, overflow: TextOverflow.ellipsis),
                  onPressed: () {
                    _subjectController.text = s;
                  },
                  backgroundColor: EloquenceTheme.violet.withOpacity(0.3),
                  labelStyle: EloquenceTheme.bodySmall.copyWith(color: Colors.white),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getTopicSuggestions(SimulationType type) {
    switch (type) {
      case SimulationType.debatPlateau:
        return const [
          'Intelligence artificielle et emploi',
          'Écologie vs croissance économique',
          'Réseaux sociaux et vie privée',
          'Télétravail: productivité et bien‑être',
          'Éducation publique vs privée',
        ];
      case SimulationType.reunionDirection:
        return const [
          'Feuille de route produit T3',
          'Budget et ROI projet data',
          'Plan de réduction des risques',
        ];
      case SimulationType.conferenceVente:
        return const [
          'Proposition de valeur – Offre Premium',
          'Étude de cas client – Gains mesurés',
          'Roadmap fonctionnalités clés',
        ];
      case SimulationType.conferencePublique:
        return const [
          'Message clé: inclusion numérique',
          'Prévention: cybersécurité au quotidien',
        ];
      case SimulationType.entretienEmbauche:
      case SimulationType.jobInterview:
        return const [
          'Parcours et réalisations majeures',
          'Forces et axes de progrès',
          'Motivations pour le poste',
        ];
      default:
        return const [];
    }
  }

  String _subjectHintFor(SimulationType type) {
    switch (type) {
      case SimulationType.debatPlateau:
        return 'Sujet du débat (ex: IA et emploi)';
      case SimulationType.reunionDirection:
        return 'Sujet de la présentation (ex: KPI T2, risques)';
      case SimulationType.conferenceVente:
        return 'Sujet du pitch (ex: nouvelle offre)';
      case SimulationType.entretienEmbauche:
      case SimulationType.jobInterview:
        return 'Thème clé (ex: projet marquant, compétences)';
      default:
        return 'Sujet principal (optionnel)';
    }
  }
  
  // _getSimulationDescription supprimé (non utilisé)
}

enum Sender { user, ai }

class Message {
  final Sender sender;
  final String text;

  Message({required this.sender, required this.text});
}