import 'package:flutter/material.dart';

class ClientChart extends StatelessWidget {
  final double amount;
  final double maxAmount;

  const ClientChart({Key? key, required this.amount, required this.maxAmount})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      color: Color(0xFFB7C2BF),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          // Calculate width as a proportion of max amount
          // Use at least 5% width for very small amounts to ensure visibility
          width:
              MediaQuery.of(context).size.width *
              (0.7 * (maxAmount > 0 ? (amount / maxAmount) : 0.05)).clamp(
                0.05,
                0.7,
              ),
          height: 12,
          color: Color(0xFF768681),
        ),
      ),
    );
  }
}
