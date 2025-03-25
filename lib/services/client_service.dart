import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/mcp/storage_service_factory.dart';

class ClientService with ChangeNotifier {
  // Singleton pattern
  static final ClientService _instance = ClientService._internal();

  factory ClientService() {
    return _instance;
  }

  ClientService._internal();

  // In-memory list of clients
  List<Client> _clients = [];

  // Storage service factory
  final _storageFactory = StorageServiceFactory();

  // Get all clients
  List<Client> get clients => List.unmodifiable(_clients);

  // Initialize the service - load clients from storage
  Future<void> init() async {
    await _loadClients();
  }

  // Load clients from storage
  Future<void> _loadClients() async {
    try {
      await _storageFactory.init();
      _clients = await _storageFactory.service.getClients();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading clients: $e');
      _clients = [];
      notifyListeners();
    }
  }

  // Add a client to the list
  Future<void> addClient(Client client) async {
    try {
      debugPrint(
        'ClientService: Adding client ${client.name} (${client.clientId})',
      );
      debugPrint(
        'ClientService: Storage type: ${_storageFactory.currentStorageType}',
      );

      await _storageFactory.service.createClient(client);
      debugPrint('ClientService: Client added to storage service');

      // Refresh client list from storage to ensure consistency
      await _loadClients();
      debugPrint(
        'ClientService: Client list refreshed, new count: ${_clients.length}',
      );
    } catch (e) {
      debugPrint('Error adding client: $e');
    }
  }

  // Update an existing client
  Future<void> updateClient(String clientId, Client updatedClient) async {
    try {
      await _storageFactory.service.updateClient(clientId, updatedClient);

      // Refresh client list to get updated data
      await _loadClients();
    } catch (e) {
      debugPrint('Error updating client: $e');
    }
  }

  // Update a client without triggering invoice updates (to prevent circular dependencies)
  Future<void> updateClientSilently(
    String clientId,
    Client updatedClient,
  ) async {
    try {
      // Find client in memory
      final index = _clients.indexWhere(
        (client) => client.clientId == clientId,
      );
      if (index != -1) {
        _clients[index] = updatedClient;
        notifyListeners();

        // Update in storage without triggering cascading updates
        await _storageFactory.service.updateClient(clientId, updatedClient);
      }
    } catch (e) {
      debugPrint('Error updating client silently: $e');
    }
  }

  // Delete a client
  Future<void> deleteClient(String clientId) async {
    try {
      final success = await _storageFactory.service.deleteClient(clientId);

      if (success) {
        // Remove from in-memory list
        _clients.removeWhere((client) => client.clientId == clientId);
        notifyListeners();
      } else {
        debugPrint('Could not delete client with ID: $clientId');
      }
    } catch (e) {
      debugPrint('Error deleting client: $e');
    }
  }

  // Generate a new client ID
  Future<String> generateClientId() async {
    return await _storageFactory.service.generateClientId();
  }

  // Check if a client can be deleted (no associated invoices)
  Future<bool> canDeleteClient(String clientId) async {
    return await _storageFactory.service.canDeleteClient(clientId);
  }

  // Clear all clients data (for testing/debugging)
  Future<void> clearAllClients() async {
    // This is a destructive operation that only affects local storage
    // We don't provide this for remote storage for safety
    if (_storageFactory.currentStorageType == StorageType.local) {
      _clients = [];
      notifyListeners();
    }
  }
}
