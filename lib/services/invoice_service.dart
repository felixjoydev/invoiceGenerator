import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/client_service.dart';
import 'package:invoicegenerator/services/catalog_service.dart';
import 'package:invoicegenerator/models/catalog_item.dart';

class InvoiceService with ChangeNotifier {
  // Singleton pattern
  static final InvoiceService _instance = InvoiceService._internal();

  factory InvoiceService() {
    return _instance;
  }

  InvoiceService._internal();

  // Local storage key
  static const String _storageKey = 'invoices';

  // In-memory storage for invoices
  List<Invoice> _invoices = [];

  List<Invoice> get invoices => _invoices;

  // Initialize the service and load data
  Future<void> init() async {
    try {
      await _loadInvoices();
      // Don't trigger statistics update on every initialization
      // Only schedule it if needed (first time or after data change)
      if (_invoices.isNotEmpty) {
        _updateStatisticsInBackground();
      }
      return;
    } catch (e) {
      debugPrint('Error initializing invoice service: $e');
      _invoices = [];
    }
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

      // Update statistics in the background
      _updateStatisticsForInvoiceChangesInBackground(invoice);

      notifyListeners();
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
        // Get old invoice for reference
        final oldInvoice = _invoices[index];

        // Update the invoice
        _invoices[index] = invoice;
        await _saveInvoices();

        // Update statistics in the background
        _updateStatisticsForInvoiceChangesInBackground(
          invoice,
          oldInvoice: oldInvoice,
        );

        notifyListeners();
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
      // Find the invoice index
      final index = _invoices.indexWhere((i) => i.invoiceId == invoiceId);

      // If found, get invoice before removing
      if (index >= 0) {
        final invoiceToDelete = _invoices[index];

        // Remove the invoice
        _invoices.removeAt(index);
        await _saveInvoices();

        // Update statistics in the background
        _updateStatisticsForDeletedInvoiceInBackground(invoiceToDelete);

        notifyListeners();
        return true;
      }

      return false;
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

  // Update client information in all invoices referencing this client
  Future<void> updateClientInInvoices(
    String clientId,
    Client updatedClient,
  ) async {
    // Don't update if client ID is empty
    if (clientId.isEmpty) return;

    bool anyUpdated = false;

    // Loop through all invoices to find ones with matching client ID
    List<Invoice> updatedInvoices = [];

    for (int i = 0; i < _invoices.length; i++) {
      if (_invoices[i].client.clientId == clientId) {
        // Create a new invoice with updated client information
        final updatedInvoice = _invoices[i].copyWith(client: updatedClient);
        updatedInvoices.add(updatedInvoice);
        anyUpdated = true;
      } else {
        updatedInvoices.add(_invoices[i]);
      }
    }

    // Save invoices if any were updated
    if (anyUpdated) {
      _invoices = updatedInvoices;
      await _saveInvoices();
      notifyListeners();
    }
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

  // Handle deleted catalog item
  Future<void> handleDeletedCatalogItem(String itemTitle) async {
    bool anyUpdated = false;

    // Loop through all invoices to remove the deleted catalog item
    for (int i = 0; i < _invoices.length; i++) {
      final invoice = _invoices[i];
      final originalItems = invoice.items;

      // Filter out the deleted item
      final updatedItems =
          originalItems.where((item) => item.title != itemTitle).toList();

      // If items were removed, update the invoice
      if (updatedItems.length != originalItems.length) {
        // Recalculate invoice totals
        double subtotal = updatedItems.fold(
          0,
          (sum, item) =>
              sum + (double.tryParse(item.amount) ?? 0) * item.quantity,
        );
        double taxAmount = subtotal * (invoice.taxRate / 100);
        double total = subtotal + taxAmount;

        // Create updated invoice
        final updatedInvoice = invoice.copyWith(
          items: updatedItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          total: total,
        );

        // Update the invoice in the list
        _invoices[i] = updatedInvoice;
        anyUpdated = true;
      }
    }

    // Save invoices if any were updated
    if (anyUpdated) {
      await _saveInvoices();
      notifyListeners();
    }
  }

  // Get all invoices
  List<Invoice> getAllInvoices() {
    return List<Invoice>.from(_invoices);
  }

  // Update statistics in the background
  void _updateStatisticsInBackground() {
    // Use a longer delay to prevent UI freezing
    Future<void>.delayed(const Duration(seconds: 2), () async {
      try {
        // Add a guard flag to prevent concurrent updates
        await updateAllStatistics();
      } catch (e) {
        debugPrint('Background statistics update error: $e');
      }
    });
  }

  // Update statistics for all clients and catalog items
  Future<void> updateAllStatistics() async {
    try {
      // Load services but don't wait for them to initialize their data
      final clientService = ClientService();
      final catalogService = CatalogService();

      // First collect all data needed for updates to reduce service calls
      final Map<String, List<Invoice>> clientInvoicesMap = {};
      final Map<String, int> catalogItemUsageMap = {};

      // Group invoices by client and count catalog item usage
      for (var invoice in _invoices) {
        // Group by client
        final clientId = invoice.client.clientId;
        if (!clientInvoicesMap.containsKey(clientId)) {
          clientInvoicesMap[clientId] = [];
        }
        clientInvoicesMap[clientId]!.add(invoice);

        // Count catalog item usage
        for (var item in invoice.items) {
          if (item.title.isNotEmpty) {
            catalogItemUsageMap[item.title] =
                (catalogItemUsageMap[item.title] ?? 0) + 1;
          }
        }
      }

      // Initialize services in parallel but don't block if they take too long
      await Future.wait([
        clientService.init().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        ),
        catalogService.init().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        ),
      ]);

      // Update clients
      await _updateClientsStatisticsBatch(clientInvoicesMap, clientService);

      // Update catalog items
      await _updateCatalogItemsBatch(catalogItemUsageMap, catalogService);
    } catch (e) {
      debugPrint('Error updating all statistics: $e');
    }
  }

