// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceSettingsAdapter extends TypeAdapter<InvoiceSettings> {
  @override
  final int typeId = 4;

  @override
  InvoiceSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceSettings(
      idFormat: fields[0] as String,
      customNotes: fields[1] as String?,
      isAutoGenerate: fields[2] as bool,
      idPrefix: fields[3] as String,
      lastInvoiceNumber: fields[4] as int,
      dueDateDays: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.idFormat)
      ..writeByte(1)
      ..write(obj.customNotes)
      ..writeByte(2)
      ..write(obj.isAutoGenerate)
      ..writeByte(3)
      ..write(obj.idPrefix)
      ..writeByte(4)
      ..write(obj.lastInvoiceNumber)
      ..writeByte(5)
      ..write(obj.dueDateDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
