import 'dart:typed_data';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/presentation/utils/transaction_event_mapper.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class TransactionStatementPdfGenerator {
  static Future<Uint8List> generateStatement({
    required MoneyTransactionEntity transaction,
    required List<MoneyTransactionHistoryEntity> history,
    required bool isPersonal,
    BusinessModel? business,
  }) async {
    final robotoRegular = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();
    final robotoItalic = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: robotoRegular,
        bold: robotoBold,
        italic: robotoItalic,
      ),
    );

    // Color Palette
    final primaryColor = PdfColor.fromHex('#75B809'); // Voryn Green
    final primaryLight = PdfColor.fromHex('#F7FEE7'); // Voryn Green Light Tint
    final successColor = PdfColor.fromHex('#16A34A');
    final successBg = PdfColor.fromHex('#DCFCE7');
    final dangerColor = PdfColor.fromHex('#EF4444');
    final dangerBg = PdfColor.fromHex('#FEF2F2');
    final warningColor = PdfColor.fromHex('#F59E0B');
    final warningBg = PdfColor.fromHex('#FEF3C7');
    final infoColor = PdfColor.fromHex('#2563EB');
    final neutralDark = PdfColor.fromHex('#1F2937');
    final neutralGrey = PdfColor.fromHex('#6B7280');
    final neutralLight = PdfColor.fromHex('#F9FAFB');
    final borderColor = PdfColor.fromHex('#E5E7EB');

    final activeHistory =
        history.where((h) => h.eventType != 'payment_deleted').toList();

    // Determine business display values
    final businessName = business?.name.trim().isNotEmpty == true
        ? business!.name
        : (isPersonal ? 'Personal Account' : 'Voryn Workspace');
    final businessType = business?.type.trim().isNotEmpty == true
        ? business!.type
        : (isPersonal ? 'Personal' : 'Business');
    final businessAddress = business?.address.trim().isNotEmpty == true
        ? business!.address
        : '';
    final businessPhone = business?.phone.trim().isNotEmpty == true
        ? business!.phone
        : '';

    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // ----------------------------------------------------
            // 1. HEADER SECTION
            // ----------------------------------------------------
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Left: Business Logo & Info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'VORYN',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: neutralDark,
                      ),
                    ),
                    pw.Text(
                      'Type: $businessType',
                      style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                    ),
                    if (businessAddress.isNotEmpty)
                      pw.Text(
                        'Address: $businessAddress',
                        style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                      ),
                    if (businessPhone.isNotEmpty)
                      pw.Text(
                        'Phone: $businessPhone',
                        style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                      ),
                  ],
                ),
                // Top Right: Statement Details
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'VORYN',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Business Management Platform',
                      style: pw.TextStyle(fontSize: 8, color: neutralGrey),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'TRANSACTION STATEMENT',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: neutralDark,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: ${dateFormat.format(now)}',
                      style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                    ),
                    pw.Text(
                      'Time: ${timeFormat.format(now)}',
                      style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 14),
            pw.Divider(thickness: 1, color: borderColor),
            pw.SizedBox(height: 14),

            // ----------------------------------------------------
            // 2. CUSTOMER SECTION
            // ----------------------------------------------------
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: neutralLight,
                border: pw.Border.all(color: borderColor, width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'STATEMENT FOR',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: neutralGrey,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        transaction.personName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: neutralDark,
                        ),
                      ),
                      if (transaction.phone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Phone: ${transaction.phone}',
                          style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Customer ID: #${transaction.id.length >= 8 ? transaction.id.substring(0, 8).toUpperCase() : transaction.id.toUpperCase()}',
                        style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                      ),
                      pw.Text(
                        'Account Since: ${dateFormat.format(transaction.createdAt)}',
                        style: pw.TextStyle(fontSize: 9, color: neutralGrey),
                      ),
                      pw.SizedBox(height: 4),
                      // Status Badge
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          color: transaction.status.toLowerCase() == 'completed'
                              ? successBg
                              : warningBg,
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(
                            color: transaction.status.toLowerCase() == 'completed'
                                ? successColor
                                : warningColor,
                            width: 0.5,
                          ),
                        ),
                        child: pw.Text(
                          transaction.status.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: transaction.status.toLowerCase() == 'completed'
                                ? successColor
                                : warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ----------------------------------------------------
            // 3. SUMMARY SECTION (4 STAT CARDS)
            // ----------------------------------------------------
            pw.Row(
              children: [
                // Outstanding Balance Card (Highlighted)
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: primaryLight,
                      border: pw.Border.all(color: primaryColor, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'OUTSTANDING',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          CurrencyFormatter.format(transaction.balanceAmount),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Total Debt / Principal Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: dangerBg,
                      border: pw.Border.all(color: dangerColor, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          TransactionEventMapper.getTotalAmountLabel(
                            transactionType: transaction.transactionType,
                          ).toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: dangerColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          CurrencyFormatter.format(transaction.amount),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: dangerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Total Payments Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: successBg,
                      border: pw.Border.all(color: successColor, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          TransactionEventMapper.getPaidAmountLabel(
                            transactionType: transaction.transactionType,
                          ).toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: successColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          CurrencyFormatter.format(transaction.paidAmount),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Total Transactions Count Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: neutralLight,
                      border: pw.Border.all(color: borderColor, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TRANSACTIONS',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: neutralGrey,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${activeHistory.length}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: neutralDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // ----------------------------------------------------
            // 4. TRANSACTION HISTORY SECTION TITLE
            // ----------------------------------------------------
            pw.Text(
              'Transaction History',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: neutralDark,
              ),
            ),
            pw.Text(
              'Complete history of all customer transactions.',
              style: pw.TextStyle(fontSize: 9, color: neutralGrey),
            ),
            pw.SizedBox(height: 10),

            // ----------------------------------------------------
            // 5. TIMELINE TRANSACTIONS CARDS
            // ----------------------------------------------------
            if (activeHistory.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: neutralLight,
                  border: pw.Border.all(color: borderColor),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'No transactions recorded yet.',
                  style: pw.TextStyle(fontSize: 10, color: neutralGrey),
                ),
              )
            else
              ...activeHistory.map((item) {
                final eventTitle = TransactionEventMapper.formatEventTitle(
                  item.eventType,
                  transactionType: transaction.transactionType,
                );
                final eventDesc = TransactionEventMapper.formatEventDescription(
                  item.eventType,
                  transactionType: transaction.transactionType,
                  notes: item.notes,
                );

                // Determine badge status color & prefix
                PdfColor statusColor = neutralGrey;
                PdfColor statusBg = neutralLight;
                String amountPrefix = '';

                if (item.eventType == 'payment') {
                  statusColor = successColor;
                  statusBg = successBg;
                  amountPrefix = '+';
                } else if (item.eventType == 'debt_created' ||
                    item.eventType == 'debt_added') {
                  statusColor = dangerColor;
                  statusBg = dangerBg;
                  amountPrefix = '-';
                } else if (item.eventType == 'adjustment') {
                  statusColor = infoColor;
                  statusBg = PdfColor.fromHex('#EFF6FF');
                  amountPrefix = '±';
                } else if (item.eventType == 'reminder_sent') {
                  statusColor = warningColor;
                  statusBg = warningBg;
                }

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: borderColor, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Top Row: Title Badge & Amount
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 8,
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  color: statusColor,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                eventTitle,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: neutralDark,
                                ),
                              ),
                            ],
                          ),
                          if (item.amount > 0 ||
                              item.eventType == 'payment' ||
                              item.eventType == 'debt_created' ||
                              item.eventType == 'debt_added' ||
                              item.eventType == 'adjustment')
                            pw.Text(
                              '$amountPrefix${CurrencyFormatter.format(item.amount)}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 4),

                      // Second Row: Date/Time & Payment Method Badge
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${dateFormat.format(item.createdAt.toLocal())} • ${timeFormat.format(item.createdAt.toLocal())}',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: neutralGrey,
                            ),
                          ),
                          if (item.paymentMethod != null &&
                              item.paymentMethod!.trim().isNotEmpty)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color: statusBg,
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(
                                  color: statusColor,
                                  width: 0.4,
                                ),
                              ),
                              child: pw.Text(
                                item.paymentMethod!.trim(),
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (eventDesc.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          eventDesc,
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: neutralDark,
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 6),

                      // Running Balance Bar
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: neutralLight,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Balance After Transaction',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: neutralGrey,
                              ),
                            ),
                            pw.Text(
                              CurrencyFormatter.format(item.balanceAfter),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: neutralDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 16),

            // ----------------------------------------------------
            // 6. FOOTER SUMMARY BLOCK
            // ----------------------------------------------------
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: neutralLight,
                border: pw.Border.all(color: borderColor, width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        TransactionEventMapper.getTotalAmountLabel(
                          transactionType: transaction.transactionType,
                        ).toUpperCase(),
                        style: pw.TextStyle(fontSize: 8, color: neutralGrey),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        CurrencyFormatter.format(transaction.amount),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: dangerColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        TransactionEventMapper.getPaidAmountLabel(
                          transactionType: transaction.transactionType,
                        ).toUpperCase(),
                        style: pw.TextStyle(fontSize: 8, color: neutralGrey),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        CurrencyFormatter.format(transaction.paidAmount),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: successColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'OUTSTANDING BALANCE',
                        style: pw.TextStyle(fontSize: 8, color: neutralGrey),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        CurrencyFormatter.format(transaction.balanceAmount),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // ----------------------------------------------------
            // 7. FOOTER & SYSTEM DECLARATION
            // ----------------------------------------------------
            pw.Divider(thickness: 1, color: borderColor),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'This statement is system generated. No signature required.',
                  style: pw.TextStyle(fontSize: 8, color: neutralGrey),
                ),
                pw.Text(
                  'Powered by VORYN • www.voryn.app',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPdf(Uint8List pdfData, String filename) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: filename,
    );
  }

  static Future<void> sharePdf(Uint8List pdfData, String filename) async {
    final file = XFile.fromData(
      pdfData,
      name: filename,
      mimeType: 'application/pdf',
    );
    await SharePlus.instance.share(ShareParams(files: [file], subject: filename));
  }
}
