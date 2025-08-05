// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'virelangue_leaderboard_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LeaderboardEntryAdapter extends TypeAdapter<LeaderboardEntry> {
  @override
  final int typeId = 56;

  @override
  LeaderboardEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeaderboardEntry(
      userId: fields[0] as String,
      username: fields[1] as String,
      totalGemValue: fields[2] as int,
      gemCounts: (fields[3] as Map?)?.cast<GemType, int>(),
      currentStreak: fields[4] as int,
      bestStreak: fields[5] as int,
      totalSessions: fields[6] as int,
      averageScore: fields[7] as double,
      league: fields[8] as LeaderboardLeague,
      seasonNumber: fields[9] as int,
      lastUpdated: fields[10] as DateTime,
      compositeScore: fields[11] as double,
      currentRank: fields[12] as int,
      leagueRank: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LeaderboardEntry obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.totalGemValue)
      ..writeByte(3)
      ..write(obj.gemCounts)
      ..writeByte(4)
      ..write(obj.currentStreak)
      ..writeByte(5)
      ..write(obj.bestStreak)
      ..writeByte(6)
      ..write(obj.totalSessions)
      ..writeByte(7)
      ..write(obj.averageScore)
      ..writeByte(8)
      ..write(obj.league)
      ..writeByte(9)
      ..write(obj.seasonNumber)
      ..writeByte(10)
      ..write(obj.lastUpdated)
      ..writeByte(11)
      ..write(obj.compositeScore)
      ..writeByte(12)
      ..write(obj.currentRank)
      ..writeByte(13)
      ..write(obj.leagueRank);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRankHistoryAdapter extends TypeAdapter<UserRankHistory> {
  @override
  final int typeId = 67;

  @override
  UserRankHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserRankHistory(
      userId: fields[0] as String,
      rankSnapshots: (fields[1] as List).cast<RankSnapshot>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserRankHistory obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.rankSnapshots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRankHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RankSnapshotAdapter extends TypeAdapter<RankSnapshot> {
  @override
  final int typeId = 68;

  @override
  RankSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RankSnapshot(
      timestamp: fields[0] as DateTime,
      globalRank: fields[1] as int,
      leagueRank: fields[2] as int,
      league: fields[3] as LeaderboardLeague,
      totalGemValue: fields[4] as int,
      compositeScore: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RankSnapshot obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.globalRank)
      ..writeByte(2)
      ..write(obj.leagueRank)
      ..writeByte(3)
      ..write(obj.league)
      ..writeByte(4)
      ..write(obj.totalGemValue)
      ..writeByte(5)
      ..write(obj.compositeScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SeasonStatsAdapter extends TypeAdapter<SeasonStats> {
  @override
  final int typeId = 69;

  @override
  SeasonStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SeasonStats(
      seasonNumber: fields[0] as int,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime,
      totalParticipants: fields[3] as int,
      totalGemValueAwarded: fields[4] as int,
      topPerformers: (fields[5] as List).cast<String>(),
      averageScore: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SeasonStats obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.seasonNumber)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.totalParticipants)
      ..writeByte(4)
      ..write(obj.totalGemValueAwarded)
      ..writeByte(5)
      ..write(obj.topPerformers)
      ..writeByte(6)
      ..write(obj.averageScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LeaderboardAchievementAdapter
    extends TypeAdapter<LeaderboardAchievement> {
  @override
  final int typeId = 61;

  @override
  LeaderboardAchievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeaderboardAchievement(
      userId: fields[0] as String,
      type: fields[1] as AchievementType,
      title: fields[2] as String,
      description: fields[3] as String,
      iconEmoji: fields[4] as String,
      earnedAt: fields[5] as DateTime,
      gemValueAtEarning: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LeaderboardAchievement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.iconEmoji)
      ..writeByte(5)
      ..write(obj.earnedAt)
      ..writeByte(6)
      ..write(obj.gemValueAtEarning);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardAchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
