import 'package:flutter/foundation.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:invoicegenerator/services/client_service.dart';

class RevenueService with ChangeNotifier {
  // Singleton pattern
  static final RevenueService _instance = RevenueService._internal();
  factory RevenueService() => _instance;
  RevenueService._internal();

  // Store selected month & year
  DateTime _selectedMonth = DateTime.now();

  // Cached revenue data
  Map<String, double> _monthlyRevenue = {};

  // Debug flag
  final bool _verbose = true;

  // Getters
  DateTime get selectedMonth => _selectedMonth;

  // Initialize and fetch data
  Future<void> init() async {
    // Wait for invoice service to load data first
    final invoiceService = InvoiceService();
    await invoiceService.init();

    // Now calculate revenues
    calculateAllMonthlyRevenues();

    // Listen for changes in the invoice service
    invoiceService.addListener(_handleInvoiceServiceChanged);

    if (_verbose) {
      _logRevenueData();
    }
  }

  // Log revenue data for debugging
  void _logRevenueData() {
    final invoiceService = InvoiceService();
    final invoices = invoiceService.invoices;

    debugPrint('================== REVENUE DEBUG ==================');
    debugPrint('Total invoices loaded: ${invoices.length}');
    for (var invoice in invoices) {
      debugPrint(
        'Invoice ${invoice.invoiceId}: ${invoice.total} on ${_formatDate(invoice.issueDate)}',
      );
    }

    debugPrint('Monthly revenue data:');
    _monthlyRevenue.forEach((month, amount) {
      debugPrint('$month: \$${amount.toStringAsFixed(2)}');
    });

    debugPrint('Selected month: ${_formatDate(_selectedMonth)}');
    debugPrint('Selected month revenue: ${getSelectedMonthRevenue()}');
    debugPrint('=================================================');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Cleanup resources
  @override
  void dispose() {
    InvoiceService().removeListener(_handleInvoiceServiceChanged);
    super.dispose();
  }

  // Handle invoice service changes
  void _handleInvoiceServiceChanged() {
    calculateAllMonthlyRevenues();
  }

  // Get monthly revenue for the selected month
  double getSelectedMonthRevenue() {
    final key = _getMonthKey(_selectedMonth);
    return _monthlyRevenue[key] ?? 0.0;
  }

  // Set selected month and notify listeners
  void setSelectedMonth(DateTime newMonth) {
    _selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
    notifyListeners();

    if (_verbose) {
      debugPrint('Selected month set to: ${_formatDate(_selectedMonth)}');
      debugPrint('Revenue for this month: ${getSelectedMonthRevenue()}');
    }
  }

  // Get percentage change from previous month
  double getPercentChangeFromPreviousMonth() {
    final currentKey = _getMonthKey(_selectedMonth);
    final currentRevenue = _monthlyRevenue[currentKey] ?? 0.0;

    // Get previous month with year rollover
    final DateTime previousMonth;
    if (_selectedMonth.month == 1) {
      // If January, previous month is December of previous year
      previousMonth = DateTime(_selectedMonth.year - 1, 12, 1);
    } else {
      previousMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    }

    final previousKey = _getMonthKey(previousMonth);
    final previousRevenue = _monthlyRevenue[previousKey] ?? 0.0;

    // Calculate percentage change
    if (previousRevenue == 0) return 0.0;
    return ((currentRevenue - previousRevenue) / previousRevenue) * 100;
  }

  // Is revenue up compared to previous month?
  bool isRevenueUp() {
    return getPercentChangeFromPreviousMonth() >= 0;
  }

  // Get all month revenue data
  Map<String, double> getAllMonthlyRevenue() {
    return Map.from(_monthlyRevenue);
  }

  // Calculate all monthly revenues based on invoices
  void calculateAllMonthlyRevenues() {
    try {
      // Get all invoices
      final invoiceService = InvoiceService();
      final allInvoices = invoiceService.getAllInvoices();

      if (_verbose) {
        debugPrint('Calculating revenue with ${allInvoices.length} invoices');
      }

      // Clear current data
      _monthlyRevenue = {};

      // Process each invoice
      for (var invoice in allInvoices) {
        // Get month key from issue date
        final monthKey = _getMonthKey(invoice.issueDate);

        // Add to monthly total - ensure we're using double
        final total = invoice.total.toDouble();
        _monthlyRevenue[monthKey] = (_monthlyRevenue[monthKey] ?? 0.0) + total;

        if (_verbose) {
          debugPrint(
            'Added invoice ${invoice.invoiceId} with total $total to month $monthKey',
          );
        }
      }

      if (_verbose) {
        _logRevenueData();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating monthly revenues: $e');
    }
  }

  // Get formatted month key (YYYY-MM)
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Get revenue data for chart display
  List<MonthRevenueData> getChartData() {
    final currentYear = DateTime.now().year;
    List<MonthRevenueData> chartData = [];

    // First find max revenue for proper scaling
    double maxRevenue = 0.0;
    for (int month = 1; month <= 12; month++) {
      final monthDate = DateTime(currentYear, month, 1);
      final key = _getMonthKey(monthDate);
      final revenue = _monthlyRevenue[key] ?? 0.0;
      if (revenue > maxRevenue) {
        maxRevenue = revenue;
      }
    }

    // Use a safe maximum value
    maxRevenue = maxRevenue > 0 ? maxRevenue : 10000.0;

    // Maximum height a bar can have (constrained by parent container)
    const double maxBarHeight = 90.0; // Keep under 100px to avoid overflow
    // Minimum height for visibility of non-zero revenue
    const double minBarHeight = 20.0;
    // Height for zero revenue months (only for past and current months)
    const double zeroRevenueHeight = 2.0;

    // For future months with no data, use these varying heights for visual appeal
    const List<double> futureMonthHeights = [
      60.0,
      45.0,
      70.0,
      40.0,
      65.0,
      50.0,
    ];

    // Add data for all 12 months of current year
    for (int month = 1; month <= 12; month++) {
      final monthDate = DateTime(currentYear, month, 1);
      final key = _getMonthKey(monthDate);
      final revenue = _monthlyRevenue[key] ?? 0.0;

      // Determine if month is in future
      final isFutureMonth = monthDate.isAfter(
        DateTime(DateTime.now().year, DateTime.now().month, 1),
      );

      // Normalize height for chart with safer limits
      double height;

      if (isFutureMonth) {
        // Future months get aesthetic varying heights when no data
        if (revenue > 0) {
          // If we have actual revenue data for future (unlikely), use it
          if (revenue == maxRevenue) {
            height = maxBarHeight;
          } else {
            height =
                minBarHeight +
                ((revenue / maxRevenue) * (maxBarHeight - minBarHeight));
          }
        } else {
          // For future months with no data, use varying decorative heights
          final futureMonthIndex = monthDate.month - DateTime.now().month - 1;
          final heightIndex = futureMonthIndex % futureMonthHeights.length;
          height = futureMonthHeights[heightIndex];
        }
      } else {
        // For past and current months, use actual data scaling
        if (revenue > 0) {
          if (revenue == maxRevenue) {
            // Highest revenue month gets maximum height
            height = maxBarHeight;
          } else {
            // Other months get proportional heights
            height =
                minBarHeight +
                ((revenue / maxRevenue) * (maxBarHeight - minBarHeight));
          }
        } else {
          height = zeroRevenueHeight; // Minimal height for zero revenue
        }
      }

      final isCurrentMonth =
          monthDate.month == _selectedMonth.month &&
          monthDate.year == _selectedMonth.year;

      chartData.add(
        MonthRevenueData(
          month: monthDate,
          revenue: revenue,
          height: height,
          isSelected: isCurrentMonth,
          isFutureMonth: isFutureMonth,
        ),
      );
    }

    return chartData;
  }

  // Get formatted month name
  String getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month - 1];
  }

