import 'package:hive/hive.dart';

part 'invoice_item_model.g.dart';

/// Invoice Item model for Hive
/// Represents an item in an invoice, which may reference a catalog item
@HiveType(typeId: 5)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  String currency;

  @HiveField(4)
  String? catalogItemId; // Reference to the catalog item (title)

  InvoiceItem({
    required this.title,
    required this.amount,
    required this.quantity,
    this.currency = 'USD',
    this.catalogItemId,
  });

  /// Convert from JSON
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      title: json['title'] ?? '',
      amount: _parseDouble(json['amount']),
      quantity: json['quantity'] ?? 1,
      currency: json['currency'] ?? 'USD',
      catalogItemId: json['catalogItemId'],
    );
  }

  /// Convert from CatalogItem
  factory InvoiceItem.fromCatalogItem(dynamic item) {
    if (item is Map<String, dynamic>) {
      final title = item['title'] ?? '';
      return InvoiceItem(
        title: title,
        amount: _parseDouble(item['amount']),
        quantity: item['quantity'] ?? 1,
        currency: item['currency'] ?? 'USD',
        catalogItemId:
            title, // Store title as catalogItemId for proper reference
      );
    } else {
      final title = item.title;
      return InvoiceItem(
        title: title,
        amount: item.amount,
        quantity: item.quantity,
        currency: item.currency,
        catalogItemId:
            title, // Store title as catalogItemId for proper reference
      );
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'quantity': quantity,
      'currency': currency,
      'catalogItemId': catalogItemId,
    };
  }

  /// Calculate line total
  double get total => amount * quantity;

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
