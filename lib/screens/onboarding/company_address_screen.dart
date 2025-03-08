import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/carousel_dots.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/utils/keyboard_dismiss_wrapper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/inputs/dropdown_input.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/utils/slide_page_route.dart';

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

  // Validation state
  bool _isZipValid = true;

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  // Validate ZIP code
  void _validateZip(String value) {
    // Basic validation - can be enhanced based on selected country
    setState(() {
      _isZipValid = value.isNotEmpty;
    });
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

                        const SizedBox(height: 24),

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
                          hintText: 'Enter ZIP',
                          controller: _zipController,
                          onChanged: (value) {
                            _validateZip(value);
                          },
                          errorText: !_isZipValid ? 'Invalid ZIP' : null,
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
                  // Validate inputs before proceeding
                  if (!_isZipValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid ZIP code'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
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
                      page: Scaffold(
                        appBar: AppBar(title: const Text('Contact Details')),
                        body: const Center(
                          child: Text('Next screen placeholder'),
                        ),
                      ),
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

/// TopNav with a back button, extends from the base TopNav design
class TopNavWithBack extends StatelessWidget {
  final VoidCallback onBackPressed;

  const TopNavWithBack({Key? key, required this.onBackPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the TopNav class as a base and add back button
    return Stack(
      children: [
        const TopNav(),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/back.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFF373C3A),
                BlendMode.srcIn,
              ),
            ),
            onPressed: onBackPressed,
          ),
        ),
      ],
    );
  }
}
