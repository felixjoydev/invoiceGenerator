import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Base container for navigation with consistent styling
class NavContainer extends StatelessWidget {
  final Widget child;

  const NavContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      color: const Color.fromRGBO(218, 228, 225, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: child,
    );
  }
}

/// Top navigation for the main app screens (after onboarding)
class TopNav extends StatelessWidget {
  final VoidCallback? onLogoPressed;
  final VoidCallback? onSettingsPressed;

  const TopNav({super.key, this.onLogoPressed, this.onSettingsPressed});

  @override
  Widget build(BuildContext context) {
    return NavContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo on the left (clickable for theme change)
          GestureDetector(
            onTap: onLogoPressed,
            child: SvgPicture.asset(
              'assets/icons/logo.svg',
              width: 32,
              height: 32,
              // No color filter to preserve original colors
            ),
          ),

          // Settings icon on the right (clickable for settings)
          GestureDetector(
            onTap: onSettingsPressed,
            child: SvgPicture.asset(
              'assets/icons/settings.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFF373C3A),
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A specialized version for the first time home screen
class HomeTopNav extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final VoidCallback onSettingsPressed;

  const HomeTopNav({
    super.key,
    required this.onThemeToggle,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TopNav(
      onLogoPressed: onThemeToggle,
      onSettingsPressed: onSettingsPressed,
    );
  }
}

/// Navigation for onboarding screens with back button
class OnboardingNav extends StatelessWidget {
  final VoidCallback onBackPressed;

  const OnboardingNav({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return NavContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Back button
          IconButton(
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
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// TopNav with a back button that shows only the back button
class TopNavWithBack extends StatelessWidget {
  final VoidCallback onBackPressed;

  const TopNavWithBack({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background container
        Container(
          width: double.infinity,
          height: 60,
          color: const Color.fromRGBO(218, 228, 225, 1),
        ),
        // Back button - using GestureDetector instead of IconButton to eliminate any implicit padding
        Positioned(
          left: 16, 
          top: 18, // Centered vertically (60 height - 24 icon height)/2 = 18
          child: GestureDetector(
            onTap: onBackPressed,
            child: SvgPicture.asset(
              'assets/icons/back.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFF373C3A),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}