import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/models/invoice.dart';
import 'package:invoicegenerator/models/company_info.dart';
import 'package:invoicegenerator/services/pdf_service.dart';
import 'package:invoicegenerator/screens/invoices/invoice_create_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/services/invoice_service.dart';

/// Shows a bottom sheet with a preview of the invoice and actions
void showInvoicePreviewSheet({
  required BuildContext context,
  required Invoice invoice,
  required CompanyInfo companyInfo,
  String? logoPath,
  required int currentTabIndex,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return InvoicePreviewSheet(
        invoice: invoice,
        companyInfo: companyInfo,
        logoPath: logoPath,
        currentTabIndex: currentTabIndex,
      );
    },
  );
}

class InvoicePreviewSheet extends StatelessWidget {
  final Invoice invoice;
  final CompanyInfo companyInfo;
  final String? logoPath;
  final int currentTabIndex;

  const InvoicePreviewSheet({
    super.key,
    required this.invoice,
    required this.companyInfo,
    this.logoPath,
    required this.currentTabIndex,
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
    debugPrint('InvoicePreviewSheet - Logo path: $logoPath');
    if (logoPath != null) {
      final logoFile = File(logoPath!);
      final exists = logoFile.existsSync();
      debugPrint(
        'InvoicePreviewSheet - Logo file exists: $exists (path: $logoPath)',
      );
    }

    // Get the template from invoice template name
    final template = _getTemplateByName(invoice.templateName);

    // Convert PdfColor to Flutter Color for PDF preview background
    final backgroundColor = Color.fromARGB(
      255,
      (template.backgroundColor.red * 255).round(),
      (template.backgroundColor.green * 255).round(),
      (template.backgroundColor.blue * 255).round(),
    );

    // Calculate the height to be almost full screen
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.9;

    // Get invoice service
    final invoiceService = InvoiceService();

    // Define handlers for delete and mark as paid
    void handleDeleteInvoice() {
      // Show confirmation dialog
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder:
            (context) => Dialog(
              backgroundColor: const Color(
                0xFFDAE4E1,
              ), // Background color from theme
              insetPadding: const EdgeInsets.all(20),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No rounded corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with MainHeading style
                    const Text(
                      'Delete Invoice',
                      style: TextStyle(
                        color: Color(0xFF373C3A),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Helvetica Now Display',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 4,
                      width: double.infinity,
                      color: const Color(0xFFCAD5D2),
                    ),
                    const SizedBox(height: 24),

                    // Content text
                    const Text(
                      'Are you sure you want to delete this invoice?',
                      style: TextStyle(
                        fontFamily: 'Helvetica Now Display',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF373C3A),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Actions row
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Align to the end
                      children: [
                        // Cancel button - text only
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                color: Color(0xFF373C3A),
                                fontSize: 14,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Add fixed spacing between buttons
                        const SizedBox(width: 24),

                        // Delete button - secondary button style with icon
                        InkWell(
                          onTap: () {
                            // Delete the invoice
                            invoiceService.deleteInvoice(invoice.invoiceId);

                            // Close the dialog
                            Navigator.of(context).pop();

                            // Close the bottom sheet
                            Navigator.of(context).pop();

                            // Save scroll position before navigating
                            InvoiceListScreen.saveScrollPositionForCurrentTab(
                              context,
                              currentTabIndex,
                            );

                            // Navigate back to invoice list and show message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Invoice ${invoice.invoiceId} deleted',
                                ),
                                backgroundColor: const Color(0xFFD61443),
                              ),
                            );

                            // Return to invoice list with correct tab
                            InvoiceListScreen.navigateWithTab(
                              context,
                              tabIndex: currentTabIndex,
                              invoiceIdToAnimate:
                                  null, // No animation for deleted invoice
                              saveCurrentPosition:
                                  false, // We already saved it above
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/delete.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFD61443),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'DELETE',
                                style: TextStyle(
                                  color: Color(0xFFD61443),
                                  fontSize: 14,
                                  fontFamily: 'Victor Mono',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

    void handleMarkAsPaid() {
      // Create updated invoice with paid status
      final updatedInvoice = invoice.copyWith(
        status: InvoiceStatus.paid,
        paidDate: DateTime.now(), // Set paid date to current date
      );

      // Update the invoice
      invoiceService.updateInvoice(updatedInvoice);

      // Close the bottom sheet
      Navigator.of(context).pop();

      // Save scroll position before navigating
      InvoiceListScreen.saveScrollPositionForCurrentTab(
        context,
        currentTabIndex,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice ${invoice.invoiceId} marked as paid'),
          backgroundColor: const Color(0xFF13AF5B),
        ),
      );

      // Return to invoice list with correct tab and animation
      InvoiceListScreen.navigateWithTab(
        context,
        tabIndex: currentTabIndex,
        invoiceIdToAnimate: invoice.invoiceId,
        saveCurrentPosition: false, // We already saved it above
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Handle - now outside the content area
        Container(
          width: 48,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF373C3A),
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        const SizedBox(height: 12),
        // Main content - no rounded corners
        Container(
          height: bottomSheetHeight - 20, // Adjust height to account for handle
          width: double.infinity,
          color: const Color(0xFFDAE4E1),
          child: Column(
            children: [
              // Content area
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Scrollable content area
                      Expanded(
                        child: SingleChildScrollView(
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
                                  dueDate: DateFormat(
                                    'MM/dd/yyyy',
                                  ).format(invoice.dueDate),
                                  status: invoice.status,
                                  paidDate: invoice.paidDate,
                                ),
                              ),

                              // Delete and Mark as Paid buttons
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 0.0,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child:
                                      invoice.status == InvoiceStatus.paid
                                          ? // For paid invoices, center the delete button
                                          Center(
                                            child: InkWell(
                                              onTap: handleDeleteInvoice,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 24,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/icons/delete.svg',
                                                      width: 24,
                                                      height: 24,
                                                      colorFilter:
                                                          const ColorFilter.mode(
                                                            Color(0xFFD61443),
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'DELETE INVOICE',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFFD61443,
                                                        ),
                                                        fontSize: 14,
                                                        fontFamily:
                                                            'Victor Mono',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                          : // For unpaid invoices, show both buttons with borders
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              // DELETE INVOICE Button
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: handleDeleteInvoice,
                                                  child: CustomPaint(
                                                    painter:
                                                        DashedBorderPainter(
                                                          sides: const {
                                                            BorderSide.top,
                                                            BorderSide.bottom,
                                                            BorderSide.left,
                                                            BorderSide.right,
                                                          },
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                          ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SvgPicture.asset(
                                                            'assets/icons/delete.svg',
                                                            width: 24,
                                                            height: 24,
                                                            colorFilter:
                                                                const ColorFilter.mode(
                                                                  Color(
                                                                    0xFFD61443,
                                                                  ),
                                                                  BlendMode
                                                                      .srcIn,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          const Text(
                                                            'DELETE INVOICE',
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFFD61443,
                                                              ),
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  'Victor Mono',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // MARK AS PAID Button
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: handleMarkAsPaid,
                                                  child: CustomPaint(
                                                    painter:
                                                        DashedBorderPainter(
                                                          sides: const {
                                                            BorderSide.top,
                                                            BorderSide.bottom,
                                                            BorderSide.right,
                                                          },
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                          ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SvgPicture.asset(
                                                            'assets/icons/paid-mark.svg',
                                                            width: 24,
                                                            height: 24,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          const Text(
                                                            'MARK AS PAID',
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFF13AF5B,
                                                              ),
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  'Victor Mono',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                ),
                              ),

                              // PDF Preview - Fixed size instead of expanding
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 16.0,
                                ),
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio:
                                        1 /
                                        1.414, // A4 aspect ratio (210×297 mm)
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
                                          color:
                                              backgroundColor, // Use the template background color
                                          child: MediaQuery(
                                            data: MediaQuery.of(
                                              context,
                                            ).copyWith(
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: PdfPreview(
                                              key: UniqueKey(),
                                              build:
                                                  (
                                                    format,
                                                  ) => PdfService.previewPdf(
                                                    invoice,
                                                    companyInfo,
                                                    logoPath: logoPath,
                                                    template:
                                                        template, // Pass the template
                                                  ),
                                              allowPrinting: false,
                                              allowSharing: false,
                                              canChangeOrientation: false,
                                              canChangePageFormat: false,
                                              canDebug: false,
                                              useActions: false,
                                              padding: EdgeInsets.zero,
                                              previewPageMargin:
                                                  EdgeInsets.zero,
                                              pdfPreviewPageDecoration: null,
                                              scrollViewDecoration:
                                                  const BoxDecoration(
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
                              // Add bottom padding to ensure space after PDF preview when scrolling
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Action buttons - fixed at bottom
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: MediaQuery.of(context).padding.bottom + 16.0,
                        ),
                        child: InvoiceActionButtons(
                          onEditPressed: () {
                            // Close bottom sheet first
                            Navigator.pop(context);

                            // Remember the tab index for later
                            final tabToReturn = currentTabIndex;
                            final invoiceId = invoice.invoiceId;

                            // Save current scroll position for this tab right now
                            // This needs to happen before we leave the current screen
                            InvoiceListScreen.saveScrollPositionForCurrentTab(
                              context,
                              tabToReturn,
                            );

                            // Navigate to edit screen with invoice data
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => InvoiceCreateScreen(
                                      invoiceToEdit: invoice,
                                      returnTabIndex: tabToReturn,
                                    ),
                              ),
                            ).then((_) {
                              // After returning from edit, restore scroll position when navigating
                              // Don't save current position again (we want to keep the original position)
                              InvoiceListScreen.navigateWithTab(
                                context,
                                tabIndex: tabToReturn,
                                invoiceIdToAnimate: invoiceId,
                                saveCurrentPosition: false,
                              );
                            });
                          },
                          onDownloadPressed: () async {
                            final path = await PdfService.savePdf(
                              invoice,
                              companyInfo,
                              logoPath: logoPath,
                              template: template, // Pass the template
                            );
                            if (path != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Invoice saved to $path'),
                                ),
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
                              template: template, // Pass the template
                            );
                          },
                          showEditButton: invoice.status != InvoiceStatus.paid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reuse the InvoiceHeader widget from invoice_preview.dart
class InvoiceHeader extends StatelessWidget {
  final String clientName;
  final String issueDate;
  final String invoiceId;
  final String currency;
  final String amount;
  final String dueDate;
  final InvoiceStatus status;
  final DateTime? paidDate;

  const InvoiceHeader({
    super.key,
    required this.clientName,
    required this.issueDate,
    required this.invoiceId,
    required this.currency,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd/yyyy');

    // Determine status text and color based on invoice status
    String statusText;
    Color statusColor;

    switch (status) {
      case InvoiceStatus.paid:
        final displayDate =
            paidDate != null
                ? dateFormat.format(paidDate!)
                : issueDate; // Use the issueDate string directly
        statusText = 'PAID ON $displayDate';
        statusColor = const Color(0xFF13AF5B);
        break;
      case InvoiceStatus.overdue:
        statusText = 'DUE ON $dueDate';
        statusColor = const Color(0xFFD61443);
        break;
      case InvoiceStatus.outstanding:
        statusText = 'DUE ON $dueDate';
        statusColor = const Color(0xFF778682);
        break;
    }

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
                statusText,
                style: TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: statusColor,
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
  final bool showEditButton;

  const InvoiceActionButtons({
    super.key,
    required this.onEditPressed,
    required this.onDownloadPressed,
    required this.onSharePressed,
    this.showEditButton = true, // Default to showing edit button
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // EDIT BUTTON - only show if showEditButton is true
          if (showEditButton)
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
                  sides:
                      showEditButton
                          ? const {
                            BorderSide.top,
                            BorderSide.bottom,
                            BorderSide.left,
                            BorderSide.right,
                          }
                          : const {
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

// Custom border painter to create dashed borders
enum BorderSide { top, right, bottom, left, all }

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
