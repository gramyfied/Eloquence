import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/avatar_with_halo.dart';
import 'tribunal_idees_screen_real.dart';

class TribunalIdeesScreen extends ConsumerStatefulWidget {
  const TribunalIdeesScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<TribunalIdeesScreen> createState() => _TribunalIdeesScreenState();
}

class _TribunalIdeesScreenState extends ConsumerState<TribunalIdeesScreen> 
    with TickerProviderStateMixin {
  
  // Gamification State
  int _currentXP = 150;
  int _currentLevel = 2;
  List<String> _unlockedBadges = ['premier_plaidoyer'];
  
  // Exercise State
  String _currentDebateTopic = '';
  List<String> _debateTopics = [
    'Les chaussettes dépareillées sont-elles un crime contre l\'humanité ?',
    'Faut-il interdire les lundis matins par décret présidentiel ?',
    'Les licornes devraient-elles payer des impôts ?',
    'Est-ce que les robots ont le droit de rêver de moutons électriques ?',
    'Faut-il créer un permis de conduire pour les trottinettes ?'
  ];
  
  // Animation Controllers
  late AnimationController _pulseAnimationController;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectRandomTopic();
  }
  
  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  void _selectRandomTopic() {
    setState(() {
      _currentDebateTopic = _debateTopics[DateTime.now().millisecond % _debateTopics.length];
    });
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
                // Header avec gamification
                _buildGamificationHeader(),
                
                // Corps principal
                Expanded(
                  child: _buildWelcomeInterface(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGamificationHeader() {
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
          // Titre
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
            ],
          ),
          
          SizedBox(height: 16),
          
          // Barre XP simple
          _buildSimpleXPBar(),
          
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
                  label: '85%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleXPBar() {
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
              '$_currentXP / 250 XP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        Container(
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
              value: _currentXP / 250,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
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
                  onPressed: _startTribunalExercise,
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
                        'XP de base: 120',
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
                        'Multiplicateur: 1.7x',
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
  
  /// Démarrer l'exercice tribunal - redirige vers l'écran spécialisé
  void _startTribunalExercise() {
    HapticFeedback.mediumImpact();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TribunalIdeesScreenReal(),
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseAnimationController.dispose();
    super.dispose();
  }
}
