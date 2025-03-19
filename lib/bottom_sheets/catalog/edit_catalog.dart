// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

class EditCatalogSheet extends StatefulWidget {
  final CatalogItem item;
  final Function(CatalogItem)? onSave;
  final VoidCallback? onDelete;

  const EditCatalogSheet({
    super.key,
    required this.item,
    this.onSave,
    this.onDelete,
  });

  @override
  State<EditCatalogSheet> createState() => _EditCatalogSheetState();
}

class _EditCatalogSheetState extends State<EditCatalogSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final bool _isAtTop = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with item data
    _nameController.text = widget.item.title;
    _priceController.text = widget.item.amount.replaceAll(
      RegExp(r'[^\d.]'),
      '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (widget.onSave != null) {
      // Create updated item
      final updatedItem = CatalogItem(
        title: _nameController.text,
        amount: _priceController.text,
        currency: widget.item.currency,
        quantity: widget.item.quantity,
        usageInfo: widget.item.usageInfo,
        isNew: widget.item.isNew,
      );

      widget.onSave!(updatedItem);
    }
    Navigator.pop(context);
  }

  void _handleDelete() {
    if (widget.onDelete != null) {
      widget.onDelete!();
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maximum height (screen height - 80px)
    final double maxHeight = MediaQuery.of(context).size.height - 120;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Dismiss keyboard when dragging
        FocusScope.of(context).unfocus();
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fixed Header Section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with no icon
                                MainHeading.noIcon(text: 'Edit Catalog Item'),

                                // Add spacing between heading and input fields
                                SizedBox(height: 24),
                              ],
                            ),
                          ),

                          // Input Fields Section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              children: [
                                // Item Name field
                                GenericInputField(
                                  label: 'ITEM NAME',
                                  hintText: 'Enter item name',
                                  controller: _nameController,
                                ),

                                SizedBox(height: 16),

                                // Price field
                                GenericInputField(
                                  label: 'PRICE (USD)',
                                  hintText: 'Enter price',
                                  controller: _priceController,
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Spacer(),

                          // Delete button (stays in place with content)
                          SafeArea(
                            top: false,
                            child: Container(
                              width: double.infinity,
                              color: Color(0xFFDAE4E1),
                              padding: EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                90,
                              ), // Extra bottom padding for primary button
                              child: Align(
                                alignment: Alignment.center,
                                child: SecondaryButton(
                                  iconType: IconType.editBox,
                                  text: 'DELETE ITEM',
                                  color: Color(0xFFD61443),
                                  onPressed: _handleDelete,
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

            // Primary button positioned at the bottom, will float above keyboard
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  width: double.infinity,
                  color: Color(0xFFDAE4E1),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: SafeArea(
                    top: false,
                    child: PrimaryButton(
                      label: 'SAVE',
                      onPressed: _handleSave,
                      isEnabled: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the bottom sheet
void showEditCatalogSheet(
  BuildContext context, {
  required CatalogItem item,
  Function(CatalogItem)? onSave,
  VoidCallback? onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return EditCatalogSheet(item: item, onSave: onSave, onDelete: onDelete);
    },
  );
}
