import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/confidence_models.dart';
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
    // L'adapter pour ConfidenceScenario (21) est supprimé car l'entité n'est plus stockée dans Hive.
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

      // STORYTELLING - Badges spécifiques au Générateur d'Histoires
      Badge(id: 'first_story', name: '📚 Premier Conte', description: 'Raconter votre première histoire complète.', iconPath: 'assets/badges/storytelling/first_story.png', rarity: BadgeRarity.common, category: BadgeCategory.storytelling, xpReward: 30),
      Badge(id: 'story_weaver', name: '🧙‍♂️ Tisseur d\'Histoires', description: 'Terminer 10 histoires narratives.', iconPath: 'assets/badges/storytelling/story_weaver.png', rarity: BadgeRarity.rare, category: BadgeCategory.storytelling, xpReward: 100),
      Badge(id: 'narrative_master', name: '👑 Maître Narrateur', description: 'Terminer 50 histoires avec excellence.', iconPath: 'assets/badges/storytelling/narrative_master.png', rarity: BadgeRarity.epic, category: BadgeCategory.storytelling, xpReward: 300),
      Badge(id: 'plot_twist_genius', name: '🌪️ Génie du Rebondissement', description: 'Intégrer 20 rebondissements IA avec brio.', iconPath: 'assets/badges/storytelling/plot_twist_genius.png', rarity: BadgeRarity.rare, category: BadgeCategory.storytelling, xpReward: 150),
      Badge(id: 'speed_storyteller', name: '⚡ Conteur Express', description: 'Raconter une histoire en moins de 3 minutes.', iconPath: 'assets/badges/storytelling/speed_storyteller.png', rarity: BadgeRarity.common, category: BadgeCategory.storytelling, xpReward: 50),
      Badge(id: 'epic_narrator', name: '📖 Narrateur Épique', description: 'Raconter une histoire de plus de 10 minutes.', iconPath: 'assets/badges/storytelling/epic_narrator.png', rarity: BadgeRarity.rare, category: BadgeCategory.storytelling, xpReward: 120),
      Badge(id: 'genre_explorer', name: '🎭 Explorateur de Genres', description: 'Raconter des histoires dans 5 genres différents.', iconPath: 'assets/badges/storytelling/genre_explorer.png', rarity: BadgeRarity.rare, category: BadgeCategory.storytelling, xpReward: 180),
      Badge(id: 'character_creator', name: '🎨 Créateur de Personnages', description: 'Développer 25 personnages uniques.', iconPath: 'assets/badges/storytelling/character_creator.png', rarity: BadgeRarity.epic, category: BadgeCategory.storytelling, xpReward: 200),
      Badge(id: 'voice_magician', name: '🎤 Magicien de la Voix', description: 'Score de modulation vocale supérieur à 90%.', iconPath: 'assets/badges/storytelling/voice_magician.png', rarity: BadgeRarity.epic, category: BadgeCategory.storytelling, xpReward: 250),
      Badge(id: 'emotion_master', name: '💫 Maître des Émotions', description: 'Score émotionnel moyen supérieur à 85%.', iconPath: 'assets/badges/storytelling/emotion_master.png', rarity: BadgeRarity.rare, category: BadgeCategory.storytelling, xpReward: 160),
      Badge(id: 'story_streak_7', name: '🔥 Semaine Narrative', description: 'Raconter des histoires 7 jours consécutifs.', iconPath: 'assets/badges/storytelling/story_streak_7.png', rarity: BadgeRarity.rare, category: BadgeCategory.storytelling, xpReward: 140),
      Badge(id: 'collaborative_genius', name: '🤝 Génie Collaboratif', description: 'Accepter et développer 15 suggestions IA.', iconPath: 'assets/badges/storytelling/collaborative_genius.png', rarity: BadgeRarity.epic, category: BadgeCategory.storytelling, xpReward: 220),
      Badge(id: 'legendary_storyteller', name: '🌟 Conteur Légendaire', description: 'Atteindre 100 histoires parfaites (95%+).', iconPath: 'assets/badges/storytelling/legendary_storyteller.png', rarity: BadgeRarity.legendary, category: BadgeCategory.storytelling, xpReward: 500),
      
      // TRIBUNAL - Badges spécifiques au Tribunal des Idées Impossibles
      Badge(id: 'first_plea', name: '⚖️ Premier Plaidoyer', description: 'Terminer votre première session au Tribunal des Idées Impossibles.', iconPath: 'assets/badges/tribunal/first_plea.png', rarity: BadgeRarity.common, category: BadgeCategory.special, xpReward: 50),
      Badge(id: 'debate_champion', name: '🏆 Champion du Débat', description: 'Remporter 10 débats avec excellence (90%+).', iconPath: 'assets/badges/tribunal/debate_champion.png', rarity: BadgeRarity.rare, category: BadgeCategory.performance, xpReward: 150),
      Badge(id: 'rhetorical_master', name: '🎭 Maître de la Rhétorique', description: 'Score de persuasion supérieur à 95% dans 5 débats.', iconPath: 'assets/badges/tribunal/rhetorical_master.png', rarity: BadgeRarity.epic, category: BadgeCategory.performance, xpReward: 300),
      Badge(id: 'impossible_defender', name: '🛡️ Défenseur de l\'Impossible', description: 'Défendre avec succès 20 idées impossibles.', iconPath: 'assets/badges/tribunal/impossible_defender.png', rarity: BadgeRarity.rare, category: BadgeCategory.special, xpReward: 200),
      Badge(id: 'judge_interrogator', name: '🔍 Interrogateur du Juge', description: 'Répondre brillamment à 50 questions du Juge Magistrat.', iconPath: 'assets/badges/tribunal/judge_interrogator.png', rarity: BadgeRarity.epic, category: BadgeCategory.special, xpReward: 250),
      Badge(id: 'creative_advocate', name: '💡 Avocat Créatif', description: 'Utiliser 15 sujets générés par IA avec succès.', iconPath: 'assets/badges/tribunal/creative_advocate.png', rarity: BadgeRarity.rare, category: BadgeCategory.special, xpReward: 120),
      Badge(id: 'lightning_debater', name: '⚡ Débatteur Éclair', description: 'Terminer un débat en moins de 3 minutes.', iconPath: 'assets/badges/tribunal/lightning_debater.png', rarity: BadgeRarity.common, category: BadgeCategory.performance, xpReward: 75),
      Badge(id: 'marathon_pleader', name: '🏃 Plaideur Marathon', description: 'Maintenir un débat pendant plus de 15 minutes.', iconPath: 'assets/badges/tribunal/marathon_pleader.png', rarity: BadgeRarity.rare, category: BadgeCategory.performance, xpReward: 180),
      Badge(id: 'tribunal_streak_5', name: '🔥 Série Juridique', description: 'Participer au Tribunal 5 jours consécutifs.', iconPath: 'assets/badges/tribunal/tribunal_streak_5.png', rarity: BadgeRarity.rare, category: BadgeCategory.streak, xpReward: 140),
      Badge(id: 'absurd_specialist', name: '🤪 Spécialiste de l\'Absurde', description: 'Argumenter sur 30 sujets différents avec brio.', iconPath: 'assets/badges/tribunal/absurd_specialist.png', rarity: BadgeRarity.epic, category: BadgeCategory.special, xpReward: 280),
      Badge(id: 'court_legend', name: '👑 Légende du Tribunal', description: 'Atteindre 100 sessions parfaites au Tribunal.', iconPath: 'assets/badges/tribunal/court_legend.png', rarity: BadgeRarity.legendary, category: BadgeCategory.milestone, xpReward: 500),
      Badge(id: 'perfect_argument', name: '💎 Argument Parfait', description: 'Obtenir un score de 100% dans un débat.', iconPath: 'assets/badges/tribunal/perfect_argument.png', rarity: BadgeRarity.epic, category: BadgeCategory.performance, xpReward: 200),
    ];
  }
}