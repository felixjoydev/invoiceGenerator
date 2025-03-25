import 'package:hive/hive.dart';

part 'catalog_item_model.g.dart';

/// Catalog Item model for Hive
@HiveType(typeId: 2)
class CatalogItem extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  String currency;

  @HiveField(4)
  int usageCount;

  CatalogItem({
    required this.title,
    required this.amount,
    required this.quantity,
    this.currency = 'USD',
    this.usageCount = 0,
  });

  /// Convert from JSON
  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      title: json['title'] ?? '',
      amount: _parseDouble(json['amount']),
      quantity: json['quantity'] ?? 1,
      currency: json['currency'] ?? 'USD',
      usageCount: json['usageCount'] ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'quantity': quantity,
      'currency': currency,
      'usageCount': usageCount,
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
