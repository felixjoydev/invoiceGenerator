import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class InvoiceSettingsService {
  static const String _prefsKeyInvoiceSettings = 'invoice_settings';

  // Singleton instance
  static final InvoiceSettingsService _instance =
      InvoiceSettingsService._internal();
  factory InvoiceSettingsService() => _instance;
  InvoiceSettingsService._internal();

  // Default settings
  String _idFormat = '001';
  String _customNotes = '';
  bool _isAutoGenerate = true;
  String _idPrefix = 'INV';
  int _lastInvoiceNumber = 0;
  bool _isInitialized = false;

  // Getters
  String get idFormat => _idFormat;
  String get customNotes => _customNotes;
  bool get isAutoGenerate => _isAutoGenerate;
  String get idPrefix => _idPrefix;
  int get lastInvoiceNumber => _lastInvoiceNumber;

  // Initialize and load settings
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        // Try to load from Supabase
        final settings = await _loadSettingsFromSupabase();
        if (settings != null) {
          _idFormat = settings['idFormat'] ?? '001';
          _customNotes = settings['customNotes'] ?? '';
          _isAutoGenerate = settings['isAutoGenerate'] ?? true;
          _idPrefix = settings['idPrefix'] ?? 'INV';
          _lastInvoiceNumber = settings['lastInvoiceNumber'] ?? 0;

          _isInitialized = true;
          return;
        }
      }

      // If not authenticated or no settings in Supabase, load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_prefsKeyInvoiceSettings);

      if (settingsJson != null) {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        _idFormat = settings['idFormat'] ?? '001';
        _customNotes = settings['customNotes'] ?? '';
        _isAutoGenerate = settings['isAutoGenerate'] ?? true;
        _idPrefix = settings['idPrefix'] ?? 'INV';
        _lastInvoiceNumber = settings['lastInvoiceNumber'] ?? 0;

        // If the user is authenticated, sync settings to Supabase
        if (user != null) {
          await _saveSettingsToSupabase();
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing InvoiceSettingsService: $e');
    }
  }

  // Load settings from Supabase
  Future<Map<String, dynamic>?> _loadSettingsFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response =
          await Supabase.instance.client
              .from('invoice_settings')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      if (response == null) return null;

      return {
        'idFormat': response['id_format'],
        'customNotes': response['custom_notes'],
        'isAutoGenerate': response['auto_generate'],
        'idPrefix': response['id_prefix'],
        'lastInvoiceNumber': response['last_invoice_number'],
      };
    } catch (e) {
      debugPrint('Error loading invoice settings from Supabase: $e');
      return null;
    }
  }

  // Save settings to Supabase
  Future<bool> _saveSettingsToSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      // Check if settings already exist
      final existing =
          await Supabase.instance.client
              .from('invoice_settings')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

      final data = {
        'user_id': user.id,
        'id_format': _idFormat,
        'custom_notes': _customNotes,
        'auto_generate': _isAutoGenerate,
        'id_prefix': _idPrefix,
        'last_invoice_number': _lastInvoiceNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // Update existing record
        await Supabase.instance.client
            .from('invoice_settings')
            .update(data)
            .eq('id', existing['id']);
      } else {
        // Create new record
        data['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client.from('invoice_settings').insert(data);
      }

      return true;
    } catch (e) {
      debugPrint('Error saving invoice settings to Supabase: $e');
      return false;
    }
  }

  // Save invoice settings
  Future<bool> saveInvoiceSettings({
    String? idFormat,
    String? customNotes,
  }) async {
    try {
      await init(); // Ensure service is initialized

      // Update values if provided
      if (idFormat != null) _idFormat = idFormat;
      if (customNotes != null) _customNotes = customNotes;

      // Save to shared preferences
      final saveLocal = await _saveToPrefs();

      // Save to Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _saveSettingsToSupabase();
      }

      return saveLocal;
    } catch (e) {
      debugPrint('Error saving invoice settings: $e');
      return false;
    }
  }

  // Save invoice ID settings
  Future<bool> saveInvoiceIdSettings({
    bool? isAutoGenerate,
    String? idPrefix,
  }) async {
    try {
      await init(); // Ensure service is initialized

      // Update values if provided
      if (isAutoGenerate != null) _isAutoGenerate = isAutoGenerate;
      if (idPrefix != null) _idPrefix = idPrefix;

      // Save to shared preferences
      final saveLocal = await _saveToPrefs();

      // Save to Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _saveSettingsToSupabase();
      }

      return saveLocal;
    } catch (e) {
      debugPrint('Error saving invoice ID settings: $e');
      return false;
    }
  }

  // Update last invoice number when a new invoice is created
  Future<bool> incrementInvoiceNumber() async {
    try {
      await init(); // Ensure service is initialized
      _lastInvoiceNumber++;

      // Save to shared preferences
      final saveLocal = await _saveToPrefs();

      // Save to Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _saveSettingsToSupabase();
      }

      return saveLocal;
    } catch (e) {
      debugPrint('Error updating last invoice number: $e');
      return false;
    }
  }

  // Generate next invoice ID based on settings
  String generateNextInvoiceId() {
    if (!_isAutoGenerate) return 'INV00001'; // Return default for manual mode

    // Generate next number with padding
    final nextNumber = _lastInvoiceNumber + 1;
    final paddedNumber = nextNumber.toString().padLeft(5, '0');

    // Return prefix + number
    final String prefix = _idPrefix.isNotEmpty ? _idPrefix : 'INV';
    return '$prefix$paddedNumber';
  }

  // Helper method to save to SharedPreferences
  Future<bool> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> settings = {
        'idFormat': _idFormat,
        'customNotes': _customNotes,
        'isAutoGenerate': _isAutoGenerate,
        'idPrefix': _idPrefix,
        'lastInvoiceNumber': _lastInvoiceNumber,
      };
      return await prefs.setString(
        _prefsKeyInvoiceSettings,
        jsonEncode(settings),
      );
    } catch (e) {
      debugPrint('Error saving to SharedPreferences: $e');
      return false;
    }
  }
}
