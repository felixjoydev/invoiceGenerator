// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 1;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      clientId: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      email: fields[3] as String?,
      phone: fields[4] as String?,
      addressLine1: fields[5] as String?,
      addressLine2: fields[6] as String?,
      city: fields[7] as String?,
      state: fields[8] as String?,
      zipCode: fields[9] as String?,
      country: fields[10] as String?,
      invoiceCount: fields[11] as int,
      amount: fields[12] as double,
      outstandingAmount: fields[13] as double,
      dueAmount: fields[14] as double,
      currency: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.clientId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.addressLine1)
      ..writeByte(6)
      ..write(obj.addressLine2)
      ..writeByte(7)
      ..write(obj.city)
      ..writeByte(8)
      ..write(obj.state)
      ..writeByte(9)
      ..write(obj.zipCode)
      ..writeByte(10)
      ..write(obj.country)
      ..writeByte(11)
      ..write(obj.invoiceCount)
      ..writeByte(12)
      ..write(obj.amount)
      ..writeByte(13)
      ..write(obj.outstandingAmount)
      ..writeByte(14)
      ..write(obj.dueAmount)
      ..writeByte(15)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
