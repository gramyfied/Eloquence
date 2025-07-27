import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eloquence_2_0/core/utils/navigator_service.dart';

// Import de tous les écrans nécessaires
import '../../screens/home_screen.dart';
import '../../screens/exercises_screen.dart';
import '../../screens/exercise_detail_screen.dart';
import '../../screens/exercise_active_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/scenario/scenario_screen.dart';
import '../../features/confidence_boost/presentation/screens/confidence_boost_entry.dart';
import '../../features/confidence_boost/domain/entities/confidence_scenario.dart';
import '../../features/confidence_boost/domain/entities/confidence_models.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/widgets/auth_wrapper.dart';

/// Provider pour le routeur unifié de l'application selon les meilleures pratiques GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NavigatorService.navigatorKey,
    initialLocation: '/',
    routes: <RouteBase>[
      // Route racine avec AuthWrapper
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const AuthWrapper();
        },
        routes: <RouteBase>[
          // Routes d'authentification
          GoRoute(
            path: 'login',
            builder: (BuildContext context, GoRouterState state) {
              return const LoginScreen();
            },
          ),
          GoRoute(
            path: 'signup',
            builder: (BuildContext context, GoRouterState state) {
              return const SignUpScreen();
            },
          ),
          
          // Route principale avec navigation intégrée
          ShellRoute(
            builder: (BuildContext context, GoRouterState state, Widget child) {
              return MainScreen(child: child);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'home',
                builder: (BuildContext context, GoRouterState state) {
                  return const HomeScreen();
                },
              ),
              GoRoute(
                path: 'exercises',
                builder: (BuildContext context, GoRouterState state) {
                  return const ExercisesScreen();
                },
              ),
              GoRoute(
                path: 'scenarios',
                builder: (BuildContext context, GoRouterState state) {
                  return const ScenarioScreen();
                },
              ),
              GoRoute(
                path: 'profile',
                builder: (BuildContext context, GoRouterState state) {
                  return const ProfileScreen();
                },
              ),
            ],
          ),
          
          // Route confidence_boost - NOUVELLE APPROCHE LIVEKIT
          GoRoute(
            path: 'confidence_boost',
            builder: (BuildContext context, GoRouterState state) {
              // Utilise le nouveau écran LiveKit (remplace WebSocket)
              final defaultScenario = ConfidenceScenario(
                id: 'default',
                title: 'Conversation Confiance',
                description: 'Exercice de conversation pour améliorer votre confiance en public',
                prompt: 'Exprimez-vous naturellement et avec confiance sur un sujet qui vous intéresse',
                type: ConfidenceScenarioType.presentation,
                durationSeconds: 600,
                difficulty: 'beginner',
                icon: '🎤',
                keywords: ['confiance', 'expression', 'communication'],
                tips: ['Parlez clairement', 'Restez naturel', 'Prenez votre temps'],
              );
              return ConfidenceBoostEntry.livekitScreen(defaultScenario);
            },
          ),
          
          // Routes paramétrées
          GoRoute(
            path: 'exercise_detail/:id',
            builder: (BuildContext context, GoRouterState state) {
              final exerciseId = state.pathParameters['id']!;
              return ExerciseDetailScreen(exerciseId: exerciseId);
            },
          ),
          GoRoute(
            path: 'exercise_active/:id',
            builder: (BuildContext context, GoRouterState state) {
              final exerciseId = state.pathParameters['id']!;
              
              // CORRECTION CRITIQUE : Rediriger confidence_boost vers LiveKit
              if (exerciseId == 'confidence_boost') {
                final defaultScenario = ConfidenceScenario(
                  id: 'confidence_boost',
                  title: 'Confidence Boost',
                  description: 'Exercice pour améliorer votre confiance en expression orale',
                  prompt: 'Parlez avec assurance et confiance sur un sujet de votre choix',
                  type: ConfidenceScenarioType.presentation,
                  durationSeconds: 600,
                  difficulty: 'beginner',
                  icon: '💪',
                  keywords: ['confiance', 'assurance', 'expression'],
                  tips: ['Parlez avec assurance', 'Gardez le contact visuel', 'Structurez vos idées'],
                );
                return ConfidenceBoostEntry.livekitScreen(defaultScenario);
              }
              return ExerciseActiveScreen(exerciseId: exerciseId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Text(
          'Page non trouvée: ${state.error}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  );
});
