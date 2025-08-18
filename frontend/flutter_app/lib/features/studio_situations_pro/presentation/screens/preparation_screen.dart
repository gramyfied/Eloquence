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

class _PreparationScreenState extends ConsumerState<PreparationScreen> with TickerProviderStateMixin {
  // Wizard state
  int _currentStep = 0; // 0: objectif, 1: sujet, 2: diff/durée, 3: récap
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController(text: 'Participant');
  String _difficulty = 'intermediate';
  int _durationMinutes = 10;
  bool _isLoading = false;

  // Animation controllers (réutilisation légère)
  late AnimationController _micAnimationController;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _userNameController.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3 && _canProceed()) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _userNameController.text.trim().isNotEmpty;
      case 1:
        return _subjectController.text.trim().isNotEmpty;
      case 2:
      case 3:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceTheme.navy,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
                child: _buildStepContent(),
              ),
            ),
            _buildNavBar(),
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

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EloquenceTheme.spacingMd, vertical: EloquenceTheme.spacingSm),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active ? EloquenceTheme.cyan : EloquenceTheme.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepGoal();
      case 1:
        return _buildStepTopic();
      case 2:
        return _buildStepDifficultyDuration();
      case 3:
        return _buildStepSummary();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepGoal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Objectif & Identité', style: EloquenceTheme.headline3.copyWith(color: Colors.white)),
        const SizedBox(height: EloquenceTheme.spacingSm),
        Text('Définissez votre nom affiché et l’objectif de la session.', style: EloquenceTheme.bodyMedium.copyWith(color: Colors.white70)),
        const SizedBox(height: EloquenceTheme.spacingMd),
        TextField(
          controller: _userNameController,
          style: EloquenceTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Nom participant',
            labelStyle: EloquenceTheme.bodySmall.copyWith(color: Colors.white70),
            filled: true,
            fillColor: EloquenceTheme.glassBackground,
            border: OutlineInputBorder(
              borderRadius: EloquenceTheme.borderRadiusLarge,
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStepTopic() {
    final suggestions = _getTopicSuggestions(widget.simulationType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sujet', style: EloquenceTheme.headline3.copyWith(color: Colors.white)),
        const SizedBox(height: EloquenceTheme.spacingSm),
        Text('Choisissez un sujet ou saisissez le vôtre.', style: EloquenceTheme.bodyMedium.copyWith(color: Colors.white70)),
        const SizedBox(height: EloquenceTheme.spacingMd),
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
          onChanged: (_) => setState(() {}),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: EloquenceTheme.spacingSm),
          Wrap(
            spacing: EloquenceTheme.spacingSm,
            runSpacing: EloquenceTheme.spacingSm,
            children: suggestions.map((s) {
              return ActionChip(
                label: Text(s, overflow: TextOverflow.ellipsis),
                onPressed: () => setState(() => _subjectController.text = s),
                backgroundColor: EloquenceTheme.violet.withOpacity(0.3),
                labelStyle: EloquenceTheme.bodySmall.copyWith(color: Colors.white),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStepDifficultyDuration() {
    Widget diff(String value, String label, String desc) {
      final selected = _difficulty == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _difficulty = value),
          child: Container(
            padding: const EdgeInsets.all(EloquenceTheme.spacingSm),
            decoration: BoxDecoration(
              color: selected ? EloquenceTheme.cyan.withOpacity(0.1) : EloquenceTheme.glassBackground,
              borderRadius: EloquenceTheme.borderRadiusLarge,
              border: Border.all(color: selected ? EloquenceTheme.cyan : EloquenceTheme.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: EloquenceTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: EloquenceTheme.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulté & Durée', style: EloquenceTheme.headline3.copyWith(color: Colors.white)),
        const SizedBox(height: EloquenceTheme.spacingMd),
        Row(children: [
          diff('beginner', 'Débutant', 'Questions simples, rythme lent'),
          const SizedBox(width: 8),
          diff('intermediate', 'Intermédiaire', 'Équilibre défi / accessibilité'),
          const SizedBox(width: 8),
          diff('advanced', 'Avancé', 'Questions complexes'),
          const SizedBox(width: 8),
          diff('expert', 'Expert', 'Crise, pression maximale'),
        ]),
        const SizedBox(height: EloquenceTheme.spacingLg),
        Text("Durée (minutes)", style: EloquenceTheme.bodyMedium.copyWith(color: Colors.white)),
        Slider(
          value: _durationMinutes.toDouble(),
          min: 5,
          max: 30,
          divisions: 5,
          activeColor: EloquenceTheme.cyan,
          inactiveColor: EloquenceTheme.glassBorder,
          onChanged: (v) => setState(() => _durationMinutes = v.round()),
        ),
        Center(
          child: Text('$_durationMinutes min', style: EloquenceTheme.bodyMedium.copyWith(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildStepSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Récapitulatif', style: EloquenceTheme.headline3.copyWith(color: Colors.white)),
        const SizedBox(height: EloquenceTheme.spacingSm),
        _summaryRow('Simulation', widget.simulationType.toDisplayString(), Icons.theater_comedy),
        const SizedBox(height: 8),
        _summaryRow('Nom', _userNameController.text.trim().isEmpty ? 'Participant' : _userNameController.text.trim(), Icons.badge),
        const SizedBox(height: 8),
        _summaryRow('Sujet', _subjectController.text.trim().isEmpty ? 'Non défini' : _subjectController.text.trim(), Icons.topic),
        const SizedBox(height: 8),
        _summaryRow('Difficulté', _difficulty, Icons.trending_up),
        const SizedBox(height: 8),
        _summaryRow('Durée', '$_durationMinutes minutes', Icons.timer),
        const Spacer(),
      ],
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: EloquenceTheme.cyan, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: EloquenceTheme.bodySmall.copyWith(color: Colors.white70)),
              Text(value, style: EloquenceTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    final canProceed = _canProceed();
    return Padding(
      padding: const EdgeInsets.all(EloquenceTheme.spacingMd),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (canProceed && !_isLoading)
                  ? (_currentStep == 3 ? _startSimulation : _nextStep)
                  : null,
              child: _isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_currentStep == 3 ? 'Commencer la simulation' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSimulation() async {
    final userName = _userNameController.text.trim().isEmpty ? 'Participant' : _userNameController.text.trim();
    final subject = _subjectController.text.trim().isEmpty ? 'Sujet préparé avec le coach' : _subjectController.text.trim();

    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      context.push(
        '/simulation/${widget.simulationType.toRouteString()}',
        extra: {
          'userName': userName,
          'userSubject': subject,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du démarrage: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
}