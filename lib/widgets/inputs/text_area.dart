import 'package:flutter/material.dart';

class TextArea extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final Function(String)? onChanged;
  final String? errorText;
  final TextStyle? errorStyle;
  final AlignmentGeometry? errorAlignment;

  const TextArea({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 6,
    this.onChanged,
    this.errorText,
    this.errorStyle,
    this.errorAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF8D9694),
                fontSize: 14,
                fontFamily: 'Helvetica Now Display',
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFCAD5D2)),
                borderRadius: BorderRadius.circular(4),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFCAD5D2)),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF373C3A)),
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(
              fontFamily: 'Helvetica Now Display',
              fontSize: 14,
              color: Color(0xFF373C3A),
            ),
            onChanged: onChanged,
          ),
        ),
        if (errorText != null)
          Container(
            width: double.infinity,
            alignment: errorAlignment ?? Alignment.centerLeft,
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              errorText!,
              style:
                  errorStyle ??
                  const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Helvetica Now Display',
                  ),
            ),
          ),
      ],
    );
  }
}
