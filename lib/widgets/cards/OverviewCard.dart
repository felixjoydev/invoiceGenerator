import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';
import 'package:invoicegenerator/widgets/cards/DueCard.dart';
import 'package:invoicegenerator/widgets/display/tabs.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/invoice_preview.dart';
import 'package:invoicegenerator/services/company_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';

// Import the other card types
import 'package:invoicegenerator/widgets/cards/OustandingCard.dart'
    as outstanding;
import 'package:invoicegenerator/widgets/cards/PaidCard.dart' as paid;

class OverviewCard extends StatefulWidget {
  const OverviewCard({super.key});

  @override
  State<OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<OverviewCard>
    with SingleTickerProviderStateMixin {
  int _activeTabIndex = 0;
  late AnimationController _animationController;

  // Add invoice service
  final InvoiceService _invoiceService = InvoiceService();

  // Add company service
  final CompanyService _companyService = CompanyService();

  // Totals
  double _overdueTotal = 0.0;
  double _outstandingTotal = 0.0;
  double _paidTotal = 0.0;

  // Lists for each tab
  List<Invoice> _overdueInvoices = [];
  List<Invoice> _outstandingInvoices = [];
  List<Invoice> _paidInvoices = [];

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    // Initialize the invoice service and load data
    _loadInvoiceData();

    // Listen for changes in invoice data
    _invoiceService.addListener(_handleInvoiceUpdates);
  }

  Future<void> _loadInvoiceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize both services
      await Future.wait([_invoiceService.init(), _companyService.init()]);

