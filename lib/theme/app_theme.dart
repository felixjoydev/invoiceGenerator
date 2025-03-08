import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color defaultPrimaryColor = Color(0xFFF05022);

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

  // Divider Styles
  static const Color dividerColor = Color(0xFFCAD5D2);

  // Create a light theme with a specific primary color
  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        background: background,
        surface: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
        error: statusOverdue,
        onError: Colors.white,
      ),
      fontFamily: 'Helvetica Now Display',
      textTheme: TextTheme(
        // Heading 1: 60px, Bold, #373C3A
        displayLarge: const TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 60,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        // Heading 2: 24px, Bold, #373C3A
        displayMedium: const TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        // Heading 3: 16px, Bold, #768581
        displaySmall: const TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF768581),
        ),
        // Heading 4: 16px, Bold, #3B3B3B (for titles inside cards)
        headlineMedium: const TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3B3B3B),
        ),
        // Body (Input field - filled): 16px, Regular, #373C3A
        bodyLarge: const TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        // Body (Input field - placeholder): 16px, Regular, #8D9694
        bodyMedium: const TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF8D9694),
        ),
        // Caption: 12px, Bold, #768581
        labelSmall: const TextStyle(
          fontFamily: 'Victor Mono',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF768581),
        ),
        // Input field label: 14px, Bold, #373C3A
        labelMedium: const TextStyle(
          fontFamily: 'Victor Mono',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        // First-time user heading: 16px, Bold, #373C3A
        labelLarge: const TextStyle(
          fontFamily: 'Victor Mono',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: dividerColor,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: dividerColor,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: primaryColor,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: statusOverdue,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Victor Mono',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF8D9694),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Victor Mono',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Victor Mono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardTheme(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(vertical: 16),
        minLeadingWidth: 0,
        dense: true,
      ),
    );
  }

  // Create a dark theme (if needed)
  static ThemeData darkTheme(Color primaryColor) {
    // For future implementation
    return lightTheme(primaryColor);
  }

  // Spacing constants
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing16 = 16;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.only(
    left: 20,
    right: 20,
    top: 80,
  );
}
