import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/display/SmallHeading.dart';
import 'package:invoicegenerator/bottom_sheets/invoices/new_item.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/inputs/dropdown_input.dart';
import 'package:invoicegenerator/widgets/inputs/index.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/services/company_service.dart';
import 'package:invoicegenerator/screens/settings/settings_screen.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessDetailsSheet extends StatefulWidget {
  const BusinessDetailsSheet({super.key});

  @override
  State<BusinessDetailsSheet> createState() => _BusinessDetailsSheetState();
}

class _BusinessDetailsSheetState extends State<BusinessDetailsSheet> {
  // Company service instance
  final _companyService = CompanyService();

  // Text controllers for the input fields
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Focus nodes for keyboard navigation
  final FocusNode _businessNameFocus = FocusNode();
  final FocusNode _taxFocus = FocusNode();
  final FocusNode _addressLine1Focus = FocusNode();
  final FocusNode _addressLine2Focus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _zipFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _websiteFocus = FocusNode();

  // Selected values
  String _selectedCurrency = 'USD';
  String _selectedCountry = 'US';
  bool _isTaxEnabled = true;
  String? _logoPath;

  // Validation state and messages
  bool _isZipValid = true;
  String? _zipErrorMessage;
  String? _phoneErrorMessage;
  String? _emailErrorMessage;
  String? _websiteErrorMessage;

  // Track if form has been modified
  bool _isFormModified = false;

  // Track if at top for drag to dismiss
  bool _isAtTop = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initCompanyService();
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

  // Initialize company service and load company data
  Future<void> _initCompanyService() async {
    debugPrint('Initializing company service in BusinessDetailsSheet');
    await _companyService.refresh();
    _loadCompanyData();
  }

  // Load company data into form fields
  void _loadCompanyData() {
    final companyInfo = _companyService.companyInfo;
    if (companyInfo != null) {
      debugPrint(
        'Loading company info with logo path: ${companyInfo.logoPath}',
      );

      // Check if the logo file exists
      if (companyInfo.logoPath != null) {
        final logoFile = File(companyInfo.logoPath!);
        final exists = logoFile.existsSync();
        debugPrint(
          'Loaded logo file exists: $exists (${companyInfo.logoPath})',
        );
      }

      setState(() {
        // Basic Details
        _businessNameController.text = companyInfo.businessName;
        _logoPath = companyInfo.logoPath;
        _selectedCurrency = companyInfo.currency;
        _isTaxEnabled = companyInfo.enableTax;
        if (companyInfo.taxRate != null) {
          _taxController.text = companyInfo.taxRate.toString();
        }

        // Address Details
        _selectedCountry = companyInfo.country;
        _addressLine1Controller.text = companyInfo.addressLine1;
        if (companyInfo.addressLine2 != null) {
          _addressLine2Controller.text = companyInfo.addressLine2!;
        }
        _cityController.text = companyInfo.city;
        if (companyInfo.zip != null) {
          _zipController.text = companyInfo.zip!;
        }

        // Contact Details
        if (companyInfo.phone != null) {
          _phoneController.text = companyInfo.phone!;
        }
        if (companyInfo.email != null) {
          _emailController.text = companyInfo.email!;
        }
        if (companyInfo.website != null) {
          _websiteController.text = companyInfo.website!;
        }
      });

      // Add listeners after populating fields to avoid triggering _markFormModified
      _addControllerListeners();
    } else {
      debugPrint('No company info found to load');
    }
  }

  // Add listeners to all controllers to track changes
  void _addControllerListeners() {
    _businessNameController.addListener(_markFormModified);
    _taxController.addListener(_markFormModified);
    _addressLine1Controller.addListener(_markFormModified);
    _addressLine2Controller.addListener(_markFormModified);
    _cityController.addListener(_markFormModified);
    _zipController.addListener(_markFormModified);
    _phoneController.addListener(_markFormModified);
    _emailController.addListener(_markFormModified);
    _websiteController.addListener(_markFormModified);
  }

