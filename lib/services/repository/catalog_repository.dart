import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/services/repository/supabase_repository.dart';
import 'package:uuid/uuid.dart';

class CatalogRepository extends SupabaseRepository<CatalogItem> {
  static final CatalogRepository _instance = CatalogRepository._internal();

  factory CatalogRepository() {
    return _instance;
  }

  CatalogRepository._internal();

  @override
  String get tableName => 'catalog_items';

  @override
  CatalogItem fromJson(Map<String, dynamic> json) {
    return CatalogItem.fromMap(json);
  }

  @override
  Map<String, dynamic> toJson(CatalogItem item) {
    final map = item.toMap();

    // Make sure we have a user_id
    if (map['user_id'] == null) {
      map['user_id'] = currentUser?.id;
    }

    // Make sure we have an item_id
    if (map['item_id'] == null || map['item_id'].isEmpty) {
      map['item_id'] = const Uuid().v4();
    }

    // Generate an ID if it's null - Supabase requires a non-null ID for insert
    if (map['id'] == null) {
      map['id'] = const Uuid().v4();
    }

    // Remove fields that don't exist in the database
    map.remove('is_new');
    map.remove('usage_info');
    map.remove('quantity');

    return map;
  }

  /// Get all catalog items with usage info
  Future<List<CatalogItem>> getAllWithUsage() async {
    try {
      // First get all catalog items
      final items = await getAll();

      // Then fetch usage statistics for each item
      final List<CatalogItem> enrichedItems = [];
      for (final item in items) {
        final usageCount = await _getItemUsage(item.id!);
        final usageInfo = 'USED IN $usageCount INVOICES';

        enrichedItems.add(
          item.copyWith(usageInfo: usageInfo, isNew: usageCount == 0),
        );
      }

      return enrichedItems;
    } catch (e) {
      debugPrint('Error fetching catalog items with usage: $e');
      rethrow;
    }
  }

  /// Get usage count for a catalog item
  Future<int> _getItemUsage(String itemId) async {
    try {
      // Count how many invoice items reference this catalog item by title
      final item =
          await supabase
              .from(tableName)
              .select('title')
              .eq('id', itemId)
              .single();

      if (item == null) return 0;

      final title = item['title'];

      // Count invoice items with this title
      final response = await supabase
          .from('invoice_items')
          .select('id')
          .eq('title', title);

      return response.length;
    } catch (e) {
      debugPrint('Error getting item usage: $e');
      return 0;
    }
  }
}
