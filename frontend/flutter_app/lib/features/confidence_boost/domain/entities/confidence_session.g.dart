// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confidence_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionRecordAdapter extends TypeAdapter<SessionRecord> {
  @override
  final int typeId = 15;

  @override
  SessionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionRecord(
      userId: fields[0] as String,
      analysis: fields[1] as ConfidenceAnalysis,
      scenario: fields[2] as ConfidenceScenario,
      textSupport: fields[3] as TextSupport,
      earnedXP: fields[4] as int,
      newBadges: (fields[5] as List).cast<Badge>(),
      timestamp: fields[6] as DateTime,
      sessionDuration: fields[7] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, SessionRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.analysis)
      ..writeByte(2)
      ..write(obj.scenario)
      ..writeByte(3)
      ..write(obj.textSupport)
      ..writeByte(4)
      ..write(obj.earnedXP)
      ..writeByte(5)
      ..write(obj.newBadges)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.sessionDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
