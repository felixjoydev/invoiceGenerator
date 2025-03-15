import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/services/pdf_service.dart';

class InvoicePreview extends StatelessWidget {
  final Invoice invoice;
  final CompanyInfo companyInfo;

  const InvoicePreview({
    Key? key,
    required this.invoice,
    required this.companyInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceId}'),
        backgroundColor: const Color(0xFFDAE4E1),
        elevation: 0,
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await PdfService.sharePdf(invoice, companyInfo);
            },
          ),
          // Save button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final path = await PdfService.savePdf(invoice, companyInfo);
              if (path != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invoice saved to $path')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save invoice')),
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.previewPdf(invoice, companyInfo),
        allowPrinting: true,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
