import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

/// A secondary button with an icon and text
///
/// This button is used for secondary actions throughout the app.
/// It displays an icon followed by text, both in the specified color.
class SecondaryButton extends StatelessWidget {
  /// The icon to display on the left side of the button
  final IconType iconType;

  /// The text to display on the button
  final String text;

  /// The color of both the icon and text
  final Color color;

  /// Callback when the button is pressed
  final VoidCallback? onPressed;

  /// Creates a secondary button with an icon and text
  const SecondaryButton({
    Key? key,
    required this.iconType,
    required this.text,
    this.color = const Color(0xFFF05022),
    this.onPressed,
  }) : super(key: key);

  /// Creates an upload button (convenience constructor)
  factory SecondaryButton.upload({
    Key? key,
    VoidCallback? onPressed,
    Color color = const Color(0xFFF05022),
  }) {
    return SecondaryButton(
      key: key,
      iconType: IconType.upload,
      text: 'UPLOAD',
      color: color,
      onPressed: onPressed,
    );
  }

  /// Creates an "ADD FROM CATALOG" button (convenience constructor)
  factory SecondaryButton.addFromCatalog({
    Key? key,
    VoidCallback? onPressed,
    Color color = const Color(0xFFF05022),
  }) {
    return SecondaryButton(
      key: key,
      iconType: IconType.catalog,
      text: 'ADD FROM CATALOG',
      color: color,
      onPressed: onPressed,
    );
  }

  /// Creates an "ADD NEW ITEM" button (convenience constructor)
  factory SecondaryButton.addNewItem({
    Key? key,
    VoidCallback? onPressed,
    Color color = const Color(0xFFF05022),
  }) {
    return SecondaryButton(
      key: key,
      iconType: IconType.addItem,
      text: 'ADD NEW ITEM',
      color: color,
      onPressed: onPressed,
    );
  }

  /// Creates an "ADD ITEM" button (convenience constructor)
  factory SecondaryButton.addItem({
    Key? key,
    VoidCallback? onPressed,
    Color color = const Color(0xFFF05022),
  }) {
    return SecondaryButton(
      key: key,
      iconType: IconType.addItem,
      text: 'ADD ITEM',
      color: color,
      onPressed: onPressed,
    );
  }

  /// Creates an "EDIT" button (convenience constructor)
  factory SecondaryButton.edit({
    Key? key,
    VoidCallback? onPressed,
    Color color = const Color(0xFFF05022),
  }) {
    return SecondaryButton(
      key: key,
      iconType: IconType.editBox,
      text: 'EDIT',
      color: color,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(iconType: iconType, size: 24, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontFamily: 'Victor Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Keeping these classes for backwards compatibility
class UploadButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;

  const UploadButton({
    Key? key,
    this.onPressed,
    this.color = const Color(0xFFF05022),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SecondaryButton.upload(onPressed: onPressed, color: color);
  }
}

class CustomUploadIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomUploadIcon({Key? key, required this.size, required this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
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
    // Vertical line
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2 - 1,
        size.height / 2,
        2,
        size.height / 2 - 3,
      ),
      paint,
    );

    // Horizontal line at bottom
    canvas.drawRect(
      Rect.fromLTWH(size.width / 6, size.height - 3, size.width * 2 / 3, 2),
      paint,
    );

    // Left vertical small line
    canvas.drawRect(
      Rect.fromLTWH(size.width / 6, size.height - 9, 2, 6),
      paint,
    );

    // Right vertical small line
    canvas.drawRect(
      Rect.fromLTWH(size.width * 5 / 6 - 2, size.height - 9, 2, 6),
      paint,
    );

    // Arrow head - horizontal part
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 6, size.height / 3, 12, 2),
      paint,
    );

    // Arrow head - left diagonal
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 6, size.height / 3, 2, 2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 4, size.height / 3 - 2, 2, 2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 2, size.height / 3 - 4, 2, 2),
      paint,
    );

    // Arrow head - right diagonal
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 + 4, size.height / 3, 2, 2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 + 2, size.height / 3 - 2, 2, 2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 3 - 4, 2, 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
