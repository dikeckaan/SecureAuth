// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      useBiometric: fields[0] as bool? ?? false,
      requireAuthOnLaunch: fields[1] as bool? ?? true,
      passwordHash: fields[2] as String?,
      isDarkMode: fields[3] as bool? ?? false,
      autoLockSeconds: fields[4] as int? ?? 60,
      clipboardClearSeconds: fields[5] as int? ?? 30,
      maxFailedAttempts: fields[6] as int? ?? 10,
      wipeOnMaxAttempts: fields[7] as bool? ?? false,
      passwordSalt: fields[8] as String?,
      languageCode: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.useBiometric)
      ..writeByte(1)
      ..write(obj.requireAuthOnLaunch)
      ..writeByte(2)
      ..write(obj.passwordHash)
      ..writeByte(3)
      ..write(obj.isDarkMode)
      ..writeByte(4)
      ..write(obj.autoLockSeconds)
      ..writeByte(5)
      ..write(obj.clipboardClearSeconds)
      ..writeByte(6)
      ..write(obj.maxFailedAttempts)
      ..writeByte(7)
      ..write(obj.wipeOnMaxAttempts)
      ..writeByte(8)
      ..write(obj.passwordSalt)
      ..writeByte(9)
      ..write(obj.languageCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
