import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/reports/domain/models/business_analytics_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportPdfRenderers {
  static final primaryColor = PdfColor.fromHex('#4F46E5');
  static final primaryLight = PdfColor.fromHex('#EEF2FF');
  static final secondaryDark = PdfColor.fromHex('#1E293B');
  static final textDark = PdfColor.fromHex('#0F172A');
  static final textGrey = PdfColor.fromHex('#64748B');
  static final bgLight = PdfColor.fromHex('#F8FAFC');
  static final borderColor = PdfColor.fromHex('#E2E8F0');
  static final successColor = PdfColor.fromHex('#16A34A');
  static final successLight = PdfColor.fromHex('#DCFCE7');
  static final dangerColor = PdfColor.fromHex('#DC2626');
  static final dangerLight = PdfColor.fromHex('#FEE2E2');
  static final accentAmber = PdfColor.fromHex('#D97706');
  static final accentBlue = PdfColor.fromHex('#0284C7');
  static final accentPurple = PdfColor.fromHex('#7C3AED');

  static final dateFormat = DateFormat('dd MMM yyyy');
  static final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static pw.Widget buildHeader(
    BusinessModel business,
    String reportTitle,
    String? filterLabel,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'BIZOS ERP',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                business.name.toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  color: secondaryDark,
                ),
              ),
            ],
          ),
          pw.Text(
            filterLabel ?? reportTitle,
            style: pw.TextStyle(fontSize: 9, color: textGrey),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildFooter(pw.Context context, DateTime now, String documentType) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Confidential $documentType | BizOS Enterprise Intelligence Engine',
            style: pw.TextStyle(fontSize: 8.5, color: textGrey),
          ),
          pw.Text(
            'Generated: ${dateTimeFormat.format(now)}',
            style: pw.TextStyle(fontSize: 8.5, color: textGrey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8.5, color: textGrey),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildTitleBanner(
    BusinessModel business,
    String title,
    String? ownerName,
    DateTime start,
    DateTime end, {
    String? secondaryMetricLabel,
    String? secondaryMetricValue,
    PdfColor? secondaryMetricColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: bgLight,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Business: ${business.name} | Type: ${business.type} | Owner: ${ownerName?.trim().isNotEmpty == true ? ownerName : "Primary Business Owner"}',
                style: pw.TextStyle(fontSize: 9.5, color: textDark),
              ),
              pw.Text(
                'Reporting Scope: ${start.year == end.year && start.month == end.month && start.day == end.day ? dateFormat.format(start) : "${dateFormat.format(start)} - ${dateFormat.format(end)}"}',
                style: pw.TextStyle(fontSize: 9, color: textGrey),
              ),
            ],
          ),
          if (secondaryMetricLabel != null && secondaryMetricValue != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  secondaryMetricLabel,
                  style: pw.TextStyle(fontSize: 8.5, color: textGrey),
                ),
                pw.Text(
                  secondaryMetricValue,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: secondaryMetricColor ?? primaryColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget buildKpiCard(
    String title,
    String value,
    PdfColor color,
    PdfColor bgColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget buildTableHeaderCell(String title, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        title,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8.5,
        ),
      ),
    );
  }

  static pw.Widget buildTableCell(
    String value, {
    bool alignRight = false,
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? secondaryDark,
        ),
      ),
    );
  }

  static pw.Widget buildSingleTrendChart({
    required String title,
    required List<MonthlyAnalyticsItem> items,
    required double Function(MonthlyAnalyticsItem) valueGetter,
    required PdfColor barColor,
  }) {
    final maxVal = items.isEmpty
        ? 1.0
        : items.map(valueGetter).reduce((a, b) => a > b ? a : b);
    final validMax = maxVal > 0 ? maxVal : 1.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgLight,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (idx) {
              final item = items[idx];
              final val = valueGetter(item);
              final barHeight = validMax > 0 ? ((val / validMax) * 45).clamp(2.0, 45.0) : 2.0;

              return pw.Column(
                children: [
                  pw.Container(
                    width: 14,
                    height: barHeight,
                    decoration: pw.BoxDecoration(
                      color: barColor,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    item.monthName,
                    style: pw.TextStyle(fontSize: 7.5, color: textDark, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildEmptyStateNotice(String message) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: primaryLight,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: primaryColor, width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'NOTICE: ',
            style: pw.TextStyle(
              color: primaryColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9.5,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              message,
              style: pw.TextStyle(
                color: secondaryDark,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