  // Mark form as modified when any field changes
  void _markFormModified() {
    if (!_isFormModified) {
      setState(() {
        _isFormModified = true;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _businessNameController.dispose();
    _taxController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();

    // Dispose focus nodes
    _businessNameFocus.dispose();
    _taxFocus.dispose();
    _addressLine1Focus.dispose();
    _addressLine2Focus.dispose();
    _cityFocus.dispose();
    _zipFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _websiteFocus.dispose();

    // Dispose scroll controller
    _scrollController.dispose();

    super.dispose();
  }

  // Handle back button press
  void _handleBackPressed() {
    debugPrint('Handling back button press in BusinessDetailsSheet');
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

  // Handle currency selection

  // Handle country selection

  // Handle tax toggle

  // Handle logo selection
  void _handleLogoSelected(String path) {
    debugPrint('Logo selected: $path');

    // Check if the file exists
    final logoFile = File(path);
    if (!logoFile.existsSync()) {
      debugPrint('Logo file does not exist: $path');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Image file not found'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _logoPath = path;
      _markFormModified();
    });
  }

  // Handle logo removal
  void _handleLogoRemoved() {
    debugPrint('Logo removed');
    setState(() {
      _logoPath = null;
      _markFormModified();
    });
  }

  // ZIP code validation patterns for different countries
  final Map<String, Pattern> _zipPatterns = {
    'US': r'^\d{5}(-\d{4})?$', // US: 12345 or 12345-6789
    'UK': r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$', // UK formats
    'CA':
        r'^[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z] ?\d[ABCEGHJ-NPRSTV-Z]\d$', // Canada
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

  // Handle ZIP change
  void _handleZipChange(String value) {
    if (_zipErrorMessage != null) {
      _validateZip(value);
    }
  }

  // Validate ZIP code
  void _validateZip(String value) {
    setState(() {
      if (value.isEmpty) {
        _isZipValid = true;
        _zipErrorMessage = null;
        return;
      }

      final pattern = _zipPatterns[_selectedCountry] ?? _zipPatterns['US'];
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

      final RegExp websiteRegex = RegExp(
        r'^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?(\/.*)?$',
      );
      _websiteErrorMessage =
          websiteRegex.hasMatch(value)
              ? null
              : 'Please enter a valid website URL';
    });
  }

  // Save changes
  Future<void> _saveChanges() async {
    // Validate required fields
    if (_businessNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your business name'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_addressLine1Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your address'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your city'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate optional fields
    if (_zipController.text.isNotEmpty) {
      _validateZip(_zipController.text);
      if (!_isZipValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid ZIP code'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (_phoneController.text.isNotEmpty) {
      _validatePhone(_phoneController.text);
      if (_phoneErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (_emailController.text.isNotEmpty) {
      _validateEmail(_emailController.text);
      if (_emailErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (_websiteController.text.isNotEmpty) {
      _validateWebsite(_websiteController.text);
      if (_websiteErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid website URL'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 16),
              Text('Saving changes...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }

    // Get current user ID from Supabase or use existing ID
    String companyId = _companyService.companyInfo!.id;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        companyId = currentUser.id;
        debugPrint('Using Supabase user ID: $companyId');
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }

    // Create updated company info
    final companyInfo = CompanyInfo(
      id: companyId,
      businessName: _businessNameController.text,
      logoPath: _logoPath,
      currency: _selectedCurrency,
      taxRate:
          _taxController.text.isNotEmpty
              ? double.tryParse(_taxController.text)
              : null,
      enableTax: _isTaxEnabled,
      country: _selectedCountry,
      addressLine1: _addressLine1Controller.text,
      addressLine2:
          _addressLine2Controller.text.isEmpty
              ? null
              : _addressLine2Controller.text,
      city: _cityController.text,
      zip: _zipController.text.isEmpty ? null : _zipController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      website: _websiteController.text.isEmpty ? null : _websiteController.text,
      bankName: _companyService.companyInfo?.bankName,
      accountHolder: _companyService.companyInfo?.accountHolder,
      accountNumber: _companyService.companyInfo?.accountNumber,
      ifscCode: _companyService.companyInfo?.ifscCode,
    );

    debugPrint('Saving company info with logo path: ${companyInfo.logoPath}');

    try {
      // Save to service (now handles both local and Supabase saving)
      await _companyService.saveCompanyInfo(companyInfo);

      // Verify that the company info was saved properly
      await _companyService.refresh();
      final savedInfo = _companyService.companyInfo;
      debugPrint(
        'Verified saved company info with logo path: ${savedInfo?.logoPath}',
      );

      if (savedInfo?.logoPath != null) {
        final logoFile = File(savedInfo!.logoPath!);
        final exists = logoFile.existsSync();
        debugPrint('Verified saved logo file exists: $exists');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset form modified state
        setState(() {
          _isFormModified = false;
        });

        // Navigate back to settings screen
        _handleBackPressed();
      }
    } catch (e) {
      debugPrint('Error saving company info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
                            text: 'Company Details',
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
                                        // Basic Details Section
                                        const SmallHeading(
                                          title: "Basic Details",
                                        ),
                                        const SizedBox(height: 24),

                                        // Upload Logo Section
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            UploadLogoSection(
                                              onLogoSelected:
                                                  _handleLogoSelected,
                                              initialLogoPath: _logoPath,
                                              onLogoRemoved: _handleLogoRemoved,
                                            ),
                                          ],
                                        ),

                                        // Business Name Input
                                        GenericInputField(
                                          label: 'BUSINESS NAME',
                                          hintText: 'Enter business name',
                                          controller: _businessNameController,
                                          focusNode: _businessNameFocus,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) {
                                            _taxFocus.requestFocus();
                                          },
                                        ),

                                        // Currency Selector
                                        GestureDetector(
                                          onTap: () {
                                            // Will open bottom sheet for currency selection
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Currency selector will open a bottom sheet',
                                                ),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          child: GenericSelectorField(
                                            label: 'CURRENCY',
                                            hintText: 'Select currency',
                                            value: _selectedCurrency,
                                          ),
                                        ),

                                        // Tax Input
                                        TaxInputRow(
                                          controller: _taxController,
                                          onChanged: (value) {
                                            _markFormModified();
                                          },
                                          enabled: _isTaxEnabled,
                                          onToggle: (value) {
                                            setState(() {
                                              _isTaxEnabled = value;
                                              _markFormModified();
                                            });
                                          },
                                        ),

                                        const SizedBox(height: 32),

                                        // Address Section
                                        const SmallHeading(
                                          title: "Company Address",
                                        ),
                                        const SizedBox(height: 8),

                                        // Country Dropdown
                                        GestureDetector(
                                          onTap: () {
                                            // Will open bottom sheet for country selection
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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

                                        // Address Line 1
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

                                        // Address Line 2
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

                                        // City
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

                                        // ZIP
                                        GenericInputField(
                                          label: 'ZIP',
                                          hintText: 'Enter ZIP code',
                                          controller: _zipController,
                                          focusNode: _zipFocus,
                                          onChanged: _handleZipChange,
                                          onBlur:
                                              () => _validateZip(
                                                _zipController.text,
                                              ),
                                          errorText: _zipErrorMessage,
                                          errorStyle: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                          errorAlignment: Alignment.centerRight,
                                        ),

                                        const SizedBox(height: 32),

                                        // Contact Section
                                        const SmallHeading(
                                          title: "Contact Details",
                                        ),
                                        const SizedBox(height: 8),

                                        // Phone Input
                                        GenericInputField(
                                          label: 'PHONE',
                                          hintText: 'Enter your phone number',
                                          controller: _phoneController,
                                          focusNode: _phoneFocus,
                                          keyboardType: TextInputType.phone,
                                          onChanged: (value) {
                                            if (_phoneErrorMessage != null) {
                                              _validatePhone(value);
                                            }
                                          },
                                          onBlur:
                                              () => _validatePhone(
                                                _phoneController.text,
                                              ),
                                          errorText: _phoneErrorMessage,
                                          errorStyle: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                          errorAlignment: Alignment.centerRight,
                                        ),

                                        // Email Input
                                        GenericInputField(
                                          label: 'EMAIL',
                                          hintText: 'Enter your email',
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          onChanged: (value) {
                                            if (_emailErrorMessage != null) {
                                              _validateEmail(value);
                                            }
                                          },
                                          onBlur:
                                              () => _validateEmail(
                                                _emailController.text,
                                              ),
                                          errorText: _emailErrorMessage,
                                          errorStyle: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                          errorAlignment: Alignment.centerRight,
                                        ),

                                        // Website Input
                                        GenericInputField(
                                          label: 'WEBSITE',
                                          hintText: 'Enter your website',
                                          controller: _websiteController,
                                          focusNode: _websiteFocus,
                                          keyboardType: TextInputType.url,
                                          onChanged: (value) {
                                            if (_websiteErrorMessage != null) {
                                              _validateWebsite(value);
                                            }
                                          },
                                          onBlur:
                                              () => _validateWebsite(
                                                _websiteController.text,
                                              ),
                                          errorText: _websiteErrorMessage,
                                          errorStyle: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                          errorAlignment: Alignment.centerRight,
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

// Helper method to show the BusinessDetailsSheet as a modal bottom sheet
void showBusinessDetailsSheet(BuildContext context) {
  debugPrint('Showing BusinessDetailsSheet');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return const BusinessDetailsSheet();
    },
  );
}
