import 'package:flutter/material.dart';

class CatalogCard extends StatelessWidget {
  final String title;
  final String usageInfo;
  final String currency;
  final String amount;

  const CatalogCard({
    Key? key,
    required this.title,
    required this.usageInfo,
    required this.currency,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Color(0xFF3A3A3A),
                  fontSize: 16,
                  fontFamily: 'Helvetica Now Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                usageInfo,
                style: TextStyle(
                  color: Color(0xFF768681),
                  fontSize: 12,
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currency,
                style: TextStyle(
                  color: Color(0xFF8D9694),
                  fontSize: 14,
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(width: 4),
              Text(
                amount,
                style: TextStyle(
                  color: Color(0xFF3A3A3A),
                  fontSize: 16,
                  fontFamily: 'Helvetica Now Display',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Example usage
class CatalogCardExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CatalogCard(
          title: "Website Design",
          usageInfo: "USED IN 2 INVOICES",
          currency: "USD",
          amount: "4500.00",
        ),
      ),
    );
  }
}