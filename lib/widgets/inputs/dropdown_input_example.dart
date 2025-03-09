import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';

/// An improved version of the CurrencySelector using the AppIcon widget
class CurrencySelectorImproved extends StatelessWidget {
  const CurrencySelectorImproved({Key? key}) : super(key: key);

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
                  // Using the AppIcon widget instead of CustomPaint
                  Transform.rotate(
                    angle: -1.5708, // -90 degrees in radians
                    child: AppIcon(
                      iconType: IconType.chevronRight,
                      size: 24,
                      color: Color(0xFF373C3A),
                    ),
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
