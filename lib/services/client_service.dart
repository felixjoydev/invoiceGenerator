import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/services/repository/client_repository.dart';

class ClientService with ChangeNotifier {
  // Singleton pattern
  static final ClientService _instance = ClientService._internal();

  factory ClientService() {
    return _instance;
  }

  ClientService._internal();

  // Local storage key
  static const String _storageKey = 'clients';

  // In-memory list of clients
  List<Client> _clients = [];

  // Repository for Supabase interaction
  final ClientRepository _clientRepository = ClientRepository();

  // Initialization flags to prevent recursive init
  bool _isInitializing = false;
  bool _isInitialized = false;

  // Get all clients
  List<Client> get clients => List.unmodifiable(_clients);

  // Initialize the service - load clients from storage
  Future<void> init() async {
    // Skip if already initialized or initializing
    if (_isInitialized) return;
    if (_isInitializing) {
      debugPrint(
        'ClientService - Already initializing, skipping duplicate init call',
      );
      return;
    }

    _isInitializing = true;
    try {
      // Check if user is authenticated
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        // User is authenticated, try to load from Supabase first
        debugPrint('User authenticated, loading clients from Supabase');
        await _loadClientsFromSupabase();
      } else {
        // User not authenticated, load from local storage
        debugPrint('No authenticated user, loading clients from local storage');
        await _loadClients();
      }

      // If there are clients but no authenticated user, clear them
      if (currentUser == null && _clients.isNotEmpty) {
        debugPrint(
          'No authenticated user but found clients - clearing local data',
        );
        _clients = [];
        await _saveClients();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing client service: $e');
      // Reset clients on error
      _clients = [];
    } finally {
      _isInitializing = false;
    }
  }

  // Load clients from Supabase
  Future<void> _loadClientsFromSupabase() async {
    try {
      debugPrint('Loading clients from Supabase');
      final clientsFromSupabase = await _clientRepository.getAll();

      if (clientsFromSupabase.isNotEmpty) {
        debugPrint('Found ${clientsFromSupabase.length} clients in Supabase');
        _clients = clientsFromSupabase;

        // Save to local storage for offline access
        await _saveClients();
        notifyListeners();
        return;
      } else {
        debugPrint('No clients found in Supabase, checking local storage');
        // If no clients in Supabase, try loading from local
        await _loadClients();

        // If we have local clients, sync them to Supabase
        if (_clients.isNotEmpty) {
          debugPrint('Found local clients, syncing to Supabase');
          await _syncClientsToSupabase();
        }
      }
    } catch (e) {
      debugPrint('Error loading clients from Supabase: $e');
      // Fallback to local storage
      await _loadClients();
    }
  }

