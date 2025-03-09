import 'package:flutter/material.dart';
import 'dart:math' as math;

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      child: Row(
        children: [
          _buildBarChartColumn('Jan', 83, false, false),
          SizedBox(width: 10),
          _buildBarChartColumn('Feb', 83, false, false),
          SizedBox(width: 10),
          _buildBarChartColumn('Mar', 66, false, false),
          SizedBox(width: 10),
          _buildBarChartColumn('Apr', 77, false, false),
          SizedBox(width: 10),
          _buildBarChartColumn('May', 105, false, false),
          SizedBox(width: 10),
          _buildBarChartColumn('Jun', 96, false, false),
          SizedBox(width: 10),
          _buildBarChartColumn('Jul', 87, true, false),
          SizedBox(width: 10),
          _buildBarChartColumn('Aug', 77, false, true),
          SizedBox(width: 10),
          _buildBarChartColumn('Sep', 83, false, true),
          SizedBox(width: 10),
          _buildBarChartColumn('Oct', 96, false, true),
          SizedBox(width: 10),
          _buildBarChartColumn('Nov', 83, false, true),
          SizedBox(width: 10),
          _buildBarChartColumn('Dec', 101, false, true),
        ],
      ),
    );
  }

  Widget _buildBarChartColumn(
    String month,
    double height,
    bool isHighlighted,
    bool isOutlined,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          isOutlined
              ? SizedBox(
                height: height,
                width: 18,
                child: CustomPaint(
                  painter: DashedRectanglePainter(
                    color: const Color(0xFFB7C2BF),
                  ),
                ),
              )
              : Container(
                height: height,
                width: 18,
                decoration: BoxDecoration(
                  color:
                      isHighlighted
                          ? const Color(0xFFF05022)
                          : const Color(0xFFB7C2BF),
                ),
              ),
          SizedBox(height: 3),
          Text(
            month,
            style: TextStyle(
              fontFamily: 'Aeonik',
              fontSize: 10,
              color: isHighlighted ? Color(0xFFF05022) : Color(0xFF8B9199),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing dashed rectangle borders
class DashedRectanglePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedRectanglePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 3.0,
    this.dashSpace = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;

    // Draw top line
    _drawDashedLine(canvas, paint, Offset(0, 0), Offset(width, 0));
    // Draw right line
    _drawDashedLine(canvas, paint, Offset(width, 0), Offset(width, height));
    // Draw bottom line
    _drawDashedLine(canvas, paint, Offset(width, height), Offset(0, height));
    // Draw left line
    _drawDashedLine(canvas, paint, Offset(0, height), Offset(0, 0));
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    // Calculate the length of the line
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);

    // Calculate the number of dash segments
    final int dashCount = (distance / (dashWidth + dashSpace)).floor();

    // Calculate the unit vector in the direction of the line
    final double unitDx = dx / distance;
    final double unitDy = dy / distance;

    // Draw the dashed line
    for (int i = 0; i < dashCount; i++) {
      final double startX = start.dx + i * (dashWidth + dashSpace) * unitDx;
      final double startY = start.dy + i * (dashWidth + dashSpace) * unitDy;
      final double endX = startX + dashWidth * unitDx;
      final double endY = startY + dashWidth * unitDy;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
