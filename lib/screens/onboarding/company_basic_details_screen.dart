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
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:invoicegenerator/services/hive/company_info_service.dart';
import 'package:invoicegenerator/models/hive/company_info_model.dart';
import 'package:invoicegenerator/services/hive/service_provider.dart';

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
  String _selectedCurrency = 'USD';
  String? _logoPath;

  // Service provider reference
  late HiveServiceProvider _serviceProvider;

  @override
  void initState() {
    super.initState();
    // Data will be loaded in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the service provider
    _serviceProvider = HiveServiceProviderWidget.of(context);
    // Load data
    _loadSavedData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  // Load any saved data from Hive
  Future<void> _loadSavedData() async {
    try {
      final companyInfo = _serviceProvider.companyInfoService.companyInfo;

      if (companyInfo != null && mounted) {
        setState(() {
          if (companyInfo.businessName.isNotEmpty) {
            _businessNameController.text = companyInfo.businessName;
          }
          if (companyInfo.logoPath != null) {
            _logoPath = companyInfo.logoPath;
          }
          _selectedCurrency = companyInfo.currency;
          _isTaxEnabled = companyInfo.enableTax;

          // Set tax rate if it exists
          if (companyInfo.enableTax && companyInfo.taxNumber != null) {
            _taxController.text = companyInfo.taxNumber!;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading company data: $e');
    }
  }

  // Save data to Hive
  Future<void> _saveDataTemporarily() async {
    try {
      // Create a CompanyInfo object
      final companyInfo = CompanyInfo(
        businessName: _businessNameController.text,
        currency: _selectedCurrency,
        enableTax: _isTaxEnabled,
        logoPath: _logoPath,
        taxNumber:
            _isTaxEnabled && _taxController.text.isNotEmpty
                ? _taxController.text
                : null,
      );

      // Save to Hive
      await _serviceProvider.companyInfoService.saveCompanyInfo(companyInfo);
    } catch (e) {
      debugPrint('Error saving company data: $e');
    }
  }

  // Handle currency selection
  void _handleCurrencySelected(String currency) {
    setState(() {
      _selectedCurrency = currency;
    });
  }

  // Handle logo selection
  void _handleLogoSelected(String path) {
    setState(() {
      _logoPath = path;
    });
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
                const TopNav(showLogo: false, hideSettings: true),
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
                        UploadLogoSection(
                          onLogoSelected: _handleLogoSelected,
                          initialLogoPath: _logoPath,
                        ),

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
                          child: CurrencySelector(
                            selectedCurrency: _selectedCurrency,
                            onCurrencySelected: _handleCurrencySelected,
                          ),
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
                onPressed: () async {
                  // Validate form
                  if (_businessNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter your business name'),
                      ),
                    );
                    return;
                  }

                  // Save data temporarily
                  await _saveDataTemporarily();

                  // Navigate to next screen with a smooth slide-right transition
                  if (mounted) {
                    Navigator.of(context).push(
                      SlidePageRoute(
                        page: const CompanyAddressScreen(),
                        direction: SlideDirection.right,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
