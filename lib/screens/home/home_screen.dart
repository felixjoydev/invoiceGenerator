import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/screens/home/first_time_home_screen.dart';
import 'package:invoicegenerator/widgets/cards/RevenueCard.dart';
import 'package:invoicegenerator/widgets/cards/OverviewCard.dart';
import 'package:invoicegenerator/widgets/cards/TopClients.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/screens/clients/client_list_screen.dart';
import 'package:invoicegenerator/screens/catalog/catalog_list_screen.dart';
import 'package:invoicegenerator/utils/route_transitions.dart';
import 'package:invoicegenerator/screens/settings/settings_screen.dart';
import 'package:invoicegenerator/services/revenue_service.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:provider/provider.dart';
import 'package:invoicegenerator/screens/auth/get-started.dart'; // For fallback

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Current active nav item (default to home)
  BottomNavItem _activeNavItem = BottomNavItem.home;

  // Services
  final RevenueService _revenueService = RevenueService();
  final InvoiceService _invoiceService = InvoiceService();
  bool _servicesInitialized = false;
  bool _initializingError = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomeScreen - initState');
    _initializeServices();
  }

  // Initialize services
  Future<void> _initializeServices() async {
    debugPrint('🏠 HomeScreen - initializing services');
    try {
      await _invoiceService.init();
      await _revenueService.init();
      debugPrint('✅ HomeScreen - services initialized successfully');

      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ HomeScreen - Error initializing services: $e');
      if (mounted) {
        setState(() {
          _initializingError = true;
        });
      }
    }
  }

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == _activeNavItem) return; // Already on this screen

    // Handle navigation based on selected item
    if (item == BottomNavItem.invoice) {
      // Navigate to invoice list screen with animation
      context.navigateWithSlide(const InvoiceListScreen());
    } else if (item == BottomNavItem.clients) {
      // Navigate to client list screen with animation
      context.navigateWithSlide(const ClientListScreen());
    } else if (item == BottomNavItem.catalog) {
      // Navigate to catalog list screen with animation
      context.navigateWithSlide(const CatalogListScreen());
    } else {
      // For other tabs, just update the state for now
      setState(() {
        _activeNavItem = item;
      });
    }
  }

  // Handle the add button press
  void _handleAddTapped() {
    // Show debug options in debug mode
    if (kDebugMode) {
      _showDebugOptions();
    } else {
      debugPrint('Show action options sheet');
    }
  }

  // Show debug options menu
  void _showDebugOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Debug Options'),
                    subtitle: const Text('Development testing tools'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.money),
                    title: const Text('Test Revenue Calculation'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _revenueService.testRevenueCalculation();
                      setState(() {}); // Refresh UI
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Refresh Revenue Data'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _revenueService.calculateAllMonthlyRevenues();
                      setState(() {}); // Refresh UI
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.healing),
                    title: const Text('Verify & Fix Invoice Data'),
                    subtitle: const Text('Repair corrupted invoice records'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _revenueService.verifyAndFixInvoiceData();
                      setState(() {}); // Refresh UI
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 HomeScreen - build');

    // Display a loading indicator while services are initializing
    if (!_servicesInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your dashboard...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Display error screen if there was an issue initializing
    if (_initializingError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading dashboard data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please try again later', style: TextStyle(fontSize: 16)),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initializingError = false;
                    _servicesInitialized = false;
                  });
                  _initializeServices();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Build the actual home screen if everything is ready
    try {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _revenueService),
          ChangeNotifierProvider.value(value: _invoiceService),
        ],
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              // Top navigation with SafeArea
              SafeArea(
                bottom: false,
                child: HomeTopNav(
                  onThemeToggle: () {
                    // Navigate to first_time_home_screen for testing
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const FirstTimeHomeScreen(),
                      ),
                    );
                  },
                  onSettingsPressed: () {
                    SettingsScreen.show(context);
                  },
                ),
              ),

              // Scrollable content area with slide transition
              Expanded(
                child: ContentSlideTransition(
                  slideFromRight:
                      false, // Not applicable for initial screen load
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 32px spacing after TopNav
                        const SizedBox(height: 32),

                        // Revenue Card
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: RevenueCard(),
                        ),

                        // 32px spacing after RevenueCard
                        const SizedBox(height: 32),

                        // Overview Card
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: OverviewCard(),
                        ),

                        // 32px spacing after OverviewCard
                        const SizedBox(height: 32),

                        // Top Clients Card
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: TopClients(),
                        ),

                        // Add some bottom padding to ensure content doesn't get cut off
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom navigation
              BottomNav(
                activeItem: _activeNavItem,
                onItemSelected: _handleNavItemSelected,
                onAddTapped: _handleAddTapped,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ HomeScreen - Error in build: $e');
      // Fallback UI in case of rendering errors
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('Dashboard Error'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => GetStartedScreen()),
                  );
                },
                child: Text('Go to Start Screen'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
