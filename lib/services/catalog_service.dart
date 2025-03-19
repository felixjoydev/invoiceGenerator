import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/services/invoice_service.dart';

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

  // Default items for first-time initialization
  final List<CatalogItem> _defaultItems = [
    // Pre-populated sample items
    CatalogItem(
      title: 'Website Design',
      amount: '4500.00',
      quantity: 1,
      usageInfo: 'USED IN 3 INVOICES',
    ),
    CatalogItem(
      title: 'Logo Design',
      amount: '1500.00',
      quantity: 1,
      usageInfo: 'USED IN 2 INVOICES',
    ),
    CatalogItem(
      title: 'Mobile App Development',
      amount: '8000.00',
      quantity: 1,
      usageInfo: 'USED IN 5 INVOICES',
    ),
    CatalogItem(
      title: 'SEO Services',
      amount: '2000.00',
      quantity: 1,
      usageInfo: 'USED IN 4 INVOICES',
    ),
  ];

  // Initialize the service - load catalog items from storage
  Future<void> init() async {
    await _loadItems();
  }

  // Load catalog items from shared preferences
  Future<void> _loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString(_storageKey);

      if (itemsJson != null) {
        final List<dynamic> itemsData = jsonDecode(itemsJson);

        // Clear existing items
        _catalogItems = [];

        // Convert each item to a CatalogItem object
        for (var itemData in itemsData) {
          try {
            // Make sure itemData is a Map<String, dynamic>
            if (itemData is Map) {
              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(
                itemData,
              );

              // Create and add the CatalogItem object
              _catalogItems.add(CatalogItem.fromMap(itemMap));
            }
          } catch (e) {
            debugPrint('Error converting catalog item data: $e');
          }
        }
      } else {
        // If no data in storage, use default items
        _catalogItems = List.from(_defaultItems);
        // Save the default items to storage
        await _saveItems();
      }
    } catch (e) {
      debugPrint('Error loading catalog items: $e');
      // Initialize with default items if there's an error
      _catalogItems = List.from(_defaultItems);
    }

    // Notify listeners about the updated data
    notifyListeners();
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

  // Add a new catalog item at the beginning of the list
  Future<void> addItem(CatalogItem item) async {
    _catalogItems.insert(0, item);
    await _saveItems();
    notifyListeners();
  }

  // Add multiple catalog items at the beginning of the list
  Future<void> addItems(List<CatalogItem> items) async {
    _catalogItems.insertAll(0, items);
    await _saveItems();
    notifyListeners();
  }

  // Update an existing catalog item
  Future<void> updateItem(CatalogItem updatedItem) async {
    final index = _catalogItems.indexWhere(
      (item) => item.title == updatedItem.title,
    );
    if (index != -1) {
      _catalogItems[index] = updatedItem;
      await _saveItems();

      // Update this catalog item in all invoices
      await _updateCatalogItemInInvoices(updatedItem);

      notifyListeners();
    }
  }

  // Update a catalog item without triggering invoice updates (to prevent circular dependencies)
  Future<void> updateItemSilently(CatalogItem updatedItem) async {
    final index = _catalogItems.indexWhere(
      (item) => item.title == updatedItem.title,
    );
    if (index != -1) {
      _catalogItems[index] = updatedItem;
      await _saveItems();
      notifyListeners();
    }
  }

  // Update catalog item in all invoices
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
      return getAllItems();
    }

    final lowerQuery = query.toLowerCase();
    return _catalogItems
        .where((item) => item.title.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
