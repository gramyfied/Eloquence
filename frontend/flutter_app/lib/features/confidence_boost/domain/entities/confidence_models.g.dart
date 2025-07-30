// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confidence_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TextSupportAdapter extends TypeAdapter<TextSupport> {
  @override
  final int typeId = 11;

  @override
  TextSupport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TextSupport(
      type: fields[0] as SupportType,
      content: fields[1] as String,
      suggestedWords: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TextSupport obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.suggestedWords);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSupportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConfidenceAnalysisAdapter extends TypeAdapter<ConfidenceAnalysis> {
  @override
  final int typeId = 13;

  @override
  ConfidenceAnalysis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConfidenceAnalysis(
      overallScore: fields[0] as double,
      confidenceScore: fields[1] as double,
      fluencyScore: fields[2] as double,
      clarityScore: fields[3] as double,
      energyScore: fields[4] as double,
      feedback: fields[5] as String,
      wordCount: fields[6] as int,
      speakingRate: fields[7] as double,
      keywordsUsed: (fields[8] as List).cast<String>(),
      transcription: fields[9] as String,
      strengths: (fields[10] as List).cast<String>(),
      improvements: (fields[11] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ConfidenceAnalysis obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.overallScore)
      ..writeByte(1)
      ..write(obj.confidenceScore)
      ..writeByte(2)
      ..write(obj.fluencyScore)
      ..writeByte(3)
      ..write(obj.clarityScore)
      ..writeByte(4)
      ..write(obj.energyScore)
      ..writeByte(5)
      ..write(obj.feedback)
      ..writeByte(6)
      ..write(obj.wordCount)
      ..writeByte(7)
      ..write(obj.speakingRate)
      ..writeByte(8)
      ..write(obj.keywordsUsed)
      ..writeByte(9)
      ..write(obj.transcription)
      ..writeByte(10)
      ..write(obj.strengths)
      ..writeByte(11)
      ..write(obj.improvements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfidenceAnalysisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConfidenceMetricsAdapter extends TypeAdapter<ConfidenceMetrics> {
  @override
  final int typeId = 14;

  @override
  ConfidenceMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConfidenceMetrics(
      confidenceLevel: fields[0] as double,
      voiceClarity: fields[1] as double,
      speakingPace: fields[2] as double,
      energyLevel: fields[3] as double,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ConfidenceMetrics obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.confidenceLevel)
      ..writeByte(1)
      ..write(obj.voiceClarity)
      ..writeByte(2)
      ..write(obj.speakingPace)
      ..writeByte(3)
      ..write(obj.energyLevel)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfidenceMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationMessageAdapter extends TypeAdapter<ConversationMessage> {
  @override
  final int typeId = 15;

  @override
  ConversationMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationMessage(
      id: fields[0] as String,
      content: fields[1] as String,
      isUser: fields[2] as bool,
      timestamp: fields[3] as DateTime,
      metrics: fields[4] as ConfidenceMetrics?,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationMessage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.isUser)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.metrics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnalysisResultAdapter extends TypeAdapter<AnalysisResult> {
  @override
  final int typeId = 16;

  @override
  AnalysisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalysisResult(
      confidenceScore: fields[0] as double,
      clarityScore: fields[1] as double,
      fluencyScore: fields[2] as double,
      transcription: fields[3] as String,
      keyInsights: (fields[4] as List).cast<String>(),
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AnalysisResult obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.confidenceScore)
      ..writeByte(1)
      ..write(obj.clarityScore)
      ..writeByte(2)
      ..write(obj.fluencyScore)
      ..writeByte(3)
      ..write(obj.transcription)
      ..writeByte(4)
      ..write(obj.keyInsights)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SupportTypeAdapter extends TypeAdapter<SupportType> {
  @override
  final int typeId = 10;

  @override
  SupportType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SupportType.fullText;
      case 1:
        return SupportType.fillInBlanks;
      case 2:
        return SupportType.guidedStructure;
      case 3:
        return SupportType.keywordChallenge;
      case 4:
        return SupportType.freeImprovisation;
      default:
        return SupportType.fullText;
    }
  }

  @override
  void write(BinaryWriter writer, SupportType obj) {
    switch (obj) {
      case SupportType.fullText:
        writer.writeByte(0);
        break;
      case SupportType.fillInBlanks:
        writer.writeByte(1);
        break;
      case SupportType.guidedStructure:
        writer.writeByte(2);
        break;
      case SupportType.keywordChallenge:
        writer.writeByte(3);
        break;
      case SupportType.freeImprovisation:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConfidenceScenarioTypeAdapter
    extends TypeAdapter<ConfidenceScenarioType> {
  @override
  final int typeId = 12;

  @override
  ConfidenceScenarioType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConfidenceScenarioType.presentation;
      case 1:
        return ConfidenceScenarioType.meeting;
      case 2:
        return ConfidenceScenarioType.interview;
      case 3:
        return ConfidenceScenarioType.networking;
      case 4:
        return ConfidenceScenarioType.pitch;
      default:
        return ConfidenceScenarioType.presentation;
    }
  }

  @override
  void write(BinaryWriter writer, ConfidenceScenarioType obj) {
    switch (obj) {
      case ConfidenceScenarioType.presentation:
        writer.writeByte(0);
        break;
      case ConfidenceScenarioType.meeting:
        writer.writeByte(1);
        break;
      case ConfidenceScenarioType.interview:
        writer.writeByte(2);
        break;
      case ConfidenceScenarioType.networking:
        writer.writeByte(3);
        break;
      case ConfidenceScenarioType.pitch:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfidenceScenarioTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
