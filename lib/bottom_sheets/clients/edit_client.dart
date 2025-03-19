import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:invoicegenerator/widgets/display/SmallHeading.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/client_service.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

class EditClientSheet extends StatefulWidget {
  final Client client;
  final Function(Client)? onClientUpdated;
  final Function()? onClientDeleted;

  const EditClientSheet({
    super.key,
    required this.client,
    this.onClientUpdated,
    this.onClientDeleted,
  });

  @override
  State<EditClientSheet> createState() => _EditClientSheetState();
}

class _EditClientSheetState extends State<EditClientSheet> {
  // Text controllers for the input fields
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;

  // Focus nodes for keyboard navigation between fields
  final FocusNode _organizationNameFocus = FocusNode();
  final FocusNode _taxIdFocus = FocusNode();
  final FocusNode _addressLine1Focus = FocusNode();
  final FocusNode _addressLine2Focus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _zipFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _websiteFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  // Selected country
  String? _selectedCountry;

  // Validation state and messages
  bool _isZipValid = true;
  String? _zipErrorMessage;
  String? _phoneErrorMessage;
  String? _emailErrorMessage;
  String? _websiteErrorMessage;

  // Track if button should be enabled
  bool _isButtonEnabled = false;

  // Service to manage clients
  final _clientService = ClientService();

  @override
  void initState() {
    super.initState();

    // Initialize the client service if needed
    _initClientService();

    // Prefill fields with client data
    _prefillClientData();

    // Add listeners to controllers for validation
    _organizationNameController.addListener(_validateForm);
    _addressLine1Controller.addListener(_validateForm);
    _emailController.addListener(_validateForm);

    // Set up focus node listeners for keyboard navigation
    _taxIdFocus.addListener(() {
      if (!_taxIdFocus.hasFocus) {
        // When tax ID loses focus (done pressed), move to next section's first field
        FocusScope.of(context).unfocus();
      }
    });

    _zipFocus.addListener(() {
      if (!_zipFocus.hasFocus) {
        // When ZIP loses focus (done pressed), move to next section's first field
        FocusScope.of(context).unfocus();
      }
    });

    _websiteFocus.addListener(() {
      if (!_websiteFocus.hasFocus) {
        // When website loses focus (done pressed), move to notes
        FocusScope.of(context).unfocus();
      }
    });

    _scrollController.addListener(_scrollListener);

    // Initial validation
    _validateForm();
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
    // Dispose all controllers
    _organizationNameController.dispose();
    _clientIdController.dispose();
    _taxIdController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _scrollController.dispose();

    // Dispose all focus nodes
    _organizationNameFocus.dispose();
    _taxIdFocus.dispose();
    _addressLine1Focus.dispose();
    _addressLine2Focus.dispose();
    _cityFocus.dispose();
    _zipFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _websiteFocus.dispose();
    _notesFocus.dispose();

    super.dispose();
  }

  // Prefill fields with client data
  void _prefillClientData() {
    _organizationNameController.text = widget.client.name;
    _clientIdController.text = widget.client.clientId;
    _taxIdController.text = widget.client.taxId ?? '';
    _selectedCountry = widget.client.country;
    _addressLine1Controller.text = widget.client.addressLine1 ?? '';
    _addressLine2Controller.text = widget.client.addressLine2 ?? '';
    _cityController.text = widget.client.city ?? '';
    _zipController.text = widget.client.zip ?? '';
    _phoneController.text = widget.client.phone ?? '';
    _emailController.text = widget.client.email ?? '';
    _websiteController.text = widget.client.website ?? '';
    _notesController.text = widget.client.notes ?? '';
  }

  // Handle back button press
  void _handleBackPressed() {
    Navigator.pop(context);
  }

  // Validate form to enable/disable primary button
  void _validateForm() {
    // Basic validation - check if name field is filled
    bool isValid = _organizationNameController.text.isNotEmpty;

    setState(() {
      _isButtonEnabled = isValid;
    });
  }

