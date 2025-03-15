import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_prefsKeyInvoiceSettings);

      if (settingsJson != null) {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        _idFormat = settings['idFormat'] ?? '001';
        _customNotes = settings['customNotes'] ?? '';
        _isAutoGenerate = settings['isAutoGenerate'] ?? true;
        _idPrefix = settings['idPrefix'] ?? 'INV';
        _lastInvoiceNumber = settings['lastInvoiceNumber'] ?? 0;
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing InvoiceSettingsService: $e');
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
      return await _saveToPrefs();
    } catch (e) {
      print('Error saving invoice settings: $e');
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
      return await _saveToPrefs();
    } catch (e) {
      print('Error saving invoice ID settings: $e');
      return false;
    }
  }

  // Update last invoice number when a new invoice is created
  Future<bool> incrementInvoiceNumber() async {
    try {
      await init(); // Ensure service is initialized
      _lastInvoiceNumber++;
      return await _saveToPrefs();
    } catch (e) {
      print('Error updating last invoice number: $e');
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

      await prefs.setString(_prefsKeyInvoiceSettings, jsonEncode(settings));
      return true;
    } catch (e) {
      print('Error saving to preferences: $e');
      return false;
    }
  }
}
