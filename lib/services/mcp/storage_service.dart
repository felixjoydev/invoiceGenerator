import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/models/invoice.dart';

/// Abstract storage service interface to unify SharedPreferences and Supabase implementations
abstract class StorageService {
  // Initialization
  Future<void> init();

  // Company operations
  Future<CompanyInfo?> getCompanyInfo();
  Future<void> updateCompanyInfo(CompanyInfo info);

  // Client operations
  Future<List<Client>> getClients();
  Future<Client?> getClientById(String clientId);
  Future<void> createClient(Client client);
  Future<void> updateClient(String clientId, Client client);
  Future<bool> deleteClient(String clientId);
  Future<bool> canDeleteClient(String clientId);
  Future<String> generateClientId();

  // Catalog operations
  Future<List<CatalogItem>> getCatalogItems();
  Future<CatalogItem?> getItemByTitle(String title);
  Future<void> createItem(CatalogItem item);
  Future<void> updateItem(String title, CatalogItem item);
  Future<void> deleteItem(String title);
  Future<bool> isItemTitleUnique(String title);

  // Invoice operations
  Future<List<Invoice>> getInvoices();
  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status);
  Future<List<Invoice>> getInvoicesByClient(String clientId);
  Future<Invoice?> getInvoiceById(String invoiceId);
  Future<bool> createInvoice(Invoice invoice);
  Future<bool> updateInvoice(String invoiceId, Invoice invoice);
  Future<bool> deleteInvoice(String invoiceId);
  Future<String> generateInvoiceId();
  Future<void> saveInvoices(List<Invoice> invoices);

  // Invoice Settings operations
  Future<InvoiceSettings?> getInvoiceSettings();
  Future<void> updateInvoiceSettings(InvoiceSettings settings);

  // Clear operations
  Future<void> clearClientAndCatalogData();
}

/// Invoice settings model to match the one used in invoice_settings_service.dart
class InvoiceSettings {
  final String idFormat;
  final String customNotes;
  final bool isAutoGenerate;
  final String idPrefix;
  final int lastInvoiceNumber;

  InvoiceSettings({
    this.idFormat = '001',
    this.customNotes = '',
    this.isAutoGenerate = true,
    this.idPrefix = 'INV',
    this.lastInvoiceNumber = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'idFormat': idFormat,
      'customNotes': customNotes,
      'isAutoGenerate': isAutoGenerate,
      'idPrefix': idPrefix,
      'lastInvoiceNumber': lastInvoiceNumber,
    };
  }

  factory InvoiceSettings.fromMap(Map<String, dynamic> map) {
    return InvoiceSettings(
      idFormat: map['idFormat'] ?? '001',
      customNotes: map['customNotes'] ?? '',
      isAutoGenerate: map['isAutoGenerate'] ?? true,
      idPrefix: map['idPrefix'] ?? 'INV',
      lastInvoiceNumber: map['lastInvoiceNumber'] ?? 0,
    );
  }

  InvoiceSettings copyWith({
    String? idFormat,
    String? customNotes,
    bool? isAutoGenerate,
    String? idPrefix,
    int? lastInvoiceNumber,
  }) {
    return InvoiceSettings(
      idFormat: idFormat ?? this.idFormat,
      customNotes: customNotes ?? this.customNotes,
      isAutoGenerate: isAutoGenerate ?? this.isAutoGenerate,
      idPrefix: idPrefix ?? this.idPrefix,
      lastInvoiceNumber: lastInvoiceNumber ?? this.lastInvoiceNumber,
    );
  }
}