  // Update clients in a single batch
  Future<void> _updateClientsStatisticsBatch(
    Map<String, List<Invoice>> clientInvoicesMap,
    ClientService clientService,
  ) async {
    try {
      // Skip if no clients to update
      if (clientInvoicesMap.isEmpty) return;

      // Get clients only once - with empty fallback
      final clients = clientService.clients;
      if (clients.isEmpty) return;

      final List<Client> updatedClients = [];
      final Set<String> updatedClientIds = {};

      // Process each client
      for (var entry in clientInvoicesMap.entries) {
        final clientId = entry.key;
        if (clientId.isEmpty) continue;

        final clientInvoices = entry.value;
        if (clientInvoices.isEmpty) continue;

        // Find client
        final clientIndex = clients.indexWhere((c) => c.clientId == clientId);
        if (clientIndex < 0 || updatedClientIds.contains(clientId)) continue;

        final client = clients[clientIndex];
        updatedClientIds.add(clientId);

        // Calculate statistics
        final invoiceCount = clientInvoices.length;
        double totalAmount = 0;
        double outstandingAmount = 0;
        double dueAmount = 0;
        bool hasOutstanding = false;
        bool hasDue = false;

        for (var invoice in clientInvoices) {
          totalAmount += invoice.total;

          if (invoice.status == InvoiceStatus.outstanding) {
            outstandingAmount += invoice.total;
            hasOutstanding = true;
          } else if (invoice.status == InvoiceStatus.overdue) {
            dueAmount += invoice.total;
            hasDue = true;
          }
        }

        // Create updated client
        final updatedClient = Client(
          name: client.name,
          clientId: client.clientId,
          taxId: client.taxId,
          country: client.country,
          addressLine1: client.addressLine1,
          addressLine2: client.addressLine2,
          city: client.city,
          zip: client.zip,
          phone: client.phone,
          email: client.email,
          website: client.website,
          notes: client.notes,
          type: client.type,
          invoiceCount: invoiceCount,
          currency: client.currency,
          amount: totalAmount,
          outstandingAmount: outstandingAmount,
          hasOutstanding: hasOutstanding,
          dueAmount: dueAmount,
          hasDue: hasDue,
        );

        updatedClients.add(updatedClient);
      }

      // Update all clients but avoid triggering recursive updates
      for (var client in updatedClients) {
        // Use internal update to avoid circular dependency
        await clientService.updateClientSilently(client.clientId, client);
      }
    } catch (e) {
      debugPrint('Error updating client statistics batch: $e');
    }
  }

