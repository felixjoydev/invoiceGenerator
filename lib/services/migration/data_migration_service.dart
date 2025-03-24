import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/company_service.dart';
import 'package:invoicegenerator/services/client_service.dart';
import 'package:invoicegenerator/services/catalog_service.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:invoicegenerator/services/repository/company_repository.dart';
import 'package:invoicegenerator/services/repository/client_repository.dart';
import 'package:invoicegenerator/services/repository/catalog_repository.dart';
import 'package:invoicegenerator/services/repository/invoice_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service to migrate data from local storage to Supabase
class DataMigrationService {
  // Singleton pattern
  static final DataMigrationService _instance =
      DataMigrationService._internal();

  factory DataMigrationService() {
    return _instance;
  }

  DataMigrationService._internal();

  // Services
  final CompanyService _companyService = CompanyService();
  final ClientService _clientService = ClientService();
  final CatalogService _catalogService = CatalogService();
  final InvoiceService _invoiceService = InvoiceService();

  // Repositories
  final CompanyRepository _companyRepository = CompanyRepository();
  final ClientRepository _clientRepository = ClientRepository();
  final CatalogRepository _catalogRepository = CatalogRepository();
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  // Migration state
  bool _isMigrating = false;
  double _progress = 0.0;
  String _status = 'Not started';

  // Getters for state
  bool get isMigrating => _isMigrating;
  double get progress => _progress;
  String get status => _status;

