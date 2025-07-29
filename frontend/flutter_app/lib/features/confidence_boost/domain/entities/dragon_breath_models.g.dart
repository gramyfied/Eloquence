// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dragon_breath_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreathingExerciseAdapter extends TypeAdapter<BreathingExercise> {
  @override
  final int typeId = 42;

  @override
  BreathingExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingExercise(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      inspirationDuration: fields[3] as int,
      expirationDuration: fields[4] as int,
      retentionDuration: fields[5] as int,
      pauseDuration: fields[6] as int,
      totalCycles: fields[7] as int,
      requiredLevel: fields[8] as DragonLevel,
      benefits: fields[9] as String,
      isCustom: fields[10] as bool,
      createdAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BreathingExercise obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.inspirationDuration)
      ..writeByte(4)
      ..write(obj.expirationDuration)
      ..writeByte(5)
      ..write(obj.retentionDuration)
      ..writeByte(6)
      ..write(obj.pauseDuration)
      ..writeByte(7)
      ..write(obj.totalCycles)
      ..writeByte(8)
      ..write(obj.requiredLevel)
      ..writeByte(9)
      ..write(obj.benefits)
      ..writeByte(10)
      ..write(obj.isCustom)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BreathingMetricsAdapter extends TypeAdapter<BreathingMetrics> {
  @override
  final int typeId = 43;

  @override
  BreathingMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingMetrics(
      averageBreathDuration: fields[0] as double,
      consistency: fields[1] as double,
      controlScore: fields[2] as double,
      completedCycles: fields[3] as int,
      totalCycles: fields[4] as int,
      actualDuration: fields[5] as Duration,
      expectedDuration: fields[6] as Duration,
      qualityScore: fields[7] as double,
      cycleDeviations: (fields[8] as List).cast<double>(),
      timestamp: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BreathingMetrics obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.averageBreathDuration)
      ..writeByte(1)
      ..write(obj.consistency)
      ..writeByte(2)
      ..write(obj.controlScore)
      ..writeByte(3)
      ..write(obj.completedCycles)
      ..writeByte(4)
      ..write(obj.totalCycles)
      ..writeByte(5)
      ..write(obj.actualDuration)
      ..writeByte(6)
      ..write(obj.expectedDuration)
      ..writeByte(7)
      ..write(obj.qualityScore)
      ..writeByte(8)
      ..write(obj.cycleDeviations)
      ..writeByte(9)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DragonAchievementAdapter extends TypeAdapter<DragonAchievement> {
  @override
  final int typeId = 44;

  @override
  DragonAchievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DragonAchievement(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      emoji: fields[3] as String,
      requiredLevel: fields[4] as DragonLevel,
      requiredSessions: fields[5] as int,
      requiredQuality: fields[6] as double,
      xpReward: fields[7] as int,
      isUnlocked: fields[8] as bool,
      unlockedAt: fields[9] as DateTime?,
      category: fields[10] as String,
      currentValue: fields[11] as int,
      targetValue: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, DragonAchievement obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.requiredLevel)
      ..writeByte(5)
      ..write(obj.requiredSessions)
      ..writeByte(6)
      ..write(obj.requiredQuality)
      ..writeByte(7)
      ..write(obj.xpReward)
      ..writeByte(8)
      ..write(obj.isUnlocked)
      ..writeByte(9)
      ..write(obj.unlockedAt)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.currentValue)
      ..writeByte(12)
      ..write(obj.targetValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragonAchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BreathingSessionAdapter extends TypeAdapter<BreathingSession> {
  @override
  final int typeId = 45;

  @override
  BreathingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingSession(
      id: fields[0] as String,
      userId: fields[1] as String,
      exerciseId: fields[2] as String,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      metrics: fields[5] as BreathingMetrics?,
      unlockedAchievements: (fields[6] as List).cast<DragonAchievement>(),
      xpGained: fields[7] as int,
      isCompleted: fields[8] as bool,
      motivationalMessage: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BreathingSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.metrics)
      ..writeByte(6)
      ..write(obj.unlockedAchievements)
      ..writeByte(7)
      ..write(obj.xpGained)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.motivationalMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DragonProgressAdapter extends TypeAdapter<DragonProgress> {
  @override
  final int typeId = 46;

  @override
  DragonProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DragonProgress(
      userId: fields[0] as String,
      currentLevel: fields[1] as DragonLevel,
      totalSessions: fields[2] as int,
      totalXP: fields[3] as int,
      currentStreak: fields[4] as int,
      longestStreak: fields[5] as int,
      averageQuality: fields[6] as double,
      bestQuality: fields[7] as double,
      totalPracticeTime: fields[8] as Duration?,
      lastSessionDate: fields[9] as DateTime?,
      achievements: (fields[10] as List).cast<DragonAchievement>(),
      statistics: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DragonProgress obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.currentLevel)
      ..writeByte(2)
      ..write(obj.totalSessions)
      ..writeByte(3)
      ..write(obj.totalXP)
      ..writeByte(4)
      ..write(obj.currentStreak)
      ..writeByte(5)
      ..write(obj.longestStreak)
      ..writeByte(6)
      ..write(obj.averageQuality)
      ..writeByte(7)
      ..write(obj.bestQuality)
      ..writeByte(8)
      ..write(obj.totalPracticeTime)
      ..writeByte(9)
      ..write(obj.lastSessionDate)
      ..writeByte(10)
      ..write(obj.achievements)
      ..writeByte(11)
      ..write(obj.statistics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragonProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DragonLevelAdapter extends TypeAdapter<DragonLevel> {
  @override
  final int typeId = 40;

  @override
  DragonLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DragonLevel.apprenti;
      case 1:
        return DragonLevel.maitre;
      case 2:
        return DragonLevel.sage;
      case 3:
        return DragonLevel.legende;
      default:
        return DragonLevel.apprenti;
    }
  }

  @override
  void write(BinaryWriter writer, DragonLevel obj) {
    switch (obj) {
      case DragonLevel.apprenti:
        writer.writeByte(0);
        break;
      case DragonLevel.maitre:
        writer.writeByte(1);
        break;
      case DragonLevel.sage:
        writer.writeByte(2);
        break;
      case DragonLevel.legende:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragonLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BreathingPhaseAdapter extends TypeAdapter<BreathingPhase> {
  @override
  final int typeId = 41;

  @override
  BreathingPhase read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BreathingPhase.preparation;
      case 1:
        return BreathingPhase.inspiration;
      case 2:
        return BreathingPhase.retention;
      case 3:
        return BreathingPhase.expiration;
      case 4:
        return BreathingPhase.pause;
      case 5:
        return BreathingPhase.completed;
      default:
        return BreathingPhase.preparation;
    }
  }

  @override
  void write(BinaryWriter writer, BreathingPhase obj) {
    switch (obj) {
      case BreathingPhase.preparation:
        writer.writeByte(0);
        break;
      case BreathingPhase.inspiration:
        writer.writeByte(1);
        break;
      case BreathingPhase.retention:
        writer.writeByte(2);
        break;
      case BreathingPhase.expiration:
        writer.writeByte(3);
        break;
      case BreathingPhase.pause:
        writer.writeByte(4);
        break;
      case BreathingPhase.completed:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingPhaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
