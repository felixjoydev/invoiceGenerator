import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/screens/home/first_time_home_screen.dart';
import 'package:invoicegenerator/widgets/cards/RevenueCard.dart';
import 'package:invoicegenerator/widgets/cards/OverviewCard.dart';
import 'package:invoicegenerator/widgets/cards/TopClients.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Current active nav item (default to home)
  BottomNavItem _activeNavItem = BottomNavItem.home;

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == _activeNavItem) return; // Already on this screen

    // Handle navigation based on selected item
    if (item == BottomNavItem.invoice) {
      // Navigate to invoice list screen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const InvoiceListScreen()),
      );
    } else {
      // For other tabs, just update the state for now
      setState(() {
        _activeNavItem = item;
      });
    }
  }

  // Handle the add button press
  void _handleAddTapped() {
    debugPrint('Show action options sheet');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                debugPrint('Settings pressed');
              },
            ),
          ),

          // Scrollable content area
          Expanded(
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

          // Bottom navigation
          BottomNav(
            activeItem: _activeNavItem,
            onItemSelected: _handleNavItemSelected,
            onAddTapped: _handleAddTapped,
          ),
        ],
      ),
    );
  }
}
