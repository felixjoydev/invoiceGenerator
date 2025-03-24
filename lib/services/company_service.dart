import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/services/repository/company_repository.dart';

class CompanyService {
  static const String _storageKey = 'company_info';

  CompanyInfo? _companyInfo;
  final CompanyRepository _companyRepository = CompanyRepository();

  // Private initialization flag
  bool _isInitializing = false;

  CompanyInfo? get companyInfo => _companyInfo;

  // Initialize the service
  Future<void> init() async {
    if (_isInitializing) {
      debugPrint(
        'CompanyService - Already initializing, skipping duplicate init call',
      );
      return;
    }

    _isInitializing = true;
    try {
      await _loadCompanyInfo();
    } finally {
      _isInitializing = false;
    }
  }

  // Force a fresh reload from storage
  Future<void> refresh() async {
    debugPrint('Forcing refresh of company info');
    _companyInfo = null;
    await _loadCompanyInfo();
  }

  // Load company info from local storage
  Future<void> _loadCompanyInfo() async {
    try {
      // First try to load from Supabase
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        debugPrint('Attempting to load company info from Supabase');
        final supabaseCompanyInfo = await _companyRepository.getCompanyInfo();
        if (supabaseCompanyInfo != null) {
          debugPrint('Successfully loaded company info from Supabase');
          _companyInfo = supabaseCompanyInfo;

          // Save to local storage for offline access
          final prefs = await SharedPreferences.getInstance();
          final String companyJson = jsonEncode(_companyInfo!.toMap());
          await prefs.setString(_storageKey, companyJson);

          return;
        }
      }

      // If not found in Supabase, load from local storage
      debugPrint('Loading company info from local storage');
      final prefs = await SharedPreferences.getInstance();
      final String? companyJson = prefs.getString(_storageKey);

      if (companyJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(companyJson);
        _companyInfo = CompanyInfo.fromMap(decoded);
        debugPrint(
          'Loaded company info with logo path: ${_companyInfo?.logoPath}',
        );

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

        // If user is logged in, sync to Supabase
        if (user != null && _companyInfo != null) {
          // Update id to match user id for Supabase
          _companyInfo = _companyInfo!.copyWith(id: user.id);
          await _syncToSupabase(_companyInfo!);
        }
      }
    } catch (e) {
      debugPrint('Error loading company info: $e');
      _companyInfo = null;
    }
  }

  // Sync company info to Supabase
  Future<void> _syncToSupabase(CompanyInfo info) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('No user authenticated, skipping Supabase sync');
        return;
      }

      debugPrint('Syncing company info to Supabase');

      // Make sure the ID matches the user ID
      CompanyInfo infoToSync = info.copyWith(id: user.id);
      String? logoUrl;

      // Upload logo to Supabase storage if needed
      if (infoToSync.logoPath != null) {
        try {
          final logoFile = File(infoToSync.logoPath!);
          if (await logoFile.exists()) {
            debugPrint(
              'Logo file exists at path: ${infoToSync.logoPath}, uploading to Supabase',
            );

            // Try to upload the logo and get the URL
            logoUrl = await _companyRepository.uploadLogo(logoFile);

            if (logoUrl != null) {
              debugPrint(
                'Logo uploaded successfully to Supabase, URL: $logoUrl',
              );

              // Important: We DON'T update the local logo_path because we need to keep
              // the local file reference for offline use, but we'll use the logo_url
              // when sending to Supabase in the next steps
            } else {
              debugPrint('Failed to get logo URL after upload');
            }
          } else {
            debugPrint(
              'Logo file does not exist at path: ${infoToSync.logoPath}',
            );
          }
        } catch (e) {
          debugPrint('Error uploading logo to Supabase: $e');
          // Continue without logo
        }
      } else {
        debugPrint('No logo path provided');
      }

      // If we successfully uploaded a logo, create a special version of the company info
      // that includes the Supabase logo URL for the database
      if (logoUrl != null) {
        // Create data map manually to include logoUrl in correct field
        var data = infoToSync.toMap();
        data['logo_url'] = logoUrl;

        debugPrint('Adding logo_url to profile data: $logoUrl');
        await _companyRepository.createInitialProfile(infoToSync);
      } else {
        // Just use the regular info
        await _companyRepository.createInitialProfile(infoToSync);
      }

      debugPrint('Company info successfully synced to Supabase');
    } catch (e) {
      debugPrint('Error syncing to Supabase: $e');
    }
  }

  // Save company info to local storage
  Future<void> saveCompanyInfo(CompanyInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();

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

      debugPrint('Saving company info with logo path: ${infoToSave.logoPath}');
      final String companyJson = jsonEncode(infoToSave.toMap());
      await prefs.setString(_storageKey, companyJson);
      _companyInfo = infoToSave;

      // Verify the data was saved
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(savedJson);
        final savedLogoPath = decoded['logoPath'];
        debugPrint('Verified saved logo path: $savedLogoPath');

        // Double check file existence after saving
        if (savedLogoPath != null) {
          final logoExists = await File(savedLogoPath).exists();
          debugPrint('Verified logo exists after saving: $logoExists');
        }
      }

      // Sync to Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        debugPrint('User authenticated, syncing to Supabase');
        // Update id to match user id for Supabase
        infoToSave = infoToSave.copyWith(id: user.id);
        await _syncToSupabase(infoToSave);
      } else {
        debugPrint('No user authenticated, skipping Supabase sync');
      }
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
    // Use current user ID if available, otherwise generate one
    String id;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      id = user.id;
    } else {
      id = const Uuid().v4();
    }

    final companyInfo = CompanyInfo(
      id: id,
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
