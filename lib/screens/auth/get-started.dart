import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Main content with scroll
            Expanded(child: const GetStartedContent()),

            // Bottom button with padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: PrimaryButton(
                label: 'GET STARTED',
                onPressed: () {
                  // Navigate directly to company basic details screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const CompanyBasicDetailsScreen(),
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

class GetStartedContent extends StatelessWidget {
  const GetStartedContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with logo and menu - using actual SVG files
          Column(
            children: [
              // Remove fixed height container and increase top padding
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Logo with smaller dimensions (40px width)
                    Hero(
                      tag: 'logo',
                      child: SvgPicture.asset(
                        'assets/icons/logo.svg',
                        width: 40,
                        height: 49,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    // Invo Black SVG
                    SvgPicture.asset(
                      'assets/icons/invo-black.svg',
                      width: 54.89,
                      height: 19.55,
                    ),
                  ],
                ),
              ),
              // Add 24px spacing
              const SizedBox(height: 24),
              // Divider using AppTheme.divider1 for consistency
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AppTheme.divider1,
              ),
            ],
          ),

          SizedBox(height: 78),

          // Illustration section - using get-started.svg
          Container(
            height: 181.35,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SvgPicture.asset(
              'assets/icons/get-started.svg',
              fit: BoxFit.fitWidth,
            ),
          ),

          SizedBox(height: 78),

          // Text content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME TO INVO',
                  style: AppTheme.firstTimeUserHeading.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simple and beautiful invoice maker',
                  style: AppTheme.heading1.copyWith(fontSize: 48, height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
