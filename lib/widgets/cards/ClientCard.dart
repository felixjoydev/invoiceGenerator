import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientCard extends StatelessWidget {
  final String clientName;
  final String clientId;
  final int invoiceCount;
  final String? currency;
  final double? amount;
  final double? outstandingAmount;
  final double? dueAmount;
  final bool hasOutstanding;
  final bool hasDue;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const ClientCard({
    super.key,
    this.clientName = "Acuro",
    this.clientId = "001",
    this.invoiceCount = 2,
    this.currency = "USD",
    this.amount = 4500.00,
    this.outstandingAmount = 1000.00,
    this.dueAmount = 0.00,
    this.hasOutstanding = true,
    this.hasDue = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // Provide haptic feedback immediately
        HapticFeedback.mediumImpact();
        // Then call the callback
        if (onLongPress != null) {
          onLongPress!();
        }
      },
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Client info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(
                    fontFamily: 'Helvetica Now Display',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      clientId.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Victor Mono',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF778681),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF778681),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$invoiceCount invoices".toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Victor Mono',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF778681),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Right side - Financial info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currency != null && amount != null)
                  Row(
                    children: [
                      Text(
                        currency!.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF8D9694),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        amount!.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                if (hasOutstanding &&
                    currency != null &&
                    outstandingAmount != null)
                  Text(
                    "$currency ${outstandingAmount!.toStringAsFixed(0)} OUTSTANDING",
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFD68814),
                    ),
                  ),
                if (hasDue && currency != null && dueAmount != null)
                  Text(
                    "$currency ${dueAmount!.toStringAsFixed(0)} DUE",
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFD61443),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage
class ClientCardExample extends StatelessWidget {
  const ClientCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClientCard(),
              SizedBox(height: 16),
              ClientCard(
                clientName: "Nexus Corp",
                clientId: "002",
                invoiceCount: 5,
                currency: "EUR",
                amount: 7250.50,
                outstandingAmount: 2500.00,
              ),
              SizedBox(height: 16),
              ClientCard(
                clientName: "Vertex Inc",
                clientId: "003",
                invoiceCount: 1,
                currency: "GBP",
                amount: 1200.00,
                hasOutstanding: false,
              ),
              SizedBox(height: 16),
              ClientCard(
                clientName: "Quantum Ltd",
                clientId: "004",
                invoiceCount: 3,
                currency: "USD",
                amount: 3500.00,
                hasOutstanding: false,
                hasDue: true,
                dueAmount: 1500.00,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
