import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:eloquence_2_0/core/theme/eloquence_unified_theme.dart';
import 'package:eloquence_2_0/features/studio_situations_pro/data/models/simulation_models.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  final SimulationType simulationType;

  const PreparationScreen({
    Key? key,
    required this.simulationType,
  }) : super(key: key);

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      Message(sender: Sender.ai, text: "Let's get ready for your simulation!"),
      Message(
        sender: Sender.ai,
        text: "To be effective in this setting, convey confidence and articulate clearly. What's your first thought?",
      ),
    ]);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String text) {
    if (text.isEmpty) return;
    setState(() {
      _messages.add(Message(sender: Sender.user, text: text));
    });
    _textController.clear();
    // TODO: AI response logic will be added here
  }

  void _handleFileUpload() {
    // TODO: Implémenter la sélection de fichier avec file_picker à l'étape 4.2
    setState(() {
      _messages.add(
        Message(
          sender: Sender.ai,
          text: "La fonctionnalité de téléchargement de documents est en cours de développement. Elle permettra bientôt d'analyser vos fichiers.",
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceTheme.navy,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
              padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
          const SizedBox(height: EloquenceTheme.spacingMd),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EloquenceTheme.cyan,
              shape: RoundedRectangleBorder(
                borderRadius: EloquenceTheme.borderRadiusLarge,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            onPressed: () {
              context.push('/simulation/${widget.simulationType.toRouteString()}');
            },
            child: const Text(
              'Commencer la Simulation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: EloquenceTheme.spacingMd),
        ],
      ),
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
}

enum Sender { user, ai }

class Message {
  final Sender sender;
  final String text;

  Message({required this.sender, required this.text});
}