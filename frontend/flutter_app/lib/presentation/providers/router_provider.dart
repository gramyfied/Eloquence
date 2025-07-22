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
import '../../features/confidence_boost/presentation/screens/confidence_boost_adaptive_screen.dart';
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
          
          // Routes principales de l'application
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
              return const ExercisesScreen(); // Redirection temporaire
            },
          ),
          GoRoute(
            path: 'profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfileScreen();
            },
          ),
          
          // Route confidence_boost - NOUVELLE INTERFACE ADAPTATIVE
          GoRoute(
            path: 'confidence_boost',
            builder: (BuildContext context, GoRouterState state) {
              // Scénario par défaut optimisé pour l'interface conversationnelle
              const defaultScenario = ConfidenceScenario(
                id: 'confidence_boost_express',
                title: 'Confidence Boost Express',
                description: 'Gagnez en assurance en 3 minutes avec un sujet qui vous passionne',
                prompt: 'Parlez d\'un sujet qui vous passionne pendant 2 minutes. Exprimez-vous avec confiance et authenticité.',
                type: ConfidenceScenarioType.presentation,
                durationSeconds: 120,
                difficulty: 'Facile',
                icon: '🚀',
                tips: [
                  'Choisissez un sujet qui vous anime vraiment',
                  'Respirez profondément avant de commencer',
                  'Regardez droit devant vous',
                  'Laissez votre passion transparaître',
                ],
                keywords: [
                  'passion',
                  'confiance',
                  'authenticité',
                  'expression',
                ],
              );
              return const ConfidenceBoostAdaptiveScreen(scenario: defaultScenario);
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
              
              // CORRECTION CRITIQUE : Rediriger confidence_boost vers la nouvelle interface
              if (exerciseId == 'confidence_boost') {
                const defaultScenario = ConfidenceScenario(
                  id: 'confidence_boost_express',
                  title: 'Confidence Boost Express',
                  description: 'Gagnez en assurance en 3 minutes avec un sujet qui vous passionne',
                  prompt: 'Parlez d\'un sujet qui vous passionne pendant 2 minutes. Exprimez-vous avec confiance et authenticité.',
                  type: ConfidenceScenarioType.presentation,
                  durationSeconds: 120,
                  difficulty: 'Facile',
                  icon: '🚀',
                  tips: [
                    'Choisissez un sujet qui vous anime vraiment',
                    'Respirez profondément avant de commencer',
                    'Regardez droit devant vous',
                    'Laissez votre passion transparaître',
                  ],
                  keywords: [
                    'passion',
                    'confiance',
                    'authenticité',
                    'expression',
                  ],
                );
                return const ConfidenceBoostAdaptiveScreen(scenario: defaultScenario);
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