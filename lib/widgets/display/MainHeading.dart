import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Enum representing the available heading icon types
enum HeadingIconType {
  company, // company.svg
  address, // address.svg
  contact, // contact.svg
  logo, // logo.svg
  back, // back.svg
  none, // No icon
}

/// A reusable heading component for section headers
class MainHeading extends StatelessWidget {
  /// The text to display in the heading
  final String text;

  /// The type of icon to display (or none)
  final HeadingIconType iconType;

  /// Creates a MainHeading with the specified text and icon type
  const MainHeading({
    Key? key,
    this.text = 'Company Details',
    this.iconType = HeadingIconType.company,
  }) : super(key: key);

  /// Creates a MainHeading specifically for business details
  factory MainHeading.business({Key? key}) => MainHeading(
    key: key,
    text: 'Business Details',
    iconType: HeadingIconType.back,
  );

  /// Creates a MainHeading specifically for invoice settings
  factory MainHeading.invoiceSettings({Key? key}) => MainHeading(
    key: key,
    text: 'Invoice Settings',
    iconType: HeadingIconType.back,
  );

  /// Creates a MainHeading specifically for client settings
  factory MainHeading.clientSettings({Key? key}) => MainHeading(
    key: key,
    text: 'Client Settings',
    iconType: HeadingIconType.back,
  );

  /// Creates a MainHeading specifically for company address
  factory MainHeading.address({Key? key}) => MainHeading(
    key: key,
    text: 'Company Address',
    iconType: HeadingIconType.address,
  );

  /// Creates a MainHeading specifically for contact details
  factory MainHeading.contact({Key? key}) => MainHeading(
    key: key,
    text: 'Contact Details',
    iconType: HeadingIconType.contact,
  );

  /// Creates a MainHeading specifically for settings
  factory MainHeading.settings({Key? key}) =>
      MainHeading(key: key, text: 'Settings', iconType: HeadingIconType.logo);

  /// Creates a MainHeading without an icon
  factory MainHeading.noIcon({Key? key, required String text}) =>
      MainHeading(key: key, text: text, iconType: HeadingIconType.none);

  /// Gets the SVG asset path for the icon
  String? _getIconPath() {
    switch (iconType) {
      case HeadingIconType.company:
        return 'assets/icons/company.svg';
      case HeadingIconType.address:
        return 'assets/icons/address.svg';
      case HeadingIconType.contact:
        return 'assets/icons/contact.svg';
      case HeadingIconType.logo:
        return 'assets/icons/logo.svg';
      case HeadingIconType.back:
        return 'assets/icons/back.svg';
      case HeadingIconType.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show icon if it's not 'none'
            if (iconType != HeadingIconType.none) ...[
              _buildIcon(),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF373C3A),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Helvetica Now Display',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 4,
          width: double.infinity,
          color: const Color(0xFFCAD5D2),
        ),
      ],
    );
  }

  /// Builds the appropriate icon widget
  Widget _buildIcon() {
    final iconPath = _getIconPath();

    if (iconPath == null) {
      return const SizedBox(width: 24, height: 24);
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: SvgPicture.asset(
        iconPath,
        colorFilter: const ColorFilter.mode(Color(0xFF373C3A), BlendMode.srcIn),
      ),
    );
  }
}
