class Client {
  final String? id; // Supabase UUID
  final String? userId; // Auth user ID
  final String name;
  final String clientId;
  final String? taxId;
  final String? country;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? zip;
  final String? phone;
  final String? email;
  final String? website;
  final String? notes;
  final String type; // 'organization' or 'person'
  final int invoiceCount;
  final String currency;
  final double amount;
  final double outstandingAmount;
  final bool hasOutstanding;
  final double dueAmount;
  final bool hasDue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Client({
    this.id,
    this.userId,
    required this.name,
    required this.clientId,
    this.taxId,
    this.country,
    this.addressLine1 = '',
    this.addressLine2,
    this.city,
    this.zip,
    this.phone,
    this.email = '',
    this.website,
    this.notes,
    required this.type,
    this.invoiceCount = 0,
    this.currency = 'USD',
    this.amount = 0.0,
    this.outstandingAmount = 0.0,
    this.hasOutstanding = false,
    this.dueAmount = 0.0,
    this.hasDue = false,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Client to a Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'name': name,
      'tax_id': taxId,
      'country': country,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'zip': zip,
      'phone': phone,
      'email': email,
      'website': website,
      'notes': notes,
      'type': type,
      'invoice_count': invoiceCount,
      'currency': currency,
      'amount': amount,
      'outstanding_amount': outstandingAmount,
      'has_outstanding': hasOutstanding,
      'due_amount': dueAmount,
      'has_due': hasDue,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create a Client from a Map (e.g., from JSON)
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'] ?? map['clientName'] ?? '',
      clientId: map['client_id'] ?? map['clientId'] ?? '',
      taxId: map['tax_id'] ?? map['taxId'],
      country: map['country'],
      addressLine1: map['address_line1'] ?? map['addressLine1'],
      addressLine2: map['address_line2'] ?? map['addressLine2'],
      city: map['city'],
      zip: map['zip'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      notes: map['notes'],
      type: map['type'] ?? 'organization',
      invoiceCount: map['invoice_count'] ?? map['invoiceCount'] ?? 0,
      currency: map['currency'] ?? 'USD',
      amount: (map['amount'] is num) ? map['amount'].toDouble() : 0.0,
      outstandingAmount:
          (map['outstanding_amount'] is num)
              ? map['outstanding_amount'].toDouble()
              : (map['outstandingAmount'] is num)
              ? map['outstandingAmount'].toDouble()
              : 0.0,
      hasOutstanding: map['has_outstanding'] ?? map['hasOutstanding'] ?? false,
      dueAmount:
          (map['due_amount'] is num)
              ? map['due_amount'].toDouble()
              : (map['dueAmount'] is num)
              ? map['dueAmount'].toDouble()
              : 0.0,
      hasDue: map['has_due'] ?? map['hasDue'] ?? false,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Create a copy with updated fields
  Client copyWith({
    String? id,
    String? userId,
    String? name,
    String? clientId,
    String? taxId,
    String? country,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? zip,
    String? phone,
    String? email,
    String? website,
    String? notes,
    String? type,
    int? invoiceCount,
    String? currency,
    double? amount,
    double? outstandingAmount,
    bool? hasOutstanding,
    double? dueAmount,
    bool? hasDue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      clientId: clientId ?? this.clientId,
      taxId: taxId ?? this.taxId,
      country: country ?? this.country,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      hasOutstanding: hasOutstanding ?? this.hasOutstanding,
      dueAmount: dueAmount ?? this.dueAmount,
      hasDue: hasDue ?? this.hasDue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
