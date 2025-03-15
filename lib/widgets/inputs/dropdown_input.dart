import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

class CurrencySelector extends StatelessWidget {
  final String? value;
  final String selectedCurrency;
  final Function(String currency)? onCurrencySelected;

  const CurrencySelector({
    super.key,
    this.value,
    this.selectedCurrency = 'USD',
    this.onCurrencySelected,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? selectedCurrency;

    return Column(
      children: [
        SizedBox(
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
                  Text(
                    displayValue,
                    style: const TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF373C3A),
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
  const CustomChevronIcon({super.key});

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

/// A generic field that displays a value and indicates it can be tapped to select
/// Used primarily for opening selection bottom sheets
class GenericSelectorField extends StatefulWidget {
  final String label;
  final String hintText;
  final String? value;
  final Function()? onTap;

  const GenericSelectorField({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    this.onTap,
  });

  @override
  State<GenericSelectorField> createState() => _GenericSelectorFieldState();
}

class _GenericSelectorFieldState extends State<GenericSelectorField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF373C3A),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        widget.value != null && widget.value!.isNotEmpty
                            ? widget.value!
                            : widget.hintText,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              widget.value != null && widget.value!.isNotEmpty
                                  ? const Color(0xFF373C3A)
                                  : const Color(0xFF8D9694),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF373C3A),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          painter: DashedLinePainter(color: const Color(0xFFCAD5D2)),
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
      ],
    );
  }
}
