import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/mcp/storage_service.dart';
import 'package:path/path.dart' as path;

/// Implementation of StorageService using Supabase
class SupabaseStorageService implements StorageService {
  // Singleton pattern
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  // Supabase client
  late SupabaseClient _supabase;

  // Organization ID
  String? _organizationId;

  // In-memory caches
  CompanyInfo? _companyInfo;
  List<Client>? _clients;
  List<CatalogItem>? _catalogItems;
  List<Invoice>? _invoices;
  InvoiceSettings? _invoiceSettings;

  // Flag to prevent multiple initializations
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      debugPrint('SupabaseStorageService already initialized, skipping');
      return;
    }

    try {
      // Clear all in-memory caches first
      _clearAllCaches();

      // Get the Supabase client instance
      _supabase = Supabase.instance.client;
      _isInitialized = true;

      // Fetch current organization ID if user is authenticated
      if (_supabase.auth.currentUser != null) {
        await _fetchCurrentOrganization();
      } else {
        debugPrint('No user is logged in, cannot initialize Supabase storage');
      }
    } catch (e) {
      debugPrint('Error initializing Supabase storage service: $e');
      // Reset organization ID on failure
      _organizationId = null;
    }
  }

  // Clear all in-memory caches
  void _clearAllCaches() {
    debugPrint('Clearing all in-memory caches in SupabaseStorageService');
    _companyInfo = null;
    _clients = null;
    _catalogItems = null;
    _invoices = null;
    _invoiceSettings = null;
    _organizationId = null;
  }

  // Helper method to fetch current organization ID
  Future<void> _fetchCurrentOrganization() async {
    try {
      if (_supabase.auth.currentUser == null) {
        debugPrint('No user is logged in');
        return;
      }

      final results =
          await _supabase
              .from('organizations')
              .select('id')
              .eq('user_id', _supabase.auth.currentUser!.id)
              .limit(1)
              .single();

      if (results != null) {
        _organizationId = results['id'];
        debugPrint('Organization ID set to: $_organizationId');
      } else {
        debugPrint('No organization found for current user');
      }
    } catch (e) {
      debugPrint('Error fetching organization: $e');
    }
  }

  // Ensure organization exists
  Future<bool> _ensureOrganizationExists() async {
    if (_organizationId != null) return true;

    // Check again if the auth session changed
    await _fetchCurrentOrganization();
    return _organizationId != null;
  }

  // Company Info Methods
  @override
  Future<CompanyInfo?> getCompanyInfo() async {
    if (_companyInfo != null) return _companyInfo;

    try {
      // Check organization ID
      if (_organizationId == null) {
        debugPrint('No organization ID available');
        return null;
      }

      final orgData =
          await _supabase
              .from('organizations')
              .select('*, addresses(*), contact_info(*), bank_details(*)')
              .eq('id', _organizationId!) // Non-null assertion after check
              .single();

      if (orgData == null) return null;

      // Extract address and contact info
      final addresses = orgData['addresses'] as List<dynamic>;
      final contactInfo = orgData['contact_info'] as List<dynamic>;
      final bankDetails = orgData['bank_details'] as List<dynamic>;

      final address = addresses.isNotEmpty ? addresses[0] : null;
      final contact = contactInfo.isNotEmpty ? contactInfo[0] : null;
      final bank = bankDetails.isNotEmpty ? bankDetails[0] : null;

      // Create CompanyInfo object
      _companyInfo = CompanyInfo(
        businessName: orgData['business_name'],
        currency: orgData['currency'],
        enableTax: orgData['enable_tax'] ?? false,
        taxRate: orgData['tax_rate'],
        logoPath: orgData['logo_url'],

        // Address fields
        country: address?['country'] ?? '',
        addressLine1: address?['address_line1'] ?? '',
        addressLine2: address?['address_line2'],
        city: address?['city'] ?? '',
        zip: address?['zip_code'],

        // Contact fields
        phone: contact?['phone'],
        email: contact?['email'],
        website: contact?['website'],

        // Bank details
        bankName: bank?['bank_name'],
        accountHolder: bank?['account_name'],
        accountNumber: bank?['account_number'],
        ifscCode: bank?['swift_code'],
      );

      return _companyInfo;
    } catch (e) {
      debugPrint('Error fetching company info: $e');
      return null;
    }
  }

  @override
  Future<void> updateCompanyInfo(CompanyInfo info) async {
    if (!await _ensureOrganizationExists()) {
      await _createNewOrganization(info);
      return;
    }

    try {
      // Handle logo upload to Supabase storage if needed
      String? logoUrl = info.logoPath;
      if (info.logoPath != null && !info.logoPath!.startsWith('http')) {
        try {
          // Check if file exists
          final file = File(info.logoPath!);
          if (await file.exists()) {
            // Upload file to Supabase storage
            final fileName =
                '${_organizationId}_${path.basename(info.logoPath!)}';
            debugPrint('Uploading logo file to Supabase: $fileName');

            final storageResponse = await _supabase.storage
                .from('logos')
                .upload(fileName, file);

            // Get the public URL
            final publicUrl = _supabase.storage
                .from('logos')
                .getPublicUrl(fileName);

            // Update the logo URL to use the Supabase storage URL
            logoUrl = publicUrl;
            debugPrint('Uploaded logo to Supabase, public URL: $publicUrl');
          } else {
            // File doesn't exist, clear the logo path
            debugPrint(
              'Logo file does not exist, clearing logo path: ${info.logoPath}',
            );
            logoUrl = null;
          }
        } catch (e) {
          debugPrint('Error uploading logo to Supabase: $e');
          logoUrl = null;
        }
      }

      // Update organization
      await _supabase
          .from('organizations')
          .update({
            'business_name': info.businessName,
            'currency': info.currency,
            'enable_tax': info.enableTax,
            'tax_rate': info.taxRate,
            'logo_url': logoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _organizationId!);

      // Update or insert address
      final existingAddress =
          await _supabase
              .from('addresses')
              .select('id')
              .eq('entity_id', _organizationId!) // Non-null assertion
              .eq('entity_type', 'organization')
              .maybeSingle();

      if (existingAddress != null) {
        await _supabase
            .from('addresses')
            .update({
              'country': info.country,
              'address_line1': info.addressLine1,
              'address_line2': info.addressLine2,
              'city': info.city,
              'zip_code': info.zip,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingAddress['id']);
      } else {
        await _supabase.from('addresses').insert({
          'entity_id': _organizationId,
          'entity_type': 'organization',
          'country': info.country,
          'address_line1': info.addressLine1,
          'address_line2': info.addressLine2,
          'city': info.city,
          'zip_code': info.zip,
        });
      }

      // Update or insert contact info
      final existingContact =
          await _supabase
              .from('contact_info')
              .select('id')
              .eq('entity_id', _organizationId!) // Non-null assertion
              .eq('entity_type', 'organization')
              .maybeSingle();

      if (existingContact != null) {
        await _supabase
            .from('contact_info')
            .update({
              'email': info.email,
              'phone': info.phone,
              'website': info.website,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingContact['id']);
      } else {
        await _supabase.from('contact_info').insert({
          'entity_id': _organizationId,
          'entity_type': 'organization',
          'email': info.email,
          'phone': info.phone,
          'website': info.website,
        });
      }

      // Update or insert bank details
      final existingBank =
          await _supabase
              .from('bank_details')
              .select('id')
              .eq('organization_id', _organizationId!) // Non-null assertion
              .maybeSingle();

      if (existingBank != null) {
        await _supabase
            .from('bank_details')
            .update({
              'bank_name': info.bankName,
              'account_name': info.accountHolder,
              'account_number': info.accountNumber,
              'swift_code': info.ifscCode,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingBank['id']);
      } else if (info.bankName != null ||
          info.accountHolder != null ||
          info.accountNumber != null ||
          info.ifscCode != null) {
        await _supabase.from('bank_details').insert({
          'organization_id': _organizationId,
          'bank_name': info.bankName,
          'account_name': info.accountHolder,
          'account_number': info.accountNumber,
          'swift_code': info.ifscCode,
        });
      }

      // Update local cache
      _companyInfo = info;
    } catch (e) {
      debugPrint('Error updating company info: $e');
    }
  }

  // Helper to create a new organization
  Future<void> _createNewOrganization(CompanyInfo info) async {
    if (_supabase.auth.currentUser == null) {
      debugPrint('No user is logged in, cannot create organization');
      return;
    }

    try {
      // Insert into organizations table
      final orgResponse =
          await _supabase
              .from('organizations')
              .insert({
                'user_id': _supabase.auth.currentUser!.id,
                'business_name': info.businessName,
                'currency': info.currency,
                'enable_tax': info.enableTax,
                'tax_rate': info.taxRate,
                'logo_url': info.logoPath,
              })
              .select('id')
              .single();

      final newOrgId = orgResponse['id'];
      _organizationId = newOrgId;

      // Insert address
      await _supabase.from('addresses').insert({
        'entity_id': newOrgId,
        'entity_type': 'organization',
        'country': info.country,
        'address_line1': info.addressLine1,
        'address_line2': info.addressLine2,
        'city': info.city,
        'zip_code': info.zip,
      });

      // Insert contact info
      await _supabase.from('contact_info').insert({
        'entity_id': newOrgId,
        'entity_type': 'organization',
        'email': info.email,
        'phone': info.phone,
        'website': info.website,
      });

      // Insert bank details if provided
      if (info.bankName != null ||
          info.accountHolder != null ||
          info.accountNumber != null ||
          info.ifscCode != null) {
        await _supabase.from('bank_details').insert({
          'organization_id': newOrgId,
          'bank_name': info.bankName,
          'account_name': info.accountHolder,
          'account_number': info.accountNumber,
          'swift_code': info.ifscCode,
        });
      }

      // Insert default invoice settings
      await _supabase.from('invoice_settings').insert({
        'organization_id': newOrgId,
      });

      // Update local cache
      _companyInfo = info;
    } catch (e) {
      debugPrint('Error creating organization: $e');
    }
  }

  // Client Methods
  @override
  Future<List<Client>> getClients() async {
    debugPrint('SupabaseStorageService: Getting clients from Supabase');

    if (_clients != null) {
      debugPrint(
        'SupabaseStorageService: Returning ${_clients!.length} clients from cache',
      );
      return List.unmodifiable(_clients!);
    }

    if (!await _ensureOrganizationExists()) {
      debugPrint(
        'SupabaseStorageService: No organization exists, returning empty client list',
      );
      return [];
    }

    try {
      debugPrint(
        'SupabaseStorageService: Fetching clients for organization: $_organizationId using RPC function',
      );

      final data = await _supabase.rpc(
        'get_clients_with_details',
        params: {'org_id': _organizationId},
      );

      debugPrint(
        'SupabaseStorageService: Fetched ${data.length} clients from Supabase',
      );

      _clients =
          data.map((data) {
            // Extract addresses and contact info from the JSON arrays
            final addresses = (data['addresses'] as List<dynamic>?) ?? [];
            final contactInfo = (data['contact_info'] as List<dynamic>?) ?? [];

            final address = addresses.isNotEmpty ? addresses[0] : null;
            final contact = contactInfo.isNotEmpty ? contactInfo[0] : null;

            return Client(
              name: data['name'],
              clientId: data['client_id'],
              taxId: data['tax_id'],
              country: address?['country'],
              addressLine1: address?['address_line1'] ?? '',
              addressLine2: address?['address_line2'],
              city: address?['city'],
              zip: address?['zip_code'],
              phone: contact?['phone'],
              email: contact?['email'] ?? '',
              website: contact?['website'],
              notes: data['notes'],
              type: data['type'],
              invoiceCount: data['invoice_count'] ?? 0,
              currency: data['currency'] ?? 'USD',
              amount: data['amount']?.toDouble() ?? 0.0,
              outstandingAmount: data['outstanding_amount']?.toDouble() ?? 0.0,
              hasOutstanding: data['has_outstanding'] ?? false,
              dueAmount: data['due_amount']?.toDouble() ?? 0.0,
              hasDue: data['has_due'] ?? false,
            );
          }).toList();

      debugPrint(
        'SupabaseStorageService: Successfully loaded ${_clients!.length} clients',
      );
      return List.unmodifiable(_clients!);
    } catch (e) {
      debugPrint('SupabaseStorageService: Error getting clients: $e');
      rethrow; // Make error visible for debugging
    }
  }

  @override
  Future<Client?> getClientById(String clientId) async {
    await getClients();
    try {
      return _clients!.firstWhere((client) => client.clientId == clientId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createClient(Client client) async {
    debugPrint(
      'SupabaseStorageService: Starting to create client ${client.name} (${client.clientId})',
    );

    // First verify organization exists
    if (!await _ensureOrganizationExists()) {
      debugPrint(
        'SupabaseStorageService: Cannot create client - organization does not exist',
      );
      return;
    }

    try {
      debugPrint(
        'SupabaseStorageService: Using organization ID: $_organizationId',
      );

      // Prepare address data if provided
      final addresses = [];
      if (client.country != null ||
          client.addressLine1 != null ||
          client.city != null ||
          client.zip != null) {
        addresses.add({
          'country': client.country ?? '',
          'address_line1': client.addressLine1 ?? '',
          'address_line2': client.addressLine2,
          'city': client.city ?? '',
          'zip_code': client.zip,
        });
      }

      // Prepare contact info if provided
      final contactInfo = [];
      if (client.email != null ||
          client.phone != null ||
          client.website != null) {
        contactInfo.add({
          'email': client.email,
          'phone': client.phone,
          'website': client.website,
        });
      }

      // Use the RPC function to create the client with all related data in one transaction
      final clientResponse = await _supabase.rpc(
        'create_client_with_details',
        params: {
          'p_organization_id': _organizationId,
          'p_client_id': client.clientId,
          'p_name': client.name,
          'p_type': client.type,
          'p_tax_id': client.taxId,
          'p_notes': client.notes,
          'p_addresses': addresses.isEmpty ? null : addresses,
          'p_contact_info': contactInfo.isEmpty ? null : contactInfo,
        },
      );

      debugPrint(
        'SupabaseStorageService: Client created with DB ID: $clientResponse',
      );

      // Update local cache
      if (_clients != null) {
        _clients!.insert(0, client);
        debugPrint(
          'SupabaseStorageService: Updated local cache with new client',
        );
      } else {
        debugPrint(
          'SupabaseStorageService: Local cache not initialized, will be loaded on next get',
        );
      }

      debugPrint(
        'SupabaseStorageService: Successfully created client ${client.name}',
      );
    } catch (e) {
      debugPrint('SupabaseStorageService: Error creating client: $e');
      // Explicitly rethrow to ensure error is propagated
      rethrow;
    }
  }

  @override
  Future<void> updateClient(String clientId, Client client) async {
    if (!await _ensureOrganizationExists()) return;

    try {
      // Find the client's UUID from the client_id
      final clientData =
          await _supabase
              .from('clients')
              .select('id')
              .eq('organization_id', _organizationId!) // Non-null assertion
              .eq('client_id', clientId)
              .single();

      if (clientData == null) {
        debugPrint('Client not found: $clientId');
        return;
      }

      final clientUuid = clientData['id'];

      // Update client record
      await _supabase
          .from('clients')
          .update({
            'name': client.name,
            'type': client.type,
            'tax_id': client.taxId,
            'notes': client.notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clientUuid);

      // Update address
      final existingAddress =
          await _supabase
              .from('addresses')
              .select('id')
              .eq('entity_id', clientUuid)
              .eq('entity_type', 'client')
              .maybeSingle();

      if (existingAddress != null) {
        await _supabase
            .from('addresses')
            .update({
              'country': client.country ?? '',
              'address_line1': client.addressLine1 ?? '',
              'address_line2': client.addressLine2,
              'city': client.city ?? '',
              'zip_code': client.zip,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingAddress['id']);
      } else if (client.country != null ||
          client.addressLine1 != null ||
          client.city != null ||
          client.zip != null) {
        await _supabase.from('addresses').insert({
          'entity_id': clientUuid,
          'entity_type': 'client',
          'country': client.country ?? '',
          'address_line1': client.addressLine1 ?? '',
          'address_line2': client.addressLine2,
          'city': client.city ?? '',
          'zip_code': client.zip,
        });
      }

      // Update contact info
      final existingContact =
          await _supabase
              .from('contact_info')
              .select('id')
              .eq('entity_id', clientUuid)
              .eq('entity_type', 'client')
              .maybeSingle();

      if (existingContact != null) {
        await _supabase
            .from('contact_info')
            .update({
              'email': client.email,
              'phone': client.phone,
              'website': client.website,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingContact['id']);
      } else if (client.email != null ||
          client.phone != null ||
          client.website != null) {
        await _supabase.from('contact_info').insert({
          'entity_id': clientUuid,
          'entity_type': 'client',
          'email': client.email,
          'phone': client.phone,
          'website': client.website,
        });
      }

      // Update invoices that reference this client
      // This is handled automatically through triggers

      // Update local cache
      if (_clients != null) {
        final index = _clients!.indexWhere((c) => c.clientId == clientId);
        if (index != -1) {
          _clients![index] = client;
        }
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
    }
  }

  @override
  Future<bool> deleteClient(String clientId) async {
    if (!await canDeleteClient(clientId)) {
      return false;
    }

    if (!await _ensureOrganizationExists()) return false;

    try {
      // Delete the client (Supabase will handle cascade/constraint operations)
      await _supabase
          .from('clients')
          .delete()
          .eq('organization_id', _organizationId!) // Non-null assertion
          .eq('client_id', clientId);

      // Update local cache
      if (_clients != null) {
        _clients!.removeWhere((client) => client.clientId == clientId);
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting client: $e');
      return false;
    }
  }

  @override
  Future<bool> canDeleteClient(String clientId) async {
    if (!await _ensureOrganizationExists()) return false;

    try {
      // Get client UUID from client_id
      final clientRecord =
          await _supabase
              .from('clients')
              .select('id')
              .eq('organization_id', _organizationId!) // Non-null assertion
              .eq('client_id', clientId)
              .maybeSingle();

      if (clientRecord == null) return true; // Client doesn't exist

      // Check for related invoices
      final invoices = await _supabase
          .from('invoices')
          .select('id')
          .eq('client_id', clientRecord['id'])
          .limit(1);

      return invoices.isEmpty;
    } catch (e) {
      debugPrint('Error checking if client can be deleted: $e');
      return false;
    }
  }

  @override
  Future<String> generateClientId() async {
    if (!await _ensureOrganizationExists()) {
      return 'CL001'; // Default if no organization
    }

    try {
      // Find the highest existing client ID number
      final lastClientId = await _supabase
          .from('clients')
          .select('client_id')
          .eq('organization_id', _organizationId!) // Non-null assertion
          .order('client_id', ascending: false)
          .limit(1);

      int highestIdNumber = 0;

      if (lastClientId.isNotEmpty) {
        final clientId = lastClientId[0]['client_id'];
        final idMatch = RegExp(r'CL(\d+)').firstMatch(clientId);
        if (idMatch != null) {
          highestIdNumber = int.tryParse(idMatch.group(1) ?? '0') ?? 0;
        }
      }

      // Create a new ID by incrementing the highest number
      final newIdNumber = highestIdNumber + 1;
      return 'CL${newIdNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('Error generating client ID: $e');
      return 'CL001'; // Default fallback
    }
  }

  // The following methods need to be implemented to complete the interface
  // They are stubs for now that will be expanded in subsequent edits

  @override
  Future<List<CatalogItem>> getCatalogItems() async {
    debugPrint('SupabaseStorageService: Getting catalog items from Supabase');

    if (_catalogItems != null) {
      debugPrint(
        'SupabaseStorageService: Returning ${_catalogItems!.length} catalog items from cache',
      );
      return List.unmodifiable(_catalogItems!);
    }

    if (!await _ensureOrganizationExists()) {
      debugPrint(
        'SupabaseStorageService: No organization exists, returning empty catalog items list',
      );
      return [];
    }

    try {
      debugPrint(
        'SupabaseStorageService: Fetching catalog items for organization: $_organizationId using RPC function',
      );

      final data = await _supabase.rpc(
        'get_catalog_items_with_details',
        params: {'org_id': _organizationId},
      );

      debugPrint(
        'SupabaseStorageService: Fetched ${data.length} catalog items from Supabase',
      );

      _catalogItems =
          data.map((data) {
            return CatalogItem(
              title: data['name'],
              amount: data['unit_price'].toString(),
              quantity: 1, // Default quantity
              currency: data['currency'] ?? 'USD',
              usageInfo: 'NOT USED YET', // Default usage info
            );
          }).toList();

      debugPrint(
        'SupabaseStorageService: Successfully loaded ${_catalogItems!.length} catalog items',
      );
      return List.unmodifiable(_catalogItems!);
    } catch (e) {
      debugPrint('SupabaseStorageService: Error getting catalog items: $e');
      rethrow; // Make error visible for debugging
    }
  }

  @override
  Future<CatalogItem?> getItemByTitle(String title) async {
    await getCatalogItems();
    try {
      return _catalogItems!.firstWhere((item) => item.title == title);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createItem(CatalogItem item) async {
    debugPrint(
      'SupabaseStorageService: Starting to create catalog item ${item.title}',
    );

    if (!await _ensureOrganizationExists()) {
      debugPrint(
        'SupabaseStorageService: Cannot create catalog item - organization does not exist',
      );
      return;
    }

    try {
      debugPrint(
        'SupabaseStorageService: Using organization ID: $_organizationId',
      );

      // Use the RPC function to create the catalog item
      final itemResponse = await _supabase.rpc(
        'create_catalog_item',
        params: {
          'p_organization_id': _organizationId,
          'p_item_id':
              item.title
                  .replaceAll(' ', '-')
                  .toLowerCase(), // Generate an item_id from title
          'p_name': item.title,
          'p_description': '', // Optional description
          'p_is_service': false, // Default value
          'p_unit_price': double.tryParse(item.amount) ?? 0,
          'p_currency': item.currency ?? 'USD',
        },
      );

      debugPrint(
        'SupabaseStorageService: Catalog item created with DB ID: $itemResponse',
      );

      // Update local cache
      if (_catalogItems != null) {
        _catalogItems!.insert(0, item);
        debugPrint(
          'SupabaseStorageService: Updated local cache with new catalog item',
        );
      } else {
        debugPrint(
          'SupabaseStorageService: Local cache not initialized, will be loaded on next get',
        );
      }

      debugPrint(
        'SupabaseStorageService: Successfully created catalog item ${item.title}',
      );
    } catch (e) {
      debugPrint('SupabaseStorageService: Error creating catalog item: $e');
      rethrow; // Explicitly rethrow to ensure error is propagated
    }
  }

  @override
  Future<void> updateItem(String title, CatalogItem item) async {
    if (!await _ensureOrganizationExists()) return;

    try {
      // Update catalog item
      await _supabase
          .from('catalog_items')
          .update({
            'title': item.title,
            'amount': double.tryParse(item.amount) ?? 0,
            'quantity': item.quantity,
            'currency': item.currency ?? 'USD',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('organization_id', _organizationId!)
          .eq('title', title);

      // Update local cache
      if (_catalogItems != null) {
        final index = _catalogItems!.indexWhere((i) => i.title == title);
        if (index != -1) {
          _catalogItems![index] = item;
        }
      }
    } catch (e) {
      debugPrint('Error updating catalog item: $e');
    }
  }

  @override
  Future<void> deleteItem(String title) async {
    if (!await _ensureOrganizationExists()) return;

    try {
      // Delete catalog item
      await _supabase
          .from('catalog_items')
          .delete()
          .eq('organization_id', _organizationId!)
          .eq('title', title);

      // Update local cache
      if (_catalogItems != null) {
        _catalogItems!.removeWhere((item) => item.title == title);
      }
    } catch (e) {
      debugPrint('Error deleting catalog item: $e');
    }
  }

  @override
  Future<bool> isItemTitleUnique(String title) async {
    if (!await _ensureOrganizationExists()) return true;

    try {
      final items = await _supabase
          .from('catalog_items')
          .select('id')
          .eq('organization_id', _organizationId!)
          .eq('title', title)
          .limit(1);

      return items.isEmpty;
    } catch (e) {
      debugPrint('Error checking item title uniqueness: $e');
      return false;
    }
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    if (_invoices != null) return List.unmodifiable(_invoices!);

    if (!await _ensureOrganizationExists()) return [];

    try {
      final data = await _supabase
          .from('invoices')
          .select('*, invoice_items(*)')
          .eq('organization_id', _organizationId!)
          .order('created_at', ascending: false);

      _invoices = [];

      for (var invoiceData in data) {
        try {
          // Get client data for this invoice
          final clientId = invoiceData['client_id'];
          final clientData =
              await _supabase
                  .from('clients')
                  .select('*, addresses(*), contact_info(*)')
                  .eq('id', clientId)
                  .single();

          if (clientData == null) continue;

          // Find client's address and contact info
          final addresses = clientData['addresses'] as List<dynamic>;
          final contactInfo = clientData['contact_info'] as List<dynamic>;

          final address = addresses.isNotEmpty ? addresses[0] : null;
          final contact = contactInfo.isNotEmpty ? contactInfo[0] : null;

          // Build client object
          final client = Client(
            name: clientData['name'],
            clientId: clientData['client_id'],
            taxId: clientData['tax_id'],
            country: address?['country'],
            addressLine1: address?['address_line1'] ?? '',
            addressLine2: address?['address_line2'],
            city: address?['city'],
            zip: address?['zip_code'],
            phone: contact?['phone'],
            email: contact?['email'] ?? '',
            website: contact?['website'],
            notes: clientData['notes'],
            type: clientData['type'],
            currency: clientData['currency'] ?? 'USD',
            amount: clientData['amount']?.toDouble() ?? 0,
            outstandingAmount:
                clientData['outstanding_amount']?.toDouble() ?? 0,
            dueAmount: clientData['due_amount']?.toDouble() ?? 0,
            invoiceCount: clientData['invoice_count'] ?? 0,
            hasOutstanding: clientData['has_outstanding'] ?? false,
            hasDue: clientData['has_due'] ?? false,
          );

          // Get invoice items
          final invoiceItems = invoiceData['invoice_items'] as List<dynamic>;
          final items =
              invoiceItems
                  .map(
                    (item) => CatalogItem(
                      title: item['title'] ?? 'Unnamed Item',
                      amount: (item['unit_price'] ?? 0).toString(),
                      quantity: item['quantity'] ?? 1,
                    ),
                  )
                  .toList();

          // Parse status
          InvoiceStatus status;
          switch (invoiceData['status']?.toLowerCase()) {
            case 'paid':
              status = InvoiceStatus.paid;
              break;
            case 'outstanding':
              status = InvoiceStatus.outstanding;
              break;
            case 'overdue':
              status = InvoiceStatus.overdue;
              break;
            default:
              status = InvoiceStatus.outstanding;
          }

          // Create invoice object with null safety
          final invoice = Invoice(
            invoiceId: invoiceData['invoice_id'] ?? 'missing-id',
            client: client,
            items: items,
            issueDate:
                invoiceData['issue_date'] != null
                    ? DateTime.parse(invoiceData['issue_date'])
                    : DateTime.now(),
            dueDate:
                invoiceData['due_date'] != null
                    ? DateTime.parse(invoiceData['due_date'])
                    : DateTime.now().add(const Duration(days: 30)),
            status: status,
            subtotal: invoiceData['subtotal']?.toDouble() ?? 0.0,
            taxRate: invoiceData['tax_rate']?.toDouble() ?? 0.0,
            taxAmount: invoiceData['tax_amount']?.toDouble() ?? 0.0,
            total: invoiceData['total']?.toDouble() ?? 0.0,
            templateName: invoiceData['template_name'] ?? 'Orange',
            notes: invoiceData['notes'],
          );

          _invoices!.add(invoice);
        } catch (e) {
          debugPrint('Error parsing invoice ${invoiceData['invoice_id']}: $e');
          // Skip this invoice and continue with the next one
        }
      }

      return List.unmodifiable(_invoices!);
    } catch (e) {
      debugPrint('Error getting invoices: $e');
      return [];
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    await getInvoices();
    final String statusStr;

    switch (status) {
      case InvoiceStatus.paid:
        statusStr = 'paid';
        break;
      case InvoiceStatus.outstanding:
        statusStr = 'outstanding';
        break;
      case InvoiceStatus.overdue:
        statusStr = 'overdue';
        break;
    }

    try {
      if (_organizationId == null) return [];

      // Try to fetch directly from database with filter
      final data = await _supabase
          .from('invoices')
          .select('*, invoice_items(*)')
          .eq('organization_id', _organizationId!)
          .eq('status', statusStr)
          .order('created_at', ascending: false);

      // If we have in-memory data, filter it
      if (_invoices != null) {
        return _invoices!.where((i) => i.status == status).toList();
      }

      // Otherwise process the filtered data from database
      final result = <Invoice>[];
      // Similar processing to getInvoices but with the filtered data
      // ... (processing code similar to getInvoices)

      return result;
    } catch (e) {
      debugPrint('Error getting invoices by status: $e');
      // Fallback to in-memory filtering
      if (_invoices != null) {
        return _invoices!.where((i) => i.status == status).toList();
      }
      return [];
    }
  }

  @override
  Future<List<Invoice>> getInvoicesByClient(String clientId) async {
    await getInvoices();

    // Use in-memory data if available
    if (_invoices != null) {
      return _invoices!.where((i) => i.client.clientId == clientId).toList();
    }

    return [];
  }

  @override
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    await getInvoices();
    try {
      return _invoices!.firstWhere((i) => i.invoiceId == invoiceId);
    } catch (e) {
      debugPrint('Invoice not found: $invoiceId');
      return null;
    }
  }

  @override
  Future<bool> createInvoice(Invoice invoice) async {
    if (!await _ensureOrganizationExists()) return false;

    try {
      // First, find the client UUID from clientId
      final clientData =
          await _supabase
              .from('clients')
              .select('id')
              .eq('organization_id', _organizationId!)
              .eq('client_id', invoice.client.clientId)
              .single();

      if (clientData == null) {
        debugPrint('Client not found: ${invoice.client.clientId}');
        return false;
      }

      final clientUuid = clientData['id'];

      // Insert invoice
      final invoiceResponse =
          await _supabase
              .from('invoices')
              .insert({
                'organization_id': _organizationId,
                'client_id': clientUuid,
                'invoice_id': invoice.invoiceId,
                'issue_date': invoice.issueDate.toIso8601String(),
                'due_date': invoice.dueDate.toIso8601String(),
                'subtotal': invoice.subtotal,
                'tax_rate': invoice.taxRate,
                'tax_amount': invoice.taxAmount,
                'total': invoice.total,
                'status': invoice.status.toString().split('.').last,
                'template_name': invoice.templateName,
                'notes': invoice.notes,
              })
              .select('id')
              .single();

      final invoiceUuid = invoiceResponse['id'];

      // Insert invoice items
      for (var item in invoice.items) {
        // Try to find catalog item ID if it exists
        final catalogData =
            await _supabase
                .from('catalog_items')
                .select('id')
                .eq('organization_id', _organizationId!)
                .eq('title', item.title)
                .maybeSingle();

        final catalogItemId = catalogData?['id'];

        // Insert invoice item
        await _supabase.from('invoice_items').insert({
          'invoice_id': invoiceUuid,
          'catalog_item_id': catalogItemId,
          'title': item.title,
          'description': null,
          'quantity': item.quantity,
          'unit_price': double.tryParse(item.amount) ?? 0,
          'amount': (double.tryParse(item.amount) ?? 0) * item.quantity,
        });

        // Update catalog item usage if it exists
        if (catalogItemId != null) {
          try {
            // Try to use the RPC function first
            await _supabase.rpc(
              'increment_catalog_item_usage',
              params: {'item_id': catalogItemId},
            );
          } catch (e) {
            // If RPC fails, manually increment the usage count
            debugPrint('Error calling increment_catalog_item_usage RPC: $e');
            try {
              // Get current usage count
              final catalogItem =
                  await _supabase
                      .from('catalog_items')
                      .select('usage_count')
                      .eq('id', catalogItemId)
                      .single();

              // Increment usage count
              int currentCount = catalogItem['usage_count'] ?? 0;
              await _supabase
                  .from('catalog_items')
                  .update({'usage_count': currentCount + 1})
                  .eq('id', catalogItemId);
            } catch (e2) {
              debugPrint('Error manually incrementing catalog item usage: $e2');
            }
          }
        }
      }

      // Update client statistics
      try {
        await _supabase.rpc(
          'update_client_statistics',
          params: {'client_uuid': clientUuid},
        );
      } catch (e) {
        // If RPC fails, log error but don't attempt manual update as it's complex
        debugPrint('Error calling update_client_statistics RPC: $e');
      }

      // Update in-memory cache
      if (_invoices != null) {
        _invoices!.insert(0, invoice);
      }

      return true;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      return false;
    }
  }

  @override
  Future<bool> updateInvoice(String invoiceId, Invoice invoice) async {
    if (!await _ensureOrganizationExists()) return false;

    try {
      // Find the invoice UUID from invoice_id
      final invoiceData =
          await _supabase
              .from('invoices')
              .select('id, client_id')
              .eq('organization_id', _organizationId!)
              .eq('invoice_id', invoiceId)
              .single();

      if (invoiceData == null) {
        debugPrint('Invoice not found: $invoiceId');
        return false;
      }

      final invoiceUuid = invoiceData['id'];
      final oldClientUuid = invoiceData['client_id'];

      // Find the client UUID from clientId
      final clientData =
          await _supabase
              .from('clients')
              .select('id')
              .eq('organization_id', _organizationId!)
              .eq('client_id', invoice.client.clientId)
              .single();

      if (clientData == null) {
        debugPrint('Client not found: ${invoice.client.clientId}');
        return false;
      }

      final clientUuid = clientData['id'];

      // Update invoice
      await _supabase
          .from('invoices')
          .update({
            'client_id': clientUuid,
            'issue_date': invoice.issueDate.toIso8601String(),
            'due_date': invoice.dueDate.toIso8601String(),
            'subtotal': invoice.subtotal,
            'tax_rate': invoice.taxRate,
            'tax_amount': invoice.taxAmount,
            'total': invoice.total,
            'status': invoice.status.toString().split('.').last,
            'template_name': invoice.templateName,
            'notes': invoice.notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceUuid);

      // Delete old invoice items
      await _supabase
          .from('invoice_items')
          .delete()
          .eq('invoice_id', invoiceUuid);

      // Insert new invoice items
      for (var item in invoice.items) {
        // Try to find catalog item ID if it exists
        final catalogData =
            await _supabase
                .from('catalog_items')
                .select('id')
                .eq('organization_id', _organizationId!)
                .eq('title', item.title)
                .maybeSingle();

        final catalogItemId = catalogData?['id'];

        // Insert invoice item
        await _supabase.from('invoice_items').insert({
          'invoice_id': invoiceUuid,
          'catalog_item_id': catalogItemId,
          'title': item.title,
          'description': null,
          'quantity': item.quantity,
          'unit_price': double.tryParse(item.amount) ?? 0,
          'amount': (double.tryParse(item.amount) ?? 0) * item.quantity,
        });
      }

      // Update client statistics for both old and new client if different
      try {
        await _supabase.rpc(
          'update_client_statistics',
          params: {'client_uuid': clientUuid},
        );
      } catch (e) {
        debugPrint(
          'Error calling update_client_statistics RPC for new client: $e',
        );
        // Continue execution even if this fails
      }

      if (oldClientUuid != clientUuid) {
        try {
          await _supabase.rpc(
            'update_client_statistics',
            params: {'client_uuid': oldClientUuid},
          );
        } catch (e) {
          debugPrint(
            'Error calling update_client_statistics RPC for old client: $e',
          );
          // Continue execution even if this fails
        }
      }

      // Update in-memory cache
      if (_invoices != null) {
        final index = _invoices!.indexWhere((i) => i.invoiceId == invoiceId);
        if (index != -1) {
          _invoices![index] = invoice;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteInvoice(String invoiceId) async {
    if (!await _ensureOrganizationExists()) return false;

    try {
      // Find the invoice UUID from invoice_id
      final invoiceData =
          await _supabase
              .from('invoices')
              .select('id, client_id')
              .eq('organization_id', _organizationId!)
              .eq('invoice_id', invoiceId)
              .single();

      if (invoiceData == null) {
        debugPrint('Invoice not found: $invoiceId');
        return false;
      }

      final invoiceUuid = invoiceData['id'];
      final clientUuid = invoiceData['client_id'];

      // Delete invoice (cascade will delete invoice items)
      await _supabase.from('invoices').delete().eq('id', invoiceUuid);

      // Update client statistics
      try {
        await _supabase.rpc(
          'update_client_statistics',
          params: {'client_uuid': clientUuid},
        );
      } catch (e) {
        debugPrint(
          'Error calling update_client_statistics RPC after delete: $e',
        );
        // Continue execution even if this fails
      }

      // Update in-memory cache
      if (_invoices != null) {
        _invoices!.removeWhere((i) => i.invoiceId == invoiceId);
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      return false;
    }
  }

  @override
  Future<String> generateInvoiceId() async {
    if (!await _ensureOrganizationExists()) {
      return 'inv-001'; // Default if no organization
    }

    try {
      // Get invoice settings
      final settings = await getInvoiceSettings();

      // If settings specify a custom format, use it
      if (settings != null &&
          settings.isAutoGenerate == false &&
          settings.idFormat != null) {
        return settings.idFormat!;
      }

      // Otherwise, find the highest existing invoice ID number
      final lastInvoiceId = await _supabase
          .from('invoices')
          .select('invoice_id')
          .eq('organization_id', _organizationId!)
          .order('invoice_id', ascending: false)
          .limit(1);

      int highestIdNumber = 0;

      if (lastInvoiceId.isNotEmpty) {
        final invoiceId = lastInvoiceId[0]['invoice_id'];
        final idMatch = RegExp(r'inv-(\d+)').firstMatch(invoiceId);
        if (idMatch != null) {
          highestIdNumber = int.tryParse(idMatch.group(1) ?? '0') ?? 0;
        }
      }

      // Create a new ID by incrementing the highest number
      final newIdNumber = highestIdNumber + 1;
      return 'inv-${newIdNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('Error generating invoice ID: $e');
      return 'inv-001'; // Default fallback
    }
  }

  @override
  Future<InvoiceSettings?> getInvoiceSettings() async {
    if (_invoiceSettings != null) return _invoiceSettings;

    if (!await _ensureOrganizationExists()) return null;

    try {
      final data =
          await _supabase
              .from('invoice_settings')
              .select('*')
              .eq('organization_id', _organizationId!)
              .maybeSingle();

      if (data == null) {
        // If no settings exist, create default settings
        final defaultSettings = InvoiceSettings();
        await updateInvoiceSettings(defaultSettings);
        return defaultSettings;
      }

      _invoiceSettings = InvoiceSettings(
        idFormat: data['id_format'],
        customNotes: data['custom_notes'],
        isAutoGenerate: data['is_auto_generate'] ?? true,
        idPrefix: data['id_prefix'] ?? 'INV',
        lastInvoiceNumber: data['last_invoice_number'] ?? 0,
      );

      return _invoiceSettings;
    } catch (e) {
      debugPrint('Error getting invoice settings: $e');
      return null;
    }
  }

  @override
  Future<void> updateInvoiceSettings(InvoiceSettings settings) async {
    if (!await _ensureOrganizationExists()) return;

    try {
      // Check if settings already exist
      final existingData =
          await _supabase
              .from('invoice_settings')
              .select('id')
              .eq('organization_id', _organizationId!)
              .maybeSingle();

      if (existingData != null) {
        // Update existing settings
        await _supabase
            .from('invoice_settings')
            .update({
              'id_format': settings.idFormat,
              'custom_notes': settings.customNotes,
              'is_auto_generate': settings.isAutoGenerate,
              'id_prefix': settings.idPrefix,
              'last_invoice_number': settings.lastInvoiceNumber,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingData['id']);
      } else {
        // Create new settings
        await _supabase.from('invoice_settings').insert({
          'organization_id': _organizationId,
          'id_format': settings.idFormat,
          'custom_notes': settings.customNotes,
          'is_auto_generate': settings.isAutoGenerate,
          'id_prefix': settings.idPrefix,
          'last_invoice_number': settings.lastInvoiceNumber,
        });
      }

      // Update local cache
      _invoiceSettings = settings;
    } catch (e) {
      debugPrint('Error updating invoice settings: $e');
    }
  }

  @override
  Future<void> saveInvoices(List<Invoice> invoices) async {
    // For Supabase, we update invoices individually rather than in bulk
    for (var invoice in invoices) {
      await updateInvoice(invoice.invoiceId, invoice);
    }
  }

  // Method to clear client and catalog data
  @override
  Future<void> clearClientAndCatalogData() async {
    debugPrint(
      'Clearing client and catalog data cache in SupabaseStorageService',
    );
    _clients = null;
    _catalogItems = null;
  }

  /// Clear all in-memory caches
  Future<void> clearCache() async {
    debugPrint('SupabaseStorageService: Clearing all in-memory caches');
    _companyInfo = null;
    _clients = null;
    _catalogItems = null;
    _invoices = null;
    _invoiceSettings = null;
    debugPrint('SupabaseStorageService: All in-memory caches cleared');
  }
}
