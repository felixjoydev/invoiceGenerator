import 'package:flutter/material.dart';

class ClientAdd extends StatelessWidget {
  const ClientAdd({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CheckboxCustom(),
              SizedBox(width: 8),
              Text(
                'Acuro',
                style: TextStyle(
                  color: Color(0xFF3A3A3A),
                  fontSize: 16,
                  fontFamily: 'Helvetica Now Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: 32),
            child: Row(
              children: [
                Text(
                  '001',
                  style: TextStyle(
                    color: Color(0xFF76857F),
                    fontSize: 12,
                    fontFamily: 'Victor Mono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckboxCustom extends StatelessWidget {
  const CheckboxCustom({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color orangeColor = Color(0xFFF05022);
    final Color lightGrayColor = Color(0xFFDAE4E1);

    return Container(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          // Main rectangle
          Positioned(
            left: 5,
            top: 3,
            child: Container(
              width: 14,
              height: 16,
              color: orangeColor,
            ),
          ),
          // Bottom rectangle
          Positioned(
            left: 5,
            top: 19,
            child: Container(
              width: 14,
              height: 2,
              color: orangeColor,
            ),
          ),
          // Left rectangle
          Positioned(
            left: 3,
            top: 3,
            child: Container(
              width: 2,
              height: 18,
              color: orangeColor,
            ),
          ),
          // Right rectangle
          Positioned(
            left: 19,
            top: 3,
            child: Container(
              width: 2,
              height: 18,
              color: orangeColor,
            ),
          ),
          // Checkmark dots
          Positioned(
            left: 7,
            top: 12,
            child: Container(
              width: 2,
              height: 2,
              color: lightGrayColor,
            ),
          ),
          Positioned(
            left: 9,
            top: 14,
            child: Container(
              width: 2,
              height: 2,
              color: lightGrayColor,
            ),
          ),
          Positioned(
            left: 11,
            top: 12,
            child: Container(
              width: 2,
              height: 2,
              color: lightGrayColor,
            ),
          ),
          Positioned(
            left: 13,
            top: 10,
            child: Container(
              width: 2,
              height: 2,
              color: lightGrayColor,
            ),
          ),
          Positioned(
            left: 15,
            top: 8,
            child: Container(
              width: 2,
              height: 2,
              color: lightGrayColor,
            ),
          ),
        ],
      ),
    );
  }
}