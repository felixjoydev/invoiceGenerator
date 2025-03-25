import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/services/mcp/storage_service_factory.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CompanyService with ChangeNotifier {
  // In-memory company info
  CompanyInfo? _companyInfo;
  CompanyInfo? get companyInfo => _companyInfo;

  // Storage service factory
  final _storageFactory = StorageServiceFactory();

  // Singleton pattern
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  // Initialize the service and load data
  Future<void> init() async {
    await _loadCompanyInfo();
  }

  // Get company info, loading if needed
  Future<CompanyInfo?> getCompanyInfo() async {
    if (_companyInfo == null) {
      await _loadCompanyInfo();
    }
    return _companyInfo;
  }

  // Force a fresh reload from storage
  Future<void> refresh() async {
    debugPrint('Forcing refresh of company info');
    _companyInfo = null;
    await _loadCompanyInfo();
  }

  // Load company info from storage
  Future<void> _loadCompanyInfo() async {
    try {
      // Get company info from the appropriate storage service
      await _storageFactory.init();
      _companyInfo = await _storageFactory.service.getCompanyInfo();

      // Verify that the logo file exists
      if (_companyInfo?.logoPath != null) {
        final logoFile = File(_companyInfo!.logoPath!);
        final exists = await logoFile.exists();
        debugPrint('Logo file exists: $exists');

        // If the file doesn't exist, clear the logo path
        if (!exists) {
          debugPrint('Logo file does not exist, clearing logo path');
          _companyInfo = _companyInfo!.copyWith(logoPath: null);
          await saveCompanyInfo(_companyInfo!);
        }
      }
    } catch (e) {
      debugPrint('Error loading company info: $e');
      _companyInfo = null;
    }
  }

  // Save company info to storage
  Future<void> saveCompanyInfo(CompanyInfo info) async {
    try {
      // Verify that the logo file exists before saving
      CompanyInfo infoToSave = info;
      if (info.logoPath != null) {
        final logoFile = File(info.logoPath!);
        final exists = await logoFile.exists();
        debugPrint(
          'Verifying logo file exists before saving: $exists (${info.logoPath})',
        );

        if (exists) {
          // Create a backup copy of the logo file to ensure persistence
          try {
            final appDir = await getApplicationDocumentsDirectory();
            final fileName = path.basename(info.logoPath!);
            final backupDir = Directory('${appDir.path}/logos_backup');

            // Create backup directory if it doesn't exist
            if (!await backupDir.exists()) {
              await backupDir.create(recursive: true);
            }

            final backupPath = '${backupDir.path}/$fileName';
            debugPrint('Creating backup of logo at: $backupPath');

            // Only copy if the files are different
            if (info.logoPath! != backupPath) {
              final backupFile = File(backupPath);
              if (!await backupFile.exists()) {
                await logoFile.copy(backupPath);
                // Update the path to use the backup
                infoToSave = info.copyWith(logoPath: backupPath);
                debugPrint('Updated logo path to use backup: $backupPath');
              } else {
                // If backup exists, use it
                infoToSave = info.copyWith(logoPath: backupPath);
                debugPrint('Using existing backup: $backupPath');
              }
            }
          } catch (e) {
            debugPrint('Error creating logo backup: $e');
          }
        } else {
          // If the file doesn't exist, clear the logo path
          debugPrint(
            'Logo file does not exist, clearing logo path before saving',
          );
          infoToSave = info.copyWith(logoPath: null);
        }
      }

      // Save to appropriate storage service
      await _storageFactory.service.updateCompanyInfo(infoToSave);
      _companyInfo = infoToSave;
    } catch (e) {
      debugPrint('Error saving company info: $e');
    }
  }

  // Update company info
  Future<void> updateCompanyInfo(CompanyInfo updatedInfo) async {
    try {
      // Handle logo path separately to avoid overwriting it if it's not changed
      final currentInfo = await getCompanyInfo();
      if (currentInfo != null &&
          updatedInfo.logoPath == null &&
          currentInfo.logoPath != null) {
        // Keep the existing logo path if not being updated
        updatedInfo = updatedInfo.copyWith(logoPath: currentInfo.logoPath);
      }

      // Verify logo file exists before saving
      if (updatedInfo.logoPath != null) {
        try {
          final file = File(updatedInfo.logoPath!);
          final exists = await file.exists();
          debugPrint(
            'Verifying logo file exists before saving: $exists (${updatedInfo.logoPath})',
          );

          if (!exists) {
            debugPrint(
              'Logo file does not exist, clearing logo path before saving',
            );
            updatedInfo = updatedInfo.copyWith(logoPath: null);
          }
        } catch (e) {
          debugPrint('Error verifying logo file: $e');
          // Clear logo path if there's an error
          updatedInfo = updatedInfo.copyWith(logoPath: null);
        }
      }

      await _storageFactory.service.updateCompanyInfo(updatedInfo);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating company info: $e');
      // Optionally rethrow or handle the error as appropriate
    }
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
