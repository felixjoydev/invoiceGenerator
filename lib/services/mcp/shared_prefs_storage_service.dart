import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/mcp/storage_service.dart';

/// Implementation of StorageService using SharedPreferences
/// This class reuses the existing SharedPreferences code but adapts it to the new interface
class SharedPrefsStorageService implements StorageService {
  // Singleton pattern
  static final SharedPrefsStorageService _instance =
      SharedPrefsStorageService._internal();
  factory SharedPrefsStorageService() => _instance;
  SharedPrefsStorageService._internal();

  // Storage keys
  static const String _companyInfoKey = 'company_info';
  static const String _clientsKey = 'clients';
  static const String _catalogItemsKey = 'catalog_items';
  static const String _invoicesKey = 'invoices';
  static const String _invoiceSettingsKey = 'invoice_settings';

  // In-memory caches
  CompanyInfo? _companyInfo;
  List<Client> _clients = [];
  List<CatalogItem> _catalogItems = [];
  List<Invoice> _invoices = [];
  InvoiceSettings? _invoiceSettings;

  // Default items for first-time initialization
  final List<CatalogItem> _defaultItems = [
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

  @override
  Future<void> init() async {
    await Future.wait([
      _loadCompanyInfo(),
      _loadClients(),
      _loadCatalogItems(),
      _loadInvoices(),
      _loadInvoiceSettings(),
    ]);

    debugPrint('SharedPrefsStorageService initialized');
  }

  // Company Info Methods
  @override
  Future<CompanyInfo?> getCompanyInfo() async {
    if (_companyInfo == null) {
      await _loadCompanyInfo();
    }
    return _companyInfo;
  }

  @override
  Future<void> updateCompanyInfo(CompanyInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String companyJson = jsonEncode(info.toMap());
      await prefs.setString(_companyInfoKey, companyJson);
      _companyInfo = info;
    } catch (e) {
      debugPrint('Error saving company info: $e');
    }
  }

  Future<void> _loadCompanyInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? companyJson = prefs.getString(_companyInfoKey);

