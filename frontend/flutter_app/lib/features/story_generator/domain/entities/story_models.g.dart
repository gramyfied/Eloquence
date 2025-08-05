// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoryElementAdapter extends TypeAdapter<StoryElement> {
  @override
  final int typeId = 52;

  @override
  StoryElement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoryElement(
      id: fields[0] as String,
      type: fields[1] as StoryElementType,
      name: fields[2] as String,
      emoji: fields[3] as String,
      description: fields[4] as String,
      difficulty: fields[5] as VirelangueDifficulty,
      keywords: (fields[6] as List).cast<String>(),
      preferredGenre: fields[7] as StoryGenre?,
      isCustomGenerated: fields[8] as bool,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StoryElement obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.keywords)
      ..writeByte(7)
      ..write(obj.preferredGenre)
      ..writeByte(8)
      ..write(obj.isCustomGenerated)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryElementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AIInterventionAdapter extends TypeAdapter<AIIntervention> {
  @override
  final int typeId = 53;

  @override
  AIIntervention read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIIntervention(
      id: fields[0] as String,
      content: fields[1] as String,
      timestamp: fields[2] as Duration,
      wasAccepted: fields[3] as bool,
      userResponse: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AIIntervention obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.wasAccepted)
      ..writeByte(4)
      ..write(obj.userResponse)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIInterventionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoryMetricsAdapter extends TypeAdapter<StoryMetrics> {
  @override
  final int typeId = 54;

  @override
  StoryMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoryMetrics(
      creativity: fields[0] as double,
      collaboration: fields[1] as double,
      fluidity: fields[2] as double,
      totalDuration: fields[3] as Duration,
      wordCount: fields[4] as int,
      pauseCount: fields[5] as int,
      averagePauseDuration: fields[6] as double,
      aiInterventionsUsed: fields[7] as int,
      overallScore: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, StoryMetrics obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.creativity)
      ..writeByte(1)
      ..write(obj.collaboration)
      ..writeByte(2)
      ..write(obj.fluidity)
      ..writeByte(3)
      ..write(obj.totalDuration)
      ..writeByte(4)
      ..write(obj.wordCount)
      ..writeByte(5)
      ..write(obj.pauseCount)
      ..writeByte(6)
      ..write(obj.averagePauseDuration)
      ..writeByte(7)
      ..write(obj.aiInterventionsUsed)
      ..writeByte(8)
      ..write(obj.overallScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoryAdapter extends TypeAdapter<Story> {
  @override
  final int typeId = 55;

  @override
  Story read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Story(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      elements: (fields[3] as List).cast<StoryElement>(),
      audioSegmentUrls: (fields[4] as List).cast<String>(),
      aiInterventions: (fields[5] as List).cast<AIIntervention>(),
      metrics: fields[6] as StoryMetrics,
      createdAt: fields[7] as DateTime?,
      genre: fields[8] as StoryGenre?,
      likes: fields[9] as int,
      isPublic: fields[10] as bool,
      transcription: fields[11] as String?,
      tags: (fields[12] as List).cast<String>(),
      isFavorite: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Story obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.elements)
      ..writeByte(4)
      ..write(obj.audioSegmentUrls)
      ..writeByte(5)
      ..write(obj.aiInterventions)
      ..writeByte(6)
      ..write(obj.metrics)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.genre)
      ..writeByte(9)
      ..write(obj.likes)
      ..writeByte(10)
      ..write(obj.isPublic)
      ..writeByte(11)
      ..write(obj.transcription)
      ..writeByte(12)
      ..write(obj.tags)
      ..writeByte(13)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoryUserStatsAdapter extends TypeAdapter<StoryUserStats> {
  @override
  final int typeId = 72;

  @override
  StoryUserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoryUserStats(
      userId: fields[0] as String,
      totalStories: fields[1] as int,
      totalLikes: fields[2] as int,
      averageCreativity: fields[3] as double,
      averageCollaboration: fields[4] as double,
      averageFluidity: fields[5] as double,
      totalAIInterventionsUsed: fields[6] as int,
      genreStats: (fields[7] as Map?)?.cast<StoryGenre, int>(),
      unlockedBadges: (fields[8] as List?)?.cast<StoryBadgeType>(),
      lastStoryDate: fields[9] as DateTime?,
      currentStreak: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StoryUserStats obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.totalStories)
      ..writeByte(2)
      ..write(obj.totalLikes)
      ..writeByte(3)
      ..write(obj.averageCreativity)
      ..writeByte(4)
      ..write(obj.averageCollaboration)
      ..writeByte(5)
      ..write(obj.averageFluidity)
      ..writeByte(6)
      ..write(obj.totalAIInterventionsUsed)
      ..writeByte(7)
      ..write(obj.genreStats)
      ..writeByte(8)
      ..write(obj.unlockedBadges)
      ..writeByte(9)
      ..write(obj.lastStoryDate)
      ..writeByte(10)
      ..write(obj.currentStreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryUserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AudioMetricsAdapter extends TypeAdapter<AudioMetrics> {
  @override
  final int typeId = 74;

  @override
  AudioMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioMetrics(
      articulationScore: fields[0] as double,
      fluencyScore: fields[1] as double,
      emotionScore: fields[2] as double,
      volumeVariation: fields[3] as double,
      speakingRate: fields[4] as double,
      fillerWords: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AudioMetrics obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.articulationScore)
      ..writeByte(1)
      ..write(obj.fluencyScore)
      ..writeByte(2)
      ..write(obj.emotionScore)
      ..writeByte(3)
      ..write(obj.volumeVariation)
      ..writeByte(4)
      ..write(obj.speakingRate)
      ..writeByte(5)
      ..write(obj.fillerWords);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoryNarrativeAnalysisAdapter
    extends TypeAdapter<StoryNarrativeAnalysis> {
  @override
  final int typeId = 75;

  @override
  StoryNarrativeAnalysis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoryNarrativeAnalysis(
      storyId: fields[0] as String,
      overallScore: fields[1] as double,
      creativityScore: fields[2] as double,
      relevanceScore: fields[3] as double,
      structureScore: fields[4] as double,
      positiveFeedback: fields[5] as String,
      improvementSuggestions: fields[6] as String,
      audioMetrics: fields[7] as AudioMetrics,
      transcription: fields[8] as String,
      titleSuggestion: fields[9] as String,
      detectedKeywords: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, StoryNarrativeAnalysis obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.storyId)
      ..writeByte(1)
      ..write(obj.overallScore)
      ..writeByte(2)
      ..write(obj.creativityScore)
      ..writeByte(3)
      ..write(obj.relevanceScore)
      ..writeByte(4)
      ..write(obj.structureScore)
      ..writeByte(5)
      ..write(obj.positiveFeedback)
      ..writeByte(6)
      ..write(obj.improvementSuggestions)
      ..writeByte(7)
      ..write(obj.audioMetrics)
      ..writeByte(8)
      ..write(obj.transcription)
      ..writeByte(9)
      ..write(obj.titleSuggestion)
      ..writeByte(10)
      ..write(obj.detectedKeywords);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryNarrativeAnalysisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoryElementTypeAdapter extends TypeAdapter<StoryElementType> {
  @override
  final int typeId = 50;

  @override
  StoryElementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StoryElementType.character;
      case 1:
        return StoryElementType.location;
      case 2:
        return StoryElementType.magicObject;
      default:
        return StoryElementType.character;
    }
  }

  @override
  void write(BinaryWriter writer, StoryElementType obj) {
    switch (obj) {
      case StoryElementType.character:
        writer.writeByte(0);
        break;
      case StoryElementType.location:
        writer.writeByte(1);
        break;
      case StoryElementType.magicObject:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryElementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoryGenreAdapter extends TypeAdapter<StoryGenre> {
  @override
  final int typeId = 51;

  @override
  StoryGenre read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StoryGenre.fantasy;
      case 1:
        return StoryGenre.scienceFiction;
      case 2:
        return StoryGenre.adventure;
      case 3:
        return StoryGenre.mystery;
      case 4:
        return StoryGenre.comedy;
      case 5:
        return StoryGenre.horror;
      case 6:
        return StoryGenre.fairytale;
      default:
        return StoryGenre.fantasy;
    }
  }

  @override
  void write(BinaryWriter writer, StoryGenre obj) {
    switch (obj) {
      case StoryGenre.fantasy:
        writer.writeByte(0);
        break;
      case StoryGenre.scienceFiction:
        writer.writeByte(1);
        break;
      case StoryGenre.adventure:
        writer.writeByte(2);
        break;
      case StoryGenre.mystery:
        writer.writeByte(3);
        break;
      case StoryGenre.comedy:
        writer.writeByte(4);
        break;
      case StoryGenre.horror:
        writer.writeByte(5);
        break;
      case StoryGenre.fairytale:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryGenreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InterventionTypeAdapter extends TypeAdapter<InterventionType> {
  @override
  final int typeId = 73;

  @override
  InterventionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InterventionType.plotTwist;
      case 1:
        return InterventionType.characterReveal;
      case 2:
        return InterventionType.settingShift;
      case 3:
        return InterventionType.toneChange;
      case 4:
        return InterventionType.mysteryElement;
      case 5:
        return InterventionType.creativeBoost;
      case 6:
        return InterventionType.narrativeChallenge;
      default:
        return InterventionType.plotTwist;
    }
  }

  @override
  void write(BinaryWriter writer, InterventionType obj) {
    switch (obj) {
      case InterventionType.plotTwist:
        writer.writeByte(0);
        break;
      case InterventionType.characterReveal:
        writer.writeByte(1);
        break;
      case InterventionType.settingShift:
        writer.writeByte(2);
        break;
      case InterventionType.toneChange:
        writer.writeByte(3);
        break;
      case InterventionType.mysteryElement:
        writer.writeByte(4);
        break;
      case InterventionType.creativeBoost:
        writer.writeByte(5);
        break;
      case InterventionType.narrativeChallenge:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoryBadgeTypeAdapter extends TypeAdapter<StoryBadgeType> {
  @override
  final int typeId = 71;

  @override
  StoryBadgeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StoryBadgeType.improvisationMaster;
      case 1:
        return StoryBadgeType.aiCollaborator;
      case 2:
        return StoryBadgeType.librarian;
      case 3:
        return StoryBadgeType.popularStoryteller;
      case 4:
        return StoryBadgeType.narrativeLegend;
      case 5:
        return StoryBadgeType.genreMaster;
      case 6:
        return StoryBadgeType.creativityChampion;
      case 7:
        return StoryBadgeType.fluentNarrator;
      default:
        return StoryBadgeType.improvisationMaster;
    }
  }

  @override
  void write(BinaryWriter writer, StoryBadgeType obj) {
    switch (obj) {
      case StoryBadgeType.improvisationMaster:
        writer.writeByte(0);
        break;
      case StoryBadgeType.aiCollaborator:
        writer.writeByte(1);
        break;
      case StoryBadgeType.librarian:
        writer.writeByte(2);
        break;
      case StoryBadgeType.popularStoryteller:
        writer.writeByte(3);
        break;
      case StoryBadgeType.narrativeLegend:
        writer.writeByte(4);
        break;
      case StoryBadgeType.genreMaster:
        writer.writeByte(5);
        break;
      case StoryBadgeType.creativityChampion:
        writer.writeByte(6);
        break;
      case StoryBadgeType.fluentNarrator:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryBadgeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
