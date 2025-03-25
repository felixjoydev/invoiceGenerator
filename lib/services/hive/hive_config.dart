import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:invoicegenerator/models/hive/company_info_model.dart';
import 'package:invoicegenerator/models/hive/client_model.dart';
import 'package:invoicegenerator/models/hive/catalog_item_model.dart';
import 'package:invoicegenerator/models/hive/invoice_model.dart';
import 'package:invoicegenerator/models/hive/invoice_settings_model.dart';
import 'package:invoicegenerator/models/hive/invoice_item_model.dart';

/// Hive box names
class HiveBoxes {
  static const String companyInfo = 'companyInfo';
  static const String clients = 'clients';
  static const String catalogItems = 'catalogItems';
  static const String invoices = 'invoices';
  static const String invoiceSettings = 'invoiceSettings';
  static const String appPreferences = 'appPreferences';
}

/// Hive type IDs for registered adapters
class HiveTypes {
  static const int companyInfo = 0;
  static const int client = 1;
  static const int catalogItem = 2;
  static const int invoice = 3;
  static const int invoiceSettings = 4;
  static const int invoiceItem = 5;
}

/// Hive initialization and configuration
class HiveConfig {
  /// Flag to check if Hive is initialized
  static bool _isInitialized = false;

  /// Initialize Hive and register all adapters
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('HiveConfig: Beginning initialization...');

      // Validate the Hive models
      validateHiveModels();

      // Initialize Hive with a custom path for non-web platforms
      if (!kIsWeb) {
        final Directory appDocumentDir =
            await getApplicationDocumentsDirectory();
        final String hiveStoragePath = '${appDocumentDir.path}/hive';
        debugPrint(
          'HiveConfig: Initializing Flutter storage at $hiveStoragePath',
        );
        await Hive.initFlutter(hiveStoragePath);
      } else {
        debugPrint('HiveConfig: Initializing Flutter storage for web');
        await Hive.initFlutter();
      }

      // Register all adapters
      debugPrint('HiveConfig: Registering adapters');
      _registerAdapters();

      // Open boxes
      debugPrint('HiveConfig: Opening boxes');
      await _openBoxes();

      _isInitialized = true;
      debugPrint('HiveConfig: Initialization completed successfully');
    } catch (e, stackTrace) {
      debugPrint('ERROR initializing Hive: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Validate the Hive models
  static void validateHiveModels() {
    debugPrint('HiveConfig: Validating Client model fields...');

    try {
      // Create a test client and check fields
      final testClient = Client(
        clientId: 'TEST001',
        name: 'Test Client',
        type: 'organization',
        currency: 'USD',
      );

      // Check crucial fields
      final hasNullCurrency = testClient.currency == null;
      final hasOutstanding = testClient.hasOutstanding;
      final hasDue = testClient.hasDue;

      debugPrint(
        'HiveConfig: Client.currency is ${hasNullCurrency ? 'NULL' : 'not null'}',
      );
      debugPrint(
        'HiveConfig: Client.hasOutstanding is ${hasOutstanding ? 'true' : 'false'}',
      );
      debugPrint('HiveConfig: Client.hasDue is ${hasDue ? 'true' : 'false'}');

      // Create test CatalogItem
      final testCatalogItem = CatalogItem(
        title: 'Test Item',
        amount: 10.0,
        quantity: 1,
      );

      debugPrint(
        'HiveConfig: CatalogItem.currency is ${testCatalogItem.currency}',
      );

      debugPrint('HiveConfig: Model validation passed');
    } catch (e, stackTrace) {
      debugPrint('ERROR validating Hive models: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow, just log the error
    }
  }

  /// Register all Hive adapters
  static void _registerAdapters() {
    Hive.registerAdapter(CompanyInfoAdapter());
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(CatalogItemAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(InvoiceSettingsAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
  }

  /// Open all Hive boxes
  static Future<void> _openBoxes() async {
    try {
      await Hive.openBox<CompanyInfo>(HiveBoxes.companyInfo);
      debugPrint('HiveConfig: Opened companyInfo box');

      await Hive.openBox<Client>(HiveBoxes.clients);
      debugPrint('HiveConfig: Opened clients box');

      await Hive.openBox<CatalogItem>(HiveBoxes.catalogItems);
      debugPrint('HiveConfig: Opened catalogItems box');

      await Hive.openBox<Invoice>(HiveBoxes.invoices);
      debugPrint('HiveConfig: Opened invoices box');

      await Hive.openBox<InvoiceSettings>(HiveBoxes.invoiceSettings);
      debugPrint('HiveConfig: Opened invoiceSettings box');

      await Hive.openBox(HiveBoxes.appPreferences);
      debugPrint('HiveConfig: Opened appPreferences box');
    } catch (e, stackTrace) {
      debugPrint('ERROR opening Hive boxes: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Close all Hive boxes
  static Future<void> closeBoxes() async {
    await Hive.close();
    _isInitialized = false;
  }

  /// Delete all Hive boxes
  static Future<void> deleteBoxes() async {
    await Hive.deleteBoxFromDisk(HiveBoxes.companyInfo);
    await Hive.deleteBoxFromDisk(HiveBoxes.clients);
    await Hive.deleteBoxFromDisk(HiveBoxes.catalogItems);
    await Hive.deleteBoxFromDisk(HiveBoxes.invoices);
    await Hive.deleteBoxFromDisk(HiveBoxes.invoiceSettings);
    await Hive.deleteBoxFromDisk(HiveBoxes.appPreferences);
  }
}
