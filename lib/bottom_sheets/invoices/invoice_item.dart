import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/actions/ItemAdd.dart';
import 'package:invoicegenerator/services/catalog_service.dart';
import 'package:invoicegenerator/models/catalog_item.dart';

class InvoiceItemSheet extends StatefulWidget {
  final VoidCallback? onAddNewItemPressed;
  final Function(List<CatalogItem>)? onItemsSelected;
  final List<CatalogItem> preSelectedItems;

  const InvoiceItemSheet({
    super.key,
    this.onAddNewItemPressed,
    this.onItemsSelected,
    this.preSelectedItems = const [],
  });

  @override
  State<InvoiceItemSheet> createState() => _InvoiceItemSheetState();
}

class _InvoiceItemSheetState extends State<InvoiceItemSheet> {
  final TextEditingController _searchController = TextEditingController();
  final _catalogService = CatalogService();
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;

  List<CatalogItem> _catalogItems = [];
  List<CatalogItem> _filteredItems = [];
  List<CatalogItem> _selectedItems = [];
  List<CatalogItem> _newlySelectedItems = [];
  Map<String, bool> _selectionState = {};
  Map<String, int> _quantityState = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize with empty selection states
    _selectedItems = [];
    _newlySelectedItems = [];
    _selectionState = {};
    _quantityState = {};

