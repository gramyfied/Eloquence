import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/widgets/layered_scaffold.dart';
import 'package:eloquence_2_0/core/navigation/navigation_state.dart';
import '../../../features/ai_scenarios/presentation/screens/scenario_configuration_screen.dart';

class ScenarioScreen extends ConsumerStatefulWidget {
  const ScenarioScreen({super.key});

  @override
  ConsumerState<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends ConsumerState<ScenarioScreen> {
  @override
  void initState() {
    super.initState();
    // Mettre à jour le NavigationState quand on arrive sur cette page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationStateProvider.notifier).navigateTo('/scenarios');
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationStateProvider);
    
    return LayeredScaffold(
      carouselState: navigationState.carouselState,
      showNavigation: false, // Désactiver car déjà gérée par MainScreen
      content: const ScenarioConfigurationScreen(),
    );
  }
}
