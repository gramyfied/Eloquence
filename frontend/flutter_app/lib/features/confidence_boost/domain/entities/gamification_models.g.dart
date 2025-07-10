// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserGamificationProfileAdapter
    extends TypeAdapter<UserGamificationProfile> {
  @override
  final int typeId = 20;

  @override
  UserGamificationProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserGamificationProfile(
      userId: fields[0] as String,
      totalXP: fields[1] as int,
      currentLevel: fields[2] as int,
      xpInCurrentLevel: fields[3] as int,
      xpRequiredForNextLevel: fields[4] as int,
      earnedBadgeIds: (fields[5] as List).cast<String>(),
      currentStreak: fields[6] as int,
      longestStreak: fields[7] as int,
      lastSessionDate: fields[8] as DateTime,
      skillLevels: (fields[9] as Map).cast<String, int>(),
      totalSessions: fields[10] as int,
      perfectSessions: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserGamificationProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.totalXP)
      ..writeByte(2)
      ..write(obj.currentLevel)
      ..writeByte(3)
      ..write(obj.xpInCurrentLevel)
      ..writeByte(4)
      ..write(obj.xpRequiredForNextLevel)
      ..writeByte(5)
      ..write(obj.earnedBadgeIds)
      ..writeByte(6)
      ..write(obj.currentStreak)
      ..writeByte(7)
      ..write(obj.longestStreak)
      ..writeByte(8)
      ..write(obj.lastSessionDate)
      ..writeByte(9)
      ..write(obj.skillLevels)
      ..writeByte(10)
      ..write(obj.totalSessions)
      ..writeByte(11)
      ..write(obj.perfectSessions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGamificationProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BadgeAdapter extends TypeAdapter<Badge> {
  @override
  final int typeId = 21;

  @override
  Badge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Badge(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      iconPath: fields[3] as String,
      rarity: fields[4] as BadgeRarity,
      category: fields[5] as BadgeCategory,
      earnedDate: fields[6] as DateTime?,
      xpReward: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Badge obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconPath)
      ..writeByte(4)
      ..write(obj.rarity)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.earnedDate)
      ..writeByte(7)
      ..write(obj.xpReward);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BadgeRarityAdapter extends TypeAdapter<BadgeRarity> {
  @override
  final int typeId = 22;

  @override
  BadgeRarity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BadgeRarity.common;
      case 1:
        return BadgeRarity.rare;
      case 2:
        return BadgeRarity.epic;
      case 3:
        return BadgeRarity.legendary;
      default:
        return BadgeRarity.common;
    }
  }

  @override
  void write(BinaryWriter writer, BadgeRarity obj) {
    switch (obj) {
      case BadgeRarity.common:
        writer.writeByte(0);
        break;
      case BadgeRarity.rare:
        writer.writeByte(1);
        break;
      case BadgeRarity.epic:
        writer.writeByte(2);
        break;
      case BadgeRarity.legendary:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeRarityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BadgeCategoryAdapter extends TypeAdapter<BadgeCategory> {
  @override
  final int typeId = 23;

  @override
  BadgeCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BadgeCategory.performance;
      case 1:
        return BadgeCategory.streak;
      case 2:
        return BadgeCategory.social;
      case 3:
        return BadgeCategory.special;
      case 4:
        return BadgeCategory.milestone;
      default:
        return BadgeCategory.performance;
    }
  }

  @override
  void write(BinaryWriter writer, BadgeCategory obj) {
    switch (obj) {
      case BadgeCategory.performance:
        writer.writeByte(0);
        break;
      case BadgeCategory.streak:
        writer.writeByte(1);
        break;
      case BadgeCategory.social:
        writer.writeByte(2);
        break;
      case BadgeCategory.special:
        writer.writeByte(3);
        break;
      case BadgeCategory.milestone:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