    _loadCatalogItems();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset <= 0) {
      setState(() {
        _isAtTop = true;
      });
    } else if (_isAtTop) {
      setState(() {
        _isAtTop = false;
      });
    }
  }

  // Load catalog items from the service
  Future<void> _loadCatalogItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize the service
      await _catalogService.init();

      // Get all items
      final items = _catalogService.getAllItems();

      setState(() {
        _catalogItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading catalog items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleAddNewItem() {
    // Close the current bottom sheet
    Navigator.pop(context);

    // Call the passed callback if it exists
    if (widget.onAddNewItemPressed != null) {
      widget.onAddNewItemPressed!();
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = List.from(_catalogItems);
      } else {
        _filteredItems = _catalogService.searchItems(query);
      }

      // If no results are found and we're not at the top,
      // don't change the scroll position
      if (_filteredItems.isEmpty && !_isAtTop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Keep scroll position to prevent jarring UI shift
          // This only applies when search finds no results
        });
      }
    });
  }

  void _toggleItemSelection(CatalogItem item) {
    setState(() {
      // Update selection state
      _selectionState[item.title] = !(_selectionState[item.title] ?? false);

      // Update selected items list and quantity
      if (_selectionState[item.title] ?? false) {
        // If selecting, ensure quantity is at least 1
        _quantityState[item.title] = _quantityState[item.title] ?? 0;
        if (_quantityState[item.title]! <= 0) {
          _quantityState[item.title] = 1;
        }

        // Add to selected items or update if already present with the new quantity
        int existingIndex = _selectedItems.indexWhere(
          (selectedItem) => selectedItem.title == item.title,
        );

        if (existingIndex >= 0) {
          // Update existing item with new quantity
          _selectedItems[existingIndex] = item.copyWith(
            quantity: _quantityState[item.title]!,
          );
        } else {
          // Add new item with the proper quantity
          _selectedItems.add(
            item.copyWith(quantity: _quantityState[item.title]!),
          );
        }

        // Add to newly selected items
        int newlySelectedIndex = _newlySelectedItems.indexWhere(
          (selectedItem) => selectedItem.title == item.title,
        );

        if (newlySelectedIndex < 0) {
          _newlySelectedItems.add(
            item.copyWith(quantity: _quantityState[item.title]!),
          );
        } else {
          _newlySelectedItems[newlySelectedIndex] = item.copyWith(
            quantity: _quantityState[item.title]!,
          );
        }
      } else {
        // If deselecting, set quantity to 0 and remove from selected
        _quantityState[item.title] = 0;
        _selectedItems.removeWhere(
          (selectedItem) => selectedItem.title == item.title,
        );

        // Remove from newly selected items
        _newlySelectedItems.removeWhere(
          (selectedItem) => selectedItem.title == item.title,
        );
      }
    });
  }

  void _handleQuantityChanged(CatalogItem item, int newQuantity) {
    setState(() {
      _quantityState[item.title] = newQuantity;

      // Update selection state based on quantity
      bool isSelected = newQuantity > 0;
      _selectionState[item.title] = isSelected;

      // Update selected items
      if (isSelected) {
        // Add or update item in selected items
        int existingIndex = _selectedItems.indexWhere(
          (selectedItem) => selectedItem.title == item.title,
        );

        if (existingIndex >= 0) {
          // Update existing item with new quantity
          _selectedItems[existingIndex] = item.copyWith(quantity: newQuantity);
        } else {
          // Add new item with the proper quantity
          _selectedItems.add(item.copyWith(quantity: newQuantity));
        }

        // Add to newly selected items
        int newlySelectedIndex = _newlySelectedItems.indexWhere(
          (selectedItem) => selectedItem.title == item.title,
        );

        if (newlySelectedIndex < 0) {
          _newlySelectedItems.add(item.copyWith(quantity: newQuantity));
        } else {
          _newlySelectedItems[newlySelectedIndex] = item.copyWith(
            quantity: newQuantity,
          );
        }
      } else {
        // Remove from selected items if quantity is 0
        _selectedItems.removeWhere(
          (selectedItem) => selectedItem.title == item.title,
        );

        // Remove from newly selected items
        _newlySelectedItems.removeWhere(
          (selectedItem) => selectedItem.title == item.title,
        );
      }
    });
  }

  // Close the sheet and pass selected items back to parent
  void _applySelection() {
    if (widget.onItemsSelected != null) {
      widget.onItemsSelected!(_selectedItems);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maximum height (screen height - 80px)
    final double maxHeight = MediaQuery.of(context).size.height - 120;
    final int selectedCount = _selectedItems.length;
    final int newlySelectedCount = _newlySelectedItems.length;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Dismiss keyboard when dragging the sheet down
        FocusScope.of(context).unfocus();

        if (_isAtTop && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      // Dismiss keyboard when tapping on sheet handle
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: maxHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle
            Container(
              width: 48,
              height: 8,
              decoration: BoxDecoration(
                color: Color(0xFF373C3A),
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            SizedBox(height: 12),
            // Main content
            Expanded(
              child: GestureDetector(
                // Dismiss keyboard when tapping anywhere outside of input fields
                onTap: () => FocusScope.of(context).unfocus(),
                // Make sure the gesture detector doesn't block other gestures
                behavior: HitTestBehavior.translucent,
                child: Container(
                  width: double.infinity,
                  color: Color(0xFFDAE4E1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed Header Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Add New Item button
                            MainHeadingWithButton(
                              text: 'Select Items',
                              iconPath: 'assets/icons/catalog-black.svg',
                              onAddNewItemPressed: _handleAddNewItem,
                            ),

                            // Add spacing between heading and search input
                            SizedBox(height: 8),

                            // Search input
                            SearchInput(
                              controller: _searchController,
                              hintText: 'Search items',
                              onChanged: _handleSearch,
                            ),

                            // Add spacing between search input and item list
                            SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Scrollable Items List
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                if (notification.metrics.pixels <= 0) {
                                  setState(() {
                                    _isAtTop = true;
                                  });
                                } else if (_isAtTop) {
                                  setState(() {
                                    _isAtTop = false;
                                  });
                                }
                              }
                              return false;
                            },
                            child:
                                _isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _filteredItems.isEmpty
                                    ? const Center(
                                      child: Text(
                                        'No catalog items found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF8D9694),
                                          fontFamily: 'Helvetica Now Display',
                                        ),
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      controller: _scrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Unfocus the search input when tapping the list
                                          FocusScope.of(context).unfocus();
                                        },
                                        child: _buildCatalogItemsList(),
                                      ),
                                    ),
                          ),
                        ),
                      ),

                      // Fixed Bottom Button Section
                      if (_newlySelectedItems.isNotEmpty)
                        Container(
                          width: double.infinity,
                          color: Color(0xFFDAE4E1),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            16,
                            20,
                            MediaQuery.of(context).padding.bottom + 16,
                          ),
                          child: PrimaryButton(
                            label:
                                newlySelectedCount > 1
                                    ? 'ADD $newlySelectedCount ITEMS TO INVOICE'
                                    : 'ADD $newlySelectedCount ITEM TO INVOICE',
                            onPressed: _applySelection,
                            isEnabled: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the list of catalog items
  Widget _buildCatalogItemsList() {
    // Show all items in the original order without separating already-added items
    return Column(
      children: List.generate(_filteredItems.length * 2 - 1, (index) {
        // For even indices, show the item
        if (index.isEven) {
          final itemIndex = index ~/ 2;
          final item = _filteredItems[itemIndex];
          final isSelected = _selectionState[item.title] ?? false;
          final quantity = _quantityState[item.title] ?? 0;

          return ItemAdd(
            key: ValueKey(item.title),
            title: item.title,
            amount: item.amount,
            currency: item.currency ?? 'USD',
            isSelected: isSelected,
            initialQuantity: quantity,
            isAlreadyAdded:
                false, // Always set to false so no items are disabled
            onSelect: () => _toggleItemSelection(item),
            onQuantityChanged:
                (newQuantity) => _handleQuantityChanged(item, newQuantity),
          );
        }
        // For odd indices, show a divider
        else {
          return Column(
            children: const [
              SizedBox(height: 16),
              DashedDivider(),
              SizedBox(height: 16),
            ],
          );
        }
      }),
    );
  }
}

/// DashedDivider copied from catalog_sort.dart
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final width = constraints.constrainWidth();
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final dashCount = (width / (dashWidth + dashSpace)).floor();

          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFCAD5D2)),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// MainHeading with a SecondaryButton on the right
class MainHeadingWithButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback? onAddNewItemPressed;

  const MainHeadingWithButton({
    super.key,
    required this.text,
    required this.iconPath,
    this.onAddNewItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title with icon on left
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF373C3A),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF373C3A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Helvetica Now Display',
                  ),
                ),
              ],
            ),

            // Add New Item button on right
            SecondaryButton.addNewItem(onPressed: onAddNewItemPressed),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 4,
          width: double.infinity,
          color: const Color(0xFFCAD5D2),
        ),
      ],
    );
  }
}
