// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'virelangue_badge_system.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VirelangueBadgeAdapter extends TypeAdapter<VirelangueBadge> {
  @override
  final int typeId = 52;

  @override
  VirelangueBadge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VirelangueBadge(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as BadgeType,
      category: fields[3] as BadgeCategory,
      name: fields[4] as String,
      description: fields[5] as String,
      iconEmoji: fields[6] as String,
      level: fields[7] as int,
      rarity: fields[8] as BadgeRarity,
      earnedAt: fields[9] as DateTime,
      seriesName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VirelangueBadge obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.iconEmoji)
      ..writeByte(7)
      ..write(obj.level)
      ..writeByte(8)
      ..write(obj.rarity)
      ..writeByte(9)
      ..write(obj.earnedAt)
      ..writeByte(10)
      ..write(obj.seriesName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirelangueBadgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BadgeProgressAdapter extends TypeAdapter<BadgeProgress> {
  @override
  final int typeId = 53;

  @override
  BadgeProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BadgeProgress(
      userId: fields[0] as String,
      totalBadges: fields[1] as int,
      badgesByCategory: (fields[2] as Map).cast<BadgeCategory, int>(),
      badgesByRarity: (fields[3] as Map).cast<BadgeRarity, int>(),
      lastBadgeEarned: fields[4] as DateTime?,
      streak: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BadgeProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.totalBadges)
      ..writeByte(2)
      ..write(obj.badgesByCategory)
      ..writeByte(3)
      ..write(obj.badgesByRarity)
      ..writeByte(4)
      ..write(obj.lastBadgeEarned)
      ..writeByte(5)
      ..write(obj.streak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BadgeSeriesAdapter extends TypeAdapter<BadgeSeries> {
  @override
  final int typeId = 54;

  @override
  BadgeSeries read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BadgeSeries(
      name: fields[0] as String,
      description: fields[1] as String,
      requiredBadges: (fields[2] as List).cast<BadgeType>(),
      seriesRarity: fields[3] as BadgeRarity,
      rewardEmoji: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BadgeSeries obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.requiredBadges)
      ..writeByte(3)
      ..write(obj.seriesRarity)
      ..writeByte(4)
      ..write(obj.rewardEmoji);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeSeriesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SpecialEventBadgeAdapter extends TypeAdapter<SpecialEventBadge> {
  @override
  final int typeId = 55;

  @override
  SpecialEventBadge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpecialEventBadge(
      eventName: fields[0] as String,
      eventDescription: fields[1] as String,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      associatedBadge: fields[4] as BadgeType,
      isActive: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SpecialEventBadge obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.eventName)
      ..writeByte(1)
      ..write(obj.eventDescription)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.associatedBadge)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialEventBadgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
