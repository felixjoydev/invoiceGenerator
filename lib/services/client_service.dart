import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/client.dart';

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

  // Get all clients
  List<Client> get clients => List.unmodifiable(_clients);

  // Initialize the service - load clients from storage
  Future<void> init() async {
    await _loadClients();
  }

  // Load clients from shared preferences
  Future<void> _loadClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? clientsJson = prefs.getString(_storageKey);

      if (clientsJson != null) {
        final List<dynamic> clientsData = jsonDecode(clientsJson);

        // Clear existing clients
        _clients = [];

        // Convert each item to a Client object
        for (var clientData in clientsData) {
          try {
            // Make sure clientData is a Map<String, dynamic>
            if (clientData is Map) {
              final Map<String, dynamic> clientMap = Map<String, dynamic>.from(
                clientData,
              );

              // Ensure required fields for Client constructor are available
              if (!clientMap.containsKey('clientName') ||
                  clientMap['clientName'] == null) {
                clientMap['clientName'] = '';
              }
              if (!clientMap.containsKey('clientId') ||
                  clientMap['clientId'] == null) {
                clientMap['clientId'] = generateClientId();
              }
              if (!clientMap.containsKey('type') || clientMap['type'] == null) {
                clientMap['type'] = 'organization';
              }

              // Create and add the Client object
              _clients.add(Client.fromMap(clientMap));
            }
          } catch (e) {
            debugPrint('Error converting client data: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
      // Initialize with empty list if there's an error
      _clients = [];
    }

    // Notify listeners about the updated data
    notifyListeners();
  }

  // Save clients to shared preferences
  Future<void> _saveClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> clientsData =
          _clients.map((client) => client.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(clientsData));
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

    // Notify listeners that data has changed
    notifyListeners();
  }

  // Update an existing client
  Future<void> updateClient(String clientId, Client updatedClient) async {
    final index = _clients.indexWhere((client) => client.clientId == clientId);
    if (index != -1) {
      _clients[index] = updatedClient;
      await _saveClients();
      notifyListeners();
    }
  }

  // Delete a client
  Future<void> deleteClient(String clientId) async {
    _clients.removeWhere((client) => client.clientId == clientId);
    await _saveClients();
    notifyListeners();
  }

  // Generate a new client ID
  String generateClientId() {
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

  // Clear all clients data (for testing/debugging)
  Future<void> clearAllClients() async {
    _clients = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
