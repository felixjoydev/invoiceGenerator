import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/services/pdf_service.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/screens/invoices/invoice_create_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:invoicegenerator/services/invoice_service.dart';
import 'package:invoicegenerator/services/company_service.dart';

class InvoicePreview extends StatelessWidget {
  final Invoice invoice;
  final CompanyInfo companyInfo;
  final String? logoPath;

  const InvoicePreview({
    super.key,
    required this.invoice,
    required this.companyInfo,
    this.logoPath,
  });

  // Helper method to get template by name
  PdfTemplate _getTemplateByName(String name) {
    return PdfTemplate.allTemplates.firstWhere(
      (template) => template.name == name,
      orElse: () => PdfTemplate.defaultTemplate,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add debugging for logo path
    debugPrint('InvoicePreview - Logo path: $logoPath');
    if (logoPath != null) {
      final logoFile = File(logoPath!);
      final exists = logoFile.existsSync();
      debugPrint(
        'InvoicePreview - Logo file exists: $exists (path: $logoPath)',
      );
    }

    // Get the template from invoice template name
    final template = _getTemplateByName(invoice.templateName);

    // Convert PdfColor to Flutter Color for background
    final backgroundColor = Color.fromARGB(
      255,
      (template.backgroundColor.red * 255).round(),
      (template.backgroundColor.green * 255).round(),
      (template.backgroundColor.blue * 255).round(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFDAE4E1),
      body: Column(
        children: [
          // Top section with invoice header and PDF Preview
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top section with invoice header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InvoiceHeader(
                      clientName: invoice.client.name,
                      issueDate: DateFormat(
                        'MM/dd/yyyy',
                      ).format(invoice.issueDate),
                      invoiceId: invoice.invoiceId,
                      currency: companyInfo.currency,
                      amount: invoice.total.toStringAsFixed(2),
                      dueDate: DateFormat('MM/dd/yyyy').format(invoice.dueDate),
                    ),
                  ),

                  // PDF Preview - Use Expanded to take remaining space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio:
                              1 / 1.414, // A4 aspect ratio (210×297 mm)
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(
                                    128,
                                    128,
                                    128,
                                    0.08,
                                  ),
                                  blurRadius: 0,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 0),
                                ),
                                BoxShadow(
                                  color: const Color.fromRGBO(
                                    128,
                                    128,
                                    128,
                                    0.08,
                                  ),
                                  blurRadius: 1,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 1),
                                ),
                                BoxShadow(
                                  color: const Color.fromRGBO(
                                    128,
                                    128,
                                    128,
                                    0.08,
                                  ),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: const Color.fromRGBO(
                                    128,
                                    128,
                                    128,
                                    0.08,
                                  ),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRect(
                              child: Material(
                                color: backgroundColor,
                                child: MediaQuery(
                                  data: MediaQuery.of(
                                    context,
                                  ).copyWith(padding: EdgeInsets.zero),
                                  child: PdfPreview(
                                    key: UniqueKey(),
                                    build:
                                        (format) => PdfService.previewPdf(
                                          invoice,
                                          companyInfo,
                                          logoPath: logoPath,
                                          template: template,
                                        ),
                                    allowPrinting: false,
                                    allowSharing: false,
                                    canChangeOrientation: false,
                                    canChangePageFormat: false,
                                    canDebug: false,
                                    useActions: false,
                                    padding: EdgeInsets.zero,
                                    previewPageMargin: EdgeInsets.zero,
                                    pdfPreviewPageDecoration: null,
                                    scrollViewDecoration: const BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                    maxPageWidth:
                                        double
                                            .infinity, // Take available width in aspect ratio
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InvoiceActionButtons(
                      onEditPressed: () {
                        // Navigate to edit screen with invoice data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    InvoiceCreateScreen(invoiceToEdit: invoice),
                          ),
                        ).then((_) async {
                          // Refresh the preview by fetching the latest invoice data
                          final invoiceService = InvoiceService();
                          await invoiceService.init();

                          // Refresh company info
                          final companyService = CompanyService();
                          await companyService.init();
                          final latestCompanyInfo = companyService.companyInfo;

                          if (latestCompanyInfo != null) {
                            // Find the updated invoice using its ID
                            final updatedInvoices =
                                invoiceService.getAllInvoices();
                            final updatedInvoice = updatedInvoices.firstWhere(
                              (inv) => inv.invoiceId == invoice.invoiceId,
                              orElse:
                                  () =>
                                      invoice, // Fallback to original invoice if not found
                            );

                            // Navigate to a new instance of InvoicePreview with the updated invoice
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder:
                                    (context) => InvoicePreview(
                                      invoice: updatedInvoice,
                                      companyInfo: latestCompanyInfo,
                                      logoPath: latestCompanyInfo.logoPath,
                                    ),
                              ),
                            );
                          }
                        });
                      },
                      onDownloadPressed: () async {
                        final path = await PdfService.savePdf(
                          invoice,
                          companyInfo,
                          logoPath: logoPath,
                          template: template,
                        );
                        if (path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invoice saved to $path')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save invoice'),
                            ),
                          );
                        }
                      },
                      onSharePressed: () async {
                        await PdfService.sharePdf(
                          invoice,
                          companyInfo,
                          logoPath: logoPath,
                          template: template,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom section with pattern and button (not in SafeArea)
          const ZigzagPattern(),

          // Orange background with SafeArea for the text
          Container(
            width: double.infinity,
            color: const Color(0xFFF05022),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.only(top: 8),
                height: 72,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder:
                            (context) => InvoiceListScreen(
                              invoiceIdToAnimate: invoice.invoiceId,
                            ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Invoice header with client info and amount
class InvoiceHeader extends StatelessWidget {
  final String clientName;
  final String issueDate;
  final String invoiceId;
  final String currency;
  final String amount;
  final String dueDate;

  const InvoiceHeader({
    Key? key,
    required this.clientName,
    required this.issueDate,
    required this.invoiceId,
    required this.currency,
    required this.amount,
    required this.dueDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Company and invoice info
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
              const SizedBox(height: 7),
              Row(
                children: [
                  Text(
                    issueDate,
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF778682),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF778682),
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
                    invoiceId,
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF778682),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right side - Amount and due date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currency,
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF8D9694),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amount,
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
              Text(
                'DUE ON $dueDate',
                style: const TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF778682),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Action buttons for edit, download and share with dashed borders
class InvoiceActionButtons extends StatelessWidget {
  final VoidCallback onEditPressed;
  final VoidCallback onDownloadPressed;
  final VoidCallback onSharePressed;

  const InvoiceActionButtons({
    Key? key,
    required this.onEditPressed,
    required this.onDownloadPressed,
    required this.onSharePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // EDIT BUTTON
          Expanded(
            child: GestureDetector(
              onTap: onEditPressed,
              child: CustomPaint(
                painter: DashedBorderPainter(
                  sides: const {
                    BorderSide.top,
                    BorderSide.bottom,
                    BorderSide.left,
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/edit-box.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFF05022),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'EDIT',
                        style: TextStyle(
                          color: Color(0xFFF05022),
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // DOWNLOAD BUTTON
          Expanded(
            child: GestureDetector(
              onTap: onDownloadPressed,
              child: CustomPaint(
                painter: DashedBorderPainter(
                  sides: const {
                    BorderSide.top,
                    BorderSide.bottom,
                    BorderSide.left,
                    BorderSide.right,
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/download.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFF05022),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'DOWNLOAD',
                        style: TextStyle(
                          color: Color(0xFFF05022),
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SHARE BUTTON
          Expanded(
            child: GestureDetector(
              onTap: onSharePressed,
              child: CustomPaint(
                painter: DashedBorderPainter(
                  sides: const {
                    BorderSide.top,
                    BorderSide.bottom,
                    BorderSide.right,
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/share.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFF05022),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'SHARE',
                        style: TextStyle(
                          color: Color(0xFFF05022),
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Zigzag pattern with sharp edges at the bottom
class ZigzagPattern extends StatelessWidget {
  const ZigzagPattern({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 8,
      child: CustomPaint(painter: ZigzagPatternPainter()),
    );
  }
}

class ZigzagPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFF05022)
          ..style = PaintingStyle.fill;

    final path = Path();
    const zigzagHeight = 8.0;
    const zigzagWidth = 16.0;

    // Start from top-left
    path.moveTo(0, 0);

    // Draw sharp zigzag pattern
    double currentX = 0;
    while (currentX < size.width) {
      // Draw down diagonal line
      path.lineTo(currentX + zigzagWidth / 2, zigzagHeight);

      // Draw up diagonal line (if not at the end)
      if (currentX + zigzagWidth < size.width) {
        path.lineTo(currentX + zigzagWidth, 0);
      }

      currentX += zigzagWidth;
    }

    // Complete the shape by drawing to bottom-right, bottom-left and back to start
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom border painter to create dashed borders
class DashedBorderPainter extends CustomPainter {
  final Set<BorderSide> sides;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    this.sides = const {BorderSide.all},
    this.color = const Color(0xFFCAD5D2),
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Top border
    if (sides.contains(BorderSide.top) || sides.contains(BorderSide.all)) {
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, 0),
          Offset(startX + dashWidth, 0),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Right border
    if (sides.contains(BorderSide.right) || sides.contains(BorderSide.all)) {
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(size.width, startY),
          Offset(size.width, startY + dashWidth),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    }

    // Bottom border
    if (sides.contains(BorderSide.bottom) || sides.contains(BorderSide.all)) {
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, size.height),
          Offset(startX + dashWidth, size.height),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Left border
    if (sides.contains(BorderSide.left) || sides.contains(BorderSide.all)) {
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(0, startY),
          Offset(0, startY + dashWidth),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// BorderSide enum for dashed border painter
enum BorderSide { top, right, bottom, left, all }
