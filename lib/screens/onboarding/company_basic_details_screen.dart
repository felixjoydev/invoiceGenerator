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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _checkIfUserHasProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  // Load any saved data from shared preferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedBusinessName = prefs.getString('temp_business_name');
      final savedLogoPath = prefs.getString('temp_logo_path');
      final savedCurrency = prefs.getString('temp_currency');
      final savedTaxEnabled = prefs.getBool('temp_enable_tax');
      final savedTaxRate = prefs.getString('temp_tax_rate');

      if (mounted) {
        setState(() {
          if (savedBusinessName != null) {
            _businessNameController.text = savedBusinessName;
          }
          if (savedLogoPath != null) {
            _logoPath = savedLogoPath;
          }
          if (savedCurrency != null) {
            _selectedCurrency = savedCurrency;
          }
          if (savedTaxEnabled != null) {
            _isTaxEnabled = savedTaxEnabled;
          }
          if (savedTaxRate != null) {
            _taxController.text = savedTaxRate;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading temporary company data: $e');
    }
  }

  // Save data to shared preferences temporarily
  Future<void> _saveDataTemporarily() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('temp_business_name', _businessNameController.text);
      if (_logoPath != null) {
        debugPrint('Saving temp logo path: $_logoPath');
        // Verify the logo file exists
        final logoFile = File(_logoPath!);
        final exists = await logoFile.exists();
        debugPrint('Logo file exists: $exists');

        if (exists) {
          await prefs.setString('temp_logo_path', _logoPath!);
        } else {
          debugPrint('Logo file does not exist, not saving');
        }
      }
      await prefs.setString('temp_currency', _selectedCurrency);
      await prefs.setBool('temp_enable_tax', _isTaxEnabled);

      if (_isTaxEnabled && _taxController.text.isNotEmpty) {
        await prefs.setString('temp_tax_rate', _taxController.text);
      }
    } catch (e) {
      debugPrint('Error saving temporary company data: $e');
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

  // Check if the user already has a profile, and if so navigate to home screen
  Future<void> _checkIfUserHasProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('No authenticated user found in onboarding');
        return;
      }

      debugPrint('Checking if user ${user.email} has an existing profile');

      try {
        final response =
            await supabase
                .from('profiles')
                .select('id, business_name, updated_at')
                .eq('id', user.id)
                .maybeSingle();

        debugPrint('Profile check response: $response');

        // Check if we have a valid profile with a business name
        if (response != null &&
            response['business_name'] != null &&
            response['business_name'].toString().isNotEmpty) {
          debugPrint(
            'User already has profile with business name: ${response['business_name']}, redirecting to home',
          );

          if (!mounted) return;

          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          debugPrint('No complete profile found, staying on onboarding screen');
        }
      } catch (e) {
        debugPrint('Error querying profiles: $e');
        // Check if the error is just that no profile exists - we'll stay on onboarding screen
      }
    } catch (e) {
      debugPrint('Error checking user profile: $e');
    }
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

                  // Save profile data to Supabase
                  await _saveProfileToSupabase();

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

  // Add a new method to save profile to Supabase
  Future<void> _saveProfileToSupabase() async {
    try {
      debugPrint('Starting to save profile to Supabase');
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('No user found, cannot save profile');
        return;
      }
      debugPrint('User found: ${user.email}');

      // Upload logo to storage if available
      String? logoUrl;
      if (_logoPath != null) {
        final file = File(_logoPath!);
        if (await file.exists()) {
          debugPrint('Logo file exists, uploading to storage');
          final fileExtension = _logoPath!.split('.').last;
          final fileName = '${user.id}/logo.$fileExtension';
          try {
            await supabase.storage
                .from('logos')
                .upload(
                  fileName,
                  file,
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: true,
                  ),
                );

            // Get public URL
            logoUrl = supabase.storage.from('logos').getPublicUrl(fileName);
            debugPrint('Logo uploaded successfully: $logoUrl');
          } catch (e) {
            debugPrint('Error uploading logo: $e');
            // Continue without logo
          }
        }
      }

      // Create profile data
      final profileData = {
        'id': user.id,
        'business_name': _businessNameController.text,
        'logo_url': logoUrl,
        'currency': _selectedCurrency,
        'tax_enabled': _isTaxEnabled,
        'tax_rate':
            _isTaxEnabled && _taxController.text.isNotEmpty
                ? double.tryParse(_taxController.text) ?? 0.0
                : 0.0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Preparing to upsert profile data: $profileData');

      // Insert or update profile in database
      final response =
          await supabase.from('profiles').upsert(profileData).select();

      debugPrint('Profile upsert response: $response');

      // Explicitly check the database for the profile to be sure it was saved
      await Future.delayed(const Duration(milliseconds: 500));
      final checkResponse =
          await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (checkResponse != null) {
        debugPrint(
          'Profile verified in database: ${checkResponse['business_name']}',
        );
      } else {
        debugPrint('WARNING: Could not verify profile was saved properly');
      }

      debugPrint('Profile saved to Supabase successfully');
    } catch (e) {
      debugPrint('Error saving profile to Supabase: $e');
      // Continue anyway, we'll try again later
    }
  }
}
