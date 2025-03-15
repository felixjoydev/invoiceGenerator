import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Generate PDF document from invoice data
  static Future<pw.Document> generateInvoicePdf(
    Invoice invoice,
    CompanyInfo companyInfo,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MM/dd/yyyy');

    // Load fonts
    final fontData = await rootBundle.load(
      'assets/fonts/HelveticaNowDisplay-Regular.ttf',
    );
    final fontBoldData = await rootBundle.load(
      'assets/fonts/HelveticaNowDisplay-Bold.ttf',
    );
    final ttfFont = pw.Font.ttf(fontData);
    final ttfFontBold = pw.Font.ttf(fontBoldData);

    // Define theme color
    final PdfColor themeColor = PdfColor.fromHex(
      '#C25018',
    ); // Orange like in sample
    final PdfColor backgroundColor = PdfColor.fromHex(
      '#E8E0CE',
    ); // Beige/tan background

    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttfFont, bold: ttfFontBold),
        build: (pw.Context context) {
          return pw.Container(
            color: backgroundColor,
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Invoice title and logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Invoice',
                      style: pw.TextStyle(
                        color: themeColor,
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      width: 140,
                      height: 80,
                      decoration: pw.BoxDecoration(color: themeColor),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'LOGO HERE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Company and Client Info
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Company Info (Left)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyInfo.businessName,
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 16,
                            ),
                          ),
                          pw.Text(
                            companyInfo.city,
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 16,
                            ),
                          ),
                          pw.Text(
                            companyInfo.country,
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Client Info (Right)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            invoice.client.name,
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 16,
                            ),
                          ),
                          if (companyInfo.addressLine1.isNotEmpty)
                            pw.Text(
                              companyInfo.addressLine1,
                              style: pw.TextStyle(
                                color: themeColor,
                                fontSize: 16,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'M: ${companyInfo.phone ?? "N/A"}',
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 16,
                            ),
                          ),
                          pw.Text(
                            'E: ${companyInfo.email ?? "N/A"}',
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 16,
                            ),
                          ),
                          pw.Text(
                            'W: ${companyInfo.website ?? "N/A"}',
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 50),

                // Invoice details - Invoice #, Date, etc.
                pw.Text(
                  'Invoice #: ${invoice.invoiceId}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Issue Date: ${dateFormat.format(invoice.issueDate)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Due Date: ${dateFormat.format(invoice.dueDate)}',
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 30),

                // Table Header
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'ITEM NAME',
                        style: pw.TextStyle(
                          color: themeColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'QTY',
                        style: pw.TextStyle(
                          color: themeColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'PRICE',
                        style: pw.TextStyle(
                          color: themeColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),

                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 8),
                  height: 2,
                  color: themeColor,
                ),

                // Invoice Items
                ...invoice.items.map(
                  (item) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            item.title,
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            item.quantity.toString(),
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 14,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${companyInfo.currency}${(item.amount is num ? (item.amount as num).toStringAsFixed(2) : (double.tryParse(item.amount.toString()) ?? 0.0).toStringAsFixed(2))}',
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 14,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 8),
                  height: 2,
                  color: themeColor,
                ),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Expanded(flex: 4, child: pw.Container()),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'SUBTOTAL',
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 14,
                                ),
                              ),
                              pw.Text(
                                '${invoice.subtotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 5),
                          if (companyInfo.enableTax && invoice.taxRate > 0)
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TAX (${invoice.taxRate.toStringAsFixed(0)}%)',
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 14,
                                  ),
                                ),
                                pw.Text(
                                  '${invoice.taxAmount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'TOTAL (${companyInfo.currency})',
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                '${invoice.total.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Notes section
                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'NOTES',
                    style: pw.TextStyle(
                      color: themeColor,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8),
                    height: 2,
                    color: themeColor,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(invoice.notes!, style: pw.TextStyle(fontSize: 12)),
                ],

                // Bank details
                if (companyInfo.bankName != null ||
                    companyInfo.accountNumber != null) ...[
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Please make the payment to this account:',
                    style: pw.TextStyle(color: themeColor, fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  if (companyInfo.accountHolder != null)
                    pw.Text(
                      companyInfo.accountHolder!,
                      style: pw.TextStyle(color: themeColor, fontSize: 12),
                    ),
                  if (companyInfo.bankName != null)
                    pw.Text(
                      companyInfo.bankName!,
                      style: pw.TextStyle(color: themeColor, fontSize: 12),
                    ),
                  if (companyInfo.accountNumber != null)
                    pw.Text(
                      companyInfo.accountNumber!,
                      style: pw.TextStyle(color: themeColor, fontSize: 12),
                    ),
                  if (companyInfo.ifscCode != null)
                    pw.Text(
                      'IFSC: ${companyInfo.ifscCode!}',
                      style: pw.TextStyle(color: themeColor, fontSize: 12),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  // Save the PDF to a file and share it
  static Future<void> sharePdf(Invoice invoice, CompanyInfo companyInfo) async {
    // Generate the PDF
    final pdf = await generateInvoicePdf(invoice, companyInfo);

    // Get temporary directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${invoice.invoiceId}.pdf');

    // Write to file
    await file.writeAsBytes(await pdf.save());

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Invoice ${invoice.invoiceId}',
      text: 'Invoice for ${invoice.client.name}',
    );
  }

  // Preview PDF (returns PDF data)
  static Future<Uint8List> previewPdf(
    Invoice invoice,
    CompanyInfo companyInfo,
  ) async {
    final pdf = await generateInvoicePdf(invoice, companyInfo);
    return pdf.save();
  }

  // Save the PDF to device
  static Future<String?> savePdf(
    Invoice invoice,
    CompanyInfo companyInfo,
  ) async {
    try {
      // Generate the PDF
      final pdf = await generateInvoicePdf(invoice, companyInfo);

      // Get directory for saving
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${invoice.invoiceId}.pdf');

      // Write to file
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      return null;
    }
  }
}
