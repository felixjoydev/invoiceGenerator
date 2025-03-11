import 'package:invoicegenerator/models/catalog_item.dart';

class CatalogService {
  // Singleton instance
  static final CatalogService _instance = CatalogService._internal();

  factory CatalogService() {
    return _instance;
  }

  CatalogService._internal();

  // In-memory storage of catalog items
  final List<CatalogItem> _catalogItems = [
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

  // Get all catalog items
  List<CatalogItem> getAllItems() {
    return List.unmodifiable(_catalogItems);
  }

  // Add a new catalog item at the beginning of the list
  void addItem(CatalogItem item) {
    _catalogItems.insert(0, item);
  }

  // Add multiple catalog items at the beginning of the list
  void addItems(List<CatalogItem> items) {
    _catalogItems.insertAll(0, items);
  }

  // Update an existing catalog item
  void updateItem(CatalogItem updatedItem) {
    final index = _catalogItems.indexWhere(
      (item) => item.title == updatedItem.title,
    );
    if (index != -1) {
      _catalogItems[index] = updatedItem;
    }
  }

  // Delete a catalog item by title
  void deleteItem(String title) {
    _catalogItems.removeWhere((item) => item.title == title);
  }

  // Clear all items (for testing)
  void clearAll() {
    _catalogItems.clear();
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
