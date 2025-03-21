import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/utils/keyboard_dismiss_wrapper.dart';
import 'package:invoicegenerator/screens/auth/get-started.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 20.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const GetStartedScreen(),
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          const begin = Offset(-1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/icons/back.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),

            // Main content with scroll
            Expanded(
              child: KeyboardDismissWrapper(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        const LoginHeader(),
                        const SizedBox(height: 24),
                        const LoginDivider(),
                        const SizedBox(height: 24),
                        const SocialLoginButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Terms text at bottom
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: TermsText()),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginHeader extends StatelessWidget {
  const LoginHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Log in or create an account',
          style: AppTheme.heading1.copyWith(fontSize: 48, height: 1.1),
        ),
        const SizedBox(height: 56),
        Column(
          children: [
            const EmailInputField(),
            const SizedBox(height: 24),
            LoginButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const CompanyBasicDetailsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class EmailInputField extends StatelessWidget {
  const EmailInputField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericInputField(
      label: 'EMAIL',
      hintText: 'Enter your email',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
    );
  }
}

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 48,
        color: AppTheme.primaryColor,
        child: Center(child: Text('LOGIN', style: AppTheme.primaryButtonText)),
      ),
    );
  }
}

class LoginDivider extends StatelessWidget {
  const LoginDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppTheme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('OR', style: AppTheme.inputFieldLabel),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.dividerColor)),
      ],
    );
  }
}

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          text: 'CONTINUE WITH APPLE',
          svgAsset: 'assets/icons/apple.svg',
          onPressed: () {},
        ),
        const SizedBox(height: 16),
        SocialButton(
          text: 'CONTINUE WITH GOOGLE',
          svgAsset: 'assets/icons/google.svg',
          onPressed: () {},
        ),
      ],
    );
  }
}

class SocialButton extends StatelessWidget {
  final String text;
  final String svgAsset;
  final VoidCallback onPressed;

  const SocialButton({
    Key? key,
    required this.text,
    required this.svgAsset,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppTheme.dividerColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(svgAsset, width: 24, height: 24),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Victor Mono',
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TermsText extends StatelessWidget {
  const TermsText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Helvetica Now Display',
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
          children: <TextSpan>[
            const TextSpan(text: 'By sigining in you accept out\n'),
            TextSpan(
              text: 'Terms of Use',
              style: const TextStyle(color: AppTheme.primaryColor),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to Terms of Use
                    },
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: const TextStyle(color: AppTheme.primaryColor),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to Privacy Policy
                    },
            ),
          ],
        ),
      ),
    );
  }
}
