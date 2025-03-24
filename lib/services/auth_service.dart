import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/services/auth/deep_link_handler.dart';
import 'package:invoicegenerator/main.dart'; // Import to access navigatorKey
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final _auth = Supabase.instance.client.auth;
  final _supabase = Supabase.instance.client;
  User? _user;
  bool _loading = false;
  String? _errorMessage;

  AuthService() {
    _init();
  }

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  void _init() {
    _loading = true;
    _user = _auth.currentUser;
    _loading = false;
    notifyListeners();

    // Listen for auth state changes
    _auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          _user = session?.user;
          debugPrint('User signed in: ${_user?.email}');
          // Always check profile and navigate on sign in, regardless of loading state
          _forceCheckUserProfileAndNavigate();
          break;
        case AuthChangeEvent.signedOut:
          _user = null;
          debugPrint('User signed out');
          // Clear local storage data when user signs out
          _clearLocalStorageData();
          break;
        case AuthChangeEvent.userUpdated:
          _user = session?.user;
          debugPrint('User updated: ${_user?.email}');
          break;
        case AuthChangeEvent.passwordRecovery:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userDeleted:
        case AuthChangeEvent.mfaChallengeVerified:
        case AuthChangeEvent.initialSession:
          break;
      }

      notifyListeners();
    });
  }

  // Force check user profile and navigate, ignoring loading state
  Future<void> _forceCheckUserProfileAndNavigate() async {
    if (_user == null) {
      debugPrint('No user found in _forceCheckUserProfileAndNavigate');
      return;
    }

    debugPrint(
      'Force checking profile for user ID: ${_user!.id}, email: ${_user!.email}',
    );

    // Clear local storage data to ensure we don't see previous user's data
    await _clearLocalStorageData();

    try {
      // Check if user has a profile in the database
      final response =
          await _supabase
              .from('profiles')
              .select()
              .eq('id', _user!.id)
              .maybeSingle();

      if (response != null && response['business_name'] != null) {
        // If there's a valid business name, user has completed onboarding
        debugPrint(
          'User profile found with business name: ${response['business_name']}',
        );
        _navigateToHomeScreen();
      } else {
        // Profile exists but might be incomplete or not exist
        debugPrint(
          'User profile incomplete or not found, redirecting to onboarding',
        );
        _navigateToOnboarding();
      }
    } catch (e) {
      // If error, log and redirect to onboarding
      debugPrint('Error checking user profile: $e');
      _navigateToOnboarding();
    }
  }

  // Navigate to home screen for existing users
  void _navigateToHomeScreen() {
    debugPrint('Attempting to navigate to home screen');
    try {
      // Use navigatorKey to navigate without context
      final BuildContext? context = navigatorKey.currentContext;
      if (context != null) {
        debugPrint('Using navigator key to push to home screen');
        // Use direct navigation instead of named routes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => _getHomeScreen()),
            (route) => false, // Remove all previous routes
          );
        });
      } else {
        debugPrint('No context available for navigation');
      }
    } catch (e) {
      debugPrint('Error navigating to home screen: $e');
    }
  }

  // Navigate to onboarding for new users
  void _navigateToOnboarding() {
    debugPrint('Attempting to navigate to onboarding screen');
    try {
      final BuildContext? context = navigatorKey.currentContext;
      if (context != null) {
        debugPrint('Using navigator key to push to onboarding screen');
        // Use direct navigation instead of named routes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => _getOnboardingScreen()),
            (route) => false, // Remove all previous routes
          );
        });
      } else {
        debugPrint('No context available for navigation');
      }
    } catch (e) {
      debugPrint('Error navigating to onboarding screen: $e');
    }
  }

  // Helper method to get the home screen instance
  Widget _getHomeScreen() {
    // Import at the top of the file
    return const HomeScreen();
  }

  // Helper method to get the onboarding screen instance
  Widget _getOnboardingScreen() {
    // Import at the top of the file
    return const CompanyBasicDetailsScreen();
  }

  // Sign in with email
  Future<void> signInWithEmail(String email) async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear local storage to ensure we don't see previous user's data
      await _clearLocalStorageData();

      // Get redirect URL for the platform
      final redirectUrl = DeepLinkHandler.getRedirectUrl();

      // Start the sign in process
      await _auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectUrl.isNotEmpty ? redirectUrl : null,
      );

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear local storage to ensure we don't see previous user's data
      await _clearLocalStorageData();

      // Get redirect URL for the platform
      final redirectUrl = DeepLinkHandler.getRedirectUrl();

      // Start Google auth
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl.isNotEmpty ? redirectUrl : null,
      );

      // The callback will be handled by deep link handler
    } catch (e) {
      _loading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear local storage to ensure we don't see previous user's data
      await _clearLocalStorageData();

      // Get redirect URL for the platform
      final redirectUrl = DeepLinkHandler.getRedirectUrl();

      // Start Apple auth
      await _auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectUrl.isNotEmpty ? redirectUrl : null,
      );

      // The callback will be handled by deep link handler
    } catch (e) {
      _loading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear local storage before signing out
      await _clearLocalStorageData();

      // Sign out from Supabase
      await _auth.signOut();

      _user = null;
      _loading = false;
      notifyListeners();

      // Navigate to login screen
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      _loading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear all local storage data
  Future<void> _clearLocalStorageData() async {
    debugPrint('Clearing local storage data');
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear specific storage keys
      await prefs.remove('company_info');
      await prefs.remove('clients');
      await prefs.remove('invoices');
      await prefs.remove('catalog_items');

      // Clear any temporary onboarding data
      await prefs.remove('temp_business_name');
      await prefs.remove('temp_logo_path');
      await prefs.remove('temp_currency');
      await prefs.remove('temp_tax_rate');
      await prefs.remove('temp_enable_tax');
      await prefs.remove('temp_country');
      await prefs.remove('temp_address_line1');
      await prefs.remove('temp_address_line2');
      await prefs.remove('temp_city');
      await prefs.remove('temp_zip');

      debugPrint('Local storage data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing local storage: $e');
    }
  }
}