  // ZIP code validation patterns for different countries
  final Map<String, Pattern> _zipPatterns = {
    'US': r'^\d{5}(-\d{4})?$', // US: 12345 or 12345-6789
    'UK':
        r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$', // UK: AA9A 9AA, A9A 9AA, A9 9AA, A99 9AA, AA9 9AA, AA99 9AA
    'CA':
        r'^[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z] ?\d[ABCEGHJ-NPRSTV-Z]\d$', // Canada: A1A 1A1
    'DE': r'^\d{5}$', // Germany: 12345
    'FR': r'^\d{5}$', // France: 12345
    'IT': r'^\d{5}$', // Italy: 12345
    'AU': r'^\d{4}$', // Australia: 1234
    'NL': r'^\d{4} ?[A-Z]{2}$', // Netherlands: 1234 AB
    'ES': r'^\d{5}$', // Spain: 12345
    'IN': r'^\d{6}$', // India: 123456
    'CN': r'^\d{6}$', // China: 123456
    'JP': r'^\d{3}-\d{4}$', // Japan: 123-4567
    'BR': r'^\d{5}-?\d{3}$', // Brazil: 12345-678 or 12345678
    'RU': r'^\d{6}$', // Russia: 123456
  };

  // Store ZIP value without showing error
  void _handleZipChange(String value) {
    // Only clear error message when typing if the new value is valid
    if (_zipErrorMessage != null) {
      _validateZip(value);
    }
  }

  // Validate ZIP code based on country
  void _validateZip(String value) {
    setState(() {
      if (value.isEmpty) {
        _isZipValid = true; // Empty ZIP is valid since it's optional
        _zipErrorMessage = null;
        return;
      }

      // Get the pattern for the selected country
      final pattern =
          _zipPatterns[_selectedCountry ?? 'US'] ?? _zipPatterns['US'];

      if (pattern is String) {
        final RegExp regex = RegExp(pattern);
        final bool isValid = regex.hasMatch(value);
        _isZipValid = isValid;
        _zipErrorMessage = isValid ? null : 'Invalid ZIP format';
      }
    });
  }

  // Phone number validation
  void _validatePhone(String value) {
    setState(() {
      if (value.isEmpty) {
        _phoneErrorMessage = null;
        return;
      }

      // Basic phone validation - numbers only, at least 6 digits
      final RegExp phoneRegex = RegExp(r'^[0-9]{6,}$');
      _phoneErrorMessage =
          phoneRegex.hasMatch(value)
              ? null
              : 'Please enter a valid phone number';
    });
  }

