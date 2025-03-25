import 'package:flutter/material.dart';
import 'package:invoicegenerator/services/mcp/storage_service_factory.dart';
import 'package:invoicegenerator/services/mcp/supabase_client.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/screens/splash/splash_screen.dart';
import 'package:invoicegenerator/screens/auth/auth_screen.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';
import 'package:invoicegenerator/screens/home/first_time_home_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/utils/supabase_debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Ensure Flutter is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the storage service factory
  final storageFactory = StorageServiceFactory();
  await storageFactory.init();

  try {
    // Initialize Supabase client with correct URL and anon key from MCP
    final supabaseUrl = 'https://ufzfgzlkqlofasujkwil.supabase.co';
    final supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVmemZnemxrcWxvZmFzdWprd2lsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4MjQ1NTcsImV4cCI6MjA1ODQwMDU1N30.zwYp4YdtP18FGSmghHybMw5K43l1JKVdl8M0R17e-S8';

    debugPrint('Initializing Supabase with URL: $supabaseUrl');
    debugPrint(
      'API Key first 10 chars: ${supabaseAnonKey.substring(0, 10)}...',
    );

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );

    debugPrint('Supabase initialized successfully');

    // Check if auth configuration is valid
    final isAuthConfigValid =
        await SupabaseDebugUtils.checkAndFixAuthConfiguration();
    if (!isAuthConfigValid) {
      debugPrint(
        '⚠️ WARNING: Supabase auth configuration is invalid or not working properly.',
      );
      debugPrint(
        'App will continue, but authentication may not work as expected.',
      );
    }

    SupabaseDebugUtils.validateConfiguration();
  } catch (e) {
    // If Supabase can't be initialized, log error but continue with local storage
    debugPrint('Error initializing Supabase: $e');
    debugPrint('App will continue in offline mode with local storage only');
  }

  // Log that we've fixed the Supabase data loading
  debugPrint(
    '✅ Fixed Supabase data loading - clients and catalogs will now be properly loaded from Supabase',
  );

  // Run the app
  runApp(const ProviderScope(child: InvoiceGeneratorApp()));
}

class InvoiceGeneratorApp extends StatefulWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  State<InvoiceGeneratorApp> createState() => _InvoiceGeneratorAppState();
}

class _InvoiceGeneratorAppState extends State<InvoiceGeneratorApp> {
  final supabase = Supabase.instance.client;
  late final ValueNotifier<Widget?> _currentScreen;
  final bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _currentScreen = ValueNotifier(null);

    // Initialize with the appropriate screen
    _determineInitialScreen().then((screen) {
      if (mounted) {
        _currentScreen.value = screen;
      }
    });

    // Setup auth state listener
    _setupAuthListener();

    // Log the current auth state for debugging at app start
    final currentUser = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;
    debugPrint('App init - Current user: ${currentUser?.email}');
    debugPrint('App init - Has session: ${session != null}');
  }

  // Setup listener for auth state changes
  void _setupAuthListener() {
    debugPrint('Setting up auth state listener');
    supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // Log the auth state change for debugging
      debugPrint(
        'Auth state change detected: $event, has session: ${session != null}',
      );

      if (session != null) {
        debugPrint('User ID: ${session.user.id}, Email: ${session.user.email}');
        debugPrint(
          'Session expires: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}',
        );
        debugPrint('Access token: ${session.accessToken.substring(0, 20)}...');
      } else {
        debugPrint('No session data available');
      }

      switch (event) {
        case AuthChangeEvent.signedIn:
          debugPrint('User signed in: ${session?.user.email}');

          // Clear any local data when user signs in to prevent conflicts
          final storageFactory = StorageServiceFactory();
          await storageFactory.forceDeleteAllLocalData();
          debugPrint('Cleared all local data after sign-in');

          _updateScreenAfterAuth();
          break;
        case AuthChangeEvent.signedOut:
          debugPrint('User signed out');
          if (mounted) {
            _currentScreen.value = const AuthScreen();
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
        case AuthChangeEvent.passwordRecovery:
        case AuthChangeEvent.userDeleted:
        case AuthChangeEvent.mfaChallengeVerified:
        default:
          // Don't change screens for these events
          break;
      }
    });
  }

  // Update the screen after an auth event
  void _updateScreenAfterAuth() {
    if (mounted) {
      _determineAuthenticatedScreen().then((screen) {
        if (mounted) {
          _currentScreen.value = screen;
        }
      });
    }
  }

  @override
  void dispose() {
    _currentScreen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: ValueListenableBuilder<Widget?>(
        valueListenable: _currentScreen,
        builder: (context, screen, child) {
          if (screen == null) {
            // Show loading screen while determining the initial screen
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your account...'),
                  ],
                ),
              ),
            );
          }
          return screen;
        },
      ),
    );
  }

  // Determine the initial screen to show
  Future<Widget> _determineInitialScreen() async {
    final currentUser = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;
    debugPrint(
      'Determining initial screen. Current user: ${currentUser?.email}, Has session: ${session != null}',
    );

    if (session != null) {
      debugPrint(
        'Session details: User ID: ${session.user.id}, expires: ${session.expiresAt}',
      );
      // User is authenticated, determine which screen to show
      return await _determineAuthenticatedScreen();
    } else {
      // User is not authenticated, show splash screen
      debugPrint('No authenticated user, showing splash screen');
      return const SplashScreen();
    }
  }

  // Determine which screen to show for an authenticated user
  Future<Widget> _determineAuthenticatedScreen() async {
    try {
      // Check if user has an organization
      final orgResponse =
          await supabase
              .from('organizations')
              .select('id')
              .limit(1)
              .maybeSingle();

      debugPrint('Organization check response: $orgResponse');

      if (orgResponse == null) {
        // User doesn't have an organization, send to onboarding
        debugPrint('No organization found, returning onboarding screen');
        return const CompanyBasicDetailsScreen();
      } else {
        // User has an organization, check if they have invoices
        final invoiceResponse =
            await supabase
                .from('invoices')
                .select('id')
                .eq('organization_id', orgResponse['id'])
                .limit(1)
                .maybeSingle();

        debugPrint('Invoice check response: $invoiceResponse');

        if (invoiceResponse == null) {
          // User has organization but no invoices
          debugPrint(
            'Organization found but no invoices, returning first time home screen',
          );
          return const FirstTimeHomeScreen();
        } else {
          // User has organization and invoices
          debugPrint('Organization and invoices found, returning home screen');
          return const HomeScreen();
        }
      }
    } catch (e) {
      debugPrint('Error determining screen to show: $e');
      // On error, default to onboarding to be safe
      return const CompanyBasicDetailsScreen();
    }
  }
}
