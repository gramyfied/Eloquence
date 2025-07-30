// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'virelangue_reward_system.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PityTimerStateAdapter extends TypeAdapter<PityTimerState> {
  @override
  final int typeId = 33;

  @override
  PityTimerState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PityTimerState(
      emeraldTimer: fields[0] as int,
      diamondTimer: fields[1] as int,
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PityTimerState obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.emeraldTimer)
      ..writeByte(1)
      ..write(obj.diamondTimer)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PityTimerStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RewardHistoryAdapter extends TypeAdapter<RewardHistory> {
  @override
  final int typeId = 34;

  @override
  RewardHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardHistory(
      userId: fields[0] as String,
      timestamp: fields[1] as DateTime,
      rewards: (fields[2] as List).cast<GemReward>(),
      activeEvents: (fields[3] as List).cast<SpecialEventType>(),
      totalValue: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RewardHistory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.rewards)
      ..writeByte(3)
      ..write(obj.activeEvents)
      ..writeByte(4)
      ..write(obj.totalValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
