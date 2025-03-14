import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkipButton extends StatelessWidget {
  const SkipButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 39,
      height: 22,
      child: Text(
        'SKIP',
        style: GoogleFonts.getFont(
          'Victor Mono',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color.fromRGBO(240, 80, 34, 1), // Converted RGB values
          height: 1.0, // Default line height
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}