import 'package:flutter/material.dart';
import 'package:invoicegenerator/models/catalog_item.dart';

class HighlightedCatalogCard extends StatelessWidget {
  final CatalogItem item;

  const HighlightedCatalogCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.usageInfo,
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF768681),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    item.currency,
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF8D9694),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.amount,
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
            ],
          ),
        ),
      ),
    );
  }
}
