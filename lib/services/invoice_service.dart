import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/client_service.dart';
import 'package:invoicegenerator/services/catalog_service.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/services/repository/invoice_repository.dart';

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

  // Repository for Supabase interaction
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  List<Invoice> get invoices => _invoices;

  // Initialization flags to prevent recursive init
  bool _isInitializing = false;
  bool _isInitialized = false;

  // Initialize the service and load data
  Future<void> init() async {
    // Skip if already initialized or initializing
    if (_isInitialized) return;
    if (_isInitializing) {
      debugPrint(
        'InvoiceService - Already initializing, skipping duplicate init call',
      );
      return;
    }

    _isInitializing = true;
    try {
      // Check if user is authenticated
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        // User is authenticated, try to load from Supabase first
        debugPrint('User authenticated, loading invoices from Supabase');
        await _loadInvoicesFromSupabase();
      } else {
        // User not authenticated, load from local storage
        debugPrint(
          'No authenticated user, loading invoices from local storage',
        );
        await _loadInvoices();
      }

      // If there are invoices but no authenticated user, clear them
      if (currentUser == null && _invoices.isNotEmpty) {
        debugPrint(
          'No authenticated user but found invoices - clearing local data',
        );
        _invoices = [];
        await _saveInvoices();
      }

      // Don't trigger statistics update on every initialization
      // Only schedule it if needed (first time or after data change)
      if (_invoices.isNotEmpty) {
        _updateStatisticsInBackground();
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing invoice service: $e');
      // Still try to load from local storage as fallback
      await _loadInvoices();
    } finally {
      _isInitializing = false;
    }
  }

  // Load invoices from Supabase
  Future<void> _loadInvoicesFromSupabase() async {
    try {
      debugPrint('Loading invoices from Supabase');
      final invoicesFromSupabase = await _invoiceRepository.getAllWithItems();

      if (invoicesFromSupabase.isNotEmpty) {
        debugPrint('Found ${invoicesFromSupabase.length} invoices in Supabase');
        _invoices = invoicesFromSupabase;

        // Save to local storage for offline access
        await _saveInvoices();
        notifyListeners();
        return;
      } else {
        debugPrint('No invoices found in Supabase, checking local storage');
        // If no invoices in Supabase, try loading from local
        await _loadInvoices();

        // If we have local invoices, sync them to Supabase
        if (_invoices.isNotEmpty) {
          debugPrint('Found local invoices, syncing to Supabase');
          await _syncInvoicesToSupabase();
        }
      }
    } catch (e) {
      debugPrint('Error loading invoices from Supabase: $e');
      // Fallback to local storage
      await _loadInvoices();
    }
  }

  // Sync all local invoices to Supabase
  Future<void> _syncInvoicesToSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user, skipping Supabase sync');
        return;
      }

      debugPrint('Syncing ${_invoices.length} invoices to Supabase');

      // For each invoice in memory, create or update in Supabase
      for (final invoice in _invoices) {
        try {
          // Ensure invoice has user_id set to current user
          invoice.toMap()['user_id'] = user.id;

          // Create invoice in Supabase with items
          await _invoiceRepository.createWithItems(invoice);
          debugPrint('Invoice ${invoice.invoiceId} synced to Supabase');
        } catch (e) {
          debugPrint('Error syncing invoice ${invoice.invoiceId}: $e');
        }
      }

      debugPrint('Finished syncing invoices to Supabase');
    } catch (e) {
      debugPrint('Error syncing invoices to Supabase: $e');
    }
  }

  // Load invoices from local storage
  Future<void> _loadInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? invoicesJson = prefs.getString(_storageKey);

      if (invoicesJson != null) {
        final List<dynamic> decoded = jsonDecode(invoicesJson);
        _invoices = decoded.map((item) => Invoice.fromMap(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading invoices: $e');
    }
  }

  // Save invoices to local storage
  Future<void> _saveInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> invoicesData =
          _invoices.map((invoice) => invoice.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(invoicesData));
    } catch (e) {
      debugPrint('Error saving invoices: $e');
    }
  }

  // Public method to save invoices (allows external access)
  Future<void> saveInvoices() async {
    try {
      debugPrint(
        'Manual saveInvoices() called - saving ${_invoices.length} invoices',
      );
      await _saveInvoices();
      debugPrint('Manual saveInvoices() completed successfully');
    } catch (e) {
      debugPrint('Error in manual saveInvoices(): $e');
    }
  }

  // Get all invoices
  List<Invoice> getAllInvoices() {
    return List.unmodifiable(_invoices);
  }

  // Get invoices by status
  List<Invoice> getInvoicesByStatus(InvoiceStatus status) {
    return _invoices.where((i) => i.status == status).toList();
  }

  // Get invoice by ID
  Invoice? getInvoiceById(String invoiceId) {
    try {
      return _invoices.firstWhere((invoice) => invoice.invoiceId == invoiceId);
    } catch (e) {
      return null;
    }
  }

  // Generate a new invoice ID
  String generateInvoiceId() {
    // Check if there's an authenticated user first
    final currentUser = Supabase.instance.client.auth.currentUser;
    bool isAuthenticated = currentUser != null;

    // Always start from 1 if no authenticated user or no existing invoices
    int highestNumber = 0;

    // Only use existing numbers if authenticated to prevent ID conflicts between users
    if (isAuthenticated && _invoices.isNotEmpty) {
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
    }

    return 'inv-${(highestNumber + 1).toString().padLeft(3, '0')}';
  }

  // Add a new invoice
  Future<bool> addInvoice(Invoice invoice) async {
    try {
      // Add invoice to the beginning of the list for sorting (newest first)
      _invoices.insert(0, invoice);
      await _saveInvoices();

      // Save to Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Create invoice in Supabase with items
          await _invoiceRepository.createWithItems(invoice);
          debugPrint('Invoice ${invoice.invoiceId} created in Supabase');
        } catch (e) {
          debugPrint('Error creating invoice in Supabase: $e');
        }
      }

      notifyListeners();

      // Schedule statistics update for affected entities
      _updateSelectiveStatistics([
        invoice.client.clientId,
      ], invoice.items.map((item) => item.title).toList());

      return true;
    } catch (e) {
      debugPrint('Error adding invoice: $e');
      return false;
    }
  }

  // Update an existing invoice
  Future<bool> updateInvoice(Invoice updatedInvoice) async {
    try {
      // Find the index of the invoice to update
      final invoiceIndex = _invoices.indexWhere(
        (invoice) => invoice.invoiceId == updatedInvoice.invoiceId,
      );

      if (invoiceIndex != -1) {
        // Replace the old invoice with the updated one
        _invoices[invoiceIndex] = updatedInvoice;
        await _saveInvoices();

        // Update in Supabase if user is authenticated
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            // Find the Supabase ID
            final supabaseInvoices = await _invoiceRepository.getAllWithItems();
            final supabaseInvoice = supabaseInvoices.firstWhere(
              (i) => i.invoiceId == updatedInvoice.invoiceId,
              orElse: () => updatedInvoice,
            );

            if (supabaseInvoice.id != null) {
              // Update invoice in Supabase with items
              await _invoiceRepository.updateWithItems(
                supabaseInvoice.id!,
                updatedInvoice,
              );
              debugPrint(
                'Invoice ${updatedInvoice.invoiceId} updated in Supabase',
              );
            } else {
              // Create if not found
              await _invoiceRepository.createWithItems(updatedInvoice);
              debugPrint(
                'Invoice ${updatedInvoice.invoiceId} created in Supabase (update)',
              );
            }
          } catch (e) {
            debugPrint('Error updating invoice in Supabase: $e');
          }
        }

        notifyListeners();

        // Schedule statistics update for affected entities
        final oldInvoice = _invoices[invoiceIndex];
        _updateSelectiveStatistics(
          [oldInvoice.client.clientId, updatedInvoice.client.clientId],
          [
            ...oldInvoice.items.map((item) => item.title),
            ...updatedInvoice.items.map((item) => item.title),
          ].toList(),
        );

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return false;
    }
  }

  // Delete an invoice
  Future<void> deleteInvoice(String invoiceId) async {
    // Find the invoice to delete first to get its data
    final invoiceToDelete = getInvoiceById(invoiceId);
    if (invoiceToDelete == null) return;

    // Delete from Supabase if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Find the Supabase ID
        final supabaseInvoices = await _invoiceRepository.getAllWithItems();
        final supabaseInvoice = supabaseInvoices.firstWhere(
          (i) => i.invoiceId == invoiceId,
          orElse: () => invoiceToDelete,
        );

        if (supabaseInvoice.id != null) {
          // Delete invoice in Supabase
          await _invoiceRepository.delete(supabaseInvoice.id!);
          debugPrint('Invoice deleted from Supabase');
        }
      } catch (e) {
        debugPrint('Error deleting invoice from Supabase: $e');
      }
    }

    // Remove the invoice from the list
    _invoices.removeWhere((invoice) => invoice.invoiceId == invoiceId);
    await _saveInvoices();
    notifyListeners();

    // Schedule statistics update for affected entities
    _updateSelectiveStatistics([
      invoiceToDelete.client.clientId,
    ], invoiceToDelete.items.map((item) => item.title).toList());
  }

  // Update client information in all invoices when a client is updated
  Future<void> updateClientInInvoices(
    String clientId,
    Client updatedClient,
  ) async {
    bool anyUpdated = false;

    // Update client in all invoices that use this client
    for (int i = 0; i < _invoices.length; i++) {
      final invoice = _invoices[i];
      if (invoice.client.clientId == clientId) {
        // Create updated invoice with new client info
        final updatedInvoice = invoice.copyWith(client: updatedClient);
        _invoices[i] = updatedInvoice;
        anyUpdated = true;

        // Update in Supabase if user is authenticated
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            // Find the Supabase ID - don't wait for this to complete
            _invoiceRepository
                .getAllWithItems()
                .then((supabaseInvoices) {
                  final supabaseInvoice = supabaseInvoices.firstWhere(
                    (i) => i.invoiceId == invoice.invoiceId,
                    orElse: () => updatedInvoice,
                  );

                  if (supabaseInvoice.id != null) {
                    // Update invoice in Supabase with items
                    _invoiceRepository
                        .updateWithItems(supabaseInvoice.id!, updatedInvoice)
                        .then((_) {
                          debugPrint('Invoice client info updated in Supabase');
                        })
                        .catchError((e) {
                          debugPrint('Error updating invoice client info: $e');
                        });
                  }
                })
                .catchError((e) {
                  debugPrint('Error finding invoice in Supabase: $e');
                });
          } catch (e) {
            debugPrint('Error updating invoice client in Supabase: $e');
          }
        }
      }
    }

    // Save changes if any invoices were updated
    if (anyUpdated) {
      await _saveInvoices();
      notifyListeners();
    }
  }

  // Handle a deleted catalog item
  Future<void> handleDeletedCatalogItem(String itemTitle) async {
    bool anyUpdated = false;

    // Loop through all invoices
    for (int i = 0; i < _invoices.length; i++) {
      final invoice = _invoices[i];
      bool invoiceUpdated = false;

      // Filter out the deleted item
      final updatedItems =
          invoice.items.where((item) => item.title != itemTitle).toList();

      // Check if the item list changed
      if (updatedItems.length != invoice.items.length) {
        // Create a new invoice with the updated items
        final updatedInvoice = invoice.copyWith(items: updatedItems);
        _invoices[i] = updatedInvoice;
        invoiceUpdated = true;
        anyUpdated = true;

        // Update in Supabase if user is authenticated
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            // Find the Supabase ID - don't wait for this to complete
            _invoiceRepository
                .getAllWithItems()
                .then((supabaseInvoices) {
                  final supabaseInvoice = supabaseInvoices.firstWhere(
                    (i) => i.invoiceId == invoice.invoiceId,
                    orElse: () => updatedInvoice,
                  );

                  if (supabaseInvoice.id != null) {
                    // Update invoice in Supabase with items
                    _invoiceRepository
                        .updateWithItems(supabaseInvoice.id!, updatedInvoice)
                        .then((_) {
                          debugPrint(
                            'Invoice items updated in Supabase (removed item)',
                          );
                        })
                        .catchError((e) {
                          debugPrint('Error updating invoice items: $e');
                        });
                  }
                })
                .catchError((e) {
                  debugPrint('Error finding invoice in Supabase: $e');
                });
          } catch (e) {
            debugPrint('Error updating invoice items in Supabase: $e');
          }
        }
      }
    }

    // Save changes if any invoices were updated
    if (anyUpdated) {
      await _saveInvoices();
      notifyListeners();
    }
  }

  // Background update statistics for clients and catalog items
  void _updateStatisticsInBackground() {
    Future.delayed(const Duration(seconds: 1), () {
      updateAllStatistics();
    });
  }

  // Update all statistics for clients and catalog items
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
      // Get all clients from service
      final allClients = clientService.clients;
      final List<Client> updatedClients = [];

      // Update statistics for each client
      for (var client in allClients) {
        final clientId = client.clientId;
        final clientInvoices = clientInvoicesMap[clientId] ?? [];

        // Calculate statistics
        final invoiceCount = clientInvoices.length;

        double totalAmount = 0;
        double outstandingAmount = 0;
        double dueAmount = 0;

        for (var invoice in clientInvoices) {
          final total = invoice.total;
          totalAmount += total;

          // Calculate outstanding amount (not paid in full)
          if (invoice.status == InvoiceStatus.outstanding) {
            outstandingAmount += total;
          }

          // Calculate due amount (past due date and not paid in full)
          if (invoice.status == InvoiceStatus.overdue) {
            dueAmount += total;
          }
        }

        // Check flags
        final hasOutstanding = outstandingAmount > 0;
        final hasDue = dueAmount > 0;

        // Create updated client with new statistics
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
      // Get all catalog items
      final allItems = catalogService.getAllItems();

      // Update each item with usage info
      for (var item in allItems) {
        final usageCount = catalogItemUsageMap[item.title] ?? 0;
        final usageInfo = 'USED IN $usageCount INVOICES';
        final isNew = usageCount == 0;

        // Create updated item with new usage info
        final updatedItem = item.copyWith(usageInfo: usageInfo, isNew: isNew);

        // Only update if the usage info changed
        if (updatedItem.usageInfo != item.usageInfo ||
            updatedItem.isNew != item.isNew) {
          await catalogService.updateItem(updatedItem);
        }
      }
    } catch (e) {
      debugPrint('Error updating catalog items batch: $e');
    }
  }

  // Update statistics selectively for specific clients and items
  Future<void> _updateSelectiveStatistics(
    List<String> clientIds,
    List<String> itemTitles,
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
