import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:invoicegenerator/models/hive/invoice_settings_model.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';

/// Service for managing invoice settings using Hive
class InvoiceSettingsService extends ChangeNotifier {
  late Box<InvoiceSettings> _settingsBox;
  bool _isInitialized = false;

  InvoiceSettings? _settings;
  InvoiceSettings? get settings => _settings;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await HiveConfig.initialize();
      _settingsBox = Hive.box<InvoiceSettings>(HiveBoxes.invoiceSettings);
      _loadSettings();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing InvoiceSettingsService: $e');
      rethrow;
    }
  }

  /// Load settings from Hive
  void _loadSettings() {
    try {
      // Get settings from Hive (stored as singleton with key 0)
      _settings = _settingsBox.get(0);

      if (_settings == null) {
        // Create default settings if none exist
        _settings = InvoiceSettings.defaultSettings();
        _settingsBox.put(0, _settings!);
      }
    } catch (e) {
      debugPrint('Error loading invoice settings: $e');
      // Create default settings as fallback
      _settings = InvoiceSettings.defaultSettings();
    }
  }

  /// Save settings to Hive
  Future<bool> saveSettings(InvoiceSettings settings) async {
    try {
      await _settingsBox.put(0, settings);
      _settings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving invoice settings: $e');
      return false;
    }
  }

  /// Update specific settings fields
  Future<bool> updateSettings({
    String? idFormat,
    String? customNotes,
    bool? isAutoGenerate,
    String? idPrefix,
    int? lastInvoiceNumber,
    int? dueDateDays,
  }) async {
    if (_settings == null) {
      _loadSettings();
      if (_settings == null) return false;
    }

    // Create a new instance with updated fields
    final updatedSettings = InvoiceSettings(
      idFormat: idFormat ?? _settings!.idFormat,
      customNotes: customNotes ?? _settings!.customNotes,
      isAutoGenerate: isAutoGenerate ?? _settings!.isAutoGenerate,
      idPrefix: idPrefix ?? _settings!.idPrefix,
      lastInvoiceNumber: lastInvoiceNumber ?? _settings!.lastInvoiceNumber,
      dueDateDays: dueDateDays ?? _settings!.dueDateDays,
    );

    return saveSettings(updatedSettings);
  }

  /// Generate the next invoice ID based on settings
  String generateInvoiceId() {
    if (_settings == null) {
      _loadSettings();
      if (_settings == null) {
        // Use default pattern if settings not available
        return 'inv-001';
      }
    }

    // Increment the last invoice number
    final nextNumber = _settings!.lastInvoiceNumber + 1;

    // Update the last invoice number in settings
    updateSettings(lastInvoiceNumber: nextNumber);

    // Generate ID based on format
    if (_settings!.idFormat.contains('000')) {
      // Format with leading zeros (e.g., inv-001)
      final digits = _settings!.idFormat.split('-')[1].length;
      return '${_settings!.idFormat.split('-')[0]}-${nextNumber.toString().padLeft(digits, '0')}';
    } else {
      // Simple format (e.g., INV-1)
      return '${_settings!.idPrefix}-$nextNumber';
    }
  }

  /// Reset settings to default
  Future<bool> resetSettings() async {
    try {
      _settings = InvoiceSettings.defaultSettings();
      await _settingsBox.put(0, _settings!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resetting invoice settings: $e');
      return false;
    }
  }
}
