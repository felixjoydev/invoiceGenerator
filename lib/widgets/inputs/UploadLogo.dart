import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';

class UploadLogoSection extends StatelessWidget {
  final Function(String path)? onLogoSelected;

  const UploadLogoSection({super.key, this.onLogoSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPLOAD LOGO',
                      style: TextStyle(
                        fontFamily: 'Victor Mono',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF373C3A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREFERRED IMAGE SIZE',
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            color: Color(0xFF8D9694),
                          ),
                        ),
                        Text(
                          '240px x 240px @72 DPI',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: Color(0xFF373C3A),
                          ),
                        ),
                        Text(
                          'Max size of 1MB',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: Color(0xFF373C3A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SecondaryButton.upload(
                  onPressed: () {
                    // Mock logo upload for now
                    if (onLogoSelected != null) {
                      onLogoSelected!('path/to/logo.png');
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 1,
            child: CustomPaint(
              painter: DashedLinePainter(),
              size: Size(double.infinity, 1),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomUploadIcon extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const CustomUploadIcon({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: UploadIconPainter(color: color)),
    );
  }
}

class UploadIconPainter extends CustomPainter {
  final Color color;

  UploadIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw the upload icon
    final Path path = Path();

    // Vertical line
    path.addRect(
      Rect.fromLTWH(
        size.width / 2 - 1,
        size.height / 2,
        2,
        size.height / 2 - 3,
      ),
    );

    // Horizontal line at bottom
    path.addRect(
      Rect.fromLTWH(size.width / 4, size.height - 3, size.width / 2, 2),
    );

    // Arrow head
    path.moveTo(size.width / 2, size.height / 4);
    path.lineTo(size.width / 3, size.height / 2.5);
    path.lineTo(size.width * 2 / 3, size.height / 2.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
