import 'package:invoicegenerator/models/catalog_item.dart' as ui;
import 'package:invoicegenerator/models/hive/catalog_item_model.dart';

/// Adapter class to convert between UI CatalogItem and Hive CatalogItem
class CatalogItemAdapter {
  /// Convert from Hive CatalogItem to UI CatalogItem
  static ui.CatalogItem toUICatalogItem(CatalogItem hiveItem) {
    return ui.CatalogItem(
      title: hiveItem.title,
      amount: hiveItem.amount.toString(),
      quantity: hiveItem.quantity,
      currency: hiveItem.currency,
      usageInfo: 'USED IN ${hiveItem.usageCount} INVOICES',
    );
  }

  /// Convert from UI CatalogItem to Hive CatalogItem
  static CatalogItem toHiveCatalogItem(ui.CatalogItem uiItem) {
    // Extract numeric value from amount string (removing currency symbols, etc)
    String amountStr = uiItem.amount.replaceAll(RegExp(r'[^\d.]'), '');

    return CatalogItem(
      title: uiItem.title,
      amount: double.tryParse(amountStr) ?? 0.0,
      quantity: uiItem.quantity,
      currency: uiItem.currency,
      usageCount: 0, // Default to 0 as we don't track this in UI items
    );
  }
}
