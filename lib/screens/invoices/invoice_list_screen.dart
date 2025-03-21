import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/display/tabs.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/cards/DueCard.dart';
import 'package:invoicegenerator/widgets/cards/AnimatedInvoiceCard.dart';
import 'package:invoicegenerator/widgets/cards/AnimatedOutstandingCard.dart';
import 'package:invoicegenerator/widgets/cards/AnimatedPaidCard.dart';
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
import 'package:invoicegenerator/bottom_sheets/invoices/invoice_preview.dart';
import 'package:invoicegenerator/widgets/display/BlurredBackground.dart';
import 'package:invoicegenerator/widgets/display/PressWidget.dart';
import 'package:invoicegenerator/widgets/cards/HighlightedInvoiceCard.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class InvoiceListScreen extends StatefulWidget {
  final String? invoiceIdToAnimate;
  final int initialTabIndex;

  // Store scroll positions by tab index
  static final Map<int, double> _scrollPositions = {
    0: 0.0, // All tab
    1: 0.0, // Overdue tab
    2: 0.0, // Outstanding tab
    3: 0.0, // Paid tab
  };

  const InvoiceListScreen({
    super.key,
    this.invoiceIdToAnimate,
    this.initialTabIndex = 0,
  });

  // Static method to navigate with correct tab index and animation
  static void navigateWithTab(
    BuildContext context, {
    required int tabIndex,
    String? invoiceIdToAnimate,
    bool saveCurrentPosition = false,
  }) {
    // Always try to get the current state to save position
    final currentState =
        context.findAncestorStateOfType<_InvoiceListScreenState>();

    // If saveCurrentPosition is true, save the current tab's position
    if (saveCurrentPosition &&
        currentState != null &&
        currentState._scrollController.hasClients) {
      int currentTabIndex = currentState._selectedTabIndex;
      saveScrollPosition(
        currentTabIndex,
        currentState._scrollController.offset,
      );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => InvoiceListScreen(
              invoiceIdToAnimate: invoiceIdToAnimate,
              initialTabIndex: tabIndex,
            ),
      ),
    );
  }

  // Static method to save a specific tab's scroll position
  static void saveScrollPosition(int tabIndex, double position) {
    _scrollPositions[tabIndex] = position;
    debugPrint('Saved scroll position for tab $tabIndex: $position');
  }

  // Static method to save the current tab's scroll position
  static void saveScrollPositionForCurrentTab(
    BuildContext context,
    int tabIndex,
  ) {
    final currentState =
        context.findAncestorStateOfType<_InvoiceListScreenState>();
    if (currentState != null && currentState._scrollController.hasClients) {
      saveScrollPosition(tabIndex, currentState._scrollController.offset);
      debugPrint(
        'Explicitly saved scroll position for tab $tabIndex: ${currentState._scrollController.offset}',
      );
    } else {
      debugPrint(
        'Could not find current state to save scroll position for tab $tabIndex',
      );
    }
  }

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  // Selected tab index
  int _selectedTabIndex = 0;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Page storage bucket to preserve scroll positions
  final PageStorageBucket _bucket = PageStorageBucket();

  // Fixed scroll controller for each tab
  final ScrollController _scrollController = ScrollController();

  // Search query
  String _searchQuery = '';

  // Services
  final _invoiceService = InvoiceService();
  final _companyService = CompanyService();

  // Loading state
  bool _isLoading = true;

  // Track newly added invoices that should be animated
  final Set<String> _newlyAddedInvoiceIds = {};

  // Currently selected invoice (for long press)
  Invoice? _selectedInvoice;

  // Selected card position
  GlobalKey _lastSelectedKey = GlobalKey();
  Offset _selectedItemPosition = Offset.zero;
  Size _selectedItemSize = Size.zero;
  bool _showPressWidgetAbove = false;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    // Set the selected tab index from widget property
    _selectedTabIndex = widget.initialTabIndex;
    // Add listener to refresh when invoices change
    _invoiceService.addListener(_handleInvoiceUpdates);

    // If an invoice ID was provided to animate, add it to the set
    if (widget.invoiceIdToAnimate != null) {
      _newlyAddedInvoiceIds.add(widget.invoiceIdToAnimate!);
      debugPrint('Will animate invoice: ${widget.invoiceIdToAnimate}');
    }

    // Restore scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure controller is properly attached
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          final position =
              InvoiceListScreen._scrollPositions[_selectedTabIndex] ?? 0.0;
          if (position == 0.0) {
            debugPrint(
              'Tab $_selectedTabIndex has no saved position, starting at 0.0',
            );
          } else {
            debugPrint(
              'Restoring tab $_selectedTabIndex to saved position: $position',
            );
          }
          _scrollController.jumpTo(position);
        }
      });
    });

    // Add listener to save scroll position when scrolling
    _scrollController.addListener(_saveScrollPosition);
  }

  @override
  void didUpdateWidget(InvoiceListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the tab index changed, save and restore scroll positions
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      // Save current scroll position for the old tab
      _saveScrollPosition();

      setState(() {
        _selectedTabIndex = widget.initialTabIndex;
      });

      // Restore scroll position for the new tab after UI updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a small delay to ensure controller is properly attached
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            final position =
                InvoiceListScreen._scrollPositions[_selectedTabIndex] ?? 0.0;
            _scrollController.jumpTo(position);
            debugPrint(
              'Restored scroll position for tab $_selectedTabIndex: $position',
            );
          }
        });
      });
    }

    // If a new invoice ID was provided to animate
    if (widget.invoiceIdToAnimate != null &&
        widget.invoiceIdToAnimate != oldWidget.invoiceIdToAnimate) {
      debugPrint(
        'Invoice ID to animate changed to: ${widget.invoiceIdToAnimate}',
      );

      // Add to the set of newly added invoice IDs
      setState(() {
        _newlyAddedInvoiceIds.add(widget.invoiceIdToAnimate!);
      });
    }
  }

  // Handle invoice service updates
  void _handleInvoiceUpdates() {
    if (mounted) {
      setState(() {
        // Just trigger a rebuild - invoices are obtained from service
      });
    }
  }

  // Load invoices from the service
  Future<void> _loadInvoices() async {
    // Set loading state but don't block UI
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Try to load data with error handling
      try {
        // Initialize invoice service with timeout
        await _invoiceService.init().timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            debugPrint('Invoice service init timed out, continuing anyway');
          },
        );
      } catch (e) {
        debugPrint('Error initializing invoice service: $e');
        // Continue anyway - service might have partial data
      }

      // Initialize company service separately with error handling
      try {
        await _companyService.init().timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            debugPrint('Company service init timed out, continuing anyway');
          },
        );
      } catch (e) {
        debugPrint('Error initializing company service: $e');
        // Continue anyway - service might have partial data
      }
    } catch (e) {
      debugPrint('Unexpected error in invoice loading: $e');
    } finally {
      // Always set loading to false, even if services have errors
      if (mounted) {
        setState(() {
          _isLoading = false;
          // No need to update any state for invoices as they're obtained directly from the service
        });
      }
    }
  }

  // Filtered lists based on search query
  List<Invoice> get _filteredAllInvoices {
    try {
      // Get all invoices from the service
      final allInvoices = _invoiceService.getAllInvoices();

      // Sort by issueDate (most recent first)
      // This ensures newly created invoices appear at the top of the "All" tab
      allInvoices.sort((a, b) {
        // Compare by issue date (newest first)
        final dateComparison = b.issueDate.compareTo(a.issueDate);
        // If same date, compare by invoice ID (newest ID format typically sorts higher)
        return dateComparison != 0
            ? dateComparison
            : b.invoiceId.compareTo(a.invoiceId);
      });

      if (_searchQuery.isEmpty) {
        return allInvoices;
      }

      final query = _searchQuery.toLowerCase();
      return allInvoices.where((invoice) {
        return invoice.client.name.toLowerCase().contains(query) ||
            invoice.invoiceId.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      debugPrint('Error loading all invoices: $e');
      return [];
    }
  }

  List<Invoice> get _filteredOverdueInvoices {
    try {
      final overdueInvoices = _invoiceService.getInvoicesByStatus(
        InvoiceStatus.overdue,
      );

      // Sort by due date (most overdue first)
      overdueInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      if (_searchQuery.isEmpty) {
        return overdueInvoices;
      }

      final query = _searchQuery.toLowerCase();
      return overdueInvoices.where((invoice) {
        return invoice.client.name.toLowerCase().contains(query) ||
            invoice.invoiceId.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      debugPrint('Error loading overdue invoices: $e');
      return [];
    }
  }

  List<Invoice> get _filteredOutstandingInvoices {
    try {
      final outstandingInvoices = _invoiceService.getInvoicesByStatus(
        InvoiceStatus.outstanding,
      );

      // Sort by due date (closest due date first)
      outstandingInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      if (_searchQuery.isEmpty) {
        return outstandingInvoices;
      }

      final query = _searchQuery.toLowerCase();
      return outstandingInvoices.where((invoice) {
        return invoice.client.name.toLowerCase().contains(query) ||
            invoice.invoiceId.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      debugPrint('Error loading outstanding invoices: $e');
      return [];
    }
  }

  List<Invoice> get _filteredPaidInvoices {
    try {
      final paidInvoices = _invoiceService.getInvoicesByStatus(
        InvoiceStatus.paid,
      );

      // Sort by paid date (newest first), fallback to issue date if paidDate is null
      paidInvoices.sort((a, b) {
        // If both have paid dates, compare them
        if (a.paidDate != null && b.paidDate != null) {
          return b.paidDate!.compareTo(a.paidDate!);
        }
        // If only one has paid date, it comes first
        else if (a.paidDate != null) {
          return -1;
        } else if (b.paidDate != null) {
          return 1;
        }
        // If neither has paid date, sort by issue date
        return b.issueDate.compareTo(a.issueDate);
      });

      if (_searchQuery.isEmpty) {
        return paidInvoices;
      }

      final query = _searchQuery.toLowerCase();
      return paidInvoices.where((invoice) {
        return invoice.client.name.toLowerCase().contains(query) ||
            invoice.invoiceId.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      debugPrint('Error loading paid invoices: $e');
      return [];
    }
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
    // Get current invoice IDs to compare after returning
    final Set<String> currentInvoiceIds = Set<String>.from(
      _invoiceService.getAllInvoices().map((i) => i.invoiceId),
    );

    // Navigate to the InvoiceCreateScreen
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const InvoiceCreateScreen()),
        )
        .then((_) {
          // Get updated invoices
          final updatedInvoices = _invoiceService.getAllInvoices();

          // Check if new invoices were added
          if (updatedInvoices.length > currentInvoiceIds.length) {
            // Find newly added invoice IDs
            for (final invoice in updatedInvoices) {
              if (!currentInvoiceIds.contains(invoice.invoiceId)) {
                setState(() {
                  _newlyAddedInvoiceIds.add(invoice.invoiceId);
                });
                debugPrint(
                  'New invoice to animate: ${invoice.invoiceId} (${invoice.client.name})',
                );
              }
            }
          }

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

    // Get company info and logo path
    final companyInfo = _companyService.companyInfo!;
    final logoPath = companyInfo.logoPath;

    debugPrint('InvoiceListScreen - Opening preview with logo path: $logoPath');
    if (logoPath != null) {
      final logoFile = File(logoPath);
      final exists = logoFile.existsSync();
      debugPrint(
        'InvoiceListScreen - Logo file exists: $exists (path: $logoPath)',
      );
    }

    // Show the invoice preview bottom sheet instead of navigating to full screen
    showInvoicePreviewSheet(
      context: context,
      invoice: invoice,
      companyInfo: companyInfo,
      logoPath: logoPath,
      currentTabIndex: _selectedTabIndex,
    );
  }

  // Handle search input changes
  void _handleSearchInputChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  // Handle when animation completes for an invoice card
  void _handleAnimationComplete(String invoiceId) {
    setState(() {
      _newlyAddedInvoiceIds.remove(invoiceId);
    });
  }

  // Mark an invoice for animation (can be called from outside)
  void markInvoiceForAnimation(String invoiceId) {
    if (mounted) {
      setState(() {
        _newlyAddedInvoiceIds.add(invoiceId);
      });
      debugPrint('Marked invoice for animation: $invoiceId');
    }
  }

  // Handle when long press on invoice card
  void _handleLongPress(Invoice invoice, GlobalKey itemKey) {
    _lastSelectedKey = itemKey;

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Get the position immediately, if possible
    final RenderBox? renderBox =
        itemKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      _selectedItemPosition = renderBox.localToGlobal(Offset.zero);
      _selectedItemSize = renderBox.size;

      // Calculate press widget position
      final screenHeight = MediaQuery.of(context).size.height;
      final bottomNavHeight = 80.0;
      // Dynamically determine the PressWidget height based on invoice status
      final pressWidgetHeight =
          invoice.status == InvoiceStatus.paid ? 56.0 : 168.0;

      // Calculate space available below the card
      final bottomSpace =
          screenHeight -
          _selectedItemPosition.dy -
          _selectedItemSize.height -
          bottomNavHeight;

      // Show above if not enough space below (add 8px spacing)
      _showPressWidgetAbove = bottomSpace < (pressWidgetHeight + 8.0);

      // Additional check - ensure the highlighted card is fully visible when PressWidget is above
      if (_showPressWidgetAbove) {
        // Make sure there's enough space above for PressWidget
        if (_selectedItemPosition.dy < pressWidgetHeight) {
          // Not enough space above, force show below and handle scrolling if needed
          _showPressWidgetAbove = false;
        }
      }
    }

    setState(() {
      _selectedInvoice = invoice;
    });

    // Also set up a post-frame callback to refine the position if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedItemPosition();
    });
  }

  // Calculate the position and size of the selected item
  void _updateSelectedItemPosition() {
    final RenderBox? renderBox =
        _lastSelectedKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      _selectedItemPosition = renderBox.localToGlobal(Offset.zero);
      _selectedItemSize = renderBox.size;

      // Check if showing the PressWidget below would overflow the screen
      final screenHeight = MediaQuery.of(context).size.height;
      final bottomNavHeight = 80.0; // Approximate height of bottom navigation
      final pressWidgetHeight =
          _selectedInvoice?.status == InvoiceStatus.paid ? 56.0 : 168.0;

      // Calculate space available below the card
      final bottomSpace =
          screenHeight -
          _selectedItemPosition.dy -
          _selectedItemSize.height -
          bottomNavHeight;

      // Show above if not enough space below (add 8px spacing)
      _showPressWidgetAbove = bottomSpace < (pressWidgetHeight + 8.0);

      // Additional check - ensure the highlighted card is fully visible when PressWidget is above
      if (_showPressWidgetAbove) {
        // Make sure there's enough space above for PressWidget
        if (_selectedItemPosition.dy < pressWidgetHeight) {
          // Not enough space above, force show below and handle scrolling if needed
          _showPressWidgetAbove = false;
        }
      }

      // Ensure we trigger a rebuild with the new position
      setState(() {});
    }
  }

  // Handle when the background is tapped to dismiss the selection
  void _handleBackgroundTap() {
    setState(() {
      _selectedInvoice = null;
    });
  }

  // Handle when edit is tapped
  void _handleEditTapped() {
    if (_selectedInvoice == null) return;

    // Store a reference to the selected invoice
    final invoiceToEdit = _selectedInvoice;

    // Clear the selection
    setState(() {
      _selectedInvoice = null;
    });

    // Navigate to edit invoice screen or show edit bottom sheet
    // This part would depend on your app's flow for editing invoices
    _handleInvoiceTapped(invoiceToEdit!);
  }

  // Handle when mark as paid is tapped
  void _handleMarkAsPaidTapped() {
    if (_selectedInvoice == null) return;

    // Only update if invoice is not already paid
    if (_selectedInvoice!.status != InvoiceStatus.paid) {
      // Create updated invoice with paid status
      final updatedInvoice = _selectedInvoice!.copyWith(
        status: InvoiceStatus.paid,
        paidDate: DateTime.now(), // Set paid date to current date
      );

      // Update the invoice
      _invoiceService.updateInvoice(updatedInvoice);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice ${_selectedInvoice!.invoiceId} marked as paid',
          ),
          backgroundColor: const Color(0xFF13AF5B),
        ),
      );
    }

    // Clear the selection
    setState(() {
      _selectedInvoice = null;
    });
  }

  // Handle when delete is tapped
  void _handleDeleteTapped() {
    if (_selectedInvoice == null) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder:
          (context) => Dialog(
            backgroundColor: const Color(
              0xFFDAE4E1,
            ), // Background color from theme
            insetPadding: const EdgeInsets.all(20),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // No rounded corners
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with MainHeading style
                  const Text(
                    'Delete Invoice',
                    style: TextStyle(
                      color: Color(0xFF373C3A),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Helvetica Now Display',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: const Color(0xFFCAD5D2),
                  ),
                  const SizedBox(height: 24),

                  // Content text
                  const Text(
                    'Are you sure you want to delete this invoice?',
                    style: TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF373C3A),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions row
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end, // Align to the end
                    children: [
                      // Cancel button - text only
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Color(0xFF373C3A),
                              fontSize: 14,
                              fontFamily: 'Victor Mono',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Add fixed spacing between buttons
                      const SizedBox(width: 24),

                      // Delete button - secondary button style with icon
                      InkWell(
                        onTap: () {
                          // Delete the invoice
                          _invoiceService.deleteInvoice(
                            _selectedInvoice!.invoiceId,
                          );

                          // Clear the selection
                          setState(() {
                            _selectedInvoice = null;
                          });

                          // Close the dialog
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/delete.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFD61443),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'DELETE',
                              style: TextStyle(
                                color: Color(0xFFD61443),
                                fontSize: 14,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Save current scroll position
  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      InvoiceListScreen._scrollPositions[_selectedTabIndex] =
          _scrollController.offset;
      debugPrint(
        'Saved scroll position for tab $_selectedTabIndex: ${_scrollController.offset}',
      );
    }
  }

  @override
  void dispose() {
    // Save final scroll position
    _saveScrollPosition();

    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.dispose();
    _searchController.dispose();
    // Remove listener when widget is disposed
    _invoiceService.removeListener(_handleInvoiceUpdates);
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
        body: PageStorage(
          bucket: _bucket,
          child: Stack(
            key: ValueKey('invoice-list-stack-${_selectedTabIndex}'),
            children: [
              Column(
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
                      tabs: const ['All', 'Overdue', 'Outstanding', 'Paid'],
                      initialTabIndex: _selectedTabIndex,
                      onTabChanged: (index) {
                        // Save current scroll position
                        _saveScrollPosition();

                        setState(() {
                          _selectedTabIndex = index;
                        });

                        // Restore scroll position for the new tab after UI updates
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Add a small delay to ensure controller is properly attached
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (_scrollController.hasClients) {
                              final position =
                                  InvoiceListScreen
                                      ._scrollPositions[_selectedTabIndex] ??
                                  0.0;
                              _scrollController.jumpTo(position);
                              debugPrint(
                                'Restored scroll position for tab $_selectedTabIndex: $position',
                              );
                            }
                          });
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
                      key: ValueKey('content-slide-${_selectedTabIndex}'),
                      // Direction determination happens in the route
                      slideFromRight:
                          ModalRoute.of(context)?.settings.arguments
                              is HomeScreen,
                      // Disable slide animation if we have newly added items to animate
                      disableAnimation: _newlyAddedInvoiceIds.isNotEmpty,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child:
                            _isLoading
                                ? _buildLoadingContent()
                                : SingleChildScrollView(
                                  // Use scroll controller to maintain position
                                  controller: _scrollController,
                                  // Skip page storage approach since we're handling scroll manually
                                  child:
                                      _selectedTabIndex == 0
                                          ? _buildAllCards()
                                          : _selectedTabIndex == 1
                                          ? _buildOverdueCards()
                                          : _selectedTabIndex == 2
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

              // Overlay for long press with fade-in animation
              if (_selectedInvoice != null)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: BlurredBackground(onTap: _handleBackgroundTap),
                ),

              // Selected item and press widget with absolute positioning
              if (_selectedInvoice != null)
                Stack(
                  children: [
                    // Highlighted invoice card - positioned at original location
                    Positioned(
                      left: _selectedItemPosition.dx,
                      top: _selectedItemPosition.dy,
                      width: _selectedItemSize.width,
                      child: Material(
                        color: Colors.transparent,
                        child: HighlightedInvoiceCard(
                          invoice: _selectedInvoice!,
                        ),
                      ),
                    ),

                    // PressWidget - positioned either above or below the card
                    Positioned(
                      left: _selectedItemPosition.dx,
                      top:
                          _showPressWidgetAbove
                              ? _selectedItemPosition.dy -
                                  (_selectedInvoice?.status ==
                                          InvoiceStatus.paid
                                      ? 56.0 // Only DELETE option for paid invoices
                                      : 168.0) // All options for non-paid invoices
                              : _selectedItemPosition.dy +
                                  _selectedItemSize.height +
                                  8.0, // Below the card with 8px spacing
                      width: _selectedItemSize.width,
                      child: Material(
                        color: Colors.transparent,
                        child: PressWidget(
                          onEdit: _handleEditTapped,
                          onDelete: _handleDeleteTapped,
                          onMarkAsPaid: _handleMarkAsPaidTapped,
                          // Only show for non-paid invoices
                          showMarkAsPaid:
                              _selectedInvoice?.status != InvoiceStatus.paid,
                          // Don't show Edit for paid invoices
                          showEdit:
                              _selectedInvoice?.status != InvoiceStatus.paid,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build loading content that doesn't block the UI
  Widget _buildLoadingContent() {
    return Stack(
      children: [
        // Show empty state content when loading
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Padding(
                padding: EdgeInsets.only(top: 100.0),
                child: Text(
                  'Loading invoices...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8D9694),
                    fontFamily: 'Helvetica Now Display',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Show a non-blocking loading indicator
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF13AF5B)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build All tab content
  Widget _buildAllCards() {
    final filteredInvoices = _filteredAllInvoices;

    if (filteredInvoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(
            'No invoices found',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8D9694),
              fontFamily: 'Helvetica Now Display',
            ),
          ),
        ),
      );
    }

    // Wrap in KeyedSubtree to preserve state
    return KeyedSubtree(
      key: ValueKey('all-cards-${filteredInvoices.length}'),
      child: Column(
        children: List.generate(filteredInvoices.length * 2 - 1, (index) {
          // Return card for even indices
          if (index.isEven) {
            final invoiceIndex = index ~/ 2;
            final invoice = filteredInvoices[invoiceIndex];
            final dateFormat = DateFormat('MM/dd/yyyy');
            final isNewlyAdded = _newlyAddedInvoiceIds.contains(
              invoice.invoiceId,
            );
            final itemKey = GlobalKey();

            // Different card types based on invoice status
            if (invoice.status == InvoiceStatus.overdue) {
              // Calculate days overdue
              final now = DateTime.now();
              final difference = now.difference(invoice.dueDate).inDays;
              final daysText = '$difference days due';

              // Use animated card for newly added invoices
              if (isNewlyAdded) {
                return KeyedSubtree(
                  key: itemKey,
                  child: AnimatedInvoiceCard(
                    companyName: invoice.client.name,
                    date: dateFormat.format(invoice.issueDate),
                    invoiceNumber: invoice.invoiceId,
                    amount: invoice.total.toStringAsFixed(2),
                    daysText: daysText,
                    daysColor: const Color(0xFFD61443),
                    onTap: () => _handleInvoiceTapped(invoice),
                    onAnimationComplete:
                        () => _handleAnimationComplete(invoice.invoiceId),
                    onLongPress: () => _handleLongPress(invoice, itemKey),
                  ),
                );
              }

              return KeyedSubtree(
                key: itemKey,
                child: DueCard(
                  companyName: invoice.client.name,
                  date: dateFormat.format(invoice.issueDate),
                  invoiceNumber: invoice.invoiceId,
                  amount: invoice.total.toStringAsFixed(2),
                  daysText: daysText,
                  daysColor: const Color(0xFFD61443),
                  onTap: () => _handleInvoiceTapped(invoice),
                  onLongPress: () => _handleLongPress(invoice, itemKey),
                ),
              );
            } else if (invoice.status == InvoiceStatus.outstanding) {
              // Calculate days until due
              final now = DateTime.now();
              final difference = invoice.dueDate.difference(now).inDays;
              final daysText = 'DUE IN $difference DAYS';

              // Use animated card for newly added invoices
              if (isNewlyAdded) {
                return KeyedSubtree(
                  key: itemKey,
                  child: AnimatedOutstandingCard(
                    companyName: invoice.client.name,
                    date: dateFormat.format(invoice.issueDate),
                    invoiceNumber: invoice.invoiceId,
                    amount: invoice.total.toStringAsFixed(2),
                    daysText: daysText,
                    daysColor: const Color(0xFFD68814),
                    onTap: () => _handleInvoiceTapped(invoice),
                    onAnimationComplete:
                        () => _handleAnimationComplete(invoice.invoiceId),
                    onLongPress: () => _handleLongPress(invoice, itemKey),
                  ),
                );
              }

              return KeyedSubtree(
                key: itemKey,
                child: Outstanding.DueCard(
                  companyName: invoice.client.name,
                  date: dateFormat.format(invoice.issueDate),
                  invoiceNumber: invoice.invoiceId,
                  amount: invoice.total.toStringAsFixed(2),
                  daysText: daysText,
                  daysColor: const Color(0xFFD68814),
                  onTap: () => _handleInvoiceTapped(invoice),
                  onLongPress: () => _handleLongPress(invoice, itemKey),
                ),
              );
            } else {
              // Paid
              // Get formatted paid date or fallback to issue date
              final displayDate =
                  invoice.paidDate != null
                      ? dateFormat.format(invoice.paidDate!)
                      : dateFormat.format(invoice.issueDate);
              final daysText = 'PAID ON $displayDate';

              // Use animated card for newly added invoices
              if (isNewlyAdded) {
                return KeyedSubtree(
                  key: itemKey,
                  child: AnimatedPaidCard(
                    companyName: invoice.client.name,
                    date: dateFormat.format(invoice.issueDate),
                    invoiceNumber: invoice.invoiceId,
                    amount: invoice.total.toStringAsFixed(2),
                    daysText: daysText,
                    daysColor: const Color(0xFF13AF5B),
                    onTap: () => _handleInvoiceTapped(invoice),
                    onAnimationComplete:
                        () => _handleAnimationComplete(invoice.invoiceId),
                    onLongPress: () => _handleLongPress(invoice, itemKey),
                  ),
                );
              }

              return KeyedSubtree(
                key: itemKey,
                child: Paid.DueCard(
                  companyName: invoice.client.name,
                  date: dateFormat.format(invoice.issueDate),
                  invoiceNumber: invoice.invoiceId,
                  amount: invoice.total.toStringAsFixed(2),
                  daysText: daysText,
                  daysColor: const Color(0xFF13AF5B),
                  onTap: () => _handleInvoiceTapped(invoice),
                  onLongPress: () => _handleLongPress(invoice, itemKey),
                ),
              );
            }
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

    // Wrap in KeyedSubtree to preserve state
    return KeyedSubtree(
      key: ValueKey('overdue-cards-${filteredInvoices.length}'),
      child: Column(
        children: List.generate(filteredInvoices.length * 2 - 1, (index) {
          // Return card for even indices
          if (index.isEven) {
            final invoiceIndex = index ~/ 2;
            final invoice = filteredInvoices[invoiceIndex];
            final dateFormat = DateFormat('MM/dd/yyyy');
            final isNewlyAdded = _newlyAddedInvoiceIds.contains(
              invoice.invoiceId,
            );
            final itemKey = GlobalKey();

            // Calculate days overdue
            final now = DateTime.now();
            final difference = now.difference(invoice.dueDate).inDays;
            final daysText = '$difference days due';

            // Use animated card for newly added invoices
            if (isNewlyAdded) {
              return KeyedSubtree(
                key: itemKey,
                child: AnimatedInvoiceCard(
                  companyName: invoice.client.name,
                  date: dateFormat.format(invoice.issueDate),
                  invoiceNumber: invoice.invoiceId,
                  amount: invoice.total.toStringAsFixed(2),
                  daysText: daysText,
                  daysColor: const Color(0xFFD61443),
                  onTap: () => _handleInvoiceTapped(invoice),
                  onAnimationComplete:
                      () => _handleAnimationComplete(invoice.invoiceId),
                  onLongPress: () => _handleLongPress(invoice, itemKey),
                ),
              );
            }

            return KeyedSubtree(
              key: itemKey,
              child: DueCard(
                companyName: invoice.client.name,
                date: dateFormat.format(invoice.issueDate),
                invoiceNumber: invoice.invoiceId,
                amount: invoice.total.toStringAsFixed(2),
                daysText: daysText,
                daysColor: const Color(0xFFD61443),
                onTap: () => _handleInvoiceTapped(invoice),
                onLongPress: () => _handleLongPress(invoice, itemKey),
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
      ),
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

    // Wrap in KeyedSubtree to preserve state
    return KeyedSubtree(
      key: ValueKey('outstanding-cards-${filteredInvoices.length}'),
      child: Column(
        children: List.generate(filteredInvoices.length * 2 - 1, (index) {
          // Return card for even indices
          if (index.isEven) {
            final invoiceIndex = index ~/ 2;
            final invoice = filteredInvoices[invoiceIndex];
            final dateFormat = DateFormat('MM/dd/yyyy');
            final isNewlyAdded = _newlyAddedInvoiceIds.contains(
              invoice.invoiceId,
            );
            final itemKey = GlobalKey();

            // Calculate days until due
            final now = DateTime.now();
            final difference = invoice.dueDate.difference(now).inDays;
            final daysText = 'DUE IN $difference DAYS';

            // Use animated card for newly added invoices
            if (isNewlyAdded) {
              return KeyedSubtree(
                key: itemKey,
                child: AnimatedOutstandingCard(
                  companyName: invoice.client.name,
                  date: dateFormat.format(invoice.issueDate),
                  invoiceNumber: invoice.invoiceId,
                  amount: invoice.total.toStringAsFixed(2),
                  daysText: daysText,
                  daysColor: const Color(0xFFD68814),
                  onTap: () => _handleInvoiceTapped(invoice),
                  onAnimationComplete:
                      () => _handleAnimationComplete(invoice.invoiceId),
                  onLongPress: () => _handleLongPress(invoice, itemKey),
                ),
              );
            }

            return KeyedSubtree(
              key: itemKey,
              child: Outstanding.DueCard(
                companyName: invoice.client.name,
                date: dateFormat.format(invoice.issueDate),
                invoiceNumber: invoice.invoiceId,
                amount: invoice.total.toStringAsFixed(2),
                daysText: daysText,
                daysColor: const Color(0xFFD68814),
                onTap: () => _handleInvoiceTapped(invoice),
                onLongPress: () => _handleLongPress(invoice, itemKey),
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
      ),
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

    // Wrap in KeyedSubtree to preserve state
    return KeyedSubtree(
      key: ValueKey('paid-cards-${filteredInvoices.length}'),
      child: Column(
        children: List.generate(filteredInvoices.length * 2 - 1, (index) {
          // Return card for even indices
          if (index.isEven) {
            final invoiceIndex = index ~/ 2;
            final invoice = filteredInvoices[invoiceIndex];
            final dateFormat = DateFormat('MM/dd/yyyy');
            final isNewlyAdded = _newlyAddedInvoiceIds.contains(
              invoice.invoiceId,
            );
            final itemKey = GlobalKey();

            // Get formatted paid date or fallback to issue date
            final displayDate =
                invoice.paidDate != null
                    ? dateFormat.format(invoice.paidDate!)
                    : dateFormat.format(invoice.issueDate);
            final daysText = 'PAID ON $displayDate';

            // Use animated card for newly added invoices
            if (isNewlyAdded) {
              return KeyedSubtree(
                key: itemKey,
                child: AnimatedPaidCard(
                  companyName: invoice.client.name,
                  date: dateFormat.format(invoice.issueDate),
                  invoiceNumber: invoice.invoiceId,
                  amount: invoice.total.toStringAsFixed(2),
                  daysText: daysText,
                  daysColor: const Color(0xFF13AF5B),
                  onTap: () => _handleInvoiceTapped(invoice),
                  onAnimationComplete:
                      () => _handleAnimationComplete(invoice.invoiceId),
                  onLongPress: () => _handleLongPress(invoice, itemKey),
                ),
              );
            }

            return KeyedSubtree(
              key: itemKey,
              child: Paid.DueCard(
                companyName: invoice.client.name,
                date: dateFormat.format(invoice.issueDate),
                invoiceNumber: invoice.invoiceId,
                amount: invoice.total.toStringAsFixed(2),
                daysText: daysText,
                daysColor: const Color(0xFF13AF5B),
                onTap: () => _handleInvoiceTapped(invoice),
                onLongPress: () => _handleLongPress(invoice, itemKey),
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
      ),
    );
  }
}
