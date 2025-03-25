// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_info_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompanyInfoAdapter extends TypeAdapter<CompanyInfo> {
  @override
  final int typeId = 0;

  @override
  CompanyInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompanyInfo(
      businessName: fields[0] as String,
      currency: fields[1] as String,
      enableTax: fields[2] as bool,
      country: fields[3] as String?,
      addressLine1: fields[4] as String?,
      addressLine2: fields[5] as String?,
      city: fields[6] as String?,
      state: fields[7] as String?,
      zipCode: fields[8] as String?,
      phone: fields[9] as String?,
      email: fields[10] as String?,
      website: fields[11] as String?,
      logoPath: fields[12] as String?,
      bankName: fields[13] as String?,
      accountNumber: fields[14] as String?,
      accountName: fields[15] as String?,
      swiftCode: fields[16] as String?,
      taxNumber: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CompanyInfo obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.enableTax)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.addressLine1)
      ..writeByte(5)
      ..write(obj.addressLine2)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.state)
      ..writeByte(8)
      ..write(obj.zipCode)
      ..writeByte(9)
      ..write(obj.phone)
      ..writeByte(10)
      ..write(obj.email)
      ..writeByte(11)
      ..write(obj.website)
      ..writeByte(12)
      ..write(obj.logoPath)
      ..writeByte(13)
      ..write(obj.bankName)
      ..writeByte(14)
      ..write(obj.accountNumber)
      ..writeByte(15)
      ..write(obj.accountName)
      ..writeByte(16)
      ..write(obj.swiftCode)
      ..writeByte(17)
      ..write(obj.taxNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
