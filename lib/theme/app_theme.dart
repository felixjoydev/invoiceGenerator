import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFFF05022);
  // Primary Light and Dark to be defined

  // Text Colors
  static const Color textPrimary = Color(0xFF373C3A);
  static const Color textSecondary = Color(0xFF8B9199);
  static const Color textDisabled = Color(0xFFB6BAC0);

  // Background Colors
  static const Color background = Color(0xFFDAE4E1);

  // Status Colors
  static const Color statusPaid = Color(0xFF14D66D);
  static const Color statusOutstanding = Color(0xFFD68814);
  static const Color statusOverdue = Color(0xFFD61443);

  // Icon Colors
  static const Color iconPrimary = Color(0xFF373C3A);
  static const Color iconAccent = Color(0xFFF05022);

  // Divider Colors
  static const Color dividerColor = Color(0xFFCAD5D2);

  // Typography - Font Family 1: 'Helvetica Now Display'
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Helvetica Now Display',
    fontSize: 60,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Helvetica Now Display',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Helvetica Now Display',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF768581), // Specific color for heading3
  );

  static const TextStyle heading4 = TextStyle(
    fontFamily: 'Helvetica Now Display',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3B3B3B), // Specific color for titles inside cards
  );

  static const TextStyle bodyInputFilled = TextStyle(
    fontFamily: 'Helvetica Now Display',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static const TextStyle bodyInputPlaceholder = TextStyle(
    fontFamily: 'Helvetica Now Display',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF8D9694), // Specific color for placeholders
  );

  // Typography - Font Family 2: 'Victor Mono'
  static const TextStyle caption = TextStyle(
    fontFamily: 'Victor Mono',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Color(0xFF768581),
  );

  static const TextStyle inputFieldLabel = TextStyle(
    fontFamily: 'Victor Mono',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle firstTimeUserHeading = TextStyle(
    fontFamily: 'Victor Mono',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  // Button Styles
  static const ButtonStyle primaryButtonStyle = ButtonStyle(
    padding: MaterialStatePropertyAll<EdgeInsets>(
      EdgeInsets.symmetric(vertical: 12),
    ),
    backgroundColor: MaterialStatePropertyAll<Color>(primaryColor),
    shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
  );

  static const TextStyle primaryButtonText = TextStyle(
    fontFamily: 'Victor Mono',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle secondaryButtonText = TextStyle(
    fontFamily: 'Victor Mono',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle tertiaryButtonText = TextStyle(
    fontFamily: 'Victor Mono',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  // Input Field Styles
  static const double inputFieldHeight = 56;
  static const EdgeInsets inputFieldPadding = EdgeInsets.symmetric(
    vertical: 16,
  );
  static const BorderRadius inputFieldBorderRadius = BorderRadius.zero;

  // List Item Styles
  static const double listItemHeight = 56;
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(vertical: 16);
  static const BorderRadius listItemBorderRadius = BorderRadius.zero;

  // Card Styles
  static const CardTheme cardTheme = CardTheme(
    color: background,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  );

  // Spacing Scale
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing16 = 16;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;

  // Screen Padding
  static const EdgeInsets screenPadding = EdgeInsets.only(
    left: 20,
    right: 20,
    top: 80,
  );

  // Divider Styles
  static const Divider divider1 = Divider(
    height: 4,
    thickness: 4,
    color: dividerColor,
  );

  static const Divider divider2 = Divider(
    height: 1,
    thickness: 1,
    color: dividerColor,
  );

  // Note: Divider3 (dashed) will need a custom painter implementation

  // Theme Data
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      cardTheme: cardTheme,
      textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineMedium: heading4,
        bodyLarge: bodyInputFilled,
        bodyMedium: bodyInputPlaceholder,
        labelSmall: caption,
        labelMedium: inputFieldLabel,
        labelLarge: firstTimeUserHeading,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
