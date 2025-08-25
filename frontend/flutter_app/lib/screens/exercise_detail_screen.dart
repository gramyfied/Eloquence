import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/navigation/navigation_state.dart';
import '../utils/constants.dart';
import '../widgets/layered_scaffold.dart';
import '../data/models/scenario_model.dart';
import '../data/services/api_service.dart';

// ====== Providers (état de préparation) ======
final selectedScenarioProvider = StateProvider<ScenarioModel?>((ref) => null);
final selectedDifficultyProvider = StateProvider<String>((ref) => 'intermediate');
final selectedDurationProvider = StateProvider<int>((ref) => 10);
final selectedTopicProvider = StateProvider<String?>((ref) => null);
final customTopicProvider = StateProvider<String>((ref) => '');
final isLoadingProvider = StateProvider<bool>((ref) => false);

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({Key? key, required this.exerciseId}) : super(key: key);

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExercisePreparationState();
}

class _ExercisePreparationState extends ConsumerState<ExerciseDetailScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // État des scénarios
  bool _isFetchingScenarios = false;
  List<ScenarioModel> _scenarios = [];

  // Fallback de scénarios prédéfinis (si API indisponible)
  final List<ScenarioModel> _predefinedScenarios = [
    ScenarioModel(
      id: 'debate_tv',
      name: 'Débat Télévisé',
      description: 'Débat TV avec journalistes et experts. Variations IA selon vos réponses.',
      type: 'debate',
      difficulty: 'intermediate',
      language: 'fr',
      tags: ['débat', 'télévision', 'actualité', 'argumentation'],
      previewImage: null,
    ),
    ScenarioModel(
      id: 'job_interview',
      name: "Entretien d'Embauche",
      description: 'Simulation RH + manager, réactions réalistes.',
      type: 'interview',
      difficulty: 'advanced',
      language: 'fr',
      tags: ['entretien', 'emploi', 'professionnel', 'stress'],
      previewImage: null,
    ),
    ScenarioModel(
      id: 'presentation_pitch',
      name: 'Présentation Projet',
      description: 'Pitch avec interruptions et questions imprévisibles.',
      type: 'presentation',
      difficulty: 'advanced',
      language: 'fr',
      tags: ['présentation', 'projet', 'investisseurs', 'pitch'],
      previewImage: null,
    ),
  ];

  // Sujets populaires par catégorie
  final Map<String, List<String>> _topicsByCategory = const {
    'Technologie': [
      'Intelligence Artificielle et Emploi',
      'Réseaux Sociaux et Vie Privée',
      'Voitures Autonomes',
      'Cryptomonnaies et Finance',
      'Télétravail et Productivité',
    ],
    'Société': [
      'Écologie vs Économie',
      'Éducation Numérique',
      'Égalité Hommes-Femmes',
      'Immigration et Intégration',
      'Santé Mentale au Travail',
    ],
    'Économie': [
      "Inflation et Pouvoir d'Achat",
      'Entrepreneuriat et Innovation',
      'Commerce International',
      'Économie Circulaire',
      'Investissement Responsable',
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
    _fetchScenarios();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchScenarios() async {
    setState(() => _isFetchingScenarios = true);
    try {
      final api = ApiService();
      final fetched = await api.getScenarios(language: 'fr');
      if (mounted) {
        setState(() => _scenarios = fetched);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _scenarios = _predefinedScenarios);
      }
    } finally {
      if (mounted) setState(() => _isFetchingScenarios = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3 && _canProceedToNextStep()) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  Future<void> _startExercise() async {
    final selectedScenario = ref.read(selectedScenarioProvider);
    final selectedTopic = ref.read(selectedTopicProvider);
    final customTopic = ref.read(customTopicProvider);

    if (selectedScenario == null) {
      _showError('Veuillez sélectionner un scénario');
      return;
    }

    final topic = selectedTopic ?? customTopic;
    if (topic.isEmpty) {
      _showError('Veuillez choisir ou saisir un sujet');
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final api = ApiService();
      const userId = 'user_demo';
      await api.startSession(
        selectedScenario.id,
        userId,
        language: 'fr',
        goal: topic,
        agentProfileId: null,
        isMultiAgent: false,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session démarrée')));

      // Lire les paramètres sélectionnés juste avant navigation
      final difficulty = ref.read(selectedDifficultyProvider);
      final duration = ref.read(selectedDurationProvider);

      context.go(
        '/exercise_active/${widget.exerciseId}',
        extra: {
          'topic': topic,
          'difficulty': difficulty,
          'duration': duration,
        },
      );
    } catch (e) {
      _showError('Erreur lors du démarrage: $e');
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); 
  }

  @override
  Widget build(BuildContext context) {
    return LayeredScaffold(
          carouselState: CarouselVisibilityState.subtle,
      showNavigation: false,
          onCarouselTap: () {
            ref.read(navigationStateProvider).navigateTo('/exercises');
            context.pop();
          },
      content: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, _) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
            child: Column(
              children: [
                  _buildProgressIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                  children: [
                        _buildScenarioSelection(),
                        _buildTopicSelection(),
                        _buildDifficultyAndDuration(),
                        _buildSummaryAndStart(),
                      ],
                    ),
                  ),
                  _buildNavigationBar(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? EloquenceColors.cyan : EloquenceColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScenarioSelection() {
    final selectedScenario = ref.watch(selectedScenarioProvider);
    final scenarios = _scenarios;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisissez votre scénario', style: EloquenceTextStyles.logoTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          const Text('Chaque scénario génère une expérience unique via IA', style: TextStyle(color: Color(0xB3FFFFFF))),
          const SizedBox(height: 16),
          if (_isFetchingScenarios)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: scenarios.length,
                itemBuilder: (context, index) {
                  final scenario = scenarios[index];
                  final isSelected = selectedScenario?.id == scenario.id;
                  return InkWell(
                    onTap: () => ref.read(selectedScenarioProvider.notifier).state = scenario,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0x332196F3) : const Color(0x221A1F2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? EloquenceColors.cyan : EloquenceColors.glassBorder),
                      ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Expanded(
                            child: Center(
                              child: Icon(_getScenarioIcon(scenario.type), color: EloquenceColors.cyan, size: 36),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(scenario.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                        Text(
                            scenario.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicSelection() {
    final selectedTopic = ref.watch(selectedTopicProvider);
    final customTopic = ref.watch(customTopicProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisissez votre sujet', style: EloquenceTextStyles.logoTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x221A1F2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EloquenceColors.glassBorder),
            ),
            child: TextField(
              onChanged: (value) {
                ref.read(customTopicProvider.notifier).state = value;
                if (value.isNotEmpty) {
                  ref.read(selectedTopicProvider.notifier).state = null;
                }
              },
              decoration: const InputDecoration(
                hintText: 'Saisissez votre sujet...',
                hintStyle: TextStyle(color: Color(0xB3FFFFFF)),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _topicsByCategory.entries.map((entry) {
                final category = entry.key;
                final topics = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(category, style: const TextStyle(color: EloquenceColors.cyan, fontWeight: FontWeight.bold)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topics.map((topic) {
                        final isSelected = selectedTopic == topic && customTopic.isEmpty;
                        return GestureDetector(
                        onTap: () {
                            ref.read(selectedTopicProvider.notifier).state = topic;
                            ref.read(customTopicProvider.notifier).state = '';
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: isSelected ? EloquenceColors.cyan : const Color(0x221A1F2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? EloquenceColors.cyan : EloquenceColors.glassBorder),
                            ),
                            child: Text(
                              topic,
                              style: TextStyle(color: isSelected ? Colors.white : Colors.white),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
                                ),
                              ),
                            ],
                          ),
    );
  }

  Widget _buildDifficultyAndDuration() {
    final selectedDifficulty = ref.watch(selectedDifficultyProvider);
    final selectedDuration = ref.watch(selectedDurationProvider);

    Widget difficultyOption(String value, String label, String description) {
      final isSelected = selectedDifficulty == value;
      return Expanded(
        child: InkWell(
          onTap: () => ref.read(selectedDifficultyProvider.notifier).state = value,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0x332196F3) : const Color(0x221A1F2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? EloquenceColors.cyan : EloquenceColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isSelected ? EloquenceColors.cyan : Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
              ],
                        ),
                      ),
                    ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personnalisez votre exercice', style: EloquenceTextStyles.logoTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          Row(children: [
            difficultyOption('beginner', 'Débutant', 'Questions simples, rythme lent'),
            const SizedBox(width: 8),
            difficultyOption('intermediate', 'Intermédiaire', 'Équilibre entre défi et accessibilité'),
            const SizedBox(width: 8),
            difficultyOption('advanced', 'Avancé', 'Questions complexes, interruptions'),
            const SizedBox(width: 8),
            difficultyOption('expert', 'Expert', 'Crise et pression maximale'),
          ]),
          const SizedBox(height: 24),
          const Text("Durée de l'exercice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x221A1F2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EloquenceColors.glassBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('5 min', style: TextStyle(color: Color(0xB3FFFFFF))),
                    Text('$selectedDuration min', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Text('30 min', style: TextStyle(color: Color(0xB3FFFFFF))),
                  ],
                ),
                Slider(
                  value: selectedDuration.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  activeColor: EloquenceColors.cyan,
                  inactiveColor: EloquenceColors.glassBorder,
                  onChanged: (value) => ref.read(selectedDurationProvider.notifier).state = value.round(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndStart() {
    final selectedScenario = ref.watch(selectedScenarioProvider);
    final selectedTopic = ref.watch(selectedTopicProvider);
    final customTopic = ref.watch(customTopicProvider);
    final difficulty = ref.watch(selectedDifficultyProvider);
    final duration = ref.watch(selectedDurationProvider);
    final topic = selectedTopic ?? customTopic;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif', style: EloquenceTextStyles.logoTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          _summaryRow('Scénario', selectedScenario?.name ?? 'Non sélectionné', Icons.theater_comedy),
          const SizedBox(height: 12),
          _summaryRow('Sujet', topic.isNotEmpty ? topic : 'Non défini', Icons.topic),
          const SizedBox(height: 12),
          _summaryRow('Difficulté', _getDifficultyLabel(difficulty), Icons.trending_up),
          const SizedBox(height: 12),
          _summaryRow('Durée', '$duration minutes', Icons.timer),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: EloquenceColors.cyan, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    final isLoading = ref.watch(isLoadingProvider);
    final canProceed = _canProceedToNextStep();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _previousStep,
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (canProceed && !isLoading)
                  ? (_currentStep == 3 ? _startExercise : _nextStep)
                  : null,
              child: isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_currentStep == 3 ? "Commencer l'exercice" : 'Suivant'),
            ),
          ),
        ],
          ),
        );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return ref.read(selectedScenarioProvider) != null;
      case 1:
        final selectedTopic = ref.read(selectedTopicProvider);
        final customTopic = ref.read(customTopicProvider);
        return selectedTopic != null || customTopic.isNotEmpty;
      case 2:
      case 3:
        return true;
      default:
        return false;
    }
  }

  IconData _getScenarioIcon(String type) {
    switch (type) {
      case 'debate':
        return Icons.forum;
      case 'interview':
        return Icons.work;
      case 'presentation':
        return Icons.present_to_all;
      case 'press_conference':
        return Icons.mic;
      case 'meeting':
        return Icons.groups;
      case 'negotiation':
        return Icons.handshake;
      default:
        return Icons.psychology;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      case 'expert':
        return 'Expert';
      default:
        return 'Intermédiaire';
    }
  }
}