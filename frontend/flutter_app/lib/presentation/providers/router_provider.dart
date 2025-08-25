import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../features/studio_situations_pro/data/models/simulation_models.dart';
import '../../features/confidence_boost/presentation/screens/virelangue_roulette_screen.dart';
import '../../features/confidence_boost/presentation/screens/dragon_breath_screen.dart';
import '../../features/confidence_boost/presentation/screens/cosmic_voice_screen.dart';
import '../../features/story_generator/presentation/screens/story_generator_home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/widgets/auth_wrapper.dart';
import '../../features/confidence_boost/presentation/screens/tribunal_idees_screen_real.dart';

import '../../features/studio_situations_pro/presentation/screens/simulation_selection_screen.dart'; // NOUVEAU
import '../../features/studio_situations_pro/presentation/screens/preparation_screen.dart';      // NOUVEAU
import '../../features/studio_situations_pro/presentation/screens/simulation_screen.dart';       // NOUVEAU

// Définir une GlobalKey pour le navigateur racine, après les imports
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider pour le routeur unifié de l'application selon les meilleures pratiques GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey, // Utiliser la clé globale
    initialLocation: '/',
    routes: <RouteBase>[
      // Route racine avec AuthWrapper
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const AuthWrapper();
        },
        // Routes enfants de la route racine (peuvent utiliser rootNavigatorKey)
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
              // Ceci encapsule les routes de navigation principales
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
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              // Construire un scénario en lisant éventuellement le contexte passé via extra
              String? topic;
              String? difficulty;
              int? durationMinutes;
              final extra = state.extra;
              if (extra is Map) {
                final map = Map<String, dynamic>.from(extra);
                topic = map['topic'] as String?;
                difficulty = map['difficulty'] as String?;
                final dur = map['duration'];
                if (dur is int) durationMinutes = dur;
              }

              final scenario = ConfidenceScenario(
                id: 'confidence_boost',
                title: 'Conversation Confiance',
                description: 'Exercice de conversation pour améliorer votre confiance en public',
                prompt: topic != null && topic.isNotEmpty
                    ? 'Parlez avec assurance sur "$topic"; développez vos idées clairement.'
                    : 'Exprimez-vous naturellement et avec confiance sur un sujet qui vous intéresse',
                type: ConfidenceScenarioType.presentation,
                durationSeconds: (durationMinutes ?? 10) * 60,
                difficulty: difficulty ?? 'beginner',
                icon: '🎤',
                keywords: ['confiance', 'expression', 'communication'],
                tips: ['Parlez clairement', 'Restez naturel', 'Prenez votre temps'],
              );
              return ConfidenceBoostEntry.livekitScreen(scenario);
            },
          ),
          
          // Route virelangue_roulette - NOUVELLE ROULETTE MAGIQUE
          GoRoute(
            path: 'virelangue_roulette',
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              return const VirelangueRouletteScreen();
            },
          ),
          
          // Route dragon_breath - NOUVEL EXERCICE SOUFFLE DE DRAGON
          GoRoute(
            path: 'dragon_breath',
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              return const DragonBreathScreen();
            },
          ),
          
          // Route story_generator - GÉNÉRATEUR D'HISTOIRES INFINIES
          GoRoute(
            path: 'story_generator',
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              return const StoryGeneratorHomeScreen();
            },
          ),
          
          // Route cosmic_voice - L'ACCORDEUR VOCAL COSMIQUE
          GoRoute(
            path: 'cosmic_voice',
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              return const CosmicVoiceScreen();
            },
          ),
          
          // Route tribunal_idees - LE TRIBUNAL DES IDÉES
          GoRoute(
            path: 'tribunal_idees',
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              return const TribunalIdeesScreenReal();
            },
          ),
          
          // Routes paramétrées
          GoRoute(
            path: 'exercise_detail/:id',
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              final exerciseId = state.pathParameters['id']!;
              return ExerciseDetailScreen(exerciseId: exerciseId);
            },
          ),
          GoRoute(
            path: 'exercise_active/:id',
            parentNavigatorKey: rootNavigatorKey, // Ouvre sur le navigateur racine
            builder: (BuildContext context, GoRouterState state) {
              final exerciseId = state.pathParameters['id']!;
              
              // CORRECTION CRITIQUE : Rediriger confidence_boost vers LiveKit
              if (exerciseId == 'confidence_boost') {
                String? topic;
                String? difficulty;
                int? durationMinutes;
                final extra = state.extra;
                if (extra is Map) {
                  final map = Map<String, dynamic>.from(extra);
                  topic = map['topic'] as String?;
                  difficulty = map['difficulty'] as String?;
                  final dur = map['duration'];
                  if (dur is int) durationMinutes = dur;
                }

                final scenario = ConfidenceScenario(
                  id: 'confidence_boost',
                  title: 'Confidence Boost',
                  description: 'Exercice pour améliorer votre confiance en expression orale',
                  prompt: topic != null && topic.isNotEmpty
                      ? 'Parlez avec assurance sur "$topic"; structurez vos idées avec clarté.'
                      : 'Parlez avec assurance et confiance sur un sujet de votre choix',
                  type: ConfidenceScenarioType.presentation,
                  durationSeconds: (durationMinutes ?? 10) * 60,
                  difficulty: difficulty ?? 'beginner',
                  icon: '💪',
                  keywords: ['confiance', 'assurance', 'expression'],
                  tips: ['Parlez avec assurance', 'Gardez le contact visuel', 'Structurez vos idées'],
                );
                return ConfidenceBoostEntry.livekitScreen(scenario);
              }
              
              // NOUVEAU : Rediriger virelangue_roulette vers l'écran virelangue
              if (exerciseId == 'virelangue_roulette') {
                return const VirelangueRouletteScreen();
              }
              
              // NOUVEAU : Rediriger dragon_breath vers l'écran souffle de dragon
              if (exerciseId == 'dragon_breath') {
                return const DragonBreathScreen();
              }
              
              // NOUVEAU : Rediriger story_generator vers l'écran générateur d'histoires
              if (exerciseId == 'story_generator') {
                return const StoryGeneratorHomeScreen();
              }
              
              // NOUVEAU : Rediriger cosmic_voice vers l'Accordeur Vocal Cosmique
              if (exerciseId == 'cosmic_voice') {
                return const CosmicVoiceScreen();
              }
              
              // NOUVEAU : Rediriger tribunal_idees vers le Tribunal des Idées
              if (exerciseId == 'tribunal_idees') {
                return const TribunalIdeesScreenReal();
              }
              
              return ExerciseActiveScreen(exerciseId: exerciseId);
            },
          ),

          // Routes Studio Situations Pro (NOUVEAU)
          GoRoute(
            path: 'studio_situations_pro',
            parentNavigatorKey: rootNavigatorKey,
            builder: (BuildContext context, GoRouterState state) {
              return SimulationSelectionScreen();
            },
          ),
          GoRoute(
            path: 'preparation/:simulationType',
            parentNavigatorKey: rootNavigatorKey,
            builder: (BuildContext context, GoRouterState state) {
              final simulationType = state.pathParameters['simulationType']!;
              return PreparationScreen(
                simulationType: SimulationTypeExtension.fromRouteString(simulationType),
              );
            },
          ),
          GoRoute(
            path: 'simulation/:simulationType',
            parentNavigatorKey: rootNavigatorKey,
            builder: (BuildContext context, GoRouterState state) {
              final simulationType = state.pathParameters['simulationType']!;
              // Transmettre les extras (userName, userSubject) si fournis
              final extra = state.extra;
              String? userName;
              String? userSubject;
              if (extra is Map) {
                final map = Map<String, dynamic>.from(extra);
                userName = map['userName'] as String?;
                userSubject = map['userSubject'] as String?;
              }
              return SimulationScreen(
                simulationType: SimulationTypeExtension.fromRouteString(simulationType),
                userName: userName,
                userSubject: userSubject,
              );
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
