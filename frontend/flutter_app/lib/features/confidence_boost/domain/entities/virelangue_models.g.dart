// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'virelangue_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VirelangueAdapter extends TypeAdapter<Virelangue> {
  @override
  final int typeId = 31;

  @override
  Virelangue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Virelangue(
      id: fields[0] as String,
      text: fields[1] as String,
      difficulty: fields[2] as VirelangueDifficulty,
      targetScore: fields[3] as double,
      problemSounds: (fields[4] as List).cast<String>(),
      category: fields[5] as String?,
      isCustomGenerated: fields[6] as bool,
      generatedAt: fields[7] as DateTime?,
      theme: fields[8] as String,
      language: fields[9] as String,
      description: fields[10] as String,
      isCustom: fields[11] as bool,
      createdAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Virelangue obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.difficulty)
      ..writeByte(3)
      ..write(obj.targetScore)
      ..writeByte(4)
      ..write(obj.problemSounds)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.isCustomGenerated)
      ..writeByte(7)
      ..write(obj.generatedAt)
      ..writeByte(8)
      ..write(obj.theme)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.isCustom)
      ..writeByte(12)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirelangueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GemCollectionAdapter extends TypeAdapter<GemCollection> {
  @override
  final int typeId = 32;

  @override
  GemCollection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GemCollection(
      userId: fields[0] as String,
      gems: (fields[1] as Map?)?.cast<GemType, int>(),
      totalValue: fields[2] as int,
      lastUpdated: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GemCollection obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.gems)
      ..writeByte(2)
      ..write(obj.totalValue)
      ..writeByte(3)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GemCollectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VirelangueStatsAdapter extends TypeAdapter<VirelangueStats> {
  @override
  final int typeId = 35;

  @override
  VirelangueStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VirelangueStats(
      userId: fields[0] as String,
      totalSessions: fields[1] as int,
      totalVirelangues: fields[2] as int,
      averageScore: fields[3] as double,
      bestScore: fields[4] as double,
      currentStreak: fields[5] as int,
      bestStreak: fields[6] as int,
      difficultyStats: (fields[7] as Map?)?.cast<VirelangueDifficulty, int>(),
      lastSessionDate: fields[8] as DateTime?,
      totalTimeSpentMs: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VirelangueStats obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.totalSessions)
      ..writeByte(2)
      ..write(obj.totalVirelangues)
      ..writeByte(3)
      ..write(obj.averageScore)
      ..writeByte(4)
      ..write(obj.bestScore)
      ..writeByte(5)
      ..write(obj.currentStreak)
      ..writeByte(6)
      ..write(obj.bestStreak)
      ..writeByte(7)
      ..write(obj.difficultyStats)
      ..writeByte(8)
      ..write(obj.lastSessionDate)
      ..writeByte(9)
      ..write(obj.totalTimeSpentMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirelangueStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VirelangueUserProgressAdapter
    extends TypeAdapter<VirelangueUserProgress> {
  @override
  final int typeId = 36;

  @override
  VirelangueUserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VirelangueUserProgress(
      userId: fields[0] as String,
      totalSessions: fields[1] as int,
      bestScore: fields[2] as double,
      averageScore: fields[3] as double,
      currentCombo: fields[4] as int,
      currentStreak: fields[5] as int,
      totalGemValue: fields[6] as int,
      currentLevel: fields[7] as VirelangueDifficulty,
      lastSessionDate: fields[8] as DateTime?,
      recentVirelangueIds: (fields[9] as List?)?.cast<String>(),
      recentDifficulties: (fields[10] as List?)?.cast<VirelangueDifficulty>(),
    );
  }

  @override
  void write(BinaryWriter writer, VirelangueUserProgress obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.totalSessions)
      ..writeByte(2)
      ..write(obj.bestScore)
      ..writeByte(3)
      ..write(obj.averageScore)
      ..writeByte(4)
      ..write(obj.currentCombo)
      ..writeByte(5)
      ..write(obj.currentStreak)
      ..writeByte(6)
      ..write(obj.totalGemValue)
      ..writeByte(7)
      ..write(obj.currentLevel)
      ..writeByte(8)
      ..write(obj.lastSessionDate)
      ..writeByte(9)
      ..write(obj.recentVirelangueIds)
      ..writeByte(10)
      ..write(obj.recentDifficulties);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirelangueUserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GemTypeAdapter extends TypeAdapter<GemType> {
  @override
  final int typeId = 30;

  @override
  GemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GemType.ruby;
      case 1:
        return GemType.emerald;
      case 2:
        return GemType.diamond;
      default:
        return GemType.ruby;
    }
  }

  @override
  void write(BinaryWriter writer, GemType obj) {
    switch (obj) {
      case GemType.ruby:
        writer.writeByte(0);
        break;
      case GemType.emerald:
        writer.writeByte(1);
        break;
      case GemType.diamond:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VirelangueDifficultyAdapter extends TypeAdapter<VirelangueDifficulty> {
  @override
  final int typeId = 33;

  @override
  VirelangueDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VirelangueDifficulty.easy;
      case 1:
        return VirelangueDifficulty.medium;
      case 2:
        return VirelangueDifficulty.hard;
      case 3:
        return VirelangueDifficulty.expert;
      default:
        return VirelangueDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, VirelangueDifficulty obj) {
    switch (obj) {
      case VirelangueDifficulty.easy:
        writer.writeByte(0);
        break;
      case VirelangueDifficulty.medium:
        writer.writeByte(1);
        break;
      case VirelangueDifficulty.hard:
        writer.writeByte(2);
        break;
      case VirelangueDifficulty.expert:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirelangueDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
