import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/display/SmallHeading.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/inputs/dropdown_input.dart';
import 'package:invoicegenerator/widgets/inputs/date_input.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:invoicegenerator/widgets/inputs/toggle.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/invoice_item.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/select_client.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/new_client.dart'
    as new_client_sheet;
import 'package:invoicegenerator/bottom_sheets/invoices/new_item.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/editItem.dart';
import 'package:invoicegenerator/models/catalog_item.dart';
import 'package:invoicegenerator/models/client.dart';
// Import Hive client model with alias to avoid conflicts
import 'package:invoicegenerator/models/hive/client_model.dart' as hive;
import 'package:invoicegenerator/bottom_sheets/invoices/issue_date_picker.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/due_date_picker.dart';
import 'package:flutter/services.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:invoicegenerator/services/company_service.dart';
import 'package:invoicegenerator/services/invoice_settings_service.dart';
import 'package:invoicegenerator/widgets/invoice/invoice_preview.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
// Import Hive catalog item with alias
import 'package:invoicegenerator/models/catalog_item.dart' as old_model;

class InvoiceCreateScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;
  final int? returnTabIndex;

  const InvoiceCreateScreen({
    super.key,
    this.invoiceToEdit,
    this.returnTabIndex,
  });

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  // Text controllers for the input fields
  final TextEditingController _invoiceIdController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _taxPercentController = TextEditingController(
    text: '0.00',
  );

  // Selected customer
  String? _selectedCustomer;
  String? _selectedCustomerId;
  Client? _selectedClientObject;

  // List to store invoice items (empty for first-time users)
  final List<CatalogItem> _invoiceItems = [];

  // Tax toggle
  bool _isTaxEnabled = false;

  // Selected template
  String _selectedTemplate = 'Orange'; // Default template

  // Tax text field focus node to handle selection behavior
  final FocusNode _taxFocusNode = FocusNode();

  // Invoice settings service
  final _invoiceSettingsService = InvoiceSettingsService();

  // Flag for edit mode
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();

    // Check if we're in edit mode
    _isEditMode = widget.invoiceToEdit != null;

    if (_isEditMode) {
      // Populate form with existing invoice data
      _populateFormWithInvoice(widget.invoiceToEdit!);
    } else {
      // Set today's date as default for issue date and due date
      final now = DateTime.now();
      final formattedDate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      _issueDateController.text = formattedDate;
      _dueDateController.text = formattedDate;

      // Load invoice settings and initialize fields
      _initializeInvoiceSettings();
    }

    // Setup focus listener to select all text when tax field gets focus
    _taxFocusNode.addListener(() {
      if (_taxFocusNode.hasFocus) {
        // Select all text when field gets focus
        _taxPercentController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _taxPercentController.text.length,
        );
      }
    });
  }

  // Populate form with existing invoice data
  void _populateFormWithInvoice(Invoice invoice) {
    // Set invoice ID
    _invoiceIdController.text = invoice.invoiceId;

    // Set dates
    final dateFormat = DateFormat('dd/MM/yyyy');
    _issueDateController.text = dateFormat.format(invoice.issueDate);
    _dueDateController.text = dateFormat.format(invoice.dueDate);

    // Set client
    _selectedCustomer = invoice.client.name;
    _selectedCustomerId = invoice.client.clientId;
    _selectedClientObject = invoice.client;

    // Set invoice items
    _invoiceItems.addAll(invoice.items);

    // Set tax
    _isTaxEnabled = invoice.taxRate > 0;
    _taxPercentController.text = invoice.taxRate.toStringAsFixed(2);

    // Set notes
    if (invoice.notes != null) {
      _notesController.text = invoice.notes!;
    }

    // Set template
    _selectedTemplate = invoice.templateName;
  }

  // Initialize invoice settings
  Future<void> _initializeInvoiceSettings() async {
    try {
      await _invoiceSettingsService.init();

      if (mounted) {
        setState(() {
          // Set custom notes if available
          final savedNotes = _invoiceSettingsService.customNotes;
          _notesController.text = savedNotes;

          // Set invoice ID based on settings
          if (_invoiceSettingsService.isAutoGenerate) {
            // Use auto-generated ID
            _invoiceIdController.text =
                _invoiceSettingsService.generateNextInvoiceId();
          } else {
            // For manual mode, leave empty field for user to enter
            _invoiceIdController.text = '';
          }
        });
      }
    } catch (e) {
      print('Error initializing invoice settings: $e');
    }
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _issueDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _taxPercentController.dispose();
    _taxFocusNode.dispose();
    super.dispose();
  }

  // Handle back button press
  void _handleBackPressed() {
    Navigator.of(context).pop();
  }

  // Handle date field tap to show date picker
  void _showDatePicker(TextEditingController controller) {
    // Parse date from controller if available
    DateTime? initialDate;
    if (controller.text.isNotEmpty) {
      try {
        // Parse DD/MM/YYYY format
        final parts = controller.text.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          initialDate = DateTime(year, month, day);
        }
      } catch (e) {
        // If parsing fails, use current date
        initialDate = DateTime.now();
      }
    } else {
      // If no date set, use current date
      initialDate = DateTime.now();
    }

    if (controller == _issueDateController) {
      // For ISSUE DATE, use the IssueDatePickerSheet
      showIssueDatePicker(
        context,
        initialDate: initialDate,
        onDateSelected: (DateTime? selectedDate) {
          if (selectedDate != null) {
            // Format date as DD/MM/YYYY
            final day = selectedDate.day.toString().padLeft(2, '0');
            final month = selectedDate.month.toString().padLeft(2, '0');
            final year = selectedDate.year.toString();
            controller.text = '$day/$month/$year';

            // Update state to reflect the change
            setState(() {});
          }
        },
      );
    } else if (controller == _dueDateController) {
      // For DUE DATE, use the DueDatePickerSheet
      showDueDatePicker(
        context,
        initialDate: initialDate,
        onDateSelected: (DateTime? selectedDate) {
          if (selectedDate != null) {
            // Format date as DD/MM/YYYY
            final day = selectedDate.day.toString().padLeft(2, '0');
            final month = selectedDate.month.toString().padLeft(2, '0');
            final year = selectedDate.year.toString();
            controller.text = '$day/$month/$year';

            // Update state to reflect the change
            setState(() {});
          }
        },
      );
    } else {
      // For other date fields, keep current behavior
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date picker will open a bottom sheet'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Handle add item button press
  void _handleAddItemPressed() {
    // Open the InvoiceItemSheet bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return InvoiceItemSheet(
          onAddNewItemPressed: _handleAddNewItem,
          onItemsSelected: _handleItemsSelected,
          preSelectedItems: _invoiceItems,
        );
      },
    );
  }

  // Handle selected items from the InvoiceItemSheet
  void _handleItemsSelected(List<CatalogItem> selectedItems) {
    setState(() {
      // Always add all selected items at the beginning of the invoice list
      // This allows for multiple instances of the same catalog item
      // and ensures new items are always at the top
      _invoiceItems.insertAll(0, selectedItems);
    });
  }

  // Handle add new item button press from the InvoiceItemSheet
  void _handleAddNewItem() {
    // Show the new item bottom sheet
    showNewItemSheet(
      context,
      onItemsAdded: (items) {
        // Convert Hive catalog items to old model format
        final oldItems =
            items
                .map(
                  (item) => old_model.CatalogItem(
                    title: item.title,
                    amount: item.amount.toString(),
                    quantity: item.quantity,
                    currency: item.currency,
                  ),
                )
                .toList();

        // When items are added, select them in the invoice
        _handleItemsSelected(oldItems);
      },
    );
  }

  // Handle tax toggle change
  void _handleTaxToggleChanged(bool value) {
    setState(() {
      _isTaxEnabled = value;
      // Reset tax percent to 0.00 when disabled
      if (!value) {
        _taxPercentController.text = '0.00';
      }
    });
  }

  // Calculate subtotal from invoice items
  double get _subtotal {
    double total = 0;
    for (var item in _invoiceItems) {
      // Parse the amount (remove currency symbol if present)
      String amountStr = item.amount.replaceAll(RegExp(r'[^\d.]'), '');
      double amount = double.tryParse(amountStr) ?? 0;
      total += amount * item.quantity;
    }
    return total;
  }

  // Calculate tax amount
  double get _taxAmount {
    if (!_isTaxEnabled) return 0;

    double taxPercentage = double.tryParse(_taxPercentController.text) ?? 0;
    return _subtotal * (taxPercentage / 100);
  }

  // Calculate total amount
  double get _total {
    return _subtotal + _taxAmount;
  }

  // Format currency amount
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  // Handle customer selection
  void _handleCustomerSelected(Client client) {
    setState(() {
      _selectedCustomer = client.name;
      _selectedCustomerId = client.clientId;
      _selectedClientObject = client;
    });
  }

  // Show customer selector bottom sheet
  void _showCustomerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectClientSheet(
          onClientSelected: _handleCustomerSelected,
          preSelectedClientId: _selectedCustomerId,
          onAddNewClientPressed: () {
            // Show the new client bottom sheet directly
            new_client_sheet.showNewClientSheet(
              context,
              onClientAdded: (hiveClient) {
                // Convert Hive Client to the old Client model
                final client = _convertHiveClientToOldModel(hiveClient);
                // When client is added, select it in the invoice
                _handleCustomerSelected(client);
              },
            );
          },
        );
      },
    );
  }

  // Helper function to convert Hive Client to old Client model
  Client _convertHiveClientToOldModel(hive.Client hiveClient) {
    return Client(
      name: hiveClient.name,
      clientId: hiveClient.clientId,
      type: hiveClient.type,
      email: hiveClient.email,
      phone: hiveClient.phone,
      addressLine1: hiveClient.addressLine1,
      addressLine2: hiveClient.addressLine2,
      city: hiveClient.city,
      country: hiveClient.country,
      zip: hiveClient.zipCode,
      invoiceCount: hiveClient.invoiceCount,
      amount: hiveClient.amount,
      outstandingAmount: hiveClient.outstandingAmount,
      dueAmount: hiveClient.dueAmount,
    );
  }

  // Handle edit item
  void _handleEditItem(CatalogItem item, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditItemSheet(
          item: item,
          onSave: (updatedItem) {
            setState(() {
              // Update the item at the specific index
              _invoiceItems[index] = updatedItem;
            });
          },
          onDelete: () {
            setState(() {
              // Remove the item from the list
              _invoiceItems.removeAt(index);
            });
          },
        );
      },
    );
  }

  // Handle template selection
  void _handleTemplateSelected(String templateName) {
    setState(() {
      _selectedTemplate = templateName;
    });
  }

  // Add this method to find the template by name
  PdfTemplate _getTemplateByName(String name) {
    return PdfTemplate.allTemplates.firstWhere(
      (template) => template.name == name,
      orElse: () => PdfTemplate.defaultTemplate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // Wrap the body in a GestureDetector to dismiss keyboard when tapping outside
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside input fields
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Custom top navigation with back button on left and "Create Invoice" title
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
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF373C3A),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // 8px spacing
                    const Text(
                      'Create Invoice',
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

            // Content area with form fields
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 32px spacing after topnav
                      const SizedBox(height: 8),

                      // Invoice Information section
                      SizedBox(
                        width: double.infinity,
                        child: const SmallHeading(title: "Invoice Information"),
                      ),

                      // 4px spacing after heading (like in add_client_screen)
                      const SizedBox(height: 4),

                      // Customer selector
                      GestureDetector(
                        onTap: _showCustomerSelector,
                        child: GenericSelectorField(
                          label: 'SELECT CUSTOMER',
                          hintText: 'Select customer',
                          value: _selectedCustomer,
                        ),
                      ),

                      // Invoice ID field (pre-filled, disabled)
                      GenericInputField(
                        label: 'INVOICE ID',
                        hintText:
                            _invoiceSettingsService.isAutoGenerate
                                ? 'Auto-generated'
                                : 'Enter invoice ID',
                        controller: _invoiceIdController,
                        // Make it read-only only if auto-generate is enabled
                        readOnly: _invoiceSettingsService.isAutoGenerate,
                      ),

                      // Issue Date field using DateInput widget
                      DateInput(
                        label: 'ISSUE DATE',
                        hintText: 'DD/MM/YYYY',
                        controller: _issueDateController,
                        onTap: () => _showDatePicker(_issueDateController),
                        onChanged: (value) {
                          // Update the controller value
                          setState(() {
                            _issueDateController.text = value;
                          });
                        },
                      ),

                      // Due Date field using DateInput widget
                      DateInput(
                        label: 'DUE DATE',
                        hintText: 'DD/MM/YYYY',
                        controller: _dueDateController,
                        onTap: () => _showDatePicker(_dueDateController),
                        onChanged: (value) {
                          // Update the controller value
                          setState(() {
                            _dueDateController.text = value;
                          });
                        },
                      ),

                      // 32px spacing before Item Details section
                      const SizedBox(height: 32),

                      // Item Details section
                      SizedBox(
                        width: double.infinity,
                        child: const SmallHeading(title: "Item Details"),
                      ),

                      // 4px spacing after heading
                      const SizedBox(height: 4),

                      // Table Header Row
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                        child: Row(
                          children: [
                            // ITEM NAME column (aligned left, starting from edge)
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'ITEM NAME',
                                style: TextStyle(
                                  fontFamily: 'Victor Mono',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFF768581),
                                ),
                              ),
                            ),

                            // QTY column (aligned left in its space)
                            const SizedBox(
                              width: 60,
                              child: Text(
                                'QTY',
                                style: TextStyle(
                                  fontFamily: 'Victor Mono',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFF768581),
                                ),
                              ),
                            ),

                            // PRICE column (aligned left in its space)
                            const SizedBox(
                              width: 100,
                              child: Text(
                                'PRICE (USD)',
                                style: TextStyle(
                                  fontFamily: 'Victor Mono',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFF768581),
                                ),
                              ),
                            ),

                            // Space for chevron icon
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),

                      // Divider after header row
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFCAD5D2),
                      ),

                      // Show selected items or empty state
                      if (_invoiceItems.isEmpty)
                        // Empty state for first-time users
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: SecondaryButton.addNewItem(
                              onPressed: _handleAddItemPressed,
                            ),
                          ),
                        )
                      else
                        // Display selected invoice items with reordering capability
                        Column(
                          children: [
                            const SizedBox(height: 16),

                            // ReorderableListView for invoice items
                            ReorderableList(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _invoiceItems.length,
                              onReorderStart: (index) {
                                HapticFeedback.mediumImpact(); // Provide tactile feedback on drag start
                              },
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  final item = _invoiceItems.removeAt(oldIndex);
                                  _invoiceItems.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, index) {
                                return Column(
                                  key: ValueKey(
                                    _invoiceItems[index].title +
                                        index.toString(),
                                  ),
                                  children: [
                                    _buildInvoiceItemRow(
                                      _invoiceItems[index],
                                      index,
                                    ),
                                    if (index < _invoiceItems.length - 1)
                                      const DashedDivider(),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            // Regular divider above the Add Item button
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFCAD5D2),
                            ),
                            const SizedBox(height: 16),
                            // Add Item button
                            Align(
                              alignment: Alignment.center,
                              child: SecondaryButton.addNewItem(
                                onPressed: _handleAddItemPressed,
                              ),
                            ),
                          ],
                        ),
                      // Adjust spacing based on whether there are items or not
                      if (_invoiceItems.isEmpty)
                        // No additional spacing needed since the padding from Padding widget already adds 16px
                        const SizedBox.shrink()
                      else
                        const SizedBox(height: 16),

                      // Divider at the bottom of the items section
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFCAD5D2),
                      ),

                      // Keep 16px spacing after the divider
                      const SizedBox(height: 16),

                      // Only show subtotal, tax, and total sections if there are items
                      if (_invoiceItems.isNotEmpty) ...[
                        // SUBTOTAL row
                        Row(
                          children: [
                            // SUBTOTAL label (left)
                            const Expanded(
                              child: Text(
                                'SUBTOTAL',
                                style: TextStyle(
                                  fontFamily: 'Victor Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8D9694),
                                ),
                              ),
                            ),

                            // SUBTOTAL amount (right) - aligned with price column
                            SizedBox(
                              width:
                                  116, // 100 for price column + 16 for chevron icon space
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Add USD before subtotal amount
                                  const Text(
                                    'USD',
                                    style: TextStyle(
                                      fontFamily: 'Victor Mono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8D9694),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatAmount(_subtotal),
                                    style: const TextStyle(
                                      fontFamily: 'Helvetica Now Display',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF373C3A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // 16px spacing between rows
                        const SizedBox(height: 16),

                        // TAX row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // TAX label with toggle closer to it (left)
                            Expanded(
                              child: Row(
                                children: [
                                  const Text(
                                    'TAX',
                                    style: TextStyle(
                                      fontFamily: 'Victor Mono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8D9694),
                                    ),
                                  ),
                                  // Space between label and toggle
                                  const SizedBox(width: 8),
                                  // Custom tax toggle/checkbox
                                  CustomCheckbox(
                                    isChecked: _isTaxEnabled,
                                    onChanged: _handleTaxToggleChanged,
                                  ),
                                ],
                              ),
                            ),

                            // Tax percentage value - aligned with price column
                            SizedBox(
                              width:
                                  116, // 100 for price column + 16 for chevron icon space
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Tax percentage input with attached % symbol
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        // The text field takes most of the space
                                        TextField(
                                          controller: _taxPercentController,
                                          focusNode: _taxFocusNode,
                                          enabled: _isTaxEnabled,
                                          textAlign: TextAlign.left,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Helvetica Now Display',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                _isTaxEnabled
                                                    ? const Color(0xFF373C3A)
                                                    : const Color(0xFF8D9694),
                                          ),
                                        ),

                                        // Position the percentage symbol directly next to the text
                                        // We calculate estimated width of text to place % symbol
                                        Positioned(
                                          left:
                                              _taxPercentController
                                                  .text
                                                  .length *
                                              8.0, // Estimate width based on text length
                                          child: Text(
                                            '%',
                                            style: TextStyle(
                                              fontFamily:
                                                  'Helvetica Now Display',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  _isTaxEnabled
                                                      ? const Color(0xFF373C3A)
                                                      : const Color(0xFF8D9694),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // 16px spacing after tax row
                        const SizedBox(height: 16),

                        // Divider after tax row
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFCAD5D2),
                        ),

                        // 16px spacing after divider
                        const SizedBox(height: 16),

                        // TOTAL row
                        Row(
                          children: [
                            // TOTAL label (left)
                            const Expanded(
                              child: Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontFamily: 'Victor Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8D9694),
                                ),
                              ),
                            ),

                            // TOTAL amount with currency - aligned with price column
                            SizedBox(
                              width:
                                  116, // 100 for price column + 16 for chevron icon space
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'USD',
                                    style: TextStyle(
                                      fontFamily: 'Victor Mono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8D9694),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatAmount(_total),
                                    style: const TextStyle(
                                      fontFamily: 'Helvetica Now Display',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF373C3A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // 16px spacing after total row
                        const SizedBox(height: 16),

                        // Final divider
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFCAD5D2),
                        ),
                      ],

                      // 32px spacing before Notes section
                      const SizedBox(height: 32),

                      // Notes section
                      SizedBox(
                        width: double.infinity,
                        child: const SmallHeading(title: "Notes"),
                      ),

                      // 12px spacing after heading
                      const SizedBox(height: 12),

                      // Notes field
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText:
                              'Add any custom notes to include on this invoice',
                          hintStyle: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            fontSize: 16,
                            color: Color(0xFF8D9694),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF373C3A),
                        ),
                        minLines: 2,
                        maxLines: null, // Allow unlimited lines
                      ),

                      // 32px spacing before Template Selection section
                      const SizedBox(height: 32),

                      // Template Selection section
                      SizedBox(
                        width: double.infinity,
                        child: const SmallHeading(title: "Template Selection"),
                      ),

                      // 24px spacing after heading
                      const SizedBox(height: 24),

                      // Template previews in a horizontal scrollable row
                      SizedBox(
                        height:
                            172, // Increased from 162 to 172 to accommodate shadow
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                            ), // Add bottom padding for shadow
                            child: Row(
                              children: [
                                // Orange Template Preview
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: GestureDetector(
                                    onTap:
                                        () => _handleTemplateSelected('Orange'),
                                    child: _buildTemplatePreview(
                                      isSelected: _selectedTemplate == 'Orange',
                                      backgroundColor: const Color(0xFFE7E1CF),
                                      accentColor: const Color(0xFFCE5506),
                                      accentColorLight: const Color(0xFFE46512),
                                      dividerColor: const Color(0xFFF19F69),
                                    ),
                                  ),
                                ),

                                // Grey Template Preview
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: GestureDetector(
                                    onTap:
                                        () => _handleTemplateSelected('Grey'),
                                    child: _buildTemplatePreview(
                                      isSelected: _selectedTemplate == 'Grey',
                                      backgroundColor: const Color(0xFFDAE4E1),
                                      accentColor: const Color(0xFF373C3A),
                                      accentColorLight: const Color(0xFF768581),
                                      dividerColor: const Color(0xFFCAD5D2),
                                    ),
                                  ),
                                ),

                                // Blue Template Preview
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: GestureDetector(
                                    onTap:
                                        () => _handleTemplateSelected('Blue'),
                                    child: _buildTemplatePreview(
                                      isSelected: _selectedTemplate == 'Blue',
                                      backgroundColor: const Color(0xFFCFDBE7),
                                      accentColor: const Color(0xFF0C6AC9),
                                      accentColorLight: const Color(0xFF1981E9),
                                      dividerColor: const Color(0xFF4397EC),
                                    ),
                                  ),
                                ),

                                // Minimal Template Preview
                                GestureDetector(
                                  onTap:
                                      () => _handleTemplateSelected('Minimal'),
                                  child: _buildTemplatePreview(
                                    isSelected: _selectedTemplate == 'Minimal',
                                    backgroundColor: const Color(0xFFFFFFFF),
                                    accentColor: const Color(0xFF373C3A),
                                    accentColorLight: const Color(0xFF959595),
                                    dividerColor: const Color(0xFFE8E8E8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Add more spacing at the bottom for better visual appearance
                      const SizedBox(height: 32),

                      // Add Create Invoice button
                      PrimaryButton(
                        label:
                            _isEditMode ? 'UPDATE INVOICE' : 'CREATE INVOICE',
                        onPressed: _createInvoice,
                        isEnabled:
                            _selectedCustomer != null &&
                            _invoiceItems.isNotEmpty,
                      ),

                      const SizedBox(height: 16),
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

  // Create invoice and save it
  void _createInvoice() async {
    // Validate required fields
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a client')));
      return;
    }

    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    try {
      // Parse dates
      final dateFormat = DateFormat('dd/MM/yyyy');
      final issueDate = dateFormat.parse(_issueDateController.text);
      final dueDate = dateFormat.parse(_dueDateController.text);

      // Get company info for tax rate
      final companyService = CompanyService();
      await companyService.init();

      final companyInfo = companyService.companyInfo;
      if (companyInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company information not set')),
        );
        return;
      }

      // Get tax rate from the UI or company settings
      double taxRate = 0.0;
      if (_isTaxEnabled) {
        taxRate = double.tryParse(_taxPercentController.text) ?? 0.0;
      }

      // Initialize invoice service and generate ID
      final invoiceService = InvoiceService();
      await invoiceService.init();

      // Use custom invoice ID or generate a new one
      String invoiceId =
          _isEditMode
              ? _invoiceIdController.text
              : (_invoiceIdController.text.isNotEmpty
                  ? _invoiceIdController.text
                  : invoiceService.generateInvoiceId());

      // Create the invoice object
      final invoice = Invoice(
        invoiceId: invoiceId,
        client:
            _selectedClientObject ??
            Client(
              clientId: _selectedCustomerId ?? 'unknown',
              name: _selectedCustomer ?? 'Unknown Client',
              type: 'organization',
            ),
        issueDate: issueDate,
        dueDate: dueDate,
        items: List<CatalogItem>.from(_invoiceItems),
        subtotal: _subtotal,
        taxRate: taxRate,
        taxAmount: _taxAmount,
        total: _total,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        status:
            _isEditMode && widget.invoiceToEdit!.status == InvoiceStatus.paid
                ? InvoiceStatus.paid
                : _determineDueStatus(dueDate),
        templateName: _selectedTemplate, // Set the selected template
      );

      // Save the invoice
      bool success =
          _isEditMode
              ? await invoiceService.updateInvoice(invoice)
              : await invoiceService.addInvoice(invoice);

      if (success) {
        // If auto-generate is enabled, increment the last invoice number
        if (!_isEditMode && _invoiceSettingsService.isAutoGenerate) {
          await _invoiceSettingsService.incrementInvoiceNumber();
        }

        // Navigate to the preview screen
        if (mounted) {
          final logoPath = companyInfo.logoPath;

          debugPrint(
            'InvoiceCreateScreen - Opening preview with logo path: $logoPath',
          );
          if (logoPath != null) {
            final logoFile = File(logoPath);
            final exists = logoFile.existsSync();
            debugPrint(
              'InvoiceCreateScreen - Logo file exists: $exists (path: $logoPath)',
            );
          }

          // Get template object from template name
          _getTemplateByName(_selectedTemplate);

          // After successful save, navigate to invoice preview
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => InvoicePreview(
                    invoice: invoice,
                    companyInfo: companyInfo,
                    logoPath: logoPath,
                    returnTabIndex: widget.returnTabIndex ?? 0,
                  ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save invoice')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating invoice: $e')));
    }
  }

  // Determine invoice status based on due date
  InvoiceStatus _determineDueStatus(DateTime dueDate) {
    final now = DateTime.now();

    // If due date is in the past, it's overdue
    if (dueDate.isBefore(now)) {
      return InvoiceStatus.overdue;
    }

    // Otherwise it's outstanding
    return InvoiceStatus.outstanding;
  }

  // Build a row for an invoice item
  Widget _buildInvoiceItemRow(CatalogItem item, int index) {
    return ReorderableDelayedDragStartListener(
      index: index,
      key: ValueKey(item.title + index.toString()),
      child: GestureDetector(
        onTap: () => _handleEditItem(item, index),
        behavior: HitTestBehavior.opaque, // Make entire row area clickable
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: Row(
            children: [
              // Dragger icon with a visual cue that it's draggable
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 2.0,
                ),
                child: SvgPicture.asset(
                  'assets/icons/dragger.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF768581),
                    BlendMode.srcIn,
                  ),
                ),
              ),

              // 4px spacing after dragger icon
              const SizedBox(width: 4),

              // Item name (left aligned)
              Expanded(
                flex: 3,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Helvetica Now Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF373C3A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Quantity (left aligned in its space)
              SizedBox(
                width: 60,
                child: Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontFamily: 'Helvetica Now Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF373C3A),
                  ),
                ),
              ),

              // Price (left aligned in its space)
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Text(
                      item.currency,
                      style: const TextStyle(
                        fontFamily: 'Victor Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8D9694),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.amount,
                      style: const TextStyle(
                        fontFamily: 'Helvetica Now Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF373C3A),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron right icon
              SvgPicture.asset(
                'assets/icons/chevron-right.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF373C3A),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a template preview
  Widget _buildTemplatePreview({
    required bool isSelected,
    required Color backgroundColor,
    required Color accentColor,
    required Color accentColorLight,
    required Color dividerColor,
  }) {
    return Stack(
      children: [
        // Template container
        Container(
          width: 114,
          height: 162,
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(128, 128, 128, 0.08),
                blurRadius: 0,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: const Color.fromRGBO(128, 128, 128, 0.08),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: const Color.fromRGBO(128, 128, 128, 0.08),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: const Color.fromRGBO(128, 128, 128, 0.08),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),

        // Selection border - pixelated
        if (isSelected) ...[
          // Draw individual "pixel" squares for the border - Top row
          ...List.generate(
            57,
            (index) => Positioned(
              top: 0,
              left: index * 2.0,
              child: Container(
                width: 2,
                height: 2,
                color: const Color(0xFFF05022),
              ),
            ),
          ),

          // Bottom row
          ...List.generate(
            57,
            (index) => Positioned(
              top: 160,
              left: index * 2.0,
              child: Container(
                width: 2,
                height: 2,
                color: const Color(0xFFF05022),
              ),
            ),
          ),

          // Left column
          ...List.generate(
            80,
            (index) => Positioned(
              top: index * 2.0 + 2,
              left: 0,
              child: Container(
                width: 2,
                height: 2,
                color: const Color(0xFFF05022),
              ),
            ),
          ),

          // Right column
          ...List.generate(
            80,
            (index) => Positioned(
              top: index * 2.0 + 2,
              left: 112,
              child: Container(
                width: 2,
                height: 2,
                color: const Color(0xFFF05022),
              ),
            ),
          ),
        ],

        // Template content
        Positioned(
          top: 2,
          left: 2,
          child: Container(
            width: 110,
            height: 158,
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Invoice" title
                      Expanded(
                        child: Text(
                          'Invoice',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Logo placeholder
                      Container(
                        width: 24,
                        height: 16,
                        color: accentColor,
                        alignment: Alignment.center,
                        child: Text(
                          'LOGO',
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            color: Colors.white,
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Client & Company info placeholder
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client info
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILL TO',
                              style: TextStyle(
                                fontFamily: 'Victor Mono',
                                color: accentColorLight,
                                fontSize: 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Client Name',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Address',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                            Text(
                              'City, Country',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Company info
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Your Company',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Company Address',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                            Text(
                              'M: 555-1234',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                            Text(
                              'E: email@example.com',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Invoice details
                  const SizedBox(height: 4),
                  Container(
                    height: 0.3,
                    color: dividerColor,
                  ), // Thinner divider
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVOICE ID',
                            style: TextStyle(
                              fontFamily: 'Victor Mono',
                              color: accentColorLight,
                              fontSize: 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'INV-001',
                            style: TextStyle(
                              fontFamily: 'Helvetica Now Display',
                              color: accentColor,
                              fontSize: 3,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISSUE DATE',
                            style: TextStyle(
                              fontFamily: 'Victor Mono',
                              color: accentColorLight,
                              fontSize: 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '01/01/2023',
                            style: TextStyle(
                              fontFamily: 'Helvetica Now Display',
                              color: accentColor,
                              fontSize: 3,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DUE DATE',
                            style: TextStyle(
                              fontFamily: 'Victor Mono',
                              color: accentColorLight,
                              fontSize: 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '15/01/2023',
                            style: TextStyle(
                              fontFamily: 'Helvetica Now Display',
                              color: accentColor,
                              fontSize: 3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 0.3,
                    color: dividerColor,
                  ), // Thinner divider
                  // Item header
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'ITEM NAME',
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            color: accentColorLight,
                            fontSize: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'QTY',
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            color: accentColorLight,
                            fontSize: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'PRICE',
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            color: accentColorLight,
                            fontSize: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 0.5,
                    color: dividerColor,
                  ), // Thinner thick divider
                  // Items
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Service Item 1',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            color: accentColor,
                            fontSize: 3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '2',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            color: accentColor,
                            fontSize: 3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                fontFamily: 'Victor Mono',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                            Text(
                              ' 100.00',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 0.2,
                    color: dividerColor.withOpacity(0.5),
                  ), // Even thinner divider
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Product Item 2',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            color: accentColor,
                            fontSize: 3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '1',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            color: accentColor,
                            fontSize: 3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                fontFamily: 'Victor Mono',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                            Text(
                              ' 50.00',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                color: accentColor,
                                fontSize: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Totals section
                  const SizedBox(height: 2),
                  Container(
                    height: 0.5,
                    color: dividerColor,
                  ), // Thinner thick divider
                  const SizedBox(height: 2),
                  // Subtotal
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SUBTOTAL',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            color: accentColorLight,
                            fontSize: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'USD',
                        style: TextStyle(
                          fontFamily: 'Victor Mono',
                          color: accentColor,
                          fontSize: 3,
                        ),
                      ),
                      Text(
                        ' 250.00',
                        style: TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          color: accentColor,
                          fontSize: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  // Total
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TOTAL',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            color: accentColorLight,
                            fontSize: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'USD',
                        style: TextStyle(
                          fontFamily: 'Victor Mono',
                          color: accentColor,
                          fontSize: 3,
                        ),
                      ),
                      Text(
                        ' 250.00',
                        style: TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          color: accentColor,
                          fontSize: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Notes section
                  const SizedBox(height: 3),
                  Text(
                    'NOTES',
                    style: TextStyle(
                      fontFamily: 'Victor Mono',
                      color: accentColorLight,
                      fontSize: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    height: 0.3,
                    color: dividerColor,
                  ), // Thinner divider
                  const SizedBox(height: 1),
                  Text(
                    'Thank you for your business.',
                    style: TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      color: accentColor,
                      fontSize: 3,
                    ),
                  ),
                  Text(
                    'Payment due within 15 days.',
                    style: TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      color: accentColor,
                      fontSize: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom dashed divider for invoice items
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      child: SizedBox(
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
      ),
    );
  }
}
