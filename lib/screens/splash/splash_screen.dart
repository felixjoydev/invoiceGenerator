import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/screens/auth/get-started.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';
import 'package:invoicegenerator/screens/home/first_time_home_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';
import 'package:invoicegenerator/services/hive/service_provider.dart';
import 'package:invoicegenerator/services/hive/data_cleanup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late HiveServiceProvider _serviceProvider;
  String? _errorMessage;
  bool _needsReset = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();

    debugPrint('SplashScreen initialized');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Determine which screen to show after a delay
    Timer(const Duration(seconds: 3), () {
      _navigateToAppropriateScreen();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      // Get the service provider
      _serviceProvider = HiveServiceProviderWidget.of(context);
      debugPrint('SplashScreen: Service provider obtained successfully');
    } catch (e) {
      debugPrint('ERROR getting service provider: $e');
      setState(() {
        _errorMessage = 'Service provider error: $e';
        _needsReset = true;
      });
    }
  }

  Future<void> _resetApp() async {
    if (_isResetting) return;

    setState(() {
      _isResetting = true;
      _errorMessage = 'Resetting application...';
    });

    try {
      debugPrint('Performing app reset...');
      await DataCleanup.forceCleanStart();

      // Re-initialize Hive
      await HiveConfig.initialize();

      // Reset the service provider
      final serviceProvider = HiveServiceProviderWidget.of(context);
      await serviceProvider.initialize();

      debugPrint('App reset complete, restarting...');

      setState(() {
        _errorMessage = 'Reset complete, restarting app...';
      });

      // Wait a moment and then navigate to Get Started
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToScreen(const GetStartedScreen());
        }
      });
    } catch (e) {
      debugPrint('ERROR during app reset: $e');
      setState(() {
        _errorMessage = 'Reset failed: $e\nPlease restart the app manually.';
        _isResetting = false;
      });
    }
  }

  Future<void> _navigateToAppropriateScreen() async {
    try {
      debugPrint('SplashScreen: Determining next screen...');

      // Check if company info exists and has been set up
      final companyInfo = _serviceProvider.companyInfoService.companyInfo;
      debugPrint(
        'SplashScreen: Company info retrieved: ${companyInfo != null}',
      );

      if (companyInfo == null || companyInfo.businessName.isEmpty) {
        // New user, show get started screen
        debugPrint(
          'SplashScreen: No company info found, navigating to GetStartedScreen',
        );
        _navigateToScreen(const GetStartedScreen());
        return;
      }

      // Check if there are any invoices using the service instead of direct box access
      final invoices = _serviceProvider.invoiceService.invoices;
      debugPrint('SplashScreen: Found ${invoices.length} invoices');

      if (invoices.isEmpty) {
        // Existing user with no invoices yet
        debugPrint(
          'SplashScreen: No invoices found, navigating to FirstTimeHomeScreen',
        );
        _navigateToScreen(const FirstTimeHomeScreen());
      } else {
        // Existing user with invoices
        debugPrint('SplashScreen: Invoices found, navigating to HomeScreen');
        _navigateToScreen(const HomeScreen());
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR navigating: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _errorMessage = 'Navigation error: $e';
        _needsReset = true;
      });
    }
  }

  void _navigateToScreen(Widget screen) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Center(
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
                  width: 100, // Width set to 100
                  height: 125, // Height adjusted proportionally
                ),
              ),
            ),
          ),

          // Display error message if any
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Show reset button if needed
          if (_needsReset)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _isResetting ? null : _resetApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_isResetting ? 'Resetting...' : 'Reset App Data'),
              ),
            ),
        ],
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
