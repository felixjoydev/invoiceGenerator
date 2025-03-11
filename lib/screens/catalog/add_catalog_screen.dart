import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/display/ItemDivider.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';

class AddCatalogScreen extends StatefulWidget {
  const AddCatalogScreen({super.key});

  @override
  State<AddCatalogScreen> createState() => _AddCatalogScreenState();
}

class _AddCatalogScreenState extends State<AddCatalogScreen> {
  // List to keep track of catalog items
  final List<CatalogItemInput> _catalogItems = [];
  int _itemCount = 0;

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
      _itemCount++;
      _catalogItems.add(
        CatalogItemInput(
          key: UniqueKey(),
          itemNumber: _itemCount,
          onDelete: () => _deleteItem(_itemCount),
        ),
      );
    });
  }

  // Delete a catalog item
  void _deleteItem(int itemNumber) {
    setState(() {
      // Find the index of the item with this number
      final index = _catalogItems.indexWhere(
        (item) => item.itemNumber == itemNumber,
      );
      if (index != -1) {
        _catalogItems.removeAt(index);
      }
    });
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // List of catalog item inputs
                    ..._catalogItems,

                    // 16px spacing before Add Item button
                    const SizedBox(height: 16),

                    // Add Item button
                    SecondaryButton.addItem(onPressed: _addNewItem),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that combines an ItemDivider and three text inputs for catalog items
class CatalogItemInput extends StatefulWidget {
  final int itemNumber;
  final VoidCallback onDelete;

  const CatalogItemInput({
    Key? key,
    required this.itemNumber,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<CatalogItemInput> createState() => _CatalogItemInputState();
}

class _CatalogItemInputState extends State<CatalogItemInput> {
  // Controllers for the text inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Item Divider
        ItemDivider(number: widget.itemNumber, onDelete: widget.onDelete),

        // 8px spacing after ItemDivider
        const SizedBox(height: 8),

        // Item Name input
        GenericInputField(
          label: 'ITEM NAME',
          hintText: 'Enter item name',
          controller: _nameController,
        ),

        // Price input
        GenericInputField(
          label: 'PRICE (USD)',
          hintText: 'Enter price',
          controller: _priceController,
        ),

        // Quantity input (pre-filled with "1")
        GenericInputField(
          label: 'QTY',
          hintText: '',
          controller: _qtyController,
        ),
      ],
    );
  }
}
