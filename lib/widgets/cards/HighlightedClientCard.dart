// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoicegenerator/models/client.dart';

class HighlightedClientCard extends StatelessWidget {
  final Client client;

  const HighlightedClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Provide haptic feedback
          HapticFeedback.lightImpact();

          // Dismiss keyboard when tapping on the card
          FocusScope.of(context).unfocus();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFDAE4E1),
            border: Border.all(color: const Color(0xFFCAD5D2)),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Client name
                    Text(
                      client.name,
                      style: const TextStyle(
                        color: Color(0xFF3A3A3A),
                        fontSize: 16,
                        fontFamily: 'Helvetica Now Display',
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Client ID and invoice count
                    Row(
                      children: [
                        // Client ID
                        Text(
                          client.clientId,
                          style: const TextStyle(
                            color: Color(0xFF768681),
                            fontSize: 12,
                            fontFamily: 'Victor Mono',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Dot separator
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: Color(0xFF768681),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Invoice count
                        Text(
                          '${client.invoiceCount} invoices',
                          style: const TextStyle(
                            color: Color(0xFF768681),
                            fontSize: 12,
                            fontFamily: 'Victor Mono',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount info on the right
              _buildAmountInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInfo() {
    final bool hasSpecialStatus = client.hasOutstanding || client.hasDue;

    // If client has no invoices or amount, show empty container
    if (client.invoiceCount == 0) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Total amount
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              client.currency,
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
              client.amount.toStringAsFixed(2),
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
        // Only show pending amount if there's a special status
        if (hasSpecialStatus) const SizedBox(height: 4),
        if (hasSpecialStatus)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      client.hasOutstanding
                          ? const Color(0xFFF05022)
                          : const Color(0xFFFFAA33),
                ),
              ),
              const SizedBox(width: 4),
              // Status text
              Text(
                client.hasOutstanding
                    ? 'Outstanding ${client.currency} ${client.outstandingAmount.toStringAsFixed(2)}'
                    : 'Due ${client.currency} ${client.dueAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color:
                      client.hasOutstanding
                          ? const Color(0xFFF05022)
                          : const Color(0xFFFFAA33),
                  fontSize: 12,
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
      ],
    );
  }
}
