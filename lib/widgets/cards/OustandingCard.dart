import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';

class DueCard extends StatelessWidget {
  final String companyName;
  final String date;
  final String invoiceNumber;
  final String amount;
  final String daysText;
  final Color daysColor;

  const DueCard({
    Key? key,
    this.companyName = 'Acuro',
    this.date = '05/03/2025',
    this.invoiceNumber = 'inv-001',
    this.amount = '\$423.00',
    this.daysText = 'DUE IN 5 DAYS',
    this.daysColor = const Color(0xFFD68814),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - Company and invoice details
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  AppTheme.ensureVictorMonoUppercase(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Victor Mono',
                    color: Color(0xFF768681),
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF768681),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  AppTheme.ensureVictorMonoUppercase(invoiceNumber),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Victor Mono',
                    color: Color(0xFF768681),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Right side - Amount and due days
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Text(
                  'USD',
                  style: TextStyle(
                    color: Color(0xFF8D9694),
                    fontSize: 14,
                    fontFamily: 'Victor Mono',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(width: 7),
                Text(
                  amount.replaceAll('\$', ''),
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
            SizedBox(height: 4),
            Text(
              AppTheme.ensureVictorMonoUppercase(daysText),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Victor Mono',
                color: daysColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
