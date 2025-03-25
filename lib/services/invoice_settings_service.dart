import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/services/mcp/storage_service.dart';
import 'package:invoicegenerator/services/mcp/storage_service_factory.dart';

class InvoiceSettingsService {
  // Singleton instance
  static final InvoiceSettingsService _instance =
      InvoiceSettingsService._internal();
  factory InvoiceSettingsService() => _instance;
  InvoiceSettingsService._internal();

  // Storage service factory
  final _storageFactory = StorageServiceFactory();

  // In-memory settings
  InvoiceSettings? _settings;

  // Flag to check if initialized
  bool _isInitialized = false;

  // Getters
  String get idFormat => _settings?.idFormat ?? '001';
  String get customNotes => _settings?.customNotes ?? '';
  bool get isAutoGenerate => _settings?.isAutoGenerate ?? true;
  String get idPrefix => _settings?.idPrefix ?? 'INV';
  int get lastInvoiceNumber => _settings?.lastInvoiceNumber ?? 0;

  // Initialize and load settings
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _storageFactory.init();
      _settings = await _storageFactory.service.getInvoiceSettings();

      // If settings are null, create default settings
      if (_settings == null) {
        _settings = InvoiceSettings();
        await _saveToStorage();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing InvoiceSettingsService: $e');
      _settings = InvoiceSettings(); // Use defaults on error
    }
  }

  // Save invoice settings
  Future<bool> saveInvoiceSettings({
    String? idFormat,
    String? customNotes,
  }) async {
    try {
      await init(); // Ensure service is initialized

      // Create updated settings
      _settings = InvoiceSettings(
        idFormat: idFormat ?? _settings!.idFormat,
        customNotes: customNotes ?? _settings!.customNotes,
        isAutoGenerate: _settings!.isAutoGenerate,
        idPrefix: _settings!.idPrefix,
        lastInvoiceNumber: _settings!.lastInvoiceNumber,
      );

      // Save to storage
      return await _saveToStorage();
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

      // Create updated settings
      _settings = InvoiceSettings(
        idFormat: _settings!.idFormat,
        customNotes: _settings!.customNotes,
        isAutoGenerate: isAutoGenerate ?? _settings!.isAutoGenerate,
        idPrefix: idPrefix ?? _settings!.idPrefix,
        lastInvoiceNumber: _settings!.lastInvoiceNumber,
      );

      // Save to storage
      return await _saveToStorage();
    } catch (e) {
      debugPrint('Error saving invoice ID settings: $e');
      return false;
    }
  }

  // Update last invoice number when a new invoice is created
  Future<bool> incrementInvoiceNumber() async {
    try {
      await init(); // Ensure service is initialized

      // Create updated settings
      _settings = InvoiceSettings(
        idFormat: _settings!.idFormat,
        customNotes: _settings!.customNotes,
        isAutoGenerate: _settings!.isAutoGenerate,
        idPrefix: _settings!.idPrefix,
        lastInvoiceNumber: _settings!.lastInvoiceNumber + 1,
      );

      return await _saveToStorage();
    } catch (e) {
      debugPrint('Error updating last invoice number: $e');
      return false;
    }
  }

  // Generate next invoice ID based on settings
  String generateNextInvoiceId() {
    if (!_isInitialized) {
      return 'INV00001'; // Default if not initialized
    }

    if (!_settings!.isAutoGenerate) {
      return 'INV00001'; // Return default for manual mode
    }

    // Generate next number with padding
    final nextNumber = _settings!.lastInvoiceNumber + 1;
    final paddedNumber = nextNumber.toString().padLeft(5, '0');

    // Return prefix + number
    final String prefix =
        _settings!.idPrefix.isNotEmpty ? _settings!.idPrefix : 'INV';
    return '$prefix$paddedNumber';
  }

  // Helper method to save to storage
  Future<bool> _saveToStorage() async {
    try {
      if (_settings != null) {
        await _storageFactory.service.updateInvoiceSettings(_settings!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving to storage: $e');
      return false;
    }
  }
}
