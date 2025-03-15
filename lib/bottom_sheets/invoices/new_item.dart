import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:invoicegenerator/widgets/display/ItemDivider.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/services/catalog_service.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/invoice_item.dart';

class NewItemSheet extends StatefulWidget {
  final Function(List<CatalogItem>)? onItemsAdded;

  const NewItemSheet({super.key, this.onItemsAdded});

  @override
  State<NewItemSheet> createState() => _NewItemSheetState();
}

class _NewItemSheetState extends State<NewItemSheet> {
  // List to keep track of catalog items
  final List<CatalogItemInput> _catalogItems = [];

  // Service to manage catalog items
  final _catalogService = CatalogService();

  // Track if button should be enabled
  bool _isButtonEnabled = false;

  // Track if first item has content to show Add Item button
  bool _showAddItemButton = false;

  // Add scroll controller
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;

  @override
  void initState() {
    super.initState();
    // Add the first item by default
    _addNewItem(isInitialLoad: true);
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

  @override
  void dispose() {
    // Dispose the scroll controller
    _scrollController.dispose();
    super.dispose();
  }

  // Handle back button press
  void _handleBackPressed() {
    Navigator.pop(context);

    // Show the invoice item bottom sheet again
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return InvoiceItemSheet(
          onAddNewItemPressed: () {
            Navigator.pop(context);
            showNewItemSheet(context);
          },
        );
      },
    );
  }

  // Add a new catalog item input
  void _addNewItem({bool isInitialLoad = false}) {
    // Close keyboard when adding new item, but not during initial load
    if (!isInitialLoad) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      _catalogItems.add(
        CatalogItemInput(
          key: UniqueKey(),
          onDelete: (index) => _deleteItem(index),
          onFieldChanged: () {
            _validateForm();
            _checkFirstItemContent();
          },
          onItemFocused: _scrollToItem,
        ),
      );
      // Update all items to show delete button if more than one item
      _updateItems();
    });

    // Scroll to make the newly added item visible after the UI is updated
    // Use a slightly longer delay to ensure the UI is fully updated
    Future.delayed(Duration(milliseconds: 200), () {
      if (_scrollController.hasClients && mounted) {
        final int lastIndex = _catalogItems.length - 1;
        _scrollToItem(lastIndex);
      }
    });
  }

  // Delete a catalog item
  void _deleteItem(int index) {
    setState(() {
      if (index >= 0 && index < _catalogItems.length) {
        _catalogItems.removeAt(index);
        // Update all items after deletion
        _updateItems();
        // Re-validate form after deletion
        _validateForm();
        // Check first item content after deletion
        _checkFirstItemContent();
      }
    });
  }

  // Check if the first item has any content
  void _checkFirstItemContent() {
    if (_catalogItems.isNotEmpty) {
      final firstItem = _catalogItems[0];
      final hasContent =
          firstItem.nameController.text.isNotEmpty ||
          firstItem.priceController.text.isNotEmpty;

      setState(() {
        _showAddItemButton = hasContent;
      });
    } else {
      setState(() {
        _showAddItemButton = false;
      });
    }
  }

  // Update all items (set correct index and delete button visibility)
  void _updateItems() {
    // Only show delete buttons if there is more than one item
    final bool showDeleteButton = _catalogItems.length > 1;

    for (var i = 0; i < _catalogItems.length; i++) {
      _catalogItems[i] = CatalogItemInput(
        key: _catalogItems[i].key,
        itemNumber: i + 1, // 1-based indexing for display
        showDeleteButton: showDeleteButton,
        onDelete: (index) => _deleteItem(index),
        index: i, // Pass current index
        onFieldChanged: () {
          _validateForm();
          _checkFirstItemContent();
        },
        onItemFocused: _scrollToItem, // Add callback for when item is focused
        nameController: _catalogItems[i].nameController,
        priceController: _catalogItems[i].priceController,
        qtyController: _catalogItems[i].qtyController,
      );
    }
  }

  // Scroll to make a particular item visible
  void _scrollToItem(int index) {
    if (!mounted) return;

    // Schedule after frame update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index >= 0 &&
          index < _catalogItems.length &&
          _scrollController.hasClients &&
          mounted) {
        // Use a longer delay to ensure the keyboard is fully shown
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            final approximateItemHeight = 220.0;

            // Calculate the scroll offset to bring the desired item to the top
            // of the visible area with a small padding
            final targetOffset = (index * approximateItemHeight);

            // Use animateTo for smooth scrolling
            _scrollController.animateTo(
              max(0, targetOffset),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
  }

  // Validate form to enable/disable primary button
  void _validateForm() {
    bool isValid = false;

    // Check if at least one item has all required fields filled
    for (var item in _catalogItems) {
      if (item.isValid()) {
        isValid = true;
        break;
      }
    }

    setState(() {
      _isButtonEnabled = isValid;
    });
  }

  // Handle save to catalog
  void _saveToCatalog() {
    // Collect valid items
    List<CatalogItem> validItems = [];

    for (var item in _catalogItems) {
      if (item.isValid()) {
        // Convert input to CatalogItem
        validItems.add(
          CatalogItem(
            title: item.nameController.text,
            amount: item.priceController.text,
            quantity: int.tryParse(item.qtyController.text) ?? 1,
            // usageInfo defaults to 'USED IN 0 INVOICES' in the model
          ),
        );
      }
    }

    // Add to service
    if (validItems.isNotEmpty) {
      _catalogService.addItems(validItems);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item(s) added to catalog'),
          backgroundColor: Colors.green,
        ),
      );

      // Close the bottom sheet and pass the items back to the parent
      Navigator.pop(context);

      // Call the callback if it exists
      if (widget.onItemsAdded != null) {
        widget.onItemsAdded!(validItems);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maximum height (screen height - 80px)
    final double maxHeight = MediaQuery.of(context).size.height - 120;

    // Get keyboard height to adjust padding
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (_isAtTop && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      // Dismiss keyboard when tapping on sheet handle
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
        height: maxHeight,
        child: Stack(
          children: [
            // Main content column
            Column(
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
                                // Header with back button
                                MainHeading(
                                  text: 'Add New Item',
                                  iconPath: 'assets/icons/back.svg',
                                  onBackPressed: _handleBackPressed,
                                ),
                              ],
                            ),
                          ),

                          // Scrollable Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification
                                      is ScrollUpdateNotification) {
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
                                child: GestureDetector(
                                  // Unfocus when tapping the scrollable area
                                  onTap: () => FocusScope.of(context).unfocus(),
                                  behavior: HitTestBehavior.translucent,
                                  // Apply padding to the bottom when keyboard is visible
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          keyboardHeight > 0
                                              ? keyboardHeight
                                              : 0,
                                    ),
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      child: Column(
                                        children: [
                                          // Build List of catalog item inputs with spacing
                                          if (_catalogItems.isNotEmpty)
                                            ..._buildItemsWithSpacing(),

                                          // 16px spacing before Add Item button
                                          const SizedBox(height: 16),

                                          // Add Item button - centered, only shown when first item has content
                                          if (_showAddItemButton)
                                            Center(
                                              child: SecondaryButton.addItem(
                                                onPressed: _addNewItem,
                                              ),
                                            ),

                                          // Extra bottom spacing to ensure content is not hidden by the button
                                          const SizedBox(height: 120),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Primary button positioned at the bottom, will remain fixed at bottom of sheet
            Positioned(
              bottom: 0, // Fixed at bottom regardless of keyboard
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                color: Color(0xFFDAE4E1),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: PrimaryButton(
                  label: 'ADD ITEM TO INVOICE',
                  onPressed: _saveToCatalog,
                  isEnabled: _isButtonEnabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build catalog items with appropriate spacing between them
  List<Widget> _buildItemsWithSpacing() {
    final List<Widget> itemsWithSpacing = [];

    for (var i = 0; i < _catalogItems.length; i++) {
      // Add the item
      itemsWithSpacing.add(_catalogItems[i]);

      // Add spacing after each item except the last one
      if (i < _catalogItems.length - 1) {
        itemsWithSpacing.add(const SizedBox(height: 24));
      }
    }

    return itemsWithSpacing;
  }
}

/// A widget that combines an ItemDivider and two text inputs for catalog items
class CatalogItemInput extends StatefulWidget {
  final int itemNumber;
  final bool showDeleteButton;
  final Function(int) onDelete;
  final Function() onFieldChanged;
  final int index;
  final Function(int index)?
  onItemFocused; // Add callback for focus notification

  // Using late final instead of making them part of the constructor initialization
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController qtyController;

  CatalogItemInput({
    super.key,
    this.itemNumber = 1,
    this.showDeleteButton = false,
    required this.onDelete,
    required this.onFieldChanged,
    this.index = 0,
    this.onItemFocused,
    TextEditingController? nameController,
    TextEditingController? priceController,
    TextEditingController? qtyController,
  }) {
    this.nameController = nameController ?? TextEditingController();
    this.priceController = priceController ?? TextEditingController();
    this.qtyController = qtyController ?? TextEditingController(text: "1");
  }

  // Check if this item is valid (has all required fields)
  bool isValid() {
    return nameController.text.isNotEmpty && priceController.text.isNotEmpty;
    // QTY check removed since it's hidden with a default value of "1"
  }

  @override
  State<CatalogItemInput> createState() => _CatalogItemInputState();
}

class _CatalogItemInputState extends State<CatalogItemInput> {
  // Focus nodes for managing keyboard navigation
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  // Track quantity value
  int _quantity = 1;

  @override
  void initState() {
    super.initState();

    // Add listeners to controllers to validate on change
    widget.nameController.addListener(_onFieldChanged);
    widget.priceController.addListener(_onFieldChanged);
    widget.qtyController.addListener(_onFieldChanged);

    // Ensure QTY has a default value
    if (widget.qtyController.text.isEmpty) {
      widget.qtyController.text = "1";
    }

    // Initialize quantity from controller
    _quantity = int.tryParse(widget.qtyController.text) ?? 1;

    // Add focus listeners to scroll to visible area when field receives focus
    _nameFocus.addListener(_handleFocusChange);
    _priceFocus.addListener(_handleFocusChange);
  }

  void _onFieldChanged() {
    widget.onFieldChanged();
  }

  // Handle focus changes and ensure focused field is visible
  void _handleFocusChange() {
    // When a field receives focus, immediately notify parent to scroll this item into view
    if (_nameFocus.hasFocus || _priceFocus.hasFocus) {
      // Use a short delay to ensure the keyboard is fully shown before scrolling
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted && widget.onItemFocused != null) {
          widget.onItemFocused!(widget.index);
        }
      });
    }
  }

  // Decrease quantity (minimum 1)
  void _decreaseQuantity() {
    // Close keyboard when interacting with quantity
    FocusScope.of(context).unfocus();

    if (_quantity > 1) {
      setState(() {
        _quantity--;
        widget.qtyController.text = _quantity.toString();
      });
      _onFieldChanged();
    }
  }

  // Increase quantity
  void _increaseQuantity() {
    // Close keyboard when interacting with quantity
    FocusScope.of(context).unfocus();

    setState(() {
      _quantity++;
      widget.qtyController.text = _quantity.toString();
    });
    _onFieldChanged();
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_handleFocusChange);
    _priceFocus.removeListener(_handleFocusChange);
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Item Divider with delete button visibility controlled by showDeleteButton
        ItemDivider(
          number: widget.itemNumber,
          onDelete: () => widget.onDelete(widget.index),
          showDeleteButton: widget.showDeleteButton,
        ),

        // 8px spacing after ItemDivider
        const SizedBox(height: 8),

        // Item Name input
        GenericInputField(
          label: 'ITEM NAME',
          hintText: 'Enter item name',
          controller: widget.nameController,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _priceFocus.requestFocus();
          },
        ),

        // Price input (numbers only)
        GenericInputField(
          label: 'PRICE (USD)',
          hintText: 'Enter price',
          controller: widget.priceController,
          focusNode: _priceFocus,
          textInputAction: TextInputAction.done,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),

        // Quantity selector
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'QTY',
                    style: TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF373C3A),
                    ),
                  ),
                  Row(
                    children: [
                      // Minus button
                      GestureDetector(
                        onTap: _decreaseQuantity,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xFFCAD5D2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: Color(0xFF373C3A),
                          ),
                        ),
                      ),

                      // Quantity display
                      Container(
                        width: 40,
                        height: 32,
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF373C3A),
                          ),
                        ),
                      ),

                      // Plus button
                      GestureDetector(
                        onTap: _increaseQuantity,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xFFCAD5D2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: Color(0xFF373C3A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add dashed line
            SizedBox(
              height: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
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
            ),
          ],
        ),
      ],
    );
  }
}

/// MainHeading with back button for the bottom sheet
class MainHeading extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback? onBackPressed;

  const MainHeading({
    super.key,
    required this.text,
    required this.iconPath,
    this.onBackPressed,
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
                GestureDetector(
                  onTap: onBackPressed,
                  child: SizedBox(
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

/// Helper method to show the NewItemSheet as a modal bottom sheet
void showNewItemSheet(
  BuildContext context, {
  Function(List<CatalogItem>)? onItemsAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return NewItemSheet(onItemsAdded: onItemsAdded);
    },
  );
}
