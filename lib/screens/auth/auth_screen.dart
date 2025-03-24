import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/utils/keyboard_dismiss_wrapper.dart';
import 'package:invoicegenerator/screens/auth/get-started.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:invoicegenerator/services/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showManualContinue = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSocialSignIn(Future<void> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showManualContinue = false;
    });

    try {
      // Launch the authentication process
      await signInMethod();

      // Set up an authentication listener with more frequent checks
      Timer? authCheckTimer;
      authCheckTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        // Check if authentication completed
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          timer.cancel();
          debugPrint('Auth screen detected user: ${user.email}');

          // Navigate to the next screen
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const CompanyBasicDetailsScreen(),
              ),
            );
          }
        }
      });

      // Add a way to manually continue after 3 seconds if browser doesn't auto-close
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          setState(() {
            _showManualContinue = true;
            _errorMessage =
                "If you've completed Google login, tap here to continue or press 'Done' in the browser";
          });
        }
      });

      // Update message after 8 seconds with more specific instructions
      Future.delayed(Duration(seconds: 8), () {
        if (mounted &&
            _isLoading &&
            authCheckTimer != null &&
            authCheckTimer.isActive) {
          setState(() {
            _errorMessage =
                "After selecting your Google account, press 'Done' in the top left corner of the browser to return to the app.";
          });
        }
      });

      // Set a timeout to stop checking after 60 seconds
      Future.delayed(Duration(seconds: 60), () {
        if (mounted && _isLoading) {
          if (authCheckTimer != null) {
            authCheckTimer.cancel();
          }
          setState(() {
            _isLoading = false;
            _errorMessage =
                "Sign in timed out. Please try again and be sure to press 'Done' after selecting your Google account.";
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _manualContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force check if we have an authenticated user
      final user = Supabase.instance.client.auth.currentUser;

      // Try refreshing the session
      await Supabase.instance.client.auth.refreshSession();

      // Check again after refreshing
      final refreshedUser = Supabase.instance.client.auth.currentUser;

      if (refreshedUser != null) {
        // User is authenticated, navigate
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CompanyBasicDetailsScreen(),
          ),
        );
        return;
      } else if (user != null) {
        // User was found in the first check
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CompanyBasicDetailsScreen(),
          ),
        );
        return;
      }

      // No user found even after manual check
      setState(() {
        _isLoading = false;
        _errorMessage = "Unable to detect sign in. Please try again.";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error checking authentication: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
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
                            SocialLoginButtons(
                              isLoading: _isLoading,
                              onGoogleSignIn:
                                  () => _handleSocialSignIn(
                                    () =>
                                        AuthProvider.of(
                                          context,
                                        ).signInWithGoogle(),
                                  ),
                              onAppleSignIn:
                                  () => _handleSocialSignIn(
                                    () =>
                                        AuthProvider.of(
                                          context,
                                        ).signInWithApple(),
                                  ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: GestureDetector(
                                  onTap:
                                      _showManualContinue
                                          ? _manualContinue
                                          : null,
                                  child: Column(
                                    children: [
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_errorMessage!.contains("tap here") ||
                                          _errorMessage!.contains(
                                            "completed authentication",
                                          ))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12.0,
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _manualContinue,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryColor,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: const Text(
                                              "Continue",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
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

            // Loading indicator (only shows when loading)
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Signing in...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Show manual continue button after delay
                        if (_showManualContinue) ...[
                          SizedBox(height: 24),
                          Text(
                            'Authentication taking too long?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              _manualContinue();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'Continue manually',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

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
  const EmailInputField({super.key});

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

  const LoginButton({super.key, required this.onPressed});

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
  const LoginDivider({super.key});

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
  final bool isLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  const SocialLoginButtons({
    super.key,
    this.isLoading = false,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          text: 'CONTINUE WITH APPLE',
          svgAsset: 'assets/icons/apple.svg',
          onPressed: isLoading ? null : onAppleSignIn,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        SocialButton(
          text: 'CONTINUE WITH GOOGLE',
          svgAsset: 'assets/icons/google.svg',
          onPressed: isLoading ? null : onGoogleSignIn,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

class SocialButton extends StatelessWidget {
  final String text;
  final String svgAsset;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.text,
    required this.svgAsset,
    required this.onPressed,
    this.isLoading = false,
  });

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
            child:
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textPrimary,
                      ),
                    )
                    : Row(
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
  const TermsText({super.key});

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
