import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/catalog_item.dart';

enum InvoiceStatus { overdue, outstanding, paid }

class Invoice {
  final String invoiceId;
  final Client client;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<CatalogItem> items;
  final double subtotal;
  final double taxRate; // Percentage value (e.g., 10.0 for 10%)
  final double taxAmount;
  final double total;
  final String? notes;
  final InvoiceStatus status;

  Invoice({
    required this.invoiceId,
    required this.client,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.status = InvoiceStatus.outstanding,
  });

  // Create a copy with updated fields
  Invoice copyWith({
    String? invoiceId,
    Client? client,
    DateTime? issueDate,
    DateTime? dueDate,
    List<CatalogItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? notes,
    InvoiceStatus? status,
  }) {
    return Invoice(
      invoiceId: invoiceId ?? this.invoiceId,
      client: client ?? this.client,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  // Serialize to Map
  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'client': client.toMap(),
      'issueDate': issueDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'notes': notes,
      'status': status.index,
    };
  }

  // Deserialize from Map
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      invoiceId: map['invoiceId'],
      client: Client.fromMap(map['client']),
      issueDate: DateTime.fromMillisecondsSinceEpoch(map['issueDate']),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      items:
          (map['items'] as List)
              .map((item) => CatalogItem.fromMap(item))
              .toList(),
      subtotal: map['subtotal'],
      taxRate: map['taxRate'],
      taxAmount: map['taxAmount'],
      total: map['total'],
      notes: map['notes'],
      status: InvoiceStatus.values[map['status']],
    );
  }
}
