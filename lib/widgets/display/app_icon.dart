import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A centralized widget for displaying custom app icons
///
/// This widget provides a unified way to display all custom icons in the app,
/// supporting both SVG icons from assets.
class AppIcon extends StatelessWidget {
  /// The type of icon to display
  final IconType iconType;

  /// The size of the icon (both width and height)
  final double size;

  /// The color to apply to the icon
  final Color? color;

  /// Creates an AppIcon with the specified type, size, and color
  const AppIcon({
    super.key,
    required this.iconType,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Get the appropriate asset path
    final String? assetPath = _getAssetPath();

    // Default color if none provided
    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.black;

    // If we don't have an asset path, show an error icon
    if (assetPath == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.error, color: iconColor, size: size),
      );
    }

    // Return the SVG icon
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        assetPath,
        height: size,
        width: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  /// Gets the asset path for the current icon type
  String? _getAssetPath() {
    switch (iconType) {
      case IconType.upload:
        return 'assets/icons/upload.svg';
      case IconType.chevronRight:
        return 'assets/icons/chevron-right.svg';
      case IconType.activeDot:
        return 'assets/icons/activeDot.svg';
      case IconType.inactiveDot:
        return 'assets/icons/inactiveDot.svg';
      case IconType.catalog:
        return 'assets/icons/catalog.svg';
      case IconType.addItem:
        return 'assets/icons/add-item.svg';
      case IconType.editBox:
        return 'assets/icons/edit-box.svg';
    }
  }
}

/// Enum representing all available icon types in the app
enum IconType {
  upload,
  chevronRight,
  activeDot,
  inactiveDot,
  catalog,
  addItem,
  editBox,
}
