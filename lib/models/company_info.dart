class CompanyInfo {
  final String businessName;
  final String? logoPath;
  final String currency;
  final double? taxRate;
  final bool enableTax;

  // Address fields
  final String country;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? zip;

  // Contact fields
  final String? phone;
  final String? email;
  final String? website;

  // Bank details
  final String? bankName;
  final String? accountHolder;
  final String? accountNumber;
  final String? ifscCode;

  CompanyInfo({
    required this.businessName,
    this.logoPath,
    required this.currency,
    this.taxRate,
    required this.enableTax,
    required this.country,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.zip,
    this.phone,
    this.email,
    this.website,
    this.bankName,
    this.accountHolder,
    this.accountNumber,
    this.ifscCode,
  });

  // Create a copy with updated fields
  CompanyInfo copyWith({
    String? businessName,
    String? logoPath,
    String? currency,
    double? taxRate,
    bool? enableTax,
    String? country,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? zip,
    String? phone,
    String? email,
    String? website,
    String? bankName,
    String? accountHolder,
    String? accountNumber,
    String? ifscCode,
  }) {
    return CompanyInfo(
      businessName: businessName ?? this.businessName,
      logoPath: logoPath ?? this.logoPath,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      enableTax: enableTax ?? this.enableTax,
      country: country ?? this.country,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      bankName: bankName ?? this.bankName,
      accountHolder: accountHolder ?? this.accountHolder,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
    );
  }

  // Serialize to Map
  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logoPath': logoPath,
      'currency': currency,
      'taxRate': taxRate,
      'enableTax': enableTax,
      'country': country,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'zip': zip,
      'phone': phone,
      'email': email,
      'website': website,
      'bankName': bankName,
      'accountHolder': accountHolder,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
    };
  }

  // Deserialize from Map
  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      businessName: map['businessName'],
      logoPath: map['logoPath'],
      currency: map['currency'],
      taxRate: map['taxRate'],
      enableTax: map['enableTax'] ?? false,
      country: map['country'],
      addressLine1: map['addressLine1'],
      addressLine2: map['addressLine2'],
      city: map['city'],
      zip: map['zip'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      bankName: map['bankName'],
      accountHolder: map['accountHolder'],
      accountNumber: map['accountNumber'],
      ifscCode: map['ifscCode'],
    );
  }
}
