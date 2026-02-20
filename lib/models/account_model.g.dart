// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually updated to add HiveField(8) type and HiveField(9) counter
// while preserving backward compatibility with existing 8-field records.

part of 'account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 0;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      issuer: fields[2] as String,
      secret: fields[3] as String,
      digits: fields[4] as int,
      period: fields[5] as int,
      algorithm: fields[6] as String,
      createdAt: fields[7] as DateTime,
      // Fields 8 and 9 are optional for backward compatibility
      type: fields[8] as String? ?? 'totp',
      counter: fields[9] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.issuer)
      ..writeByte(3)
      ..write(obj.secret)
      ..writeByte(4)
      ..write(obj.digits)
      ..writeByte(5)
      ..write(obj.period)
      ..writeByte(6)
      ..write(obj.algorithm)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.counter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
