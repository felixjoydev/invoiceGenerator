import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/company_info.dart';

class CompanyService {
  static const String _storageKey = 'company_info';

  CompanyInfo? _companyInfo;

  CompanyInfo? get companyInfo => _companyInfo;

  // Initialize the service and load data
  Future<void> init() async {
    await _loadCompanyInfo();
  }

  // Load company info from local storage
  Future<void> _loadCompanyInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? companyJson = prefs.getString(_storageKey);

      if (companyJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(companyJson);
        _companyInfo = CompanyInfo.fromMap(decoded);
      }
    } catch (e) {
      debugPrint('Error loading company info: $e');
      _companyInfo = null;
    }
  }

  // Save company info to local storage
  Future<void> saveCompanyInfo(CompanyInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String companyJson = jsonEncode(info.toMap());
      await prefs.setString(_storageKey, companyJson);
      _companyInfo = info;
    } catch (e) {
      debugPrint('Error saving company info: $e');
    }
  }

  // Update company info
  Future<void> updateCompanyInfo({
    String? businessName,
    String? logoPath,
    String? currency,
    double? taxRate,
    bool? enableTax,
    String? country,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? zip,
    String? phone,
    String? email,
    String? website,
    String? bankName,
    String? accountHolder,
    String? accountNumber,
    String? ifscCode,
  }) async {
    if (_companyInfo == null) {
      debugPrint('Cannot update company info. It is not initialized.');
      return;
    }

    final updatedInfo = _companyInfo!.copyWith(
      businessName: businessName,
      logoPath: logoPath,
      currency: currency,
      taxRate: taxRate,
      enableTax: enableTax,
      country: country,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      zip: zip,
      phone: phone,
      email: email,
      website: website,
      bankName: bankName,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
    );

    await saveCompanyInfo(updatedInfo);
  }

  // Save company info from onboarding
  Future<void> saveCompanyInfoFromOnboarding({
    required String businessName,
    String? logoPath,
    required String currency,
    double? taxRate,
    required bool enableTax,
    required String country,
    required String addressLine1,
    String? addressLine2,
    required String city,
    String? zip,
    String? phone,
    String? email,
    String? website,
  }) async {
    final companyInfo = CompanyInfo(
      businessName: businessName,
      logoPath: logoPath,
      currency: currency,
      taxRate: taxRate,
      enableTax: enableTax,
      country: country,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      zip: zip,
      phone: phone,
      email: email,
      website: website,
      bankName: null,
      accountHolder: null,
      accountNumber: null,
      ifscCode: null,
    );

    await saveCompanyInfo(companyInfo);
  }

  // Check if company info is set up
  bool isCompanyInfoSetUp() {
    return _companyInfo != null;
  }
}
