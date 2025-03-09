import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == BottomNavItem.invoice) return; // Already on invoice screen

    if (item == BottomNavItem.home) {
      // Go back to home screen
      Navigator.of(context).pop();
    }
    // Other navigation options would be handled here
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
          // Custom top navigation with invoice icon on left, sort and add icons on right
          SafeArea(
            bottom: false,
            child: NavContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Invoice icon on the left
                  SvgPicture.asset(
                    'assets/icons/invoice.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      const Color(0xFF373C3A),
                      BlendMode.srcIn,
                    ),
                  ),

                  // Sort and Add icons on the right with 16px spacing
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/sort.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          const Color(0xFF373C3A),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 16), // 16px spacing
                      SvgPicture.asset(
                        'assets/icons/add-black.svg',
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main content area (currently empty as per instructions)
          Expanded(child: Container()),

          // Bottom navigation with invoice selected
          BottomNav(
            activeItem: BottomNavItem.invoice,
            onItemSelected: _handleNavItemSelected,
            onAddTapped: _handleAddTapped,
          ),
        ],
      ),
    );
  }
}
