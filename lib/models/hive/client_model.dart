import 'package:hive/hive.dart';

part 'client_model.g.dart';

/// Client Type enum
enum ClientType { organization, person }

/// Client model for Hive
@HiveType(typeId: 1)
class Client extends HiveObject {
  @HiveField(0)
  String clientId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // 'organization' or 'person'

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? phone;

  @HiveField(5)
  String? addressLine1;

  @HiveField(6)
  String? addressLine2;

  @HiveField(7)
  String? city;

  @HiveField(8)
  String? state;

  @HiveField(9)
  String? zipCode;

  @HiveField(10)
  String? country;

  @HiveField(11)
  int invoiceCount;

  @HiveField(12)
  double amount;

  @HiveField(13)
  double outstandingAmount;

  @HiveField(14)
  double dueAmount;

  @HiveField(15)
  String? currency;

  // Computed getters
  bool get hasOutstanding => outstandingAmount > 0;
  bool get hasDue => dueAmount > 0;

  // Safe getter for currency that provides default value if null
  String get currencyOrDefault => currency ?? 'USD';

  Client({
    required this.clientId,
    required this.name,
    required this.type,
    this.email,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.invoiceCount = 0,
    this.amount = 0.0,
    this.outstandingAmount = 0.0,
    this.dueAmount = 0.0,
    this.currency,
  });

  /// Convert from JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      clientId: json['clientId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'organization',
      email: json['email'],
      phone: json['phone'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
      invoiceCount: json['invoiceCount'] ?? 0,
      amount: _parseDouble(json['amount']),
      outstandingAmount: _parseDouble(json['outstandingAmount']),
      dueAmount: _parseDouble(json['dueAmount']),
      currency: json['currency'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'name': name,
      'type': type,
      'email': email,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'invoiceCount': invoiceCount,
      'amount': amount,
      'outstandingAmount': outstandingAmount,
      'dueAmount': dueAmount,
      'currency': currency,
    };
  }

  /// Helper to parse double values from JSON
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