      if (companyJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(companyJson);
        _companyInfo = CompanyInfo.fromMap(decoded);
      }
    } catch (e) {
      debugPrint('Error loading company info: $e');
      _companyInfo = null;
    }
  }

  // Client Methods
  @override
  Future<List<Client>> getClients() async {
    if (_clients.isEmpty) {
      await _loadClients();
    }
    return List.unmodifiable(_clients);
  }

  @override
  Future<Client?> getClientById(String clientId) async {
    await getClients();
    return _clients.firstWhere(
      (client) => client.clientId == clientId,
      orElse: () => null as Client,
    );
  }

  @override
  Future<void> createClient(Client client) async {
    _clients.insert(0, client);
    await _saveClients();
  }

  @override
  Future<void> updateClient(String clientId, Client client) async {
    final index = _clients.indexWhere((c) => c.clientId == clientId);
    if (index != -1) {
      _clients[index] = client;
      await _saveClients();

      // Update client in all invoices
      for (int i = 0; i < _invoices.length; i++) {
        if (_invoices[i].client.clientId == clientId) {
          final updatedInvoice = _invoices[i].copyWith(client: client);
          _invoices[i] = updatedInvoice;
        }
      }
      await saveInvoices(_invoices);
    }
  }

  @override
  Future<bool> deleteClient(String clientId) async {
    if (!await canDeleteClient(clientId)) {
      return false;
    }

    _clients.removeWhere((client) => client.clientId == clientId);
    await _saveClients();
    return true;
  }

  @override
  Future<bool> canDeleteClient(String clientId) async {
    await getInvoices();
    return !_invoices.any((invoice) => invoice.client.clientId == clientId);
  }

  @override
  Future<String> generateClientId() async {
    await getClients();

    // Find the highest existing client ID number
    int highestIdNumber = 0;

    for (var client in _clients) {
      // Extract the numeric part from clientId format "CLxxx"
      final idMatch = RegExp(r'CL(\d+)').firstMatch(client.clientId);
      if (idMatch != null) {
        final idNumber = int.tryParse(idMatch.group(1) ?? '0') ?? 0;
        if (idNumber > highestIdNumber) {
          highestIdNumber = idNumber;
        }
      }
    }

    // Create a new ID by incrementing the highest number
    final newIdNumber = highestIdNumber + 1;
    return 'CL${newIdNumber.toString().padLeft(3, '0')}';
  }

  Future<void> _loadClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? clientsJson = prefs.getString(_clientsKey);

      if (clientsJson != null) {
        final List<dynamic> decoded = jsonDecode(clientsJson);
        _clients =
            decoded.map((clientMap) => Client.fromMap(clientMap)).toList();
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
      _clients = [];
    }
  }

  Future<void> _saveClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> clientsData =
          _clients.map((client) => client.toMap()).toList();
      await prefs.setString(_clientsKey, jsonEncode(clientsData));
    } catch (e) {
      debugPrint('Error saving clients: $e');
    }
  }

  // Catalog Item Methods
  @override
  Future<List<CatalogItem>> getCatalogItems() async {
    if (_catalogItems.isEmpty) {
      await _loadCatalogItems();
    }
    return List.unmodifiable(_catalogItems);
  }

  @override
  Future<CatalogItem?> getItemByTitle(String title) async {
    await getCatalogItems();
    try {
      return _catalogItems.firstWhere((item) => item.title == title);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createItem(CatalogItem item) async {
    _catalogItems.insert(0, item);
    await _saveCatalogItems();
  }

  @override
  Future<void> updateItem(String title, CatalogItem item) async {
    final index = _catalogItems.indexWhere((i) => i.title == title);
    if (index != -1) {
      _catalogItems[index] = item;
      await _saveCatalogItems();

      // Update item in all invoices
      bool anyInvoiceUpdated = false;
      for (int i = 0; i < _invoices.length; i++) {
        final invoice = _invoices[i];
        bool invoiceUpdated = false;

        final updatedItems =
            invoice.items.map((invItem) {
              if (invItem.title == title) {
                invoiceUpdated = true;
                return item.copyWith(quantity: invItem.quantity);
              }
              return invItem;
            }).toList();

        if (invoiceUpdated) {
          _invoices[i] = invoice.copyWith(items: updatedItems);
          anyInvoiceUpdated = true;
        }
      }

      if (anyInvoiceUpdated) {
        await saveInvoices(_invoices);
      }
    }
  }

  @override
  Future<void> deleteItem(String title) async {
    _catalogItems.removeWhere((item) => item.title == title);
    await _saveCatalogItems();

    // Remove item from all invoices
    bool anyInvoiceUpdated = false;
    for (int i = 0; i < _invoices.length; i++) {
      final invoice = _invoices[i];
      final originalItems = invoice.items;

      final updatedItems =
          originalItems.where((item) => item.title != title).toList();

      if (updatedItems.length != originalItems.length) {
        // Recalculate totals
        double subtotal = updatedItems.fold(
          0,
          (sum, item) =>
              sum + (double.tryParse(item.amount) ?? 0) * item.quantity,
        );
        double taxAmount = subtotal * (invoice.taxRate / 100);
        double total = subtotal + taxAmount;

        _invoices[i] = invoice.copyWith(
          items: updatedItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          total: total,
        );
        anyInvoiceUpdated = true;
      }
    }

    if (anyInvoiceUpdated) {
      await saveInvoices(_invoices);
    }
  }

  @override
  Future<bool> isItemTitleUnique(String title) async {
    await getCatalogItems();
    return !_catalogItems.any((item) => item.title == title);
  }

  Future<void> _loadCatalogItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? catalogJson = prefs.getString(_catalogItemsKey);

      if (catalogJson != null && catalogJson.isNotEmpty) {
        final List<dynamic> catalogData = jsonDecode(catalogJson);
        _catalogItems = [];

        for (var data in catalogData) {
          try {
            if (data is Map) {
              final itemMap = Map<String, dynamic>.from(data);
              final item = CatalogItem.fromMap(itemMap);
              _catalogItems.add(item);
            }
          } catch (e) {
            debugPrint('Error parsing individual catalog item: $e');
            // Skip this item and continue with the next one
          }
        }
      } else {
        // Initialize with empty list (no default items)
        _catalogItems = [];
      }
    } catch (e) {
      debugPrint('Error loading catalog items: $e');
      _catalogItems = [];
    }
  }

  Future<void> _saveCatalogItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> itemsData =
          _catalogItems.map((item) => item.toMap()).toList();
      await prefs.setString(_catalogItemsKey, jsonEncode(itemsData));
    } catch (e) {
      debugPrint('Error saving catalog items: $e');
    }
  }

  // Invoice Methods
  @override
  Future<List<Invoice>> getInvoices() async {
    if (_invoices.isEmpty) {
      await _loadInvoices();
    }
    return List.unmodifiable(_invoices);
  }

  @override
  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    await getInvoices();
    return _invoices.where((i) => i.status == status).toList();
  }

  @override
  Future<List<Invoice>> getInvoicesByClient(String clientId) async {
    await getInvoices();
    return _invoices.where((i) => i.client.clientId == clientId).toList();
  }

  @override
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    await getInvoices();
    try {
      return _invoices.firstWhere((i) => i.invoiceId == invoiceId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> createInvoice(Invoice invoice) async {
    try {
      _invoices.add(invoice);
      await saveInvoices(_invoices);

      // Update client statistics
      await _updateClientStatistics(invoice.client.clientId);

      // Update catalog item usage
      await _updateCatalogItemUsage(invoice.items.map((i) => i.title).toList());

      return true;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      return false;
    }
  }

  @override
  Future<bool> updateInvoice(String invoiceId, Invoice invoice) async {
    try {
      final index = _invoices.indexWhere((i) => i.invoiceId == invoiceId);
      if (index == -1) return false;

      // Store old invoice for reference
      final oldInvoice = _invoices[index];

      // Update invoice
      _invoices[index] = invoice;
      await saveInvoices(_invoices);

      // Get affected client IDs
      final Set<String> clientIds = {invoice.client.clientId};
      if (oldInvoice.client.clientId != invoice.client.clientId) {
        clientIds.add(oldInvoice.client.clientId);
      }

      // Get affected catalog item titles
      final Set<String> itemTitles = {};
      for (var item in invoice.items) {
        itemTitles.add(item.title);
      }
      for (var item in oldInvoice.items) {
        itemTitles.add(item.title);
      }

      // Update statistics
      for (var clientId in clientIds) {
        await _updateClientStatistics(clientId);
      }
      await _updateCatalogItemUsage(itemTitles.toList());

      return true;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      final index = _invoices.indexWhere((i) => i.invoiceId == invoiceId);
      if (index == -1) return false;

      // Store old invoice for reference
      final oldInvoice = _invoices[index];

      // Delete invoice
      _invoices.removeAt(index);
      await saveInvoices(_invoices);

      // Update client statistics
      await _updateClientStatistics(oldInvoice.client.clientId);

      // Update catalog item usage
      await _updateCatalogItemUsage(
        oldInvoice.items.map((i) => i.title).toList(),
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      return false;
    }
  }

  @override
  Future<String> generateInvoiceId() async {
    await getInvoices();

    // Find the highest existing invoice ID number
    int highestNumber = 0;

    for (var invoice in _invoices) {
      if (invoice.invoiceId.startsWith('inv-')) {
        try {
          final int num = int.parse(invoice.invoiceId.substring(4));
          if (num > highestNumber) {
            highestNumber = num;
          }
        } catch (_) {}
      }
    }

    // Create a new ID by incrementing the highest number
    return 'inv-${(highestNumber + 1).toString().padLeft(3, '0')}';
  }

  Future<void> _loadInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? invoicesJson = prefs.getString(_invoicesKey);

      if (invoicesJson != null && invoicesJson.isNotEmpty) {
        final List<dynamic> invoicesData = jsonDecode(invoicesJson);
        _invoices = [];

        for (var data in invoicesData) {
          try {
            if (data is Map) {
              final invoiceMap = Map<String, dynamic>.from(data);
              final invoice = Invoice.fromMap(invoiceMap);
              _invoices.add(invoice);
            }
          } catch (e) {
            debugPrint('Error parsing individual invoice: $e');
            // Skip this invoice and continue with the next one
          }
        }
      } else {
        _invoices = [];
      }
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      _invoices = [];
    }
  }

  @override
  Future<void> saveInvoices(List<Invoice> invoices) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert all invoices to JSON
      final List<String> jsonInvoices =
          invoices.map((invoice) => jsonEncode(invoice.toMap())).toList();

      // Save to SharedPreferences
      await prefs.setStringList(_invoicesKey, jsonInvoices);

      // Update in-memory cache
      _invoices = List<Invoice>.from(invoices);
    } catch (e) {
      debugPrint('Error saving invoices: $e');
    }
  }

  // Invoice Settings Methods
  @override
  Future<InvoiceSettings?> getInvoiceSettings() async {
    if (_invoiceSettings == null) {
      await _loadInvoiceSettings();
    }
    return _invoiceSettings;
  }

  @override
  Future<void> updateInvoiceSettings(InvoiceSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_invoiceSettingsKey, jsonEncode(settings.toMap()));
      _invoiceSettings = settings;
    } catch (e) {
      debugPrint('Error saving invoice settings: $e');
    }
  }

  Future<void> _loadInvoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_invoiceSettingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        _invoiceSettings = InvoiceSettings.fromMap(settings);
      } else {
        _invoiceSettings = InvoiceSettings();
      }
    } catch (e) {
      debugPrint('Error loading invoice settings: $e');
      _invoiceSettings = InvoiceSettings();
    }
  }

  // Helper methods for updating statistics
  Future<void> _updateClientStatistics(String clientId) async {
    // First get the client
    final clientIndex = _clients.indexWhere((c) => c.clientId == clientId);
    if (clientIndex == -1) return;

    // Filter invoices for this client
    final clientInvoices =
        _invoices.where((i) => i.client.clientId == clientId).toList();

    // Calculate statistics
    final invoiceCount = clientInvoices.length;
    double totalAmount = 0;
    double outstandingAmount = 0;
    double dueAmount = 0;
    bool hasOutstanding = false;
    bool hasDue = false;

    for (var invoice in clientInvoices) {
      totalAmount += invoice.total;

      if (invoice.status == InvoiceStatus.outstanding) {
        outstandingAmount += invoice.total;
        hasOutstanding = true;
      } else if (invoice.status == InvoiceStatus.overdue) {
        dueAmount += invoice.total;
        hasDue = true;
      }
    }

    // Create updated client
    final client = _clients[clientIndex];
    final updatedClient = Client(
      name: client.name,
      clientId: client.clientId,
      taxId: client.taxId,
      country: client.country,
      addressLine1: client.addressLine1,
      addressLine2: client.addressLine2,
      city: client.city,
      zip: client.zip,
      phone: client.phone,
      email: client.email,
      website: client.website,
      notes: client.notes,
      type: client.type,
      invoiceCount: invoiceCount,
      currency: client.currency,
      amount: totalAmount,
      outstandingAmount: outstandingAmount,
      hasOutstanding: hasOutstanding,
      dueAmount: dueAmount,
      hasDue: hasDue,
    );

    // Update client without triggering further updates
    _clients[clientIndex] = updatedClient;
    await _saveClients();
  }

  Future<void> _updateCatalogItemUsage(List<String> itemTitles) async {
    if (itemTitles.isEmpty) return;

    // Update each catalog item's usage count
    final Map<String, int> usageCounts = {};

    // Count usage in invoices
    for (var invoice in _invoices) {
      for (var item in invoice.items) {
        if (itemTitles.contains(item.title)) {
          usageCounts[item.title] = (usageCounts[item.title] ?? 0) + 1;
        }
      }
    }

    // Update catalog items
    bool anyUpdated = false;
    for (var title in itemTitles) {
      final index = _catalogItems.indexWhere((item) => item.title == title);
      if (index != -1) {
        final usage = usageCounts[title] ?? 0;
        final updatedItem = _catalogItems[index].copyWith(
          usageInfo: 'USED IN $usage INVOICES',
        );
        _catalogItems[index] = updatedItem;
        anyUpdated = true;
      }
    }

    if (anyUpdated) {
      await _saveCatalogItems();
    }
  }

  // Method to clear all local clients and catalog data
  Future<void> clearClientAndCatalogData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear in-memory caches
      _clients = [];
      _catalogItems = [];

      // Clear from SharedPreferences
      await prefs.remove(_clientsKey);
      await prefs.remove(_catalogItemsKey);

      debugPrint('Successfully cleared all client and catalog data');
    } catch (e) {
      debugPrint('Error clearing client and catalog data: $e');
    }
  }
}
