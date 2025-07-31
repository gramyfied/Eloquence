# Guide de Correction : Problème Barre de Navigation Visible dans les Exercices

## ⚠️ Problème

La barre de navigation reste visible dans certains écrans d'exercices alors qu'elle devrait disparaître pour offrir une expérience immersive.

## 🔍 Diagnostic

### Symptômes
- La barre de navigation du bas reste affichée dans l'exercice
- L'utilisateur voit les boutons Home, Exercices, Profil pendant l'exercice
- L'expérience n'est pas immersive comme dans d'autres exercices (ex: roulette de virelangue)

### Cause Racine
Le problème vient de la configuration des routes dans `router_provider.dart`. Les routes configurées **à l'intérieur** du `ShellRoute` héritent automatiquement de la barre de navigation du `MainScreen`.

## 🛠️ Solution

### Étape 1: Identifier la Route Problématique

Dans `frontend/flutter_app/lib/presentation/providers/router_provider.dart`, chercher si la route est dans le `ShellRoute` :

```dart
// ❌ INCORRECT - Route dans ShellRoute
ShellRoute(
  builder: (context, state, child) => MainScreen(child: child),
  routes: [
    GoRoute(
      path: 'scenarios',  // ← Cette route aura la barre de navigation
      builder: (context, state) => const ScenarioScreen(),
    ),
  ],
),
```

### Étape 2: Déplacer la Route

Déplacer la route **en dehors** du `ShellRoute` et ajouter `parentNavigatorKey: rootNavigatorKey` :

```dart
// ✅ CORRECT - Route indépendante
GoRoute(
  path: 'scenarios',
  parentNavigatorKey: rootNavigatorKey, // ← Clé importante !
  builder: (context, state) => const ScenarioScreen(),
),
```

### Étape 3: Vérifier la Cohérence

S'assurer que toutes les routes d'exercices immersifs utilisent le même pattern :

```dart
// Exemples de routes correctement configurées
GoRoute(
  path: 'virelangue_roulette',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const VirelangueRouletteScreen(),
),

GoRoute(
  path: 'dragon_breath', 
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const DragonBreathScreen(),
),

GoRoute(
  path: 'scenario_exercise',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => ScenarioExerciseScreen(...),
),
```

## 📋 Checklist de Vérification

- [ ] La route utilise `parentNavigatorKey: rootNavigatorKey`
- [ ] La route est **en dehors** du `ShellRoute`
- [ ] Les autres exercices similaires utilisent le même pattern
- [ ] Test : la barre de navigation disparaît dans l'exercice
- [ ] Test : navigation de retour fonctionne correctement

## 🎯 Bonnes Pratiques

### Routes avec Barre de Navigation
Utiliser le `ShellRoute` pour les écrans de navigation principale :
- Home
- Liste des exercices  
- Profil
- Paramètres

### Routes sans Barre de Navigation
Utiliser `parentNavigatorKey: rootNavigatorKey` pour les écrans immersifs :
- Exercices actifs
- Écrans de configuration d'exercices
- Écrans de résultats
- Écrans plein écran

### Pattern de Navigation GoRouter

```dart
GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
      routes: [
        // Routes avec navigation
        ShellRoute(
          builder: (context, state, child) => MainScreen(child: child),
          routes: [
            GoRoute(path: 'home', ...),
            GoRoute(path: 'exercises', ...),
            GoRoute(path: 'profile', ...),
          ],
        ),
        
        // Routes immersives (sans navigation)
        GoRoute(
          path: 'exercise_name',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => ExerciseScreen(),
        ),
      ],
    ),
  ],
);
```

## 🚨 Erreurs Communes

1. **Oublier `parentNavigatorKey`** : La route reste dans le contexte du MainScreen
2. **Mauvais placement** : Route dans ShellRoute au lieu d'être indépendante  
3. **Incohérence** : Mélanger les patterns entre exercices similaires

## 🔧 Debug

Si le problème persiste :

1. Vérifier que `rootNavigatorKey` est bien défini
2. Contrôler l'ordre des routes (les plus spécifiques en premier)
3. Tester avec hot reload vs restart complet
4. Vérifier les logs de navigation GoRouter

## 📚 Références

- [Documentation GoRouter](https://pub.dev/packages/go_router)
- [ShellRoute vs GoRoute](https://docs.flutter.dev/ui/navigation/url-based)
- Configuration actuelle : `frontend/flutter_app/lib/presentation/providers/router_provider.dart`

---

**Note :** Ce guide résout le problème spécifique de la barre de navigation visible dans les exercices. Pour d'autres problèmes de navigation, consulter la documentation GoRouter officielle.