import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/services/mcp/storage_service_factory.dart';
import 'package:invoicegenerator/services/invoice_service.dart';

class CatalogService with ChangeNotifier {
  // Singleton instance
  static final CatalogService _instance = CatalogService._internal();

  factory CatalogService() {
    return _instance;
  }

  CatalogService._internal();

  // In-memory storage of catalog items
  List<CatalogItem> _catalogItems = [];

  // Storage service factory
  final _storageFactory = StorageServiceFactory();

  // Initialize the service - load catalog items from storage
  Future<void> init() async {
    await _loadItems();
  }

  // Load catalog items from storage
  Future<void> _loadItems() async {
    try {
      await _storageFactory.init();

      // Force clear local data to ensure no default items
      if (_storageFactory.currentStorageType == StorageType.local) {
        await _storageFactory.service.clearClientAndCatalogData();
      }

      _catalogItems = await _storageFactory.service.getCatalogItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading catalog items: $e');
      _catalogItems = [];
      notifyListeners();
    }
  }

  // Get all catalog items
  List<CatalogItem> getAllItems() {
    return List.unmodifiable(_catalogItems);
  }

  // Add a new catalog item at the beginning of the list
  Future<void> addItem(CatalogItem item) async {
    try {
      await _storageFactory.service.createItem(item);
      await _loadItems(); // Refresh list
    } catch (e) {
      debugPrint('Error adding catalog item: $e');
    }
  }

  // Add multiple catalog items at the beginning of the list
  Future<void> addItems(List<CatalogItem> items) async {
    try {
      for (var item in items) {
        await _storageFactory.service.createItem(item);
      }
      await _loadItems(); // Refresh list
    } catch (e) {
      debugPrint('Error adding multiple catalog items: $e');
    }
  }

  // Update an existing catalog item
  Future<void> updateItem(CatalogItem updatedItem) async {
    try {
      await _storageFactory.service.updateItem(updatedItem.title, updatedItem);
      await _loadItems(); // Refresh list
    } catch (e) {
      debugPrint('Error updating catalog item: $e');
    }
  }

  // Update a catalog item without triggering invoice updates (to prevent circular dependencies)
  Future<void> updateItemSilently(CatalogItem updatedItem) async {
    try {
      final index = _catalogItems.indexWhere(
        (item) => item.title == updatedItem.title,
      );
      if (index != -1) {
        _catalogItems[index] = updatedItem;
        notifyListeners();

        // Update storage without triggering cascade
        await _storageFactory.service.updateItem(
          updatedItem.title,
          updatedItem,
        );
      }
    } catch (e) {
      debugPrint('Error silently updating catalog item: $e');
    }
  }

  // Delete a catalog item by title
  Future<void> deleteItem(String title) async {
    try {
      await _storageFactory.service.deleteItem(title);
      await _loadItems(); // Refresh list
    } catch (e) {
      debugPrint('Error deleting catalog item: $e');
    }
  }

  // Check if a title is unique
  Future<bool> isTitleUnique(String title) async {
    return await _storageFactory.service.isItemTitleUnique(title);
  }

  // Clear all items (for testing)
  Future<void> clearAll() async {
    // This is a destructive operation that only affects local storage
    // We don't provide this for remote storage for safety
    if (_storageFactory.currentStorageType == StorageType.local) {
      _catalogItems.clear();
      notifyListeners();
    }
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