      // Update the data
      await _updateInvoiceData();
    } catch (e) {
      debugPrint('Error loading invoice data: $e');
      // Set loading to false even if there's an error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleInvoiceUpdates() {
    if (mounted) {
      _updateInvoiceData();
    }
  }

  Future<void> _updateInvoiceData() async {
    // Calculate totals
    await _calculateTotals();

    // Get filtered lists for each tab
    await _getFilteredLists();

    // Update UI
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateTotals() async {
    _overdueTotal = 0.0;
    _outstandingTotal = 0.0;
    _paidTotal = 0.0;

    final allInvoices = await _invoiceService.getAllInvoices();

    debugPrint('Found ${allInvoices.length} invoices');

    for (final invoice in allInvoices) {
      switch (invoice.status) {
        case InvoiceStatus.overdue:
          _overdueTotal += invoice.total;
          break;
        case InvoiceStatus.outstanding:
          _outstandingTotal += invoice.total;
          break;
        case InvoiceStatus.paid:
          _paidTotal += invoice.total;
          break;
      }
    }

    debugPrint(
      'Totals - Overdue: $_overdueTotal, Outstanding: $_outstandingTotal, Paid: $_paidTotal',
    );
  }

  Future<void> _getFilteredLists() async {
    // Get overdue invoices sorted by most days overdue
    final overdueInvoices = await _invoiceService.getInvoicesByStatus(
      InvoiceStatus.overdue,
    );
    _overdueInvoices = overdueInvoices;
    _overdueInvoices.sort((a, b) {
      final aDaysOverdue = DateTime.now().difference(a.dueDate).inDays;
      final bDaysOverdue = DateTime.now().difference(b.dueDate).inDays;
      return bDaysOverdue.compareTo(aDaysOverdue); // Highest days overdue first
    });

    // Take only top 3 if we have more
    if (_overdueInvoices.length > 3) {
      _overdueInvoices = _overdueInvoices.sublist(0, 3);
    }

    // Get outstanding invoices sorted by closest to due date
    final outstandingInvoices = await _invoiceService.getInvoicesByStatus(
      InvoiceStatus.outstanding,
    );
    _outstandingInvoices = outstandingInvoices;
    _outstandingInvoices.sort((a, b) {
      return a.dueDate.compareTo(b.dueDate); // Closest due date first
    });

    // Take only top 3 if we have more
    if (_outstandingInvoices.length > 3) {
      _outstandingInvoices = _outstandingInvoices.sublist(0, 3);
    }

    // Get paid invoices sorted by most recently paid
    final paidInvoices = await _invoiceService.getInvoicesByStatus(
      InvoiceStatus.paid,
    );
    _paidInvoices = paidInvoices;
    _paidInvoices.sort((a, b) {
      // Sort by paid date if available, otherwise use issue date
      final aDate = a.paidDate ?? a.issueDate;
      final bDate = b.paidDate ?? b.issueDate;
      return bDate.compareTo(aDate); // Most recent first
    });

    // Take only top 3 if we have more
    if (_paidInvoices.length > 3) {
      _paidInvoices = _paidInvoices.sublist(0, 3);
    }

    debugPrint(
      'Filtered lists - Overdue: ${_overdueInvoices.length}, Outstanding: ${_outstandingInvoices.length}, Paid: ${_paidInvoices.length}',
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _invoiceService.removeListener(_handleInvoiceUpdates);
    super.dispose();
  }

  void _handleTabChanged(int index) {
    setState(() {
      _activeTabIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _navigateToInvoiceList() {
    // Navigate to invoice list screen with the corresponding tab selected
    if (context.mounted) {
      InvoiceListScreen.navigateWithTab(
        context,
        tabIndex:
            _activeTabIndex +
            1, // +1 because InvoiceListScreen has "All" as index 0
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Invoices Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF36393A),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  // Overdue section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFFD61443),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                color: Color(0xFF8D9694),
                                fontSize: 10,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _isLoading
                                  ? '...'
                                  : _overdueTotal.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
                                fontFamily: 'Helvetica Now Display',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppTheme.ensureVictorMonoUppercase('Overdue'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Victor Mono',
                            color: Color(0xFF8D9694),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Outstanding section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFFD68814),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                color: Color(0xFF8D9694),
                                fontSize: 10,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _isLoading
                                  ? '...'
                                  : _outstandingTotal.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
                                fontFamily: 'Helvetica Now Display',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppTheme.ensureVictorMonoUppercase('Outstanding'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Victor Mono',
                            color: Color(0xFF8D9694),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Paid section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFF13AF5B),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                color: Color(0xFF8D9694),
                                fontSize: 10,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _isLoading
                                  ? '...'
                                  : _paidTotal.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
                                fontFamily: 'Helvetica Now Display',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppTheme.ensureVictorMonoUppercase('Paid'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Victor Mono',
                            color: Color(0xFF8D9694),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          // Tab and content section
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab bar
              CustomTabBar(
                tabs: ['Overdue', 'Outstanding', 'Paid'],
                initialTabIndex: _activeTabIndex,
                onTabChanged: _handleTabChanged,
              ),
              SizedBox(height: 16),
              // Invoice list with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _isLoading
                        ? _buildLoadingIndicator()
                        : _buildCardListForActiveTab(),
              ),
              SizedBox(height: 16),
              // Add divider before View All button
              CustomPaint(
                painter: DashedLinePainter(color: Color(0xFFCAD5D2)),
                size: Size(double.infinity, 1),
              ),
              SizedBox(height: 16),
              // View all button
              GestureDetector(
                onTap: _navigateToInvoiceList,
                child: Center(
                  child: Text(
                    AppTheme.ensureVictorMonoUppercase('View all invoices'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Victor Mono',
                      color: Color(0xFFF05022),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Bottom border
              Container(height: 4, color: Color(0xFFCAD5D2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF05022)),
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildCardListForActiveTab() {
    // Key needed for AnimatedSwitcher to recognize this as a different widget
    final key = ValueKey<int>(_activeTabIndex);

    switch (_activeTabIndex) {
      case 0: // Overdue
        if (_overdueInvoices.isEmpty) {
          return _buildEmptyState(key, 'No overdue invoices');
        }
        return _buildCardList(
          key: key,
          invoices: _overdueInvoices,
          cardBuilder: (invoice) {
            // Calculate days overdue
            final now = DateTime.now();
            final difference = now.difference(invoice.dueDate).inDays;
            final daysText = '$difference days due';

            return DueCard(
              companyName: invoice.client.name,
              date: DateFormat('MM/dd/yyyy').format(invoice.issueDate),
              invoiceNumber: invoice.invoiceId,
              amount: invoice.total.toStringAsFixed(2),
              daysText: daysText,
              daysColor: const Color(0xFFD61443),
              onTap: () => _handleInvoiceTapped(invoice),
            );
          },
        );
      case 1: // Outstanding
        if (_outstandingInvoices.isEmpty) {
          return _buildEmptyState(key, 'No outstanding invoices');
        }
        return _buildCardList(
          key: key,
          invoices: _outstandingInvoices,
          cardBuilder: (invoice) {
            // Calculate days until due
            final now = DateTime.now();
            final difference = invoice.dueDate.difference(now).inDays;
            final daysText = 'DUE IN $difference DAYS';

            return outstanding.DueCard(
              companyName: invoice.client.name,
              date: DateFormat('MM/dd/yyyy').format(invoice.issueDate),
              invoiceNumber: invoice.invoiceId,
              amount: invoice.total.toStringAsFixed(2),
              daysText: daysText,
              daysColor: const Color(0xFFD68814),
              onTap: () => _handleInvoiceTapped(invoice),
            );
          },
        );
      case 2: // Paid
        if (_paidInvoices.isEmpty) {
          return _buildEmptyState(key, 'No paid invoices');
        }
        return _buildCardList(
          key: key,
          invoices: _paidInvoices,
          cardBuilder: (invoice) {
            // Get formatted paid date or fallback to issue date
            final displayDate =
                invoice.paidDate != null
                    ? DateFormat('MM/dd/yyyy').format(invoice.paidDate!)
                    : DateFormat('MM/dd/yyyy').format(invoice.issueDate);
            final daysText = 'PAID ON $displayDate';

            return paid.DueCard(
              companyName: invoice.client.name,
              date: DateFormat('MM/dd/yyyy').format(invoice.issueDate),
              invoiceNumber: invoice.invoiceId,
              amount: invoice.total.toStringAsFixed(2),
              daysText: daysText,
              daysColor: const Color(0xFF13AF5B),
              onTap: () => _handleInvoiceTapped(invoice),
            );
          },
        );
      default:
        return Container(key: key);
    }
  }

  Widget _buildEmptyState(Key key, String message) {
    return Container(
      key: key,
      height: 100,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF8D9694),
          fontFamily: 'Helvetica Now Display',
        ),
      ),
    );
  }

  Widget _buildCardList({
    required Key key,
    required List<Invoice> invoices,
    required Widget Function(Invoice) cardBuilder,
  }) {
    return Column(
      key: key,
      children: [
        for (int i = 0; i < invoices.length; i++) ...[
          // Card
          cardBuilder(invoices[i]),
          // Dashed divider (for all items including the last one)
          if (i < invoices.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CustomPaint(
                painter: DashedLinePainter(color: Color(0xFFCAD5D2)),
                size: Size(double.infinity, 1),
              ),
            ),
        ],
      ],
    );
  }

  void _handleInvoiceTapped(Invoice invoice) {
    // Show invoice preview bottom sheet instead of navigating
    if (context.mounted) {
      // Get company info from service
      final companyInfo = _companyService.companyInfo;

      if (companyInfo == null) {
        // Show error if company info is not available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company information not set')),
        );
        return;
      }

      // Get logo path
      final logoPath = companyInfo.logoPath;

      // Log for debugging
      debugPrint('OverviewCard - Opening preview with logo path: $logoPath');
      if (logoPath != null) {
        final logoFile = File(logoPath);
        final exists = logoFile.existsSync();
        debugPrint(
          'OverviewCard - Logo file exists: $exists (path: $logoPath)',
        );
      }

      // Show the invoice preview bottom sheet
      showInvoicePreviewSheet(
        context: context,
        invoice: invoice,
        companyInfo: companyInfo,
        logoPath: logoPath,
        currentTabIndex:
            _activeTabIndex +
            1, // +1 because InvoiceListScreen has "All" as index 0
        isFromHomeScreen:
            true, // Set to true so user stays on home screen after actions
      );
    }
  }
}
