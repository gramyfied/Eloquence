import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../domain/entities/scenario_models.dart';
import '../../data/services/ai_scenario_conversation_service.dart';
import '../providers/scenario_provider.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';

/// ÉCRAN 2 : Exercice avec IA + Assistance Interactive
/// Interface conversationnelle révolutionnaire avec aide intégrée et vrais appels API
class ScenarioExerciseScreen extends ConsumerStatefulWidget {
  final ScenarioConfiguration configuration;

  const ScenarioExerciseScreen({
    super.key,
    required this.configuration,
  });

  @override
  ConsumerState<ScenarioExerciseScreen> createState() => _ScenarioExerciseScreenState();
}

class _ScenarioExerciseScreenState extends ConsumerState<ScenarioExerciseScreen>
    with TickerProviderStateMixin {
  
  // Service de conversation IA
  late final AIScenarioConversationService _conversationService;
  
  // États de la conversation
  List<ConversationMessage> messages = [];
  String currentUserInput = "";
  String currentTranscription = "";
  bool isWaitingForResponse = false;
  
  // Système d'aide interactive
  List<String> currentSuggestions = [];
  String selectedSuggestion = "";
  bool showSuggestions = false;
  int helpUsedCount = 0;
  final int maxHelpUsage = 3;
  
  // Métriques temps réel
  int wordCount = 0;
  Duration elapsed = Duration.zero;
  
  // Controllers
  late AnimationController _suggestionController;
  late AnimationController _typingController;
  late Timer _timer;
  late TextEditingController _textController;
  late ScrollController _scrollController;
  
  // Subscriptions aux streams
  StreamSubscription<ConversationMessage>? _messageSubscription;
  StreamSubscription<String>? _transcriptionSubscription;
  StreamSubscription<List<String>>? _suggestionsSubscription;
  StreamSubscription<bool>? _listeningSubscription;

  // Diagnostic et fallback
  bool _showDiagnosticsPanel = false;
  Map<String, dynamic> _diagnosticInfo = {};
  bool _manualInputMode = false;
  bool _connectionIssues = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeConversationService();
    _startTimer();
    
    // Démarrer la conversation après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startConversation();
    });
  }

  void _initializeControllers() {
    _suggestionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _textController = TextEditingController();
    _scrollController = ScrollController();
    
    _textController.addListener(() {
      setState(() {
        currentUserInput = _textController.text;
        if (currentUserInput.isNotEmpty) {
          selectedSuggestion = ""; // Efface la suggestion si l'utilisateur tape
        }
      });
    });
  }
  
  void _initializeConversationService() {
    _conversationService = AIScenarioConversationService();
    
    // S'abonner aux streams
    _messageSubscription = _conversationService.messageStream.listen(_onNewMessage);
    _transcriptionSubscription = _conversationService.transcriptionStream.listen(_onTranscription);
    _suggestionsSubscription = _conversationService.suggestionsStream.listen(_onNewSuggestions);
    _listeningSubscription = _conversationService.isListeningStream.listen(_onListeningStateChanged);
  }
  
  void _onNewMessage(ConversationMessage message) {
    setState(() {
      messages.add(message);
      isWaitingForResponse = false;
      
      if (message.sender == MessageSender.user) {
        wordCount += message.text.split(' ').length;
      }
    });
    
    // Scroll vers le bas
    _scrollToBottom();
  }
  
  void _onTranscription(String transcription) {
    setState(() {
      currentTranscription = transcription;
    });
  }
  
  void _onNewSuggestions(List<String> suggestions) {
    setState(() {
      currentSuggestions = suggestions;
      if (suggestions.isNotEmpty && helpUsedCount < maxHelpUsage) {
        showSuggestions = true;
        _suggestionController.forward();
      }
    });
  }
  
  void _onListeningStateChanged(bool isListening) {
    // L'état d'écoute est géré automatiquement par le service
    if (mounted) {
      setState(() {
        // Mise à jour de l'UI si nécessaire
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceTheme.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: EloquenceTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildConversationArea()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EloquenceTheme.spacingLg,
        vertical: EloquenceTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        boxShadow: EloquenceTheme.shadowSmall,
      ),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: _showExitConfirmation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EloquenceTheme.glassBackground.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EloquenceTheme.glassBorder),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: EloquenceTheme.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: EloquenceTheme.spacingMd),
          
          // Indicateur d'état
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _conversationService.isRecording 
                  ? EloquenceTheme.errorRed.withOpacity(0.2)
                  : EloquenceTheme.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _conversationService.isRecording ? Icons.mic : Icons.mic_off,
                  color: _conversationService.isRecording 
                      ? EloquenceTheme.errorRed 
                      : EloquenceTheme.cyan,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _conversationService.isRecording ? "ÉCOUTE" : "PRÊT",
                  style: TextStyle(
                    color: _conversationService.isRecording 
                        ? EloquenceTheme.errorRed 
                        : EloquenceTheme.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: EloquenceTheme.spacingMd),
          
          // Timer
          Text(
            _formatDuration(elapsed),
            style: EloquenceTheme.timerDisplay.copyWith(fontSize: 16),
          ),
          
          const Spacer(),
          
          // Titre
          Flexible(
            child: Text(
              "CONVERSATION IA",
              style: EloquenceTheme.bodyMedium.copyWith(
                color: EloquenceTheme.cyan,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    return Column(
      children: [
        // Zone de transcription en temps réel
        if (currentTranscription.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(EloquenceTheme.spacingLg),
            padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
            decoration: BoxDecoration(
              color: EloquenceTheme.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EloquenceTheme.cyan.withOpacity(0.3)),
            ),
            child: Text(
              "🎤 $currentTranscription",
              style: TextStyle(
                color: EloquenceTheme.cyan,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        // Liste des messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(EloquenceTheme.spacingLg),
            itemCount: messages.length + (isWaitingForResponse ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length && isWaitingForResponse) {
                return _buildTypingIndicator();
              }
              
              final message = messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ConversationMessage message) {
    bool isAI = message.sender == MessageSender.ai;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) _buildAIAvatar(),
          if (isAI) const SizedBox(width: 12),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAI ? EloquenceTheme.glassBackground : EloquenceTheme.cyan,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isAI ? const Radius.circular(4) : const Radius.circular(20),
                  bottomRight: isAI ? const Radius.circular(20) : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isAI ? EloquenceTheme.white : EloquenceTheme.navy,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (!isAI) const SizedBox(width: 12),
          if (!isAI) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(EloquenceTheme.spacingLg),
      decoration: BoxDecoration(
        color: EloquenceTheme.glassBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Zone de suggestions (si disponibles)
          if (showSuggestions) _buildSuggestionsArea(),
          
          if (showSuggestions) const SizedBox(height: 16),
          
          // Zone de saisie avec aide intégrée
          _buildInputWithHelp(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsArea() {
    return AnimatedBuilder(
      animation: _suggestionController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _suggestionController.value)),
          child: Opacity(
            opacity: _suggestionController.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EloquenceTheme.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EloquenceTheme.violet.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: EloquenceTheme.violet, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Suggestions d'aide IA",
                        style: TextStyle(
                          color: EloquenceTheme.violet,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...currentSuggestions.map((suggestion) => 
                    _buildSuggestionChip(suggestion)
                  ).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _selectSuggestion(suggestion),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EloquenceTheme.glassBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: EloquenceTheme.cyan.withOpacity(0.3)),
          ),
          child: Text(
            suggestion,
            style: const TextStyle(
              color: EloquenceTheme.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputWithHelp() {
    return Container(
      decoration: BoxDecoration(
        color: EloquenceTheme.navy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EloquenceTheme.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Zone de texte avec suggestion fantôme
          Container(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Texte fantôme (suggestion)
                if (selectedSuggestion.isNotEmpty && currentUserInput.isEmpty)
                  Text(
                    selectedSuggestion,
                    style: TextStyle(
                      color: EloquenceTheme.white.withOpacity(0.4),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                // Champ de saisie
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: EloquenceTheme.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: selectedSuggestion.isEmpty 
                        ? "Tapez votre réponse..." 
                        : "",
                    hintStyle: TextStyle(color: EloquenceTheme.white.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ],
            ),
          ),
          
          // Boutons d'aide (si suggestion sélectionnée)
          if (selectedSuggestion.isNotEmpty && currentUserInput.isEmpty)
            _buildHelpButtons(),
          
          // Barre d'actions
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildHelpButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EloquenceTheme.cyan.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, color: EloquenceTheme.violet, size: 16),
          const SizedBox(width: 8),
          Text(
            "Utiliser cette suggestion IA ?",
            style: TextStyle(
              color: EloquenceTheme.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          
          // Bouton Refuser
          GestureDetector(
            onTap: _rejectSuggestion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "Non",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Bouton Accepter
          GestureDetector(
            onTap: _acceptSuggestion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: EloquenceTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EloquenceTheme.successGreen.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: EloquenceTheme.successGreen, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "Oui",
                    style: TextStyle(
                      color: EloquenceTheme.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EloquenceTheme.cyan.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Bouton demander aide IA
          if (helpUsedCount < maxHelpUsage)
            GestureDetector(
              onTap: _requestHelp,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EloquenceTheme.violet.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology,
                  color: EloquenceTheme.violet,
                  size: 20,
                ),
              ),
            ),
          
          if (helpUsedCount < maxHelpUsage) const SizedBox(width: 12),
          
          // Bouton micro (avec état du service)
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _conversationService.isRecording 
                    ? EloquenceTheme.errorRed.withOpacity(0.2)
                    : EloquenceTheme.cyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _conversationService.isRecording ? Icons.mic : Icons.mic_off,
                color: _conversationService.isRecording ? EloquenceTheme.errorRed : EloquenceTheme.cyan,
                size: 20,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Compteur de mots et aide
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Mots: $wordCount",
                style: TextStyle(
                  color: EloquenceTheme.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              if (maxHelpUsage > 0)
                Text(
                  "Aide IA: $helpUsedCount/$maxHelpUsage",
                  style: TextStyle(
                    color: EloquenceTheme.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Bouton envoyer
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: EloquenceTheme.cyan,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Envoyer",
                    style: TextStyle(
                      color: EloquenceTheme.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.send,
                    color: EloquenceTheme.navy,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [EloquenceTheme.cyan, EloquenceTheme.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.psychology,
        color: EloquenceTheme.navy,
        size: 16,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: EloquenceTheme.violet,
      ),
      child: const Icon(
        Icons.person,
        color: EloquenceTheme.navy,
        size: 16,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildAIAvatar(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EloquenceTheme.glassBackground,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 4),
                    _buildTypingDot(1),
                    const SizedBox(width: 4),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    double delay = index * 0.2;
    double animationValue = (_typingController.value + delay) % 1.0;
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: EloquenceTheme.white.withOpacity(0.3 + 0.7 * animationValue),
      ),
    );
  }

  // Méthodes de gestion
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsed = elapsed + const Duration(seconds: 1);
        if (elapsed.inSeconds >= widget.configuration.durationMinutes * 60) {
          _completeExercise();
        }
      });
    });
  }

  Future<void> _startConversation() async {
    final success = await _conversationService.startConversation(widget.configuration);
    
    // Obtenir les informations de diagnostic
    _diagnosticInfo = _conversationService.getDiagnosticInfo();
    
    if (!success) {
      setState(() {
        _connectionIssues = true;
        _manualInputMode = true; // Activer le mode manuel en cas d'échec
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: EloquenceTheme.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text("⚠️ Mode dégradé activé - Conversation textuelle disponible"),
                ),
              ],
            ),
            backgroundColor: EloquenceTheme.warningOrange,
            action: SnackBarAction(
              label: "Diagnostic",
              textColor: EloquenceTheme.white,
              onPressed: _showDiagnosticsDialog,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _connectionIssues = false;
        _manualInputMode = false;
      });
    }
  }
  
  void _showDiagnosticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EloquenceTheme.glassBackground,
        shape: RoundedRectangleBorder(
          borderRadius: EloquenceTheme.borderRadiusLarge,
          side: const BorderSide(color: EloquenceTheme.glassBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: EloquenceTheme.cyan),
            SizedBox(width: 8),
            Text("Diagnostic du Service IA", style: TextStyle(color: EloquenceTheme.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._diagnosticInfo.entries.map((entry) {
                final isOk = entry.value == true ||
                           (entry.value is String && entry.value.isNotEmpty) ||
                           (entry.value is int && entry.value > 0);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isOk ? Icons.check_circle : Icons.error,
                        color: isOk ? EloquenceTheme.successGreen : EloquenceTheme.errorRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${entry.key}: ${entry.value}",
                          style: const TextStyle(color: EloquenceTheme.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fermer", style: TextStyle(color: EloquenceTheme.cyan)),
          ),
          ElevatedButton(
            onPressed: _retryConnection,
            style: ElevatedButton.styleFrom(backgroundColor: EloquenceTheme.cyan),
            child: const Text("Réessayer", style: TextStyle(color: EloquenceTheme.navy)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _retryConnection() async {
    Navigator.of(context).pop(); // Fermer le dialog
    await _startConversation();
  }

  void _requestHelp() {
    if (helpUsedCount >= maxHelpUsage) return;
    
    setState(() {
      helpUsedCount++;
      showSuggestions = !showSuggestions;
      if (showSuggestions) {
        _suggestionController.forward();
      } else {
        _suggestionController.reverse();
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      selectedSuggestion = suggestion;
      showSuggestions = false;
    });
    
    _suggestionController.reverse();
    
    // Feedback haptique
    HapticFeedback.lightImpact();
  }

  void _acceptSuggestion() {
    setState(() {
      currentUserInput = selectedSuggestion;
      _textController.text = selectedSuggestion;
      selectedSuggestion = "";
    });
    
    // Feedback haptique
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("💡 Suggestion IA acceptée"),
        backgroundColor: EloquenceTheme.successGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _rejectSuggestion() {
    setState(() {
      selectedSuggestion = "";
    });
    
    // Feedback haptique
    HapticFeedback.lightImpact();
  }

  void _sendMessage() {
    if (currentUserInput.trim().isEmpty) return;
    
    final messageText = currentUserInput.trim();
    
    // En mode manuel ou en cas de problème de connexion, envoyer directement au service
    if (_manualInputMode || _connectionIssues) {
      _conversationService.addUserMessage(messageText);
    }
    
    setState(() {
      _textController.clear();
      currentUserInput = "";
      selectedSuggestion = "";
      showSuggestions = false;
      isWaitingForResponse = true;
    });
    
    _suggestionController.reverse();
    
    // Scroll vers le bas
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    // Feedback haptique
    HapticFeedback.mediumImpact();
    
    if (_conversationService.isRecording) {
      await _conversationService.stopRecording();
    } else {
      await _conversationService.startRecording();
    }
    
    setState(() {
      // L'état sera mis à jour via le stream
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: EloquenceTheme.glassBackground,
          shape: RoundedRectangleBorder(
            borderRadius: EloquenceTheme.borderRadiusLarge,
            side: const BorderSide(color: EloquenceTheme.glassBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: EloquenceTheme.spacingMd),
              Text(
                "Quitter l'exercice ?",
                style: TextStyle(color: EloquenceTheme.white),
              ),
            ],
          ),
          content: const Text(
            "Votre conversation avec l'IA sera terminée. Êtes-vous sûr de vouloir quitter ?",
            style: TextStyle(color: EloquenceTheme.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Annuler",
                style: TextStyle(
                  color: EloquenceTheme.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitExercise();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EloquenceTheme.errorRed,
                foregroundColor: EloquenceTheme.white,
              ),
              child: const Text("Quitter"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exitExercise() async {
    _timer.cancel();
    await _conversationService.endConversation();
    if (mounted) {
      GoRouter.of(context).go('/scenarios');
    }
  }

  Future<void> _completeExercise() async {
    _timer.cancel();
    await _conversationService.endConversation();
    if (mounted) {
      GoRouter.of(context).go('/scenario_feedback');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _suggestionController.dispose();
    _typingController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _timer.cancel();
    
    // Annuler les subscriptions
    _messageSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    _suggestionsSubscription?.cancel();
    _listeningSubscription?.cancel();
    
    // Nettoyer le service
    _conversationService.dispose();
    
    super.dispose();
  }
}
