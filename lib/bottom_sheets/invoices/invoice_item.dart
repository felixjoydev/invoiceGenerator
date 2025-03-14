import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/actions/ItemAdd.dart';
import 'package:invoicegenerator/services/catalog_service.dart';
import 'package:invoicegenerator/models/catalog_item.dart';

// Helper class to track item selection info
class SelectedItemInfo {
  final CatalogItem item;
  int quantity;
  bool isSelected;

  SelectedItemInfo(this.item, this.quantity, this.isSelected);
}

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
  List<CatalogItem> _newlySelectedItems = []; // Items to be returned to parent

  // Track each item in the list with a unique identifier
  Map<String, SelectedItemInfo> _selectedItemsMap = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize with empty selection states
    _newlySelectedItems = [];
    _selectedItemsMap = {};

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

  // Toggle item selection and track it in our maps
  void _toggleItemSelection(CatalogItem item, String itemKey) {
    setState(() {
      // If the item is not in our map, add it as selected
      if (!_selectedItemsMap.containsKey(itemKey)) {
        // Create a new instance with quantity 1 initially
        final selectedItem = item.copyWith(quantity: 1);
        _selectedItemsMap[itemKey] = SelectedItemInfo(selectedItem, 1, true);

        // Make sure we don't have an existing item with the same title
        // since we want to maintain exactly one entry per selection in the UI
        bool found = false;

        // Check if we already have this item in the list
        for (int i = 0; i < _newlySelectedItems.length; i++) {
          if (_newlySelectedItems[i].title == item.title &&
              _selectedItemsMap.values.any(
                (info) =>
                    info.item.title == item.title &&
                    info.isSelected &&
                    identical(info.item, _newlySelectedItems[i]),
              )) {
            found = true;
            break;
          }
        }

        if (!found) {
          // If not found, add a new entry
          _newlySelectedItems.add(selectedItem);
        }
      } else {
        // Item exists, toggle its selection state
        final info = _selectedItemsMap[itemKey]!;
        info.isSelected = !info.isSelected;

        if (info.isSelected) {
          // If selecting, set quantity to 1
          info.quantity = 1;

          // Check if we already have an item with this title
          bool found = false;
          for (int i = 0; i < _newlySelectedItems.length; i++) {
            if (_newlySelectedItems[i].title == item.title) {
              found = true;
              break;
            }
          }

          if (!found) {
            // Only add to the list if we don't already have it
            _newlySelectedItems.add(item.copyWith(quantity: 1));
          }
        } else {
          // If deselecting, set quantity to 0
          info.quantity = 0;

          // Look for this specific item key in our map of selected items
          bool otherSelectionsExist = false;
          for (var mapKey in _selectedItemsMap.keys) {
            if (mapKey != itemKey &&
                _selectedItemsMap[mapKey]!.item.title == item.title &&
                _selectedItemsMap[mapKey]!.isSelected) {
              otherSelectionsExist = true;
              break;
            }
          }

          // Only remove from _newlySelectedItems if there are no other
          // selections of this item
          if (!otherSelectionsExist) {
            for (int i = 0; i < _newlySelectedItems.length; i++) {
              if (_newlySelectedItems[i].title == item.title) {
                _newlySelectedItems.removeAt(i);
                break;
              }
            }
          }
        }
      }
    });
  }

  // Update the quantity of a selected item
  void _handleQuantityChanged(
    CatalogItem item,
    String itemKey,
    int newQuantity,
  ) {
    setState(() {
      if (_selectedItemsMap.containsKey(itemKey)) {
        final info = _selectedItemsMap[itemKey]!;

        if (newQuantity > 0) {
          // Update quantity in our selection map
          info.quantity = newQuantity;
          info.isSelected = true;

          // Find the selected item in our list by title
          int index = -1;
          for (int i = 0; i < _newlySelectedItems.length; i++) {
            if (_newlySelectedItems[i].title == item.title) {
              index = i;
              break;
            }
          }

          if (index >= 0) {
            // We only maintain one item per title in the list
            // So we'll update its quantity
            _newlySelectedItems[index] = item.copyWith(quantity: newQuantity);
          } else {
            // If this item isn't in the list yet, add it
            _newlySelectedItems.add(item.copyWith(quantity: newQuantity));
          }
        } else {
          // If quantity becomes 0, deselect this item
          info.quantity = 0;
          info.isSelected = false;

          // Check if any other items with the same title are still selected
          bool anySelected = false;
          for (var mapKey in _selectedItemsMap.keys) {
            if (_selectedItemsMap[mapKey]!.item.title == item.title &&
                _selectedItemsMap[mapKey]!.isSelected) {
              anySelected = true;
              break;
            }
          }

          // If no other items with this title are selected, remove from the list
          if (!anySelected) {
            for (int i = 0; i < _newlySelectedItems.length; i++) {
              if (_newlySelectedItems[i].title == item.title) {
                _newlySelectedItems.removeAt(i);
                break;
              }
            }
          }
        }
      }
    });
  }

  // Close the sheet and pass selected items back to parent
  void _applySelection() {
    // Create copies of selected items to be added to the invoice
    final List<CatalogItem> itemsToReturn = [];

    // Process all selected items with quantity > 0
    for (int i = 0; i < _newlySelectedItems.length; i++) {
      final item = _newlySelectedItems[i];
      if (item.quantity > 0) {
        // Create a copy of the item with the correct quantity
        // Each copy will be treated as a new item when added to the invoice
        final selectedItem = CatalogItem(
          title: item.title,
          amount: item.amount,
          quantity: item.quantity,
          currency: item.currency,
          usageInfo: item.usageInfo,
          isNew: item.isNew,
        );

        itemsToReturn.add(selectedItem);
      }
    }

    if (widget.onItemsSelected != null && itemsToReturn.isNotEmpty) {
      widget.onItemsSelected!(itemsToReturn);
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

    // Count the number of unique item titles selected with quantity > 0
    final selectedItems =
        _newlySelectedItems.where((item) => item.quantity > 0).toList();

    // Count by unique title
    final Map<String, int> titleCount = {};
    for (var item in selectedItems) {
      titleCount[item.title] = (titleCount[item.title] ?? 0) + 1;
    }
    final int newlySelectedCount = titleCount.length;

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
      child: SizedBox(
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
                      if (_newlySelectedItems
                          .where((item) => item.quantity > 0)
                          .isNotEmpty)
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

          // Create a unique identifier for this specific item instance
          final itemKey = "${item.title}-${itemIndex}";

          // Check if this specific item has been selected
          bool isSelected = false;
          int quantity = 0;

          if (_selectedItemsMap.containsKey(itemKey)) {
            final info = _selectedItemsMap[itemKey]!;
            isSelected = info.isSelected;
            quantity = info.quantity;
          }

          return ItemAdd(
            key: ValueKey(itemKey),
            title: item.title,
            amount: item.amount,
            currency: item.currency,
            isSelected: isSelected,
            initialQuantity: quantity,
            isAlreadyAdded:
                false, // Always allow items to be added multiple times
            onSelect: () {
              _toggleItemSelection(item, itemKey);
            },
            onQuantityChanged: (newQuantity) {
              _handleQuantityChanged(item, itemKey, newQuantity);
            },
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
