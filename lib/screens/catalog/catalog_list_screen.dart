import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/cards/CatalogCard.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/screens/clients/client_list_screen.dart';

class CatalogListScreen extends StatefulWidget {
  const CatalogListScreen({super.key});

  @override
  State<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends State<CatalogListScreen> {
  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Search query
  String _searchQuery = '';

  // Sample catalog data
  final List<Map<String, dynamic>> _catalogItems = [
    {
      'title': 'Website Design',
      'usageInfo': 'USED IN 3 INVOICES',
      'currency': 'USD',
      'amount': '4500.00',
    },
    {
      'title': 'Logo Design',
      'usageInfo': 'USED IN 2 INVOICES',
      'currency': 'USD',
      'amount': '1500.00',
    },
    {
      'title': 'Mobile App Development',
      'usageInfo': 'USED IN 5 INVOICES',
      'currency': 'USD',
      'amount': '8000.00',
    },
    {
      'title': 'SEO Services',
      'usageInfo': 'USED IN 4 INVOICES',
      'currency': 'USD',
      'amount': '2000.00',
    },
    {
      'title': 'Content Writing',
      'usageInfo': 'USED IN 3 INVOICES',
      'currency': 'USD',
      'amount': '1200.00',
    },
    {
      'title': 'UI/UX Design',
      'usageInfo': 'USED IN 6 INVOICES',
      'currency': 'USD',
      'amount': '3500.00',
    },
    {
      'title': 'Digital Marketing',
      'usageInfo': 'USED IN 2 INVOICES',
      'currency': 'USD',
      'amount': '2500.00',
    },
    {
      'title': 'Web Hosting',
      'usageInfo': 'USED IN 8 INVOICES',
      'currency': 'USD',
      'amount': '500.00',
    },
    {
      'title': 'Domain Registration',
      'usageInfo': 'USED IN 4 INVOICES',
      'currency': 'USD',
      'amount': '200.00',
    },
    {
      'title': 'Consultation',
      'usageInfo': 'USED IN 3 INVOICES',
      'currency': 'USD',
      'amount': '1800.00',
    },
  ];

  // Filtered catalog items based on search query
  List<Map<String, dynamic>> get _filteredCatalogItems {
    if (_searchQuery.isEmpty) {
      return _catalogItems;
    }

    final query = _searchQuery.toLowerCase();
    return _catalogItems.where((item) {
      return item['title'].toLowerCase().contains(query);
    }).toList();
  }

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == BottomNavItem.catalog) return; // Already on catalog screen

    if (item == BottomNavItem.home) {
      // Navigate to home screen with replacement
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (item == BottomNavItem.invoice) {
      // Navigate to invoice list screen with replacement
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const InvoiceListScreen()),
      );
    } else if (item == BottomNavItem.clients) {
      // Navigate to clients list screen with replacement
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ClientListScreen()),
      );
    }
    // Other navigation options would be handled here
  }

  // Handle the add button press
  void _handleAddTapped() {
    debugPrint('Show action options sheet');
  }

  // Handle search input changes
  void _handleSearchInputChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        // Prevent bottom navigation from being pushed up by keyboard
        resizeToAvoidBottomInset: false,
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            // Custom top navigation with catalog icon on left, sort and add icons on right
            SafeArea(
              bottom: false,
              child: NavContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Catalog icon and title
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/catalog-black.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            const Color(0xFF373C3A),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8), // 8px spacing
                        const Text(
                          'Catalog',
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

            // 32px spacing after TopNav
            const SizedBox(height: 32),

            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SearchInput(
                controller: _searchController,
                hintText: 'Search catalog',
                onChanged: _handleSearchInputChanged,
              ),
            ),

            // 24px spacing after Search Input
            const SizedBox(height: 24),

            // Main content area with catalog cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(child: _buildCatalogCards()),
              ),
            ),

            // Bottom navigation with catalog selected
            BottomNav(
              activeItem: BottomNavItem.catalog,
              onItemSelected: _handleNavItemSelected,
              onAddTapped: _handleAddTapped,
            ),
          ],
        ),
      ),
    );
  }

  // Build the catalog cards
  Widget _buildCatalogCards() {
    final filteredItems = _filteredCatalogItems;

    if (filteredItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(
            'No matching catalog items found',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8D9694),
              fontFamily: 'Helvetica Now Display',
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(filteredItems.length * 2 - 1, (index) {
        // Return card for even indices
        if (index.isEven) {
          final itemIndex = index ~/ 2;
          final item = filteredItems[itemIndex];

          return CatalogCard(
            title: item['title'],
            usageInfo: item['usageInfo'],
            currency: item['currency'],
            amount: item['amount'],
          );
        }
        // Return divider for odd indices
        else {
          return Column(
            children: const [
              SizedBox(height: 16),
              Divider(height: 1, color: Color(0xFFCAD5D2)),
              SizedBox(height: 16),
            ],
          );
        }
      })..add(const SizedBox(height: 16)), // Add bottom spacing
    );
  }
}
