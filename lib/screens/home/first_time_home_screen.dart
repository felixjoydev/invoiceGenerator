import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/display/information_box.dart';
import 'package:invoicegenerator/widgets/display/welcome_header.dart';
import 'package:invoicegenerator/widgets/cards/welcome_action.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';

class FirstTimeHomeScreen extends StatefulWidget {
  const FirstTimeHomeScreen({super.key});

  @override
  State<FirstTimeHomeScreen> createState() => _FirstTimeHomeScreenState();
}

class _FirstTimeHomeScreenState extends State<FirstTimeHomeScreen> {
  // Current active nav item (default to home)
  BottomNavItem _activeNavItem = BottomNavItem.home;

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == _activeNavItem) return; // Already on this screen

    setState(() {
      _activeNavItem = item;
    });

    // TODO: Implement actual navigation between screens
    switch (item) {
      case BottomNavItem.home:
        debugPrint('Navigate to Home');
        break;
      case BottomNavItem.invoice:
        debugPrint('Navigate to Invoices');
        break;
      case BottomNavItem.clients:
        debugPrint('Navigate to Clients');
        break;
      case BottomNavItem.catalog:
        debugPrint('Navigate to Catalog');
        break;
      case BottomNavItem.add:
        // This should never be called as the add button has a separate handler
        break;
    }
  }

  // Handle the add button press
  void _handleAddTapped() {
    // TODO: Implement the action sheet toggle
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
                // For testing: Navigate to HomeScreen when logo is clicked
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              onSettingsPressed: () {
                debugPrint('Settings pressed');
              },
            ),
          ),

          // 32px spacing after TopNav
          const SizedBox(height: 32),

          // Welcome header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: WelcomeScreen(),
          ),

          // 40px spacing after welcome header
          const SizedBox(height: 56),

          // Welcome actions list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: WelcomeActionsList(
              onInvoicePressed: () {
                debugPrint('Create invoice pressed');
              },
              onClientPressed: () {
                debugPrint('Add client pressed');
              },
              onCatalogPressed: () {
                debugPrint('Add catalog item pressed');
              },
            ),
          ),

          // Spacer to push content to bottom
          const Spacer(),

          // Information box
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: InformationBox(),
          ),

          // 40px spacing above bottom nav
          const SizedBox(height: 40),

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
