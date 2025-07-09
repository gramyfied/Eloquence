import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/app_user.dart';
import '../../../../core/config/supabase_config.dart';

/// Service d'authentification Supabase
class SupabaseAuthService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  SupabaseClient get _client => SupabaseConfig.client;

  /// Obtenir l'utilisateur actuel
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    return AppUser.fromSupabaseUser(user);
  }

  /// Stream de changements d'état d'authentification
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((state) {
      final user = state.session?.user;
      if (user == null) return null;
      
      return AppUser.fromSupabaseUser(user);
    });
  }

  /// Inscription avec email et mot de passe
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _logger.i('Tentative d\'inscription: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      
      if (response.user != null) {
        _logger.i('Inscription réussie pour: $email');
        return AppUser.fromSupabaseUser(response.user!);
      }
      
      return null;
    } catch (e) {
      _logger.e('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Connexion avec email et mot de passe
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Tentative de connexion: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _logger.i('Connexion réussie pour: $email');
        return currentUser;
      }
      
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      _logger.i('Déconnexion en cours...');
      await _client.auth.signOut();
      _logger.i('Déconnexion réussie');
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('Demande de réinitialisation du mot de passe: $email');
      await _client.auth.resetPasswordForEmail(email);
      _logger.i('Email de réinitialisation envoyé');
    } catch (e) {
      _logger.e('Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }

  /// Mise à jour du profil utilisateur
  Future<AppUser?> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      _logger.i('Mise à jour du profil utilisateur');
      
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      
      if (updates.isNotEmpty) {
        await _client.auth.updateUser(
          UserAttributes(data: updates),
        );
      }
      
      _logger.i('Profil mis à jour avec succès');
      return currentUser;
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  /// Obtenir le token JWT actuel
  String? get currentToken {
    return _client.auth.currentSession?.accessToken;
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isSignedIn {
    return _client.auth.currentUser != null;
  }

  /// Actualiser la session
  Future<void> refreshSession() async {
    try {
      await _client.auth.refreshSession();
      _logger.i('Session actualisée');
    } catch (e) {
      _logger.e('Erreur lors de l\'actualisation de la session: $e');
      rethrow;
    }
  }
}