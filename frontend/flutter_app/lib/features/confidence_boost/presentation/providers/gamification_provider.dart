import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/gamification_models.dart';
import '../../data/services/adaptive_gamification_service.dart';

/// Provider pour la gestion d'état de la gamification
/// 
/// ✅ FONCTIONNALITÉS :
/// - Gestion du profil utilisateur gamifié
/// - Calcul automatique des récompenses post-session
/// - État de loading et erreur pour les opérations async
/// - Cache des badges disponibles
/// - Notifications des nouveaux accomplissements
class GamificationState {
  final UserGamificationProfile? userProfile;
  final List<Badge> availableBadges;
  final GamificationResult? lastSessionResult;
  final bool isLoading;
  final String? error;
  final bool showCelebration;

  const GamificationState({
    this.userProfile,
    this.availableBadges = const [],
    this.lastSessionResult,
    this.isLoading = false,
    this.error,
    this.showCelebration = false,
  });

  GamificationState copyWith({
    UserGamificationProfile? userProfile,
    List<Badge>? availableBadges,
    GamificationResult? lastSessionResult,
    bool? isLoading,
    String? error,
    bool? showCelebration,
  }) {
    return GamificationState(
      userProfile: userProfile ?? this.userProfile,
      availableBadges: availableBadges ?? this.availableBadges,
      lastSessionResult: lastSessionResult ?? this.lastSessionResult,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      showCelebration: showCelebration ?? this.showCelebration,
    );
  }
}

/// Notifier pour gérer les opérations de gamification
class GamificationNotifier extends StateNotifier<GamificationState> {
  final AdaptiveGamificationService _gamificationService;
  final Logger _logger = Logger();

  GamificationNotifier(this._gamificationService) : super(const GamificationState());

  /// Initialise la gamification pour un utilisateur
  Future<void> initializeForUser(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Initialiser le service
      await _gamificationService.initialize();
      
      // Charger le profil utilisateur
      final userProfile = await _gamificationService.getUserProfile(userId);
      
      // Charger tous les badges disponibles
      final badges = await _gamificationService.getAllBadges();
      
      state = state.copyWith(
        userProfile: userProfile,
        availableBadges: badges,
        isLoading: false,
      );
      
      _logger.i('🎮 Gamification initialisée pour $userId - Niveau ${userProfile.currentLevel}');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur initialisation gamification: $e', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'initialisation de la gamification: $e',
      );
    }
  }

  /// Calcule et applique les récompenses après une session
  Future<void> processSessionRewards({
    required String userId,
    required double overallScore,
    required ConversationDifficulty difficulty,
    required Duration sessionDuration,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      if (state.userProfile == null) {
        _logger.w('⚠️ Profil utilisateur non initialisé');
        return;
      }

      state = state.copyWith(isLoading: true, error: null);

      // Créer un AnalysisResult temporaire pour le calcul
      final analysisResult = AnalysisResult(
        overallConfidenceScore: overallScore,
        skillScores: additionalContext?['skillScores'] ?? {},
      );

      // Calculer les récompenses
      final gamificationResult = await _gamificationService.calculateAdaptiveRewards(
        userId: userId,
        analysisResult: analysisResult,
        difficulty: difficulty,
        sessionDuration: sessionDuration,
        additionalContext: additionalContext,
      );

      // Recharger le profil mis à jour
      final updatedProfile = await _gamificationService.getUserProfile(userId);

      state = state.copyWith(
        userProfile: updatedProfile,
        lastSessionResult: gamificationResult,
        isLoading: false,
        showCelebration: gamificationResult.earnedXP > 0,
      );

      _logger.i('🎉 Récompenses appliquées: ${gamificationResult.earnedXP}XP, ${gamificationResult.newBadges.length} badges');

      // Auto-masquer la célébration après un délai
      _autoHideCelebration();

    } catch (e, stackTrace) {
      _logger.e('❌ Erreur traitement récompenses: $e', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du calcul des récompenses: $e',
      );
    }
  }

  /// Masque la célébration après un délai
  void _autoHideCelebration() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        state = state.copyWith(showCelebration: false);
      }
    });
  }

  /// Force le masquage de la célébration
  void hideCelebration() {
    state = state.copyWith(showCelebration: false);
  }

  /// Obtient les badges gagnés par l'utilisateur
  Future<List<Badge>> getUserEarnedBadges(String userId) async {
    try {
      return await _gamificationService.getUserBadges(userId);
    } catch (e) {
      _logger.e('❌ Erreur récupération badges: $e');
      return [];
    }
  }

  /// Obtient des encouragements personnalisés
  List<String> getPersonalizedEncouragements() {
    if (state.userProfile == null) return [];
    
    return _gamificationService.getPersonalizedEncouragements(
      state.userProfile!,
      state.lastSessionResult != null 
        ? AnalysisResult(overallConfidenceScore: 0.8) // Mock pour l'exemple
        : null,
    );
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset de l'état (pour tests ou déconnexion)
  void reset() {
    state = const GamificationState();
  }
}

/// Provider principal pour la gamification
final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  final gamificationService = ref.read(adaptiveGamificationServiceProvider);
  return GamificationNotifier(gamificationService);
});

/// Provider pour le profil gamification de l'utilisateur courant
final userGamificationProfileProvider = Provider<UserGamificationProfile?>((ref) {
  return ref.watch(gamificationProvider).userProfile;
});

/// Provider pour les badges disponibles
final availableBadgesProvider = Provider<List<Badge>>((ref) {
  return ref.watch(gamificationProvider).availableBadges;
});

/// Provider pour le dernier résultat de session
final lastSessionResultProvider = Provider<GamificationResult?>((ref) {
  return ref.watch(gamificationProvider).lastSessionResult;
});

/// Provider pour savoir si on doit montrer la célébration
final showGamificationCelebrationProvider = Provider<bool>((ref) {
  return ref.watch(gamificationProvider).showCelebration;
});

/// Provider pour les encouragements personnalisés
final personalizedEncouragementsProvider = Provider<List<String>>((ref) {
  final notifier = ref.read(gamificationProvider.notifier);
  return notifier.getPersonalizedEncouragements();
});

/// Provider pour l'état de loading
final gamificationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(gamificationProvider).isLoading;
});

/// Provider pour les erreurs de gamification
final gamificationErrorProvider = Provider<String?>((ref) {
  return ref.watch(gamificationProvider).error;
});