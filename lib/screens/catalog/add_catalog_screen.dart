import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/display/ItemDivider.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';

class AddCatalogScreen extends StatefulWidget {
  const AddCatalogScreen({super.key});

  @override
  State<AddCatalogScreen> createState() => _AddCatalogScreenState();
}

class _AddCatalogScreenState extends State<AddCatalogScreen> {
  // List to keep track of catalog items
  final List<CatalogItemInput> _catalogItems = [];

  @override
  void initState() {
    super.initState();
    // Add the first item by default
    _addNewItem();
  }

  // Handle back button press
  void _handleBackPressed() {
    Navigator.of(context).pop();
  }

  // Add a new catalog item input
  void _addNewItem() {
    setState(() {
      _catalogItems.add(
        CatalogItemInput(
          key: UniqueKey(),
          onDelete: (index) => _deleteItem(index),
        ),
      );
      // Update all items to show delete button if more than one item
      _updateItems();
    });
  }

  // Delete a catalog item
  void _deleteItem(int index) {
    setState(() {
      if (index >= 0 && index < _catalogItems.length) {
        _catalogItems.removeAt(index);
        // Update all items after deletion
        _updateItems();
      }
    });
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Custom top navigation with back button on left and "Add Catalog Item" title
          SafeArea(
            bottom: false,
            child: NavContainer(
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: _handleBackPressed,
                    child: SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        const Color(0xFF373C3A),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // 8px spacing
                  const Text(
                    'Add Catalog Item',
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
            ),
          ),

          // 8px spacing after TopNav
          const SizedBox(height: 8),

          // Content area with catalog item inputs and add button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Build List of catalog item inputs with spacing
                    if (_catalogItems.isNotEmpty) ..._buildItemsWithSpacing(),

                    // 16px spacing before Add Item button
                    const SizedBox(height: 16),

                    // Add Item button - centered
                    Center(
                      child: SecondaryButton.addItem(onPressed: _addNewItem),
                    ),

                    // 40px bottom spacing
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Primary Button at bottom
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PrimaryButton(
                label: 'ADD TO CATALOG',
                onPressed: () {
                  // Add to catalog functionality will go here
                },
              ),
            ),
          ),
        ],
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

/// A widget that combines an ItemDivider and three text inputs for catalog items
class CatalogItemInput extends StatefulWidget {
  final int itemNumber;
  final bool showDeleteButton;
  final Function(int) onDelete;
  final int index;

  const CatalogItemInput({
    Key? key,
    this.itemNumber = 1,
    this.showDeleteButton = false,
    required this.onDelete,
    this.index = 0,
  }) : super(key: key);

  @override
  State<CatalogItemInput> createState() => _CatalogItemInputState();
}

class _CatalogItemInputState extends State<CatalogItemInput> {
  // Controllers for the text inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  // Focus nodes for managing keyboard navigation
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _qtyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill QTY with "1"
    _qtyController.text = "1";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    _qtyFocus.dispose();
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
          controller: _nameController,
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
          controller: _priceController,
          focusNode: _priceFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _qtyFocus.requestFocus();
          },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),

        // Quantity input (pre-filled with "1", numbers only)
        GenericInputField(
          label: 'QTY',
          hintText: '',
          controller: _qtyController,
          focusNode: _qtyFocus,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }
}
