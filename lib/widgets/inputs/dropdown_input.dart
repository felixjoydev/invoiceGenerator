import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'CURRENCY',
                style: TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF373C3A),
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Select currency',
                    style: TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontSize: 16,
                      color: Color(0xFF8D9694),
                    ),
                  ),
                  const SizedBox(width: 5),
                  AppIcon(
                    iconType: IconType.chevronRight,
                    size: 24,
                    color: const Color(0xFF373C3A),
                  ),
                ],
              ),
            ],
          ),
        ),
        CustomPaint(
          painter: DashedLinePainter(),
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
      ],
    );
  }
}

class CustomChevronIcon extends StatelessWidget {
  const CustomChevronIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: SizedBox(
        width: 14,
        height: 8,
        child: CustomPaint(painter: ChevronPainter()),
      ),
    );
  }
}

class ChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF373C3A)
          ..style = PaintingStyle.fill;

    // Draw the pixel art chevron
    canvas.drawRect(const Rect.fromLTWH(8, 5, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(10, 7, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(12, 9, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(14, 11, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(10, 15, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(8, 17, 2, 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// A generic dropdown selector field based on the CurrencySelector pattern
class GenericSelectorField extends StatelessWidget {
  final String label;
  final String hintText;

  const GenericSelectorField({
    Key? key,
    required this.label,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF373C3A),
                ),
              ),
              Row(
                children: [
                  Text(
                    hintText,
                    style: const TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontSize: 16,
                      color: Color(0xFF8D9694),
                    ),
                  ),
                  const SizedBox(width: 5),
                  AppIcon(
                    iconType: IconType.chevronRight,
                    size: 24,
                    color: const Color(0xFF373C3A),
                  ),
                ],
              ),
            ],
          ),
        ),
        CustomPaint(
          painter: DashedLinePainter(),
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
      ],
    );
  }
}
