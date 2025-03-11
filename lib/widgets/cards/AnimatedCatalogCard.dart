import 'package:flutter/material.dart';
import 'package:invoicegenerator/models/catalog_item.dart';

class AnimatedCatalogCard extends StatefulWidget {
  final CatalogItem item;
  final VoidCallback onAnimationComplete;
  final VoidCallback? onLongPress;

  const AnimatedCatalogCard({
    super.key,
    required this.item,
    required this.onAnimationComplete,
    this.onLongPress,
  });

  @override
  State<AnimatedCatalogCard> createState() => _AnimatedCatalogCardState();
}

class _AnimatedCatalogCardState extends State<AnimatedCatalogCard>
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

    // Setup slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
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
            onTap: () {
              // Dismiss keyboard when tapping on the card
              FocusScope.of(context).unfocus();
            },
            onLongPress: widget.onLongPress,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Simple text instead of pixel animation
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          color: Color(0xFF3A3A3A),
                          fontSize: 16,
                          fontFamily: 'Helvetica Now Display',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.usageInfo,
                        style: const TextStyle(
                          color: Color(0xFF768681),
                          fontSize: 12,
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.currency,
                        style: const TextStyle(
                          color: Color(0xFF8D9694),
                          fontSize: 14,
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.item.amount,
                        style: const TextStyle(
                          color: Color(0xFF3A3A3A),
                          fontSize: 16,
                          fontFamily: 'Helvetica Now Display',
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
