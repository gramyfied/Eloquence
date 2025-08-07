import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';
import '../../domain/entities/confidence_models.dart';
import '../widgets/animated_microphone_button.dart';
import '../widgets/avatar_with_halo.dart';
import '../../data/services/confidence_livekit_service.dart';
import '../../data/services/mistral_api_service.dart';

class TribunalIdeesScreenReal extends ConsumerStatefulWidget {
  const TribunalIdeesScreenReal({Key? key}) : super(key: key);
  
  @override
  ConsumerState<TribunalIdeesScreenReal> createState() => _TribunalIdeesScreenRealState();
}

class _TribunalIdeesScreenRealState extends ConsumerState<TribunalIdeesScreenReal>
    with TickerProviderStateMixin {
  
  // Logger
  static final Logger _logger = Logger();
  
  // Service LiveKit spécialisé pour le tribunal
  final ConfidenceLiveKitService _livekitService = ConfidenceLiveKitService();
  
  // Service Mistral pour génération IA
  final MistralApiService _mistralService = MistralApiService();
  
  // Gamification State
  int _currentXP = 0;
  int _earnedXP = 0;
  int _currentLevel = 1;
  double _exerciseScore = 0.0;
  List<String> _unlockedBadges = [];
  List<String> _completedAchievements = [];
  bool _isLevelingUp = false;
  bool _isBadgeUnlocked = false;
  bool _isExerciseActive = false;
  
  // Exercise State
  String _currentDebateTopic = '';
  bool _isGeneratingTopic = false;
  List<String> _debateTopics = [
    'Les chaussettes dépareillées sont-elles un crime contre l\'humanité ?',
    'Faut-il interdire les lundis matins par décret présidentiel ?',
    'Les licornes devraient-elles payer des impôts ?',
    'Est-ce que les robots ont le droit de rêver de moutons électriques ?',
    'Faut-il créer un permis de conduire pour les trottinettes ?'
  ];
  
  // Sujets de fallback en cas d'erreur IA
  List<String> _fallbackTopics = [
    'Les nuages ont-ils le droit de voyager sans passeport ?',
    'Faut-il instaurer un couvre-feu pour les réveils trop bruyants ?',
    'Les plantes d\'intérieur devraient-elles payer un loyer ?',
    'Est-il légal de porter des chaussettes avec des sandales ?',
    'Les miroirs mentent-ils sur notre apparence ?',
    'Faut-il créer une école pour apprendre à parler aux animaux ?',
    'Les rêves devraient-ils être soumis aux droits d\'auteur ?',
    'Est-ce que les fantômes ont des droits civiques ?'
  ];
  
  // Animation Controllers
  late AnimationController _xpAnimationController;
  late AnimationController _badgeAnimationController;
  late AnimationController _levelUpAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _confettiController;
  
  // Gamification Configuration
  final int baseXP = 120;
  final double xpMultiplier = 1.7;
  final Map<String, double> bonusConditions = {
    'perfect_completion': 0.5,
    'first_try_success': 0.3,
    'speed_bonus': 0.2,
    'creativity_bonus': 0.4,
    'consistency_bonus': 0.25,
    'improvement_bonus': 0.35
  };
  
  // LiveKit Integration
  final ScrollController _chatScrollController = ScrollController();
  List<ConversationMessage> _conversationMessages = [];
  String? _currentTranscription;
  bool _isServiceConnected = false;
  
  // Questions du juge
  List<String> _judgeQuestions = [];
  String? _lastJudgeQuestion;
  bool _showQuestionsPanel = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProgress();
    _generateNewTopic(); // Génère un sujet IA dès le démarrage
    _setupLiveKitListeners();
  }
  
  /// Configurer les listeners du service LiveKit spécialisé
  void _setupLiveKitListeners() {
    // Écouter les messages de conversation
    _livekitService.conversationStream.listen((message) {
      if (mounted) {
        setState(() {
          _conversationMessages.add(message);
          
          // Si c'est un message du juge (pas de l'utilisateur), vérifier s'il contient une question
          if (!message.isUser && message.content.contains('?')) {
            _judgeQuestions.add(message.content);
            _lastJudgeQuestion = message.content;
          }
        });
        _scrollToBottom();
      }
    });

    // Écouter la transcription
    _livekitService.transcriptionStream.listen((transcription) {
      if (mounted) {
        setState(() {
          _currentTranscription = transcription;
        });
      }
    });

    // Écouter les erreurs
    _livekitService.errorStream.listen((error) {
      if (mounted) {
        _showErrorSnackBar(error);
      }
    });
  }
  
  void _initializeAnimations() {
    _xpAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _badgeAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _levelUpAnimationController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _confettiController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
  }
  
  /// Générer un nouveau sujet de débat original avec l'IA
  Future<void> _generateNewTopic() async {
    setState(() {
      _isGeneratingTopic = true;
    });
    
    _logger.i('🎯 DÉBUT génération nouveau sujet - État exercice: ${_isExerciseActive ? "ACTIF" : "INACTIF"}');
    _logger.i('📍 Interface perçue par utilisateur: ${_isExerciseActive ? "ÉCRAN PRINCIPAL (après Commencer)" : "ÉCRAN D\'ACCUEIL (avant Commencer)"}');
    _logger.i('🔧 Contexte appelant: ${StackTrace.current.toString().split('\n')[1]}');
    _logger.i('📱 État actuel: _currentDebateTopic="$_currentDebateTopic", _isGeneratingTopic=$_isGeneratingTopic');
    
    try {
      // Créer un prompt vraiment unique avec multiple sources d'aléatoire
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final nanoTime = DateTime.now().microsecondsSinceEpoch;
      final randomSeed = (uniqueId + nanoTime + hashCode) % 100000; // Plus large range
      
      final themes = [
        'créatures fantastiques', 'objets du quotidien', 'phénomènes naturels',
        'professions bizarres', 'animaux improbables', 'technologies futiles',
        'nourritures étranges', 'situation de la vie quotidienne', 'lois absurdes',
        'droits des objets inanimés', 'problèmes existentiels ridicules', 'science fiction',
        'mythologie moderne', 'bureaucratie absurde', 'droits des machines'
      ];
      
      final randomTheme = themes[randomSeed % themes.length];
      final randomAdjective = ['ridicule', 'absurde', 'loufoques', 'impensable', 'saugrenu', 'délirant'][randomSeed % 6];
      
      // Force le cache bypass en ajoutant plusieurs éléments uniques
      final sessionId = 'tribunal_${DateTime.now().microsecond}_${hashCode}';
      final cacheKiller = 'UNIQUE_$randomSeed-$uniqueId-$nanoTime-$sessionId';
      
      final prompt = '''$cacheKiller - GÉNÉRATION ABSOLUMENT UNIQUE
      
Crée un nouveau sujet de débat $randomAdjective pour le "Tribunal des Idées Impossibles".

CONTRAINTES STRICTES:
- Thème inspiré: $randomTheme
- Style: Question provocante ou affirmation à défendre
- Longueur: 10-30 mots MAXIMUM
- Totalement original et jamais vu
- Français uniquement
- Aucune explication ajoutée
- DIFFÉRENT de tous les sujets précédents

CONTEXTE UNIQUE:
Session: $sessionId
Seed: $randomSeed
Nano: $nanoTime
État: ${_isExerciseActive ? "ACTIF" : "INACTIF"}

EXEMPLES DE STYLE (NE PAS COPIER, CRÉER DU NOUVEAU):
"Les nuages devraient-ils payer une taxe carbone pour leurs déplacements ?"
"Faut-il créer un syndicat pour défendre les chaussettes orphelines ?"

RÉPONDS UNIQUEMENT AVEC LE NOUVEAU SUJET CRÉATIF:''';

      _logger.i('🎲 Appel Mistral avec seed: $randomSeed, thème: $randomTheme, sessionId: $sessionId');

      final generatedTopic = await _mistralService.generateText(
        prompt: prompt,
        maxTokens: 100,
        temperature: 1.0, // Maximum de créativité
      );
      
      _logger.i('📝 Réponse brute Mistral: "$generatedTopic"');
      
      // Nettoyer la réponse
      final cleanTopic = generatedTopic
          .trim()
          .replaceAll(RegExp(r'^["\x27]|["\x27]$'), '') // Enlever guillemets
          .replaceAll(RegExp(r'^\d+\.\s*'), '') // Enlever numérotation
          .replaceAll(RegExp(r'^-\s*'), '') // Enlever tirets
          .trim();
      
      if (cleanTopic.isNotEmpty && cleanTopic.length > 10) {
        setState(() {
          _currentDebateTopic = cleanTopic;
          _isGeneratingTopic = false;
        });
        
        _logger.i('✨ Nouveau sujet IA appliqué (seed: $randomSeed): "$cleanTopic"');
        _logger.i('🎭 Interface actuelle: ${_isExerciseActive ? "PRINCIPAL (après Commencer)" : "ACCUEIL (avant Commencer)"}');
        _logger.i('📄 Sujet affiché dans: ${_isExerciseActive ? "Zone de débat actif" : "Zone de présentation"}');
      } else {
        _logger.w('⚠️ Sujet IA invalide (trop court): "$cleanTopic"');
        throw Exception('Sujet IA trop court ou vide: "$cleanTopic"');
      }
      
    } catch (e) {
      _logger.w('⚠️ Erreur génération sujet IA: ${e.toString()}');
      _logger.i('🔄 Utilisation collection étendue dynamique');
      
      // Collection mega-étendue avec variabilité garantie
      final megaTopics = [
        'Les nuages devraient-ils demander permission avant de pleuvoir ?',
        'Faut-il créer un permis de conduire pour les escargots pressés ?',
        'Les miroirs ont-ils le droit de mentir sur notre apparence ?',
        'Est-ce que les chaussettes ont une âme après la mort du pied ?',
        'Les poissons rouges méritent-ils des vacances à la mer ?',
        'Faut-il interdire aux réveils de sonner avant 10h du matin ?',
        'Les licornes doivent-elles payer des impôts sur leur magie ?',
        'Est-il légal de rêver de son voisin sans autorisation écrite ?',
        'Les fourmis organisent-elles des grèves pour de meilleures fourmilières ?',
        'Faut-il créer un tribunal spécialisé pour juger les blagues nulles ?',
        'Les pizza hawaïennes constituent-elles un crime contre l\'humanité ?',
        'Est-ce que les fantômes doivent présenter leur carte d\'identité ?',
        'Les robots ont-ils le droit de tomber amoureux de leurs utilisateurs ?',
        'Faut-il interdire aux lundis d\'exister par décret présidentiel ?',
        'Les planètes sont-elles secrètement jalouses du succès de la Terre ?',
        'Est-ce que les monstres sous le lit paient un loyer aux propriétaires ?',
        'Les parapluies complotent-ils activement contre les nuages de pluie ?',
        'Faut-il donner le droit de vote aux intelligences artificielles ?',
        'Est-ce que les clés se cachent volontairement quand on est pressé ?',
        'Les chats domestiques sont-ils des espions aliens déguisés ?',
        'Faut-il créer une école publique pour apprendre à parler pinguin ?',
        'Est-ce que les étoiles filantes ont besoin d\'un permis de chute ?',
        'Les légumes ont-ils des sentiments quand on les mange vivants ?',
        'Faut-il interdire aux araignées de faire de la décoration d\'intérieur ?',
        'Est-ce que les dragons crachent du feu uniquement par timidité ?',
        'Les smartphones rêvent-ils de moutons électriques la nuit ?',
        'Faut-il créer un code pénal pour les crimes contre la logique ?',
        'Est-ce que les chaussures gauches complotent contre les droites ?',
        'Les extraterrestres ont-ils besoin d\'un visa pour visiter la Terre ?',
        'Faut-il instaurer une taxe sur les pensées négatives ?',
        'Est-ce que les ombres ont des droits d\'auteur sur leur forme ?',
        'Les machines à café sont-elles secrètement conscientes de notre dépendance ?',
        'Faut-il interdire aux pingouins de porter du noir et blanc ?',
        'Est-ce que les rêves peuvent être poursuivis pour contrefaçon ?',
        'Les escalators ont-ils une âme mécanique qui souffre ?',
        'Faut-il créer un permis de rire pour les comédiens professionnels ?',
        'Est-ce que les numéros de téléphone ressentent de la nostalgie ?',
        'Les mots ont-ils le droit de changer de sens sans préavis ?',
        'Faut-il poursuivre le temps pour harcèlement moral quotidien ?',
        'Est-ce que les couleurs primaires discriminent les couleurs secondaires ?'
      ];
      
      // Utiliser un algorithme de sélection ultra-aléatoire
      final timeHash = DateTime.now().microsecondsSinceEpoch;
      final objectHash = hashCode;
      final exerciseHash = _isExerciseActive ? 12345 : 54321;
      final superRandomIndex = (timeHash + objectHash + exerciseHash) % megaTopics.length;
      
      final selectedTopic = megaTopics[superRandomIndex];
      
      setState(() {
        _currentDebateTopic = selectedTopic;
        _isGeneratingTopic = false;
      });
      
      _logger.i('🎲 Sujet mega-collection sélectionné (index: $superRandomIndex/${megaTopics.length}): "$selectedTopic"');
      _logger.i('🔍 Détails sélection: timeHash=$timeHash, objectHash=$objectHash, exerciseHash=$exerciseHash');
      _logger.i('🎭 Interface fallback: ${_isExerciseActive ? "PRINCIPAL (après Commencer)" : "ACCUEIL (avant Commencer)"}');
    }
    
    _logger.i('🎯 FIN génération - Nouveau sujet: "$_currentDebateTopic"');
    
    // Feedback haptique
    HapticFeedback.lightImpact();
  }
  
  /// Méthode unifiée pour la génération de nouveaux sujets (fonctionne dans tous les états)
  void _selectRandomTopic() {
    _logger.i('🔄 _selectRandomTopic appelée - État exercice: ${_isExerciseActive ? "ACTIF" : "INACTIF"}');
    _logger.i('📱 Interface perçue par utilisateur: ${_isExerciseActive ? "ÉCRAN PRINCIPAL" : "ÉCRAN D\'ACCUEIL"}');
    _logger.i('🔍 DIAGNOSTIC: Widget actuel = ${_isExerciseActive ? "_buildUnifiedInterface" : "_buildUnifiedInterface"} (même méthode!)');
    _logger.i('🎯 Bouton appelant = ${_isExerciseActive ? "Interface principal" : "Interface accueil"} - UTILISE MÊME LOGIQUE');
    
    // Vérifier si la génération est déjà en cours
    if (_isGeneratingTopic) {
      _logger.w('⚠️ Génération déjà en cours, ignorer le double-clic');
      return;
    }
    
    _logger.i('🚀 LANCEMENT génération identique pour les deux interfaces');
    _generateNewTopic();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header avec gamification et statut LiveKit
                _buildGamificationHeader(_isServiceConnected),
                
                // Corps principal - interface unifié avec animations discrètes
                Expanded(
                  child: _buildUnifiedInterface(),
                ),
              ],
            ),
          ),
          
          // Overlays d'animation
          if (_isLevelingUp) _buildLevelUpAnimation(),
          if (_isBadgeUnlocked) _buildBadgeUnlockAnimation(),
          
          // Confetti effect (simplified)
          if (_isLevelingUp)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFFFD700).withOpacity(0.3 * _confettiController.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildGamificationHeader(bool isConnected) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFD700).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre avec statut LiveKit
          Row(
            children: [
              Icon(Icons.gavel, color: Color(0xFFFFD700), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Le Tribunal des Idées Impossibles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Indicateur de connexion LiveKit
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      isConnected ? 'IA' : 'Off',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Barre XP animée
          _buildAnimatedXPBar(),
          
          SizedBox(height: 12),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  icon: Icons.star,
                  label: 'Niveau $_currentLevel',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.military_tech,
                  label: '${_unlockedBadges.length} badges',
                  color: Colors.purple,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.trending_up,
                  label: '${(_exerciseScore * 100).toInt()}%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedXPBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expérience',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '$_currentXP / ${_getXPForNextLevel()} XP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        AnimatedBuilder(
          animation: _xpAnimationController,
          builder: (context, child) {
            return Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (_currentXP / _getXPForNextLevel()) * _xpAnimationController.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(Colors.blue, Color(0xFFFFD700), _xpAnimationController.value)!,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeInterface() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          
          // Avatar du juge avec animation
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseAnimationController.value * 0.1),
                child: AvatarWithHalo(
                  characterName: 'juge_magistrat',
                  size: 80,
                  isActive: false,
                ),
              );
            },
          ),
          
          SizedBox(height: 16),
          
          // Nom du personnage
          Text(
            'Juge Magistrat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Maître des débats impossibles',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 20),
          
          // Sujet du débat
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Sujet du débat :',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  _currentDebateTopic,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectRandomTopic,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text(
                    'Nouveau sujet',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startExercise,
                  icon: Icon(Icons.play_arrow, size: 16),
                  label: Text(
                    'Commencer',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Indicateur XP
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'XP de base: $baseXP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Multiplicateur: ${xpMultiplier}x',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  /// Interface unifiée avec animations discrètes pendant l'enregistrement
  Widget _buildUnifiedInterface() {
    return Stack(
      children: [
        // Interface principale qui reste toujours visible
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Zone des questions du juge (toujours visible pendant l'exercice)
              if (_isExerciseActive && _lastJudgeQuestion != null)
                _buildLastJudgeQuestionWidget(),
              
              SizedBox(height: 20),
              
              // Avatar du juge avec animation et état d'enregistrement
              _buildAnimatedJudgeAvatar(),
              
              SizedBox(height: 16),
              
              // Nom du personnage avec animation pendant l'enregistrement
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 500),
                style: TextStyle(
                  color: _isExerciseActive ? Color(0xFFFFD700) : Colors.white,
                  fontSize: _isExerciseActive ? 24 : 22,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(
                  'Juge Magistrat',
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 8),
              
              // Status dynamique
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Text(
                  _isExerciseActive ? 'En cours d\'audience...' : 'Maître des débats impossibles',
                  key: ValueKey(_isExerciseActive),
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Sujet du débat avec animation pendant l'enregistrement
              _buildAnimatedDebateTopic(),
              
              SizedBox(height: 20),
              
              // Messages de conversation (visibles pendant l'exercice)
              if (_isExerciseActive && _conversationMessages.isNotEmpty)
                _buildCompactConversationArea(),
              
              // Boutons d'action
              if (!_isExerciseActive) _buildActionButtons(),
              
              // Contrôles pendant l'exercice (version compacte)
              if (_isExerciseActive) _buildCompactControls(),
              
              SizedBox(height: 16),
              
              // Indicateur XP (toujours visible)
              _buildXPIndicator(),
              
              SizedBox(height: 20),
            ],
          ),
        ),
        
        // Overlay discret pour l'état d'enregistrement
        if (_isExerciseActive) _buildRecordingOverlay(),
        
        // Bouton flottant pour voir toutes les questions du juge
        if (_isExerciseActive && _judgeQuestions.isNotEmpty)
          _buildQuestionsFloatingButton(),
        
        // Panel coulissant avec l'historique des questions
        if (_showQuestionsPanel)
          _buildQuestionsPanel(),
      ],
    );
  }

  /// Avatar animé avec état d'enregistrement
  Widget _buildAnimatedJudgeAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 500),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: _isExerciseActive ? [
              BoxShadow(
                color: Color(0xFFFFD700).withOpacity(0.3 * _pulseAnimationController.value),
                blurRadius: 20 * _pulseAnimationController.value,
                spreadRadius: 5 * _pulseAnimationController.value,
              ),
            ] : null,
          ),
          child: Transform.scale(
            scale: 1.0 + (_pulseAnimationController.value * (_isExerciseActive ? 0.15 : 0.1)),
            child: AvatarWithHalo(
              characterName: 'juge_magistrat',
              size: _isExerciseActive ? 90 : 80,
              isActive: _isExerciseActive,
            ),
          ),
        );
      },
    );
  }

  /// Sujet du débat avec animation
  Widget _buildAnimatedDebateTopic() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_isExerciseActive ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFFD700).withOpacity(_isExerciseActive ? 0.5 : 0.3),
          width: _isExerciseActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            _isExerciseActive ? 'Défendez votre position :' : 'Sujet du débat :',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _currentDebateTopic,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Zone de conversation compacte
  Widget _buildCompactConversationArea() {
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversation',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              itemCount: _conversationMessages.length,
              itemBuilder: (context, index) {
                final message = _conversationMessages[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        message.isUser ? Icons.person : Icons.gavel,
                        color: message.isUser ? Colors.blue : Color(0xFFFFD700),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Boutons d'action (interface de bienvenue)
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _selectRandomTopic,
            icon: Icon(Icons.refresh, size: 16),
            label: Text(
              'Nouveau sujet',
              style: TextStyle(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startExercise,
            icon: Icon(Icons.play_arrow, size: 16),
            label: Text(
              'Commencer',
              style: TextStyle(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Contrôles compacts pendant l'exercice
  Widget _buildCompactControls() {
    return Column(
      children: [
        // Transcription en temps réel
        if (_currentTranscription != null)
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.mic, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentTranscription!,
                    style: TextStyle(
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Boutons d'action pendant l'exercice
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _stopExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Terminer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Indicateur XP (toujours visible)
  Widget _buildXPIndicator() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'XP de base: $baseXP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Multiplicateur: ${xpMultiplier}x',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Zone persistante pour la dernière question du juge
  Widget _buildLastJudgeQuestionWidget() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFD700).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFFD700).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Color(0xFFFFD700), size: 18),
              SizedBox(width: 8),
              Text(
                'Question du Juge Magistrat :',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _lastJudgeQuestion!,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          if (_judgeQuestions.length > 1)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '${_judgeQuestions.length - 1} autre(s) question(s) - Touchez "Questions" pour tout voir',
                style: TextStyle(
                  color: Color(0xFFFFD700).withOpacity(0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Bouton flottant pour accéder à toutes les questions
  Widget _buildQuestionsFloatingButton() {
    return Positioned(
      top: 10,
      left: 10,
      child: AnimatedBuilder(
        animation: _pulseAnimationController,
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _showQuestionsPanel = !_showQuestionsPanel;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFFD700).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz, color: Colors.black, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Questions',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_judgeQuestions.length > 1) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_judgeQuestions.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Panel coulissant avec l'historique complet des questions
  Widget _buildQuestionsPanel() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showQuestionsPanel = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {}, // Empêche la fermeture quand on tape sur le panel
            child: AnimatedSlide(
              duration: Duration(milliseconds: 300),
              offset: _showQuestionsPanel ? Offset.zero : Offset(-1, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      // En-tête du panel
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFD700).withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.gavel, color: Color(0xFFFFD700), size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Questions du Juge',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_judgeQuestions.length} question(s) posée(s)',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showQuestionsPanel = false;
                                });
                              },
                              child: Icon(Icons.close, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
                      
                      // Liste des questions
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _judgeQuestions.length,
                          itemBuilder: (context, index) {
                            final question = _judgeQuestions[index];
                            final isLatest = index == _judgeQuestions.length - 1;
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isLatest
                                    ? Color(0xFFFFD700).withOpacity(0.15)
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLatest
                                      ? Color(0xFFFFD700).withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isLatest ? Color(0xFFFFD700) : Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Question ${index + 1}${isLatest ? ' (Actuelle)' : ''}',
                                          style: TextStyle(
                                            color: isLatest ? Colors.black : Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    question,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Overlay discret pour indiquer l'enregistrement
  Widget _buildRecordingOverlay() {
    return Positioned(
      top: 10,
      right: 10,
      child: AnimatedBuilder(
        animation: _pulseAnimationController,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8 * _pulseAnimationController.value),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Affichage des métriques temps réel
  Widget _buildMetricsDisplay(ConfidenceMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem('Confiance', metrics.confidenceLevel, Colors.blue),
          _buildMetricItem('Clarté', metrics.voiceClarity, Colors.green),
          _buildMetricItem('Rythme', metrics.speakingPace, Colors.orange),
          _buildMetricItem('Énergie', metrics.energyLevel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLevelUpAnimation() {
    return AnimatedBuilder(
      animation: _levelUpAnimationController,
      builder: (context, child) {
        return Container(
          color: Color(0xFFFFD700).withOpacity(0.3 * _levelUpAnimationController.value),
          child: Center(
            child: Transform.scale(
              scale: 1.0 + (0.5 * _levelUpAnimationController.value),
              child: Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'NIVEAU SUPÉRIEUR !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Niveau $_currentLevel atteint !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBadgeUnlockAnimation() {
    return AnimatedBuilder(
      animation: _badgeAnimationController,
      builder: (context, child) {
        return Container(
          color: Colors.purple.withOpacity(0.2 * _badgeAnimationController.value),
          child: Center(
            child: Transform.scale(
              scale: 0.5 + (0.5 * _badgeAnimationController.value),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.military_tech,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'NOUVEAU BADGE !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getLastUnlockedBadgeName(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // MÉTHODES DE CONTRÔLE AVEC LIVEKIT
  
  /// Démarrer la session LiveKit spécialisée Tribunal
  Future<void> _startExercise() async {
    setState(() {
      _isExerciseActive = true;
      _isServiceConnected = false;
    });
    
    try {
      // Utiliser la méthode spécialisée tribunal directement
      final success = await _livekitService.startTribunalIdeasSession(
        userId: 'tribunal_user_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (success) {
        setState(() {
          _isServiceConnected = true;
        });
        _pulseAnimationController.repeat(reverse: true);
        _logger.i('✅ Session Tribunal spécialisée démarrée avec succès - Juge Magistrat actif');
      } else {
        throw Exception('Impossible de démarrer la session tribunal spécialisée');
      }
    } catch (e) {
      _logger.e('❌ Erreur démarrage tribunal spécialisé: $e');
      if (mounted) {
        _showErrorSnackBar('Impossible de démarrer la session Tribunal: $e');
        setState(() {
          _isExerciseActive = false;
          _isServiceConnected = false;
        });
      }
    }
    
    // Feedback haptique
    HapticFeedback.mediumImpact();
  }
  
  /// Terminer la session spécialisée
  Future<void> _stopExercise() async {
    try {
      await _livekitService.endSession();
      _logger.i('🔚 Session Tribunal spécialisée terminée');
      
      setState(() {
        _isExerciseActive = false;
        _isServiceConnected = false;
        // Réinitialiser les questions pour la prochaine session
        _judgeQuestions.clear();
        _lastJudgeQuestion = null;
        _showQuestionsPanel = false;
      });
      
      // Calculer le score et XP
      _completeExercise(0.85); // Score simulé
      
      HapticFeedback.mediumImpact();
    } catch (e) {
      _logger.e('❌ Erreur arrêt tribunal spécialisé: $e');
    }
  }
  
  /// Afficher erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: _startExercise,
        ),
      ),
    );
  }
  
  /// Faire défiler vers le bas
  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // MÉTHODES DE GAMIFICATION
  
  void _completeExercise(double score) {
    setState(() {
      _exerciseScore = score;
    });
    
    // Calcul XP avec bonus
    int earnedXP = _calculateXPWithBonus(score);
    
    // Animation XP
    _animateXPGain(earnedXP);
    
    // Vérifications
    _checkLevelUp();
    _checkBadgeUnlock();
    _checkAchievementProgress();
    
    // Sauvegarde
    _saveProgress();
  }
  
  int _calculateXPWithBonus(double score) {
    double totalMultiplier = xpMultiplier;
    
    if (score >= 1.0) totalMultiplier += bonusConditions['perfect_completion']!;
    if (score >= 0.8) totalMultiplier += bonusConditions['speed_bonus']!;
    
    return (baseXP * totalMultiplier).round();
  }
  
  void _animateXPGain(int xp) {
    setState(() {
      _earnedXP = xp;
      _currentXP += xp;
    });
    
    _xpAnimationController.forward();
    HapticFeedback.mediumImpact();
  }
  
  void _checkLevelUp() {
    int newLevel = _calculateLevel(_currentXP);
    if (newLevel > _currentLevel) {
      setState(() {
        _currentLevel = newLevel;
        _isLevelingUp = true;
      });
      
      _levelUpAnimationController.forward().then((_) {
        setState(() {
          _isLevelingUp = false;
        });
        _levelUpAnimationController.reset();
      });
      
      _confettiController.forward();
      HapticFeedback.heavyImpact();
    }
  }
  
  void _checkBadgeUnlock() {
    List<String> newBadges = _evaluateBadgeConditions();
    
    for (String badge in newBadges) {
      if (!_unlockedBadges.contains(badge)) {
        setState(() {
          _unlockedBadges.add(badge);
          _isBadgeUnlocked = true;
        });
        
        _badgeAnimationController.forward().then((_) {
          setState(() {
            _isBadgeUnlocked = false;
          });
          _badgeAnimationController.reset();
        });
        
        HapticFeedback.heavyImpact();
        break;
      }
    }
  }
  
  void _checkAchievementProgress() {
    // Logique des achievements
  }
  
  List<String> _evaluateBadgeConditions() {
    List<String> eligibleBadges = [];
    
    if (_exerciseScore >= 1.0 && !_unlockedBadges.contains('perfectionist')) {
      eligibleBadges.add('perfectionist');
    }
    
    if (_currentLevel >= 5 && !_unlockedBadges.contains('level_5_master')) {
      eligibleBadges.add('level_5_master');
    }
    
    return eligibleBadges;
  }
  
  int _getXPForNextLevel() {
    const xpPerLevel = [100, 250, 500, 1000, 2000, 4000, 8000, 15000, 30000, 50000];
    return _currentLevel < xpPerLevel.length ? xpPerLevel[_currentLevel - 1] : 50000;
  }
  
  int _calculateLevel(int totalXP) {
    const xpThresholds = [0, 100, 350, 850, 1850, 3850, 7850, 15850, 30850, 80850];
    
    for (int i = xpThresholds.length - 1; i >= 0; i--) {
      if (totalXP >= xpThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }
  
  String _getLastUnlockedBadgeName() {
    if (_unlockedBadges.isEmpty) return 'Badge Mystère';
    return _unlockedBadges.last.replaceAll('_', ' ').toUpperCase();
  }
  
  void _loadUserProgress() {
    // Charger depuis les services existants
    setState(() {
      _currentXP = 150; // Exemple
      _currentLevel = 2;
      _unlockedBadges = ['premier_plaidoyer'];
    });
  }
  
  void _saveProgress() {
    // Sauvegarder via les services existants
    print('Progression sauvegardée: XP=$_currentXP, Niveau=$_currentLevel');
  }
  
  @override
  void dispose() {
    _xpAnimationController.dispose();
    _badgeAnimationController.dispose();
    _levelUpAnimationController.dispose();
    _pulseAnimationController.dispose();
    _confettiController.dispose();
    _chatScrollController.dispose();
    _livekitService.dispose();
    super.dispose();
  }
}