  // Email validation
  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailErrorMessage = null;
        return;
      }

      // Email validation
      final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
      );
      _emailErrorMessage =
          emailRegex.hasMatch(value)
              ? null
              : 'Please enter a valid email address';
    });
  }

  // Website validation
  void _validateWebsite(String value) {
    setState(() {
      if (value.isEmpty) {
        _websiteErrorMessage = null;
        return;
      }

      // Website validation - should start with http:// or https:// or www. and have a domain extension
      final RegExp websiteRegex = RegExp(
        r'^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?(\/.*)?$',
      );
      _websiteErrorMessage =
          websiteRegex.hasMatch(value)
              ? null
              : 'Please enter a valid website URL';
    });
  }

  // Initialize client service
  Future<void> _initClientService() async {
    await _clientService.init();
  }

  // Save updated client data
  void _saveClient() {
    // Validate fields before saving (only name is required)
    if (_organizationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate optional fields if they have content
    if (_zipController.text.isNotEmpty) {
      _validateZip(_zipController.text);
      if (!_isZipValid) {
        return;
      }
    }

    if (_phoneController.text.isNotEmpty) {
      _validatePhone(_phoneController.text);
    }

    if (_emailController.text.isNotEmpty) {
      _validateEmail(_emailController.text);
    }

    if (_websiteController.text.isNotEmpty) {
      _validateWebsite(_websiteController.text);
    }

    // Check for validation errors in optional fields
    if (_zipErrorMessage != null ||
        _phoneErrorMessage != null ||
        _emailErrorMessage != null ||
        _websiteErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors before continuing'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create updated client object
    final updatedClient = Client(
      name: _organizationNameController.text,
      clientId: _clientIdController.text,
      taxId: _taxIdController.text.isEmpty ? null : _taxIdController.text,
      country: _selectedCountry,
      addressLine1: _addressLine1Controller.text,
      addressLine2:
          _addressLine2Controller.text.isEmpty
              ? null
              : _addressLine2Controller.text,
      city: _cityController.text.isEmpty ? null : _cityController.text,
      zip: _zipController.text.isEmpty ? null : _zipController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      website: _websiteController.text.isEmpty ? null : _websiteController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      type: widget.client.type,
      // Preserve other properties
      invoiceCount: widget.client.invoiceCount,
      currency: widget.client.currency,
      amount: widget.client.amount,
      outstandingAmount: widget.client.outstandingAmount,
      hasOutstanding: widget.client.hasOutstanding,
      hasDue: widget.client.hasDue,
      dueAmount: widget.client.dueAmount,
    );

    // Update client in the service
    _clientService.updateClient(updatedClient.clientId, updatedClient);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client updated successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Close the bottom sheet and pass the client back to the parent
    Navigator.pop(context);

    // Call the callback if it exists
    if (widget.onClientUpdated != null) {
      widget.onClientUpdated!(updatedClient);
    }
  }

  // Delete the client
  void _deleteClient() {
    // Delete the client from the service
    _clientService.deleteClient(widget.client.clientId);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Close the bottom sheet
    Navigator.pop(context);

    // Call the callback if it exists
    if (widget.onClientDeleted != null) {
      widget.onClientDeleted!();
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
                    color: Color(0xFF373C3A),
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                SizedBox(height: 12),
                // Main content
                Expanded(
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
                              MainHeading.noIcon(text: 'Edit Client'),

                              // Add spacing after heading
                              SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // Scrollable Content
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
                              child: GestureDetector(
                                // Unfocus when tapping the scrollable area
                                onTap: () => FocusScope.of(context).unfocus(),
                                behavior: HitTestBehavior.translucent,
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
                                    child: _buildForm(),
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

            // Delete button above the primary button
            Positioned(
              bottom: 80, // Position above the primary button
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  color: Color(0xFFDAE4E1),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SecondaryButton(
                      iconType: IconType.editBox,
                      text: 'DELETE CLIENT',
                      color: Color(0xFFD61443),
                      onPressed: _deleteClient,
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Bottom Button Section
            Positioned(
              bottom: 0,
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
                  label: 'SAVE',
                  onPressed: _saveClient,
                  isEnabled: _isButtonEnabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the client form
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Information section
        const SmallHeading(title: "Basic Information"),

        // 24px spacing after heading
        const SizedBox(height: 4),

        // Basic info fields
        GenericInputField(
          label: 'NAME',
          hintText: 'Enter name',
          controller: _organizationNameController,
          focusNode: _organizationNameFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _taxIdFocus.requestFocus();
          },
        ),

        GenericInputField(
          label: 'CLIENT ID',
          hintText: 'Auto-generated', // Pre-filled, disabled
          controller: _clientIdController,
          // Make it read-only by setting onChanged to null
          onChanged: null,
        ),

        GenericInputField(
          label: 'TAX ID',
          hintText: 'Enter tax ID',
          controller: _taxIdController,
          focusNode: _taxIdFocus,
          textInputAction: TextInputAction.done, // Last field in this section
        ),

        // 32px spacing before Address section
        const SizedBox(height: 32),

        // Address section
        const SmallHeading(title: "Address"),

        // 24px spacing after heading
        const SizedBox(height: 4),

        // Address fields
        GestureDetector(
          onTap: () {
            // Will open bottom sheet later for country selection
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Country selector will open a bottom sheet'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: GenericSelectorField(
            label: 'COUNTRY',
            hintText: 'Select country',
            value: _selectedCountry,
          ),
        ),

        GenericInputField(
          label: 'ADDRESS LINE 1',
          hintText: 'Enter address line 1',
          controller: _addressLine1Controller,
          focusNode: _addressLine1Focus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _addressLine2Focus.requestFocus();
          },
        ),

        GenericInputField(
          label: 'ADDRESS LINE 2',
          hintText: 'Enter address line 2',
          controller: _addressLine2Controller,
          focusNode: _addressLine2Focus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _cityFocus.requestFocus();
          },
        ),

        GenericInputField(
          label: 'CITY',
          hintText: 'Enter city',
          controller: _cityController,
          focusNode: _cityFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _zipFocus.requestFocus();
          },
        ),

        GenericInputField(
          label: 'ZIP',
          hintText: 'Enter ZIP',
          controller: _zipController,
          focusNode: _zipFocus,
          textInputAction: TextInputAction.done, // Last field in this section
          onChanged: _handleZipChange,
          onBlur: () => _validateZip(_zipController.text),
          errorText: _zipErrorMessage,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          errorAlignment: Alignment.centerRight,
        ),

        // 32px spacing before Contact section
        const SizedBox(height: 32),

        // Contact section
        const SmallHeading(title: "Contact Information"),

        // 24px spacing after heading
        const SizedBox(height: 4),

        // Contact fields
        PhoneInputField(
          controller: _phoneController,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            // Clear error if any when typing
            if (_phoneErrorMessage != null) {
              setState(() {
                _phoneErrorMessage = null;
              });
            }
          },
          onBlur: () => _validatePhone(_phoneController.text),
          errorText: _phoneErrorMessage,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          errorAlignment: Alignment.centerRight,
        ),

        GenericInputField(
          label: 'EMAIL',
          hintText: 'Enter email',
          controller: _emailController,
          focusNode: _emailFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _websiteFocus.requestFocus();
          },
          onChanged: (value) {
            // Clear error if any when typing
            if (_emailErrorMessage != null) {
              _validateEmail(value);
            }
          },
          onBlur: () => _validateEmail(_emailController.text),
          errorText: _emailErrorMessage,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          errorAlignment: Alignment.centerRight,
        ),

        GenericInputField(
          label: 'WEBSITE',
          hintText: 'Enter website',
          controller: _websiteController,
          focusNode: _websiteFocus,
          textInputAction: TextInputAction.done, // Last field in this section
          onChanged: (value) {
            // Clear error if any when typing
            if (_websiteErrorMessage != null) {
              _validateWebsite(value);
            }
          },
          onBlur: () => _validateWebsite(_websiteController.text),
          errorText: _websiteErrorMessage,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          errorAlignment: Alignment.centerRight,
        ),

        // 32px spacing before Notes section
        const SizedBox(height: 32),

        // Notes section
        const SmallHeading(title: "Notes"),

        // 24px spacing after heading
        const SizedBox(height: 12),

        // Notes field
        TextField(
          controller: _notesController,
          focusNode: _notesFocus,
          decoration: const InputDecoration(
            hintText:
                'Add any custom notes to include on invoices for this client',
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
          minLines: 3,
          maxLines: 5,
        ),

        // 120px spacing after notes to account for delete and save buttons
        const SizedBox(height: 120),
      ],
    );
  }
}

/// GenericSelectorField - a field that opens a selector when tapped
class GenericSelectorField extends StatelessWidget {
  final String label;
  final String hintText;
  final String? value;
  final VoidCallback? onTap;

  const GenericSelectorField({
    super.key,
    required this.label,
    required this.hintText,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Victor Mono',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF373C3A),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          value ?? hintText,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                value != null
                                    ? const Color(0xFF373C3A)
                                    : const Color(0xFF8D9694),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF8D9694),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: DashedLinePainter(color: const Color(0xFFCAD5D2)),
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
      ],
    );
  }
}

/// DashedLinePainter - utility class for drawing dashed lines
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Helper method to show the EditClientSheet as a modal bottom sheet
void showEditClientSheet(
  BuildContext context, {
  required Client client,
  Function(Client)? onClientUpdated,
  Function()? onClientDeleted,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return EditClientSheet(
        client: client,
        onClientUpdated: onClientUpdated,
        onClientDeleted: onClientDeleted,
      );
    },
  );
}
