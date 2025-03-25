import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:invoicegenerator/models/hive/invoice_model.dart';
import 'package:invoicegenerator/models/hive/invoice_item_model.dart';
import 'package:invoicegenerator/models/hive/client_model.dart';
import 'package:invoicegenerator/models/hive/catalog_item_model.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';
import 'package:invoicegenerator/services/hive/client_service.dart';
import 'package:invoicegenerator/services/hive/catalog_service.dart';
import 'package:invoicegenerator/services/hive/invoice_settings_service.dart';

/// Service for managing invoices using Hive
class InvoiceService extends ChangeNotifier {
  late Box<Invoice> _invoiceBox;
  bool _isInitialized = false;

  ClientService? _clientService;
  CatalogService? _catalogService;
  InvoiceSettingsService? _settingsService;

  List<Invoice> _invoices = [];
  List<Invoice> get invoices => _invoices;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await HiveConfig.initialize();
      _invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);
      _loadInvoices();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing InvoiceService: $e');
      rethrow;
    }
  }

  /// Set references to other services
  void setDependencies({
    ClientService? clientService,
    CatalogService? catalogService,
    InvoiceSettingsService? settingsService,
  }) {
    _clientService = clientService;
    _catalogService = catalogService;
    _settingsService = settingsService;

    // Update client cross-references
    if (_clientService != null) {
      _clientService!.setInvoiceService(this);
    }
  }

  /// Load invoices from Hive
  void _loadInvoices() {
    try {
      // Get all invoices from the Hive box
      _invoices = _invoiceBox.values.toList();

      // Sort invoices by issue date (descending)
      _invoices.sort(
        (a, b) =>
            DateTime.parse(b.issueDate).compareTo(DateTime.parse(a.issueDate)),
      );
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      _invoices = [];
    }
  }

  /// Get an invoice by ID
  Invoice? getInvoiceById(String invoiceId) {
    try {
      return _invoiceBox.get(invoiceId);
    } catch (e) {
      debugPrint('Error getting invoice by ID: $e');
      return null;
    }
  }

  /// Create a new invoice
  Future<Invoice?> createInvoice({
    required String clientId,
    required List<InvoiceItem> items,
    required String issueDate,
    required String dueDate,
    double? taxRate,
    String status = 'outstanding',
    String templateName = 'Orange',
    String? notes,
    String? currency,
  }) async {
    try {
      // Get the client
      final client = _clientService?.getClientById(clientId);
      if (client == null) {
        debugPrint('Client with ID $clientId not found');
        return null;
      }

      // Generate invoice ID
      String invoiceId = _settingsService?.generateInvoiceId() ?? 'inv-001';

      // Calculate financial totals
      double subtotal = _calculateSubtotal(items);
      double effectiveTaxRate = taxRate ?? 0.0;
      double taxAmount = (subtotal * effectiveTaxRate) / 100;
      double total = subtotal + taxAmount;

      // Create the invoice
      final invoice = Invoice(
        invoiceId: invoiceId,
        clientId: clientId,
        items: items,
        issueDate: issueDate,
        dueDate: dueDate,
        subtotal: subtotal,
        taxRate: effectiveTaxRate,
        taxAmount: taxAmount,
        total: total,
        status: status,
        templateName: templateName,
        notes: notes,
        currency: currency ?? 'USD',
      );

      // Save to Hive
      await _invoiceBox.put(invoiceId, invoice);

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();

      return invoice;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      return null;
    }
  }

  /// Update an existing invoice
  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      // Save to Hive
      await _invoiceBox.put(invoice.invoiceId, invoice);

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return false;
    }
  }

  /// Update invoice status
  Future<bool> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      final invoice = _invoiceBox.get(invoiceId);
      if (invoice == null) {
        debugPrint('Invoice with ID $invoiceId not found');
        return false;
      }

      // Update status
      final updatedInvoice = Invoice(
        invoiceId: invoice.invoiceId,
        clientId: invoice.clientId,
        items: invoice.items,
        issueDate: invoice.issueDate,
        dueDate: invoice.dueDate,
        subtotal: invoice.subtotal,
        taxRate: invoice.taxRate,
        taxAmount: invoice.taxAmount,
        total: invoice.total,
        status: status,
        templateName: invoice.templateName,
        notes: invoice.notes,
        paidDate:
            status == 'paid'
                ? DateTime.now().toIso8601String()
                : invoice.paidDate,
        currency: invoice.currency,
        pdfPath: invoice.pdfPath,
        shareUrl: invoice.shareUrl,
      );

      // Save to Hive
      await _invoiceBox.put(invoiceId, updatedInvoice);

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating invoice status: $e');
      return false;
    }
  }

  /// Delete an invoice
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      final invoice = _invoiceBox.get(invoiceId);
      if (invoice == null) {
        debugPrint('Invoice with ID $invoiceId not found');
        return false;
      }

      // Delete PDF file if it exists
      if (invoice.pdfPath != null && invoice.pdfPath!.isNotEmpty) {
        final pdfFile = File(invoice.pdfPath!);
        if (await pdfFile.exists()) {
          await pdfFile.delete();
        }
      }

      // Delete from Hive
      await _invoiceBox.delete(invoiceId);

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      return false;
    }
  }

  /// Save PDF path for an invoice
  Future<bool> savePdfPath(String invoiceId, String pdfPath) async {
    try {
      final invoice = _invoiceBox.get(invoiceId);
      if (invoice == null) {
        debugPrint('Invoice with ID $invoiceId not found');
        return false;
      }

      // Update PDF path
      final updatedInvoice = Invoice(
        invoiceId: invoice.invoiceId,
        clientId: invoice.clientId,
        items: invoice.items,
        issueDate: invoice.issueDate,
        dueDate: invoice.dueDate,
        subtotal: invoice.subtotal,
        taxRate: invoice.taxRate,
        taxAmount: invoice.taxAmount,
        total: invoice.total,
        status: invoice.status,
        templateName: invoice.templateName,
        notes: invoice.notes,
        paidDate: invoice.paidDate,
        currency: invoice.currency,
        pdfPath: pdfPath,
        shareUrl: invoice.shareUrl,
      );

      // Save to Hive
      await _invoiceBox.put(invoiceId, updatedInvoice);

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error saving PDF path: $e');
      return false;
    }
  }

  /// Get invoices for a specific client
  List<Invoice> getInvoicesForClient(String clientId) {
    return _invoices.where((invoice) => invoice.clientId == clientId).toList();
  }

  /// Check if a client has any invoices
  Future<bool> hasInvoicesForClient(String clientId) async {
    final clientInvoices = getInvoicesForClient(clientId);
    return clientInvoices.isNotEmpty;
  }

  /// Filter invoices by status
  List<Invoice> filterInvoicesByStatus(String status) {
    return _invoices.where((invoice) => invoice.status == status).toList();
  }

  /// Search invoices
  List<Invoice> searchInvoices(String query) {
    if (query.isEmpty) return _invoices;

    query = query.toLowerCase();
    return _invoices.where((invoice) {
      // Get client name for search
      final client = _clientService?.getClientById(invoice.clientId);
      final clientName = client?.name.toLowerCase() ?? '';

      return invoice.invoiceId.toLowerCase().contains(query) ||
          clientName.contains(query);
    }).toList();
  }

  /// Update client in all related invoices
  Future<void> updateClientInInvoices(Client client) async {
    final clientInvoices = getInvoicesForClient(client.clientId);
    for (final invoice in clientInvoices) {
      // No need to update invoice as it references client by ID now
      // The new relationship model automatically reflects client changes
    }
  }

  /// Calculate subtotal from invoice items
  double _calculateSubtotal(List<InvoiceItem> items) {
    double subtotal = 0.0;
    for (var item in items) {
      subtotal += (item.amount * item.quantity);
    }
    return subtotal;
  }

  /// Update client statistics based on invoices
  Future<void> _updateClientStatisticsInBackground(String clientId) async {
    try {
      if (_clientService == null) return;

      // Get all invoices for the client
      final clientInvoices = getInvoicesForClient(clientId);

      // Calculate statistics
      int invoiceCount = clientInvoices.length;
      double totalAmount = 0.0;
      double outstandingAmount = 0.0;
      double dueAmount = 0.0;

      final now = DateTime.now();

      for (final invoice in clientInvoices) {
        totalAmount += invoice.total;

        // Check for outstanding invoices
        if (invoice.status == 'outstanding') {
          outstandingAmount += invoice.total;

          // Check if due date has passed
          final dueDate = DateTime.parse(invoice.dueDate);
          if (dueDate.isBefore(now)) {
            dueAmount += invoice.total;

            // Mark as overdue if not already
            if (invoice.status != 'overdue') {
              await updateInvoiceStatus(invoice.invoiceId, 'overdue');
            }
          }
        } else if (invoice.status == 'overdue') {
          outstandingAmount += invoice.total;
          dueAmount += invoice.total;
        }
      }

      // Update client statistics
      await _clientService!.updateClientStatistics(
        clientId,
        invoiceCount: invoiceCount,
        amount: totalAmount,
        outstandingAmount: outstandingAmount,
        dueAmount: dueAmount,
      );
    } catch (e) {
      debugPrint('Error updating client statistics: $e');
    }
  }

  /// Update statistics after invoice changes
  Future<void> _updateStatisticsForInvoiceChangesInBackground(
    Invoice invoice,
  ) async {
    await _updateClientStatisticsInBackground(invoice.clientId);
  }

  /// Update statistics after invoice deletion
  Future<void> _updateStatisticsForDeletedInvoiceInBackground(
    String clientId,
    Invoice deletedInvoice,
  ) async {
    await _updateClientStatisticsInBackground(clientId);
  }

  /// Update catalog items usage
  Future<void> _updateCatalogItemsUsage(List<InvoiceItem> items) async {
    if (_catalogService == null) return;

    Set<String> processedCatalogItems = {};

    for (final item in items) {
      if (item.catalogItemId != null &&
          !processedCatalogItems.contains(item.catalogItemId)) {
        // Add to processed set to avoid incrementing the same item twice
        processedCatalogItems.add(item.catalogItemId!);

        // Increment usage count for the catalog item
        await _catalogService!.incrementUsageCount(item.catalogItemId!);

        // Also log for debugging
        debugPrint(
          'Incrementing usage count for catalog item: ${item.catalogItemId}',
        );
      }
    }

    // Force recalculation of all stats to ensure consistency
    await recalculateAllStatistics();
  }

  /// Handle changes to catalog item titles
  Future<void> updateCatalogItemTitleInInvoices(
    String oldTitle,
    String newTitle,
  ) async {
    try {
      for (final invoice in _invoices) {
        bool updated = false;

        // Update any items in this invoice that reference the old catalog item
        final updatedItems =
            invoice.items.map((item) {
              if (item.catalogItemId == oldTitle) {
                updated = true;
                return InvoiceItem(
                  title:
                      item.title, // Title might be different than catalogItemId
                  amount: item.amount,
                  quantity: item.quantity,
                  currency: item.currency,
                  catalogItemId: newTitle, // Update the reference
                );
              }
              return item;
            }).toList();

        if (updated) {
          final updatedInvoice = Invoice(
            invoiceId: invoice.invoiceId,
            clientId: invoice.clientId,
            items: updatedItems,
            issueDate: invoice.issueDate,
            dueDate: invoice.dueDate,
            subtotal: invoice.subtotal,
            taxRate: invoice.taxRate,
            taxAmount: invoice.taxAmount,
            total: invoice.total,
            status: invoice.status,
            templateName: invoice.templateName,
            notes: invoice.notes,
            paidDate: invoice.paidDate,
            currency: invoice.currency,
            pdfPath: invoice.pdfPath,
            shareUrl: invoice.shareUrl,
          );

          await _invoiceBox.put(invoice.invoiceId, updatedInvoice);
        }
      }

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating catalog item title in invoices: $e');
    }
  }

  /// Update catalog item details in invoices
  Future<void> updateCatalogItemInInvoices(CatalogItem item) async {
    try {
      for (final invoice in _invoices) {
        bool updated = false;

        // Update any items in this invoice that reference this catalog item
        final updatedItems =
            invoice.items.map((invoiceItem) {
              if (invoiceItem.catalogItemId == item.title) {
                updated = true;
                return InvoiceItem(
                  title: invoiceItem.title, // Keep original title
                  amount: item.amount, // Update amount
                  quantity: invoiceItem.quantity, // Keep original quantity
                  currency: item.currency, // Update currency
                  catalogItemId: item.title,
                );
              }
              return invoiceItem;
            }).toList();

        if (updated) {
          // Recalculate totals
          double subtotal = _calculateSubtotal(updatedItems);
          double taxAmount = (subtotal * invoice.taxRate) / 100;
          double total = subtotal + taxAmount;

          final updatedInvoice = Invoice(
            invoiceId: invoice.invoiceId,
            clientId: invoice.clientId,
            items: updatedItems,
            issueDate: invoice.issueDate,
            dueDate: invoice.dueDate,
            subtotal: subtotal,
            taxRate: invoice.taxRate,
            taxAmount: taxAmount,
            total: total,
            status: invoice.status,
            templateName: invoice.templateName,
            notes: invoice.notes,
            paidDate: invoice.paidDate,
            currency: invoice.currency,
            pdfPath: invoice.pdfPath,
            shareUrl: invoice.shareUrl,
          );

          await _invoiceBox.put(invoice.invoiceId, updatedInvoice);
        }
      }

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating catalog item in invoices: $e');
    }
  }

  /// Handle deleted catalog item in invoices
  Future<void> handleDeletedCatalogItemInInvoices(String itemTitle) async {
    try {
      for (final invoice in _invoices) {
        bool updated = false;

        // Remove catalog item reference but keep the line item
        final updatedItems =
            invoice.items.map((invoiceItem) {
              if (invoiceItem.catalogItemId == itemTitle) {
                updated = true;
                return InvoiceItem(
                  title: invoiceItem.title,
                  amount: invoiceItem.amount,
                  quantity: invoiceItem.quantity,
                  currency: invoiceItem.currency,
                  catalogItemId: null, // Remove reference
                );
              }
              return invoiceItem;
            }).toList();

        if (updated) {
          final updatedInvoice = Invoice(
            invoiceId: invoice.invoiceId,
            clientId: invoice.clientId,
            items: updatedItems,
            issueDate: invoice.issueDate,
            dueDate: invoice.dueDate,
            subtotal: invoice.subtotal,
            taxRate: invoice.taxRate,
            taxAmount: invoice.taxAmount,
            total: invoice.total,
            status: invoice.status,
            templateName: invoice.templateName,
            notes: invoice.notes,
            paidDate: invoice.paidDate,
            currency: invoice.currency,
            pdfPath: invoice.pdfPath,
            shareUrl: invoice.shareUrl,
          );

          await _invoiceBox.put(invoice.invoiceId, updatedInvoice);
        }
      }

      // Recalculate all statistics to ensure consistency
      await recalculateAllStatistics();

      // Reload invoices
      _loadInvoices();
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling deleted catalog item in invoices: $e');
    }
  }

  /// Check for overdue invoices and update their status
  Future<void> checkForOverdueInvoices() async {
    try {
      final now = DateTime.now();
      bool anyChanges = false;

      for (final invoice in _invoices) {
        if (invoice.status == 'outstanding') {
          final dueDate = DateTime.parse(invoice.dueDate);
          if (dueDate.isBefore(now)) {
            await updateInvoiceStatus(invoice.invoiceId, 'overdue');
            anyChanges = true;
          }
        }
      }

      if (anyChanges) {
        // Recalculate all statistics to ensure consistency
        await recalculateAllStatistics();

        // Reload invoices
        _loadInvoices();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking for overdue invoices: $e');
    }
  }

  /// Recalculate client statistics for a specific client
  Future<void> recalculateClientStatistics(String clientId) async {
    await _updateClientStatisticsInBackground(clientId);
  }

  /// Recalculate catalog item usage for a specific item
  Future<void> recalculateCatalogItemUsage(String itemTitle) async {
    if (_catalogService == null) return;

    try {
      // Get all invoices containing this catalog item
      int usageCount = 0;

      for (final invoice in _invoices) {
        for (final item in invoice.items) {
          if (item.catalogItemId == itemTitle) {
            usageCount++;
            break; // Count each invoice only once for this item
          }
        }
      }

      // Update the catalog item's usage count
      final catalogItem = _catalogService!.getItemByTitle(itemTitle);
      if (catalogItem != null) {
        final updatedItem = CatalogItem(
          title: catalogItem.title,
          amount: catalogItem.amount,
          quantity: catalogItem.quantity,
          currency: catalogItem.currency,
          usageCount: usageCount,
        );

        await _catalogService!.updateItemSilently(updatedItem);
      }
    } catch (e) {
      debugPrint('Error recalculating catalog item usage: $e');
    }
  }

  /// Update both client statistics and catalog item usage across the entire system
  Future<void> recalculateAllStatistics() async {
    try {
      debugPrint('InvoiceService: Starting full statistics recalculation...');

      // Get access to boxes directly for more efficient updates
      final clientBox = Hive.box<Client>(HiveBoxes.clients);
      final catalogBox = Hive.box<CatalogItem>(HiveBoxes.catalogItems);

      // Ensure we have services to work with
      if (_clientService == null || _catalogService == null) {
        debugPrint(
          'InvoiceService: Missing required services for recalculation',
        );
        return;
      }

      // Get all invoices once to minimize reads
      final allInvoices = _invoiceBox.values.toList();
      debugPrint('InvoiceService: Processing ${allInvoices.length} invoices');

      if (allInvoices.isEmpty) {
        // If no invoices exist, ensure all clients and catalog items have zero counts
        debugPrint('No invoices found, resetting all statistics to zero');

        // Reset all client statistics to zero
        for (final client in clientBox.values) {
          final updatedClient = Client(
            clientId: client.clientId,
            name: client.name,
            type: client.type,
            email: client.email,
            phone: client.phone,
            addressLine1: client.addressLine1,
            addressLine2: client.addressLine2,
            city: client.city,
            state: client.state,
            zipCode: client.zipCode,
            country: client.country,
            invoiceCount: 0,
            amount: 0.0,
            outstandingAmount: 0.0,
            dueAmount: 0.0,
            currency: client.currency,
          );
          await clientBox.put(client.clientId, updatedClient);
          debugPrint('Reset statistics for client: ${client.name}');
        }

        // Reset all catalog item usage counts to zero
        for (final item in catalogBox.values) {
          final updatedItem = CatalogItem(
            title: item.title,
            amount: item.amount,
            quantity: item.quantity,
            currency: item.currency,
            usageCount: 0,
          );
          await catalogBox.put(item.title, updatedItem);
          debugPrint('Reset usage count for catalog item: ${item.title}');
        }

        // Notify listeners to refresh the UI
        notifyListeners();
        _clientService?.notifyListeners();
        _catalogService?.notifyListeners();

        return;
      }

      // Create maps to collect statistics by client and catalog item
      final Map<String, Map<String, dynamic>> clientStats = {};
      final Map<String, int> catalogItemUsage = {};

      // First pass: collect all statistics in memory
      for (final invoice in allInvoices) {
        // Track client statistics
        final clientId = invoice.clientId;
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {
            'invoiceCount': 0,
            'amount': 0.0,
            'outstandingAmount': 0.0,
            'dueAmount': 0.0,
          };
        }

        // Increment invoice count for this client
        clientStats[clientId]!['invoiceCount']++;

        // Update client stats for this invoice
        clientStats[clientId]!['amount'] += invoice.total;

        // Handle outstanding/overdue amounts
        if (invoice.status == 'outstanding') {
          clientStats[clientId]!['outstandingAmount'] += invoice.total;

          // Check if the due date has passed
          final dueDate = DateTime.parse(invoice.dueDate);
          if (dueDate.isBefore(DateTime.now())) {
            clientStats[clientId]!['dueAmount'] += invoice.total;
          }
        } else if (invoice.status == 'overdue') {
          clientStats[clientId]!['outstandingAmount'] += invoice.total;
          clientStats[clientId]!['dueAmount'] += invoice.total;
        }

        // Process items - collect all unique catalog items referenced in this invoice
        Set<String> catalogItemsInThisInvoice = {};

        for (final item in invoice.items) {
          // Update by catalog item ID if available
          if (item.catalogItemId != null && item.catalogItemId!.isNotEmpty) {
            // Add to the set to avoid counting the same item twice in one invoice
            catalogItemsInThisInvoice.add(item.catalogItemId!);
            debugPrint('Found catalog item reference: ${item.catalogItemId}');
          }
        }

        // Now increment usage count for each unique catalog item found in this invoice
        for (final itemId in catalogItemsInThisInvoice) {
          catalogItemUsage[itemId] = (catalogItemUsage[itemId] ?? 0) + 1;
        }
      }

      // Second pass: update clients
      debugPrint(
        'InvoiceService: Updating ${clientStats.length} clients with new statistics',
      );

      // Make sure all clients have statistics (either calculated or zero)
      for (final client in clientBox.values) {
        if (!clientStats.containsKey(client.clientId)) {
          clientStats[client.clientId] = {
            'invoiceCount': 0,
            'amount': 0.0,
            'outstandingAmount': 0.0,
            'dueAmount': 0.0,
          };
        }
      }

      await Future.forEach(clientStats.entries, (entry) async {
        final clientId = entry.key;
        final stats = entry.value;

        final client = clientBox.get(clientId);
        if (client != null) {
          // Create updated client
          final updatedClient = Client(
            clientId: client.clientId,
            name: client.name,
            type: client.type,
            email: client.email,
            phone: client.phone,
            addressLine1: client.addressLine1,
            addressLine2: client.addressLine2,
            city: client.city,
            state: client.state,
            zipCode: client.zipCode,
            country: client.country,
            invoiceCount: stats['invoiceCount'],
            amount: stats['amount'],
            outstandingAmount: stats['outstandingAmount'],
            dueAmount: stats['dueAmount'],
            currency: client.currency,
          );

          // Update in Hive box
          await clientBox.put(clientId, updatedClient);

          debugPrint(
            'InvoiceService: Updated client ${client.name} (${client.clientId}): ' +
                'invoiceCount=${stats['invoiceCount']}, ' +
                'amount=${stats['amount']}',
          );
        }
      });

      // Third pass: update catalog items
      debugPrint(
        'InvoiceService: Updating ${catalogItemUsage.length} catalog items with usage statistics',
      );

      // Make sure all catalog items have usage counts (either calculated or zero)
      for (final item in catalogBox.values) {
        if (!catalogItemUsage.containsKey(item.title)) {
          catalogItemUsage[item.title] = 0;
        }
      }

      await Future.forEach(catalogItemUsage.entries, (entry) async {
        final itemId = entry.key;
        final usageCount = entry.value;

        final item = catalogBox.get(itemId);
        if (item != null) {
          // Create updated item
          final updatedItem = CatalogItem(
            title: item.title,
            amount: item.amount,
            quantity: item.quantity,
            currency: item.currency,
            usageCount: usageCount,
          );

          // Update in Hive box
          await catalogBox.put(itemId, updatedItem);

          debugPrint(
            'InvoiceService: Updated catalog item ${item.title}: usageCount=$usageCount',
          );
        }
      });

      debugPrint(
        'InvoiceService: Statistics recalculation completed successfully',
      );

      // Notify listeners to refresh the UI
      notifyListeners();
      _clientService?.notifyListeners();
      _catalogService?.notifyListeners();

      return;
    } catch (e) {
      debugPrint('ERROR recalculating statistics: $e');
      return;
    }
  }
}
