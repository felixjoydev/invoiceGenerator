import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:invoicegenerator/services/auth/supabase_config.dart';
import 'package:invoicegenerator/main.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Utility class to handle deep links for authentication
class DeepLinkHandler {
  static bool _isInitialized = false;
  static AppLinks? _appLinks;
  static Timer? _authPollTimer;

  /// Get the redirect URL for OAuth authentication
  static String getRedirectUrl() {
    // For web, we don't need a redirect URL as it will be handled by the browser
    if (kIsWeb) {
      debugPrint('Using web redirect');
      // For web, return an empty string as Supabase will handle it automatically
      return '';
    }

    // For mobile, we use the configured deep link
    debugPrint('Using mobile redirect URL: ${SupabaseConfig.redirectUrl}');
    return SupabaseConfig.redirectUrl;
  }

  /// Get the alternate redirect URL for OAuth authentication
  static String getAlternateRedirectUrl() {
    if (kIsWeb) {
      return '';
    }

    debugPrint(
      'Using alternate redirect URL: ${SupabaseConfig.alternateRedirectUrl}',
    );
    return SupabaseConfig.alternateRedirectUrl;
  }

  /// Initialize deep link handling to pass authentication results back to Supabase
  static Future<void> initializeDeepLinkHandling() async {
    if (_isInitialized) {
      debugPrint('Deep link handling already initialized');
      return;
    }

    if (kIsWeb) {
      // Web doesn't need deep link handling
      debugPrint('Skipping deep link handling initialization on web');
      _isInitialized = true;
      return;
    }

    try {
      debugPrint('Initializing deep link handling for OAuth callbacks');
      _appLinks = AppLinks();

      // Handle incoming links - this is necessary for auth callbacks
      _appLinks!.uriLinkStream.listen((uri) {
        debugPrint('🔗 Got deep link callback: $uri');
        try {
          // Let Supabase auth handle the URI
          final response = Supabase.instance.client.auth.getSessionFromUrl(uri);
          debugPrint('Deep link processed successfully: $response');

          // Check auth state after a short delay
          _checkAuthState();
        } catch (e) {
          debugPrint('❌ Error processing deep link: $e');
        }
      });

      // Get the initial URI if the app was opened with one
      final initialUri = await _appLinks!.getInitialAppLink();
      if (initialUri != null) {
        debugPrint('🔗 Got initial deep link: $initialUri');
        try {
          // Handle the initial URI
          final response = Supabase.instance.client.auth.getSessionFromUrl(
            initialUri,
          );
          debugPrint('Initial deep link processed: $response');

          // Check auth state after a short delay
          _checkAuthState();
        } catch (e) {
          debugPrint('❌ Error processing initial deep link: $e');
        }
      }

      // Set up polling for auth state changes (fallback for when deep links don't work)
      _setupAuthStatePolling();

      _isInitialized = true;
      debugPrint('Deep link handling initialized successfully ✅');
    } catch (e) {
      debugPrint('❌ Error setting up deep link handling: $e');
    }
  }

  /// Set up polling to check for authentication state changes
  /// This is a fallback for when deep links aren't processed
  static void _setupAuthStatePolling() {
    debugPrint('Setting up auth state polling fallback with faster checks');

    // Cancel any existing timer
    _authPollTimer?.cancel();

    // Poll more aggressively (every 200ms for 60 seconds)
    int attempts = 0;
    _authPollTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) async {
      attempts++;

      final result = await _checkAuthState();

      // Stop polling after 60 seconds (300 * 200ms) or when auth is detected
      if (result || attempts >= 300) {
        timer.cancel();
        _authPollTimer = null;

        if (result) {
          debugPrint('Auth detected by polling, closing auth window.');
          await closeAuthWindow();
        } else {
          debugPrint('Auth polling timeout reached without detecting auth.');
        }
      }

      // Log every few attempts
      if (attempts % 10 == 0) {
        debugPrint('Auth polling attempt $attempts/300');
      }
    });
  }

  /// Check if the user is authenticated and handle navigation
  /// Returns true if auth is detected, false otherwise
  static Future<bool> _checkAuthState() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        debugPrint('🔑 User detected in auth state check: ${user.email}');

        // Force close any browser tabs/windows that might be open
        await closeAuthWindow();

        // Notify the UI that auth is complete
        debugPrint('Notifying UI that auth is complete');

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      return false;
    }
  }

  /// Attempt to programmatically close any auth windows that might be open
  static Future<void> closeAuthWindow() async {
    try {
      if (!kIsWeb) {
        debugPrint('Attempting to close auth window on mobile');

        // Force refresh the token to trigger any callbacks
        try {
          await Supabase.instance.client.auth.refreshSession();
          debugPrint('Refreshed auth session to trigger callbacks');
        } catch (e) {
          debugPrint('Error refreshing session: $e');
        }

        // Try with both redirect URL formats for better compatibility
        await _tryCloseWithUrl(SupabaseConfig.redirectUrl);
        await _tryCloseWithUrl(SupabaseConfig.alternateRedirectUrl);

        // Wait a moment to allow browser to close
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if we have a valid session and ensure UI updates
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          debugPrint('User authenticated after close attempt: ${user.email}');

          // Navigate to app's main flow if we have a navigator context
          final context = navigatorKey.currentContext;
          if (context != null) {
            debugPrint('Context found, updating UI after auth...');

            // Use a post-frame callback to avoid navigator conflicts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                // Instead of directly adding to stream, just refresh the session
                // This will trigger the existing auth state change listeners
                Supabase.instance.client.auth.refreshSession();
                debugPrint('Refreshed session to trigger auth state change');
              } catch (e) {
                debugPrint('Error refreshing session for state change: $e');
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error closing auth window: $e');
    }
  }

  /// Helper to try closing with different redirect URL formats
  static Future<void> _tryCloseWithUrl(String baseUrl) async {
    try {
      final completeUri = Uri.parse(
        '${baseUrl}#access_token=refresh_trigger&refresh_token=refresh_trigger&type=bearer&provider=google',
      );

      await Supabase.instance.client.auth.getSessionFromUrl(completeUri);
      debugPrint('Sent OAuth URI using $baseUrl to trigger window close');
    } catch (e) {
      debugPrint('Error with OAuth URI using $baseUrl: $e');
    }
  }

  /// Force close any auth sessions that might be stuck
  static Future<void> clearAuthState() async {
    try {
      debugPrint('Attempting to clear auth state');

      // Cancel any active auth polling
      _authPollTimer?.cancel();
      _authPollTimer = null;

      await Supabase.instance.client.auth.signOut();
      debugPrint('Auth state cleared');
    } catch (e) {
      debugPrint('Error clearing auth state: $e');
    }
  }
}
