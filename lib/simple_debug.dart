import 'package:flutter/material.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';

class SimpleDebugButton extends StatelessWidget {
  const SimpleDebugButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 20,
      child: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.home),
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
      ),
    );
  }
}
