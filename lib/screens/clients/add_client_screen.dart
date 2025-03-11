import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/display/tabs.dart';
import 'package:invoicegenerator/widgets/display/SmallHeading.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/inputs/dropdown_input.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/services/client_service.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  // Selected tab index
  int _selectedTabIndex = 0;

  // Text controllers for the input fields
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _clientIdController = TextEditingController(
    text: 'CL001',
  ); // Pre-filled
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

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

    // Add listeners to controllers for validation
    _organizationNameController.addListener(_validateForm);
    _addressLine1Controller.addListener(_validateForm);
    _emailController.addListener(_validateForm);

    // Initial validation
    _validateForm();
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
    super.dispose();
  }

  // Handle back button press
  void _handleBackPressed() {
    Navigator.of(context).pop();
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

  // Initialize client service and get a unique client ID
  Future<void> _initClientService() async {
    await _clientService.init();
    setState(() {
      _clientIdController.text = _clientService.generateClientId();
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

    // Create client object - only name and clientId are absolutely required
    // along with a type which is derived from the selected tab
    final client = Client(
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
      type: _selectedTabIndex == 0 ? 'organization' : 'person',
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

    // Navigate back
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Custom top navigation with back button on left and "Add Client" title
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
                    'Add Client',
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

          // Tab control for Organization/Person selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomTabBar(
              tabs: const ['Organization', 'Person'],
              initialTabIndex: _selectedTabIndex,
              onTabChanged: _handleTabChanged,
            ),
          ),

          // Content area with form fields
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 32px spacing after tabs
                    const SizedBox(height: 32),

                    // Basic Information section
                    const SmallHeading(title: "Basic Information"),

                    // 24px spacing after heading
                    const SizedBox(height: 24),

                    // Basic info fields
                    GenericInputField(
                      label:
                          _selectedTabIndex == 0
                              ? 'ORGANIZATION NAME'
                              : 'PERSON NAME',
                      hintText:
                          _selectedTabIndex == 0
                              ? 'Enter organization name'
                              : 'Enter person name',
                      controller: _organizationNameController,
                    ),

                    GenericInputField(
                      label: 'CLIENT ID',
                      hintText: 'Enter client ID', // Pre-filled, disabled
                      controller: _clientIdController,
                      // Make it read-only
                      onChanged: null,
                    ),

                    GenericInputField(
                      label: 'TAX ID',
                      hintText: 'Enter tax ID',
                      controller: _taxIdController,
                    ),

                    // 32px spacing before Address section
                    const SizedBox(height: 32),

                    // Address section
                    const SmallHeading(title: "Address"),

                    // 24px spacing after heading
                    const SizedBox(height: 24),

                    // Address fields
                    GestureDetector(
                      onTap: () {
                        // Will open bottom sheet later for country selection
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Country selector will open a bottom sheet',
                            ),
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
                    ),

                    GenericInputField(
                      label: 'ADDRESS LINE 2',
                      hintText: 'Enter address line 2',
                      controller: _addressLine2Controller,
                    ),

                    GenericInputField(
                      label: 'CITY',
                      hintText: 'Enter city',
                      controller: _cityController,
                    ),

                    GenericInputField(
                      label: 'ZIP',
                      hintText: 'Enter ZIP',
                      controller: _zipController,
                      onChanged: _handleZipChange,
                      onBlur: () => _validateZip(_zipController.text),
                      errorText: _zipErrorMessage,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      errorAlignment: Alignment.centerRight,
                    ),

                    // 32px spacing before Contact section
                    const SizedBox(height: 32),

                    // Contact section
                    const SmallHeading(title: "Contact Information"),

                    // 24px spacing after heading
                    const SizedBox(height: 24),

                    // Contact fields
                    PhoneInputField(
                      controller: _phoneController,
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
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      errorAlignment: Alignment.centerRight,
                    ),

                    GenericInputField(
                      label: 'EMAIL',
                      hintText: 'Enter email',
                      controller: _emailController,
                      onChanged: (value) {
                        // Clear error if any when typing
                        if (_emailErrorMessage != null) {
                          _validateEmail(value);
                        }
                      },
                      onBlur: () => _validateEmail(_emailController.text),
                      errorText: _emailErrorMessage,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      errorAlignment: Alignment.centerRight,
                    ),

                    GenericInputField(
                      label: 'WEBSITE',
                      hintText: 'Enter website',
                      controller: _websiteController,
                      onChanged: (value) {
                        // Clear error if any when typing
                        if (_websiteErrorMessage != null) {
                          _validateWebsite(value);
                        }
                      },
                      onBlur: () => _validateWebsite(_websiteController.text),
                      errorText: _websiteErrorMessage,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      errorAlignment: Alignment.centerRight,
                    ),

                    // 32px spacing before Notes section
                    const SizedBox(height: 32),

                    // Notes section
                    const SmallHeading(title: "Notes"),

                    // 24px spacing after heading
                    const SizedBox(height: 24),

                    // Notes field
                    TextField(
                      controller: _notesController,
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
                label: 'ADD CLIENT',
                onPressed: _saveClient,
                isEnabled: _isButtonEnabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
