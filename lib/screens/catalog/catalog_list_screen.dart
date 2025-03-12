import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/navigation/bottom_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/cards/CatalogCard.dart';
import 'package:invoicegenerator/widgets/cards/AnimatedCatalogCard.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/screens/clients/client_list_screen.dart';
import 'package:invoicegenerator/utils/route_transitions.dart';
import 'package:invoicegenerator/screens/catalog/add_catalog_screen.dart';
import 'package:invoicegenerator/screens/catalog/edit_catalog_screen.dart';
import 'package:invoicegenerator/services/catalog_service.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/widgets/display/BlurredBackground.dart';
import 'package:invoicegenerator/widgets/cards/HighlightedCatalogCard.dart';
import 'package:invoicegenerator/widgets/display/PressWidget.dart';
import 'package:invoicegenerator/bottom_sheets/catalog/catalog_sort.dart';

class CatalogListScreen extends StatefulWidget {
  const CatalogListScreen({super.key});

  @override
  State<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends State<CatalogListScreen> {
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  // Search focus node
  final FocusNode _searchFocusNode = FocusNode();

  // Scroll controller for scrolling to top when sort is applied
  final ScrollController _scrollController = ScrollController();

  // Search query
  String _searchQuery = '';

  // Catalog service
  final _catalogService = CatalogService();

  // List of newly added items that are being animated
  final Set<String> _animatingItems = <String>{};

  // Currently selected item (for long press)
  CatalogItem? _selectedItem;

  // Current sort option
  int? _currentSortOption;

  // Selected card position
  GlobalKey _lastSelectedKey = GlobalKey();
  Offset _selectedItemPosition = Offset.zero;
  Size _selectedItemSize = Size.zero;
  bool _showPressWidgetAbove = false;

  @override
  void initState() {
    super.initState();
    // Initialize catalog service
    _loadCatalogItems();

    // Listen for changes from the service
    _catalogService.addListener(_onCatalogDataChanged);
  }

  // Load catalog items from the service
  Future<void> _loadCatalogItems() async {
    try {
      // Initialize the service
      await _catalogService.init();

      // Update state with items
      setState(() {});
    } catch (e) {
      debugPrint('Error loading catalog items: $e');
    }
  }

  // Handler for catalog data changes
  void _onCatalogDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Get filtered catalog items based on search query
  List<CatalogItem> get _filteredCatalogItems {
    // Get filtered items based on search query
    List<CatalogItem> items =
        _searchQuery.isEmpty
            ? List<CatalogItem>.from(_catalogService.getAllItems())
            : List<CatalogItem>.from(_catalogService.searchItems(_searchQuery));

    // Apply sorting based on the current sort option
    if (_currentSortOption != null) {
      switch (_currentSortOption) {
        case 0: // Amount (Low to High)
          items.sort((a, b) => a.amount.compareTo(b.amount));
          break;
        case 1: // Amount (High to Low)
          items.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case 2: // Item Name (Ascending)
          items.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
          break;
        case 3: // Item Name (Descending)
          items.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
          );
          break;
      }
    }

    return items;
  }

  // Handle bottom navigation item selection
  void _handleNavItemSelected(BottomNavItem item) {
    if (item == BottomNavItem.catalog) return; // Already on catalog screen

    if (item == BottomNavItem.home) {
      // Navigate to home screen with replacement
      context.navigateWithSlide(const HomeScreen());
    } else if (item == BottomNavItem.invoice) {
      // Navigate to invoice list screen with replacement
      context.navigateWithSlide(const InvoiceListScreen());
    } else if (item == BottomNavItem.clients) {
      // Navigate to clients list screen with replacement
      context.navigateWithSlide(const ClientListScreen());
    }
    // Other navigation options would be handled here
  }

  // Handle the add button press
  void _handleAddTapped() {
    // Clear focus before navigating
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }

    // Get current items count to compare after returning
    final int currentItemsCount = _catalogService.getAllItems().length;

