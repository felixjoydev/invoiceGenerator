import 'dart:ui';
import 'package:flutter/material.dart';

/// Blurred overlay background when an item is selected
/// Used for long-press interactions
class BlurredBackground extends StatelessWidget {
  final VoidCallback onTap;

  const BlurredBackground({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: const Color(0xFF373C3A).withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}
