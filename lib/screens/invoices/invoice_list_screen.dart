import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/display/tabs.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/cards/DueCard.dart';
import 'package:invoicegenerator/widgets/cards/OustandingCard.dart'
    as Outstanding;
import 'package:invoicegenerator/widgets/cards/PaidCard.dart' as Paid;
import 'package:invoicegenerator/screens/clients/client_list_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/screens/catalog/catalog_list_screen.dart';
import 'package:invoicegenerator/utils/route_transitions.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  // Selected tab index
  int _selectedTabIndex = 0;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Search query
  String _searchQuery = '';

  // Original invoice card data for each tab
  final List<Map<String, dynamic>> _overdueInvoices = [
    {
      'companyName': 'Acuro',
      'date': '05/03/2025',
      'invoiceNumber': 'inv-001',
      'amount': '\$423.00',
      'daysText': '12 days due',
      'daysColor': const Color(0xFFD61443),
    },
    {
      'companyName': 'Thalamus',
      'date': '08/03/2025',
      'invoiceNumber': 'inv-002',
      'amount': '\$625.00',
      'daysText': '15 days due',
      'daysColor': const Color(0xFFD61443),
    },
    {
      'companyName': 'Cortex',
      'date': '12/03/2025',
      'invoiceNumber': 'inv-003',
      'amount': '\$220.00',
      'daysText': '19 days due',
      'daysColor': const Color(0xFFD61443),
    },
    {
      'companyName': 'Medula',
      'date': '15/03/2025',
      'invoiceNumber': 'inv-004',
      'amount': '\$750.00',
      'daysText': '22 days due',
      'daysColor': const Color(0xFFD61443),
    },
    {
      'companyName': 'Cerebrum',
      'date': '20/03/2025',
      'invoiceNumber': 'inv-005',
      'amount': '\$320.00',
      'daysText': '27 days due',
      'daysColor': const Color(0xFFD61443),
    },
  ];

  final List<Map<String, dynamic>> _outstandingInvoices = [
    {
      'companyName': 'Neurox',
      'date': '05/04/2025',
      'invoiceNumber': 'inv-006',
      'amount': '\$550.00',
      'daysText': 'DUE IN 5 DAYS',
      'daysColor': const Color(0xFFD68814),
    },
    {
      'companyName': 'Synaptix',
      'date': '10/04/2025',
      'invoiceNumber': 'inv-007',
      'amount': '\$320.00',
      'daysText': 'DUE IN 10 DAYS',
      'daysColor': const Color(0xFFD68814),
    },
    {
      'companyName': 'Axonify',
      'date': '15/04/2025',
      'invoiceNumber': 'inv-008',
      'amount': '\$820.00',
      'daysText': 'DUE IN 15 DAYS',
      'daysColor': const Color(0xFFD68814),
    },
    {
      'companyName': 'BrainTech',
      'date': '20/04/2025',
      'invoiceNumber': 'inv-009',
      'amount': '\$450.00',
      'daysText': 'DUE IN 20 DAYS',
      'daysColor': const Color(0xFFD68814),
    },
  ];

  final List<Map<String, dynamic>> _paidInvoices = [
    {
      'companyName': 'Cognition',
      'date': '01/02/2025',
      'invoiceNumber': 'inv-010',
      'amount': '\$320.00',
      'daysText': 'PAID ON 10/02/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'NeuralWorks',
      'date': '05/02/2025',
      'invoiceNumber': 'inv-011',
      'amount': '\$450.00',
      'daysText': 'PAID ON 15/02/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'Synaptica',
      'date': '10/02/2025',
      'invoiceNumber': 'inv-012',
      'amount': '\$550.00',
      'daysText': 'PAID ON 20/02/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'Neurolink',
      'date': '15/02/2025',
      'invoiceNumber': 'inv-013',
      'amount': '\$390.00',
      'daysText': 'PAID ON 25/02/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'MindSphere',
      'date': '20/02/2025',
      'invoiceNumber': 'inv-014',
      'amount': '\$620.00',
      'daysText': 'PAID ON 01/03/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'CerebralTech',
      'date': '25/02/2025',
      'invoiceNumber': 'inv-015',
      'amount': '\$480.00',
      'daysText': 'PAID ON 05/03/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'BrainWave',
      'date': '01/03/2025',
      'invoiceNumber': 'inv-016',
      'amount': '\$350.00',
      'daysText': 'PAID ON 10/03/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'NeuralNet',
      'date': '05/03/2025',
      'invoiceNumber': 'inv-017',
      'amount': '\$520.00',
      'daysText': 'PAID ON 15/03/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'SynapseAI',
      'date': '10/03/2025',
      'invoiceNumber': 'inv-018',
      'amount': '\$410.00',
      'daysText': 'PAID ON 20/03/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
    {
      'companyName': 'CognitiveTech',
      'date': '15/03/2025',
      'invoiceNumber': 'inv-019',
      'amount': '\$580.00',
      'daysText': 'PAID ON 25/03/2025',
      'daysColor': const Color(0xFF13AF5B),
    },
  ];

  // Filtered lists based on search query
  List<Map<String, dynamic>> get _filteredOverdueInvoices {
    if (_searchQuery.isEmpty) {
      return _overdueInvoices;
    }

    final query = _searchQuery.toLowerCase();
    return _overdueInvoices.where((invoice) {
      return invoice['companyName'].toLowerCase().contains(query) ||
          invoice['invoiceNumber'].toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredOutstandingInvoices {
    if (_searchQuery.isEmpty) {
      return _outstandingInvoices;
    }

    final query = _searchQuery.toLowerCase();
    return _outstandingInvoices.where((invoice) {
      return invoice['companyName'].toLowerCase().contains(query) ||
          invoice['invoiceNumber'].toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPaidInvoices {
    if (_searchQuery.isEmpty) {
      return _paidInvoices;
    }

    final query = _searchQuery.toLowerCase();
    return _paidInvoices.where((invoice) {
      return invoice['companyName'].toLowerCase().contains(query) ||
          invoice['invoiceNumber'].toLowerCase().contains(query);
    }).toList();
  }

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == BottomNavItem.invoice) return; // Already on invoice screen

    if (item == BottomNavItem.home) {
      // Go back to home screen with replacement
      context.navigateWithSlide(const HomeScreen());
    } else if (item == BottomNavItem.clients) {
      // Navigate to client list screen with replacement
      context.navigateWithSlide(const ClientListScreen());
    } else if (item == BottomNavItem.catalog) {
      // Navigate to catalog list screen with replacement
      context.navigateWithSlide(const CatalogListScreen());
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
            // Custom top navigation with invoice icon on left, sort and add icons on right
            SafeArea(
              bottom: false,
              child: NavContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Invoice icon and title
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/invoice.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            const Color(0xFF373C3A),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8), // 8px spacing
                        const Text(
                          'Invoices',
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
            const SizedBox(height: 16),

            // Tabs for invoice categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomTabBar(
                tabs: const ['Overdue', 'Outstanding', 'Paid'],
                initialTabIndex: _selectedTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
            ),

            // 16px spacing after Tabs
            const SizedBox(height: 16),

            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SearchInput(
                controller: _searchController,
                hintText: 'Search invoices',
                onChanged: _handleSearchInputChanged,
              ),
            ),

            // 24px spacing after Search Input
            const SizedBox(height: 24),

            // Main content area with cards based on selected tab
            Expanded(
              child: ContentSlideTransition(
                // Direction determination happens in the route
                slideFromRight:
                    ModalRoute.of(context)?.settings.arguments is HomeScreen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    child:
                        _selectedTabIndex == 0
                            ? _buildOverdueCards()
                            : _selectedTabIndex == 1
                            ? _buildOutstandingCards()
                            : _buildPaidCards(),
                  ),
                ),
              ),
            ),

            // Bottom navigation with invoice selected
            BottomNav(
              activeItem: BottomNavItem.invoice,
              onItemSelected: _handleNavItemSelected,
              onAddTapped: _handleAddTapped,
            ),
          ],
        ),
      ),
    );
  }

  // Build the Overdue tab content
  Widget _buildOverdueCards() {
    final filteredInvoices = _filteredOverdueInvoices;

    if (filteredInvoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(
            'No matching invoices found',
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
      children: List.generate(filteredInvoices.length * 2 - 1, (index) {
        // Return card for even indices
        if (index.isEven) {
          final invoiceIndex = index ~/ 2;
          final invoice = filteredInvoices[invoiceIndex];

          return DueCard(
            companyName: invoice['companyName'],
            date: invoice['date'],
            invoiceNumber: invoice['invoiceNumber'],
            amount: invoice['amount'],
            daysText: invoice['daysText'],
            daysColor: invoice['daysColor'],
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

  // Build the Outstanding tab content
  Widget _buildOutstandingCards() {
    final filteredInvoices = _filteredOutstandingInvoices;

    if (filteredInvoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(
            'No matching invoices found',
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
      children: List.generate(filteredInvoices.length * 2 - 1, (index) {
        // Return card for even indices
        if (index.isEven) {
          final invoiceIndex = index ~/ 2;
          final invoice = filteredInvoices[invoiceIndex];

          return Outstanding.DueCard(
            companyName: invoice['companyName'],
            date: invoice['date'],
            invoiceNumber: invoice['invoiceNumber'],
            amount: invoice['amount'],
            daysText: invoice['daysText'],
            daysColor: invoice['daysColor'],
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

  // Build the Paid tab content
  Widget _buildPaidCards() {
    final filteredInvoices = _filteredPaidInvoices;

    if (filteredInvoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(
            'No matching invoices found',
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
      children: List.generate(filteredInvoices.length * 2 - 1, (index) {
        // Return card for even indices
        if (index.isEven) {
          final invoiceIndex = index ~/ 2;
          final invoice = filteredInvoices[invoiceIndex];

          return Paid.DueCard(
            companyName: invoice['companyName'],
            date: invoice['date'],
            invoiceNumber: invoice['invoiceNumber'],
            amount: invoice['amount'],
            daysText: invoice['daysText'],
            daysColor: invoice['daysColor'],
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
