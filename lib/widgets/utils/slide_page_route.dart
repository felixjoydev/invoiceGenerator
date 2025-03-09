import 'package:flutter/material.dart';

/// Direction for slide animations
enum SlideDirection {
  /// Slide from right to left (forward)
  right,

  /// Slide from left to right (backward)
  left,

  /// Slide from bottom to top
  up,

  /// Slide from top to bottom
  down,
}

/// A custom page route that creates smooth sliding transitions
/// similar to native iOS app transitions.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  /// The widget to show as the new page
  final Widget page;

  /// The direction of the slide animation
  final SlideDirection direction;

  /// Duration of the animation
  final Duration duration;

  /// Creates a smooth sliding page transition
  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Apply a smooth curve to the animation
           final curve = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           // Define the slide offset based on direction
           Offset beginOffset;
           Offset endOffset = Offset.zero;

           switch (direction) {
             case SlideDirection.right:
               beginOffset = const Offset(1.0, 0.0);
               break;
             case SlideDirection.left:
               beginOffset = const Offset(-1.0, 0.0);
               break;
             case SlideDirection.up:
               beginOffset = const Offset(0.0, 1.0);
               break;
             case SlideDirection.down:
               beginOffset = const Offset(0.0, -1.0);
               break;
           }

           // Create the sliding animation
           final slideAnimation = Tween<Offset>(
             begin: beginOffset,
             end: endOffset,
           ).animate(curve);

           // Apply a fade effect along with the slide
           final fadeAnimation = Tween<double>(
             begin: 0.0,
             end: 1.0,
           ).animate(curve);

           // Combine fade and slide transitions
           return FadeTransition(
             opacity: fadeAnimation,
             child: SlideTransition(position: slideAnimation, child: child),
           );
         },
       );
}
