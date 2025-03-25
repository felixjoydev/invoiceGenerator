// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 3;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      invoiceId: fields[0] as String,
      clientId: fields[1] as String,
      items: (fields[2] as List).cast<InvoiceItem>(),
      issueDate: fields[3] as String,
      dueDate: fields[4] as String,
      subtotal: fields[5] as double,
      taxRate: fields[6] as double,
      taxAmount: fields[7] as double,
      total: fields[8] as double,
      status: fields[9] as String,
      templateName: fields[10] as String,
      notes: fields[11] as String?,
      paidDate: fields[12] as String?,
      currency: fields[13] as String,
      pdfPath: fields[14] as String?,
      shareUrl: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.invoiceId)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.issueDate)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.subtotal)
      ..writeByte(6)
      ..write(obj.taxRate)
      ..writeByte(7)
      ..write(obj.taxAmount)
      ..writeByte(8)
      ..write(obj.total)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.templateName)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.paidDate)
      ..writeByte(13)
      ..write(obj.currency)
      ..writeByte(14)
      ..write(obj.pdfPath)
      ..writeByte(15)
      ..write(obj.shareUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
