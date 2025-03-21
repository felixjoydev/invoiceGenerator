import 'package:flutter/material.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HighlightedInvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const HighlightedInvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd/yyyy');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
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
            children: [
              // Left side - Company and invoice details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    invoice.client.name,
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
                        AppTheme.ensureVictorMonoUppercase(
                          dateFormat.format(
                            invoice.status == InvoiceStatus.paid
                                ? invoice.issueDate
                                : invoice.dueDate,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF768681),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF768681),
                          shape: BoxShape.circle,
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
                        AppTheme.ensureVictorMonoUppercase(invoice.invoiceId),
                        style: const TextStyle(
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF768681),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Right side - Amount and status text
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'USD',
                        style: TextStyle(
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF8D9694),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        invoice.total.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF3A3A3A),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTheme.ensureVictorMonoUppercase(_getStatusText(invoice)),
                    style: TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _getStatusColor(invoice),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get the status text for an invoice
  String _getStatusText(Invoice invoice) {
    switch (invoice.status) {
      case InvoiceStatus.overdue:
        final now = DateTime.now();
        final difference = now.difference(invoice.dueDate).inDays;
        return '$difference DAYS DUE';
      case InvoiceStatus.outstanding:
        final now = DateTime.now();
        final difference = invoice.dueDate.difference(now).inDays;
        return 'DUE IN $difference DAYS';
      case InvoiceStatus.paid:
        final dateFormat = DateFormat('MM/dd/yyyy');
        final displayDate =
            invoice.paidDate != null
                ? dateFormat.format(invoice.paidDate!)
                : dateFormat.format(invoice.issueDate);
        return 'PAID ON $displayDate';
    }
  }

  // Helper method to get the status color for an invoice
  Color _getStatusColor(Invoice invoice) {
    switch (invoice.status) {
      case InvoiceStatus.overdue:
        return const Color(0xFFD61443);
      case InvoiceStatus.outstanding:
        return const Color(0xFFD68814);
      case InvoiceStatus.paid:
        return const Color(0xFF13AF5B);
    }
  }
}
