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
import 'package:invoicegenerator/screens/invoices/invoice_create_screen.dart';
import 'package:invoicegenerator/utils/route_transitions.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/company_service.dart';
import 'package:invoicegenerator/widgets/invoice/invoice_preview.dart';
import 'package:intl/intl.dart';

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

  // Services
  final _invoiceService = InvoiceService();
  final _companyService = CompanyService();

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  // Load invoices from the service
  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    // Initialize services
    await _invoiceService.init();
    await _companyService.init();

    setState(() {
      _isLoading = false;
    });
  }

  // Filtered lists based on search query
  List<Invoice> get _filteredOverdueInvoices {
    final overdueInvoices = _invoiceService.getInvoicesByStatus(
      InvoiceStatus.overdue,
    );

    if (_searchQuery.isEmpty) {
      return overdueInvoices;
    }

    final query = _searchQuery.toLowerCase();
    return overdueInvoices.where((invoice) {
      return invoice.client.name.toLowerCase().contains(query) ||
          invoice.invoiceId.toLowerCase().contains(query);
    }).toList();
  }

  List<Invoice> get _filteredOutstandingInvoices {
    final outstandingInvoices = _invoiceService.getInvoicesByStatus(
      InvoiceStatus.outstanding,
    );

    if (_searchQuery.isEmpty) {
      return outstandingInvoices;
    }

    final query = _searchQuery.toLowerCase();
    return outstandingInvoices.where((invoice) {
      return invoice.client.name.toLowerCase().contains(query) ||
          invoice.invoiceId.toLowerCase().contains(query);
    }).toList();
  }

  List<Invoice> get _filteredPaidInvoices {
    final paidInvoices = _invoiceService.getInvoicesByStatus(
      InvoiceStatus.paid,
    );

    if (_searchQuery.isEmpty) {
      return paidInvoices;
    }

    final query = _searchQuery.toLowerCase();
    return paidInvoices.where((invoice) {
      return invoice.client.name.toLowerCase().contains(query) ||
          invoice.invoiceId.toLowerCase().contains(query);
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
    // Navigate to the InvoiceCreateScreen
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const InvoiceCreateScreen()),
        )
        .then((_) {
          // Refresh the list when returning from the create screen
          _loadInvoices();
        });
  }

  // Handle tapping on an invoice to view it
  void _handleInvoiceTapped(Invoice invoice) async {
    if (_companyService.companyInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company information not set')),
      );
      return;
    }

    // Navigate to the invoice preview
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => InvoicePreview(
              invoice: invoice,
              companyInfo: _companyService.companyInfo!,
            ),
      ),
    );
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
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
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
            'No overdue invoices found',
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
          final dateFormat = DateFormat('MM/dd/yyyy');

          // Calculate days overdue
          final now = DateTime.now();
          final difference = now.difference(invoice.dueDate).inDays;
          final daysText = '$difference days due';

          return GestureDetector(
            onTap: () => _handleInvoiceTapped(invoice),
            child: DueCard(
              companyName: invoice.client.name,
              date: dateFormat.format(invoice.dueDate),
              invoiceNumber: invoice.invoiceId,
              amount:
                  '${_getCurrencySymbol()}${invoice.total.toStringAsFixed(2)}',
              daysText: daysText,
              daysColor: const Color(0xFFD61443),
            ),
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
            'No outstanding invoices found',
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
          final dateFormat = DateFormat('MM/dd/yyyy');

          // Calculate days until due
          final now = DateTime.now();
          final difference = invoice.dueDate.difference(now).inDays;
          final daysText = 'DUE IN $difference DAYS';

          return GestureDetector(
            onTap: () => _handleInvoiceTapped(invoice),
            child: Outstanding.DueCard(
              companyName: invoice.client.name,
              date: dateFormat.format(invoice.dueDate),
              invoiceNumber: invoice.invoiceId,
              amount:
                  '${_getCurrencySymbol()}${invoice.total.toStringAsFixed(2)}',
              daysText: daysText,
              daysColor: const Color(0xFFD68814),
            ),
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
            'No paid invoices found',
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
          final dateFormat = DateFormat('MM/dd/yyyy');

          return GestureDetector(
            onTap: () => _handleInvoiceTapped(invoice),
            child: Paid.DueCard(
              companyName: invoice.client.name,
              date: dateFormat.format(invoice.issueDate),
              invoiceNumber: invoice.invoiceId,
              amount:
                  '${_getCurrencySymbol()}${invoice.total.toStringAsFixed(2)}',
              daysText: 'PAID',
              daysColor: const Color(0xFF13AF5B),
            ),
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

  // Helper to get currency symbol
  String _getCurrencySymbol() {
    return _companyService.companyInfo?.currency ?? 'USD';
  }
}
