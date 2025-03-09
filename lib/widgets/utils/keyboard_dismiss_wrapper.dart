import 'package:flutter/material.dart';

/// A widget that dismisses the keyboard when tapping outside of input fields
class KeyboardDismissWrapper extends StatelessWidget {
  /// The child widget to be wrapped
  final Widget child;

  /// Whether to exclude the keyboard dismiss behavior
  final bool excludeFromSemantics;

  const KeyboardDismissWrapper({
    super.key,
    required this.child,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      excludeFromSemantics: excludeFromSemantics,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
