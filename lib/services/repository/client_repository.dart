import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/repository/supabase_repository.dart';
import 'package:uuid/uuid.dart';

class ClientRepository extends SupabaseRepository<Client> {
  static final ClientRepository _instance = ClientRepository._internal();

  factory ClientRepository() {
    return _instance;
  }

  ClientRepository._internal();

  @override
  String get tableName => 'clients';

  @override
  Client fromJson(Map<String, dynamic> json) {
    return Client.fromMap(json);
  }

  @override
  Map<String, dynamic> toJson(Client client) {
    final map = client.toMap();

    // Make sure we have a user_id
    if (map['user_id'] == null) {
      map['user_id'] = currentUser?.id;
    }

    // Remove calculated fields that aren't stored in the database
    map.remove('invoice_count');
    map.remove('amount');
    map.remove('outstanding_amount');
    map.remove('has_outstanding');
    map.remove('due_amount');
    map.remove('has_due');

    // Make sure we have a client_id
    if (map['client_id'] == null || map['client_id'].isEmpty) {
      map['client_id'] = const Uuid().v4();
    }

    // Generate an ID if it's null - Supabase requires a non-null ID for insert
    if (map['id'] == null) {
      map['id'] = const Uuid().v4();
    }

    return map;
  }

  /// Override the update method to handle foreign key constraints
  @override
  Future<Client> update(String id, Client client) async {
    try {
      // Get the existing client first to preserve its ID
      final existingClient = await getById(id);

      if (existingClient == null) {
        // If client doesn't exist, fall back to create
        return await create(client);
      }

      // Convert both to maps for merging
      final existingMap = toJson(existingClient);
      final updateMap = toJson(client);

      // Create a merged map that preserves necessary IDs and relations
      final Map<String, dynamic> finalMap = {...updateMap};

      // Preserve critical fields to maintain referential integrity
      finalMap['id'] = existingMap['id'];
      finalMap['client_id'] = existingMap['client_id'];
      finalMap['user_id'] = existingMap['user_id'];

      // Set updated_at timestamp
      finalMap['updated_at'] = DateTime.now().toIso8601String();

      try {
        // Use updateOne to only update the specific record
        final response =
            await supabase
                .from(tableName)
                .update(finalMap)
                .eq('id', id)
                .select()
                .single();

        return fromJson(response);
      } catch (e) {
        debugPrint('Error with standard update in $tableName: $e');

        // If still failing, try a more targeted update that excludes problematic fields
        final minimalUpdate = {
          'name': finalMap['name'],
          'email': finalMap['email'],
          'phone': finalMap['phone'],
          'address_line1': finalMap['address_line1'],
          'address_line2': finalMap['address_line2'],
          'city': finalMap['city'],
          'postal_code': finalMap['postal_code'],
          'country': finalMap['country'],
          'updated_at': finalMap['updated_at'],
        };

        final response =
            await supabase
                .from(tableName)
                .update(minimalUpdate)
                .eq('id', id)
                .select()
                .single();

        return fromJson(response);
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  /// Get all clients with statistics
  Future<List<Client>> getAllWithStats() async {
    try {
      // First get all clients
      final clients = await getAll();

      // Then fetch statistics for each client
      final List<Client> enrichedClients = [];
      for (final client in clients) {
        final stats = await _getClientStats(client.id!);
        enrichedClients.add(
          client.copyWith(
            invoiceCount: stats['invoice_count'] ?? 0,
            amount: stats['total_amount'] ?? 0.0,
            outstandingAmount: stats['outstanding_amount'] ?? 0.0,
            hasOutstanding: (stats['outstanding_amount'] ?? 0.0) > 0,
            dueAmount: stats['due_amount'] ?? 0.0,
            hasDue: (stats['due_amount'] ?? 0.0) > 0,
          ),
        );
      }

      return enrichedClients;
    } catch (e) {
      debugPrint('Error fetching clients with stats: $e');
      rethrow;
    }
  }

  /// Get statistics for a client
  Future<Map<String, dynamic>> _getClientStats(String clientId) async {
    try {
      // Execute a query to get statistics for the client
      final response = await supabase.rpc(
        'get_client_statistics',
        params: {'p_client_id': clientId},
      );

      if (response != null && response.isNotEmpty) {
        return response[0];
      }

      return {
        'invoice_count': 0,
        'total_amount': 0.0,
        'outstanding_amount': 0.0,
        'due_amount': 0.0,
      };
    } catch (e) {
      debugPrint('Error getting client statistics: $e');
      return {
        'invoice_count': 0,
        'total_amount': 0.0,
        'outstanding_amount': 0.0,
        'due_amount': 0.0,
      };
    }
  }
}
