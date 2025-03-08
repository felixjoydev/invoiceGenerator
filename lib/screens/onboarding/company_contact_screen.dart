import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/navigation/top_nav.dart';
import 'package:invoicegenerator/widgets/display/carousel_dots.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/utils/keyboard_dismiss_wrapper.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CompanyContactScreen extends StatefulWidget {
  const CompanyContactScreen({super.key});

  @override
  State<CompanyContactScreen> createState() => _CompanyContactScreenState();
}

class _CompanyContactScreenState extends State<CompanyContactScreen> {
  // Text controllers for the input fields
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Validation state and error messages
  String? _phoneErrorMessage;
  String? _emailErrorMessage;
  String? _websiteErrorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
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
                // Carousel Dots - third dot active
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Center(
                      child: ChipIndicator(count: 3, currentIndex: 2),
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

                        // Main Heading - Contact Details with contact icon
                        MainHeading.contact(),

                        const SizedBox(height: 24),

                        // Phone Input
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

                        const SizedBox(height: 0),

                        // Email Input
                        GenericInputField(
                          label: 'EMAIL',
                          hintText: 'Enter your email',
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

                        const SizedBox(height: 0),

                        // Website Input
                        GenericInputField(
                          label: 'WEBSITE',
                          hintText: 'Enter your website',
                          controller: _websiteController,
                          onChanged: (value) {
                            // Clear error if any when typing
                            if (_websiteErrorMessage != null) {
                              _validateWebsite(value);
                            }
                          },
                          onBlur:
                              () => _validateWebsite(_websiteController.text),
                          errorText: _websiteErrorMessage,
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

            // Start Invoicing Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PrimaryButton(
                label: 'START INVOICING',
                onPressed: () {
                  // Validate all fields if not empty
                  if (_phoneController.text.isNotEmpty) {
                    _validatePhone(_phoneController.text);
                  }
                  if (_emailController.text.isNotEmpty) {
                    _validateEmail(_emailController.text);
                  }
                  if (_websiteController.text.isNotEmpty) {
                    _validateWebsite(_websiteController.text);
                  }

                  // Check if there are any validation errors
                  if (_phoneErrorMessage != null ||
                      _emailErrorMessage != null ||
                      _websiteErrorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fix the validation errors before continuing',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  // Collect contact information
                  final phone = _phoneController.text;
                  final email = _emailController.text;
                  final website = _websiteController.text;

                  print('Phone: $phone');
                  print('Email: $email');
                  print('Website: $website');

                  // Navigate to next screen (dashboard or home screen)
                  // This will be implemented later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Starting invoicing... This will navigate to the home screen.',
                      ),
                      duration: Duration(seconds: 2),
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