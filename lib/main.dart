import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoicegenerator/screens/splash/splash_screen.dart';
import 'package:invoicegenerator/services/hive/hive_config.dart';
import 'package:invoicegenerator/services/hive/migration_service.dart';
import 'package:invoicegenerator/services/hive/service_provider.dart';
import 'package:invoicegenerator/services/hive/data_cleanup.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Set to true to force a clean start (for debugging only)
const bool forceCleanStart = false;

void main() async {
  // Ensure Flutter is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('=== App starting, initializing dependencies ===');

  try {
    // Force clean start if needed (for debugging)
    if (forceCleanStart) {
      debugPrint('FORCING CLEAN START (debug mode)');
      await DataCleanup.forceCleanStart();
    }

    // Initialize Hive
    debugPrint('Initializing Hive...');
    await HiveConfig.initialize();
    debugPrint('Hive initialized successfully');

    // Clean up old test data (both in SharedPreferences and Hive)
    debugPrint('Cleaning up test data...');
    await DataCleanup.cleanupTestData();
    debugPrint('Data cleanup complete');

    // Run client data migration to fix any missing fields
    debugPrint('Running client data migration...');
    await DataCleanup.migrateClientData();
    debugPrint('Client data migration complete');

    // Check if migration is needed and run it
    debugPrint('Checking migration status...');
    bool migrationCompleted = false;
    try {
      migrationCompleted = await MigrationService.isMigrationCompleted();
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      // Default to false if there's an error checking
      migrationCompleted = false;
    }

    if (!migrationCompleted) {
      debugPrint('Migration needed, running migration...');
      try {
        await MigrationService.migrateToHive();
        debugPrint('Migration completed');
      } catch (e) {
        debugPrint('Error during migration: $e');
        // Continue with app startup even if migration fails
      }
    } else {
      debugPrint('Migration already completed, skipping');
    }

    // Initialize the service provider
    debugPrint('Initializing service provider...');
    final serviceProvider = HiveServiceProvider();
    await serviceProvider.initialize();
    debugPrint('Service provider initialized successfully');

    // Recalculate all statistics using the invoice service
    debugPrint('Recalculating all statistics...');
    await serviceProvider.invoiceService.recalculateAllStatistics();
    debugPrint('Statistics recalculation complete');

    // Run the app
    debugPrint('Running app...');
    runApp(
      ProviderScope(
        child: HiveServiceProviderWidget(
          serviceProvider: serviceProvider,
          child: const InvoiceGeneratorApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    // Log any errors during initialization
    debugPrint('ERROR DURING INITIALIZATION: $e');
    debugPrint('Stack trace: $stackTrace');

    // Run a minimal app that displays the error
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Initialization Error: $e'))),
      ),
    );
  }
}

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const SplashScreen(),
    );
  }
}
