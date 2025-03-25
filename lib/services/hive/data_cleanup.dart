import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';
import 'package:invoicegenerator/models/hive/client_model.dart';

/// Utility class for cleaning up old test data
class DataCleanup {
  /// Clean up old test data from both SharedPreferences and Hive
  static Future<void> cleanupTestData() async {
    try {
      // Clear SharedPreferences test data
      final prefs = await SharedPreferences.getInstance();

      // Remove old client and catalog data
      await prefs.remove('clients');
      await prefs.remove('catalog_items');

      // Clear corresponding Hive boxes
      await Hive.box(HiveBoxes.clients).clear();
      await Hive.box(HiveBoxes.catalogItems).clear();

      debugPrint('Successfully cleaned up old test data');
    } catch (e) {
      debugPrint('Error cleaning up test data: $e');
    }
  }

  /// Migrate or fix existing client data
  static Future<void> migrateClientData() async {
    try {
      debugPrint('DataCleanup: Migrating client data...');

      // Check if the clients box is open
      if (!Hive.isBoxOpen(HiveBoxes.clients)) {
        debugPrint('DataCleanup: Clients box is not open, opening it...');
        await Hive.openBox<Client>(HiveBoxes.clients);
      }

      final clientBox = Hive.box<Client>(HiveBoxes.clients);
      final companyBox = Hive.box(HiveBoxes.companyInfo);

      // Get company currency or default to USD
      String defaultCurrency = 'USD';
      try {
        if (companyBox.isNotEmpty) {
          final companyInfo = companyBox.getAt(0);
          if (companyInfo != null && companyInfo.currency != null) {
            defaultCurrency = companyInfo.currency;
          }
        }
      } catch (e) {
        debugPrint('DataCleanup: Error getting company currency: $e');
      }

      // Iterate through all clients and ensure they have a currency
      for (int i = 0; i < clientBox.length; i++) {
        try {
          final client = clientBox.getAt(i);
          if (client != null) {
            // Fix clients with missing or null currency
            if (client.currency == null) {
              debugPrint(
                'DataCleanup: Fixing client with null currency: ${client.name}',
              );

              // Create a new client with the default currency
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
                invoiceCount: client.invoiceCount,
                amount: client.amount,
                outstandingAmount: client.outstandingAmount,
                dueAmount: client.dueAmount,
                currency: defaultCurrency,
              );

              // Save the updated client
              await clientBox.put(client.clientId, updatedClient);
            }
          }
        } catch (e) {
          debugPrint('DataCleanup: Error fixing client data at index $i: $e');
        }
      }

      debugPrint('DataCleanup: Client data migration completed');
    } catch (e, stackTrace) {
      debugPrint('ERROR during client data migration: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Force a clean start by deleting all Hive boxes
  static Future<void> forceCleanStart() async {
    try {
      debugPrint('DataCleanup: Force cleaning all data for fresh start...');

      // Close boxes if they're open
      if (Hive.isBoxOpen(HiveBoxes.companyInfo)) {
        await Hive.box(HiveBoxes.companyInfo).close();
      }
      if (Hive.isBoxOpen(HiveBoxes.clients)) {
        await Hive.box(HiveBoxes.clients).close();
      }
      if (Hive.isBoxOpen(HiveBoxes.catalogItems)) {
        await Hive.box(HiveBoxes.catalogItems).close();
      }
      if (Hive.isBoxOpen(HiveBoxes.invoices)) {
        await Hive.box(HiveBoxes.invoices).close();
      }
      if (Hive.isBoxOpen(HiveBoxes.invoiceSettings)) {
        await Hive.box(HiveBoxes.invoiceSettings).close();
      }
      if (Hive.isBoxOpen(HiveBoxes.appPreferences)) {
        await Hive.box(HiveBoxes.appPreferences).close();
      }

      // Delete all boxes
      await HiveConfig.deleteBoxes();

      // Clear SharedPreferences
      debugPrint('DataCleanup: Clearing SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      debugPrint('DataCleanup: Clean start complete, all data has been reset');
      return;
    } catch (e, stackTrace) {
      debugPrint('ERROR during force clean start: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
