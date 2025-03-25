import 'package:flutter/material.dart';
import 'package:invoicegenerator/services/hive/company_info_service.dart';
import 'package:invoicegenerator/services/hive/client_service.dart';
import 'package:invoicegenerator/services/hive/catalog_service.dart';
import 'package:invoicegenerator/services/hive/invoice_service.dart';
import 'package:invoicegenerator/services/hive/invoice_settings_service.dart';

/// Provider for all Hive-based services with singleton pattern
class HiveServiceProvider {
  // Singleton instance
  static final HiveServiceProvider _instance = HiveServiceProvider._internal();

  // Services
  final CompanyInfoService companyInfoService = CompanyInfoService();
  final ClientService clientService = ClientService();
  final CatalogService catalogService = CatalogService();
  final InvoiceService invoiceService = InvoiceService();
  final InvoiceSettingsService invoiceSettingsService =
      InvoiceSettingsService();

  // Flag to check if initialized
  bool _isInitialized = false;

  // Flag to track if statistics have been calculated in this session
  bool _statisticsCalculated = false;

  // Factory constructor
  factory HiveServiceProvider() => _instance;

  // Private constructor
  HiveServiceProvider._internal();

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // First initialize all services
      await companyInfoService.init();
      await clientService.init();
      await catalogService.init();
      await invoiceSettingsService.init();
      await invoiceService.init();

      // Set up dependencies between services
      invoiceService.setDependencies(
        clientService: clientService,
        catalogService: catalogService,
        settingsService: invoiceSettingsService,
      );

      // Always force calculation of statistics at startup
      await _forceCalculateStatistics();

      _isInitialized = true;
      debugPrint('HiveServiceProvider initialized successfully');
    } catch (e) {
      debugPrint('Error initializing HiveServiceProvider: $e');
      rethrow;
    }
  }

  /// Force recalculation of all statistics
  Future<void> _forceCalculateStatistics() async {
    debugPrint('Force calculating all statistics at startup...');
    await invoiceService.recalculateAllStatistics();
    _statisticsCalculated = true;
    debugPrint('Statistics calculation completed');
  }

  /// Ensure statistics are calculated - can be called when screens are shown
  Future<void> ensureStatisticsCalculated() async {
    if (!_statisticsCalculated) {
      debugPrint('Calculating statistics on first access...');
      await invoiceService.recalculateAllStatistics();
      _statisticsCalculated = true;
      debugPrint('Initial statistics calculation completed');
    } else {
      debugPrint('Statistics already calculated in this session');
    }
  }
}

/// Widget that provides access to Hive services
class HiveServiceProviderWidget extends InheritedWidget {
  final HiveServiceProvider serviceProvider;

  const HiveServiceProviderWidget({
    Key? key,
    required Widget child,
    required this.serviceProvider,
  }) : super(key: key, child: child);

  static HiveServiceProvider of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<HiveServiceProviderWidget>();
    return widget!.serviceProvider;
  }

  @override
  bool updateShouldNotify(HiveServiceProviderWidget oldWidget) {
    return serviceProvider != oldWidget.serviceProvider;
  }
}
