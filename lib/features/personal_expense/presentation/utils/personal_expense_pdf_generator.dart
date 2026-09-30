import 'dart:typed_data';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PersonalExpensePdfGenerator {
  static Future<Uint8List> generatePdfReport({
    required List<PersonalExpenseEntity> filteredExpenses,
    required List<PersonalExpenseEntity> allExpenses,
    required String filterTitle,
    required DateTime startDate,
    required DateTime endDate,
    required String userName,
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

    // Color Palette - Executive Finance Palette
    final primaryColor = PdfColor.fromHex('#75B809'); // Voryn Green
    final primaryLight = PdfColor.fromHex('#F7FEE7'); // Green Tint
    final secondaryDark = PdfColor.fromHex('#1E293B'); // Slate 800
    final textDark = PdfColor.fromHex('#0F172A'); // Slate 900
    final textGrey = PdfColor.fromHex('#64748B'); // Slate 500
    final bgLight = PdfColor.fromHex('#F8FAFC'); // Slate 50
    final borderColor = PdfColor.fromHex('#E2E8F0'); // Slate 200
    final accentBlue = PdfColor.fromHex('#2563EB');
    final accentPurple = PdfColor.fromHex('#9333EA');
    final accentAmber = PdfColor.fromHex('#D97706');
    final dangerColor = PdfColor.fromHex('#EF4444');
    final successColor = PdfColor.fromHex('#16A34A');
    final successLight = PdfColor.fromHex('#DCFCE7');

    final dateFormat = DateFormat('dd MMM yyyy');
    final shortDateFormat = DateFormat('dd MMM');
    final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final now = DateTime.now();

    // ------------------------------------------------------------------
    // COMPUTE STATISTICS
    // ------------------------------------------------------------------
    final sortedExpenses = List<PersonalExpenseEntity>.from(filteredExpenses)
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate)); // Newest first

    final double totalExpense = filteredExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final int totalTransactions = filteredExpenses.length;

    final int daysDiff = endDate.difference(startDate).inDays + 1;
    final int effectiveDays = daysDiff > 0 ? daysDiff : 1;
    final double effectiveWeeks = effectiveDays / 7.0;
    final double effectiveMonths = effectiveDays / 30.4375;

    final double avgDailyExpense =
        totalTransactions > 0 ? totalExpense / effectiveDays : 0.0;
    final double avgWeeklyExpense =
        totalTransactions > 0 ? totalExpense / (effectiveWeeks > 0 ? effectiveWeeks : 1) : 0.0;
    final double avgMonthlyExpense =
        totalTransactions > 0 ? totalExpense / (effectiveMonths > 0 ? effectiveMonths : 1) : 0.0;
    final double avgTransactionValue =
        totalTransactions > 0 ? totalExpense / totalTransactions : 0.0;

    // Median Expense
    double medianExpense = 0.0;
    if (totalTransactions > 0) {
      final sortedAmounts = filteredExpenses.map((e) => e.amount).toList()..sort();
      final mid = sortedAmounts.length ~/ 2;
      if (sortedAmounts.length % 2 == 0) {
        medianExpense = (sortedAmounts[mid - 1] + sortedAmounts[mid]) / 2.0;
      } else {
        medianExpense = sortedAmounts[mid];
      }
    }

    double highestExpenseAmount = 0.0;
    double lowestExpenseAmount = 0.0;
    PersonalExpenseEntity? highestExpenseItem;
    PersonalExpenseEntity? lowestExpenseItem;

    if (totalTransactions > 0) {
      highestExpenseItem = filteredExpenses.reduce(
        (a, b) => a.amount >= b.amount ? a : b,
      );
      lowestExpenseItem = filteredExpenses.reduce(
        (a, b) => a.amount <= b.amount ? a : b,
      );
      highestExpenseAmount = highestExpenseItem.amount;
      lowestExpenseAmount = lowestExpenseItem.amount;
    }

    // Category Analytics
    final Map<String, double> categoryAmounts = {};
    final Map<String, int> categoryCounts = {};
    for (final e in filteredExpenses) {
      categoryAmounts[e.category] =
          (categoryAmounts[e.category] ?? 0.0) + e.amount;
      categoryCounts[e.category] = (categoryCounts[e.category] ?? 0) + 1;
    }

    final int numCategories = categoryAmounts.keys.length;

    String mostExpensiveCategoryName = 'N/A';
    double maxCategoryAmt = 0.0;
    String leastExpensiveCategoryName = 'N/A';
    double minCategoryAmt = 999999999.0;

    categoryAmounts.forEach((cat, amt) {
      if (amt > maxCategoryAmt) {
        maxCategoryAmt = amt;
        mostExpensiveCategoryName = cat;
      }
      if (amt < minCategoryAmt) {
        minCategoryAmt = amt;
        leastExpensiveCategoryName = cat;
      }
    });
    if (minCategoryAmt == 999999999.0) leastExpensiveCategoryName = 'N/A';

    String mostUsedCategoryName = 'N/A';
    int maxCategoryCnt = 0;
    String leastUsedCategoryName = 'N/A';
    int minCategoryCnt = 999999;

    categoryCounts.forEach((cat, cnt) {
      if (cnt > maxCategoryCnt) {
        maxCategoryCnt = cnt;
        mostUsedCategoryName = cat;
      }
      if (cnt < minCategoryCnt) {
        minCategoryCnt = cnt;
        leastUsedCategoryName = cat;
      }
    });
    if (minCategoryCnt == 999999) leastUsedCategoryName = 'N/A';

    // Payment Method Analytics
    final Map<String, double> paymentMethodAmounts = {};
    final Map<String, int> paymentMethodCounts = {};
    for (final e in filteredExpenses) {
      final method = e.paymentMethod.trim().isNotEmpty
          ? e.paymentMethod
          : 'Cash';
      paymentMethodAmounts[method] =
          (paymentMethodAmounts[method] ?? 0.0) + e.amount;
      paymentMethodCounts[method] = (paymentMethodCounts[method] ?? 0) + 1;
    }

    String mostUsedPaymentMethod = 'N/A';
    int maxMethodCnt = 0;
    String leastUsedPaymentMethod = 'N/A';
    int minMethodCnt = 999999;

    paymentMethodCounts.forEach((m, cnt) {
      if (cnt > maxMethodCnt) {
        maxMethodCnt = cnt;
        mostUsedPaymentMethod = m;
      }
      if (cnt < minMethodCnt) {
        minMethodCnt = cnt;
        leastUsedPaymentMethod = m;
      }
    });
    if (minMethodCnt == 999999) leastUsedPaymentMethod = 'N/A';

    // Daily Spending
    final Map<String, double> dailySpending = {};
    final Map<String, int> dailyCounts = {};
    for (final e in filteredExpenses) {
      final dayKey = dateFormat.format(e.expenseDate);
      dailySpending[dayKey] = (dailySpending[dayKey] ?? 0.0) + e.amount;
      dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;
    }

    String highestSpendingDay = 'N/A';
    double maxDayAmt = 0.0;
    String lowestSpendingDay = 'N/A';
    double minDayAmt = 999999999.0;

    dailySpending.forEach((day, amt) {
      if (amt > maxDayAmt) {
        maxDayAmt = amt;
        highestSpendingDay = day;
      }
      if (amt < minDayAmt) {
        minDayAmt = amt;
        lowestSpendingDay = day;
      }
    });
    if (minDayAmt == 999999999.0) lowestSpendingDay = 'N/A';

    // Weekly Spending Breakdown (Week 1 to Week 5)
    final Map<int, double> weeklySpending = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0};
    for (final e in filteredExpenses) {
      final dayOfMonth = e.expenseDate.day;
      final weekIndex = ((dayOfMonth - 1) ~/ 7) + 1;
      final clampedWeek = weekIndex.clamp(1, 5);
      weeklySpending[clampedWeek] = (weeklySpending[clampedWeek] ?? 0.0) + e.amount;
    }

    int highestSpendingWeekNum = 1;
    double maxWeekAmt = 0.0;
    int lowestSpendingWeekNum = 1;
    double minWeekAmt = 999999999.0;

    weeklySpending.forEach((w, amt) {
      if (amt > maxWeekAmt) {
        maxWeekAmt = amt;
        highestSpendingWeekNum = w;
      }
      if (amt < minWeekAmt && amt > 0) {
        minWeekAmt = amt;
        lowestSpendingWeekNum = w;
      }
    });

    // Weekend vs Weekday
    double weekendExpense = 0.0;
    double weekdayExpense = 0.0;
    for (final e in filteredExpenses) {
      if (e.expenseDate.weekday == DateTime.saturday ||
          e.expenseDate.weekday == DateTime.sunday) {
        weekendExpense += e.amount;
      } else {
        weekdayExpense += e.amount;
      }
    }

    // 12-Month Yearly Summary (using allExpenses)
    final Map<int, double> yearlyMonthSpending = {};
    for (int m = 1; m <= 12; m++) {
      yearlyMonthSpending[m] = 0.0;
    }
    final currentYear = startDate.year;
    for (final e in allExpenses) {
      if (e.expenseDate.year == currentYear) {
        yearlyMonthSpending[e.expenseDate.month] =
            (yearlyMonthSpending[e.expenseDate.month] ?? 0.0) + e.amount;
      }
    }

    int highestSpendingMonthNum = 1;
    double maxMonthAmt = 0.0;
    int lowestSpendingMonthNum = 1;
    double minMonthAmt = 999999999.0;

    yearlyMonthSpending.forEach((m, amt) {
      if (amt > maxMonthAmt) {
        maxMonthAmt = amt;
        highestSpendingMonthNum = m;
      }
      if (amt < minMonthAmt && amt > 0) {
        minMonthAmt = amt;
        lowestSpendingMonthNum = m;
      }
    });

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // Previous Period Comparison (MoM)
    final Duration periodLength = endDate.difference(startDate);
    final DateTime prevStartDate = startDate.subtract(periodLength);
    final DateTime prevEndDate = startDate.subtract(const Duration(days: 1));

    final prevExpenses = allExpenses.where((e) {
      return e.expenseDate.isAfter(prevStartDate.subtract(const Duration(days: 1))) &&
          e.expenseDate.isBefore(prevEndDate.add(const Duration(days: 1)));
    }).toList();

    final double prevTotalExpense = prevExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final double periodDiff = totalExpense - prevTotalExpense;
    final double periodChangePercent = prevTotalExpense > 0
        ? ((totalExpense - prevTotalExpense) / prevTotalExpense) * 100
        : (totalExpense > 0 ? 100.0 : 0.0);

    // Dynamic Insights Engine
    final List<String> insights = [];
    if (totalTransactions > 0) {
      if (mostExpensiveCategoryName != 'N/A' && totalExpense > 0) {
        final pct = ((maxCategoryAmt / totalExpense) * 100).toStringAsFixed(1);
        insights.add(
          '$mostExpensiveCategoryName accounts for $pct% of your spending (${CurrencyFormatter.format(maxCategoryAmt)}).',
        );
      }
      if (prevTotalExpense > 0) {
        final direction = periodDiff >= 0 ? 'increased' : 'decreased';
        final pctStr = periodChangePercent.abs().toStringAsFixed(1);
        insights.add(
          'Total spending $direction by $pctStr% compared to the previous period (${CurrencyFormatter.format(prevTotalExpense)}).',
        );
      }
      if (highestSpendingMonthNum >= 1 && highestSpendingMonthNum <= 12 && maxMonthAmt > 0) {
        insights.add(
          'Your highest spending month in $currentYear was ${monthNames[highestSpendingMonthNum - 1]} (${CurrencyFormatter.format(maxMonthAmt)}).',
        );
      }
      if (lowestSpendingMonthNum >= 1 && lowestSpendingMonthNum <= 12 && minMonthAmt < 999999999.0 && minMonthAmt > 0) {
        insights.add(
          'Your lowest spending month in $currentYear was ${monthNames[lowestSpendingMonthNum - 1]} (${CurrencyFormatter.format(minMonthAmt)}).',
        );
      }
      if (weekendExpense > 0 && weekdayExpense > 0) {
        final weekendDailyAvg = weekendExpense / 2.0;
        final weekdayDailyAvg = weekdayExpense / 5.0;
        if (weekendDailyAvg > weekdayDailyAvg) {
          final diffPct = (((weekendDailyAvg - weekdayDailyAvg) / weekdayDailyAvg) * 100).toStringAsFixed(1);
          insights.add(
            'You spent $diffPct% more per day during weekends compared to weekdays.',
          );
        }
      }
      insights.add(
        'Average daily expense is ${CurrencyFormatter.format(avgDailyExpense)} across $effectiveDays active days.',
      );
      if (mostUsedPaymentMethod != 'N/A') {
        final methodAmt = paymentMethodAmounts[mostUsedPaymentMethod] ?? 0.0;
        final pct = totalExpense > 0 ? ((methodAmt / totalExpense) * 100).toStringAsFixed(1) : '0';
        insights.add(
          '$mostUsedPaymentMethod is your most used payment method ($pct% of total volume).',
        );
      }
    }

    // Top Lists
    final List<MapEntry<String, double>> sortedCategories =
        categoryAmounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final top10Categories = sortedCategories.take(10).toList();

    final top10Expenses = List<PersonalExpenseEntity>.from(filteredExpenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top10HighestExpenses = top10Expenses.take(10).toList();

    final List<MapEntry<String, double>> sortedDays =
        dailySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final top10ExpensiveDays = sortedDays.take(10).toList();
    final top10CheapestDays = sortedDays.reversed.take(10).toList();

    // Category Colors
    final List<PdfColor> catColors = [
      primaryColor,
      accentBlue,
      accentPurple,
      accentAmber,
      dangerColor,
      PdfColor.fromHex('#06B6D4'),
      PdfColor.fromHex('#8B5CF6'),
      PdfColor.fromHex('#EC4899'),
      PdfColor.fromHex('#64748B'),
      PdfColor.fromHex('#10B981'),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
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
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'BIZOS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Executive Personal Expense Analytics',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: secondaryDark,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  filterTitle,
                  style: pw.TextStyle(fontSize: 9, color: textGrey),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
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
                  'Generated by BizOS Financial Analytics',
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
        },
        build: (pw.Context context) {
          return [
            // ----------------------------------------------------------------
            // 1. EXECUTIVE COVER HEADER
            // ----------------------------------------------------------------
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
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
                        'EXECUTIVE EXPENSE ANALYTICS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Account Holder: ${userName.trim().isNotEmpty ? userName : "Personal Account"}',
                        style: pw.TextStyle(fontSize: 10, color: textGrey),
                      ),
                      pw.Text(
                        'Reporting Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: primaryLight,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: primaryColor, width: 1),
                        ),
                        child: pw.Text(
                          CurrencyFormatter.format(totalExpense),
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$totalTransactions Transactions ($effectiveDays Days)',
                        style: pw.TextStyle(fontSize: 9, color: textGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ----------------------------------------------------------------
            // 2. FINANCIAL SUMMARY METRICS GRID (4 CARDS)
            // ----------------------------------------------------------------
            pw.Row(
              children: [
                _buildSummaryCard('Total Expense', CurrencyFormatter.format(totalExpense), dangerColor, PdfColor.fromHex('#FEF2F2')),
                pw.SizedBox(width: 8),
                _buildSummaryCard('Avg Daily Expense', CurrencyFormatter.format(avgDailyExpense), primaryColor, primaryLight),
                pw.SizedBox(width: 8),
                _buildSummaryCard('Highest Expense', CurrencyFormatter.format(highestExpenseAmount), accentAmber, PdfColor.fromHex('#FEF3C7')),
                pw.SizedBox(width: 8),
                _buildSummaryCard('Lowest Expense', CurrencyFormatter.format(lowestExpenseAmount), accentBlue, PdfColor.fromHex('#EFF6FF')),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildSummaryCard('Total Transactions', '$totalTransactions', secondaryDark, bgLight),
                pw.SizedBox(width: 8),
                _buildSummaryCard('Avg Transaction', CurrencyFormatter.format(avgTransactionValue), accentPurple, PdfColor.fromHex('#F3E8FF')),
                pw.SizedBox(width: 8),
                _buildSummaryCard('Median Expense', CurrencyFormatter.format(medianExpense), primaryColor, primaryLight),
                pw.SizedBox(width: 8),
                _buildSummaryCard('Most Expensive Cat', mostExpensiveCategoryName, dangerColor, PdfColor.fromHex('#FEF2F2')),
              ],
            ),
            pw.SizedBox(height: 14),

            // EMPTY STATE CHECK
            if (filteredExpenses.isEmpty) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(32),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'No expenses found for the selected period.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: textGrey,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Try selecting a broader date range filter.',
                      style: pw.TextStyle(fontSize: 10, color: textGrey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // --------------------------------------------------------------
              // 3. CATEGORY DISTRIBUTION DONUT / PROGRESS BARS
              // --------------------------------------------------------------
              pw.Text(
                'Category Expense Distribution',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  children: List.generate(top10Categories.length, (idx) {
                    final entry = top10Categories[idx];
                    final catName = entry.key;
                    final catAmt = entry.value;
                    final pct = totalExpense > 0 ? (catAmt / totalExpense) : 0.0;
                    final color = catColors[idx % catColors.length];

                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                '${idx + 1}. $catName',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              pw.Text(
                                '${CurrencyFormatter.format(catAmt)} (${(pct * 100).toStringAsFixed(1)}%)',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Stack(
                            children: [
                              pw.Container(
                                height: 5,
                                width: double.infinity,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  borderRadius: pw.BorderRadius.circular(2.5),
                                ),
                              ),
                              pw.Container(
                                height: 5,
                                width: (pct * 480).clamp(5.0, 480.0),
                                decoration: pw.BoxDecoration(
                                  color: color,
                                  borderRadius: pw.BorderRadius.circular(2.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              pw.SizedBox(height: 14),

              // --------------------------------------------------------------
              // 4. MONTHLY SPENDING TREND (12 MONTH STEP GRAPH)
              // --------------------------------------------------------------
              pw.Text(
                '12-Month Expense Trend ($currentYear)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: List.generate(12, (mIdx) {
                        final monthNum = mIdx + 1;
                        final amt = yearlyMonthSpending[monthNum] ?? 0.0;
                        final barHeight = maxMonthAmt > 0
                            ? ((amt / maxMonthAmt) * 50).clamp(4.0, 50.0)
                            : 4.0;
                        final isHighest = monthNum == highestSpendingMonthNum && maxMonthAmt > 0;
                        final isLowest = monthNum == lowestSpendingMonthNum && minMonthAmt < 999999999.0;

                        final barColor = isHighest
                            ? dangerColor
                            : (isLowest ? successColor : primaryColor);

                        return pw.Column(
                          children: [
                            pw.Text(
                              amt > 0 ? '${(amt / 1000).toStringAsFixed(0)}k' : '-',
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: isHighest ? dangerColor : textGrey,
                                fontWeight: isHighest ? pw.FontWeight.bold : pw.FontWeight.normal,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              width: 22,
                              height: barHeight,
                              decoration: pw.BoxDecoration(
                                color: barColor,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              monthNames[mIdx],
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildLegendIndicator('Highest Month', dangerColor),
                        pw.SizedBox(width: 12),
                        _buildLegendIndicator('Lowest Month', successColor),
                        pw.SizedBox(width: 12),
                        _buildLegendIndicator('Regular Month', primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // --------------------------------------------------------------
              // 5. WEEKLY EXPENSE GRAPH (W1 - W5)
              // --------------------------------------------------------------
              pw.Text(
                'Weekly Expense Distribution',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Row(
                children: List.generate(5, (wIdx) {
                  final weekNum = wIdx + 1;
                  final amt = weeklySpending[weekNum] ?? 0.0;
                  final pct = totalExpense > 0 ? (amt / totalExpense * 100) : 0.0;
                  final isHighest = weekNum == highestSpendingWeekNum && maxWeekAmt > 0;

                  return pw.Expanded(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(right: 6),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: isHighest ? primaryLight : bgLight,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: isHighest ? primaryColor : borderColor,
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Week $weekNum',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: isHighest ? primaryColor : textGrey,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            CurrencyFormatter.format(amt),
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          pw.Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: isHighest ? primaryColor : textGrey,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              pw.SizedBox(height: 14),

              // --------------------------------------------------------------
              // 6. PAYMENT METHOD BREAKDOWN
              // --------------------------------------------------------------
              pw.Text(
                'Payment Method Proportions',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Row(
                children: paymentMethodAmounts.entries.map((e) {
                  final method = e.key;
                  final amt = e.value;
                  final pct = totalExpense > 0 ? (amt / totalExpense * 100) : 0.0;

                  return pw.Expanded(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(right: 6),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: bgLight,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: borderColor),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            method,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: textGrey,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            CurrencyFormatter.format(amt),
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          pw.Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: primaryColor,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 14),

              // --------------------------------------------------------------
              // 7. INSIGHTS & MONTH-OVER-MONTH COMPARISON
              // --------------------------------------------------------------
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Insights Box
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: primaryLight,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: primaryColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Smart Financial Insights',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          ...insights.map(
                            (txt) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('• ',
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor,
                                      )),
                                  pw.Expanded(
                                    child: pw.Text(
                                      txt,
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        color: textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),

                  // Month-over-Month Comparison
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
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
                            'Period-over-Period Growth',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          _buildStatRow('Current Period Total', CurrencyFormatter.format(totalExpense)),
                          _buildStatRow('Previous Period Total', CurrencyFormatter.format(prevTotalExpense)),
                          _buildStatRow('Absolute Variance', CurrencyFormatter.format(periodDiff.abs())),
                          pw.Divider(color: borderColor, height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Growth Status',
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textGrey,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: periodDiff <= 0 ? successLight : PdfColor.fromHex('#FEF2F2'),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  '${periodDiff >= 0 ? "+" : "-"}${periodChangePercent.abs().toStringAsFixed(1)}%',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: periodDiff <= 0 ? successColor : dangerColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // --------------------------------------------------------------
              // 8. TOP 10 LISTS (RANKED CATEGORIES & HIGHEST EXPENSES)
              // --------------------------------------------------------------
              pw.Text(
                'Top Financial Rankings',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Top 10 Highest Single Expenses
                  pw.Expanded(
                    child: pw.Container(
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
                            'Top 10 Highest Expenses',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: secondaryDark,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          ...List.generate(top10HighestExpenses.length, (i) {
                            final item = top10HighestExpenses[i];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      '${i + 1}. ${item.category} (${shortDateFormat.format(item.expenseDate)})',
                                      style: pw.TextStyle(fontSize: 8, color: textDark),
                                      maxLines: 1,
                                    ),
                                  ),
                                  pw.Text(
                                    CurrencyFormatter.format(item.amount),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: dangerColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),

                  // Top 10 Highest Spending Days
                  pw.Expanded(
                    child: pw.Container(
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
                            'Top 10 Expensive Days',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: secondaryDark,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          ...List.generate(top10ExpensiveDays.length, (i) {
                            final item = top10ExpensiveDays[i];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    '${i + 1}. ${item.key}',
                                    style: pw.TextStyle(fontSize: 8, color: textDark),
                                  ),
                                  pw.Text(
                                    CurrencyFormatter.format(item.value),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: accentAmber,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),

                  // Top 10 Lowest Spending Days
                  pw.Expanded(
                    child: pw.Container(
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
                            'Top 10 Lowest Days',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: secondaryDark,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          ...List.generate(top10CheapestDays.length, (i) {
                            final item = top10CheapestDays[i];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    '${i + 1}. ${item.key}',
                                    style: pw.TextStyle(fontSize: 8, color: textDark),
                                  ),
                                  pw.Text(
                                    CurrencyFormatter.format(item.value),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: successColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // --------------------------------------------------------------
              // 9. EXPENSE BREAKDOWN TABLE
              // --------------------------------------------------------------
              pw.Text(
                'Full Expense Transaction Ledger',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: secondaryDark),
                    children: [
                      _buildTableHeaderCell('Date'),
                      _buildTableHeaderCell('Category'),
                      _buildTableHeaderCell('Description'),
                      _buildTableHeaderCell('Method'),
                      _buildTableHeaderCell('Amount', alignRight: true),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(sortedExpenses.length, (idx) {
                    final exp = sortedExpenses[idx];
                    final isEven = idx % 2 == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : bgLight,
                      ),
                      children: [
                        _buildTableCell(dateFormat.format(exp.expenseDate)),
                        _buildTableCell(exp.category),
                        _buildTableCell(exp.description.trim().isNotEmpty
                            ? exp.description
                            : '-'),
                        _buildTableCell(exp.paymentMethod),
                        _buildTableCell(
                          CurrencyFormatter.format(exp.amount),
                          alignRight: true,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 14),

              // --------------------------------------------------------------
              // 10. ADVANCED ANALYTICS (22 KEY METRICS TABLE)
              // --------------------------------------------------------------
              pw.Text(
                'Comprehensive Financial Metrics (22 Analytics)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  children: [
                    _buildStatRow('Highest Spending Month', '${monthNames[highestSpendingMonthNum - 1]} (${CurrencyFormatter.format(maxMonthAmt)})'),
                    _buildStatRow('Lowest Spending Month', '${monthNames[lowestSpendingMonthNum - 1]} (${CurrencyFormatter.format(minMonthAmt < 999999999.0 ? minMonthAmt : 0.0)})'),
                    _buildStatRow('Highest Spending Day', '$highestSpendingDay (${CurrencyFormatter.format(maxDayAmt)})'),
                    _buildStatRow('Lowest Spending Day', '$lowestSpendingDay (${CurrencyFormatter.format(minDayAmt < 999999999.0 ? minDayAmt : 0.0)})'),
                    _buildStatRow('Highest Spending Week', 'Week $highestSpendingWeekNum (${CurrencyFormatter.format(maxWeekAmt)})'),
                    _buildStatRow('Lowest Spending Week', 'Week $lowestSpendingWeekNum (${CurrencyFormatter.format(minWeekAmt < 999999999.0 ? minWeekAmt : 0.0)})'),
                    _buildStatRow('Highest Single Expense', CurrencyFormatter.format(highestExpenseAmount)),
                    _buildStatRow('Lowest Single Expense', CurrencyFormatter.format(lowestExpenseAmount)),
                    _buildStatRow('Average Daily Expense', CurrencyFormatter.format(avgDailyExpense)),
                    _buildStatRow('Average Weekly Expense', CurrencyFormatter.format(avgWeeklyExpense)),
                    _buildStatRow('Average Monthly Expense', CurrencyFormatter.format(avgMonthlyExpense)),
                    _buildStatRow('Average Transaction Value', CurrencyFormatter.format(avgTransactionValue)),
                    _buildStatRow('Median Expense Value', CurrencyFormatter.format(medianExpense)),
                    _buildStatRow('Total Recorded Transactions', '$totalTransactions'),
                    _buildStatRow('Categories Count', '$numCategories'),
                    _buildStatRow('Most Used Category', '$mostUsedCategoryName ($maxCategoryCnt times)'),
                    _buildStatRow('Least Used Category', '$leastUsedCategoryName ($minCategoryCnt times)'),
                    _buildStatRow('Most Expensive Category', '$mostExpensiveCategoryName (${CurrencyFormatter.format(maxCategoryAmt)})'),
                    _buildStatRow('Least Expensive Category', '$leastExpensiveCategoryName (${CurrencyFormatter.format(minCategoryAmt < 999999999.0 ? minCategoryAmt : 0.0)})'),
                    _buildStatRow('Most Used Payment Method', '$mostUsedPaymentMethod ($maxMethodCnt times)'),
                    _buildStatRow('Least Used Payment Method', '$leastUsedPaymentMethod ($minMethodCnt times)'),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --------------------------------------------------------------------------
  // HELPER BUILDERS
  // --------------------------------------------------------------------------

  static pw.Widget _buildSummaryCard(
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
                color: PdfColor.fromHex('#0F172A'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildLegendIndicator(String label, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#64748B')),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String title, {bool alignRight = false}) {
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

  static pw.Widget _buildTableCell(
    String value, {
    bool alignRight = false,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex('#1E293B'),
        ),
      ),
    );
  }

  static pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#64748B')),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SHARE & PRINT UTILITIES
  // --------------------------------------------------------------------------

  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    final file = XFile.fromData(
      pdfBytes,
      name: fileName,
      mimeType: 'application/pdf',
    );
    await SharePlus.instance.share(
      ShareParams(files: [file], text: 'Executive Personal Expense Analytics Report'),
    );
  }

  static Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
}
