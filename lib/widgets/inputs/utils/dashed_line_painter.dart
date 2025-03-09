import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({this.color = const Color(0xFFCAD5D2)});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5;
    double dashSpace = 3;
    double startX = 0;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
