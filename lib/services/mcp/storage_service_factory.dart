import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/services/mcp/storage_service.dart';
import 'package:invoicegenerator/services/mcp/shared_prefs_storage_service.dart';
import 'package:invoicegenerator/services/mcp/supabase_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Storage type
enum StorageType {
  local, // SharedPreferences
  remote, // Supabase
}

/// Factory to provide the appropriate storage service implementation
class StorageServiceFactory {
  // Singleton pattern
  static final StorageServiceFactory _instance =
      StorageServiceFactory._internal();
  factory StorageServiceFactory() => _instance;
  StorageServiceFactory._internal();

  // Current storage type preference
  static const String _storageTypeKey = 'storage_type';
  StorageType _currentType = StorageType.local;

  // Service instances
  final SharedPrefsStorageService _localService = SharedPrefsStorageService();
  final SupabaseStorageService _remoteService = SupabaseStorageService();

  /// Initialize the factory and determine which storage method to use
  Future<void> init({bool clearLocalData = false}) async {
    try {
      // Only clear data if explicitly requested
      if (clearLocalData) {
        await forceDeleteAllLocalData();
      }

      // Load storage preference
      final prefs = await SharedPreferences.getInstance();
      final storedType = prefs.getString(_storageTypeKey);

      if (storedType != null) {
        _currentType = StorageType.values.firstWhere(
          (type) => type.toString() == storedType,
          orElse: () => StorageType.local,
        );
      }

      // Initialize local service first regardless
      debugPrint('Storage Factory: Initializing local service');
      await _localService.init();

      // Try to initialize remote service if Supabase is available
      try {
        final client = Supabase.instance.client;
        final currentUser = client.auth.currentUser;
        final hasSession = client.auth.currentSession != null;

        debugPrint(
          'Storage Factory: Supabase check - User: ${currentUser?.email}, Has session: $hasSession',
        );

        if (currentUser != null && hasSession) {
          debugPrint(
            'Storage Factory: Initializing remote service with authenticated user',
          );
          await _remoteService.init();

          // Switch to remote storage if user is authenticated
          _currentType = StorageType.remote;
          await prefs.setString(_storageTypeKey, StorageType.remote.toString());
          debugPrint('Storage Factory: Switched to remote storage');

          // If local data exists, migrate to remote
          final hasLocalData = await _checkIfLocalDataExists();
          if (hasLocalData) {
            debugPrint(
              'Storage Factory: Local data exists, initiating migration',
            );
            await migrateLocalToRemote();
          }
        } else {
          debugPrint(
            'Storage Factory: No authenticated user, using local storage',
          );
          _currentType = StorageType.local;
          await prefs.setString(_storageTypeKey, StorageType.local.toString());
        }
      } catch (e) {
        debugPrint('Storage Factory: Remote service not available: $e');
        // Force local storage if remote is unavailable
        _currentType = StorageType.local;
        await prefs.setString(_storageTypeKey, StorageType.local.toString());
      }

      debugPrint(
        'Storage Factory: Initialization complete, using ${_currentType == StorageType.remote ? "REMOTE" : "LOCAL"} storage',
      );
    } catch (e) {
      debugPrint('Error initializing storage service factory: $e');
      // Default to local storage on error
      _currentType = StorageType.local;
    }
  }

  /// Check if any data exists in local storage
  Future<bool> _checkIfLocalDataExists() async {
    try {
      final companyInfo = await _localService.getCompanyInfo();
      final clients = await _localService.getClients();
      final catalogItems = await _localService.getCatalogItems();
      final invoices = await _localService.getInvoices();

      return companyInfo != null ||
          clients.isNotEmpty ||
          catalogItems.isNotEmpty ||
          invoices.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking for local data: $e');
      return false;
    }
  }

  /// Get the current storage service
  StorageService get service {
    return _currentType == StorageType.remote ? _remoteService : _localService;
  }

