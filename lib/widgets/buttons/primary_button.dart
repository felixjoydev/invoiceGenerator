import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isEnabled;

  const PrimaryButton({
    super.key,
    this.onPressed,
    this.label = 'CONTINUE',
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled
                  ? const Color.fromRGBO(240, 80, 34, 1)
                  : const Color.fromRGBO(
                    240,
                    80,
                    34,
                    0.5,
                  ), // Reduced opacity when disabled
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Victor Mono',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
