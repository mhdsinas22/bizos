import 'dart:typed_data';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:bizos/features/business/data/models/business_model.dart';

import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/core/utils/currency_formatter.dart';

class PdfGenerator {
  static Future<Uint8List> generateReport({
    required BusinessModel business,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required List<TaskModel> tasks,
    required String reportType, // 'Income', 'Expense', 'Profit', 'Task'
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

    final primaryColor = PdfColor.fromHex('#4F46E5');
    final secondaryColor = PdfColor.fromHex('#1E293B');
    final greyColor = PdfColor.fromHex('#64748B');
    final lightGreyColor = PdfColor.fromHex('#F1F5F9');

    // Compile statistics
    final double totalIncome = incomes.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final double totalExpense = expenses.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final double netProfit = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // HEADER BANNER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      business.name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Type: ${business.type}',
                      style: pw.TextStyle(fontSize: 12, color: greyColor),
                    ),
                    pw.Text(
                      'Address: ${business.address}',
                      style: pw.TextStyle(fontSize: 10, color: greyColor),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '$reportType Report'.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat.yMMMd().format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 10, color: greyColor),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1.5, color: primaryColor),
            pw.SizedBox(height: 20),

            // Financial Summary Block (only show for Financial report types)
            if (reportType != 'Task') ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightGreyColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'TOTAL INCOME',
                          style: pw.TextStyle(fontSize: 10, color: greyColor),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(totalIncome),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#10B981'),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'TOTAL EXPENSES',
                          style: pw.TextStyle(fontSize: 10, color: greyColor),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(totalExpense),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#EF4444'),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'NET BALANCE',
                          style: pw.TextStyle(fontSize: 10, color: greyColor),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(netProfit),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: netProfit >= 0
                                ? primaryColor
                                : PdfColor.fromHex('#EF4444'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
            ],

            // REPORT CONTENT TABLE
            if (reportType == 'Income') ...[
              pw.Text(
                'Income Inward Stream Log',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellHeight: 25,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Date', 'Category', 'Description', 'Amount'],
                data: incomes
                    .map(
                      (i) => [
                        DateFormat.yMMMd().format(i.date),
                        i.category,
                        i.description,
                        CurrencyFormatter.format(i.amount),
                      ],
                    )
                    .toList(),
              ),
            ] else if (reportType == 'Expense') ...[
              pw.Text(
                'Expense Log Sheet',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellHeight: 25,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Date', 'Category', 'Description', 'Amount'],
                data: expenses
                    .map(
                      (e) => [
                        DateFormat.yMMMd().format(e.date),
                        e.category,
                        e.description,
                        '-${CurrencyFormatter.format(e.amount)}',
                      ],
                    )
                    .toList(),
              ),
            ] else if (reportType == 'Profit') ...[
              pw.Text(
                'Profit & Loss Statements',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: secondaryColor),
                cellHeight: 25,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Item Category', 'Type', 'Total Amount'],
                data: [
                  ...incomes.map(
                    (i) => [
                      i.category,
                      'INFLOW',
                      CurrencyFormatter.format(i.amount),
                    ],
                  ),
                  ...expenses.map(
                    (e) => [
                      e.category,
                      'OUTFLOW',
                      '-${CurrencyFormatter.format(e.amount)}',
                    ],
                  ),
                  [
                    'NET PROFIT',
                    'BALANCE',
                    CurrencyFormatter.format(netProfit),
                  ],
                ],
              ),
            ] else if (reportType == 'Task') ...[
              pw.Text(
                'Task Checklist Status Log',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellHeight: 25,
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Task Description', 'Priority', 'Due Date', 'Status'],
                data: tasks
                    .map(
                      (t) => [
                        t.title,
                        t.priority,
                        DateFormat.yMMMd().format(t.dueDate),
                        t.isCompleted ? 'COMPLETED' : 'PENDING',
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Summary: ${tasks.where((t) => t.isCompleted).length} Completed, ${tasks.where((t) => !t.isCompleted).length} Pending out of ${tasks.length} total tasks.',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],

            pw.SizedBox(height: 40),
            pw.Divider(thickness: 1, color: lightGreyColor),
            pw.Center(
              child: pw.Text(
                'Generated via Bizos Local ERP Workspace. Confidential and proprietary.',
                style: pw.TextStyle(fontSize: 8, color: greyColor),
              ),
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
    await Share.shareXFiles([file], subject: filename);
  }
}
