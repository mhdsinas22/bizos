import 'dart:typed_data';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/utils/report_pdf_renderers.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/reports/domain/models/business_analytics_models.dart';
import 'package:bizos/features/reports/domain/services/business_analytics_engine.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

enum ReportType {
  completeAnalytics,
  expenseStatement,
  incomeStatement,
  profitLoss,
  salesReport,
  purchaseReport,
  customerReport,
  supplierReport,
  inventoryReport,
  taskStatement,
  staffReport,
  cashFlow,
}

class PdfGenerator {
  static ReportType _normalizeReportType(String rawType) {
    final lower = rawType.toLowerCase().replaceAll('⭐', '').trim();
    if (lower.contains('expense statement') || lower == 'expense report') {
      return ReportType.expenseStatement;
    }
    if (lower.contains('income') || lower.contains('revenue')) {
      return ReportType.incomeStatement;
    }
    if (lower.contains('profit') || lower.contains('p&l') || lower == 'financial summary') {
      return ReportType.profitLoss;
    }
    if (lower.contains('sales')) return ReportType.salesReport;
    if (lower.contains('purchase')) return ReportType.purchaseReport;
    if (lower.contains('customer')) return ReportType.customerReport;
    if (lower.contains('supplier') || lower.contains('vendor')) return ReportType.supplierReport;
    if (lower.contains('inventory') || lower.contains('stock')) return ReportType.inventoryReport;
    if (lower.contains('task')) return ReportType.taskStatement;
    if (lower.contains('staff') || lower.contains('employee')) return ReportType.staffReport;
    if (lower.contains('cash flow') || lower.contains('cashflow')) return ReportType.cashFlow;
    return ReportType.completeAnalytics;
  }

