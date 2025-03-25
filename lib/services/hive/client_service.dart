import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:invoicegenerator/models/hive/client_model.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';
import 'package:invoicegenerator/services/hive/invoice_service.dart';

/// Service for managing clients using Hive
class ClientService extends ChangeNotifier {
  late Box<Client> _clientBox;
  bool _isInitialized = false;
  InvoiceService? _invoiceService;

  List<Client> _clients = [];
  List<Client> get clients => _clients;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await HiveConfig.initialize();
      _clientBox = Hive.box<Client>(HiveBoxes.clients);
      _loadClients();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing ClientService: $e');
      rethrow;
    }
  }

  /// Set the invoice service reference
  void setInvoiceService(InvoiceService invoiceService) {
    _invoiceService = invoiceService;
  }

  /// Load clients from Hive
  void _loadClients() {
    try {
      // Get all clients from the Hive box
      _clients = _clientBox.values.toList();

      // Sort clients by name
      _clients.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('Error loading clients: $e');
      _clients = [];
    }
  }

  /// Get a client by ID
  Client? getClientById(String clientId) {
    try {
      return _clientBox.get(clientId);
    } catch (e) {
      debugPrint('Error getting client by ID: $e');
      return null;
    }
  }

  /// Add a new client
  Future<bool> addClient(Client client) async {
    try {
      // Ensure client ID is unique
      final existingClient = _clientBox.get(client.clientId);
      if (existingClient != null) {
        debugPrint('Client with ID ${client.clientId} already exists');
        return false;
      }

      // Save client in Hive using clientId as key
      await _clientBox.put(client.clientId, client);

      // Reload clients
      _loadClients();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding client: $e');
      return false;
    }
  }

  /// Update an existing client
  Future<bool> updateClient(Client client) async {
    try {
      // Save client in Hive using clientId as key
      await _clientBox.put(client.clientId, client);

      // Update the client in all related invoices
      if (_invoiceService != null) {
        await _invoiceService!.updateClientInInvoices(client);
      }

      // Reload clients
      _loadClients();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating client: $e');
      return false;
    }
  }

  /// Update client without propagating changes to invoices
  Future<bool> updateClientSilently(Client client) async {
    try {
      // Save client in Hive using clientId as key
      await _clientBox.put(client.clientId, client);

      // Reload clients
      _loadClients();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating client silently: $e');
      return false;
    }
  }

  /// Delete a client
  Future<bool> deleteClient(String clientId) async {
    try {
      // Check if client exists
      final client = _clientBox.get(clientId);
      if (client == null) {
        debugPrint('Client with ID $clientId not found');
        return false;
      }

      // Delete client from Hive
      await _clientBox.delete(clientId);

      // Reload clients
      _loadClients();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting client: $e');
      return false;
    }
  }

  /// Check if client can be deleted
  Future<bool> canDeleteClient(String clientId) async {
    if (_invoiceService == null) return true;

    // Check if client has associated invoices
    return !await _invoiceService!.hasInvoicesForClient(clientId);
  }

  /// Generate a new client ID
  String generateClientId() {
    // Find the highest existing client ID
    int highestNumber = 0;

    for (final client in _clients) {
      if (client.clientId.startsWith('CL')) {
        try {
          final number = int.parse(client.clientId.substring(2));
          if (number > highestNumber) {
            highestNumber = number;
          }
        } catch (e) {
          // Skip invalid format
        }
      }
    }

    // Generate a new client ID with incremented number
    final newNumber = highestNumber + 1;
    return 'CL${newNumber.toString().padLeft(3, '0')}';
  }

  /// Search clients by name or other criteria
  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;

    query = query.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
          (client.email?.toLowerCase().contains(query) ?? false) ||
          (client.phone?.toLowerCase().contains(query) ?? false) ||
          client.clientId.toLowerCase().contains(query);
    }).toList();
  }

  /// Update client statistics based on invoices
  Future<void> updateClientStatistics(
    String clientId, {
    int? invoiceCount,
    double? amount,
    double? outstandingAmount,
    double? dueAmount,
  }) async {
    try {
      // Get client from Hive
      final client = _clientBox.get(clientId);
      if (client == null) return;

      // Update client statistics
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
        invoiceCount: invoiceCount ?? client.invoiceCount,
        amount: amount ?? client.amount,
        outstandingAmount: outstandingAmount ?? client.outstandingAmount,
        dueAmount: dueAmount ?? client.dueAmount,
      );

      // Save client in Hive without propagating changes
      await updateClientSilently(updatedClient);
    } catch (e) {
      debugPrint('Error updating client statistics: $e');
    }
  }
}
