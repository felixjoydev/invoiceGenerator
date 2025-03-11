import 'package:flutter/material.dart';

class ItemDivider extends StatelessWidget {
  final int number;
  final VoidCallback onDelete;
  final bool showDeleteButton;

  const ItemDivider({
    Key? key,
    required this.number,
    required this.onDelete,
    this.showDeleteButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 32,
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
      decoration: BoxDecoration(color: const Color(0xFFCAD5D2)),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Number Box
          Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: const Color(0xFF373C3A),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFDAE4E1),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
          // Delete Button
          if (showDeleteButton)
            GestureDetector(
              onTap: onDelete,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(painter: DeleteIconPainter()),
              ),
            ),
        ],
      ),
    );
  }
}

class DeleteIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = const Color(0xFF373C3A)
          ..style = PaintingStyle.fill;

    // Horizontal bar
    canvas.drawRect(Rect.fromLTWH(2, 6, 20, 2), paint);

    // Top handle
    canvas.drawRect(Rect.fromLTWH(8, 2, 8, 2), paint);

    // Bottom bar
    canvas.drawRect(Rect.fromLTWH(4, 20, 16, 2), paint);

    // Left vertical bar
    canvas.drawRect(Rect.fromLTWH(4, 6, 2, 16), paint);

    // Right vertical bar
    canvas.drawRect(Rect.fromLTWH(18, 6, 2, 16), paint);

    // Left handle support
    canvas.drawRect(Rect.fromLTWH(8, 2, 2, 6), paint);

    // Right handle support
    canvas.drawRect(Rect.fromLTWH(14, 2, 2, 6), paint);

    // Left trash line
    canvas.drawRect(Rect.fromLTWH(9, 10, 2, 8), paint);

    // Right trash line
    canvas.drawRect(Rect.fromLTWH(13, 10, 2, 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Example usage
class ItemDividerExample extends StatelessWidget {
  const ItemDividerExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ItemDivider(
          number: 1,
          onDelete: () {
            print('Delete pressed');
          },
        ),
      ),
    );
  }
}