  // Test function to create a sample invoice and verify calculation
  Future<void> testRevenueCalculation() async {
    try {
      final invoiceService = InvoiceService();

      // Log current revenue data
      debugPrint(
        'BEFORE TEST - Monthly revenue for current month: ${getSelectedMonthRevenue()}',
      );

      // Create a test invoice for the current month
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 15);

      // Get a sample client
      final clientService = ClientService();
      await clientService.init();

      final clients = clientService.clients;

      if (clients.isEmpty) {
        debugPrint('No clients available to create test invoice');
        return;
      }

      // Add a sample invoice with proper model fields
      // Note: Create this based on the model fields in lib/models/invoice.dart
      final newInvoice = Invoice(
        invoiceId: 'test-${DateTime.now().millisecondsSinceEpoch}',
        client: clients.first,
        issueDate: thisMonth,
        dueDate: thisMonth.add(const Duration(days: 30)),
        items: [],
        subtotal: 1000.0,
        taxRate: 0.0,
        taxAmount: 0.0,
        total: 1000.0,
        status: InvoiceStatus.outstanding,
        templateName: 'Orange',
      );

      // Add the invoice to service
      final success = await invoiceService.addInvoice(newInvoice);

      if (success) {
        debugPrint('✅ Test invoice created successfully');
      } else {
        debugPrint('❌ Failed to create test invoice');
      }

      // Force recalculation
      calculateAllMonthlyRevenues();

      // Log updated revenue
      debugPrint(
        'AFTER TEST - Monthly revenue for current month: ${getSelectedMonthRevenue()}',
      );

      // Show all invoices in the system
      final allInvoices = invoiceService.getAllInvoices();
      debugPrint('Current number of invoices in system: ${allInvoices.length}');

      for (var invoice in allInvoices) {
        final date = _formatDate(invoice.issueDate);
        debugPrint('Invoice ${invoice.invoiceId}: ${invoice.total} on $date');
      }
    } catch (e) {
      debugPrint('ERROR creating test invoice: $e');
    }
  }

  // Debug method to fix any issues with existing invoices
  Future<void> verifyAndFixInvoiceData() async {
    try {
      final invoiceService = InvoiceService();
      final allInvoices = invoiceService.getAllInvoices();

      debugPrint('Verifying ${allInvoices.length} invoices');

      bool anyFixed = false;

      // Check and fix each invoice
      for (var invoice in allInvoices) {
        // Check if total is NaN or infinity
        if (invoice.total.isNaN || invoice.total.isInfinite) {
          debugPrint('Found invalid total in invoice ${invoice.invoiceId}');

          // Find actual total from items
          double fixedTotal = 0.0;
          for (var item in invoice.items) {
            double itemTotal = item.quantity * double.tryParse(item.amount)!;
            fixedTotal += itemTotal;
          }

          // Update the invoice
          final updatedInvoice = invoice.copyWith(
            total: fixedTotal,
            subtotal: fixedTotal,
            taxAmount: 0.0,
          );

          // Save the updated invoice
          await invoiceService.updateInvoice(updatedInvoice);
          anyFixed = true;

          debugPrint('Fixed invoice ${invoice.invoiceId} total to $fixedTotal');
        }
      }

      if (anyFixed) {
        // Recalculate revenue with fixed data
        calculateAllMonthlyRevenues();
        debugPrint('Recalculated revenue after fixing invoices');
      } else {
        debugPrint('No invoice issues found');
      }
    } catch (e) {
      debugPrint('Error verifying invoice data: $e');
    }
  }
}

// Data class for chart display
class MonthRevenueData {
  final DateTime month;
  final double revenue;
  final double height;
  final bool isSelected;
  final bool isFutureMonth;

  MonthRevenueData({
    required this.month,
    required this.revenue,
    required this.height,
    required this.isSelected,
    required this.isFutureMonth,
  });
}