    // Navigate to add catalog screen
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddCatalogScreen()))
        .then((_) {
          // Make sure focus isn't set when returning
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _searchFocusNode.hasFocus) {
              _searchFocusNode.unfocus();
            }
          });

          // Get updated items list
          final items = _catalogService.getAllItems();

          // Only animate if new items were added
          if (items.length > currentItemsCount) {
            setState(() {
              // Only animate new items (those at the beginning of the list)
              for (int i = 0; i < items.length - currentItemsCount; i++) {
                if (i < items.length) {
                  _animatingItems.add(items[i].title);
                }
              }
            });
          } else {
            // If no new items, just refresh the screen
            setState(() {});
          }
        });
  }

  // Handle search input changes
  void _handleSearchInputChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  // Handle when an animated card's animation completes
  void _handleAnimationComplete(String itemTitle) {
    setState(() {
      _animatingItems.remove(itemTitle);
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
      final pressWidgetHeight = 112.0; // Approximate height of PressWidget
      final bottomSpace =
          screenHeight -
          _selectedItemPosition.dy -
          _selectedItemSize.height -
          bottomNavHeight;

      // If there's not enough space to show the PressWidget below,
      // show it above instead
      _showPressWidgetAbove =
          bottomSpace < pressWidgetHeight + 8; // 8 is the spacing

      // Ensure we trigger a rebuild with the new position
      setState(() {});
    }
  }

  // Handle when long press on catalog card
  void _handleLongPress(CatalogItem item, GlobalKey itemKey) {
    _lastSelectedKey = itemKey;

    // Get the position immediately, if possible
    final RenderBox? renderBox =
        itemKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      _selectedItemPosition = renderBox.localToGlobal(Offset.zero);
      _selectedItemSize = renderBox.size;

      // Calculate press widget position
      final bottomNavHeight = 80.0;
      final pressWidgetHeight = 112.0;
      final bottomSpace =
          MediaQuery.of(context).size.height -
          _selectedItemPosition.dy -
          _selectedItemSize.height -
          bottomNavHeight;

      _showPressWidgetAbove = bottomSpace < pressWidgetHeight + 80;
    }

    setState(() {
      _selectedItem = item;
    });

    // Also set up a post-frame callback to refine the position if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedItemPosition();
    });
  }

  // Handle when the background is tapped to dismiss the selection
  void _handleBackgroundTap() {
    setState(() {
      _selectedItem = null;
    });
  }

  // Handle when edit is tapped
  void _handleEditTapped() {
    if (_selectedItem == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditCatalogScreen(item: _selectedItem!),
          ),
        )
        .then((_) {
          // Dismiss the selection and refresh the screen
          setState(() {
            _selectedItem = null;
          });
        });
  }

  // Handle when delete is tapped
  void _handleDeleteTapped() {
    if (_selectedItem == null) return;

    // Delete the item directly without confirmation
    _catalogService.deleteItem(_selectedItem!.title);

    // Clear the selection
    setState(() {
      _selectedItem = null;
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
            MediaQuery.of(context).size.height * 0.5; // Approximate height

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
                      child: CatalogSortSheet(
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _catalogService.removeListener(_onCatalogDataChanged);
    _scrollController.dispose();
    super.dispose();
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
            Column(
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
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF373C3A),
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
                    hintText: 'Search catalog',
                    onChanged: _handleSearchInputChanged,
                  ),
                ),

                // 24px spacing after Search Input
                const SizedBox(height: 24),

                // Main content area with catalog cards
                Expanded(
                  child: ContentSlideTransition(
                    // Direction determination happens in the route
                    slideFromRight:
                        ModalRoute.of(context)?.settings.arguments
                            is HomeScreen ||
                        ModalRoute.of(context)?.settings.arguments
                            is InvoiceListScreen ||
                        ModalRoute.of(context)?.settings.arguments
                            is ClientListScreen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: _buildCatalogCards(),
                      ),
                    ),
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

            // Overlay for long press with fade-in animation
            if (_selectedItem != null)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: BlurredBackground(onTap: _handleBackgroundTap),
              ),

            // Selected item and press widget with absolute positioning
            if (_selectedItem != null)
              Stack(
                children: [
                  // HighlightedCatalogCard - always positioned at original location
                  Positioned(
                    left: _selectedItemPosition.dx,
                    top: _selectedItemPosition.dy,
                    width: _selectedItemSize.width,
                    child: Material(
                      color: Colors.transparent,
                      child: HighlightedCatalogCard(item: _selectedItem!),
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

  // Build the catalog cards
  Widget _buildCatalogCards() {
    final filteredItems = _filteredCatalogItems;

    if (filteredItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(
            'No catalog items found',
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
          final itemKey = GlobalKey();

          // Check if this item is being animated
          if (_animatingItems.contains(item.title)) {
            return KeyedSubtree(
              key: itemKey,
              child: AnimatedCatalogCard(
                item: item,
                onAnimationComplete: () => _handleAnimationComplete(item.title),
                onLongPress: () => _handleLongPress(item, itemKey),
              ),
            );
          }

          return KeyedSubtree(
            key: itemKey,
            child: CatalogCard(
              title: item.title,
              usageInfo: item.usageInfo,
              currency: item.currency,
              amount: item.amount,
              onLongPress: () => _handleLongPress(item, itemKey),
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
}
