import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/display/SmallHeading.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/new_item.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/bottom_sheets/settings/invoice_settings.dart';
import 'package:invoicegenerator/services/invoice_settings_service.dart';
import 'package:invoicegenerator/services/company_service.dart';

class InvoiceIdSheet extends StatefulWidget {
  const InvoiceIdSheet({super.key});

  @override
  State<InvoiceIdSheet> createState() => _InvoiceIdSheetState();
}

class _InvoiceIdSheetState extends State<InvoiceIdSheet> {
  // Controllers for text fields
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _numberController = TextEditingController(
    text: '00000',
  );

  // Focus nodes
  final FocusNode _prefixFocus = FocusNode();

  // Selected mode
  bool _isAutoGenerate = true;

  // Track if form has been modified
  bool _isFormModified = false;

  // Track if at top for drag to dismiss
  bool _isAtTop = true;
  final ScrollController _scrollController = ScrollController();

  // Invoice settings service
  final _invoiceSettingsService = InvoiceSettingsService();
  // Company service to get company name
  final _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scrollController.addListener(_scrollListener);
    _prefixController.addListener(_markFormModified);
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

  // Load settings and company info
  Future<void> _loadSettings() async {
    await _invoiceSettingsService.init();
    await _companyService.init();

    // Load ID format (assuming we add these fields to the service)
    if (mounted) {
      setState(() {
        // Check if auto generate is enabled in settings
        _isAutoGenerate = _invoiceSettingsService.isAutoGenerate ?? true;

        // Set prefix - if available in settings or generate from company name
        if (_invoiceSettingsService.idPrefix != null &&
            _invoiceSettingsService.idPrefix!.isNotEmpty) {
          _prefixController.text = _invoiceSettingsService.idPrefix!;
        } else {
          // Get first 3 letters of company name
          final companyInfo = _companyService.companyInfo;
          if (companyInfo != null && companyInfo.businessName.isNotEmpty) {
            final companyName = companyInfo.businessName.toUpperCase();
            _prefixController.text =
                companyName.length > 3
                    ? companyName.substring(0, 3)
                    : companyName;
          } else {
            _prefixController.text = 'INV'; // Default if no company name
          }
        }
      });
    }
  }

  // Mark form as modified when any field changes
  void _markFormModified() {
    if (!_isFormModified) {
      setState(() {
        _isFormModified = true;
      });
    }
  }

  // Toggle between auto generate and manual
  void _toggleAutoGenerate(bool value) {
    setState(() {
      _isAutoGenerate = value;
      _markFormModified();
    });
  }

  // Validate prefix input - should be alpha-numeric, max 3 chars
  bool _validatePrefix() {
    if (_prefixController.text.isEmpty) {
      return false;
    }

    // Trim to 3 characters if longer
    if (_prefixController.text.length > 3) {
      setState(() {
        _prefixController.text = _prefixController.text.substring(0, 3);
      });
    }

    // Convert to uppercase
    if (_prefixController.text != _prefixController.text.toUpperCase()) {
      setState(() {
        _prefixController.text = _prefixController.text.toUpperCase();
      });
    }

    return true;
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _numberController.dispose();
    _prefixFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Handle back button press
  void _handleBackPressed() {
    Navigator.pop(context);

    // Show the invoice settings bottom sheet again
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const InvoiceSettingsSheet();
      },
    );
  }

  // Save changes
  Future<void> _saveChanges() async {
    // Validate the prefix if auto generate is enabled
    if (_isAutoGenerate && !_validatePrefix()) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid prefix (max 3 characters)'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Save settings to service
    bool success = await _invoiceSettingsService.saveInvoiceIdSettings(
      isAutoGenerate: _isAutoGenerate,
      idPrefix: _prefixController.text,
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

      // Navigate back to invoice settings screen
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
                            text: 'Invoice ID Format',
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
                                        // Auto Generate Section
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // Title text only
                                                Expanded(
                                                  child: Text(
                                                    "Auto Generate",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                        118,
                                                        133,
                                                        129,
                                                        1,
                                                      ),
                                                      fontFamily:
                                                          'Helvetica Now Display',
                                                    ),
                                                  ),
                                                ),
                                                // Checkbox for selection
                                                GestureDetector(
                                                  onTap:
                                                      () => _toggleAutoGenerate(
                                                        true,
                                                      ),
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    child: SvgPicture.asset(
                                                      _isAutoGenerate
                                                          ? 'assets/icons/checked.svg'
                                                          : 'assets/icons/unchecked.svg',
                                                      width: 24,
                                                      height: 24,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // The divider (separate from the text)
                                            Container(
                                              width: double.infinity,
                                              height: 4,
                                              color: Color.fromRGBO(
                                                202,
                                                213,
                                                210,
                                                1,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Auto Generate fields (visible only when auto generate is selected)
                                        if (_isAutoGenerate) ...[
                                          const SizedBox(height: 8),

                                          // PREFIX input
                                          GenericInputField(
                                            label: 'PREFIX',
                                            hintText: 'Enter prefix',
                                            controller: _prefixController,
                                            focusNode: _prefixFocus,
                                            textInputAction:
                                                TextInputAction.done,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                3,
                                              ),
                                            ],
                                          ),

                                          // NUMBER input (non-editable)
                                          GenericInputField(
                                            label: 'NUMBER',
                                            hintText: '00000',
                                            controller: _numberController,
                                            readOnly: true,
                                            textInputAction:
                                                TextInputAction.none,
                                          ),
                                        ],

                                        const SizedBox(height: 32),

                                        // Add Manually Section
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // Title text only
                                                Expanded(
                                                  child: Text(
                                                    "Add Manually",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                        118,
                                                        133,
                                                        129,
                                                        1,
                                                      ),
                                                      fontFamily:
                                                          'Helvetica Now Display',
                                                    ),
                                                  ),
                                                ),
                                                // Checkbox for selection
                                                GestureDetector(
                                                  onTap:
                                                      () => _toggleAutoGenerate(
                                                        false,
                                                      ),
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    child: SvgPicture.asset(
                                                      !_isAutoGenerate
                                                          ? 'assets/icons/checked.svg'
                                                          : 'assets/icons/unchecked.svg',
                                                      width: 24,
                                                      height: 24,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // The divider (separate from the text)
                                            Container(
                                              width: double.infinity,
                                              height: 4,
                                              color: Color.fromRGBO(
                                                202,
                                                213,
                                                210,
                                                1,
                                              ),
                                            ),
                                          ],
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
                  child: PrimaryButton(label: 'SAVE', onPressed: _saveChanges),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper method to show the InvoiceIdSheet as a modal bottom sheet
void showInvoiceIdSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return const InvoiceIdSheet();
    },
  );
}
