import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/carousel_dots.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/utils/keyboard_dismiss_wrapper.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/inputs/dropdown_input.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/utils/slide_page_route.dart';
import 'package:invoicegenerator/screens/onboarding/company_contact_screen.dart';

class CompanyAddressScreen extends StatefulWidget {
  const CompanyAddressScreen({super.key});

  @override
  State<CompanyAddressScreen> createState() => _CompanyAddressScreenState();
}

class _CompanyAddressScreenState extends State<CompanyAddressScreen> {
  // Text controllers for the input fields
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  // Selected country (default to US)
  String _selectedCountry = 'US';

  // Validation state and message
  bool _isZipValid = true;
  String? _zipErrorMessage;

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
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
      final pattern = _zipPatterns[_selectedCountry] ?? _zipPatterns['US'];

      if (pattern is String) {
        final RegExp regex = RegExp(pattern);
        final bool isValid = regex.hasMatch(value);
        _isZipValid = isValid;
        _zipErrorMessage =
            isValid
                ? null
                : 'Invalid ZIP format for ${_getCountryName(_selectedCountry)}';
      }
    });
  }

  // Get country name from code
  String _getCountryName(String code) {
    final Map<String, String> countryNames = {
      'US': 'United States',
      'UK': 'United Kingdom',
      'CA': 'Canada',
      'DE': 'Germany',
      'FR': 'France',
      'IT': 'Italy',
      'AU': 'Australia',
      'NL': 'Netherlands',
      'ES': 'Spain',
      'IN': 'India',
      'CN': 'China',
      'JP': 'Japan',
      'BR': 'Brazil',
      'RU': 'Russia',
    };
    return countryNames[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation with Back Button and Carousel Dots
            Stack(
              children: [
                // Top Nav with Back Button
                TopNavWithBack(
                  onBackPressed: () {
                    Navigator.pop(context);
                  },
                ),
                // Carousel Dots - second dot active
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Center(
                      child: ChipIndicator(count: 3, currentIndex: 1),
                    ),
                  ),
                ),
              ],
            ),

            // Main Content
            Expanded(
              child: KeyboardDismissWrapper(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 0),

                        // Main Heading - Business Address with address icon
                        MainHeading.address(),

                        const SizedBox(height: 12),

                        // Country Dropdown
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
                          ),
                        ),

                        const SizedBox(height: 0),

                        // Address Line 1
                        GenericInputField(
                          label: 'ADDRESS LINE 1',
                          hintText: 'Enter address line 1',
                          controller: _addressLine1Controller,
                          onChanged: (value) {
                            // Handle address line 1 changes
                          },
                        ),

                        const SizedBox(height: 0),

                        // Address Line 2
                        GenericInputField(
                          label: 'ADDRESS LINE 2',
                          hintText: 'Enter address line 2',
                          controller: _addressLine2Controller,
                          onChanged: (value) {
                            // Handle address line 2 changes
                          },
                        ),

                        const SizedBox(height: 0),

                        // City
                        GenericInputField(
                          label: 'CITY',
                          hintText: 'Enter city',
                          controller: _cityController,
                          onChanged: (value) {
                            // Handle city changes
                          },
                        ),

                        const SizedBox(height: 0),

                        // ZIP
                        GenericInputField(
                          label: 'ZIP',
                          hintText: 'Enter ZIP code',
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
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PrimaryButton(
                label: 'CONTINUE',
                onPressed: () {
                  // Validate ZIP only if it's not empty
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

                  // Save and process address data
                  final addressLine1 = _addressLine1Controller.text;
                  final addressLine2 = _addressLine2Controller.text;
                  final city = _cityController.text;
                  final zip = _zipController.text;

                  print('Address Line 1: $addressLine1');
                  print('Address Line 2: $addressLine2');
                  print('City: $city');
                  print('ZIP: $zip');

                  // Navigate to next screen
                  Navigator.of(context).push(
                    SlidePageRoute(
                      page: const CompanyContactScreen(),
                      direction: SlideDirection.right,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}