  static Future<Uint8List> generateReport({
    required BusinessModel business,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required List<TaskModel> tasks,
    required String reportType,
    String? ownerName,
    DateTime? startDate,
    DateTime? endDate,
    String? filterLabel,
    BusinessAnalyticsData? analyticsData,
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

    final now = DateTime.now();
    final start = startDate ?? (incomes.isNotEmpty || expenses.isNotEmpty
        ? (incomes.map((i) => i.date).followedBy(expenses.map((e) => e.date)).reduce((a, b) => a.isBefore(b) ? a : b))
        : DateTime(now.year, 1, 1));
    final end = endDate ?? now;

    final analytics = analyticsData ?? await BusinessAnalyticsEngine.compute(
      incomes: incomes,
      expenses: expenses,
      tasks: tasks,
      startDate: start,
      endDate: end,
      allIncomes: incomes,
      allExpenses: expenses,
    );

    final normType = _normalizeReportType(reportType);

    switch (normType) {
      case ReportType.expenseStatement:
        return _renderExpenseStatement(pdf, business, expenses, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.incomeStatement:
        return _renderIncomeStatement(pdf, business, incomes, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.profitLoss:
        return _renderProfitLossStatement(pdf, business, incomes, expenses, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.salesReport:
        return _renderSalesReport(pdf, business, incomes, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.purchaseReport:
        return _renderPurchaseReport(pdf, business, expenses, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.customerReport:
        return _renderCustomerReport(pdf, business, incomes, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.supplierReport:
        return _renderSupplierReport(pdf, business, expenses, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.inventoryReport:
        return _renderInventoryReport(pdf, business, incomes, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.taskStatement:
        return _renderTaskStatement(pdf, business, tasks, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.staffReport:
        return _renderStaffReport(pdf, business, tasks, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.cashFlow:
        return _renderCashFlowStatement(pdf, business, incomes, expenses, ownerName, start, end, filterLabel, analytics, now);
      case ReportType.completeAnalytics:
        return _renderCompleteBusinessAnalytics(pdf, business, incomes, expenses, tasks, ownerName, start, end, filterLabel, analytics, now);
    }
  }

  // 1. EXPENSE STATEMENT
  static Future<Uint8List> _renderExpenseStatement(
    pw.Document pdf,
    BusinessModel business,
    List<ExpenseModel> expenses,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final kpis = analytics.kpis;
    final avgExpense = expenses.isNotEmpty ? kpis.totalExpense / expenses.length : 0.0;
    final highestExp = expenses.isNotEmpty ? expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b) : 0.0;
    final lowestExp = expenses.isNotEmpty ? expenses.map((e) => e.amount).reduce((a, b) => a < b ? a : b) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Expense Statement', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Expense Statement'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Business Expense Statement',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Total Expenses',
            secondaryMetricValue: CurrencyFormatter.format(kpis.totalExpense),
            secondaryMetricColor: ReportPdfRenderers.dangerColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Expenses', CurrencyFormatter.format(kpis.totalExpense), ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Avg Expense', CurrencyFormatter.format(avgExpense), ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Highest Expense', CurrencyFormatter.format(highestExp), ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Lowest Expense', CurrencyFormatter.format(lowestExp), ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Total Count', '${expenses.length}', ReportPdfRenderers.secondaryDark, ReportPdfRenderers.bgLight),
            ],
          ),
          pw.SizedBox(height: 12),

          if (expenses.isEmpty)
            ReportPdfRenderers.buildEmptyStateNotice("No expense transactions found for the selected period."),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: ReportPdfRenderers.buildSingleTrendChart(
                  title: 'Monthly Expense Trend',
                  items: analytics.monthly.monthlyItems,
                  valueGetter: (m) => m.expense,
                  barColor: ReportPdfRenderers.dangerColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: ReportPdfRenderers.bgLight,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: ReportPdfRenderers.borderColor),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Expense Categories Breakdown', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
                      pw.SizedBox(height: 6),
                      ...analytics.categories.topExpenseCategories.take(5).map((cat) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(cat.categoryName, style: pw.TextStyle(fontSize: 8, color: ReportPdfRenderers.textDark)),
                            pw.Text('${CurrencyFormatter.format(cat.amount)} (${cat.contributionPct.toStringAsFixed(1)}%)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.dangerColor)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          if (expenses.isNotEmpty) ...[
            pw.Text('Detailed Expense Transactions Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                  children: [
                    ReportPdfRenderers.buildTableHeaderCell('Date'),
                    ReportPdfRenderers.buildTableHeaderCell('Ref ID'),
                    ReportPdfRenderers.buildTableHeaderCell('Person / Supplier'),
                    ReportPdfRenderers.buildTableHeaderCell('Category'),
                    ReportPdfRenderers.buildTableHeaderCell('Description'),
                    ReportPdfRenderers.buildTableHeaderCell('Method'),
                    ReportPdfRenderers.buildTableHeaderCell('Status'),
                    ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                  ],
                ),
                ...List.generate(expenses.length, (idx) {
                  final e = expenses[idx];
                  final isEven = idx % 2 == 0;
                  final refId = e.id.length >= 8 ? '#${e.id.substring(0, 8).toUpperCase()}' : (e.id.isNotEmpty ? e.id : '-');
                  final person = (e.createdByName ?? e.description).trim().isNotEmpty ? (e.createdByName ?? e.description).trim() : 'Supplier';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                    children: [
                      ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(e.date)),
                      ReportPdfRenderers.buildTableCell(refId),
                      ReportPdfRenderers.buildTableCell(person),
                      ReportPdfRenderers.buildTableCell(e.category),
                      ReportPdfRenderers.buildTableCell(e.description.trim().isNotEmpty ? e.description : '-'),
                      ReportPdfRenderers.buildTableCell(e.paymentMethod),
                      ReportPdfRenderers.buildTableCell('Recorded', isBold: true, textColor: ReportPdfRenderers.dangerColor),
                      ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(e.amount), alignRight: true, isBold: true, textColor: ReportPdfRenderers.dangerColor),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  // 2. INCOME / REVENUE STATEMENT
  static Future<Uint8List> _renderIncomeStatement(
    pw.Document pdf,
    BusinessModel business,
    List<IncomeModel> incomes,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final kpis = analytics.kpis;
    final avgRevenue = incomes.isNotEmpty ? kpis.totalRevenue / incomes.length : 0.0;
    final highestRev = incomes.isNotEmpty ? incomes.map((i) => i.amount).reduce((a, b) => a > b ? a : b) : 0.0;
    final lowestRev = incomes.isNotEmpty ? incomes.map((i) => i.amount).reduce((a, b) => a < b ? a : b) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Income Statement', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Income Statement'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Income & Revenue Statement',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Total Revenue',
            secondaryMetricValue: CurrencyFormatter.format(kpis.totalRevenue),
            secondaryMetricColor: ReportPdfRenderers.primaryColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Revenue', CurrencyFormatter.format(kpis.totalRevenue), ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Avg Transaction', CurrencyFormatter.format(avgRevenue), ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Highest Income', CurrencyFormatter.format(highestRev), ReportPdfRenderers.successColor, ReportPdfRenderers.successLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Lowest Income', CurrencyFormatter.format(lowestRev), ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Total Inflows', '${incomes.length}', ReportPdfRenderers.secondaryDark, ReportPdfRenderers.bgLight),
            ],
          ),
          pw.SizedBox(height: 12),

          if (incomes.isEmpty)
            ReportPdfRenderers.buildEmptyStateNotice("No revenue transactions found for the selected period."),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: ReportPdfRenderers.buildSingleTrendChart(
                  title: 'Monthly Revenue Trend',
                  items: analytics.monthly.monthlyItems,
                  valueGetter: (m) => m.revenue,
                  barColor: ReportPdfRenderers.primaryColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: ReportPdfRenderers.bgLight,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: ReportPdfRenderers.borderColor),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Revenue Sources Breakdown', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
                      pw.SizedBox(height: 6),
                      ...analytics.categories.revenueSources.take(5).map((cat) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(cat.categoryName, style: pw.TextStyle(fontSize: 8, color: ReportPdfRenderers.textDark)),
                            pw.Text('${CurrencyFormatter.format(cat.amount)} (${cat.contributionPct.toStringAsFixed(1)}%)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.primaryColor)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          if (incomes.isNotEmpty) ...[
            pw.Text('Detailed Income Transactions Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                  children: [
                    ReportPdfRenderers.buildTableHeaderCell('Date'),
                    ReportPdfRenderers.buildTableHeaderCell('Ref ID'),
                    ReportPdfRenderers.buildTableHeaderCell('Customer / Person'),
                    ReportPdfRenderers.buildTableHeaderCell('Category'),
                    ReportPdfRenderers.buildTableHeaderCell('Description'),
                    ReportPdfRenderers.buildTableHeaderCell('Method'),
                    ReportPdfRenderers.buildTableHeaderCell('Status'),
                    ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                  ],
                ),
                ...List.generate(incomes.length, (idx) {
                  final i = incomes[idx];
                  final isEven = idx % 2 == 0;
                  final refId = i.id.length >= 8 ? '#${i.id.substring(0, 8).toUpperCase()}' : (i.id.isNotEmpty ? i.id : '-');
                  final person = (i.createdByName ?? i.description).trim().isNotEmpty ? (i.createdByName ?? i.description).trim() : 'Customer';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                    children: [
                      ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(i.date)),
                      ReportPdfRenderers.buildTableCell(refId),
                      ReportPdfRenderers.buildTableCell(person),
                      ReportPdfRenderers.buildTableCell(i.category),
                      ReportPdfRenderers.buildTableCell(i.description.trim().isNotEmpty ? i.description : '-'),
                      ReportPdfRenderers.buildTableCell(i.paymentMethod),
                      ReportPdfRenderers.buildTableCell('Recorded', isBold: true, textColor: ReportPdfRenderers.primaryColor),
                      ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(i.amount), alignRight: true, isBold: true, textColor: ReportPdfRenderers.primaryColor),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  // 3. PROFIT & LOSS STATEMENT
  static Future<Uint8List> _renderProfitLossStatement(
    pw.Document pdf,
    BusinessModel business,
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final kpis = analytics.kpis;
    final isMultiMonth = filterLabel == 'This Year' ||
        filterLabel == 'Last Year' ||
        end.difference(start).inDays > 31;

    final List<_PnlTxRow> allTx = [
      ...incomes.map((i) => _PnlTxRow(
            date: i.date,
            type: 'INCOME',
            person: (i.createdByName ?? i.description).trim().isNotEmpty
                ? (i.createdByName ?? i.description).trim()
                : 'Direct Client',
            category: i.category,
            description: i.description,
            paymentMethod: i.paymentMethod,
            amount: i.amount,
            isIncome: true,
          )),
      ...expenses.map((e) => _PnlTxRow(
            date: e.date,
            type: 'EXPENSE',
            person: (e.createdByName ?? e.description).trim().isNotEmpty
                ? (e.createdByName ?? e.description).trim()
                : 'Vendor / Supplier',
            category: e.category,
            description: e.description,
            paymentMethod: e.paymentMethod,
            amount: e.amount,
            isIncome: false,
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Profit & Loss Statement', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Profit & Loss Statement'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Profit & Loss Statement',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Net Operating Profit',
            secondaryMetricValue: CurrencyFormatter.format(kpis.netProfit),
            secondaryMetricColor: kpis.netProfit >= 0 ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Revenue', CurrencyFormatter.format(kpis.totalRevenue), ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Total Expenses', CurrencyFormatter.format(kpis.totalExpense), ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Net Profit', CurrencyFormatter.format(kpis.netProfit), kpis.netProfit >= 0 ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor, kpis.netProfit >= 0 ? ReportPdfRenderers.successLight : ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Profit Margin %', '${kpis.profitMarginPct.toStringAsFixed(1)}%', ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
            ],
          ),
          pw.SizedBox(height: 14),

          if (allTx.isEmpty)
            ReportPdfRenderers.buildEmptyStateNotice("No transactions found for the selected period."),

          pw.Text('Financial Summary for Selected Period', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              _buildSummaryTableRow('Total Revenue Inflow', CurrencyFormatter.format(kpis.totalRevenue), isBold: true, valueColor: ReportPdfRenderers.primaryColor),
              _buildSummaryTableRow('Total Expense Outflow', CurrencyFormatter.format(kpis.totalExpense), isBold: true, valueColor: ReportPdfRenderers.dangerColor),
              _buildSummaryTableRow('Net Operating Profit', CurrencyFormatter.format(kpis.netProfit), isBold: true, valueColor: kpis.netProfit >= 0 ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor),
              _buildSummaryTableRow('Operating Profit Margin', '${kpis.profitMarginPct.toStringAsFixed(1)}%'),
              _buildSummaryTableRow('Number of Income Transactions', '${incomes.length}'),
              _buildSummaryTableRow('Number of Expense Transactions', '${expenses.length}'),
              _buildSummaryTableRow('Average Daily Revenue', CurrencyFormatter.format(analytics.daily.avgRevenuePerDay)),
              _buildSummaryTableRow('Average Daily Expense', CurrencyFormatter.format(analytics.daily.avgExpensePerDay)),
              if (analytics.daily.highestRevenueDay != 'N/A')
                _buildSummaryTableRow('Highest Revenue Day', '${analytics.daily.highestRevenueDay} (${CurrencyFormatter.format(analytics.daily.highestRevenueDayAmount)})'),
              if (analytics.daily.highestExpenseDay != 'N/A')
                _buildSummaryTableRow('Highest Expense Day', '${analytics.daily.highestExpenseDay} (${CurrencyFormatter.format(analytics.daily.highestExpenseDayAmount)})'),
            ],
          ),
          pw.SizedBox(height: 14),

          if (isMultiMonth) ...[
            pw.Text('Monthly P&L Progression Breakdown', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                  children: [
                    ReportPdfRenderers.buildTableHeaderCell('Month'),
                    ReportPdfRenderers.buildTableHeaderCell('Revenue Inflow', alignRight: true),
                    ReportPdfRenderers.buildTableHeaderCell('Expense Outflow', alignRight: true),
                    ReportPdfRenderers.buildTableHeaderCell('Net Operating Profit', alignRight: true),
                    ReportPdfRenderers.buildTableHeaderCell('Margin %', alignRight: true),
                  ],
                ),
                ...List.generate(analytics.monthly.monthlyItems.length, (idx) {
                  final item = analytics.monthly.monthlyItems[idx];
                  final isEven = idx % 2 == 0;
                  final margin = item.revenue > 0 ? (item.profit / item.revenue) * 100 : 0.0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                    children: [
                      ReportPdfRenderers.buildTableCell(item.monthName, isBold: true),
                      ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(item.revenue), alignRight: true, textColor: ReportPdfRenderers.primaryColor),
                      ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(item.expense), alignRight: true, textColor: ReportPdfRenderers.dangerColor),
                      ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(item.profit), alignRight: true, isBold: true, textColor: item.profit >= 0 ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor),
                      ReportPdfRenderers.buildTableCell('${margin.toStringAsFixed(1)}%', alignRight: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          if (analytics.categories.revenueSources.isNotEmpty || analytics.categories.topExpenseCategories.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (analytics.categories.revenueSources.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Revenue by Category', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
                        pw.SizedBox(height: 4),
                        pw.Table(
                          border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                              children: [
                                ReportPdfRenderers.buildTableHeaderCell('Category'),
                                ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                              ],
                            ),
                            ...analytics.categories.revenueSources.map((cat) => pw.TableRow(
                              children: [
                                ReportPdfRenderers.buildTableCell(cat.categoryName),
                                ReportPdfRenderers.buildTableCell('${CurrencyFormatter.format(cat.amount)} (${cat.contributionPct.toStringAsFixed(1)}%)', alignRight: true, isBold: true, textColor: ReportPdfRenderers.primaryColor),
                              ],
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (analytics.categories.revenueSources.isNotEmpty && analytics.categories.topExpenseCategories.isNotEmpty)
                  pw.SizedBox(width: 10),
                if (analytics.categories.topExpenseCategories.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Expenses by Category', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
                        pw.SizedBox(height: 4),
                        pw.Table(
                          border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                              children: [
                                ReportPdfRenderers.buildTableHeaderCell('Category'),
                                ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                              ],
                            ),
                            ...analytics.categories.topExpenseCategories.map((cat) => pw.TableRow(
                              children: [
                                ReportPdfRenderers.buildTableCell(cat.categoryName),
                                ReportPdfRenderers.buildTableCell('${CurrencyFormatter.format(cat.amount)} (${cat.contributionPct.toStringAsFixed(1)}%)', alignRight: true, isBold: true, textColor: ReportPdfRenderers.dangerColor),
                              ],
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          if (allTx.isNotEmpty) ...[
            pw.Text('Detailed Transaction Breakdown', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                  children: [
                    ReportPdfRenderers.buildTableHeaderCell('Date'),
                    ReportPdfRenderers.buildTableHeaderCell('Type'),
                    ReportPdfRenderers.buildTableHeaderCell('Person / Contact'),
                    ReportPdfRenderers.buildTableHeaderCell('Category'),
                    ReportPdfRenderers.buildTableHeaderCell('Description'),
                    ReportPdfRenderers.buildTableHeaderCell('Method'),
                    ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                  ],
                ),
                ...List.generate(allTx.length, (idx) {
                  final row = allTx[idx];
                  final isEven = idx % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                    children: [
                      ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(row.date)),
                      ReportPdfRenderers.buildTableCell(row.type, isBold: true, textColor: row.isIncome ? ReportPdfRenderers.primaryColor : ReportPdfRenderers.dangerColor),
                      ReportPdfRenderers.buildTableCell(row.person),
                      ReportPdfRenderers.buildTableCell(row.category),
                      ReportPdfRenderers.buildTableCell(row.description.trim().isNotEmpty ? row.description : '-'),
                      ReportPdfRenderers.buildTableCell(row.paymentMethod),
                      ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(row.amount), alignRight: true, isBold: true, textColor: row.isIncome ? ReportPdfRenderers.primaryColor : ReportPdfRenderers.dangerColor),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  // 4. SALES REPORT
  static Future<Uint8List> _renderSalesReport(
    pw.Document pdf,
    BusinessModel business,
    List<IncomeModel> incomes,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final kpis = analytics.kpis;
    final avgSale = incomes.isNotEmpty ? kpis.totalSales / incomes.length : 0.0;
    final highestSale = incomes.isNotEmpty ? incomes.map((i) => i.amount).reduce((a, b) => a > b ? a : b) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Sales Report', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Sales Report'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Business Sales Report',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Total Gross Sales',
            secondaryMetricValue: CurrencyFormatter.format(kpis.totalSales),
            secondaryMetricColor: ReportPdfRenderers.primaryColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Sales', CurrencyFormatter.format(kpis.totalSales), ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Sales Count', '${incomes.length}', ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Avg Sale Value', CurrencyFormatter.format(avgSale), ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Highest Sale', CurrencyFormatter.format(highestSale), ReportPdfRenderers.successColor, ReportPdfRenderers.successLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Best Customer', analytics.customers.highestPayingCustomer, ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Detailed Sales Ledger', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Date'),
                  ReportPdfRenderers.buildTableHeaderCell('Client Account'),
                  ReportPdfRenderers.buildTableHeaderCell('Category / Item'),
                  ReportPdfRenderers.buildTableHeaderCell('Method'),
                  ReportPdfRenderers.buildTableHeaderCell('Sale Amount', alignRight: true),
                ],
              ),
              ...List.generate(incomes.length, (idx) {
                final i = incomes[idx];
                final isEven = idx % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(i.date)),
                    ReportPdfRenderers.buildTableCell((i.createdByName ?? i.description).trim().isNotEmpty ? (i.createdByName ?? i.description) : '-'),
                    ReportPdfRenderers.buildTableCell(i.category),
                    ReportPdfRenderers.buildTableCell(i.paymentMethod),
                    ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(i.amount), alignRight: true, isBold: true, textColor: ReportPdfRenderers.primaryColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // 5. PURCHASE REPORT
  static Future<Uint8List> _renderPurchaseReport(
    pw.Document pdf,
    BusinessModel business,
    List<ExpenseModel> expenses,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final kpis = analytics.kpis;
    final avgPurchase = expenses.isNotEmpty ? kpis.totalPurchases / expenses.length : 0.0;
    final highestPurchase = expenses.isNotEmpty ? expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Purchase Report', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Purchase Report'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Business Purchase Report',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Total Procurement',
            secondaryMetricValue: CurrencyFormatter.format(kpis.totalPurchases),
            secondaryMetricColor: ReportPdfRenderers.dangerColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Purchases', CurrencyFormatter.format(kpis.totalPurchases), ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Orders Count', '${expenses.length}', ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Avg Purchase', CurrencyFormatter.format(avgPurchase), ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Highest Order', CurrencyFormatter.format(highestPurchase), ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Top Vendor', analytics.suppliers.largestSupplier, ReportPdfRenderers.secondaryDark, ReportPdfRenderers.bgLight),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Detailed Purchase Orders Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Date'),
                  ReportPdfRenderers.buildTableHeaderCell('Vendor / Supplier'),
                  ReportPdfRenderers.buildTableHeaderCell('Category'),
                  ReportPdfRenderers.buildTableHeaderCell('Payment Method'),
                  ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                ],
              ),
              ...List.generate(expenses.length, (idx) {
                final e = expenses[idx];
                final isEven = idx % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(e.date)),
                    ReportPdfRenderers.buildTableCell((e.createdByName ?? e.description).trim().isNotEmpty ? (e.createdByName ?? e.description) : '-'),
                    ReportPdfRenderers.buildTableCell(e.category),
                    ReportPdfRenderers.buildTableCell(e.paymentMethod),
                    ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(e.amount), alignRight: true, isBold: true, textColor: ReportPdfRenderers.dangerColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // 6. CUSTOMER REPORT
  static Future<Uint8List> _renderCustomerReport(
    pw.Document pdf,
    BusinessModel business,
    List<IncomeModel> incomes,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final cust = analytics.customers;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Customer Analytics Report', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Customer Analytics Report'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Customer Analytics Report',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Top Customer Spend',
            secondaryMetricValue: CurrencyFormatter.format(cust.highestPayingCustomerAmount),
            secondaryMetricColor: ReportPdfRenderers.primaryColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Clients', '${cust.totalCustomers}', ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('New Clients', '${cust.newCustomers}', ReportPdfRenderers.successColor, ReportPdfRenderers.successLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Returning', '${cust.returningCustomers}', ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Avg Spend', CurrencyFormatter.format(cust.avgCustomerSpend), ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Top Client', cust.highestPayingCustomer, ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Top Client Relationship Summary Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Client Name'),
                  ReportPdfRenderers.buildTableHeaderCell('Transactions', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Contribution %', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Total Revenue', alignRight: true),
                ],
              ),
              ...List.generate(cust.top10Customers.length, (idx) {
                final c = cust.top10Customers[idx];
                final isEven = idx % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(c.name, isBold: true),
                    ReportPdfRenderers.buildTableCell('${c.transactionCount}', alignRight: true),
                    ReportPdfRenderers.buildTableCell('${c.contributionPct.toStringAsFixed(1)}%', alignRight: true),
                    ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(c.totalAmount), alignRight: true, isBold: true, textColor: ReportPdfRenderers.primaryColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // 7. SUPPLIER REPORT
  static Future<Uint8List> _renderSupplierReport(
    pw.Document pdf,
    BusinessModel business,
    List<ExpenseModel> expenses,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final supp = analytics.suppliers;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Supplier Analytics Report', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Supplier Analytics Report'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Supplier Analytics Report',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Largest Vendor Spend',
            secondaryMetricValue: CurrencyFormatter.format(supp.largestSupplierAmount),
            secondaryMetricColor: ReportPdfRenderers.dangerColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Vendors', '${supp.totalSuppliers}', ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Largest Vendor', supp.largestSupplier, ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Vendor Spend', CurrencyFormatter.format(supp.largestSupplierAmount), ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Top Vendor Procurement Summary Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Vendor Name'),
                  ReportPdfRenderers.buildTableHeaderCell('Orders Count', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Contribution %', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Total Purchases', alignRight: true),
                ],
              ),
              ...List.generate(supp.topSuppliers.length, (idx) {
                final s = supp.topSuppliers[idx];
                final isEven = idx % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(s.name, isBold: true),
                    ReportPdfRenderers.buildTableCell('${s.transactionCount}', alignRight: true),
                    ReportPdfRenderers.buildTableCell('${s.contributionPct.toStringAsFixed(1)}%', alignRight: true),
                    ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(s.totalAmount), alignRight: true, isBold: true, textColor: ReportPdfRenderers.dangerColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // 8. INVENTORY REPORT
  static Future<Uint8List> _renderInventoryReport(
    pw.Document pdf,
    BusinessModel business,
    List<IncomeModel> incomes,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final prod = analytics.products;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Inventory Report', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Inventory Report'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Inventory & Product Report',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Best Selling Category',
            secondaryMetricValue: prod.bestSellingProduct,
            secondaryMetricColor: ReportPdfRenderers.primaryColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Products', '${prod.topSellingProducts.length}', ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Best Seller', prod.bestSellingProduct, ReportPdfRenderers.successColor, ReportPdfRenderers.successLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Fast Moving', prod.fastMovingProduct, ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Slow Moving', prod.slowMovingProduct, ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Product & Category Performance Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Product / Category'),
                  ReportPdfRenderers.buildTableHeaderCell('Units Sold', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Status'),
                  ReportPdfRenderers.buildTableHeaderCell('Revenue Generated', alignRight: true),
                ],
              ),
              ...List.generate(prod.topSellingProducts.length, (idx) {
                final p = prod.topSellingProducts[idx];
                final isEven = idx % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(p.name, isBold: true),
                    ReportPdfRenderers.buildTableCell('${p.unitsSold}', alignRight: true),
                    ReportPdfRenderers.buildTableCell(p.status),
                    ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(p.revenue), alignRight: true, isBold: true, textColor: ReportPdfRenderers.primaryColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // 9. TASK STATEMENT
  static Future<Uint8List> _renderTaskStatement(
    pw.Document pdf,
    BusinessModel business,
    List<TaskModel> tasks,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final tData = analytics.taskAnalytics;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Task Statement', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Task Statement'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Operations Task Statement',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Completion Rate',
            secondaryMetricValue: '${tData.completionRatePct.toStringAsFixed(1)}%',
            secondaryMetricColor: tData.completionRatePct >= 70 ? ReportPdfRenderers.successColor : ReportPdfRenderers.accentAmber,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Tasks', '${tData.totalTasks}', ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Completed', '${tData.completedTasks}', ReportPdfRenderers.successColor, ReportPdfRenderers.successLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Pending', '${tData.pendingTasks}', ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Overdue', '${tData.overdueTasks}', ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('In Progress', '${tData.inProgressTasks}', ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Rate %', '${tData.completionRatePct.toStringAsFixed(1)}%', ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
            ],
          ),
          pw.SizedBox(height: 14),

          if (tasks.isEmpty)
            ReportPdfRenderers.buildEmptyStateNotice("No tasks found for the selected period."),

          if (tasks.isNotEmpty) ...[
            pw.Text('Detailed Task Execution Log', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                  children: [
                    ReportPdfRenderers.buildTableHeaderCell('Task Title'),
                    ReportPdfRenderers.buildTableHeaderCell('Assigned Person'),
                    ReportPdfRenderers.buildTableHeaderCell('Priority'),
                    ReportPdfRenderers.buildTableHeaderCell('Status'),
                    ReportPdfRenderers.buildTableHeaderCell('Created Date'),
                    ReportPdfRenderers.buildTableHeaderCell('Due Date'),
                    ReportPdfRenderers.buildTableHeaderCell('Completed Date'),
                  ],
                ),
                ...List.generate(tasks.length, (idx) {
                  final t = tasks[idx];
                  final isEven = idx % 2 == 0;
                  final statusColor = t.isCompleted ? ReportPdfRenderers.successColor : (t.isMissed ? ReportPdfRenderers.dangerColor : ReportPdfRenderers.accentAmber);
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                    children: [
                      ReportPdfRenderers.buildTableCell(t.title, isBold: true),
                      ReportPdfRenderers.buildTableCell(t.assignedto.isNotEmpty ? t.assignedto : 'Unassigned'),
                      ReportPdfRenderers.buildTableCell(t.priority),
                      ReportPdfRenderers.buildTableCell(t.status, isBold: true, textColor: statusColor),
                      ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(t.createdAt)),
                      ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(t.dueDate)),
                      ReportPdfRenderers.buildTableCell(t.completedAt != null ? ReportPdfRenderers.dateFormat.format(t.completedAt!) : '-'),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  // 10. STAFF REPORT
  static Future<Uint8List> _renderStaffReport(
    pw.Document pdf,
    BusinessModel business,
    List<TaskModel> tasks,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final sData = analytics.staffAnalytics;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Staff Performance Report', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Staff Performance Report'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Staff Performance Report',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Overall Completion Rate',
            secondaryMetricValue: '${sData.overallCompletionPct.toStringAsFixed(1)}%',
            secondaryMetricColor: ReportPdfRenderers.primaryColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Staff', '${sData.totalStaff}', ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Assigned Tasks', '${sData.totalAssignedTasks}', ReportPdfRenderers.accentBlue, PdfColor.fromHex('#EFF6FF')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Completed', '${sData.totalCompletedTasks}', ReportPdfRenderers.successColor, ReportPdfRenderers.successLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Pending', '${sData.totalPendingTasks}', ReportPdfRenderers.accentAmber, PdfColor.fromHex('#FEF3C7')),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Overdue', '${sData.totalOverdueTasks}', ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Staff Performance Breakdown Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Staff Member'),
                  ReportPdfRenderers.buildTableHeaderCell('Assigned', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Completed', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Pending', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Overdue', alignRight: true),
                  ReportPdfRenderers.buildTableHeaderCell('Completion %', alignRight: true),
                ],
              ),
              ...List.generate(sData.staffPerformance.length, (idx) {
                final sp = sData.staffPerformance[idx];
                final isEven = idx % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(sp.staffName, isBold: true),
                    ReportPdfRenderers.buildTableCell('${sp.assigned}', alignRight: true),
                    ReportPdfRenderers.buildTableCell('${sp.completed}', alignRight: true, textColor: ReportPdfRenderers.successColor),
                    ReportPdfRenderers.buildTableCell('${sp.pending}', alignRight: true, textColor: ReportPdfRenderers.accentAmber),
                    ReportPdfRenderers.buildTableCell('${sp.overdue}', alignRight: true, textColor: ReportPdfRenderers.dangerColor),
                    ReportPdfRenderers.buildTableCell('${sp.completionPct.toStringAsFixed(1)}%', alignRight: true, isBold: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // 11. CASH FLOW STATEMENT
  static Future<Uint8List> _renderCashFlowStatement(
    pw.Document pdf,
    BusinessModel business,
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final kpis = analytics.kpis;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Cash Flow Statement', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Cash Flow Statement'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Cash Flow Statement',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Net Cash Position',
            secondaryMetricValue: CurrencyFormatter.format(kpis.closingBalance),
            secondaryMetricColor: kpis.closingBalance >= 0 ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Opening Balance', CurrencyFormatter.format(kpis.openingBalance), ReportPdfRenderers.secondaryDark, ReportPdfRenderers.bgLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Cash Inflow', CurrencyFormatter.format(kpis.cashIn), ReportPdfRenderers.successColor, ReportPdfRenderers.successLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Cash Outflow', CurrencyFormatter.format(kpis.cashOut), ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Closing Balance', CurrencyFormatter.format(kpis.closingBalance), kpis.closingBalance >= 0 ? ReportPdfRenderers.primaryColor : ReportPdfRenderers.dangerColor, ReportPdfRenderers.primaryLight),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Cash Flow Ledger Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Date'),
                  ReportPdfRenderers.buildTableHeaderCell('Flow Type'),
                  ReportPdfRenderers.buildTableHeaderCell('Description / Contact'),
                  ReportPdfRenderers.buildTableHeaderCell('Category'),
                  ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                ],
              ),
              ...List.generate(incomes.length + expenses.length, (idx) {
                final isInc = idx < incomes.length;
                final inc = isInc ? incomes[idx] : null;
                final exp = !isInc ? expenses[idx - incomes.length] : null;
                final isEven = idx % 2 == 0;

                final dt = isInc ? inc!.date : exp!.date;
                final type = isInc ? 'CASH IN' : 'CASH OUT';
                final desc = isInc ? (inc!.createdByName ?? inc.description) : (exp!.createdByName ?? exp.description);
                final cat = isInc ? inc!.category : exp!.category;
                final amt = isInc ? inc!.amount : exp!.amount;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(dt)),
                    ReportPdfRenderers.buildTableCell(type, isBold: true, textColor: isInc ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor),
                    ReportPdfRenderers.buildTableCell(desc.trim().isNotEmpty ? desc : '-'),
                    ReportPdfRenderers.buildTableCell(cat),
                    ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(amt), alignRight: true, isBold: true, textColor: isInc ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // 12. COMPLETE BUSINESS ANALYTICS
  static Future<Uint8List> _renderCompleteBusinessAnalytics(
    pw.Document pdf,
    BusinessModel business,
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
    List<TaskModel> tasks,
    String? ownerName,
    DateTime start,
    DateTime end,
    String? filterLabel,
    BusinessAnalyticsData analytics,
    DateTime now,
  ) {
    final kpis = analytics.kpis;
    final healthScore = analytics.healthScore;


    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => ReportPdfRenderers.buildHeader(business, 'Complete Business Analytics', filterLabel),
        footer: (context) => ReportPdfRenderers.buildFooter(context, now, 'Complete Business Intelligence'),
        build: (context) => [
          ReportPdfRenderers.buildTitleBanner(
            business,
            'Complete Business Analytics',
            ownerName,
            start,
            end,
            secondaryMetricLabel: 'Health Score',
            secondaryMetricValue: '${healthScore.score}/100 (${healthScore.status})',
            secondaryMetricColor: healthScore.color,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              ReportPdfRenderers.buildKpiCard('Total Revenue', CurrencyFormatter.format(kpis.totalRevenue), ReportPdfRenderers.primaryColor, ReportPdfRenderers.primaryLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Total Expense', CurrencyFormatter.format(kpis.totalExpense), ReportPdfRenderers.dangerColor, ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Net Profit', CurrencyFormatter.format(kpis.netProfit), kpis.netProfit >= 0 ? ReportPdfRenderers.successColor : ReportPdfRenderers.dangerColor, kpis.netProfit >= 0 ? ReportPdfRenderers.successLight : ReportPdfRenderers.dangerLight),
              pw.SizedBox(width: 6),
              ReportPdfRenderers.buildKpiCard('Margin %', '${kpis.profitMarginPct.toStringAsFixed(1)}%', ReportPdfRenderers.accentPurple, PdfColor.fromHex('#F3E8FF')),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: ReportPdfRenderers.buildSingleTrendChart(
                  title: 'Revenue Trend',
                  items: analytics.monthly.monthlyItems,
                  valueGetter: (m) => m.revenue,
                  barColor: ReportPdfRenderers.primaryColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: ReportPdfRenderers.buildSingleTrendChart(
                  title: 'Expense Trend',
                  items: analytics.monthly.monthlyItems,
                  valueGetter: (m) => m.expense,
                  barColor: ReportPdfRenderers.dangerColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Complete Transaction Ledger Table', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ReportPdfRenderers.textDark)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: ReportPdfRenderers.borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: ReportPdfRenderers.secondaryDark),
                children: [
                  ReportPdfRenderers.buildTableHeaderCell('Date'),
                  ReportPdfRenderers.buildTableHeaderCell('Type'),
                  ReportPdfRenderers.buildTableHeaderCell('Contact / Description'),
                  ReportPdfRenderers.buildTableHeaderCell('Category'),
                  ReportPdfRenderers.buildTableHeaderCell('Method'),
                  ReportPdfRenderers.buildTableHeaderCell('Amount', alignRight: true),
                ],
              ),
              ...List.generate(incomes.length + expenses.length, (idx) {
                final isInc = idx < incomes.length;
                final inc = isInc ? incomes[idx] : null;
                final exp = !isInc ? expenses[idx - incomes.length] : null;
                final isEven = idx % 2 == 0;

                final dt = isInc ? inc!.date : exp!.date;
                final type = isInc ? 'INCOME' : 'EXPENSE';
                final desc = isInc ? (inc!.createdByName ?? inc.description) : (exp!.createdByName ?? exp.description);
                final cat = isInc ? inc!.category : exp!.category;
                final method = isInc ? inc!.paymentMethod : exp!.paymentMethod;
                final amt = isInc ? inc!.amount : exp!.amount;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : ReportPdfRenderers.bgLight),
                  children: [
                    ReportPdfRenderers.buildTableCell(ReportPdfRenderers.dateFormat.format(dt)),
                    ReportPdfRenderers.buildTableCell(type, isBold: true, textColor: isInc ? ReportPdfRenderers.primaryColor : ReportPdfRenderers.dangerColor),
                    ReportPdfRenderers.buildTableCell(desc.trim().isNotEmpty ? desc : '-'),
                    ReportPdfRenderers.buildTableCell(cat),
                    ReportPdfRenderers.buildTableCell(method),
                    ReportPdfRenderers.buildTableCell(CurrencyFormatter.format(amt), alignRight: true, isBold: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // SHARE & PRINT UTILITIES
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    final file = XFile.fromData(
      pdfBytes,
      name: fileName,
      mimeType: 'application/pdf',
    );
    await SharePlus.instance.share(
      ShareParams(files: [file], text: 'BizOS Business Intelligence Report'),
    );
  }

  static Future<void> printPdf(Uint8List pdfBytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }

  static pw.TableRow _buildSummaryTableRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? valueColor,
  }) {
    return pw.TableRow(
      children: [
        ReportPdfRenderers.buildTableCell(label, isBold: isBold),
        ReportPdfRenderers.buildTableCell(value, alignRight: true, isBold: isBold, textColor: valueColor),
      ],
    );
  }
}

class _PnlTxRow {
  final DateTime date;
  final String type;
  final String person;
  final String category;
  final String description;
  final String paymentMethod;
  final double amount;
  final bool isIncome;

  _PnlTxRow({
    required this.date,
    required this.type,
    required this.person,
    required this.category,
    required this.description,
    required this.paymentMethod,
    required this.amount,
    required this.isIncome,
  });
}
