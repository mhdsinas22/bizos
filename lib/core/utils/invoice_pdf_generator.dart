import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';
import 'package:intl/intl.dart';

class InvoicePdfGenerator {
  static PdfColor _parsePdfColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return PdfColors.blue700;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return PdfColor.fromInt(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return PdfColors.blue700;
  }

  static Future<pw.MemoryImage?> _fetchLogoImage(String logoUrl) async {
    if (logoUrl.trim().isEmpty) return null;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(Uri.parse(logoUrl));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
        if (bytes.isNotEmpty) {
          return pw.MemoryImage(Uint8List.fromList(bytes));
        }
      }
    } catch (_) {
      // Safe fallback if logo fails to download or network is offline
    }
    return null;
  }

  static Future<Uint8List> generatePdfBytes({
    required InvoiceEntity invoice,
    required InvoiceSettingsEntity settings,
  }) async {
    final pdf = pw.Document();
    final primaryColor = _parsePdfColor(settings.primaryColor);
    final dateFormat = DateFormat('dd MMM yyyy');

    final String bizName = settings.businessName.isNotEmpty
        ? settings.businessName
        : 'Business';
    final String bizPhone = settings.businessPhone;
    final String bizEmail = settings.businessEmail;
    final String bizAddress = settings.businessAddress;
    final String bizGstin = settings.gstin;

    pw.MemoryImage? logoImage;
    if (settings.showLogo && settings.logoUrl.trim().isNotEmpty) {
      logoImage = await _fetchLogoImage(settings.logoUrl);
    }

    final template = settings.template.toLowerCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Header Section according to Template
            if (template == 'classic')
              _buildClassicHeader(
                primaryColor,
                bizName,
                bizPhone,
                bizEmail,
                bizAddress,
                bizGstin,
                invoice,
                dateFormat,
                logoImage,
              )
            else if (template == 'minimal')
              _buildMinimalHeader(
                primaryColor,
                bizName,
                bizPhone,
                bizEmail,
                bizAddress,
                bizGstin,
                invoice,
                dateFormat,
                logoImage,
              )
            else if (template == 'professional')
              _buildProfessionalHeader(
                primaryColor,
                bizName,
                bizPhone,
                bizEmail,
                bizAddress,
                bizGstin,
                invoice,
                dateFormat,
                logoImage,
              )
            else
              _buildModernHeader(
                primaryColor,
                bizName,
                bizPhone,
                bizEmail,
                bizAddress,
                bizGstin,
                invoice,
                dateFormat,
                logoImage,
              ),

            pw.SizedBox(height: 16),

            // Customer Billed-To Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        invoice.customerNameSnapshot,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (invoice.customerPhoneSnapshot.isNotEmpty)
                        pw.Text(
                          'Phone: ${invoice.customerPhoneSnapshot}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (invoice.customerEmailSnapshot.isNotEmpty)
                        pw.Text(
                          'Email: ${invoice.customerEmailSnapshot}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                  if (invoice.customerAddressSnapshot.isNotEmpty ||
                      invoice.customerGstinSnapshot.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (invoice.customerGstinSnapshot.isNotEmpty)
                          pw.Text(
                            'Customer GSTIN: ${invoice.customerGstinSnapshot}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        if (invoice.customerAddressSnapshot.isNotEmpty)
                          pw.Text(
                            invoice.customerAddressSnapshot,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Items Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.symmetric(
                inside: const pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: [
                'Item & Description',
                'Qty',
                'Rate',
                if (settings.showTax) 'Tax %',
                'Line Total',
              ],
              data: invoice.items.map((item) {
                return [
                  item.description.isNotEmpty
                      ? '${item.itemName}\n${item.description}'
                      : item.itemName,
                  '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                  '₹${item.unitPrice.toStringAsFixed(2)}',
                  if (settings.showTax) '${item.taxRate}%',
                  '₹${item.lineTotal.toStringAsFixed(2)}',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 16),

            // Totals Summary Box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    children: [
                      _buildSummaryRow(
                        'Subtotal:',
                        '₹${invoice.subtotal.toStringAsFixed(2)}',
                      ),
                      if (invoice.discountAmount > 0)
                        _buildSummaryRow(
                          'Discount:',
                          '-₹${invoice.discountAmount.toStringAsFixed(2)}',
                        ),
                      if (settings.showTax && invoice.taxAmount > 0)
                        _buildSummaryRow(
                          'Tax Amount:',
                          '₹${invoice.taxAmount.toStringAsFixed(2)}',
                        ),
                      pw.Divider(color: PdfColors.grey300),
                      _buildSummaryRow(
                        'Grand Total:',
                        '₹${invoice.grandTotal.toStringAsFixed(2)}',
                        isBold: true,
                        color: primaryColor,
                      ),
                      _buildSummaryRow(
                        'Paid Amount:',
                        '₹${invoice.paidAmount.toStringAsFixed(2)}',
                        color: PdfColors.green700,
                      ),
                      _buildSummaryRow(
                        'Balance Due:',
                        '₹${invoice.balanceAmount.toStringAsFixed(2)}',
                        isBold: true,
                        color: invoice.balanceAmount > 0
                            ? PdfColors.red700
                            : PdfColors.green700,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Payment Instructions & Notes
            if (settings.paymentInstructions.isNotEmpty ||
                invoice.paymentInstructions.isNotEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment Instructions:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      invoice.paymentInstructions.isNotEmpty
                          ? invoice.paymentInstructions
                          : settings.paymentInstructions,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),

            if (invoice.notes.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'Notes: ${invoice.notes}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],

            pw.Spacer(),

            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                settings.footerText.isNotEmpty
                    ? settings.footerText
                    : 'Thank you for your business!',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Modern Template Builder
  static pw.Widget _buildModernHeader(
    PdfColor primaryColor,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
    InvoiceEntity invoice,
    DateFormat dateFormat,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null) ...[
                pw.Container(
                  height: 40,
                  width: 80,
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ],
              pw.Text(
                bizName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (bizPhone.isNotEmpty)
                pw.Text(
                  'Phone: $bizPhone',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
              if (bizEmail.isNotEmpty)
                pw.Text(
                  'Email: $bizEmail',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
              if (bizGstin.isNotEmpty)
                pw.Text(
                  'GSTIN: $bizGstin',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.Text(
                '#${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Date: ${dateFormat.format(invoice.invoiceDate)}',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
              if (invoice.dueDate != null)
                pw.Text(
                  'Due Date: ${dateFormat.format(invoice.dueDate!)}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Classic Template Builder
  static pw.Widget _buildClassicHeader(
    PdfColor primaryColor,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
    InvoiceEntity invoice,
    DateFormat dateFormat,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Column(
      children: [
        if (logoImage != null)
          pw.Center(
            child: pw.Container(
              height: 48,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          ),
        pw.Center(
          child: pw.Text(
            bizName.toUpperCase(),
            style: pw.TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
          pw.Center(
            child: pw.Text(
              [bizPhone, bizEmail].where((s) => s.isNotEmpty).join('  |  '),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        if (bizAddress.isNotEmpty)
          pw.Center(
            child: pw.Text(bizAddress, style: const pw.TextStyle(fontSize: 9)),
          ),
        if (bizGstin.isNotEmpty)
          pw.Center(
            child: pw.Text(
              'GSTIN: $bizGstin',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        pw.SizedBox(height: 10),
        pw.Divider(color: primaryColor, thickness: 1.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.Text(
              '#${invoice.invoiceNumber}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date: ${dateFormat.format(invoice.invoiceDate)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.Divider(color: primaryColor, thickness: 0.5),
      ],
    );
  }

  // Minimal Template Builder
  static pw.Widget _buildMinimalHeader(
    PdfColor primaryColor,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
    InvoiceEntity invoice,
    DateFormat dateFormat,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                height: 40,
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Text(
              bizName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (bizPhone.isNotEmpty)
              pw.Text('Ph: $bizPhone', style: const pw.TextStyle(fontSize: 9)),
            if (bizEmail.isNotEmpty)
              pw.Text(bizEmail, style: const pw.TextStyle(fontSize: 9)),
            if (bizGstin.isNotEmpty)
              pw.Text(
                'GSTIN: $bizGstin',
                style: const pw.TextStyle(fontSize: 9),
              ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            pw.Text(
              '#${invoice.invoiceNumber}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date: ${dateFormat.format(invoice.invoiceDate)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            if (invoice.dueDate != null)
              pw.Text(
                'Due Date: ${dateFormat.format(invoice.dueDate!)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
          ],
        ),
      ],
    );
  }

  // Professional Template Builder
  static pw.Widget _buildProfessionalHeader(
    PdfColor primaryColor,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
    InvoiceEntity invoice,
    DateFormat dateFormat,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border(left: pw.BorderSide(color: primaryColor, width: 4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logoImage != null)
                pw.Container(
                  height: 44,
                  width: 44,
                  margin: const pw.EdgeInsets.only(right: 10),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    bizName,
                    style: pw.TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                    pw.Text(
                      [
                        bizPhone,
                        bizEmail,
                      ].where((s) => s.isNotEmpty).join(' • '),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  if (bizGstin.isNotEmpty)
                    pw.Text(
                      'GSTIN: $bizGstin',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '#${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Date: ${dateFormat.format(invoice.invoiceDate)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printOrDownloadPdf({
    required InvoiceEntity invoice,
    required InvoiceSettingsEntity settings,
  }) async {
    final pdfBytes = await generatePdfBytes(
      invoice: invoice,
      settings: settings,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<void> sharePdf({
    required InvoiceEntity invoice,
    required InvoiceSettingsEntity settings,
  }) async {
    final pdfBytes = await generatePdfBytes(
      invoice: invoice,
      settings: settings,
    );
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(pdfBytes);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'Invoice #${invoice.invoiceNumber} for ${invoice.customerNameSnapshot}',
      subject: 'Invoice #${invoice.invoiceNumber}',
    );
  }
}
