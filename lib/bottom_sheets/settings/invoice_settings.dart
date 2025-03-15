import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/SmallHeading.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/new_item.dart';
import 'package:invoicegenerator/widgets/inputs/dropdown_input.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/screens/settings/settings_screen.dart';
import 'package:invoicegenerator/services/invoice_settings_service.dart';
import 'package:invoicegenerator/bottom_sheets/settings/invoice_id.dart';

class InvoiceSettingsSheet extends StatefulWidget {
  const InvoiceSettingsSheet({super.key});

  @override
  State<InvoiceSettingsSheet> createState() => _InvoiceSettingsSheetState();
}

class _InvoiceSettingsSheetState extends State<InvoiceSettingsSheet> {
  // Selected value for ID format
  String _selectedIdFormat = '001';

  // Text controller for custom notes
  final TextEditingController _notesController = TextEditingController();

  // Focus node for notes field
  final FocusNode _notesFocus = FocusNode();

  // Track if form has been modified
  bool _isFormModified = false;

  // Track if at top for drag to dismiss
  bool _isAtTop = true;
  final ScrollController _scrollController = ScrollController();

  // Invoice settings service
  final _invoiceSettingsService = InvoiceSettingsService();

  @override
  void initState() {
    super.initState();
    _loadInvoiceSettings();
    _scrollController.addListener(_scrollListener);
    _notesController.addListener(_markFormModified);
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

  // Load invoice settings from service
  Future<void> _loadInvoiceSettings() async {
    await _invoiceSettingsService.init();

    setState(() {
      _selectedIdFormat = _invoiceSettingsService.idFormat;
      _notesController.text = _invoiceSettingsService.customNotes ?? '';

      // If auto-generate is selected, show a preview of the ID format
      if (_invoiceSettingsService.isAutoGenerate) {
        final prefix = _invoiceSettingsService.idPrefix;
        _selectedIdFormat = '${prefix}00000';
      } else {
        _selectedIdFormat = 'Manual Entry';
      }
    });
  }

  // Mark form as modified when any field changes
  void _markFormModified() {
    if (!_isFormModified) {
      setState(() {
        _isFormModified = true;
      });
    }
  }

  // Handle ID format selection
  void _handleIdFormatSelected(String format) {
    setState(() {
      _selectedIdFormat = format;
      _markFormModified();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  // Handle back button press
  void _handleBackPressed() {
    Navigator.pop(context);

    // Show the settings bottom sheet again
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const SettingsScreen();
      },
    );
  }

  // Save changes
  Future<void> _saveChanges() async {
    // Save settings to service
    bool success = await _invoiceSettingsService.saveInvoiceSettings(
      idFormat: _selectedIdFormat,
      customNotes: _notesController.text,
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Changes saved successfully' : 'Failed to save changes',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reset form modified state
      setState(() {
        _isFormModified = false;
      });

      // Navigate back to settings screen
      _handleBackPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maximum height (screen height - 120px)
    final double maxHeight = MediaQuery.of(context).size.height - 120;

    // Get keyboard height to adjust padding
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (_isAtTop && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
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
                    color: const Color(0xFF373C3A),
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                const SizedBox(height: 12),
                // Main content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFDAE4E1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fixed Header Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: MainHeading(
                            text: 'Invoice Settings',
                            iconPath: 'assets/icons/back.svg',
                            onBackPressed: _handleBackPressed,
                          ),
                        ),

                        // Scrollable Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                              child: GestureDetector(
                                // Unfocus when tapping the scrollable area
                                onTap: () => FocusScope.of(context).unfocus(),
                                behavior: HitTestBehavior.translucent,
                                // Apply padding to the bottom when keyboard is visible
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        keyboardHeight > 0 ? keyboardHeight : 0,
                                  ),
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Invoice ID Format Section
                                        SizedBox(
                                          width: double.infinity,
                                          child: const SmallHeading(
                                            title: "Invoice ID Format",
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // ID Format Selector
                                        GestureDetector(
                                          onTap: () {
                                            // Close the settings sheet
                                            Navigator.pop(context);

                                            // Show the invoice ID format bottom sheet
                                            showInvoiceIdSheet(context);
                                          },
                                          child: GenericSelectorField(
                                            label: 'ID FORMAT',
                                            hintText: 'Select ID format',
                                            value: _selectedIdFormat,
                                          ),
                                        ),

                                        const SizedBox(height: 32),

                                        // Custom Notes Section
                                        SizedBox(
                                          width: double.infinity,
                                          child: const SmallHeading(
                                            title: "Custom Notes",
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Text Area for Notes with explanatory text as placeholder
                                        TextField(
                                          controller: _notesController,
                                          focusNode: _notesFocus,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Add any relevant notes (e.g. payment info, thank you message, etc.) The notes section on the invoice creation will be pre-filled.',
                                            hintStyle: TextStyle(
                                              fontFamily:
                                                  'Helvetica Now Display',
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
                                          minLines: 3,
                                          maxLines: 5,
                                          onChanged: (value) {
                                            _markFormModified();
                                          },
                                        ),

                                        // Extra space at bottom to ensure content isn't hidden by button
                                        const SizedBox(height: 100),
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
              ],
            ),

            // Save Changes button (only visible when form is modified)
            if (_isFormModified)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFDAE4E1),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: PrimaryButton(
                    label: 'SAVE CHANGES',
                    onPressed: _saveChanges,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper method to show the InvoiceSettingsSheet as a modal bottom sheet
void showInvoiceSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return const InvoiceSettingsSheet();
    },
  );
}
