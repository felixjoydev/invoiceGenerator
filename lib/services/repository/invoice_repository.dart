import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/repository/client_repository.dart';
import 'package:invoicegenerator/services/repository/supabase_repository.dart';
import 'package:uuid/uuid.dart';

class InvoiceRepository extends SupabaseRepository<Invoice> {
  static final InvoiceRepository _instance = InvoiceRepository._internal();
  final ClientRepository _clientRepository = ClientRepository();

  factory InvoiceRepository() {
    return _instance;
  }

  InvoiceRepository._internal();

  @override
  String get tableName => 'invoices';

  @override
  Invoice fromJson(Map<String, dynamic> json) {
    // For the base implementation, assume we don't have client or items data
    // These will be loaded explicitly in getById or getAllWithItems
    return Invoice.fromMap(json);
  }

  @override
  Map<String, dynamic> toJson(Invoice invoice) {
    final map = invoice.toMap();

    // Make sure we have a user_id
    if (map['user_id'] == null) {
      map['user_id'] = currentUser?.id;
    }

    // Make sure we have an invoice_id
    if (map['invoice_id'] == null || map['invoice_id'].isEmpty) {
      map['invoice_id'] = const Uuid().v4();
    }

    // Generate an ID if it's null - Supabase requires a non-null ID for insert
    if (map['id'] == null) {
      map['id'] = const Uuid().v4();
    }

    return map;
  }

  /// Get all invoices with items
  Future<List<Invoice>> getAllWithItems() async {
    try {
      // Get all invoices
      final response = await supabase
          .from(tableName)
          .select('*, clients(*)')
          .order('created_at', ascending: false);

      // Process each invoice and fetch its items
      final List<Invoice> result = [];
      for (final invoiceData in response) {
        // Extract client from the nested data
        final clientData = invoiceData['clients'];
        final client = Client.fromMap(clientData);

        // Fetch invoice items
        final items = await _getInvoiceItems(invoiceData['id']);

        // Create invoice object with all data
        final invoice = Invoice.fromMap(invoiceData, clientData: client);

        result.add(invoice.copyWith(items: items));
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching all invoices: $e');
      rethrow;
    }
  }

  /// Get an invoice by ID
  @override
  Future<Invoice?> getById(String id) async {
    try {
      final response =
          await supabase
              .from(tableName)
              .select('*, clients(*)')
              .eq('id', id)
              .maybeSingle();

      if (response == null) return null;

      // Extract client from the nested data
      final clientData = response['clients'];
      final client = Client.fromMap(clientData);

      // Fetch invoice items
      final items = await _getInvoiceItems(response['id']);

      // Create invoice object with all data
      final invoice = Invoice.fromMap(response, clientData: client);

      return invoice.copyWith(items: items);
    } catch (e) {
      debugPrint('Error fetching invoice by ID: $e');
      rethrow;
    }
  }

  /// Get items for an invoice
  Future<List<CatalogItem>> _getInvoiceItems(String invoiceId) async {
    try {
      final response = await supabase
          .from('invoice_items')
          .select()
          .eq('invoice_id', invoiceId)
          .order('created_at');

      return response
          .map<CatalogItem>((item) => CatalogItem.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error fetching invoice items: $e');
      return [];
    }
  }

  /// Create a new invoice with its items
  Future<Invoice> createWithItems(Invoice invoice) async {
    try {
      // Start a transaction
      return await supabase.rpc(
        'create_invoice_with_items',
        params: {
          'p_invoice_data': toJson(invoice),
          'p_invoice_items': invoice.items.map((item) => item.toMap()).toList(),
        },
      );
    } catch (e) {
      debugPrint('Error creating invoice with items: $e');
      rethrow;
    }
  }

  /// Update an invoice with its items
  Future<Invoice> updateWithItems(String id, Invoice invoice) async {
    try {
      // Start a transaction
      return await supabase.rpc(
        'update_invoice_with_items',
        params: {
          'p_invoice_id': id,
          'p_invoice_data': toJson(invoice),
          'p_invoice_items': invoice.items.map((item) => item.toMap()).toList(),
        },
      );
    } catch (e) {
      debugPrint('Error updating invoice with items: $e');
      rethrow;
    }
  }

  /// Delete an invoice and its items
  @override
  Future<void> delete(String id) async {
    try {
      // The database will handle cascading deletes to invoice_items
      await supabase.from(tableName).delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      rethrow;
    }
  }
}
