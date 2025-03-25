import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:invoicegenerator/models/hive/company_info_model.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';

/// Service for managing company information using Hive
class CompanyInfoService extends ChangeNotifier {
  late Box<CompanyInfo> _companyBox;
  bool _isInitialized = false;

  CompanyInfo? _companyInfo;
  CompanyInfo? get companyInfo => _companyInfo;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await HiveConfig.initialize();
      _companyBox = Hive.box<CompanyInfo>(HiveBoxes.companyInfo);
      _loadCompanyInfo();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing CompanyInfoService: $e');
      rethrow;
    }
  }

  /// Load company info from Hive
  void _loadCompanyInfo() {
    try {
      // Get the company info from Hive (stored as singleton with key 0)
      _companyInfo = _companyBox.get(0);

      if (_companyInfo == null) {
        // Create a default empty company info if none exists
        _companyInfo = CompanyInfo.empty();
        _companyBox.put(0, _companyInfo!);
      }
    } catch (e) {
      debugPrint('Error loading company info: $e');
      // Create a default empty company info as fallback
      _companyInfo = CompanyInfo.empty();
    }
  }

  /// Save company info to Hive
  Future<bool> saveCompanyInfo(CompanyInfo info) async {
    try {
      await _companyBox.put(0, info);
      _companyInfo = info;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving company info: $e');
      return false;
    }
  }

  /// Update specific company info fields
  Future<bool> updateCompanyInfo({
    String? businessName,
    String? currency,
    bool? enableTax,
    String? country,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? website,
    String? logoPath,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? swiftCode,
    String? taxNumber,
  }) async {
    if (_companyInfo == null) {
      _loadCompanyInfo();
      if (_companyInfo == null) return false;
    }

    // Create a new instance with updated fields
    final updatedInfo = CompanyInfo(
      businessName: businessName ?? _companyInfo!.businessName,
      currency: currency ?? _companyInfo!.currency,
      enableTax: enableTax ?? _companyInfo!.enableTax,
      country: country ?? _companyInfo!.country,
      addressLine1: addressLine1 ?? _companyInfo!.addressLine1,
      addressLine2: addressLine2 ?? _companyInfo!.addressLine2,
      city: city ?? _companyInfo!.city,
      state: state ?? _companyInfo!.state,
      zipCode: zipCode ?? _companyInfo!.zipCode,
      phone: phone ?? _companyInfo!.phone,
      email: email ?? _companyInfo!.email,
      website: website ?? _companyInfo!.website,
      logoPath: logoPath ?? _companyInfo!.logoPath,
      bankName: bankName ?? _companyInfo!.bankName,
      accountNumber: accountNumber ?? _companyInfo!.accountNumber,
      accountName: accountName ?? _companyInfo!.accountName,
      swiftCode: swiftCode ?? _companyInfo!.swiftCode,
      taxNumber: taxNumber ?? _companyInfo!.taxNumber,
    );

    return saveCompanyInfo(updatedInfo);
  }

  /// Save logo file and update path in company info
  Future<bool> saveLogo(File logoFile) async {
    try {
      if (_companyInfo == null) {
        _loadCompanyInfo();
        if (_companyInfo == null) return false;
      }

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final logoDir = Directory('${appDir.path}/company_logos');

      // Create directory if it doesn't exist
      if (!await logoDir.exists()) {
        await logoDir.create(recursive: true);
      }

      // Generate a unique filename based on timestamp
      final filename = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final logoPath = '${logoDir.path}/$filename';

      // Copy the file to the app's documents directory
      await logoFile.copy(logoPath);

      // Update company info with the new logo path
      return updateCompanyInfo(logoPath: logoPath);
    } catch (e) {
      debugPrint('Error saving logo: $e');
      return false;
    }
  }

  /// Clear all company info and return to defaults
  Future<bool> clearCompanyInfo() async {
    try {
      _companyInfo = CompanyInfo.empty();
      await _companyBox.put(0, _companyInfo!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing company info: $e');
      return false;
    }
  }

  /// Export company info to JSON
  Map<String, dynamic> exportToJson() {
    if (_companyInfo == null) {
      _loadCompanyInfo();
      if (_companyInfo == null) return {};
    }

    return _companyInfo!.toJson();
  }

  /// Import company info from JSON
  Future<bool> importFromJson(Map<String, dynamic> json) async {
    try {
      final importedInfo = CompanyInfo.fromJson(json);
      return await saveCompanyInfo(importedInfo);
    } catch (e) {
      debugPrint('Error importing company info: $e');
      return false;
    }
  }

  /// Check if company has completed basic setup
  bool hasCompletedBasicSetup() {
    if (_companyInfo == null) {
      _loadCompanyInfo();
      if (_companyInfo == null) return false;
    }

    // Check if essential fields are filled
    return _companyInfo!.businessName.isNotEmpty &&
        _companyInfo!.country != null &&
        _companyInfo!.addressLine1 != null;
  }
}
