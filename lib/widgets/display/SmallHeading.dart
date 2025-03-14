import 'package:flutter/material.dart';

class SmallHeading extends StatelessWidget {
  final String title;
  
  const SmallHeading({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(118, 133, 129, 1),
            fontFamily: 'Helvetica Now Display',
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 4,
          color: Color.fromRGBO(202, 213, 210, 1),
        ),
      ],
    );
  }
}

// Usage example
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmallHeading(title: "Basic Details"),
            // Other content would go here
          ],
        ),
      ),
    );
  }
}