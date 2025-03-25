// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CatalogItemAdapter extends TypeAdapter<CatalogItem> {
  @override
  final int typeId = 2;

  @override
  CatalogItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CatalogItem(
      title: fields[0] as String,
      amount: fields[1] as double,
      quantity: fields[2] as int,
      currency: fields[3] as String,
      usageCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CatalogItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.usageCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
