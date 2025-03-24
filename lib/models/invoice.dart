import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/catalog_item.dart';

enum InvoiceStatus { overdue, outstanding, paid }

class Invoice {
  final String? id; // Supabase UUID
  final String? userId; // Auth user ID
  final String invoiceId;
  final Client client;
  final String? clientId; // Database reference
  final DateTime issueDate;
  final DateTime dueDate;
  final List<CatalogItem> items;
  final double subtotal;
  final double taxRate; // Percentage value (e.g., 10.0 for 10%)
  final double taxAmount;
  final double total;
  final String? notes;
  final InvoiceStatus status;
  final String templateName; // Store the template name
  final DateTime? paidDate; // Date when invoice was marked as paid
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    this.id,
    this.userId,
    required this.invoiceId,
    required this.client,
    this.clientId,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.status = InvoiceStatus.outstanding,
    this.templateName = 'Orange', // Default to Orange template
    this.paidDate,
    this.createdAt,
    this.updatedAt,
  });

  // Create a copy with updated fields
  Invoice copyWith({
    String? id,
    String? userId,
    String? invoiceId,
    Client? client,
    String? clientId,
    DateTime? issueDate,
    DateTime? dueDate,
    List<CatalogItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? notes,
    InvoiceStatus? status,
    String? templateName,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceId: invoiceId ?? this.invoiceId,
      client: client ?? this.client,
      clientId: clientId ?? this.clientId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      templateName: templateName ?? this.templateName,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Serialize to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'invoice_id': invoiceId,
      'client_id': clientId ?? client.id,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'notes': notes,
      'status': status.index,
      'template_name': templateName,
      'paid_date': paidDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Deserialize from Map
  factory Invoice.fromMap(Map<String, dynamic> map, {Client? clientData}) {
    Client client;
    if (clientData != null) {
      client = clientData;
    } else if (map['client'] != null) {
      client = Client.fromMap(map['client']);
    } else {
      throw ArgumentError('Invoice requires client data');
    }

    List<CatalogItem> items = [];
    if (map['items'] != null) {
      items =
          (map['items'] as List)
              .map((item) => CatalogItem.fromMap(item))
              .toList();
    }

    return Invoice(
      id: map['id'],
      userId: map['user_id'],
      invoiceId: map['invoice_id'] ?? map['invoiceId'],
      client: client,
      clientId: map['client_id'],
      issueDate:
          map['issue_date'] != null
              ? DateTime.parse(map['issue_date'])
              : DateTime.fromMillisecondsSinceEpoch(map['issueDate']),
      dueDate:
          map['due_date'] != null
              ? DateTime.parse(map['due_date'])
              : DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      items: items,
      subtotal:
          map['subtotal'] is int ? map['subtotal'].toDouble() : map['subtotal'],
      taxRate:
          map['tax_rate'] != null
              ? (map['tax_rate'] is int
                  ? map['tax_rate'].toDouble()
                  : map['tax_rate'])
              : map['taxRate'],
      taxAmount:
          map['tax_amount'] != null
              ? (map['tax_amount'] is int
                  ? map['tax_amount'].toDouble()
                  : map['tax_amount'])
              : map['taxAmount'],
      total: map['total'] is int ? map['total'].toDouble() : map['total'],
      notes: map['notes'],
      status: InvoiceStatus.values[map['status'] ?? 1],
      templateName: map['template_name'] ?? map['templateName'] ?? 'Orange',
      paidDate:
          map['paid_date'] != null
              ? DateTime.parse(map['paid_date'])
              : map['paidDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['paidDate'])
              : null,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
