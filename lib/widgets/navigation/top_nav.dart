import 'package:flutter/material.dart';

class TopNav extends StatelessWidget {
  const TopNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // This makes it stretch across the full width
      height: 60,
      color: const Color.fromRGBO(218, 228, 225, 1), // RGB: 0.855, 0.894, 0.882
    );
  }
}
