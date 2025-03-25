import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Flag to check if Supabase is initialized
  bool _isInitialized = false;

  // Get the Supabase client instance
  late final SupabaseClient _client;

  SupabaseClient get client => _client;

  // Initialize Supabase
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_isInitialized) return;

    try {
      // Check if Supabase is already initialized in the app
      try {
        _client = Supabase.instance.client;
        _isInitialized = true;
        debugPrint('Using existing Supabase instance');
        return;
      } catch (e) {
        // Supabase is not initialized yet, initialize it
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
        _client = Supabase.instance.client;
        _isInitialized = true;
        debugPrint('Supabase initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  // Get the current user's ID
  String? get currentUserId => _client.auth.currentUser?.id;

  // Check if user is logged in
  bool get isAuthenticated => _client.auth.currentUser != null;

  // Get current organization ID from the database
  Future<String?> getCurrentOrganizationId() async {
    if (!isAuthenticated) return null;

    try {
      final response =
          await _client.rpc('get_current_user_organization_id').single();

      return response as String?;
    } catch (e) {
      debugPrint('Error getting organization ID: $e');
      return null;
    }
  }
}
