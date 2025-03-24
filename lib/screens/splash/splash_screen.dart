import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/screens/auth/get-started.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/main.dart'; // Import for navigatorKey
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 SplashScreen - initState');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    debugPrint('🚀 SplashScreen - animation started');

    // Delay the auth check to allow animations to complete
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint('🚀 SplashScreen - Delay complete, starting navigation check');
      if (mounted) {
        _checkAuthAndRedirect();
      } else {
        debugPrint('❌ SplashScreen - Widget not mounted after delay');
      }
    });
  }

  void _navigateToScreen(Widget screen) {
    debugPrint('🚀 Attempting to navigate to ${screen.runtimeType}');

    // Set custom transition based on screen type
    late PageRouteBuilder route;

    // Special case for GetStartedScreen to ensure smooth hero animation
    if (screen is GetStartedScreen) {
      route = PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    } else {
      // For other screens, use standard MaterialPageRoute
      route = PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    }

    // Is the navigator key valid?
    if (navigatorKey.currentState == null) {
      debugPrint('❌ Navigator key currentState is NULL!');

      // Try using context as fallback
      try {
        debugPrint('🚀 Trying context-based navigation as fallback');
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacement(route);
        } else {
          debugPrint('❌ Context not mounted for fallback navigation');
        }
      } catch (e) {
        debugPrint('❌ Error in fallback navigation: $e');
      }
      return;
    }

    try {
      // Use the custom route
      navigatorKey.currentState!.pushReplacement(route);
      debugPrint('✅ Navigation completed to ${screen.runtimeType}');
    } catch (e) {
      debugPrint('❌ Error during navigation: $e');
    }
  }

  Future<void> _checkAuthAndRedirect() async {
    debugPrint('🚀 _checkAuthAndRedirect started');

    if (_isNavigating) {
      debugPrint('❌ Already navigating, skipping redirect');
      return;
    }

    // Set flag to prevent multiple navigation attempts
    _isNavigating = true;
    debugPrint('🚀 Navigation flag set');

    try {
      debugPrint('🚀 Checking Supabase session');
      final session = Supabase.instance.client.auth.currentSession;
      debugPrint(
        '🚀 Session check complete: ${session != null ? 'Has session' : 'No session'}',
      );

      // If no authenticated user, always clear local storage
      if (session == null) {
        debugPrint('❌ No authenticated user, clearing local storage');
        await _clearLocalStorageData();

        // Navigate to GetStartedScreen for unauthenticated users
        debugPrint('🚀 Navigating to GetStartedScreen (no auth)');
        await Future.delayed(const Duration(milliseconds: 200));
        _navigateToScreen(const GetStartedScreen());
        return;
      }

      // User is authenticated, check if they have a profile
      debugPrint('🚀 User is authenticated, checking profile');
      try {
        debugPrint('🚀 Querying profiles table');
        final userId = session.user.id;
        debugPrint('🚀 User ID: $userId');

        // Try to load the profile with business name
        final response =
            await Supabase.instance.client
                .from('profiles')
                .select('id, business_name, updated_at')
                .eq('id', userId)
                .maybeSingle();

        final bool hasCompleteProfile =
            response != null &&
            response['business_name'] != null &&
            response['business_name'].toString().isNotEmpty;

        if (hasCompleteProfile) {
          // User has a complete profile, go to Home
          debugPrint(
            '✅ User profile found with business name: ${response['business_name']}',
          );
          await Future.delayed(const Duration(milliseconds: 200));
          _navigateToScreen(const HomeScreen());
        } else {
          // Check if there's any profile data at all - could be partially completed
          final anyProfileData =
              await Supabase.instance.client
                  .from('profiles')
                  .select('id')
                  .eq('id', userId)
                  .maybeSingle();

          // Check if we have temporary onboarding data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final tempBusinessName = prefs.getString('temp_business_name');

          if (anyProfileData != null || tempBusinessName != null) {
            // User has either started onboarding or has a partial profile
            debugPrint(
              '🚀 User has partial profile data, continuing with onboarding',
            );
            await Future.delayed(const Duration(milliseconds: 200));
            _navigateToScreen(const CompanyBasicDetailsScreen());
          } else {
            // New user without any profile, start onboarding
            debugPrint('🚀 No user profile found, starting fresh onboarding');
            await Future.delayed(const Duration(milliseconds: 200));
            _navigateToScreen(const CompanyBasicDetailsScreen());
          }
        }
      } catch (e) {
        // Error occurred while checking profile
        debugPrint('❌ Error checking user profile: $e');

        // Default to onboarding for safety
        await Future.delayed(const Duration(milliseconds: 200));
        _navigateToScreen(const CompanyBasicDetailsScreen());
      }
    } catch (e) {
      debugPrint('❌ Error in auth check: $e');

      // Navigate to GetStartedScreen on error
      debugPrint('❌ Navigating to GetStartedScreen due to auth error');

      // Clear any local storage data to ensure a clean start
      await _clearLocalStorageData();

      await Future.delayed(const Duration(milliseconds: 200));
      _navigateToScreen(const GetStartedScreen());
    }
  }

  // Clear all local storage data
  Future<void> _clearLocalStorageData() async {
    debugPrint('Clearing local storage data in SplashScreen');
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

      debugPrint('Local storage data cleared successfully in SplashScreen');
    } catch (e) {
      debugPrint('Error clearing local storage in SplashScreen: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🚀 SplashScreen - dispose');
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🚀 SplashScreen - build');
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Hero(
            tag: 'logo',
            flightShuttleBuilder: (
              BuildContext flightContext,
              Animation<double> animation,
              HeroFlightDirection flightDirection,
              BuildContext fromHeroContext,
              BuildContext toHeroContext,
            ) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return SvgPicture.asset(
                    'assets/icons/logo.svg',
                    width: Tween<double>(
                      begin: 100,
                      end: 40,
                    ).evaluate(animation),
                    height: Tween<double>(
                      begin: 125,
                      end: 49,
                    ).evaluate(animation),
                  );
                },
              );
            },
            child: SvgPicture.asset(
              'assets/icons/logo.svg',
              width: 100,
              height: 125,
            ),
          ),
        ),
      ),
    );
  }
}

// Temporary placeholder until we create the auth screen
class SplashPlaceholder extends StatelessWidget {
  const SplashPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Coming Soon',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'re building the authentication screen next',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
