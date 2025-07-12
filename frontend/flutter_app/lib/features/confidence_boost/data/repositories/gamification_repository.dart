import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/confidence_models.dart';
import '../../domain/entities/confidence_scenario.dart';
import '../../domain/entities/confidence_session.dart';
import '../../domain/entities/gamification_models.dart';

abstract class GamificationRepository {
  Future<void> initialize();
  Future<UserGamificationProfile> getUserProfile(String userId);
  Future<void> updateUserProfile(UserGamificationProfile profile);
  Future<List<Badge>> getAllBadges();
  Future<void> awardBadge(String userId, String badgeId);
  Future<void> saveSession(SessionRecord session);
  Future<List<SessionRecord>> getUserSessionHistory(String userId, {int limit = 50});
}

class HiveGamificationRepository implements GamificationRepository {
  late Box<UserGamificationProfile> _profileBox;
  late Box<Badge> _badgeBox;
  late Box<SessionRecord> _sessionBox;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Enregistrer les adaptateurs avec vérification pour éviter les doublons
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(UserGamificationProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(ConfidenceScenarioAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(BadgeAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(BadgeRarityAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(BadgeCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(25)) {
      Hive.registerAdapter(SessionRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(26)) {
      Hive.registerAdapter(ConfidenceAnalysisAdapter());
    }
    if (!Hive.isAdapterRegistered(27)) {
      Hive.registerAdapter(TextSupportAdapter());
    }
    if (!Hive.isAdapterRegistered(28)) {
      Hive.registerAdapter(SupportTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(29)) {
      Hive.registerAdapter(ConfidenceScenarioTypeAdapter());
    }


    // Ouvrir les boxes
    _profileBox = await Hive.openBox<UserGamificationProfile>('user_profiles');
    _badgeBox = await Hive.openBox<Badge>('badges');
    _sessionBox = await Hive.openBox<SessionRecord>('sessions');

    // Créer les badges par défaut
    await _initializeDefaultBadges();
  }

  Future<void> _initializeDefaultBadges() async {
    if (_badgeBox.isEmpty) {
      final defaultBadges = _createAllBadges();
      for (final badge in defaultBadges) {
        await _badgeBox.put(badge.id, badge);
      }
    }
  }

  @override
  Future<UserGamificationProfile> getUserProfile(String userId) async {
    // Retourne un profil par défaut si aucun n'existe
    return _profileBox.get(userId) ?? UserGamificationProfile(userId: userId, lastSessionDate: DateTime.now());
  }

  @override
  Future<void> updateUserProfile(UserGamificationProfile profile) async {
    await _profileBox.put(profile.userId, profile);
  }

  @override
  Future<List<Badge>> getAllBadges() async {
    return _badgeBox.values.toList();
  }

  @override
  Future<void> awardBadge(String userId, String badgeId) async {
    final profile = await getUserProfile(userId);
    if (!profile.earnedBadgeIds.contains(badgeId)) {
      final newBadgeIds = List<String>.from(profile.earnedBadgeIds)..add(badgeId);
      final updatedProfile = profile.copyWith(earnedBadgeIds: newBadgeIds);
      await updateUserProfile(updatedProfile);
    }
  }

  @override
  Future<void> saveSession(SessionRecord session) async {
    await _sessionBox.add(session);
  }

  @override
  Future<List<SessionRecord>> getUserSessionHistory(String userId, {int limit = 50}) async {
    var allSessions = _sessionBox.values.toList().cast<SessionRecord>();
    var userSessions = allSessions.where((s) => s.userId == userId).toList();
    userSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return userSessions.take(limit).toList();
  }

  List<Badge> _createAllBadges() {
    return [
      // PERFORMANCE
      Badge(id: 'first_excellent', name: 'Premier Excellence', description: 'Obtenir un score de 85% ou plus.', iconPath: 'assets/badges/performance/first_excellent.png', rarity: BadgeRarity.common, category: BadgeCategory.performance, xpReward: 50),
      Badge(id: 'perfectionist', name: 'Perfectionniste', description: 'Atteindre un score parfait de 100%.', iconPath: 'assets/badges/performance/perfectionist.png', rarity: BadgeRarity.epic, category: BadgeCategory.performance, xpReward: 200),
      Badge(id: 'clarity_master', name: 'Maître de la Clarté', description: 'Score de clarté supérieur à 90%.', iconPath: 'assets/badges/performance/clarity_master.png', rarity: BadgeRarity.rare, category: BadgeCategory.performance, xpReward: 75),
      Badge(id: 'energy_dynamo', name: 'Dynamo d\'Énergie', description: 'Score d\'énergie supérieur à 90%.', iconPath: 'assets/badges/performance/energy_dynamo.png', rarity: BadgeRarity.rare, category: BadgeCategory.performance, xpReward: 75),
      Badge(id: 'fluent_speaker', name: 'Orateur Fluide', description: 'Score de fluidité supérieur à 90%.', iconPath: 'assets/badges/performance/fluent_speaker.png', rarity: BadgeRarity.rare, category: BadgeCategory.performance, xpReward: 75),

      // STREAK
      Badge(id: 'streak_3', name: 'Série Chaude', description: '3 jours de pratique consécutifs.', iconPath: 'assets/badges/streak/streak_3.png', rarity: BadgeRarity.common, category: BadgeCategory.streak, xpReward: 30),
      Badge(id: 'streak_7', name: 'Semaine Parfaite', description: '7 jours de pratique consécutifs.', iconPath: 'assets/badges/streak/streak_7.png', rarity: BadgeRarity.rare, category: BadgeCategory.streak, xpReward: 100),
      Badge(id: 'streak_14', name: 'Quinzaine Implacable', description: '14 jours de pratique consécutifs.', iconPath: 'assets/badges/streak/streak_14.png', rarity: BadgeRarity.epic, category: BadgeCategory.streak, xpReward: 250),
      Badge(id: 'streak_30', name: 'Mois Légendaire', description: '30 jours de pratique consécutifs.', iconPath: 'assets/badges/streak/streak_30.png', rarity: BadgeRarity.legendary, category: BadgeCategory.streak, xpReward: 500),

      // MILESTONE
      Badge(id: 'first_session', name: 'Le Premier Pas', description: 'Terminer votre première session.', iconPath: 'assets/badges/milestone/first_session.png', rarity: BadgeRarity.common, category: BadgeCategory.milestone, xpReward: 20),
      Badge(id: 'centurion', name: 'Centurion', description: 'Terminer 100 sessions.', iconPath: 'assets/badges/milestone/centurion.png', rarity: BadgeRarity.epic, category: BadgeCategory.milestone, xpReward: 300),
      Badge(id: 'novice', name: 'Novice', description: 'Atteindre le niveau 5.', iconPath: 'assets/badges/milestone/novice.png', rarity: BadgeRarity.common, category: BadgeCategory.milestone, xpReward: 50),
      Badge(id: 'adept', name: 'Adepte', description: 'Atteindre le niveau 10.', iconPath: 'assets/badges/milestone/adept.png', rarity: BadgeRarity.rare, category: BadgeCategory.milestone, xpReward: 100),
      Badge(id: 'expert', name: 'Expert', description: 'Atteindre le niveau 25.', iconPath: 'assets/badges/milestone/expert.png', rarity: BadgeRarity.epic, category: BadgeCategory.milestone, xpReward: 250),
      Badge(id: 'master', name: 'Maître', description: 'Atteindre le niveau 50.', iconPath: 'assets/badges/milestone/master.png', rarity: BadgeRarity.legendary, category: BadgeCategory.milestone, xpReward: 500),
      Badge(id: 'xp_1000', name: 'Apprenti', description: 'Gagner 1000 XP.', iconPath: 'assets/badges/milestone/xp_1000.png', rarity: BadgeRarity.common, category: BadgeCategory.milestone, xpReward: 50),
      Badge(id: 'xp_10000', name: 'Légende', description: 'Gagner 10000 XP.', iconPath: 'assets/badges/milestone/xp_10000.png', rarity: BadgeRarity.epic, category: BadgeCategory.milestone, xpReward: 400),

      // SPECIAL
      Badge(id: 'night_owl', name: 'Noctambule', description: 'Faire une session après 22h.', iconPath: 'assets/badges/special/night_owl.png', rarity: BadgeRarity.common, category: BadgeCategory.special, xpReward: 40),
      Badge(id: 'early_bird', name: 'Lève-tôt', description: 'Faire une session avant 7h.', iconPath: 'assets/badges/special/early_bird.png', rarity: BadgeRarity.common, category: BadgeCategory.special, xpReward: 40),
      Badge(id: 'weekend_warrior', name: 'Guerrier du Weekend', description: 'Faire une session pendant le weekend.', iconPath: 'assets/badges/special/weekend_warrior.png', rarity: BadgeRarity.common, category: BadgeCategory.special, xpReward: 30),
      Badge(id: 'improviser', name: 'Improvisateur Né', description: 'Terminer 10 sessions d\'improvisation.', iconPath: 'assets/badges/special/improviser.png', rarity: BadgeRarity.rare, category: BadgeCategory.special, xpReward: 150),
    ];
  }
}