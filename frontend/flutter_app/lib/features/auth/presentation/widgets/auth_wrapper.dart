import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../../../../presentation/theme/eloquence_design_system.dart';

/// AuthWrapper qui détermine si afficher l'écran d'authentification ou l'app principale
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Debug logs pour le mode développeur
    debugPrint('🔐 AuthWrapper: État auth = ${authState.state}');
    if (authState.user != null) {
      debugPrint('👤 Utilisateur connecté: ${authState.user!.email}');
    }

    // Vérifier l'état d'authentification
    if (authState.state == AuthState.loading) {
      return _buildLoadingScreen();
    } else if (authState.state == AuthState.authenticated && authState.user != null) {
      debugPrint('✅ Utilisateur authentifié, redirection vers /home');
      // Rediriger vers la route principale au lieu d'instancier MainScreen directement
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return _buildLoadingScreen(); // Afficher le loading pendant la redirection
    } else if (authState.state == AuthState.error) {
      debugPrint('🚨 Erreur d\'authentification: ${authState.error}');
      return _buildErrorScreen(authState.error ?? 'Erreur inconnue');
    } else {
      debugPrint('❌ Utilisateur non authentifié, affichage LoginScreen');
      return const LoginScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EloquenceColors.navy,
              EloquenceColors.cyan,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  EloquenceColors.cyan,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Initialisation...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EloquenceColors.navy,
              Color(0xFF8B0000), // Rouge foncé pour erreur
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur d\'authentification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Retry authentication
                    debugPrint('🔄 Tentative de reconnexion...');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EloquenceColors.cyan,
                    foregroundColor: EloquenceColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
