class Client {
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

  Client({
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
  });

  // Convert from Hive Client model
  factory Client.fromHiveClient(dynamic hiveClient) {
    return Client(
      name: hiveClient.name,
      clientId: hiveClient.clientId,
      country: hiveClient.country,
      addressLine1: hiveClient.addressLine1,
      addressLine2: hiveClient.addressLine2,
      city: hiveClient.city,
      zip: hiveClient.zipCode,
      phone: hiveClient.phone,
      email: hiveClient.email,
      type: hiveClient.type,
      invoiceCount: hiveClient.invoiceCount,
      currency: hiveClient.currency,
      amount: hiveClient.amount,
      outstandingAmount: hiveClient.outstandingAmount,
      hasOutstanding: hiveClient.hasOutstanding,
      dueAmount: hiveClient.dueAmount,
      hasDue: hiveClient.hasDue,
    );
  }

  // Convert Client to a Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'clientName': name,
      'clientId': clientId,
      'taxId': taxId,
      'country': country,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'zip': zip,
      'phone': phone,
      'email': email,
      'website': website,
      'notes': notes,
      'type': type,
      'invoiceCount': invoiceCount,
      'currency': currency,
      'amount': amount,
      'outstandingAmount': outstandingAmount,
      'hasOutstanding': hasOutstanding,
      'dueAmount': dueAmount,
      'hasDue': hasDue,
    };
  }

  // Create a Client from a Map (e.g., from JSON)
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      name: map['clientName'] ?? '',
      clientId: map['clientId'] ?? '',
      taxId: map['taxId'],
      country: map['country'],
      addressLine1: map['addressLine1'],
      addressLine2: map['addressLine2'],
      city: map['city'],
      zip: map['zip'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      notes: map['notes'],
      type: map['type'] ?? 'organization',
      invoiceCount: map['invoiceCount'] ?? 0,
      currency: map['currency'] ?? 'USD',
      amount: map['amount']?.toDouble() ?? 0.0,
      outstandingAmount: map['outstandingAmount']?.toDouble() ?? 0.0,
      hasOutstanding: map['hasOutstanding'] ?? false,
      dueAmount: map['dueAmount']?.toDouble() ?? 0.0,
      hasDue: map['hasDue'] ?? false,
    );
  }
}