  /// Set the storage type preference
  Future<void> setStorageType(StorageType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageTypeKey, type.toString());
      _currentType = type;
    } catch (e) {
      debugPrint('Error setting storage type: $e');
    }
  }

  /// Get the current storage type
  StorageType get currentStorageType => _currentType;

  /// Check if remote storage is available
  bool get isRemoteAvailable {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }

  /// Migrate data from local to remote storage
  Future<bool> migrateLocalToRemote() async {
    if (!isRemoteAvailable) {
      debugPrint('Remote storage not available for migration');
      return false;
    }

    bool success = true;

    try {
      // 1. Ensure Supabase service is initialized
      await _remoteService.init();

      // 2. Migrate company info
      try {
        final companyInfo = await _localService.getCompanyInfo();
        if (companyInfo != null) {
          await _remoteService.updateCompanyInfo(companyInfo);
          debugPrint('✅ Successfully migrated company info');
        }
      } catch (e) {
        debugPrint('❌ Error migrating company info: $e');
        success = false;
      }

      // 3. Migrate clients
      try {
        final clients = await _localService.getClients();
        int migratedCount = 0;
        for (final client in clients) {
          try {
            await _remoteService.createClient(client);
            migratedCount++;
          } catch (e) {
            debugPrint('Error migrating client ${client.clientId}: $e');
          }
        }
        debugPrint('✅ Migrated $migratedCount/${clients.length} clients');
        if (migratedCount < clients.length) success = false;
      } catch (e) {
        debugPrint('❌ Error migrating clients: $e');
        success = false;
      }

      // 4. Migrate catalog items
      try {
        final catalogItems = await _localService.getCatalogItems();
        int migratedCount = 0;
        for (final item in catalogItems) {
          try {
            await _remoteService.createItem(item);
            migratedCount++;
          } catch (e) {
            debugPrint('Error migrating catalog item ${item.title}: $e');
          }
        }
        debugPrint(
          '✅ Migrated $migratedCount/${catalogItems.length} catalog items',
        );
        if (migratedCount < catalogItems.length) success = false;
      } catch (e) {
        debugPrint('❌ Error migrating catalog items: $e');
        success = false;
      }

      // 5. Migrate invoices
      try {
        final invoices = await _localService.getInvoices();
        int migratedCount = 0;
        for (final invoice in invoices) {
          try {
            await _remoteService.createInvoice(invoice);
            migratedCount++;
          } catch (e) {
            debugPrint('Error migrating invoice ${invoice.invoiceId}: $e');
          }
        }
        debugPrint('✅ Migrated $migratedCount/${invoices.length} invoices');
        if (migratedCount < invoices.length) success = false;
      } catch (e) {
        debugPrint('❌ Error migrating invoices: $e');
        success = false;
      }

      // 6. Migrate invoice settings
      try {
        final invoiceSettings = await _localService.getInvoiceSettings();
        if (invoiceSettings != null) {
          await _remoteService.updateInvoiceSettings(invoiceSettings);
          debugPrint('✅ Successfully migrated invoice settings');
        }
      } catch (e) {
        debugPrint('❌ Error migrating invoice settings: $e');
        success = false;
      }

      // 7. Clear local data regardless of errors to prevent duplicate data
      await _clearLocalData();

      // 8. Set storage type to remote
      await setStorageType(StorageType.remote);

      if (success) {
        debugPrint('✅ Migration completed successfully');
      } else {
        debugPrint('⚠️ Migration completed with some errors');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error during migration: $e');

      // Still clear local data and set to remote to avoid partial state
      try {
        await _clearLocalData();
        await setStorageType(StorageType.remote);
      } catch (_) {}

      return false;
    }
  }

  /// Clear all data from local storage after migration
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('company_info');
      await prefs.remove('clients');
      await prefs.remove('catalog_items');
      await prefs.remove('invoices');
      await prefs.remove('invoice_settings');
      debugPrint('Successfully cleared local data after migration');
    } catch (e) {
      debugPrint('Error clearing local data: $e');
    }
  }

  /// Check if any data exists in local storage (public API version)
  Future<bool> checkLocalDataExists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('company_info') ||
        prefs.containsKey('clients') ||
        prefs.containsKey('catalog_items') ||
        prefs.containsKey('invoices') ||
        prefs.containsKey('invoice_settings');
  }

  /// Force delete all local data
  Future<void> forceDeleteAllLocalData() async {
    try {
      debugPrint('### AGGRESSIVE CLEANUP: Force deleting all local data');

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Clear all SharedPreferences keys at once
      await prefs.clear();
      debugPrint('### AGGRESSIVE CLEANUP: Cleared ALL SharedPreferences keys');

      // Clear in-memory cache in both services
      await resetAllCaches();

      // Clear file storage
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final logoBackupDir = Directory('${docsDir.path}/logo_backups');

        // Delete logo backups directory if exists
        if (await logoBackupDir.exists()) {
          await logoBackupDir.delete(recursive: true);
          debugPrint('### AGGRESSIVE CLEANUP: Deleted logo backups directory');
        }

        // Delete other directories that might have file-based storage
        final dirsToDelete = ['pdfs', 'exports', 'temp', 'cache'];
        for (final dir in dirsToDelete) {
          final directory = Directory('${docsDir.path}/$dir');
          if (await directory.exists()) {
            await directory.delete(recursive: true);
            debugPrint('### AGGRESSIVE CLEANUP: Deleted $dir directory');
          }
        }
      } catch (e) {
        debugPrint('Error deleting directories: $e');
      }
    } catch (e) {
      debugPrint('Error in force delete all local data: $e');
    }
  }

  /// Reset all in-memory caches in both services
  Future<void> resetAllCaches() async {
    try {
      // Clear local service cache
      await _localService.clearClientAndCatalogData();
      debugPrint(
        '### AGGRESSIVE CLEANUP: Cleared local service in-memory cache',
      );

      // Clear remote service cache
      await _remoteService.clearCache();
      debugPrint(
        '### AGGRESSIVE CLEANUP: Cleared remote service in-memory cache',
      );
    } catch (e) {
      debugPrint('Error resetting caches: $e');
    }
  }

  bool _isAuthenticated() {
    // Implement your logic to check if the user is authenticated
    // This is a placeholder and should be replaced with the actual implementation
    return false;
  }
}
