import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/services/repository/catalog_repository.dart';

class CatalogService with ChangeNotifier {
  // Singleton instance
  static final CatalogService _instance = CatalogService._internal();

  factory CatalogService() {
    return _instance;
  }

  CatalogService._internal();

  // Local storage key
  static const String _storageKey = 'catalog_items';

  // In-memory storage of catalog items
  List<CatalogItem> _catalogItems = [];

  // Repository for Supabase interaction
  final CatalogRepository _catalogRepository = CatalogRepository();

  // Default items for first-time initialization
  final List<CatalogItem> _defaultItems = [];

  // Initialize the service - load catalog items from storage
  Future<void> init() async {
    try {
      // Check if user is authenticated
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        // User is authenticated, try to load from Supabase first
        debugPrint('User authenticated, loading catalog items from Supabase');
        await _loadItemsFromSupabase();
      } else {
        // User not authenticated, load from local storage
        debugPrint(
          'No authenticated user, loading catalog items from local storage',
        );
        await _loadItems();
      }
    } catch (e) {
      debugPrint('Error initializing catalog service: $e');
      // Reset items on error
      _catalogItems = [];
    }
  }

  // Load catalog items from Supabase
  Future<void> _loadItemsFromSupabase() async {
    try {
      debugPrint('Loading catalog items from Supabase');
      final itemsFromSupabase = await _catalogRepository.getAllWithUsage();

      if (itemsFromSupabase.isNotEmpty) {
        debugPrint(
          'Found ${itemsFromSupabase.length} catalog items in Supabase',
        );
        _catalogItems = itemsFromSupabase;

        // Save to local storage for offline access
        await _saveItems();
        notifyListeners();
        return;
      } else {
        debugPrint(
          'No catalog items found in Supabase, checking local storage',
        );
        // If no items in Supabase, try loading from local
        await _loadItems();

        // If we have local items, sync them to Supabase
        if (_catalogItems.isNotEmpty) {
          debugPrint('Found local catalog items, syncing to Supabase');
          await _syncItemsToSupabase();
        }
      }
    } catch (e) {
      debugPrint('Error loading catalog items from Supabase: $e');
      // Fallback to local storage
      await _loadItems();
    }
  }

  // Sync all local catalog items to Supabase
  Future<void> _syncItemsToSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user, skipping Supabase sync');
        return;
      }

      debugPrint('Syncing ${_catalogItems.length} catalog items to Supabase');

      // For each item in memory, create or update in Supabase
      for (final item in _catalogItems) {
        try {
          // Ensure item has user_id set to current user
          final itemWithUserId = item.toMap();
          itemWithUserId['user_id'] = user.id;

          // Convert map back to CatalogItem object
          final itemToSync = CatalogItem.fromMap(itemWithUserId);

          // Create item in Supabase
          await _catalogRepository.create(itemToSync);
          debugPrint('Catalog item ${item.title} synced to Supabase');
        } catch (e) {
          debugPrint('Error syncing catalog item ${item.title}: $e');
        }
      }

      debugPrint('Finished syncing catalog items to Supabase');
    } catch (e) {
      debugPrint('Error syncing catalog items to Supabase: $e');
    }
  }

  // Load catalog items from shared preferences
  Future<void> _loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString(_storageKey);

      if (itemsJson != null) {
        final List<dynamic> decoded = jsonDecode(itemsJson);
        _catalogItems =
            decoded.map((item) => CatalogItem.fromMap(item)).toList();
        notifyListeners();
      } else if (_defaultItems.isNotEmpty) {
        // Initialize with default items if no stored items
        _catalogItems = List.from(_defaultItems);
        await _saveItems();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading catalog items: $e');
    }
  }

  // Save catalog items to shared preferences
  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> itemsData =
          _catalogItems.map((item) => item.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(itemsData));
    } catch (e) {
      debugPrint('Error saving catalog items: $e');
    }
  }

  // Get all catalog items
  List<CatalogItem> getAllItems() {
    return List.unmodifiable(_catalogItems);
  }

  // Add a new catalog item
  Future<void> addItem(CatalogItem item) async {
    // Add to beginning of list for newest items to appear at top
    _catalogItems.insert(0, item);
    await _saveItems();

    // Save to Supabase if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Ensure item has user_id set to current user
        final itemWithUserId = item.toMap();
        itemWithUserId['user_id'] = user.id;

        // Convert map back to CatalogItem object
        final itemToSync = CatalogItem.fromMap(itemWithUserId);

        // Create item in Supabase
        await _catalogRepository.create(itemToSync);
        debugPrint('Catalog item ${item.title} created in Supabase');
      } catch (e) {
        debugPrint('Error creating catalog item in Supabase: $e');
      }
    }

    notifyListeners();
  }

  // Add multiple catalog items
  Future<void> addItems(List<CatalogItem> items) async {
    // Insert items at the beginning of the list
    _catalogItems.insertAll(0, items);
    await _saveItems();

    // Save to Supabase if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        for (final item in items) {
          // Ensure item has user_id set to current user
          final itemWithUserId = item.toMap();
          itemWithUserId['user_id'] = user.id;

          // Convert map back to CatalogItem object
          final itemToSync = CatalogItem.fromMap(itemWithUserId);

          // Create item in Supabase
          await _catalogRepository.create(itemToSync);
        }
        debugPrint('${items.length} catalog items created in Supabase');
      } catch (e) {
        debugPrint('Error creating multiple catalog items in Supabase: $e');
      }
    }

    notifyListeners();
  }

  // Update an existing catalog item
  Future<void> updateItem(CatalogItem item) async {
    final index = _catalogItems.indexWhere(
      (existingItem) => existingItem.title == item.title,
    );

    if (index != -1) {
      _catalogItems[index] = item;
      await _saveItems();

      // Update in Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Find the Supabase ID
          final supabaseItems = await _catalogRepository.getAll();
          final supabaseItem = supabaseItems.firstWhere(
            (i) => i.title == item.title,
            orElse: () => item,
          );

          if (supabaseItem.id != null) {
            // Update item in Supabase
            await _catalogRepository.update(supabaseItem.id!, item);
            debugPrint('Catalog item ${item.title} updated in Supabase');
          } else {
            // Create if not found
            await _catalogRepository.create(item);
            debugPrint(
              'Catalog item ${item.title} created in Supabase (update)',
            );
          }
        } catch (e) {
          debugPrint('Error updating catalog item in Supabase: $e');
        }
      }

      // Update the item in all invoices that use it
      await _updateCatalogItemInInvoices(item);

      notifyListeners();
    }
  }

  // Update all instances of a catalog item in invoices
  Future<void> _updateCatalogItemInInvoices(CatalogItem updatedItem) async {
    // Get the invoice service
    final invoiceService = InvoiceService();
    await invoiceService.init();

    // Get all invoices
    final invoices = invoiceService.getAllInvoices();
    bool anyUpdated = false;

    // Loop through all invoices
    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      bool invoiceUpdated = false;

      // Create a new list of items
      final updatedItems =
          invoice.items.map((item) {
            // If this item matches the updated catalog item (by title)
            if (item.title == updatedItem.title) {
              invoiceUpdated = true;
              // Return the updated catalog item with the same quantity from the invoice
              return updatedItem.copyWith(quantity: item.quantity);
            }
            return item;
          }).toList();

      // If invoice was updated, update it in the service
      if (invoiceUpdated) {
        // Create updated invoice with new items
        final updatedInvoice = invoice.copyWith(items: updatedItems);
        await invoiceService.updateInvoice(updatedInvoice);
        anyUpdated = true;
      }
    }

    // Notify listeners if any invoices were updated
    if (anyUpdated) {
      invoiceService.notifyListeners();
    }
  }

  // Delete a catalog item by title
  Future<void> deleteItem(String title) async {
    // Delete from Supabase if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Find the Supabase ID
        final supabaseItems = await _catalogRepository.getAll();
        final supabaseItem = supabaseItems.firstWhere(
          (i) => i.title == title,
          orElse: () => CatalogItem(title: "", amount: "0", quantity: 0),
        );

        if (supabaseItem.id != null) {
          // Delete item in Supabase
          await _catalogRepository.delete(supabaseItem.id!);
          debugPrint('Catalog item deleted from Supabase');
        }
      } catch (e) {
        debugPrint('Error deleting catalog item from Supabase: $e');
      }
    }

    _catalogItems.removeWhere((item) => item.title == title);
    await _saveItems();

    // Handle deletion in invoices
    final invoiceService = InvoiceService();
    await invoiceService.init();
    await invoiceService.handleDeletedCatalogItem(title);

    notifyListeners();
  }

  // Clear all items (for testing)
  Future<void> clearAll() async {
    _catalogItems.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  // Get item count
  int get itemCount => _catalogItems.length;

  // Search items by title
  List<CatalogItem> searchItems(String query) {
    if (query.isEmpty) {
      return List.unmodifiable(_catalogItems);
    }

    final lowercaseQuery = query.toLowerCase();
    return _catalogItems.where((item) {
      return item.title.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}