  /// Check if migration is needed (if we have local data but no Supabase data)
  Future<bool> needsMigration() async {
    try {
      // Check if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return false; // Not authenticated, can't migrate
      }

      // Check if we have local data
      await _companyService.init();
      await _clientService.init();
      await _catalogService.init();
      await _invoiceService.init();

      final hasLocalCompany = _companyService.companyInfo != null;
      final hasLocalClients = _clientService.clients.isNotEmpty;
      final hasLocalCatalog = _catalogService.getAllItems().isNotEmpty;
      final hasLocalInvoices = _invoiceService.invoices.isNotEmpty;

      final hasLocalData =
          hasLocalCompany ||
          hasLocalClients ||
          hasLocalCatalog ||
          hasLocalInvoices;

      if (!hasLocalData) {
        return false; // No local data to migrate
      }

      // Check if we already have data in Supabase
      final companyInfo = await _companyRepository.getCompanyInfo();
      final clients = await _clientRepository.getAll();

      // If we already have Supabase data, no need to migrate
      if (companyInfo != null || clients.isNotEmpty) {
        return false;
      }

      return true; // We have local data and no Supabase data
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return false;
    }
  }

  /// Start the migration process
  Future<bool> startMigration() async {
    if (_isMigrating) {
      return false; // Already migrating
    }

    try {
      _isMigrating = true;
      _progress = 0.0;
      _status = 'Starting migration...';

      // Step 1: Migrate company info
      _status = 'Migrating company information...';
      await _migrateCompanyInfo();
      _progress = 0.2;

      // Step 2: Migrate clients
      _status = 'Migrating clients...';
      final clientIdMap = await _migrateClients();
      _progress = 0.4;

      // Step 3: Migrate catalog items
      _status = 'Migrating catalog items...';
      await _migrateCatalogItems();
      _progress = 0.6;

      // Step 4: Migrate invoices
      _status = 'Migrating invoices...';
      await _migrateInvoices(clientIdMap);
      _progress = 0.8;

      // Step 5: Verify migration
      _status = 'Verifying migration...';
      await _verifyMigration();
      _progress = 1.0;

      _status = 'Migration completed successfully';
      _isMigrating = false;
      return true;
    } catch (e) {
      _status = 'Migration failed: $e';
      _isMigrating = false;
      debugPrint('Migration error: $e');
      return false;
    }
  }

  /// Migrate company information
  Future<void> _migrateCompanyInfo() async {
    try {
      final localCompany = _companyService.companyInfo;
      if (localCompany == null) {
        debugPrint('No company info to migrate');
        return;
      }

      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Create company info with user ID
      final companyInfo = CompanyInfo(
        id: userId,
        businessName: localCompany.businessName,
        logoPath: localCompany.logoPath,
        currency: localCompany.currency,
        taxRate: localCompany.taxRate,
        enableTax: localCompany.enableTax,
        country: localCompany.country,
        addressLine1: localCompany.addressLine1,
        addressLine2: localCompany.addressLine2,
        city: localCompany.city,
        zip: localCompany.zip,
        phone: localCompany.phone,
        email: localCompany.email,
        website: localCompany.website,
        bankName: localCompany.bankName,
        accountHolder: localCompany.accountHolder,
        accountNumber: localCompany.accountNumber,
        ifscCode: localCompany.ifscCode,
      );

      await _companyRepository.createInitialProfile(companyInfo);
      debugPrint('Company info migrated successfully');
    } catch (e) {
      debugPrint('Error migrating company info: $e');
      rethrow;
    }
  }

  /// Migrate clients
  /// Returns a map of local client IDs to Supabase client IDs
  Future<Map<String, String>> _migrateClients() async {
    final idMap = <String, String>{};

    try {
      final localClients = _clientService.clients;
      if (localClients.isEmpty) {
        debugPrint('No clients to migrate');
        return idMap;
      }

      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Migrate each client
      for (final localClient in localClients) {
        // Create new client with same data but with user ID
        final client = Client(
          userId: userId,
          name: localClient.name,
          clientId: localClient.clientId,
          taxId: localClient.taxId,
          country: localClient.country,
          addressLine1: localClient.addressLine1,
          addressLine2: localClient.addressLine2,
          city: localClient.city,
          zip: localClient.zip,
          phone: localClient.phone,
          email: localClient.email,
          website: localClient.website,
          notes: localClient.notes,
          type: localClient.type,
        );

        // Save to Supabase
        final savedClient = await _clientRepository.create(client);

        // Store the mapping from local ID to Supabase ID
        idMap[localClient.clientId] = savedClient.id!;
      }

      debugPrint('Migrated ${localClients.length} clients');
      return idMap;
    } catch (e) {
      debugPrint('Error migrating clients: $e');
      rethrow;
    }
  }

  /// Migrate catalog items
  Future<void> _migrateCatalogItems() async {
    try {
      final localItems = _catalogService.getAllItems();
      if (localItems.isEmpty) {
        debugPrint('No catalog items to migrate');
        return;
      }

      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Migrate each catalog item
      for (final localItem in localItems) {
        // Create new item with same data but with user ID
        final item = CatalogItem(
          userId: userId,
          itemId: const Uuid().v4(), // Generate new unique ID
          title: localItem.title,
          currency: localItem.currency,
          amount: localItem.amount,
          quantity: localItem.quantity,
          usageInfo: localItem.usageInfo,
          isNew: localItem.isNew,
        );

        // Save to Supabase
        await _catalogRepository.create(item);
      }

      debugPrint('Migrated ${localItems.length} catalog items');
    } catch (e) {
      debugPrint('Error migrating catalog items: $e');
      rethrow;
    }
  }

  /// Migrate invoices
  /// Uses the client ID map to link invoices to the new client IDs
  Future<void> _migrateInvoices(Map<String, String> clientIdMap) async {
    try {
      final localInvoices = _invoiceService.invoices;
      if (localInvoices.isEmpty) {
        debugPrint('No invoices to migrate');
        return;
      }

      // Get current user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Migrate each invoice
      for (final localInvoice in localInvoices) {
        // Find the Supabase client ID for this invoice's client
        final supabaseClientId = clientIdMap[localInvoice.client.clientId];
        if (supabaseClientId == null) {
          debugPrint(
            'Could not find Supabase client ID for local client ${localInvoice.client.clientId}',
          );
          continue;
        }

        // Create new invoice with same data but with user ID and client ID
        final invoice = localInvoice.copyWith(
          userId: userId,
          clientId: supabaseClientId,
        );

        // Save to Supabase
        await _invoiceRepository.createWithItems(invoice);
      }

      debugPrint('Migrated ${localInvoices.length} invoices');
    } catch (e) {
      debugPrint('Error migrating invoices: $e');
      rethrow;
    }
  }

  /// Verify the migration
  Future<void> _verifyMigration() async {
    try {
      // Get counts from Supabase
      final companyInfo = await _companyRepository.getCompanyInfo();
      final clients = await _clientRepository.getAll();
      final catalogItems = await _catalogRepository.getAll();
      final invoices = await _invoiceRepository.getAllWithItems();

      // Log counts
      debugPrint('Company info migrated: ${companyInfo != null}');
      debugPrint('Clients migrated: ${clients.length}');
      debugPrint('Catalog items migrated: ${catalogItems.length}');
      debugPrint('Invoices migrated: ${invoices.length}');

      // If we have no company info or clients, consider it a failed migration
      if (companyInfo == null || clients.isEmpty) {
        throw Exception(
          'Migration verification failed - missing essential data',
        );
      }
    } catch (e) {
      debugPrint('Error verifying migration: $e');
      rethrow;
    }
  }
}
