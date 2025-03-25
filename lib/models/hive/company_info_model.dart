import 'package:hive/hive.dart';

part 'company_info_model.g.dart';

/// Company Information model for Hive
@HiveType(typeId: 0)
class CompanyInfo extends HiveObject {
  @HiveField(0)
  String businessName;

  @HiveField(1)
  String currency;

  @HiveField(2)
  bool enableTax;

  @HiveField(3)
  String? country;

  @HiveField(4)
  String? addressLine1;

  @HiveField(5)
  String? addressLine2;

  @HiveField(6)
  String? city;

  @HiveField(7)
  String? state;

  @HiveField(8)
  String? zipCode;

  @HiveField(9)
  String? phone;

  @HiveField(10)
  String? email;

  @HiveField(11)
  String? website;

  @HiveField(12)
  String? logoPath;

  @HiveField(13)
  String? bankName;

  @HiveField(14)
  String? accountNumber;

  @HiveField(15)
  String? accountName;

  @HiveField(16)
  String? swiftCode;

  @HiveField(17)
  String? taxNumber;

  CompanyInfo({
    required this.businessName,
    required this.currency,
    required this.enableTax,
    this.country,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.email,
    this.website,
    this.logoPath,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.swiftCode,
    this.taxNumber,
  });

  /// Convert from JSON
  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      businessName: json['businessName'] ?? '',
      currency: json['currency'] ?? 'USD',
      enableTax: json['enableTax'] ?? false,
      country: json['country'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      logoPath: json['logoPath'],
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      accountName: json['accountName'],
      swiftCode: json['swiftCode'],
      taxNumber: json['taxNumber'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'currency': currency,
      'enableTax': enableTax,
      'country': country,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
      'website': website,
      'logoPath': logoPath,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'swiftCode': swiftCode,
      'taxNumber': taxNumber,
    };
  }

  /// Create an empty company info
  factory CompanyInfo.empty() {
    return CompanyInfo(businessName: '', currency: 'USD', enableTax: false);
  }
}
