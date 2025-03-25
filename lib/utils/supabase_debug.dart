import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDebugUtils {
  static void validateConfiguration() {
    final supabase = Supabase.instance.client;

    try {
      // Log configuration details
      debugPrint('======= SUPABASE CONFIGURATION =======');

      // Check session details
      final session = supabase.auth.currentSession;
      if (session != null) {
        debugPrint('Has valid session: true');
        debugPrint(
          'Access token first 10 chars: ${session.accessToken.substring(0, 10)}...',
        );
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          session.expiresAt! * 1000,
        );
        debugPrint('Token expires at: $expiresAt');
      } else {
        debugPrint('Has valid session: false');
      }

      // Check current user
      final user = supabase.auth.currentUser;
      if (user != null) {
        debugPrint('Current user: ${user.email}');
        debugPrint('User ID: ${user.id}');
      } else {
        debugPrint('No authenticated user');
      }

      debugPrint('===================================');
    } catch (e) {
      debugPrint('Error validating Supabase configuration: $e');
    }
  }

  static void logDeepLinkDetails(String url) {
    try {
      debugPrint('======= DEEP LINK DETAILS =======');
      debugPrint('Full URL: $url');

      // Parse the URL
      final uri = Uri.parse(url);
      debugPrint('Scheme: ${uri.scheme}');
      debugPrint('Host: ${uri.host}');
      debugPrint('Path: ${uri.path}');

      // Log query parameters
      debugPrint('Query Parameters:');
      uri.queryParameters.forEach((key, value) {
        debugPrint('  $key: $value');
      });

      debugPrint('================================');
    } catch (e) {
      debugPrint('Error parsing deep link URL: $e');
    }
  }

  static Future<bool> checkAndFixAuthConfiguration() async {
    final supabase = Supabase.instance.client;

    try {
      debugPrint('======= CHECKING SUPABASE AUTH =======');

      // Test if the API key is valid by making a simple request
      try {
        // Get the current auth configuration
        final response = await supabase.auth.getUser();
        debugPrint('Auth API check successful');
        return true;
      } catch (e) {
        if (e.toString().contains('Invalid API key')) {
          debugPrint('API key validation error detected, attempting to fix...');

          // The API key may have expired or is invalid
          // Here you would typically reload the configuration or use a fallback
          debugPrint('Please reinitialize Supabase with a valid API key');

          return false;
        } else {
          debugPrint('Unknown error in auth configuration: $e');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error in checkAndFixAuthConfiguration: $e');
      return false;
    } finally {
      debugPrint('===================================');
    }
  }
}
