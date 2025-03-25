import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/utils/keyboard_dismiss_wrapper.dart';
import 'package:invoicegenerator/screens/auth/get-started.dart';
import 'package:invoicegenerator/screens/onboarding/company_basic_details_screen.dart';
import 'package:invoicegenerator/screens/home/first_time_home_screen.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/widgets/inputs/text_input.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:invoicegenerator/utils/supabase_debug.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:invoicegenerator/services/mcp/storage_service_factory.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // Log the current auth state for debugging
    final currentUser = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;
    debugPrint('Auth Screen init - Current user: ${currentUser?.email}');
    debugPrint('Auth Screen init - Has session: ${session != null}');

    // Validate Supabase configuration
    SupabaseDebugUtils.validateConfiguration();

    // Set up listener for auth state changes from deep links
    _setupDeepLinkListener();

    // Check if there's an existing session when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingAuth();
    });
  }

  // Set up a listener for deep link auth state changes
  void _setupDeepLinkListener() {
    debugPrint('Setting up deep link auth listener');
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      debugPrint('Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn) {
        debugPrint('User signed in via deep link, checking user state');
        _checkUserState();
      }
    });
  }

  // Check for existing authenticated session
  Future<void> _checkExistingAuth() async {
    debugPrint('Checking for existing auth session...');
    final session = supabase.auth.currentSession;

    if (session != null) {
      debugPrint('Found existing session for user: ${session.user.email}');
      debugPrint('Auth token expires at: ${session.expiresAt}');
      debugPrint(
        'Current time: ${DateTime.now().millisecondsSinceEpoch / 1000}',
      );
      debugPrint('Token details: ${session.accessToken.substring(0, 20)}...');
      await _checkUserState();
    } else {
      debugPrint('No existing auth session found');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Check user state and navigate to the appropriate screen
  Future<void> _checkUserState() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Debug the current auth state
      final currentUser = supabase.auth.currentUser;
      debugPrint(
        'Current auth state - User: ${currentUser?.id}, Email: ${currentUser?.email}',
      );
      debugPrint('Auth session: ${supabase.auth.currentSession != null}');

      if (currentUser == null) {
        debugPrint('No authenticated user, staying on auth screen');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint(
        'Authentication successful, checking user onboarding status...',
      );

      // Check if the user has completed onboarding
      final hasCompletedOnboarding = await _hasCompletedOnboarding();
      debugPrint('Has completed onboarding: $hasCompletedOnboarding');

      // Check if user has created invoices
      final hasCreatedInvoices = await _hasCreatedInvoices();
      debugPrint('Has created invoices: $hasCreatedInvoices');

      if (!mounted) return; // Safety check in case widget is disposed

      if (!hasCompletedOnboarding) {
        // New user, redirect to onboarding
        debugPrint('Redirecting to company basic details screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CompanyBasicDetailsScreen(),
          ),
        );
      } else if (hasCompletedOnboarding && !hasCreatedInvoices) {
        // Completed onboarding but no invoices yet
        debugPrint('Redirecting to first time home screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const FirstTimeHomeScreen()),
        );
      } else {
        // Has created invoices
        debugPrint('Redirecting to main home screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking user state: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check if user has completed onboarding by checking if company info exists
  Future<bool> _hasCompletedOnboarding() async {
    try {
      final currentUser = supabase.auth.currentUser;
      debugPrint('Checking onboarding status for user: ${currentUser?.id}');

      if (currentUser == null) {
        debugPrint('Error: No logged in user found when checking onboarding');
        return false;
      }

      // First check if this user has a record in public.users
      final userRecord =
          await supabase
              .from('users')
              .select('id')
              .eq('id', currentUser.id)
              .maybeSingle();

      if (userRecord == null) {
        debugPrint('User record not found in public.users table, creating one');
        // Create the user record if it doesn't exist
        await supabase.from('users').insert({
          'id': currentUser.id,
          'email': currentUser.email,
        });
      }

      final response =
          await supabase
              .from('organizations')
              .select()
              .eq('user_id', currentUser.id)
              .limit(1)
              .maybeSingle();

      debugPrint('Organization check response: $response');

      return response != null;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  // Check if user has created invoices
  Future<bool> _hasCreatedInvoices() async {
    try {
      final orgId = await _getUserOrganizationId();
      if (orgId != null) {
        final response =
            await supabase
                .from('invoices')
                .select('id')
                .eq('organization_id', orgId)
                .limit(1)
                .maybeSingle();

        return response != null;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error checking invoice status: $e');
      return false;
    }
  }

  // Get user's organization ID
  Future<String?> _getUserOrganizationId() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('Error: No logged in user found when getting org ID');
        return null;
      }

      final response =
          await supabase
              .from('organizations')
              .select('id')
              .eq('user_id', currentUser.id)
              .limit(1)
              .maybeSingle();

      debugPrint('Organization ID response: $response');

      if (response == null) {
        return null;
      }

      return response['id'];
    } catch (e) {
      debugPrint('Error getting organization ID: $e');
      return null;
    }
  }

  // Handle Google sign-in
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('Starting Google sign-in flow');

      // Use Supabase's direct OAuth sign-in
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'felix.invoicegenerator://login-callback',
      );

      debugPrint('OAuth sign-in initiated: ${response}');

      // Start the manual session check to detect when the user returns from the browser
      _startSessionCheck();

      // No need to check for a session here since the auth flow is redirected to browser
      // The _setupDeepLinkListener will catch the sign-in event when the user comes back
    } catch (e) {
      debugPrint('Error starting Google sign-in: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Poll for session changes to handle cases where the auth listener doesn't trigger
  void _startSessionCheck() {
    debugPrint('Starting manual session check...');

    // Check every 1 second for 60 seconds total (60 attempts)
    int attempts = 0;
    const maxAttempts = 60;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      attempts++;
      debugPrint('Manual session check attempt $attempts/$maxAttempts');

      try {
        // Check for session
        final session = supabase.auth.currentSession;
        final user = supabase.auth.currentUser;

        debugPrint(
          'Session check: hasSession=${session != null}, hasUser=${user != null}',
        );

        if (session != null) {
          debugPrint(
            'Session found! Expires at: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}',
          );
          debugPrint(
            'Token first 10 chars: ${session.accessToken.substring(0, 10)}...',
          );
        }

        if (user != null) {
          debugPrint('User found! ID: ${user.id}, Email: ${user.email}');
        }

        if (session != null && user != null) {
          debugPrint('Complete session found manually! User: ${user.email}');
          debugPrint(
            'Session token: ${session.accessToken.substring(0, 20)}...',
          );
          if (mounted) {
            _checkUserState();
            timer.cancel();
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking session: $e');
      }

      // Stop after max attempts
      if (attempts >= maxAttempts) {
        debugPrint('Reached maximum session check attempts without success');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication timed out. Please try again.'),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        timer.cancel();
      }
    });
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
                              onGoogleSignInPressed: _handleGoogleSignIn,
                              isLoading: _isLoading,
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
                  child: Center(child: const TermsText()),
                ),

                // Add reset data button at the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton.icon(
                    onPressed: () async {
                      final factory = StorageServiceFactory();
                      await factory.forceDeleteAllLocalData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully cleared all local data'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text(
                      'Reset Local Data',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
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
                // Email login functionality can be added here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email login not implemented yet'),
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
  final VoidCallback onGoogleSignInPressed;
  final bool isLoading;

  const SocialLoginButtons({
    Key? key,
    required this.onGoogleSignInPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          text: 'CONTINUE WITH GOOGLE',
          svgAsset: 'assets/icons/google.svg',
          onPressed: isLoading ? null : onGoogleSignInPressed,
        ),
        const SizedBox(height: 16),
        SocialButton(
          text: 'CONTINUE WITH APPLE',
          svgAsset: 'assets/icons/apple.svg',
          onPressed:
              isLoading
                  ? null
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Apple sign-in not implemented yet'),
                      ),
                    );
                  },
        ),
      ],
    );
  }
}

class SocialButton extends StatelessWidget {
  final String text;
  final String svgAsset;
  final VoidCallback? onPressed;

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
      color:
          onPressed == null
              ? AppTheme.dividerColor.withOpacity(0.5)
              : AppTheme.dividerColor,
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
            const TextSpan(text: 'By signing in you accept our\n'),
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
