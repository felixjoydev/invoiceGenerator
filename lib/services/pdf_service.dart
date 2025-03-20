import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Generate PDF document from invoice data
  static Future<pw.Document> generateInvoicePdf(
    Invoice invoice,
    CompanyInfo companyInfo, {
    String? logoPath,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MM/dd/yyyy');

    // Load fonts
    final fontData = await rootBundle.load(
      'assets/fonts/HelveticaNowDisplay-Regular.ttf',
    );
    final fontBoldData = await rootBundle.load(
      'assets/fonts/HelveticaNowDisplay-Bold.ttf',
    );
    final victorMonoData = await rootBundle.load(
      'assets/fonts/VictorMono-Bold.ttf',
    );

    final ttfFont = pw.Font.ttf(fontData);
    final ttfFontBold = pw.Font.ttf(fontBoldData);
    final victorMonoFont = pw.Font.ttf(victorMonoData);

    // Define theme color
    final PdfColor themeColor = PdfColor.fromHex(
      '#CE5506',
    ); // Orange like in sample
    final PdfColor themeColorLight = PdfColor.fromHex('#E46512');
    final PdfColor dividerColor = PdfColor.fromHex('#F19F69');
    final PdfColor backgroundColor = PdfColor.fromHex('#E7E1CF');

    // Load logo image if path is provided
    pw.Widget? logoWidget;
    if (logoPath != null) {
      debugPrint('PDF Service - Logo path provided: $logoPath');
      try {
        final File logoFile = File(logoPath);
        final bool fileExists = logoFile.existsSync();
        debugPrint('PDF Service - Logo file exists: $fileExists');

        if (fileExists) {
          // Check if the file is an SVG
          final bool isSvg = logoPath.toLowerCase().endsWith('.svg');
          debugPrint('PDF Service - Is SVG file: $isSvg');

          if (isSvg) {
            // Create a colored box as a placeholder for SVG files
            debugPrint('PDF Service - Creating placeholder for SVG logo');
            logoWidget = pw.Container(
              width: 120,
              height: 75,
              color: themeColor,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'LOGO',
                style: pw.TextStyle(
                  font: victorMonoFont,
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          } else {
            // Regular bitmap image handling
            try {
              debugPrint('PDF Service - Reading logo file bytes');
              final Uint8List logoBytes = logoFile.readAsBytesSync();
              debugPrint(
                'PDF Service - Logo bytes length: ${logoBytes.length}',
              );

              // For non-SVG files, try to create an image
              final pw.Image logoImage = pw.Image(
                pw.MemoryImage(logoBytes),
                width: 120,
                height: 75,
                fit: pw.BoxFit.contain,
              );
              logoWidget = logoImage;
              debugPrint('PDF Service - Logo widget created successfully');
            } catch (e) {
              debugPrint('PDF Service - Error creating image: $e');
              // If image creation fails, create a placeholder
              logoWidget = pw.Container(
                width: 120,
                height: 75,
                color: themeColor,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'LOGO',
                  style: pw.TextStyle(
                    font: victorMonoFont,
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );
            }
          }
        } else {
          debugPrint(
            'PDF Service - Logo file does not exist at path: $logoPath',
          );

          // Create a placeholder for missing logo
          logoWidget = pw.Container(
            width: 120,
            height: 75,
            color: themeColor,
            alignment: pw.Alignment.center,
            child: pw.Text(
              'LOGO',
              style: pw.TextStyle(
                font: victorMonoFont,
                color: PdfColors.white,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('PDF Service - Error loading logo image for PDF: $e');

        // Create a placeholder on error
        logoWidget = pw.Container(
          width: 120,
          height: 75,
          color: themeColor,
          alignment: pw.Alignment.center,
          child: pw.Text(
            'LOGO',
            style: pw.TextStyle(
              font: victorMonoFont,
              color: PdfColors.white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      }
    } else {
      debugPrint('PDF Service - No logo path provided');
    }

    // Add page
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttfFont, bold: ttfFontBold),
          buildBackground: (pw.Context context) {
            // Fill the entire page with the beige background color
            return pw.Container(
              width: PdfPageFormat.a4.width,
              height: PdfPageFormat.a4.height,
              color: backgroundColor,
            );
          },
          margin: const pw.EdgeInsets.all(0), // No margin for the page
        ),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(32.0), // Exactly 32px padding
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Header section with Invoice title, logo and company details
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left side - Invoice title and bill to
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Invoice',
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 64,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(
                            height: 16,
                          ), // Reduced space to align with company address
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'BILL TO',
                                style: pw.TextStyle(
                                  font: victorMonoFont,
                                  color: themeColorLight,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    invoice.client.name,
                                    style: pw.TextStyle(
                                      color: themeColor,
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  // Combine address lines 1 and 2 on one line if both exist
                                  if (invoice.client.addressLine1 != null &&
                                      invoice.client.addressLine1!.isNotEmpty)
                                    pw.Text(
                                      invoice.client.addressLine2 != null &&
                                              invoice
                                                  .client
                                                  .addressLine2!
                                                  .isNotEmpty
                                          ? '${invoice.client.addressLine1}, ${invoice.client.addressLine2}'
                                          : invoice.client.addressLine1!,
                                      style: pw.TextStyle(
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.normal,
                                      ),
                                    ),
                                  // City, country, and zip in one line if available
                                  if ((invoice.client.city != null &&
                                          invoice.client.city!.isNotEmpty) ||
                                      (invoice.client.country != null &&
                                          invoice.client.country!.isNotEmpty) ||
                                      (invoice.client.zip != null &&
                                          invoice.client.zip!.isNotEmpty))
                                    pw.Text(
                                      [
                                            if (invoice.client.city != null &&
                                                invoice.client.city!.isNotEmpty)
                                              invoice.client.city,
                                            if (invoice.client.country !=
                                                    null &&
                                                invoice
                                                    .client
                                                    .country!
                                                    .isNotEmpty)
                                              invoice.client.country,
                                            if (invoice.client.zip != null &&
                                                invoice.client.zip!.isNotEmpty)
                                              invoice.client.zip,
                                          ]
                                          .where((element) => element != null)
                                          .join(', '),
                                      style: pw.TextStyle(
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.normal,
                                      ),
                                    ),
                                  // Contact details
                                  if (invoice.client.phone != null &&
                                      invoice.client.phone!.isNotEmpty)
                                    pw.Text(
                                      'M: ${invoice.client.phone}',
                                      style: pw.TextStyle(
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.normal,
                                      ),
                                    ),
                                  if (invoice.client.email != null &&
                                      invoice.client.email!.isNotEmpty)
                                    pw.Text(
                                      'E: ${invoice.client.email}',
                                      style: pw.TextStyle(
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.normal,
                                      ),
                                    ),
                                  if (invoice.client.website != null &&
                                      invoice.client.website!.isNotEmpty)
                                    pw.Text(
                                      'W: ${invoice.client.website}',
                                      style: pw.TextStyle(
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.normal,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Right side - Logo and company info
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Logo container - only show if we have a logo
                          if (logoWidget != null)
                            pw.Container(
                              width: 120,
                              height: 75,
                              child: logoWidget,
                            ),
                          pw.SizedBox(height: 16),
                          // Company details
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                companyInfo.businessName,
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              // Address line 1 and 2 in one line
                              if (companyInfo.addressLine1.isNotEmpty)
                                pw.Text(
                                  companyInfo.addressLine2 != null &&
                                          companyInfo.addressLine2!.isNotEmpty
                                      ? '${companyInfo.addressLine1}, ${companyInfo.addressLine2}'
                                      : companyInfo.addressLine1,
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              // City and ZIP in one line
                              if (companyInfo.city.isNotEmpty ||
                                  (companyInfo.zip != null &&
                                      companyInfo.zip!.isNotEmpty))
                                pw.Text(
                                  [
                                        if (companyInfo.city.isNotEmpty)
                                          companyInfo.city,
                                        if (companyInfo.zip != null &&
                                            companyInfo.zip!.isNotEmpty)
                                          companyInfo.zip,
                                      ]
                                      .where((element) => element != null)
                                      .join(', '),
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              // Country on a separate line
                              if (companyInfo.country.isNotEmpty)
                                pw.Text(
                                  companyInfo.country,
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              if (companyInfo.phone != null)
                                pw.Text(
                                  'M: ${companyInfo.phone}',
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              if (companyInfo.email != null)
                                pw.Text(
                                  'E: ${companyInfo.email}',
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              if (companyInfo.website != null)
                                pw.Text(
                                  'W: ${companyInfo.website}',
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 76),

                  // Invoice details section
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Top divider
                      pw.Divider(color: dividerColor, thickness: 1, height: 1),
                      pw.SizedBox(height: 16),

                      // Invoice ID, Issue Date, Due Date
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Invoice ID
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'INVOICE ID',
                                style: pw.TextStyle(
                                  font: victorMonoFont,
                                  color: themeColorLight,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                invoice.invoiceId,
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.normal,
                                ),
                              ),
                            ],
                          ),

                          // Issue Date
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'ISSUE DATE',
                                style: pw.TextStyle(
                                  font: victorMonoFont,
                                  color: themeColorLight,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                dateFormat.format(invoice.issueDate),
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.normal,
                                ),
                              ),
                            ],
                          ),

                          // Due Date
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'DUE DATE',
                                style: pw.TextStyle(
                                  font: victorMonoFont,
                                  color: themeColorLight,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                dateFormat.format(invoice.dueDate),
                                style: pw.TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 16),
                      // Bottom divider
                      pw.Divider(color: dividerColor, thickness: 1, height: 1),
                    ],
                  ),

                  pw.SizedBox(height: 17),

                  // Invoice items section
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Table header
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 338,
                            child: pw.Text(
                              'ITEM NAME',
                              style: pw.TextStyle(
                                font: victorMonoFont,
                                color: themeColorLight,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 24),
                          pw.Expanded(
                            flex: 82,
                            child: pw.Text(
                              'QTY',
                              style: pw.TextStyle(
                                font: victorMonoFont,
                                color: themeColorLight,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 24),
                          pw.Expanded(
                            flex: 122,
                            child: pw.Text(
                              'PRICE',
                              style: pw.TextStyle(
                                font: victorMonoFont,
                                color: themeColorLight,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 16),
                      // Thick divider
                      pw.Container(height: 4, color: dividerColor),

                      // Invoice Items
                      ...invoice.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isLastItem = index == invoice.items.length - 1;

                        return pw.Column(
                          children: [
                            pw.SizedBox(height: 16),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 338,
                                  child: pw.Text(
                                    item.title,
                                    style: pw.TextStyle(
                                      color: themeColor,
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.normal,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 24),
                                pw.Expanded(
                                  flex: 82,
                                  child: pw.Text(
                                    item.quantity.toString(),
                                    style: pw.TextStyle(
                                      color: themeColor,
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.normal,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 24),
                                pw.Expanded(
                                  flex: 122,
                                  child: pw.RichText(
                                    text: pw.TextSpan(
                                      children: [
                                        pw.TextSpan(
                                          text: companyInfo.currency,
                                          style: pw.TextStyle(
                                            font: victorMonoFont,
                                            color: themeColor,
                                            fontSize: 12,
                                            fontWeight: pw.FontWeight.normal,
                                          ),
                                        ),
                                        pw.TextSpan(
                                          text: ' ',
                                          style: pw.TextStyle(font: ttfFont),
                                        ),
                                        pw.TextSpan(
                                          text:
                                              (item.amount is num
                                                  ? (item.amount as num)
                                                      .toStringAsFixed(2)
                                                  : (double.tryParse(
                                                            item.amount
                                                                .toString(),
                                                          ) ??
                                                          0.0)
                                                      .toStringAsFixed(2)),
                                          style: pw.TextStyle(
                                            font: ttfFont,
                                            color: themeColor,
                                            fontSize: 12,
                                            fontWeight: pw.FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 16),
                            if (!isLastItem)
                              pw.Divider(
                                color: dividerColor,
                                thickness: 1,
                                height: 1,
                              ),
                          ],
                        );
                      }),

                      // Thick divider after items
                      pw.Container(height: 4, color: dividerColor),

                      pw.SizedBox(height: 16),
                      // Totals section
                      ...[
                        // SUBTOTAL Row
                        pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 338,
                              child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  'SUBTOTAL',
                                  style: pw.TextStyle(
                                    font: victorMonoFont,
                                    color: themeColorLight,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 24),
                            pw.Expanded(flex: 82, child: pw.Container()),
                            pw.SizedBox(width: 24),
                            pw.Expanded(
                              flex: 122,
                              child: pw.RichText(
                                text: pw.TextSpan(
                                  children: [
                                    pw.TextSpan(
                                      text: companyInfo.currency,
                                      style: pw.TextStyle(
                                        font: victorMonoFont,
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.normal,
                                      ),
                                    ),
                                    pw.TextSpan(
                                      text: ' ',
                                      style: pw.TextStyle(font: ttfFont),
                                    ),
                                    pw.TextSpan(
                                      text: invoice.subtotal.toStringAsFixed(2),
                                      style: pw.TextStyle(
                                        font: ttfFont,
                                        color: themeColor,
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 8),

                        // TAX Row (if tax rate is greater than 0)
                        if (invoice.taxRate > 0) ...[
                          pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 338,
                                child: pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    'TAX (${invoice.taxRate.toStringAsFixed(0)}%)',
                                    style: pw.TextStyle(
                                      font: victorMonoFont,
                                      color: themeColorLight,
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 24),
                              pw.Expanded(flex: 82, child: pw.Container()),
                              pw.SizedBox(width: 24),
                              pw.Expanded(
                                flex: 122,
                                child: pw.RichText(
                                  text: pw.TextSpan(
                                    children: [
                                      pw.TextSpan(
                                        text: companyInfo.currency,
                                        style: pw.TextStyle(
                                          font: victorMonoFont,
                                          color: themeColor,
                                          fontSize: 12,
                                          fontWeight: pw.FontWeight.normal,
                                        ),
                                      ),
                                      pw.TextSpan(
                                        text: ' ',
                                        style: pw.TextStyle(font: ttfFont),
                                      ),
                                      pw.TextSpan(
                                        text: invoice.taxAmount.toStringAsFixed(
                                          2,
                                        ),
                                        style: pw.TextStyle(
                                          font: ttfFont,
                                          color: themeColor,
                                          fontSize: 16,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                        ],

                        // TOTAL Row
                        pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 338,
                              child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  'TOTAL',
                                  style: pw.TextStyle(
                                    font: victorMonoFont,
                                    color: themeColorLight,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 24),
                            pw.Expanded(flex: 82, child: pw.Container()),
                            pw.SizedBox(width: 24),
                            pw.Expanded(
                              flex: 122,
                              child: pw.RichText(
                                text: pw.TextSpan(
                                  children: [
                                    pw.TextSpan(
                                      text: companyInfo.currency,
                                      style: pw.TextStyle(
                                        font: victorMonoFont,
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.normal,
                                      ),
                                    ),
                                    pw.TextSpan(
                                      text: ' ',
                                      style: pw.TextStyle(font: ttfFont),
                                    ),
                                    pw.TextSpan(
                                      text: invoice.total.toStringAsFixed(2),
                                      style: pw.TextStyle(
                                        font: ttfFont,
                                        color: themeColor,
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Notes section (if notes exist or bank details exist)
                  if (invoice.notes != null && invoice.notes!.isNotEmpty ||
                      companyInfo.bankName != null ||
                      companyInfo.accountNumber != null) ...[
                    pw.SizedBox(height: 17),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Text(
                          'NOTES',
                          style: pw.TextStyle(
                            font: victorMonoFont,
                            color: themeColorLight,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 16),
                        // Thick divider
                        pw.Container(height: 4, color: dividerColor),

                        pw.SizedBox(height: 16),

                        // Notes content
                        if (invoice.notes != null && invoice.notes!.isNotEmpty)
                          pw.Text(
                            invoice.notes!,
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.normal,
                            ),
                          ),

                        // Bank details
                        if (companyInfo.bankName != null ||
                            companyInfo.accountNumber != null) ...[
                          if (invoice.notes != null &&
                              invoice.notes!.isNotEmpty)
                            pw.SizedBox(height: 16),

                          pw.Text(
                            'Please make the payment to this account:',
                            style: pw.TextStyle(
                              color: themeColor,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.normal,
                            ),
                          ),
                          pw.SizedBox(height: 6),

                          // Bank details in columns
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (companyInfo.accountHolder != null)
                                pw.Text(
                                  companyInfo.accountHolder!,
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              if (companyInfo.bankName != null)
                                pw.Text(
                                  companyInfo.bankName!,
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              if (companyInfo.accountNumber != null)
                                pw.Text(
                                  companyInfo.accountNumber!,
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              if (companyInfo.ifscCode != null)
                                pw.Text(
                                  'IFSC: ${companyInfo.ifscCode!}',
                                  style: pw.TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // Save the PDF to a file and share it
  static Future<void> sharePdf(
    Invoice invoice,
    CompanyInfo companyInfo, {
    String? logoPath,
  }) async {
    // Generate the PDF
    final pdf = await generateInvoicePdf(
      invoice,
      companyInfo,
      logoPath: logoPath,
    );

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
    CompanyInfo companyInfo, {
    String? logoPath,
  }) async {
    final pdf = await generateInvoicePdf(
      invoice,
      companyInfo,
      logoPath: logoPath,
    );
    return pdf.save();
  }

  // Save the PDF to device
  static Future<String?> savePdf(
    Invoice invoice,
    CompanyInfo companyInfo, {
    String? logoPath,
  }) async {
    try {
      // Generate the PDF
      final pdf = await generateInvoicePdf(
        invoice,
        companyInfo,
        logoPath: logoPath,
      );

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
