import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/cards/PaidCard.dart' as Paid;

class AnimatedPaidCard extends StatefulWidget {
  final String companyName;
  final String date;
  final String invoiceNumber;
  final String amount;
  final String daysText;
  final Color daysColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onAnimationComplete;

  const AnimatedPaidCard({
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
  State<AnimatedPaidCard> createState() => _AnimatedPaidCardState();
}

class _AnimatedPaidCardState extends State<AnimatedPaidCard>
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
      duration: const Duration(milliseconds: 500),
    );

    // Setup fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Remove slide animation - items will simply appear in place and fade in
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
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
            child: Paid.DueCard(
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
