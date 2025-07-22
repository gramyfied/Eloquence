import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../layers/navigation/main_navigation.dart';
import '../../../core/navigation/navigation_state.dart';
import '../../../screens/home_screen.dart';
import '../../../screens/exercises_screen.dart';
import '../profile/profile_screen.dart';
import '../scenario/scenario_screen.dart';
import '../../../core/theme/dark_theme.dart';

// class MainScreen is a shell for displaying child routes with integrated navigation
class MainScreen extends ConsumerWidget {
  final Widget child;
  
  const MainScreen({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: DarkTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Child widget from the active route
              child,

              // Main Navigation Bar below content avec padding Android
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom,
                child: MainNavigation(
                  onNavigationChanged: (newRoute) {
                    ref.read(navigationStateProvider.notifier).navigateTo(newRoute, context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
