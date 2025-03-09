import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/display/carousel_dots.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:invoicegenerator/widgets/inputs/index.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/utils/keyboard_dismiss_wrapper.dart';
import 'package:invoicegenerator/screens/onboarding/company_address_screen.dart';
import 'package:invoicegenerator/widgets/utils/slide_page_route.dart';

class CompanyBasicDetailsScreen extends StatefulWidget {
  const CompanyBasicDetailsScreen({super.key});

  @override
  State<CompanyBasicDetailsScreen> createState() =>
      _CompanyBasicDetailsScreenState();
}

class _CompanyBasicDetailsScreenState extends State<CompanyBasicDetailsScreen> {
  bool _isTaxEnabled = true;
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation with Carousel Dots
            Stack(
              children: [
                const TopNav(),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Center(
                      child: ChipIndicator(count: 3, currentIndex: 0),
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

                        // Main Heading - Company Details with company icon
                        const MainHeading(),

                        const SizedBox(height: 24),

                        // Form Fields
                        const UploadLogoSection(),

                        const SizedBox(height: 0),

                        // Business Name Input
                        BusinessNameField(
                          controller: _businessNameController,
                          onChanged: (value) {
                            // Handle business name changes
                          },
                        ),

                        const SizedBox(height: 0),

                        // Currency Selector
                        GestureDetector(
                          onTap: () {
                            // Will open bottom sheet later
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Currency selector will open a bottom sheet',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const CurrencySelector(),
                        ),

                        const SizedBox(height: 0),

                        // Tax Input
                        TaxInputRow(
                          controller: _taxController,
                          onChanged: (value) {
                            // Handle tax value changes
                          },
                          enabled: _isTaxEnabled,
                          onToggle: (value) {
                            setState(() {
                              _isTaxEnabled = value;
                            });
                          },
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
                  // Handle form submission
                  final businessName = _businessNameController.text;
                  final tax = _isTaxEnabled ? _taxController.text : null;

                  print('Business Name: $businessName');
                  print('Tax Enabled: $_isTaxEnabled');
                  print('Tax Value: $tax');

                  // Navigate to next screen with a smooth slide-right transition
                  Navigator.of(context).push(
                    SlidePageRoute(
                      page: const CompanyAddressScreen(),
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
