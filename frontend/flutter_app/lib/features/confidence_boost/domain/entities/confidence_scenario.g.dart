// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confidence_scenario.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfidenceScenarioAdapter extends TypeAdapter<ConfidenceScenario> {
  @override
  final int typeId = 20;

  @override
  ConfidenceScenario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConfidenceScenario(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      prompt: fields[3] as String,
      type: fields[4] as ConfidenceScenarioType,
      durationSeconds: fields[5] as int,
      tips: (fields[6] as List).cast<String>(),
      keywords: (fields[7] as List).cast<String>(),
      difficulty: fields[8] as String,
      icon: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ConfidenceScenario obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.prompt)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.durationSeconds)
      ..writeByte(6)
      ..write(obj.tips)
      ..writeByte(7)
      ..write(obj.keywords)
      ..writeByte(8)
      ..write(obj.difficulty)
      ..writeByte(9)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfidenceScenarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
