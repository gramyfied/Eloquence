import 'package:equatable/equatable.dart';

enum RewardLevel { micro, meso, macro }

enum ChestType { standard, superior, legendary, mystery }

enum ContentRarity { common, uncommon, rare, epic, legendary }

enum RewardType {
  points,
  visualEffect,
  badge,
  skillUnlock,
  treasureChest,
}

class Reward extends Equatable {
  final RewardType type;
  final RewardLevel level;
  final double baseMagnitude;

  const Reward({
    required this.type,
    required this.level,
    required this.baseMagnitude,
  });

  @override
  List<Object?> get props => [type, level, baseMagnitude];
}

class PointsReward extends Reward {
  final int points;
  final String pointsType;

  const PointsReward({
    required this.points,
    required this.pointsType,
    required RewardLevel level,
    required double baseMagnitude,
  }) : super(type: RewardType.points, level: level, baseMagnitude: baseMagnitude);

  @override
  List<Object?> get props => [...super.props, points, pointsType];
}

class VisualEffectReward extends Reward {
  final String effectType;
  final double duration;
  final double intensity;

  const VisualEffectReward({
    required this.effectType,
    required this.duration,
    required this.intensity,
    required RewardLevel level,
    required double baseMagnitude,
  }) : super(type: RewardType.visualEffect, level: level, baseMagnitude: baseMagnitude);

  @override
  List<Object?> get props => [...super.props, effectType, duration, intensity];
}

class BadgeReward extends Reward {
  final String badgeId;
  final String badgeName;
  final String badgeDescription;
  final String imageUrl;

  const BadgeReward({
    required this.badgeId,
    required this.badgeName,
    required this.badgeDescription,
    required this.imageUrl,
    required RewardLevel level,
    required double baseMagnitude,
  }) : super(type: RewardType.badge, level: level, baseMagnitude: baseMagnitude);

  @override
  List<Object?> get props => [...super.props, badgeId, badgeName, badgeDescription, imageUrl];
}

class SkillUnlockReward extends Reward {
  final String skillId;
  final String skillName;
  final String skillDescription;

  const SkillUnlockReward({
    required this.skillId,
    required this.skillName,
    required this.skillDescription,
    required RewardLevel level,
    required double baseMagnitude,
  }) : super(type: RewardType.skillUnlock, level: level, baseMagnitude: baseMagnitude);

  @override
  List<Object?> get props => [...super.props, skillId, skillName, skillDescription];
}

class RewardContent extends Equatable {
  final String contentType;
  final dynamic value; // Peut être String (theme, skill_unlock), int (points), etc.
  final ContentRarity rarity;

  const RewardContent({
    required this.contentType,
    this.value,
    required this.rarity,
  });

  @override
  List<Object?> get props => [contentType, value, rarity];
}

class ChestOpeningExperience extends Equatable {
  final String openingAnimation;
  final List<String> soundEffects;
  final List<String> visualEffects;

  const ChestOpeningExperience({
    required this.openingAnimation,
    required this.soundEffects,
    required this.visualEffects,
  });

  @override
  List<Object?> get props => [openingAnimation, soundEffects, visualEffects];
}

class TreasureChestReward extends Reward {
  final ChestType chestType;
  final List<RewardContent> contents;
  final ChestOpeningExperience openingExperience;

  const TreasureChestReward({
    required this.chestType,
    required this.contents,
    required this.openingExperience,
    required RewardLevel level,
    required double baseMagnitude,
  }) : super(type: RewardType.treasureChest, level: level, baseMagnitude: baseMagnitude);

  @override
  List<Object?> get props => [...super.props, chestType, contents, openingExperience];
}