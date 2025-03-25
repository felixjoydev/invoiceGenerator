import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:invoicegenerator/models/hive/catalog_item_model.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';

/// Service for managing catalog items using Hive
class CatalogService extends ChangeNotifier {
  late Box<CatalogItem> _catalogBox;
  bool _isInitialized = false;

  List<CatalogItem> _items = [];
  List<CatalogItem> get items => _items;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await HiveConfig.initialize();
      _catalogBox = Hive.box<CatalogItem>(HiveBoxes.catalogItems);
      _loadItems();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing CatalogService: $e');
      rethrow;
    }
  }

  /// Load catalog items from Hive
  void _loadItems() {
    try {
      // Get all items from the Hive box
      _items = _catalogBox.values.toList();

      // Sort items by title
      _items.sort((a, b) => a.title.compareTo(b.title));
    } catch (e) {
      debugPrint('Error loading catalog items: $e');
      _items = [];
    }
  }

  /// Get a catalog item by title
  CatalogItem? getItemByTitle(String title) {
    try {
      return _catalogBox.get(title);
    } catch (e) {
      debugPrint('Error getting catalog item by title: $e');
      return null;
    }
  }

  /// Add a new catalog item
  Future<bool> addItem(CatalogItem item) async {
    try {
      // Ensure title is unique (title is the key)
      final existingItem = _catalogBox.get(item.title);
      if (existingItem != null) {
        debugPrint('Catalog item with title ${item.title} already exists');
        return false;
      }

      // Save item in Hive using title as key
      await _catalogBox.put(item.title, item);

      // Reload items
      _loadItems();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding catalog item: $e');
      return false;
    }
  }

  /// Update an existing catalog item
  Future<bool> updateItem(CatalogItem item, {String? oldTitle}) async {
    try {
      if (oldTitle != null && oldTitle != item.title) {
        // Title has changed, need to delete old entry and create new one
        await _catalogBox.delete(oldTitle);

        // Update title references in invoices
        await _updateCatalogItemTitleInInvoices(oldTitle, item.title);
      }

      // Save item in Hive using title as key
      await _catalogBox.put(item.title, item);

      // Update item in invoices (price/quantity/etc. changes)
      await _updateCatalogItemInInvoices(item);

      // Reload items
      _loadItems();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating catalog item: $e');
      return false;
    }
  }

  /// Update catalog item without propagating changes to invoices
  Future<bool> updateItemSilently(CatalogItem item) async {
    try {
      // Save item in Hive using title as key
      await _catalogBox.put(item.title, item);

      // Reload items
      _loadItems();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating catalog item silently: $e');
      return false;
    }
  }

  /// Delete a catalog item
  Future<bool> deleteItem(String title) async {
    try {
      // Check if item exists
      final item = _catalogBox.get(title);
      if (item == null) {
        debugPrint('Catalog item with title $title not found');
        return false;
      }

      // Delete item from Hive
      await _catalogBox.delete(title);

      // Handle references in invoices
      await _handleDeletedCatalogItemInInvoices(title);

      // Reload items
      _loadItems();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting catalog item: $e');
      return false;
    }
  }

  /// Search catalog items
  List<CatalogItem> searchItems(String query) {
    if (query.isEmpty) return _items;

    query = query.toLowerCase();
    return _items.where((item) {
      return item.title.toLowerCase().contains(query);
    }).toList();
  }

  /// Update usage count for a catalog item
  Future<void> incrementUsageCount(String title) async {
    try {
      final item = _catalogBox.get(title);
      if (item == null) {
        debugPrint(
          'Catalog item with title "$title" not found for usage increment',
        );
        return;
      }

      debugPrint(
        'Incrementing usage count for "${item.title}" from ${item.usageCount} to ${item.usageCount + 1}',
      );

      final updatedItem = CatalogItem(
        title: item.title,
        amount: item.amount,
        quantity: item.quantity,
        currency: item.currency,
        usageCount: item.usageCount + 1,
      );

      await updateItemSilently(updatedItem);
    } catch (e) {
      debugPrint('Error incrementing usage count: $e');
    }
  }

  /// Update catalog item references in invoices when title changes
  Future<void> _updateCatalogItemTitleInInvoices(
    String oldTitle,
    String newTitle,
  ) async {
    // This will be implemented in the InvoiceService
    // We'll call it from there once we have both services set up
  }

  /// Update catalog item details in invoices
  Future<void> _updateCatalogItemInInvoices(CatalogItem item) async {
    // This will be implemented in the InvoiceService
    // We'll call it from there once we have both services set up
  }

  /// Handle references to deleted catalog item in invoices
  Future<void> _handleDeletedCatalogItemInInvoices(String title) async {
    // This will be implemented in the InvoiceService
    // We'll call it from there once we have both services set up
  }
}
