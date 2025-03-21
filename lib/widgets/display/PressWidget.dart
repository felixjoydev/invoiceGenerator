import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PressWidget extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMarkAsPaid;
  final bool showMarkAsPaid;
  final bool showEdit;

  const PressWidget({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.onMarkAsPaid,
    this.showMarkAsPaid = false,
    this.showEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDAE4E1),
        border: Border.all(color: const Color(0xFFCAD5D2), width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit option
          if (showEdit) ...[
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EDIT',
                      style: TextStyle(
                        color: Color(0xFFF05022),
                        fontSize: 14,
                        fontFamily: 'Victor Mono',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/edit-box.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFF05022),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Line divider after Edit
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFCAD5D2)),
            const SizedBox(height: 10),
          ],

          // Mark as Paid option
          if (showMarkAsPaid) ...[
            GestureDetector(
              onTap: onMarkAsPaid,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MARK AS PAID',
                      style: TextStyle(
                        color: Color(0xFF13AF5B),
                        fontSize: 14,
                        fontFamily: 'Victor Mono',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/paid-mark.svg',
                      width: 24,
                      height: 24,
                    ),
                  ],
                ),
              ),
            ),

            // Line divider after Mark as Paid
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFCAD5D2)),
            const SizedBox(height: 10),
          ],

          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DELETE',
                    style: TextStyle(
                      color: Color(0xFFD61443),
                      fontSize: 14,
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/delete.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFD61443),
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditBoxIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFF05022)
          ..style = PaintingStyle.fill;

    // Draw the icon using rectangles
    // Horizontal lines
    canvas.drawRect(const Rect.fromLTWH(2, 4, 8, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(2, 20, 18, 2), paint);

    // Vertical lines
    canvas.drawRect(const Rect.fromLTWH(2, 4, 2, 18), paint);
    canvas.drawRect(const Rect.fromLTWH(18, 14, 2, 8), paint);
    canvas.drawRect(const Rect.fromLTWH(6, 12, 2, 6), paint);

    // Other parts
    canvas.drawRect(const Rect.fromLTWH(6, 16, 6, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(8, 10, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(10, 8, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(12, 6, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(14, 4, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(16, 2, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(18, 4, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(20, 6, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(18, 8, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(16, 10, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(14, 12, 2, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(12, 14, 2, 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DeleteIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFD61443)
          ..style = PaintingStyle.fill;

    // Draw the delete icon
    // Horizontal lines
    canvas.drawRect(const Rect.fromLTWH(2, 6, 20, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(8, 2, 8, 2), paint);
    canvas.drawRect(const Rect.fromLTWH(4, 20, 16, 2), paint);

    // Vertical lines
    canvas.drawRect(const Rect.fromLTWH(4, 6, 2, 16), paint);
    canvas.drawRect(const Rect.fromLTWH(18, 6, 2, 16), paint);
    canvas.drawRect(const Rect.fromLTWH(8, 2, 2, 6), paint);
    canvas.drawRect(const Rect.fromLTWH(14, 2, 2, 6), paint);

    // Inner vertical lines
    canvas.drawRect(const Rect.fromLTWH(9, 10, 2, 8), paint);
    canvas.drawRect(const Rect.fromLTWH(13, 10, 2, 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
