class CompanyInfo {
  final String id; // User ID from Supabase auth
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

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyInfo({
    required this.id,
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
    this.createdAt,
    this.updatedAt,
  });

  // Create a copy with updated fields
  CompanyInfo copyWith({
    String? id,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyInfo(
      id: id ?? this.id,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Serialize to Map
  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();

    return {
      'id': id,
      'business_name': businessName,
      'logo_url': logoPath,
      'currency': currency,
      'tax_rate': taxRate,
      'tax_enabled': enableTax,
      'country': country,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'zip': zip,
      'phone': phone,
      'email': email,
      'website': website,
      'bank_name': bankName,
      'account_holder': accountHolder,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': now,
    };
  }

  // Deserialize from Map
  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      id: map['id'],
      businessName: map['business_name'] ?? map['businessName'] ?? '',
      logoPath: map['logo_url'] ?? map['logoPath'],
      currency: map['currency'] ?? 'USD',
      taxRate:
          map['tax_rate'] != null
              ? (map['tax_rate'] is int
                  ? map['tax_rate'].toDouble()
                  : map['tax_rate'])
              : (map['taxRate'] is int
                  ? map['taxRate'].toDouble()
                  : map['taxRate']),
      enableTax: map['tax_enabled'] ?? map['enableTax'] ?? false,
      country: map['country'] ?? '',
      addressLine1: map['address_line1'] ?? map['addressLine1'] ?? '',
      addressLine2: map['address_line2'] ?? map['addressLine2'],
      city: map['city'] ?? '',
      zip: map['zip'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      bankName: map['bank_name'] ?? map['bankName'],
      accountHolder: map['account_holder'] ?? map['accountHolder'],
      accountNumber: map['account_number'] ?? map['accountNumber'],
      ifscCode: map['ifsc_code'] ?? map['ifscCode'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
