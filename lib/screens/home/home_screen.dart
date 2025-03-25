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
import 'package:invoicegenerator/services/hive/service_provider.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // Initialize services
  Future<void> _initializeServices() async {
    await _invoiceService.init();
    await _revenueService.init();
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
                slideFromRight: false, // Not applicable for initial screen load
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
  }
}
