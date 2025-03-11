import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/utils/route_transitions.dart';
import 'package:invoicegenerator/screens/catalog/catalog_list_screen.dart';

class AddCatalogScreen extends StatefulWidget {
  const AddCatalogScreen({super.key});

  @override
  State<AddCatalogScreen> createState() => _AddCatalogScreenState();
}

class _AddCatalogScreenState extends State<AddCatalogScreen> {
  // Handle back button press
  void _handleBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Custom top navigation with back button on left and "Add Catalog Item" title
          SafeArea(
            bottom: false,
            child: NavContainer(
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: _handleBackPressed,
                    child: SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        const Color(0xFF373C3A),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // 8px spacing
                  const Text(
                    'Add Catalog Item',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF373C3A),
                      fontFamily: 'HelveticaNowDisplay',
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 8px spacing after TopNav (same as in catalog_list_screen.dart)
          const SizedBox(height: 8),

          // Content area (to be filled later)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Content will be added here
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
