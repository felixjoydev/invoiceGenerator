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
import 'package:invoicegenerator/utils/route_transitions.dart';
import 'package:invoicegenerator/screens/clients/add_client_screen.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/client_service.dart';

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

  // Client service
  final _clientService = ClientService();

  // List of clients
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    // Load clients from the service
    _loadClients();

    // Listen for changes from the service
    _clientService.addListener(_onClientDataChanged);
  }

  // Load clients from the service
  Future<void> _loadClients() async {
    try {
      // Initialize the service if needed
      await _clientService.init();

      setState(() {
        _clients = _clientService.clients;
      });

      // If no clients, add a sample one
      if (_clients.isEmpty) {
        _addSampleClient();
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
      // Initialize with empty list if there's an error
      setState(() {
        _clients = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading clients: $e'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Clear Data',
            onPressed: () {
              _clientService.clearAllClients();
              _addSampleClient();
            },
          ),
        ),
      );
    }
  }

  // Add a sample client for first-time use
  Future<void> _addSampleClient() async {
    // Create a sample client - only name is required
    final client = Client(
      name: 'Acuro',
      clientId: 'CL001',
      type: 'organization',
      // Optional fields for a better sample
      addressLine1: '123 Main St',
      email: 'contact@acuro.com',
      invoiceCount: 2,
      currency: 'USD',
      amount: 4500.00,
      outstandingAmount: 1000.00,
      hasOutstanding: true,
    );

    // Add to service
    await _clientService.addClient(client);
  }

  // Callback when client data changes
  void _onClientDataChanged() {
    if (mounted) {
      setState(() {
        _clients = _clientService.clients;
      });
    }
  }

  // Filtered clients based on search query
  List<Client> get _filteredClients {
    if (_searchQuery.isEmpty) {
      return _clients;
    }

    final query = _searchQuery.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
          client.clientId.toLowerCase().contains(query);
    }).toList();
  }

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == BottomNavItem.clients) return; // Already on clients screen

    if (item == BottomNavItem.home) {
      // Navigate to home screen with replacement
      context.navigateWithSlide(const HomeScreen());
    } else if (item == BottomNavItem.invoice) {
      // Navigate to invoice list screen with replacement
      context.navigateWithSlide(const InvoiceListScreen());
    } else if (item == BottomNavItem.catalog) {
      // Navigate to catalog list screen with replacement
      context.navigateWithSlide(const CatalogListScreen());
    }
    // Other navigation options would be handled here
  }

  // Handle the add button press
  void _handleAddTapped() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddClientScreen()))
        .then((_) {
          // Refresh clients when returning from add screen
          _loadClients();
        });
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
    _clientService.removeListener(_onClientDataChanged);
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
                        GestureDetector(
                          onTap: _handleAddTapped,
                          child: SvgPicture.asset(
                            'assets/icons/add-black.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 32px spacing after TopNav
            const SizedBox(height: 8),

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
              child: ContentSlideTransition(
                // Direction determination happens in the route
                slideFromRight:
                    ModalRoute.of(context)?.settings.arguments is HomeScreen ||
                    ModalRoute.of(context)?.settings.arguments
                        is InvoiceListScreen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(child: _buildClientCards()),
                ),
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
            'No clients found. Add your first client!',
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
            clientName: client.name,
            clientId: client.clientId,
            invoiceCount: client.invoiceCount,
            currency: client.currency,
            amount: client.amount,
            outstandingAmount: client.outstandingAmount,
            hasOutstanding: client.hasOutstanding,
            dueAmount: client.dueAmount,
            hasDue: client.hasDue,
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
