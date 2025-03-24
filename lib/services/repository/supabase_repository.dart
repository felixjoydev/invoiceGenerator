import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base repository class for Supabase operations
abstract class SupabaseRepository<T> {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Gets the current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Gets the Supabase client for derived classes
  SupabaseClient get supabase => _supabase;

  /// Gets the table name for this repository
  String get tableName;

  /// Converts a database row to a model object
  T fromJson(Map<String, dynamic> json);

  /// Converts a model object to a database row
  Map<String, dynamic> toJson(T item);

  /// Fetches all records for the current user
  Future<List<T>> getAll() async {
    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .order('created_at', ascending: false);

      return response.map<T>((item) => fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching all $tableName: $e');
      rethrow;
    }
  }

  /// Fetches a record by ID
  Future<T?> getById(String id) async {
    try {
      final response =
          await _supabase.from(tableName).select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return fromJson(response);
    } catch (e) {
      debugPrint('Error fetching $tableName by ID: $e');
      rethrow;
    }
  }

  /// Creates a new record
  Future<T> create(T item) async {
    try {
      final data = toJson(item);
      final response =
          await _supabase.from(tableName).insert(data).select().single();

      return fromJson(response);
    } catch (e) {
      debugPrint('Error creating $tableName: $e');
      rethrow;
    }
  }

  /// Updates an existing record
  Future<T> update(String id, T item) async {
    try {
      final data = toJson(item);
      final response =
          await _supabase
              .from(tableName)
              .update(data)
              .eq('id', id)
              .select()
              .single();

      return fromJson(response);
    } catch (e) {
      debugPrint('Error updating $tableName: $e');
      rethrow;
    }
  }

  /// Deletes a record by ID
  Future<void> delete(String id) async {
    try {
      await _supabase.from(tableName).delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting $tableName: $e');
      rethrow;
    }
  }
}