  // Sync all local clients to Supabase
  Future<void> _syncClientsToSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user, skipping Supabase sync');
        return;
      }

      debugPrint('Syncing ${_clients.length} clients to Supabase');

      // For each client in memory, create or update in Supabase
      for (final client in _clients) {
        try {
          // Ensure client has user_id set to current user
          final clientWithUserId = client.toMap();
          clientWithUserId['user_id'] = user.id;

          // Convert map back to Client object
          final clientToSync = Client.fromMap(clientWithUserId);

          // Create client in Supabase
          await _clientRepository.create(clientToSync);
          debugPrint('Client ${client.name} synced to Supabase');
        } catch (e) {
          debugPrint('Error syncing client ${client.name}: $e');
        }
      }

      debugPrint('Finished syncing clients to Supabase');
    } catch (e) {
      debugPrint('Error syncing clients to Supabase: $e');
    }
  }

  // Load clients from shared preferences
  Future<void> _loadClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? clientsJson = prefs.getString(_storageKey);

      if (clientsJson != null) {
        final List<dynamic> decoded = jsonDecode(clientsJson);
        _clients = decoded.map((item) => Client.fromMap(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
    }
  }

  // Save clients to shared preferences
  Future<void> _saveClients() async {
    try {
      debugPrint('Saving ${_clients.length} clients to shared preferences');

      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> clientsData =
          _clients.map((client) => client.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(clientsData));

      debugPrint('Clients saved successfully to shared preferences');
    } catch (e) {
      debugPrint('Error saving clients: $e');
    }
  }

  // Add a client to the list
  Future<void> addClient(Client client) async {
    // Add to beginning of list for newest clients to appear at top
    _clients.insert(0, client);

    // Save to storage
    await _saveClients();

    // Save to Supabase if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Ensure client has user_id set to current user
        final clientWithUserId = client.toMap();
        clientWithUserId['user_id'] = user.id;

        // Convert map back to Client object
        final clientToSync = Client.fromMap(clientWithUserId);

        // Create client in Supabase
        await _clientRepository.create(clientToSync);
        debugPrint('Client ${client.name} created in Supabase');
      } catch (e) {
        debugPrint('Error creating client in Supabase: $e');
      }
    }

    // Notify listeners that data has changed
    notifyListeners();
  }

  // Update an existing client
  Future<void> updateClient(String clientId, Client updatedClient) async {
    final index = _clients.indexWhere((client) => client.clientId == clientId);
    if (index != -1) {
      _clients[index] = updatedClient;
      await _saveClients();

      // Update in Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Ensure client has user_id set to current user
          final clientMap = updatedClient.toMap();
          clientMap['user_id'] = user.id;

          // Find the Supabase ID
          final supabaseClients = await _clientRepository.getAll();
          final supabaseClient = supabaseClients.firstWhere(
            (c) => c.clientId == clientId,
            orElse: () => updatedClient,
          );

          if (supabaseClient.id != null) {
            // Update client in Supabase
            await _clientRepository.update(supabaseClient.id!, updatedClient);
            debugPrint('Client ${updatedClient.name} updated in Supabase');
          } else {
            // Create if not found
            await _clientRepository.create(updatedClient);
            debugPrint(
              'Client ${updatedClient.name} created in Supabase (update)',
            );
          }
        } catch (e) {
          debugPrint('Error updating client in Supabase: $e');
        }
      }

      // Update this client in all invoices
      final invoiceService = InvoiceService();
      await invoiceService.init();
      await invoiceService.updateClientInInvoices(clientId, updatedClient);

      notifyListeners();
    }
  }

  // Update a client without triggering invoice updates (to prevent circular dependencies)
  Future<void> updateClientSilently(
    String clientId,
    Client updatedClient,
  ) async {
    final index = _clients.indexWhere((client) => client.clientId == clientId);
    if (index != -1) {
      _clients[index] = updatedClient;
      await _saveClients();

      // Update in Supabase if user is authenticated but don't wait for it
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Find the Supabase ID
          final supabaseClients = await _clientRepository.getAll();
          final supabaseClient = supabaseClients.firstWhere(
            (c) => c.clientId == clientId,
            orElse: () => updatedClient,
          );

          if (supabaseClient.id != null) {
            // Update client in Supabase
            _clientRepository
                .update(supabaseClient.id!, updatedClient)
                .then((_) => debugPrint('Client silently updated in Supabase'))
                .catchError(
                  (e) => debugPrint('Error updating client silently: $e'),
                );
          }
        } catch (e) {
          // Log but don't rethrow to avoid breaking the update
          debugPrint('Error finding client in Supabase: $e');
        }
      }

      notifyListeners();
    }
  }

  // Delete a client
  Future<void> deleteClient(String clientId) async {
    // Delete from Supabase if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Find the Supabase ID
        final supabaseClients = await _clientRepository.getAll();
        final supabaseClient = supabaseClients.firstWhere(
          (c) => c.clientId == clientId,
          orElse:
              () => Client(
                name: "",
                clientId: "",
                country: "",
                addressLine1: "",
                city: "",
                currency: "USD",
                type: "organization",
              ),
        );

        if (supabaseClient.id != null) {
          // Delete client in Supabase
          await _clientRepository.delete(supabaseClient.id!);
          debugPrint('Client deleted from Supabase');
        }
      } catch (e) {
        debugPrint('Error deleting client from Supabase: $e');
      }
    }

    // Remove from local list
    _clients.removeWhere((client) => client.clientId == clientId);
    await _saveClients();
    notifyListeners();
  }

  // Generate a new client ID
  String generateClientId() {
    // Check if there's an authenticated user first
    final currentUser = Supabase.instance.client.auth.currentUser;
    bool isAuthenticated = currentUser != null;

    // Always start from 1 if no authenticated user or no existing clients
    int highestNumber = 0;

    // Only use existing numbers if authenticated to prevent ID conflicts
    if (isAuthenticated && _clients.isNotEmpty) {
      for (var client in _clients) {
        // Try to extract the numeric part of the client ID
        try {
          // Look for client IDs in the format "001", "002", etc.
          final int clientNumber = int.tryParse(client.clientId) ?? 0;
          if (clientNumber > highestNumber) {
            highestNumber = clientNumber;
          }
        } catch (_) {}
      }
    }

    // Create a new ID by incrementing the highest number and padding with zeros
    final nextNumber = highestNumber + 1;
    return nextNumber.toString().padLeft(3, '0');
  }

  // Clear all clients data (for testing/debugging)
  Future<void> clearAllClients() async {
    _clients = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    // If authenticated, attempt to delete clients from Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Get all client IDs
        final supabaseClients = await _clientRepository.getAll();

        // Delete each client
        for (final client in supabaseClients) {
          if (client.id != null) {
            await _clientRepository.delete(client.id!);
          }
        }
        debugPrint('Cleared all clients from Supabase');
      } catch (e) {
        debugPrint('Error clearing clients from Supabase: $e');
      }
    }

    notifyListeners();
  }

  // Public method to save clients (allows external access)
  Future<void> saveClients() async {
    try {
      debugPrint(
        'Manual saveClients() called - saving ${_clients.length} clients',
      );
      await _saveClients();
      debugPrint('Manual saveClients() completed successfully');
    } catch (e) {
      debugPrint('Error in manual saveClients(): $e');
    }
  }
}
