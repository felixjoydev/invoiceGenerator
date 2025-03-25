import 'package:hive/hive.dart';
import 'package:invoicegenerator/models/hive/invoice_item_model.dart';

part 'invoice_model.g.dart';

/// Invoice Status enum
enum InvoiceStatus { outstanding, paid, overdue }

/// Invoice model for Hive
@HiveType(typeId: 3)
class Invoice extends HiveObject {
  @HiveField(0)
  String invoiceId;

  @HiveField(1)
  String clientId; // Reference to client, instead of embedding

  @HiveField(2)
  List<InvoiceItem> items;

  @HiveField(3)
  String issueDate; // ISO format date string

  @HiveField(4)
  String dueDate; // ISO format date string

  @HiveField(5)
  double subtotal;

  @HiveField(6)
  double taxRate;

  @HiveField(7)
  double taxAmount;

  @HiveField(8)
  double total;

  @HiveField(9)
  String status; // 'outstanding', 'paid', 'overdue'

  @HiveField(10)
  String templateName;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  String? paidDate; // ISO format date string

  @HiveField(13)
  String currency;

  @HiveField(14)
  String? pdfPath;

  @HiveField(15)
  String? shareUrl;

  Invoice({
    required this.invoiceId,
    required this.clientId,
    required this.items,
    required this.issueDate,
    required this.dueDate,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.status = 'outstanding',
    this.templateName = 'Orange',
    this.notes,
    this.paidDate,
    this.currency = 'USD',
    this.pdfPath,
    this.shareUrl,
  });

  /// Convert from JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Parse invoice items
    List<InvoiceItem> invoiceItems = [];
    if (json['items'] != null) {
      if (json['items'] is List) {
        invoiceItems =
            (json['items'] as List).map((item) {
              return InvoiceItem.fromCatalogItem(item);
            }).toList();
      }
    }

    // Get client ID from client object (legacy structure with embedded client)
    String clientId = '';
    if (json['client'] != null && json['client'] is Map) {
      clientId = json['client']['clientId'] ?? '';
    } else {
      clientId = json['clientId'] ?? '';
    }

    return Invoice(
      invoiceId: json['invoiceId'] ?? '',
      clientId: clientId,
      items: invoiceItems,
      issueDate: json['issueDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      subtotal: _parseDouble(json['subtotal']),
      taxRate: _parseDouble(json['taxRate']),
      taxAmount: _parseDouble(json['taxAmount']),
      total: _parseDouble(json['total']),
      status: json['status'] ?? 'outstanding',
      templateName: json['templateName'] ?? 'Orange',
      notes: json['notes'],
      paidDate: json['paidDate'],
      currency: json['currency'] ?? 'USD',
      pdfPath: json['pdfPath'],
      shareUrl: json['shareUrl'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'clientId': clientId,
      'items': items.map((item) => item.toJson()).toList(),
      'issueDate': issueDate,
      'dueDate': dueDate,
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'status': status,
      'templateName': templateName,
      'notes': notes,
      'paidDate': paidDate,
      'currency': currency,
      'pdfPath': pdfPath,
      'shareUrl': shareUrl,
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
