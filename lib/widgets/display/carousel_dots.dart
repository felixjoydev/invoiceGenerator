import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

class ChipIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const ChipIndicator({Key? key, required this.count, this.currentIndex = 0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(right: index < count - 1 ? 5 : 0),
          child: AppIcon(
            iconType:
                index == currentIndex
                    ? IconType.activeDot
                    : IconType.inactiveDot,
            size: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// Keeping these classes for backwards compatibility, but they're no longer used
class ChipDot extends StatelessWidget {
  const ChipDot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(painter: ChipDotPainter()),
    );
  }
}

class ChipDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

    // Draw the complex shape
    final path = Path();

    // Center rectangle
    path.addRect(
      Rect.fromLTWH(
        size.width * 4.67 / 16,
        size.height * 4.67 / 16,
        size.width * 6.67 / 16,
        size.height * 6.67 / 16,
      ),
    );

    // Top rectangle
    path.addRect(
      Rect.fromLTWH(
        size.width * 4.67 / 16,
        size.height * 2 / 16,
        size.width * 6.67 / 16,
        size.height * 1.33 / 16,
      ),
    );

    // Bottom rectangle
    path.addRect(
      Rect.fromLTWH(
        size.width * 4.67 / 16,
        size.height * 12.67 / 16,
        size.width * 6.67 / 16,
        size.height * 1.33 / 16,
      ),
    );

    // Right rectangle
    path.addRect(
      Rect.fromLTWH(
        size.width * 12.67 / 16,
        size.height * 4.67 / 16,
        size.width * 1.33 / 16,
        size.height * 6.67 / 16,
      ),
    );

    // Left rectangle
    path.addRect(
      Rect.fromLTWH(
        size.width * 2 / 16,
        size.height * 4.67 / 16,
        size.width * 1.33 / 16,
        size.height * 6.67 / 16,
      ),
    );

    // Top-left corner
    path.addRect(
      Rect.fromLTWH(
        size.width * 3.33 / 16,
        size.height * 3.33 / 16,
        size.width * 1.33 / 16,
        size.height * 1.33 / 16,
      ),
    );

    // Top-right corner
    path.addRect(
      Rect.fromLTWH(
        size.width * 11.33 / 16,
        size.height * 3.33 / 16,
        size.width * 1.33 / 16,
        size.height * 1.33 / 16,
      ),
    );

    // Bottom-left corner
    path.addRect(
      Rect.fromLTWH(
        size.width * 3.33 / 16,
        size.height * 11.33 / 16,
        size.width * 1.33 / 16,
        size.height * 1.33 / 16,
      ),
    );

    // Bottom-right corner
    path.addRect(
      Rect.fromLTWH(
        size.width * 11.33 / 16,
        size.height * 11.33 / 16,
        size.width * 1.33 / 16,
        size.height * 1.33 / 16,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Example usage
class ChipIndicatorExample extends StatelessWidget {
  const ChipIndicatorExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: ChipIndicator(count: 3, currentIndex: 0));
  }
}
