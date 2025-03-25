import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/display/SmallHeading.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/models/hive/client_model.dart';
import 'package:invoicegenerator/services/hive/client_service.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/select_client.dart';
import 'package:invoicegenerator/services/hive/service_provider.dart';

class NewClientSheet extends StatefulWidget {
  final Function(Client)? onClientAdded;

  const NewClientSheet({super.key, this.onClientAdded});

  @override
  State<NewClientSheet> createState() => _NewClientSheetState();
}

class _NewClientSheetState extends State<NewClientSheet> {
  // Selected tab index
  int _selectedTabIndex = 0;

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
  late final ClientService _clientService;

  @override
  void initState() {
    super.initState();

    // Initialize the client service from the provider
    _clientService = HiveServiceProvider().clientService;

    // Set the client ID
    _clientIdController.text = _clientService.generateClientId();

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

  // Handle back button press
  void _handleBackPressed() {
    Navigator.pop(context);

    // Show the select client bottom sheet again
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectClientSheet(
          onAddNewClientPressed: () {
            Navigator.pop(context);
            _showNewClientSheet(context);
          },
        );
      },
    );
  }

  // Helper method to show this sheet
  static void _showNewClientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return NewClientSheet();
      },
    );
  }

  // Handle tab change
  void _handleTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _validateForm();
  }

  // Validate form to enable/disable primary button
  void _validateForm() {
    bool isValid = false;

    // Basic validation - check if only the name field is filled
    if (_selectedTabIndex == 0) {
      // Organization
      isValid = _organizationNameController.text.isNotEmpty;
    } else {
      // Person
      isValid = _organizationNameController.text.isNotEmpty;
    }

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

  // Save client data
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

    // Create client object using the Hive Client model
    final client = Client(
      name: _organizationNameController.text,
      clientId: _clientIdController.text,
      type: _selectedTabIndex == 0 ? 'organization' : 'person',
      email: _emailController.text.isEmpty ? null : _emailController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      addressLine1:
          _addressLine1Controller.text.isEmpty
              ? null
              : _addressLine1Controller.text,
      addressLine2:
          _addressLine2Controller.text.isEmpty
              ? null
              : _addressLine2Controller.text,
      city: _cityController.text.isEmpty ? null : _cityController.text,
      zipCode: _zipController.text.isEmpty ? null : _zipController.text,
      country: _selectedCountry,
      // Note: These parameters from the Hive model have default values in the constructor
      invoiceCount: 0,
      amount: 0.0,
      outstandingAmount: 0.0,
      dueAmount: 0.0,
    );

    // Add client to the service
    _clientService.addClient(client);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client added successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Close the bottom sheet and pass the client back to the parent
    Navigator.pop(context);

    // Call the callback if it exists
    if (widget.onClientAdded != null) {
      widget.onClientAdded!(client);
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
                              MainHeading(
                                text: 'Add New Client',
                                iconPath: 'assets/icons/back.svg',
                                onBackPressed: _handleBackPressed,
                              ),

                              // Add spacing between heading and tabs
                              SizedBox(height: 24),

                              // Tab control for Organization/Person selection
                              CustomTabBar(
                                tabs: const ['Organization', 'Person'],
                                initialTabIndex: _selectedTabIndex,
                                onTabChanged: _handleTabChanged,
                              ),
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
                  label: 'ADD CLIENT',
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
        // 32px spacing after tabs
        const SizedBox(height: 32),

        // Basic Information section
        const SmallHeading(title: "Basic Information"),

        // 24px spacing after heading
        const SizedBox(height: 4),

        // Basic info fields
        GenericInputField(
          label: _selectedTabIndex == 0 ? 'ORGANIZATION NAME' : 'PERSON NAME',
          hintText:
              _selectedTabIndex == 0
                  ? 'Enter organization name'
                  : 'Enter person name',
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

        // 40px spacing after notes
        const SizedBox(height: 40),
      ],
    );
  }
}

/// Tab control for Organization/Person selection
class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final int initialTabIndex;
  final Function(int) onTabChanged;
  final Duration animationDuration;

  const CustomTabBar({
    super.key,
    required this.tabs,
    this.initialTabIndex = 0,
    required this.onTabChanged,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with SingleTickerProviderStateMixin {
  late int _activeTabIndex;
  late AnimationController _animationController;

  // Animation variables
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Schedule measuring tab widths after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorPosition();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    if (index == _activeTabIndex) return;

    setState(() {
      _activeTabIndex = index;
    });

    _updateIndicatorPosition();
    widget.onTabChanged(index);
  }

  void _updateIndicatorPosition() {
    if (!_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFCAD5D2), width: 1),
        ),
        padding: EdgeInsets.all(4),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFCAD5D2), width: 1),
      ),
      padding: EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / widget.tabs.length;

          return Stack(
            children: [
              // Animated indicator
              if (_isInitialized)
                AnimatedPositioned(
                  duration: widget.animationDuration,
                  curve: Curves.easeInOut,
                  left: tabWidth * _activeTabIndex,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(color: Color(0xFFF05022)),
                ),
              // Tab buttons
              Row(children: _buildTabButtons()),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTabButtons() {
    List<Widget> tabButtons = [];
    final int tabCount = widget.tabs.length;

    for (int i = 0; i < tabCount; i++) {
      // Add tab button
      tabButtons.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _handleTabTap(i),
            child: Container(
              // Make the container transparent since we're using a sliding indicator
              color: Colors.transparent,
              child: Center(
                child: Text(
                  widget.tabs[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        i == _activeTabIndex ? Colors.white : Color(0xFF8B9199),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return tabButtons;
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

/// Helper method to show the NewClientSheet as a modal bottom sheet
void showNewClientSheet(
  BuildContext context, {
  Function(Client)? onClientAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return NewClientSheet(onClientAdded: onClientAdded);
    },
  );
}
