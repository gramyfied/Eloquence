import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../presentation/widgets/gradient_container.dart';
import '../../domain/entities/story_models.dart';
import '../providers/story_generator_provider.dart';
import 'story_narration_screen.dart';

/// Écran de sélection des éléments narratifs avec animation de cartes
class StoryElementSelectionScreen extends ConsumerStatefulWidget {
  const StoryElementSelectionScreen({super.key});

  @override
  ConsumerState<StoryElementSelectionScreen> createState() => _StoryElementSelectionScreenState();
}

class _StoryElementSelectionScreenState extends ConsumerState<StoryElementSelectionScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _mainAnimationController;
  late AnimationController _cardFlipController;
  late AnimationController _revealController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _cardFlipAnimation;
  late Animation<double> _revealAnimation;
  late Animation<double> _pulseAnimation;
  
  List<bool> _revealedCards = [false, false, false];
  List<StoryElement?> _selectedElements = [null, null, null];
  bool _allCardsRevealed = false;
  int _currentRevealingCard = -1;

  @override
  void initState() {
    super.initState();
    
    // Animation principale pour l'entrée
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animation de retournement des cartes
    _cardFlipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation de révélation progressive
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animation de pulsation pour les cartes
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _cardFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardFlipController,
      curve: Curves.easeInOutBack,
    ));
    
    _revealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer les animations
    _startAnimations();
    
    // Générer les éléments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateStoryElements();
    });
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _generateStoryElements() async {
    logger.i('StoryElementSelection', 'Génération des éléments narratifs');
    
    try {
      await ref.read(storyGeneratorProvider.notifier).generateStoryElements();
      final state = ref.read(storyGeneratorProvider);
      
      if (state.currentSession?.availableElements != null && 
          state.currentSession!.availableElements.length >= 3) {
        setState(() {
          _selectedElements = [
            state.currentSession!.availableElements[0], // Personnage
            state.currentSession!.availableElements[1], // Lieu  
            state.currentSession!.availableElements[2], // Objet magique
          ];
        });
      }
    } catch (e) {
      logger.e('StoryElementSelection', 'Erreur génération éléments: $e');
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _cardFlipController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyGeneratorProvider);
    
    return Scaffold(
      body: GradientContainer(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _mainAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(context)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildInstructions(),
                              const SizedBox(height: 24),
                              _buildCardsArea(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Align(
                           alignment: Alignment.bottomCenter,
                           child: Padding(
                             padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                             child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: _allCardsRevealed
                                  ? _buildStartNarrationButton(context)
                                  : const SizedBox.shrink(),
                            ),
                           ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tirage des Éléments',
                  style: EloquenceTheme.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Découvrez vos éléments',
                  style: EloquenceTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [EloquenceTheme.cyan, EloquenceTheme.violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child:
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: EloquenceTheme.glassBackground,
        border: Border.all(color: EloquenceTheme.glassBorder),
        boxShadow: EloquenceTheme.shadowMedium,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: EloquenceTheme.cyan,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: EloquenceTheme.headline3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Touchez chaque carte pour révéler vos éléments narratifs. Vous obtiendrez un personnage, un lieu et un objet magique pour créer votre histoire unique !',
            style: EloquenceTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsArea() {
    const cardHeight = 190.0;
    const cardSpacing = 24.0;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: _buildStoryCard(
            index: 0,
            title: 'Personnage',
            emoji: '🧙‍♂️',
            type: StoryElementType.character,
          ),
        ),
        const SizedBox(height: cardSpacing),
        SizedBox(
          height: cardHeight,
          child: _buildStoryCard(
            index: 1,
            title: 'Lieu',
            emoji: '🏰',
            type: StoryElementType.location,
          ),
        ),
        const SizedBox(height: cardSpacing),
        SizedBox(
          height: cardHeight,
          child: _buildStoryCard(
            index: 2,
            title: 'Objet Magique',
            emoji: '🔮',
            type: StoryElementType.magicObject,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard({
    required int index,
    required String title,
    required String emoji,
    required StoryElementType type,
  }) {
    final isRevealed = _revealedCards[index];
    final element = _selectedElements[index];
    final isCurrentlyRevealing = _currentRevealingCard == index;
    
    return GestureDetector(
      onTap: () => _revealCard(index),
      child: AnimatedBuilder(
        animation: Listenable.merge([_cardFlipController, _pulseController]),
        builder: (context, child) {
          final flipValue = isRevealed
              ? 1.0
              : (isCurrentlyRevealing ? _cardFlipAnimation.value : 0.0);
          final pulseValue = !isRevealed ? _pulseAnimation.value : 1.0;

          final content = flipValue >= 0.5
              ? _buildRevealedCardContent(element, emoji, type)
              : _buildHiddenCardContent(title, emoji);

          return Transform.scale(
            scale: pulseValue,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(flipValue * math.pi),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isRevealed
                      ? LinearGradient(
                          colors: [
                            EloquenceTheme.cyan.withOpacity(0.2),
                            EloquenceTheme.violet.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            EloquenceTheme.glassBackground,
                            EloquenceTheme.glassBackground.withOpacity(0.8),
                          ],
                        ),
                  border: Border.all(
                    color: isRevealed
                        ? EloquenceTheme.cyan
                        : EloquenceTheme.glassBorder,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isRevealed
                          ? EloquenceTheme.cyan.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: isRevealed ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateY(flipValue > 0.5 ? math.pi : 0),
                  child: content,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHiddenCardContent(String title, String emoji) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '❓',
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: EloquenceTheme.headline3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Touchez pour révéler',
          style: EloquenceTheme.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedCardContent(StoryElement? element, String emoji, StoryElementType type) {
    if (element == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Text(
            element.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            element.name,
            style: EloquenceTheme.headline3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                element.description,
                style: EloquenceTheme.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildStartNarrationButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _revealAnimation.value,
          child: Container(
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  EloquenceTheme.cyan,
                  EloquenceTheme.violet,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: EloquenceTheme.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => _startNarration(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Commencer la Narration',
                          textAlign: TextAlign.center,
                          style: EloquenceTheme.headline3.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _revealCard(int index) async {
    if (_revealedCards[index] || _currentRevealingCard != -1) return;
    
    logger.i('StoryElementSelection', 'Révélation carte $index');
    
    setState(() {
      _currentRevealingCard = index;
    });
    
    _cardFlipController.reset();
    await _cardFlipController.forward();
    
    setState(() {
      _revealedCards[index] = true;
      _currentRevealingCard = -1;
      
      // Vérifier si toutes les cartes sont révélées
      if (_revealedCards.every((revealed) => revealed)) {
        _allCardsRevealed = true;
        _revealController.forward();
      }
    });
  }

  void _startNarration(BuildContext context) {
    logger.i('StoryElementSelection', 'Démarrage de la narration');
    
    // Sauvegarder les éléments sélectionnés
    ref.read(storyGeneratorProvider.notifier).selectElements(_selectedElements.cast<StoryElement>());
    
    // Navigation vers l'écran de narration
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryNarrationScreen(),
      ),
    );
  }
}