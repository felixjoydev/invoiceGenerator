import 'package:flutter/material.dart';

class CatalogCard extends StatelessWidget {
  final String title;
  final String usageInfo;
  final String currency;
  final String amount;
  final VoidCallback? onLongPress;

  const CatalogCard({
    super.key,
    required this.title,
    required this.usageInfo,
    required this.currency,
    required this.amount,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Dismiss keyboard when tapping on the card
          FocusScope.of(context).unfocus();
        },
        onLongPress: onLongPress,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: 60, // Increased height for better touch detection
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF3A3A3A),
                      fontSize: 16,
                      fontFamily: 'Helvetica Now Display',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usageInfo,
                    style: const TextStyle(
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
                    style: const TextStyle(
                      color: Color(0xFF8D9694),
                      fontSize: 14,
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amount,
                    style: const TextStyle(
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
        ),
      ),
    );
  }
}

// Example usage
class CatalogCardExample extends StatelessWidget {
  const CatalogCardExample({super.key});

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
