// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogEntryModelAdapter extends TypeAdapter<LogEntryModel> {
  @override
  final int typeId = 2;

  @override
  LogEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogEntryModel(
      timestampMs: fields[0] as int,
      levelIndex: fields[1] as int,
      category: fields[2] as String,
      message: fields[3] as String,
      metadataJson: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LogEntryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestampMs)
      ..writeByte(1)
      ..write(obj.levelIndex)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.metadataJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
