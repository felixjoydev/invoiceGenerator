import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/cards/ClientCard.dart';
import 'package:invoicegenerator/widgets/cards/AnimatedClientCard.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/screens/catalog/catalog_list_screen.dart';
import 'package:invoicegenerator/utils/route_transitions.dart';
import 'package:invoicegenerator/screens/clients/add_client_screen.dart';
import 'package:invoicegenerator/models/hive/client_model.dart' as hive;
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/hive/client_service.dart';
import 'package:invoicegenerator/services/hive/service_provider.dart';
import 'package:invoicegenerator/widgets/display/BlurredBackground.dart';
import 'package:invoicegenerator/widgets/cards/HighlightedClientCard.dart';
import 'package:invoicegenerator/widgets/display/PressWidget.dart';
import 'package:invoicegenerator/bottom_sheets/clients/client_sort.dart';
import 'package:invoicegenerator/bottom_sheets/clients/edit_client.dart';
import 'package:invoicegenerator/utils/client_adapter.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> with RouteAware {
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  // Search focus node
  final FocusNode _searchFocusNode = FocusNode();

  // Scroll controller for scrolling to top when sort is applied
  final ScrollController _scrollController = ScrollController();

  // Search query
  String _searchQuery = '';

  // Client service
  late ClientService _clientService;

  // List of clients
  List<hive.Client> _clients = [];

  // Currently selected item (for long press)
  hive.Client? _selectedClient;

  // Current sort option
  int? _currentSortOption;

  // Selected card position
  Offset _selectedItemPosition = Offset.zero;
  Size _selectedItemSize = Size.zero;
  bool _showPressWidgetAbove = false;

  // Store each item's position for immediate access without render box
  final Map<String, Rect> _clientPositions = {};

  // Track newly added clients that should be animated
  final Set<String> _newlyAddedClientIds = {};

  @override
  void initState() {
    super.initState();
    // Get the client service from the provider
    _clientService = HiveServiceProvider().clientService;

    // Listen for changes from the service
    _clientService.addListener(_onClientDataChanged);

    // Reset any selected client when screen initializes
    _selectedClient = null;

    // Force recalculation of statistics when screen loads
    _recalculateStatistics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Clear any selected client when dependencies change
    if (_selectedClient != null) {
      setState(() {
        _selectedClient = null;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _clientService.removeListener(_onClientDataChanged);
    _scrollController.dispose();
    super.dispose();
  }

  // Update _onClientDataChanged to no longer detect new clients for animation
  void _onClientDataChanged() {
    if (mounted) {
      setState(() {
        _clients = _clientService.clients;
      });
    }
  }

  // Handle when animation completes for a client card
  void _handleAnimationComplete(String clientId) {
    setState(() {
      _newlyAddedClientIds.remove(clientId);
    });
  }

  // Filtered and sorted clients based on search query and sort option
  List<hive.Client> get _filteredClients {
    // Get filtered items based on search query
    List<hive.Client> result =
        _searchQuery.isEmpty
            ? List<hive.Client>.from(_clientService.clients)
            : List<hive.Client>.from(
              _clientService.searchClients(_searchQuery),
            );

    // Then apply sorting
    if (_currentSortOption != null) {
      switch (_currentSortOption) {
        case 0: // Latest Client
          result.sort((a, b) => b.clientId.compareTo(a.clientId));
          break;
        case 1: // Oldest Client
          result.sort((a, b) => a.clientId.compareTo(b.clientId));
          break;
        case 2: // Pending Payment
          result.sort((a, b) {
            if (a.hasOutstanding && !b.hasOutstanding) return -1;
            if (!a.hasOutstanding && b.hasOutstanding) return 1;
            return 0;
          });
          break;
        case 3: // Amount (Low to High)
          result.sort((a, b) {
            double aAmount = a.amount;
            double bAmount = b.amount;
            return aAmount.compareTo(bAmount);
          });
          break;
        case 4: // Amount (High to Low)
          result.sort((a, b) {
            double aAmount = a.amount;
            double bAmount = b.amount;
            return bAmount.compareTo(aAmount);
          });
          break;
        case 5: // Client Name (Ascending)
          result.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case 6: // Client Name (Descending)
          result.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
      }
    }

    return result;
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
  }

  // Handle the add button press
  void _handleAddTapped() {
    // Clear focus before navigating
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    // Clear any selected client
    if (_selectedClient != null) {
      setState(() {
        _selectedClient = null;
      });
    }

    // Get current client IDs to compare after returning
    final Set<String> currentClientIds = Set<String>.from(
      _clients.map((c) => c.clientId),
    );

    // Navigate to the AddClientScreen
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddClientScreen()))
        .then((_) {
          // Get updated clients
          final updatedClients = _clientService.clients;

          // Check if new clients were added
          if (updatedClients.length > _clients.length) {
            setState(() {
              _clients = updatedClients;

              // Add animation markers for new clients
              for (final client in updatedClients) {
                if (!currentClientIds.contains(client.clientId)) {
                  _newlyAddedClientIds.add(client.clientId);
                  debugPrint(
                    'New client to animate: ${client.name} (${client.clientId})',
                  );
                }
              }
            });
          } else {
            // If no new clients, just refresh the screen
            setState(() {
              _clients = updatedClients;
            });
          }
        });
  }

  // Handle search input changes
  void _handleSearchInputChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  // Get the position of a client card for long press
  Rect _getClientPosition(hive.Client client) {
    // First try to get from pre-calculated positions
    if (_clientPositions.containsKey(client.clientId)) {
      return _clientPositions[client.clientId]!;
    }

    // If not available, fall back to estimating position
    final screenWidth = MediaQuery.of(context).size.width;
    final index = _filteredClients.indexOf(client);

    // Calculate constants for positioning
    final topNavHeight = 70.0;
    final searchHeight = 60.0;
    final itemHeight = 60.0;
    final itemSpacing = 33.0;
    final horizontalPadding = 16.0;

    // Calculate Y position based on index
    final yPosition =
        topNavHeight +
        searchHeight +
        32.0 +
        (index * (itemHeight + itemSpacing));

    return Rect.fromLTWH(
      horizontalPadding,
      yPosition,
      screenWidth - (horizontalPadding * 2),
      itemHeight,
    );
  }

  // Handle when long press on client card
  void _handleLongPress(hive.Client client, GlobalKey itemKey) {
    debugPrint('Long press detected on client: ${client.name}');

    // Provide haptic feedback immediately
    HapticFeedback.mediumImpact();

    // Get the client's position - first try from render box, then fallback
    final Rect clientRect;
    final RenderBox? renderBox =
        itemKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      clientRect = Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );
      debugPrint('Position from renderBox: ${position.dy}');
    } else {
      // Use pre-calculated or estimated position
      clientRect = _getClientPosition(client);
      debugPrint('Using pre-calculated position: ${clientRect.top}');
    }

    // Set the position and size
    _selectedItemPosition = Offset(clientRect.left, clientRect.top);
    _selectedItemSize = Size(clientRect.width, clientRect.height);

    // Calculate if PressWidget should show above or below
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavHeight = 80.0;
    final pressWidgetHeight = 112.0;
    final bottomSpace = screenHeight - clientRect.bottom - bottomNavHeight;

    _showPressWidgetAbove = bottomSpace < pressWidgetHeight + 8;

    // Update state to show the selected client
    setState(() {
      _selectedClient = client;
    });
  }

  // Handle when the background is tapped to dismiss the selection
  void _handleBackgroundTap() {
    setState(() {
      _selectedClient = null;
    });
  }

  // Handle when edit is tapped
  void _handleEditTapped() {
    if (_selectedClient == null) return;

    // Store a reference to the selected client before clearing the selection
    final clientToEdit = ClientAdapter.fromHiveClient(_selectedClient!);

    // Dismiss the selection
    setState(() {
      _selectedClient = null;
    });

    // Show the edit client bottom sheet
    showEditClientSheet(
      context,
      client: clientToEdit,
      onClientUpdated: (updatedClient) {
        // The client service should already have updated the client
        // Refresh the display
        setState(() {
          _clients = _clientService.clients;
        });
      },
      onClientDeleted: () {
        // The client service should already have deleted the client
        // Refresh the display
        setState(() {
          _clients = _clientService.clients;
        });
      },
    );
  }

  // Handle when delete is tapped
  void _handleDeleteTapped() {
    if (_selectedClient == null) return;

    // Delete the client directly without confirmation
    _clientService.deleteClient(_selectedClient!.clientId);

    // Clear the selection
    setState(() {
      _selectedClient = null;
    });
  }

  // Handle the sort button press
  void _handleSortTapped() {
    // Create an overlay entry
    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Create animation controllers
    AnimationController overlayAnimController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: Navigator.of(context),
    );

    AnimationController sheetAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: Navigator.of(context),
    );

    // Create animations
    Animation<double> overlayOpacity = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(
      CurvedAnimation(parent: overlayAnimController, curve: Curves.easeOut),
    );

    Animation<double> sheetSlide = Tween<double>(
      begin: 1.0, // Start from bottom
      end: 0.0, // End at correct position
    ).animate(
      CurvedAnimation(parent: sheetAnimController, curve: Curves.easeOutCubic),
    );

    // Function to close the bottom sheet
    void closeSheet() {
      // Run both animations in parallel to eliminate delay
      sheetAnimController.reverse();
      overlayAnimController.reverse().then((_) {
        // Only remove overlay and dispose controllers after both animations complete
        overlayEntry.remove();
        overlayAnimController.dispose();
        sheetAnimController.dispose();
      });
    }

    // Handle the selected sort option
    void handleSortSelection(int? sortOption) {
      // Close the sheet first
      closeSheet();

      // Then handle the sort option
      setState(() {
        _currentSortOption = sortOption;
      });

      // Scroll to top when sort is applied
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    // Create the overlay entry
    overlayEntry = OverlayEntry(
      builder: (context) {
        final sheetHeight =
            MediaQuery.of(context).size.height *
            0.6; // Approximate height for more options

        return Stack(
          children: [
            // Animated overlay background
            AnimatedBuilder(
              animation: overlayOpacity,
              builder: (context, _) {
                return Positioned.fill(
                  child: GestureDetector(
                    onTap: closeSheet,
                    child: Container(
                      color: Color(
                        0xFFA3A3A3,
                      ).withOpacity(overlayOpacity.value),
                    ),
                  ),
                );
              },
            ),

            // Animated bottom sheet
            AnimatedBuilder(
              animation: sheetSlide,
              builder: (context, _) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: -sheetHeight * sheetSlide.value,
                  child: GestureDetector(
                    onTap: () {}, // Prevent taps from passing through
                    child: Material(
                      color: Colors.transparent,
                      child: ClientSortSheet(
                        onSortSelected: handleSortSelection,
                        initialSortOption: _currentSortOption,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );

    // Insert the overlay and start animations
    overlayState.insert(overlayEntry);
    overlayAnimController.forward();
    sheetAnimController.forward();
  }

  // Method to recalculate statistics
  void _recalculateStatistics() async {
    // Get the service provider
    final serviceProvider = HiveServiceProvider();

    // Ensure statistics are calculated
    await serviceProvider.ensureStatisticsCalculated();

    // Refresh state after recalculation
    if (mounted) {
      setState(() {
        _clients = _clientService.clients;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent bottom navigation from being pushed up by keyboard
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      // Add GestureDetector at root to handle taps outside input
      body: GestureDetector(
        // When tapping anywhere, unfocus active text fields
        onTap: () => FocusScope.of(context).unfocus(),
        // Make sure the gesture detector doesn't block input widgets
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Main content
            Column(
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
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF373C3A),
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
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _handleSortTapped,
                                  child: SvgPicture.asset(
                                    'assets/icons/sort.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF373C3A),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                // Sort indicator square
                                if (_currentSortOption != null)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF05022),
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                  ),
                              ],
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
                    focusNode: _searchFocusNode,
                    hintText: 'Search clients',
                    onChanged: _handleSearchInputChanged,
                  ),
                ),

                // 24px spacing after Search Input
                const SizedBox(height: 24),

                // Main content area - restore slide animation for screen transitions
                Expanded(
                  child: ContentSlideTransition(
                    // Direction determination happens in the route - slide from right when coming from
                    // home or invoice screens, slide from left when coming from catalog
                    slideFromRight:
                        ModalRoute.of(context)?.settings.arguments
                            is HomeScreen ||
                        ModalRoute.of(context)?.settings.arguments
                            is InvoiceListScreen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: _buildClientCards(),
                      ),
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

            // Overlay for long press with fade-in animation
            if (_selectedClient != null)
              BlurredBackground(onTap: _handleBackgroundTap),

            // Selected item and press widget with absolute positioning
            if (_selectedClient != null)
              Stack(
                children: [
                  // HighlightedClientCard - always positioned at original location
                  Positioned(
                    left: _selectedItemPosition.dx,
                    top: _selectedItemPosition.dy,
                    width: _selectedItemSize.width,
                    child: Material(
                      color: Colors.transparent,
                      child: HighlightedClientCard(
                        client: ClientAdapter.fromHiveClient(_selectedClient!),
                      ),
                    ),
                  ),

                  // PressWidget - positioned either above or below the card
                  Positioned(
                    left: _selectedItemPosition.dx,
                    top:
                        _showPressWidgetAbove
                            ? _selectedItemPosition.dy -
                                112.0 -
                                0.0 // Above the card with 8px spacing
                            : _selectedItemPosition.dy +
                                _selectedItemSize.height +
                                8.0, // Below the card with 8px spacing
                    width: _selectedItemSize.width,
                    child: Material(
                      color: Colors.transparent,
                      child: PressWidget(
                        onEdit: _handleEditTapped,
                        onDelete: _handleDeleteTapped,
                      ),
                    ),
                  ),
                ],
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

    // Debug print to check if invoiceCount is being populated
    for (var client in filteredClients.take(5)) {
      debugPrint(
        '🔍 Client ${client.name} [ID: ${client.clientId}] has invoiceCount: ${client.invoiceCount}, amount: ${client.amount}',
      );
    }

    return Column(
      children: List.generate(filteredClients.length * 2 - 1, (index) {
        // Return card for even indices
        if (index.isEven) {
          final clientIndex = index ~/ 2;
          final client = filteredClients[clientIndex];
          final itemKey = GlobalKey();
          final isNewlyAdded = _newlyAddedClientIds.contains(client.clientId);

          // Use AnimatedClientCard for newly added clients
          if (isNewlyAdded) {
            return KeyedSubtree(
              key: itemKey,
              child: AnimatedClientCard(
                clientName: client.name,
                clientId: client.clientId,
                invoiceCount: client.invoiceCount,
                currency: client.currencyOrDefault,
                amount: client.amount,
                outstandingAmount: client.outstandingAmount,
                hasOutstanding: client.hasOutstanding,
                dueAmount: client.dueAmount,
                hasDue: client.hasDue,
                onAnimationComplete:
                    () => _handleAnimationComplete(client.clientId),
                onLongPress: () => _handleLongPress(client, itemKey),
                onTap: () => _handleCardTap(client),
              ),
            );
          }

          // Use regular ClientCard for existing clients
          return KeyedSubtree(
            key: itemKey,
            child: ClientCard(
              clientName: client.name,
              clientId: client.clientId,
              invoiceCount: client.invoiceCount,
              currency: client.currencyOrDefault,
              amount: client.amount,
              outstandingAmount: client.outstandingAmount,
              hasOutstanding: client.hasOutstanding,
              hasDue: client.hasDue,
              dueAmount: client.dueAmount,
              onLongPress: () => _handleLongPress(client, itemKey),
              onTap: () => _handleCardTap(client),
            ),
          );
        }
        // Return divider for odd indices
        else {
          return const Column(
            children: [
              SizedBox(height: 16),
              Divider(height: 1, color: Color(0xFFCAD5D2)),
              SizedBox(height: 16),
            ],
          );
        }
      })..add(const SizedBox(height: 16)), // Add bottom spacing
    );
  }

  // Handle when a client card is tapped (regular tap)
  void _handleCardTap(hive.Client client) {
    // Show the edit client bottom sheet directly
    showEditClientSheet(
      context,
      client: ClientAdapter.fromHiveClient(client),
      onClientUpdated: (updatedClient) {
        // The client service should already have updated the client
        // Refresh the display
        setState(() {
          _clients = _clientService.clients;
        });
      },
      onClientDeleted: () {
        // The client service should already have deleted the client
        // Refresh the display
        setState(() {
          _clients = _clientService.clients;
        });
      },
    );
  }
}
