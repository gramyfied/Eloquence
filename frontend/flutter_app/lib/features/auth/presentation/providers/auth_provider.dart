import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/app_user.dart';
import '../../data/services/supabase_auth_service.dart';

/// États d'authentification possibles
enum AuthState {
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Classe pour encapsuler l'état d'authentification
class AuthStateData {
  final AuthState state;
  final AppUser? user;
  final String? error;

  const AuthStateData({
    required this.state,
    this.user,
    this.error,
  });

  AuthStateData copyWith({
    AuthState? state,
    AppUser? user,
    String? error,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthStateData &&
        other.state == state &&
        other.user == user &&
        other.error == error;
  }

  @override
  int get hashCode => state.hashCode ^ user.hashCode ^ error.hashCode;
}

/// Provider du service d'authentification Supabase
final authServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

/// Notifier pour gérer l'état d'authentification
class AuthNotifier extends StateNotifier<AuthStateData> {
  final SupabaseAuthService _authService;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  AuthNotifier(this._authService)
      : super(const AuthStateData(state: AuthState.loading)) {
    _initializeAuth();
  }

  /// Initialiser l'authentification et écouter les changements
  void _initializeAuth() {
    // Timeout pour éviter que l'initialisation reste bloquée
    _initializeWithTimeout();
  }

  Future<void> _initializeWithTimeout() async {
    try {
      // Timeout de 5 secondes pour l'initialisation
      await Future.any([
        _performInitialization(),
        Future.delayed(const Duration(seconds: 5)).then((_) => throw TimeoutException('Auth timeout', const Duration(seconds: 5))),
      ]);
    } on TimeoutException {
      _logger.w('⚠️ Timeout d\'authentification - Passage en mode hors ligne');
      state = const AuthStateData(state: AuthState.unauthenticated);
    } catch (e) {
      _logger.e('❌ Erreur d\'initialisation auth: $e');
      // En cas d'erreur, passer en mode unauthenticated plutôt que de rester en loading
      state = const AuthStateData(state: AuthState.unauthenticated);
    }
  }

  Future<void> _performInitialization() async {
    try {
      // Vérifier l'état initial avec timeout
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _logger.i('👤 Utilisateur existant trouvé: ${currentUser.email}');
        state = AuthStateData(state: AuthState.authenticated, user: currentUser);
      } else {
        _logger.i('👤 Aucun utilisateur connecté');
        state = const AuthStateData(state: AuthState.unauthenticated);
      }

      // Écouter les changements d'état d'authentification avec gestion d'erreur robuste
      _authService.authStateChanges.timeout(const Duration(seconds: 10)).listen(
        (user) {
          if (user != null) {
            _logger.i('🔐 Utilisateur connecté: ${user.email}');
            state = AuthStateData(state: AuthState.authenticated, user: user);
          } else {
            _logger.i('🔐 Utilisateur déconnecté');
            state = const AuthStateData(state: AuthState.unauthenticated);
          }
        },
        onError: (error) {
          _logger.w('⚠️ Erreur dans le stream d\'authentification: $error - Mode hors ligne');
          // En cas d'erreur réseau, ne pas bloquer l'app, rester en unauthenticated
          if (state.state == AuthState.loading) {
            state = const AuthStateData(state: AuthState.unauthenticated);
          }
        },
      );
    } catch (e) {
      _logger.e('❌ Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Inscription avec email et mot de passe
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = const AuthStateData(state: AuthState.loading);
      
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        _logger.i('Inscription réussie: ${user.email}');
        state = AuthStateData(state: AuthState.authenticated, user: user);
      } else {
        state = const AuthStateData(
          state: AuthState.error,
          error: 'Échec de l\'inscription',
        );
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'inscription: $e');
      state = AuthStateData(
        state: AuthState.error,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Connexion avec email et mot de passe
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = const AuthStateData(state: AuthState.loading);
      
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        _logger.i('Connexion réussie: ${user.email}');
        state = AuthStateData(state: AuthState.authenticated, user: user);
      } else {
        state = const AuthStateData(
          state: AuthState.error,
          error: 'Échec de la connexion',
        );
      }
    } catch (e) {
      _logger.e('Erreur lors de la connexion: $e');
      state = AuthStateData(
        state: AuthState.error,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      state = const AuthStateData(state: AuthState.loading);
      await _authService.signOut();
      _logger.i('Déconnexion réussie');
      state = const AuthStateData(state: AuthState.unauthenticated);
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion: $e');
      state = AuthStateData(
        state: AuthState.error,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      _logger.i('Email de réinitialisation envoyé à: $email');
    } catch (e) {
      _logger.e('Erreur lors de la réinitialisation: $e');
      throw _getErrorMessage(e);
    }
  }

  /// Mise à jour du profil
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final updatedUser = await _authService.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      if (updatedUser != null) {
        state = AuthStateData(state: AuthState.authenticated, user: updatedUser);
        _logger.i('Profil mis à jour avec succès');
      }
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du profil: $e');
      state = AuthStateData(
        state: AuthState.error,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Actualiser la session
  Future<void> refreshSession() async {
    try {
      await _authService.refreshSession();
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        state = AuthStateData(state: AuthState.authenticated, user: currentUser);
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'actualisation de la session: $e');
      // Ne pas changer l'état si l'actualisation échoue
    }
  }

  /// Effacer l'erreur
  void clearError() {
    if (state.state == AuthState.error) {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        state = AuthStateData(state: AuthState.authenticated, user: currentUser);
      } else {
        state = const AuthStateData(state: AuthState.unauthenticated);
      }
    }
  }

  /// Mode développeur - Connexion directe avec utilisateur fictif
  void setDeveloperUser(AppUser user) {
    _logger.w('🚧 MODE DÉVELOPPEUR: Connexion directe sans authentification');
    _logger.i('🚧 Utilisateur développeur: ${user.displayName} (${user.email})');
    state = AuthStateData(state: AuthState.authenticated, user: user);
  }

  /// Obtenir un message d'erreur user-friendly
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid_credentials') || 
        errorString.contains('invalid login')) {
      return 'Email ou mot de passe incorrect';
    } else if (errorString.contains('email_address_invalid')) {
      return 'Adresse email invalide';
    } else if (errorString.contains('password_too_short')) {
      return 'Mot de passe trop court (minimum 6 caractères)';
    } else if (errorString.contains('user_already_registered')) {
      return 'Un compte existe déjà avec cette adresse email';
    } else if (errorString.contains('network')) {
      return 'Problème de connexion réseau';
    } else if (errorString.contains('timeout')) {
      return 'Délai d\'attente dépassé, veuillez réessayer';
    } else {
      return 'Une erreur est survenue, veuillez réessayer';
    }
  }
}

/// Provider principal pour l'état d'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

/// Provider pour vérifier si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.state == AuthState.authenticated && authState.user != null;
});

/// Provider pour obtenir l'utilisateur actuel
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Provider pour obtenir le token JWT actuel
final currentTokenProvider = Provider<String?>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.currentToken;
});