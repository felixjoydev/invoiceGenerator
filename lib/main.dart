import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/screens/splash/splash_screen.dart';
import 'package:invoicegenerator/services/auth_provider.dart';
import 'package:invoicegenerator/services/auth/deep_link_handler.dart';
import 'package:invoicegenerator/services/auth/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for navigating without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'main_navigator',
);

// App state key for provider scope
final GlobalKey appStateKey = GlobalKey(debugLabel: 'app_state');

// Get a reference to Supabase client for easier access
final supabase = Supabase.instance.client;

void main() async {
  // Ensure Flutter is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 App starting - Flutter binding initialized');

  try {
    // TEMPORARY: Clear all SharedPreferences data to fix client persistence issue
    debugPrint('🧹 Clearing all local storage data');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('✅ Local storage cleared successfully');

    debugPrint('🚀 Starting Supabase initialization...');

    // Initialize Supabase client with proper credentials
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      debug: true,
    );
    debugPrint('✅ Supabase initialized successfully');

    // Clear any existing sessions that might cause issues
    await DeepLinkHandler.clearAuthState();
    debugPrint('✅ Auth state cleared');

    // Initialize deep link handling for authentication callbacks
    await DeepLinkHandler.initializeDeepLinkHandling();
    debugPrint('✅ Deep link handling initialized');
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
  } finally {
    // Always run the app, even if initialization failed
    debugPrint('🚀 Running app...');
    runApp(ProviderScope(key: appStateKey, child: const InvoiceGeneratorApp()));
  }
}

class InvoiceGeneratorApp extends StatefulWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  State<InvoiceGeneratorApp> createState() => _InvoiceGeneratorAppState();
}

class _InvoiceGeneratorAppState extends State<InvoiceGeneratorApp> {
  // Key to force app rebuild when needed
  final _appKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 InvoiceGeneratorApp - initState');

    // Initialize deep link handling again for good measure
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.initializeDeepLinkHandling();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🚀 InvoiceGeneratorApp - build');
    return AuthProvider(
      child: MaterialApp(
        key: _appKey,
        title: 'Invoice Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
        builder: (context, child) {
          // Log when we're building the app
          debugPrint('🚀 MaterialApp builder called');
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