  // Update catalog items in a single batch
  Future<void> _updateCatalogItemsBatch(
    Map<String, int> catalogItemUsageMap,
    CatalogService catalogService,
  ) async {
    try {
      // Skip if no items to update
      if (catalogItemUsageMap.isEmpty) return;

      // Get all items at once - with empty fallback
      final allItems = catalogService.getAllItems();
      if (allItems.isEmpty) return;

      final List<CatalogItem> updatedItems = [];

      // Process each item
      for (var entry in catalogItemUsageMap.entries) {
        final title = entry.key;
        if (title.isEmpty) continue;

        final usageCount = entry.value;

        // Find item
        final itemIndex = allItems.indexWhere((item) => item.title == title);
        if (itemIndex < 0) continue;

        final item = allItems[itemIndex];
        final updatedItem = item.copyWith(
          usageInfo: 'USED IN $usageCount INVOICES',
        );

        updatedItems.add(updatedItem);
      }

      // Update all items but avoid triggering circular updates
      for (var item in updatedItems) {
        // Use internal update to avoid circular dependency
        await catalogService.updateItemSilently(item);
      }
    } catch (e) {
      debugPrint('Error updating catalog items batch: $e');
    }
  }

  // Update statistics for invoice changes in the background
  void _updateStatisticsForInvoiceChangesInBackground(
    Invoice invoice, {
    Invoice? oldInvoice,
  }) {
    // Schedule after a delay to avoid blocking UI
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Get clients and items to update
        final Set<String> clientIds = {invoice.client.clientId};
        if (oldInvoice != null &&
            oldInvoice.client.clientId != invoice.client.clientId) {
          clientIds.add(oldInvoice.client.clientId);
        }

        final Set<String> itemTitles = {};
        for (var item in invoice.items) {
          if (item.title.isNotEmpty) {
            itemTitles.add(item.title);
          }
        }

        if (oldInvoice != null) {
          for (var item in oldInvoice.items) {
            if (item.title.isNotEmpty) {
              itemTitles.add(item.title);
            }
          }
        }

        // Perform a minimal update with only affected clients and items
        await _updateSelectiveStatistics(clientIds, itemTitles);
      } catch (e) {
        debugPrint('Error in background invoice changes update: $e');
      }
    });
  }

  // Update statistics for deleted invoice in the background
  void _updateStatisticsForDeletedInvoiceInBackground(Invoice deletedInvoice) {
    // Schedule after a delay to avoid blocking UI
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final Set<String> clientIds = {deletedInvoice.client.clientId};

        final Set<String> itemTitles = {};
        for (var item in deletedInvoice.items) {
          if (item.title.isNotEmpty) {
            itemTitles.add(item.title);
          }
        }

        // Update only affected data
        await _updateSelectiveStatistics(clientIds, itemTitles);
      } catch (e) {
        debugPrint('Error in background deleted invoice update: $e');
      }
    });
  }

  // Update only specific clients and items
  Future<void> _updateSelectiveStatistics(
    Set<String> clientIds,
    Set<String> itemTitles,
  ) async {
    try {
      // Get services
      final clientService = ClientService();
      final catalogService = CatalogService();

      // Initialize services with timeout
      await Future.wait([
        clientService.init().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        ),
        catalogService.init().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        ),
      ]);

      // Prepare client data
      final Map<String, List<Invoice>> clientInvoicesMap = {};
      for (var clientId in clientIds) {
        clientInvoicesMap[clientId] =
            _invoices.where((i) => i.client.clientId == clientId).toList();
      }

      // Prepare catalog item data
      final Map<String, int> catalogItemUsageMap = {};
      for (var title in itemTitles) {
        int usageCount = 0;
        for (var invoice in _invoices) {
          if (invoice.items.any((item) => item.title == title)) {
            usageCount++;
          }
        }
        catalogItemUsageMap[title] = usageCount;
      }

      // Update data
      await _updateClientsStatisticsBatch(clientInvoicesMap, clientService);
      await _updateCatalogItemsBatch(catalogItemUsageMap, catalogService);
    } catch (e) {
      debugPrint('Error in selective statistics update: $e');
    }
  }
}
