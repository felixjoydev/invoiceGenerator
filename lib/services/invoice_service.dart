import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/invoice.dart';

class InvoiceService {
  static const String _storageKey = 'invoices';

  List<Invoice> _invoices = [];

  List<Invoice> get invoices => _invoices;

  // Initialize the service and load data
  Future<void> init() async {
    await _loadInvoices();
  }

  // Load invoices from local storage
  Future<void> _loadInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? invoicesJson = prefs.getString(_storageKey);

      if (invoicesJson != null) {
        final List<dynamic> decodedList = jsonDecode(invoicesJson);
        _invoices = decodedList.map((item) => Invoice.fromMap(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      _invoices = [];
    }
  }

  // Save invoices to local storage
  Future<void> _saveInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String invoicesJson = jsonEncode(
        _invoices.map((i) => i.toMap()).toList(),
      );
      await prefs.setString(_storageKey, invoicesJson);
    } catch (e) {
      debugPrint('Error saving invoices: $e');
    }
  }

  // Add a new invoice
  Future<bool> addInvoice(Invoice invoice) async {
    try {
      _invoices.add(invoice);
      await _saveInvoices();
      return true;
    } catch (e) {
      debugPrint('Error adding invoice: $e');
      return false;
    }
  }

  // Update an existing invoice
  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      final index = _invoices.indexWhere(
        (i) => i.invoiceId == invoice.invoiceId,
      );
      if (index >= 0) {
        _invoices[index] = invoice;
        await _saveInvoices();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return false;
    }
  }

  // Delete an invoice
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      _invoices.removeWhere((i) => i.invoiceId == invoiceId);
      await _saveInvoices();
      return true;
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      return false;
    }
  }

  // Get invoices by status
  List<Invoice> getInvoicesByStatus(InvoiceStatus status) {
    return _invoices.where((i) => i.status == status).toList();
  }

  // Search invoices
  List<Invoice> searchInvoices(String query) {
    if (query.isEmpty) return _invoices;

    final String searchQuery = query.toLowerCase();
    return _invoices.where((invoice) {
      return invoice.client.name.toLowerCase().contains(searchQuery) ||
          invoice.invoiceId.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Generate a new invoice ID
  String generateInvoiceId() {
    // Simple implementation - can be enhanced
    int highestNumber = 0;

    for (var invoice in _invoices) {
      if (invoice.invoiceId.startsWith('inv-')) {
        try {
          final int num = int.parse(invoice.invoiceId.substring(4));
          if (num > highestNumber) {
            highestNumber = num;
          }
        } catch (_) {}
      }
    }

    return 'inv-${(highestNumber + 1).toString().padLeft(3, '0')}';
  }
}
