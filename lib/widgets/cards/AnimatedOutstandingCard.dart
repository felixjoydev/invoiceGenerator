import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/cards/OustandingCard.dart'
    as Outstanding;

class AnimatedOutstandingCard extends StatefulWidget {
  final String companyName;
  final String date;
  final String invoiceNumber;
  final String amount;
  final String daysText;
  final Color daysColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onAnimationComplete;

  const AnimatedOutstandingCard({
    super.key,
    required this.companyName,
    required this.date,
    required this.invoiceNumber,
    required this.amount,
    required this.daysText,
    required this.daysColor,
    this.onTap,
    this.onLongPress,
    required this.onAnimationComplete,
  });

  @override
  State<AnimatedOutstandingCard> createState() =>
      _AnimatedOutstandingCardState();
}

class _AnimatedOutstandingCardState extends State<AnimatedOutstandingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Setup fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Remove slide animation - items will simply appear in place
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0), // Changed from (0.0, 1.0) to (0.0, 0.0)
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animation when widget is built
    _controller.forward();

    // Setup animation completion callback
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait a bit before notifying that animation is complete
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onAnimationComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                widget.onTap ??
                () {
                  // Dismiss keyboard when tapping on the card
                  FocusScope.of(context).unfocus();
                },
            onLongPress: widget.onLongPress,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Outstanding.DueCard(
              companyName: widget.companyName,
              date: widget.date,
              invoiceNumber: widget.invoiceNumber,
              amount: widget.amount,
              daysText: widget.daysText,
              daysColor: widget.daysColor,
              onTap: null, // Handled by the InkWell
              onLongPress: null, // Handled by the InkWell
            ),
          ),
        ),
      ),
    );
  }
}
