import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyRepository {
  static final CompanyRepository _instance = CompanyRepository._internal();
  final SupabaseClient _supabase = Supabase.instance.client;

  factory CompanyRepository() {
    return _instance;
  }

  CompanyRepository._internal();

  /// Gets the current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get company information for the current user
  Future<CompanyInfo?> getCompanyInfo() async {
    try {
      // Ensure user is authenticated
      final userId = currentUser?.id;
      if (userId == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      final response =
          await _supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

      if (response == null) {
        debugPrint('No company profile found for user');
        return null;
      }

      return CompanyInfo.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching company info: $e');
      return null;
    }
  }

  /// Update company information
  Future<CompanyInfo?> updateCompanyInfo(CompanyInfo companyInfo) async {
    try {
      // Ensure user is authenticated
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      final data = companyInfo.toMap();

      // Debug: print what we're sending to Supabase
      debugPrint('Updating company profile with data: $data');

      final response =
          await _supabase
              .from('profiles')
              .update(data)
              .eq('id', userId)
              .select()
              .single();

      debugPrint('Updated company profile response: $response');
      return CompanyInfo.fromMap(response);
    } catch (e) {
      debugPrint('Error updating company info: $e');
      rethrow;
    }
  }

  /// Upload company logo
  Future<String?> uploadLogo(File logoFile) async {
    try {
      // Ensure user is authenticated
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      final fileExt = logoFile.path.split('.').last;
      final fileName = '${userId}_logo.$fileExt';

      debugPrint(
        'Uploading logo file: ${logoFile.path} to bucket: company_logos',
      );

      // Check if the bucket exists
      try {
        final buckets = await _supabase.storage.listBuckets();
        debugPrint(
          'Available buckets: ${buckets.map((b) => b.name).join(', ')}',
        );
      } catch (e) {
        debugPrint('Error listing buckets: $e');
      }

      final storageResponse = await _supabase.storage
          .from('logos') // Use the actual bucket name that exists
          .upload(
            fileName,
            logoFile,
            fileOptions: FileOptions(cacheControl: '3600', upsert: true),
          );

      if (storageResponse.isEmpty) {
        throw Exception('Failed to upload logo');
      }

      // Get the public URL for the uploaded file
      final logoUrl = _supabase.storage
          .from('logos') // Use the same bucket name
          .getPublicUrl(fileName);

      debugPrint('Successfully uploaded logo: $logoUrl');

      // Update the company profile with the new logo URL
      await _supabase
          .from('profiles')
          .update({'logo_url': logoUrl})
          .eq('id', userId);

      return logoUrl;
    } catch (e) {
      debugPrint('Error uploading company logo: $e');
      rethrow;
    }
  }

  /// Create initial profile for new user
  Future<CompanyInfo?> createInitialProfile(CompanyInfo companyInfo) async {
    try {
      // Ensure user is authenticated
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // Get the map representation with snake_case keys for Supabase
      final data = companyInfo.toMap();

      // Debug print for all fields that are being sent to Supabase
      debugPrint('Creating profile with data:');
      data.forEach((key, value) {
        debugPrint('  $key: $value');
      });

      // Verify that the required fields are populated
      debugPrint('Checking required fields:');
      debugPrint('  business_name: ${data['business_name']}');
      debugPrint('  country: ${data['country']}');
      debugPrint('  address_line1: ${data['address_line1']}');
      debugPrint('  city: ${data['city']}');

      final response =
          await _supabase.from('profiles').upsert(data).select().single();

      debugPrint('Profile creation response: $response');
      return CompanyInfo.fromMap(response);
    } catch (e) {
      debugPrint('Error creating initial profile: $e');
      rethrow;
    }
  }
}
