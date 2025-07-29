import 'package:hive/hive.dart';

/// Adaptateur pour le type Duration
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 100; // ID unique pour Duration

  @override
  Duration read(BinaryReader reader) {
    final microseconds = reader.readInt();
    return Duration(microseconds: microseconds);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}

/// Adaptateur pour Map<String, dynamic>
class MapStringDynamicAdapter extends TypeAdapter<Map<String, dynamic>> {
  @override
  final int typeId = 101; // ID unique pour Map<String, dynamic>

  @override
  Map<String, dynamic> read(BinaryReader reader) {
    final map = <String, dynamic>{};
    final length = reader.readInt();
    for (int i = 0; i < length; i++) {
      final key = reader.readString();
      final value = reader.read();
      map[key] = value;
    }
    return map;
  }

  @override
  void write(BinaryWriter writer, Map<String, dynamic> obj) {
    writer.writeInt(obj.length);
    for (final entry in obj.entries) {
      writer.writeString(entry.key);
      writer.write(entry.value);
    }
  }
}

/// Adaptateur pour List<double>
class ListDoubleAdapter extends TypeAdapter<List<double>> {
  @override
  final int typeId = 102; // ID unique pour List<double>

  @override
  List<double> read(BinaryReader reader) {
    final length = reader.readInt();
    final list = <double>[];
    for (int i = 0; i < length; i++) {
      list.add(reader.readDouble());
    }
    return list;
  }

  @override
  void write(BinaryWriter writer, List<double> obj) {
    writer.writeInt(obj.length);
    for (final item in obj) {
      writer.writeDouble(item);
    }
  }
}

/// Adaptateur pour DateTime
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final int typeId = 103; // ID unique pour DateTime

  @override
  DateTime read(BinaryReader reader) {
    final milliseconds = reader.readInt();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}