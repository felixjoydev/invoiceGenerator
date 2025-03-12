import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/cards/ClientCard.dart';

class AnimatedClientCard extends StatefulWidget {
  final String clientName;
  final String clientId;
  final int? invoiceCount;
  final String? currency;
  final double? amount;
  final double? outstandingAmount;
  final bool? hasOutstanding;
  final double? dueAmount;
  final bool? hasDue;
  final VoidCallback onAnimationComplete;
  final VoidCallback? onLongPress;

  const AnimatedClientCard({
    super.key,
    required this.clientName,
    required this.clientId,
    this.invoiceCount,
    this.currency,
    this.amount,
    this.outstandingAmount,
    this.hasOutstanding,
    this.dueAmount,
    this.hasDue,
    required this.onAnimationComplete,
    this.onLongPress,
  });

  @override
  State<AnimatedClientCard> createState() => _AnimatedClientCardState();
}

class _AnimatedClientCardState extends State<AnimatedClientCard>
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

    // Setup slide animation (no actual movement - just to match AnimatedCatalogCard)
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
        child: ClientCard(
          clientName: widget.clientName,
          clientId: widget.clientId,
          invoiceCount: widget.invoiceCount ?? 0,
          currency: widget.currency,
          amount: widget.amount,
          outstandingAmount: widget.outstandingAmount,
          hasOutstanding: widget.hasOutstanding ?? false,
          dueAmount: widget.dueAmount,
          hasDue: widget.hasDue ?? false,
          onLongPress: widget.onLongPress,
        ),
      ),
    );
  }
}
