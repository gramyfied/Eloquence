import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../layers/navigation/main_navigation.dart';
import '../../../core/navigation/navigation_state.dart';
import '../../../screens/home_screen.dart';
import '../../../screens/exercises_screen.dart';
import '../profile/profile_screen.dart';
import '../scenario/scenario_screen.dart';
import '../../../core/theme/dark_theme.dart';

// class MainScreen is rewritten to use MainNavigation and NavigationState
class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current route from NavigationState (using Riverpod)
    final currentRoute = ref.watch(navigationStateProvider).currentRoute;

    // Map routes to actual screen widgets
    Widget _getPageForRoute(String route) {
      switch (route) {
        case '/home':
          return const HomeScreen();
        case '/exercises':
          return const ExercisesScreen();
        case '/profile':
          return const ProfileScreen();
        case '/scenarios':
          return const ScenarioScreen();
        default:
          return const Column(
            children: [
              Text('Page non trouvée'),
            ],
          );
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: DarkTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Active screen based on currentRoute
            _getPageForRoute(currentRoute),

            // Main Navigation Bar below content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MainNavigation(
                onNavigationChanged: (newRoute) {
                  ref.read(navigationStateProvider.notifier).navigateTo(newRoute, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
