import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/cards/ClientCard.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/screens/catalog/catalog_list_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Search query
  String _searchQuery = '';

  // Sample client data
  final List<Map<String, dynamic>> _clients = [
    {
      'clientName': 'Acuro',
      'clientId': '001',
      'invoiceCount': 2,
      'currency': 'USD',
      'amount': 4500.00,
      'outstandingAmount': 1000.00,
      'hasOutstanding': true,
    },
    {
      'clientName': 'Thalamus',
      'clientId': '002',
      'invoiceCount': 3,
      'currency': 'USD',
      'amount': 6250.00,
      'outstandingAmount': 1500.00,
      'hasOutstanding': true,
    },
    {
      'clientName': 'Cortex',
      'clientId': '003',
      'invoiceCount': 1,
      'currency': 'USD',
      'amount': 3200.00,
      'outstandingAmount': 0.00,
      'hasOutstanding': false,
    },
    {
      'clientName': 'Medula',
      'clientId': '004',
      'invoiceCount': 5,
      'currency': 'USD',
      'amount': 8500.00,
      'outstandingAmount': 2200.00,
      'hasOutstanding': true,
    },
    {
      'clientName': 'Cerebrum',
      'clientId': '005',
      'invoiceCount': 2,
      'currency': 'USD',
      'amount': 3700.00,
      'outstandingAmount': 0.00,
      'hasOutstanding': false,
    },
    {
      'clientName': 'Neurox',
      'clientId': '006',
      'invoiceCount': 4,
      'currency': 'USD',
      'amount': 5500.00,
      'outstandingAmount': 1200.00,
      'hasOutstanding': true,
    },
    {
      'clientName': 'Synaptix',
      'clientId': '007',
      'invoiceCount': 2,
      'currency': 'USD',
      'amount': 3200.00,
      'outstandingAmount': 800.00,
      'hasOutstanding': true,
    },
    {
      'clientName': 'Axonify',
      'clientId': '008',
      'invoiceCount': 3,
      'currency': 'USD',
      'amount': 4800.00,
      'outstandingAmount': 0.00,
      'hasOutstanding': false,
    },
    {
      'clientName': 'BrainTech',
      'clientId': '009',
      'invoiceCount': 1,
      'currency': 'USD',
      'amount': 2500.00,
      'outstandingAmount': 0.00,
      'hasOutstanding': false,
    },
    {
      'clientName': 'Cognition',
      'clientId': '010',
      'invoiceCount': 2,
      'currency': 'USD',
      'amount': 3800.00,
      'outstandingAmount': 1100.00,
      'hasOutstanding': true,
    },
  ];

  // Filtered clients based on search query
  List<Map<String, dynamic>> get _filteredClients {
    if (_searchQuery.isEmpty) {
      return _clients;
    }

    final query = _searchQuery.toLowerCase();
    return _clients.where((client) {
      return client['clientName'].toLowerCase().contains(query) ||
          client['clientId'].toLowerCase().contains(query);
    }).toList();
  }

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == BottomNavItem.clients) return; // Already on clients screen

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
    } else if (item == BottomNavItem.catalog) {
      // Navigate to catalog list screen with replacement
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CatalogListScreen()),
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
            // Custom top navigation with clients icon on left, sort and add icons on right
            SafeArea(
              bottom: false,
              child: NavContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Clients icon and title
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/clients.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            const Color(0xFF373C3A),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8), // 8px spacing
                        const Text(
                          'Clients',
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
                hintText: 'Search clients',
                onChanged: _handleSearchInputChanged,
              ),
            ),

            // 24px spacing after Search Input
            const SizedBox(height: 24),

            // Main content area with client cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(child: _buildClientCards()),
              ),
            ),

            // Bottom navigation with clients selected
            BottomNav(
              activeItem: BottomNavItem.clients,
              onItemSelected: _handleNavItemSelected,
              onAddTapped: _handleAddTapped,
            ),
          ],
        ),
      ),
    );
  }

  // Build the client cards
  Widget _buildClientCards() {
    final filteredClients = _filteredClients;

    if (filteredClients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(
            'No matching clients found',
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
      children: List.generate(filteredClients.length * 2 - 1, (index) {
        // Return card for even indices
        if (index.isEven) {
          final clientIndex = index ~/ 2;
          final client = filteredClients[clientIndex];

          return ClientCard(
            clientName: client['clientName'],
            clientId: client['clientId'],
            invoiceCount: client['invoiceCount'],
            currency: client['currency'],
            amount: client['amount'],
            outstandingAmount: client['outstandingAmount'],
            hasOutstanding: client['hasOutstanding'],
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
