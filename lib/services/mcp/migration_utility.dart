import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/mcp/shared_prefs_storage_service.dart';
import 'package:invoicegenerator/services/mcp/storage_service.dart';
import 'package:invoicegenerator/services/mcp/storage_service_factory.dart';
import 'package:invoicegenerator/services/mcp/supabase_storage_service.dart';

/// Result of a migration operation
class MigrationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? details;

  MigrationResult({required this.success, required this.message, this.details});
}

/// Utility class to migrate data from SharedPreferences to Supabase
class MigrationUtility {
  // Storage services
  final SharedPrefsStorageService _sharedPrefs = SharedPrefsStorageService();
  final SupabaseStorageService _supabase = SupabaseStorageService();
  final StorageServiceFactory _factory = StorageServiceFactory();

  // Migration steps and progress
  int _totalSteps = 5; // Company, Clients, Catalog, Invoices, Settings
  int _completedSteps = 0;
  String _currentOperation = '';
  List<String> _migrationLog = [];

  // Getters for progress tracking
  int get totalSteps => _totalSteps;
  int get completedSteps => _completedSteps;
  String get currentOperation => _currentOperation;
  List<String> get migrationLog => List.unmodifiable(_migrationLog);

  // Migration progress as percentage
  double get progress => _totalSteps > 0 ? _completedSteps / _totalSteps : 0;

  /// Initialize the migration utility
  Future<bool> init() async {
    try {
      await _sharedPrefs.init();
      await _supabase.init();
      return true;
    } catch (e) {
      _logError('Error initializing migration utility', e);
      return false;
    }
  }

  /// Check if remote storage is available (user is logged in)
  bool get isRemoteAvailable => _factory.isRemoteAvailable;

  /// Check if there's local data to migrate
  Future<bool> hasLocalData() async {
    try {
      final companyInfo = await _sharedPrefs.getCompanyInfo();
      return companyInfo != null;
    } catch (e) {
      _logError('Error checking for local data', e);
      return false;
    }
  }

  /// Check if there's remote data already
  Future<bool> hasRemoteData() async {
    try {
      final companyInfo = await _supabase.getCompanyInfo();
      return companyInfo != null;
    } catch (e) {
      _logError('Error checking for remote data', e);
      return false;
    }
  }

  /// Migrate all data from local to remote
  Future<MigrationResult> migrateAllData() async {
    try {
      _completedSteps = 0;
      _migrationLog = [];

      // 0. Check prerequisites
      if (!isRemoteAvailable) {
        return MigrationResult(
          success: false,
          message: 'Remote storage not available. Please log in first.',
        );
      }

      if (!await hasLocalData()) {
        return MigrationResult(
          success: false,
          message: 'No local data found to migrate.',
        );
      }

      // Check for existing remote data
      if (await hasRemoteData()) {
        return MigrationResult(
          success: false,
          message:
              'Remote data already exists. Migration would cause conflicts.',
        );
      }

      // 1. Migrate company info
      _currentOperation = 'Migrating company information';
      _logInfo('Starting company info migration');

      final companyInfo = await _sharedPrefs.getCompanyInfo();
      if (companyInfo != null) {
        await _supabase.updateCompanyInfo(companyInfo);
        _logInfo('Company info migrated successfully');
      } else {
        _logWarning('No company info found to migrate');
      }

      _incrementProgress();

      // 2. Migrate clients
      _currentOperation = 'Migrating client data';
      _logInfo('Starting client data migration');

      final clients = await _sharedPrefs.getClients();
      _logInfo('Found ${clients.length} clients to migrate');

      for (final client in clients) {
        await _supabase.createClient(client);
        _logInfo('Migrated client: ${client.name} (${client.clientId})');
      }

      _incrementProgress();

      // 3. Migrate catalog items
      _currentOperation = 'Migrating catalog items';
      _logInfo('Starting catalog item migration');

      final catalogItems = await _sharedPrefs.getCatalogItems();
      _logInfo('Found ${catalogItems.length} catalog items to migrate');

      for (final item in catalogItems) {
        await _supabase.createItem(item);
        _logInfo('Migrated catalog item: ${item.title}');
      }

      _incrementProgress();

      // 4. Migrate invoices
      _currentOperation = 'Migrating invoices';
      _logInfo('Starting invoice migration');

      final invoices = await _sharedPrefs.getInvoices();
      _logInfo('Found ${invoices.length} invoices to migrate');

      for (final invoice in invoices) {
        final success = await _supabase.createInvoice(invoice);
        if (success) {
          _logInfo('Migrated invoice: ${invoice.invoiceId}');
        } else {
          _logWarning('Failed to migrate invoice: ${invoice.invoiceId}');
        }
      }

      _incrementProgress();

      // 5. Migrate settings
      _currentOperation = 'Migrating invoice settings';
      _logInfo('Starting invoice settings migration');

      final settings = await _sharedPrefs.getInvoiceSettings();
      if (settings != null) {
        await _supabase.updateInvoiceSettings(settings);
        _logInfo('Invoice settings migrated successfully');
      } else {
        _logWarning('No invoice settings found to migrate');
      }

      _incrementProgress();

      // 6. Set storage type to remote
      await _factory.setStorageType(StorageType.remote);
      _logInfo('Set storage type to remote');

      // Complete migration
      _currentOperation = 'Migration completed';
      return MigrationResult(
        success: true,
        message: 'Migration completed successfully',
        details: {
          'migrated_clients': clients.length,
          'migrated_catalog_items': catalogItems.length,
          'migrated_invoices': invoices.length,
          'log': _migrationLog,
        },
      );
    } catch (e) {
      _logError('Migration failed', e);
      return MigrationResult(
        success: false,
        message: 'Migration failed: ${e.toString()}',
        details: {
          'completed_steps': _completedSteps,
          'total_steps': _totalSteps,
          'log': _migrationLog,
        },
      );
    }
  }

  // Private helpers
  void _incrementProgress() {
    _completedSteps++;
    _logInfo('Completed step $_completedSteps of $_totalSteps');
  }

  void _logInfo(String message) {
    _migrationLog.add('[INFO] $message');
    debugPrint('Migration: $message');
  }

  void _logWarning(String message) {
    _migrationLog.add('[WARNING] $message');
    debugPrint('Migration Warning: $message');
  }

  void _logError(String message, dynamic error) {
    _migrationLog.add('[ERROR] $message: $error');
    debugPrint('Migration Error: $message - $error');
  }
}
