import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:invoicegenerator/models/hive/company_info_model.dart';
import 'package:invoicegenerator/models/hive/client_model.dart';
import 'package:invoicegenerator/models/hive/catalog_item_model.dart';
import 'package:invoicegenerator/models/hive/invoice_model.dart';
import 'package:invoicegenerator/models/hive/invoice_settings_model.dart';
import 'package:invoicegenerator/models/hive/invoice_item_model.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';
import 'package:invoicegenerator/services/hive/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:invoicegenerator/models/client.dart' as old_model;
import 'package:invoicegenerator/models/catalog_item.dart' as old_model;
import 'package:invoicegenerator/models/invoice.dart' as old_model;

/// Service for managing migration from SharedPreferences to Hive
class MigrationService {
  static const String MIGRATION_KEY = 'migration_completed';

  /// Check if migration has been completed
  static Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(MIGRATION_KEY) ?? false;
  }

  /// Run the migration from SharedPreferences to Hive
  static Future<bool> migrateToHive() async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Reset migration flag to ensure we perform a clean migration
      await prefs.setBool(MIGRATION_KEY, false);

      // Check if migration has already been completed
      if (await isMigrationCompleted()) {
        debugPrint('Migration already completed');
        return true;
      }

      // Ensure Hive is initialized
      await HiveConfig.initialize();

      // Migrate company info
      await _migrateCompanyInfo(prefs);

      // Migrate clients
      await _migrateClients(prefs);

      // Migrate catalog items
      await _migrateCatalogItems(prefs);

      // Migrate invoice settings
      await _migrateInvoiceSettings(prefs);

      // Migrate invoices (must be done after clients and catalog items)
      await _migrateInvoices(prefs);

      // Mark migration as completed
      await prefs.setBool(MIGRATION_KEY, true);

      debugPrint('Migration to Hive completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error during migration: $e');
      return false;
    }
  }

  /// Migrate Company Info from SharedPreferences to Hive
  static Future<void> _migrateCompanyInfo(SharedPreferences prefs) async {
    try {
      final companyBox = Hive.box<CompanyInfo>(HiveBoxes.companyInfo);

      // Check if SharedPreferences has company info
      final companyJson = prefs.getString('company_info');
      if (companyJson != null && companyJson.isNotEmpty) {
        // Parse JSON data
        final companyData = json.decode(companyJson) as Map<String, dynamic>;

        // Create a CompanyInfo object
        final companyInfo = CompanyInfo.fromJson(companyData);

        // Save to Hive box with fixed key (0 for singleton)
        await companyBox.put(0, companyInfo);

        debugPrint('Migrated company info: ${companyInfo.businessName}');
      } else {
        // Create empty company info if none exists
        final emptyCompanyInfo = CompanyInfo.empty();
        await companyBox.put(0, emptyCompanyInfo);
        debugPrint('Created empty company info');
      }
    } catch (e) {
      debugPrint('Error migrating company info: $e');
      rethrow;
    }
  }

  /// Migrate Clients from SharedPreferences to Hive
  static Future<void> _migrateClients(SharedPreferences prefs) async {
    try {
      final clientBox = Hive.box<Client>(HiveBoxes.clients);

      // Skip migrating old test clients
      debugPrint('Skipping migration of old test clients');

      // Instead, initialize with empty clients list
      await prefs.remove('clients');
      debugPrint('No clients to migrate');
    } catch (e) {
      debugPrint('Error migrating clients: $e');
      rethrow;
    }
  }

  /// Migrate Catalog Items from SharedPreferences to Hive
  static Future<void> _migrateCatalogItems(SharedPreferences prefs) async {
    try {
      final catalogBox = Hive.box<CatalogItem>(HiveBoxes.catalogItems);

      // Skip migrating old test catalog items
      debugPrint('Skipping migration of old test catalog items');

      // Instead, initialize with empty catalog items list
      await prefs.remove('catalog_items');
      debugPrint('No catalog items to migrate');
    } catch (e) {
      debugPrint('Error migrating catalog items: $e');
      rethrow;
    }
  }

  /// Migrate Invoice Settings from SharedPreferences to Hive
  static Future<void> _migrateInvoiceSettings(SharedPreferences prefs) async {
    try {
      final settingsBox = Hive.box<InvoiceSettings>(HiveBoxes.invoiceSettings);

      // Check if SharedPreferences has invoice settings
      final settingsJson = prefs.getString('invoice_settings');
      if (settingsJson != null && settingsJson.isNotEmpty) {
        // Parse JSON data
        final settingsData = json.decode(settingsJson) as Map<String, dynamic>;

        // Create an InvoiceSettings object
        final settings = InvoiceSettings.fromJson(settingsData);

        // Save to Hive box with fixed key (0 for singleton)
        await settingsBox.put(0, settings);

        debugPrint('Migrated invoice settings');
      } else {
        // Create default settings if none exist
        final defaultSettings = InvoiceSettings.defaultSettings();
        await settingsBox.put(0, defaultSettings);
        debugPrint('Created default invoice settings');
      }
    } catch (e) {
      debugPrint('Error migrating invoice settings: $e');
      rethrow;
    }
  }

  /// Migrate Invoices from SharedPreferences to Hive
  static Future<void> _migrateInvoices(SharedPreferences prefs) async {
    try {
      final invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);

      // Check if SharedPreferences has invoices
      final invoicesJson = prefs.getString('invoices');
      if (invoicesJson != null && invoicesJson.isNotEmpty) {
        // Parse JSON data
        final invoicesList = json.decode(invoicesJson) as List;

        // Convert and save each invoice
        for (final invoiceData in invoicesList) {
          final invoice = Invoice.fromJson(invoiceData);

          // Use invoiceId as the key
          await invoiceBox.put(invoice.invoiceId, invoice);
          debugPrint('Migrated invoice: ${invoice.invoiceId}');
        }

        debugPrint('Migrated ${invoicesList.length} invoices');
      } else {
        debugPrint('No invoices to migrate');
      }
    } catch (e) {
      debugPrint('Error migrating invoices: $e');
      rethrow;
    }
  }

  /// Create a backup of all data in Hive
  static Future<String?> createBackup() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupData = <String, dynamic>{
        'timestamp': timestamp,
        'version': 1,
        'data': {
          HiveBoxes.companyInfo: await _exportBox<CompanyInfo>(
            HiveBoxes.companyInfo,
          ),
          HiveBoxes.clients: await _exportBox<Client>(HiveBoxes.clients),
          HiveBoxes.catalogItems: await _exportBox<CatalogItem>(
            HiveBoxes.catalogItems,
          ),
          HiveBoxes.invoices: await _exportBox<Invoice>(HiveBoxes.invoices),
          HiveBoxes.invoiceSettings: await _exportBox<InvoiceSettings>(
            HiveBoxes.invoiceSettings,
          ),
          HiveBoxes.appPreferences: await _exportBox(HiveBoxes.appPreferences),
        },
      };

      final backupJson = json.encode(backupData);

      // For web platform, we can only return the string
      if (kIsWeb) {
        return backupJson;
      }

      // For other platforms, save to file
      final directory = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/backups',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = '${directory.path}/invoice_backup_$timestamp.json';
      final file = File(filePath);
      await file.writeAsString(backupJson);

      debugPrint('Backup created at: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return null;
    }
  }

  /// Restore data from a backup
  static Future<bool> restoreFromBackup(String backupContent) async {
    try {
      // Parse backup content
      final backupData = json.decode(backupContent) as Map<String, dynamic>;
      final version = backupData['version'] as int;

      // Validate backup version
      if (version != 1) {
        debugPrint('Unsupported backup version: $version');
        return false;
      }

      // Get data section
      final data = backupData['data'] as Map<String, dynamic>;

      // Restore each box
      await _importBox<CompanyInfo>(
        HiveBoxes.companyInfo,
        data[HiveBoxes.companyInfo],
      );
      await _importBox<Client>(HiveBoxes.clients, data[HiveBoxes.clients]);
      await _importBox<CatalogItem>(
        HiveBoxes.catalogItems,
        data[HiveBoxes.catalogItems],
      );
      await _importBox<InvoiceSettings>(
        HiveBoxes.invoiceSettings,
        data[HiveBoxes.invoiceSettings],
      );
      await _importBox<Invoice>(HiveBoxes.invoices, data[HiveBoxes.invoices]);
      await _importBox(
        HiveBoxes.appPreferences,
        data[HiveBoxes.appPreferences],
      );

      debugPrint('Backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      return false;
    }
  }

  /// Export box data to a Map for backup
  static Future<Map<String, dynamic>> _exportBox<T>(String boxName) async {
    final box = Hive.box<T>(boxName);
    final data = <String, dynamic>{};

    for (final key in box.keys) {
      final item = box.get(key);
      if (item != null) {
        if (item is CompanyInfo ||
            item is Client ||
            item is CatalogItem ||
            item is Invoice ||
            item is InvoiceSettings ||
            item is InvoiceItem) {
          // Use dynamic cast to access toJson method for typed objects
          final typedItem = item as dynamic;
          data[key.toString()] = typedItem.toJson();
        } else {
          // For raw values
          data[key.toString()] = item;
        }
      }
    }

    return data;
  }

  /// Import data from a backup into a box
  static Future<void> _importBox<T>(String boxName, dynamic boxData) async {
    if (boxData == null) return;

    final box = Hive.box<T>(boxName);
    await box.clear();

    for (final entry in (boxData as Map<String, dynamic>).entries) {
      final key = entry.key;
      final value = entry.value;

      // Use dynamic typing to handle specific model types
      if (boxName == HiveBoxes.companyInfo) {
        await box.put(int.parse(key), CompanyInfo.fromJson(value) as dynamic);
      } else if (boxName == HiveBoxes.clients) {
        await box.put(key, Client.fromJson(value) as dynamic);
      } else if (boxName == HiveBoxes.catalogItems) {
        await box.put(key, CatalogItem.fromJson(value) as dynamic);
      } else if (boxName == HiveBoxes.invoices) {
        await box.put(key, Invoice.fromJson(value) as dynamic);
      } else if (boxName == HiveBoxes.invoiceSettings) {
        await box.put(
          int.parse(key),
          InvoiceSettings.fromJson(value) as dynamic,
        );
      } else {
        // For raw values
        await box.put(key, value);
      }
    }
  }

  /// Force recalculation of all statistics (clients and catalog items)
  /// This method delegates to the InvoiceService's recalculateAllStatistics method
  static Future<void> forceRecalculateAllStatistics() async {
    try {
      debugPrint(
        'MigrationService: Delegating statistics calculation to InvoiceService...',
      );

      // Get service provider
      final serviceProvider = HiveServiceProvider();
      await serviceProvider.initialize();

      // Delegate to invoice service
      await serviceProvider.invoiceService.recalculateAllStatistics();

      debugPrint('MigrationService: Statistics recalculation completed');
    } catch (e) {
      debugPrint('Error recalculating statistics: $e');
    }
  }
}
