import 'dart:math';
import 'package:flutter/material.dart';

class PixelRevealText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final bool autoStart;
  final VoidCallback? onAnimationComplete;

  const PixelRevealText({
    Key? key,
    required this.text,
    this.style = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF373C3A),
    ),
    this.duration = const Duration(milliseconds: 2000),
    this.autoStart = true,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<PixelRevealText> createState() => _PixelRevealTextState();
}

class _PixelRevealTextState extends State<PixelRevealText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pixelFadeOut;
  late Animation<double> _textFadeIn;

  // Pixel configuration
  final double pixelSize = 3;
  final double pixelSpacing = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Pixels fade out over the first 70% of animation
    _pixelFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Text fades in starting when pixels are at 30% opacity
    _textFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  void startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // The actual text (fading in)
            Opacity(
              opacity: _textFadeIn.value,
              child: Text(widget.text, style: widget.style),
            ),

            // The pixel version (fading out)
            if (_pixelFadeOut.value > 0)
              CustomPaint(
                painter: PixelTextPainter(
                  text: widget.text,
                  style: widget.style,
                  opacity: _pixelFadeOut.value,
                  pixelSize: pixelSize,
                  pixelDensity: 0.7,
                  jitterFactor:
                      0.4 *
                      (1.0 -
                          _controller
                              .value), // Reduce jitter as animation progresses
                ),
                size: _calculateTextSize(widget.text, widget.style),
              ),
          ],
        );
      },
    );
  }

  Size _calculateTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.size;
  }
}

class PixelTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double opacity;
  final double pixelSize;
  final double
  pixelDensity; // 0.0-1.0 (percentage of character covered by pixels)
  final double jitterFactor; // Random movement factor
  final Random _random = Random();

  PixelTextPainter({
    required this.text,
    required this.style,
    required this.opacity,
    this.pixelSize = 3.0,
    this.pixelDensity = 0.7,
    this.jitterFactor = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a text painter to calculate character positions
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    final pixelPaint =
        Paint()
          ..color = (style.color ?? const Color(0xFF373C3A)).withOpacity(
            opacity,
          )
          ..style = PaintingStyle.fill;

    // For each character, determine its bounding box and fill with pixels
    for (int i = 0; i < text.length; i++) {
      final charOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: i),
        Rect.zero,
      );

      // Get the offset for the next character to determine width
      final nextCharOffset =
          i < text.length - 1
              ? textPainter.getOffsetForCaret(
                TextPosition(offset: i + 1),
                Rect.zero,
              )
              : Offset(textPainter.width, 0);

      // Calculate the character width and height
      final charWidth = nextCharOffset.dx - charOffset.dx;
      final charHeight = textPainter.height;

      // Create a grid of pixels for this character
      final horizontalPixels = (charWidth / (pixelSize * 1.5)).floor();
      final verticalPixels = (charHeight / (pixelSize * 1.5)).floor();

      for (int x = 0; x < horizontalPixels; x++) {
        for (int y = 0; y < verticalPixels; y++) {
          // Use pixel density to determine if this pixel should be drawn
          if (_random.nextDouble() < pixelDensity) {
            // Calculate position with slight jitter
            final jitterX =
                jitterFactor > 0
                    ? (_random.nextDouble() * 2 - 1) * pixelSize * jitterFactor
                    : 0.0;
            final jitterY =
                jitterFactor > 0
                    ? (_random.nextDouble() * 2 - 1) * pixelSize * jitterFactor
                    : 0.0;

            final pixelX = charOffset.dx + x * (pixelSize * 1.5) + jitterX;
            final pixelY = y * (pixelSize * 1.5) + jitterY;

            canvas.drawRect(
              Rect.fromLTWH(pixelX, pixelY, pixelSize, pixelSize),
              pixelPaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelTextPainter oldDelegate) {
    return opacity != oldDelegate.opacity ||
        jitterFactor != oldDelegate.jitterFactor ||
        text != oldDelegate.text;
  }
}
