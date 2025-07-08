import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eloquence_2_0/core/utils/navigator_service.dart';

import '../screens/main/main_screen.dart';
import '../../screens/exercises_screen.dart'; // Utiliser le nouvel écran renommé
import '../screens/profile/profile_screen.dart';
import '../screens/scenario/scenario_screen.dart';
import '../../features/confidence_boost/presentation/screens/confidence_boost_screen.dart';
import '../../screens/exercise_detail_screen.dart'; // Import ExerciseDetailScreen
// import '../screens/continuous_streaming_screen.dart'; // Supprimé

/// Provider pour le routeur de l'application
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NavigatorService.navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
        routes: [
          GoRoute(
            path: 'exercise',
            builder: (context, state) => const ExercisesScreen(), // Utiliser le nouvel écran
          ),
          GoRoute(
            path: 'scenario',
            builder: (context, state) => const ScenarioScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'confidence-boost',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'] ?? 'default-user';
              return ConfidenceBoostScreen(userId: userId);
            },
          ),
          GoRoute(
            path: 'exercise_detail/:id', // Define new route for exercise detail
            builder: (context, state) {
              final exerciseId = state.pathParameters['id']!;
              return ExerciseDetailScreen(exerciseId: exerciseId);
            },
          ),
          // GoRoute(
          //   path: 'streaming',
          //   builder: (context, state) => const ContinuousStreamingScreen(), // Supprimé
          // ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page non trouvée: ${state.error}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  );
});