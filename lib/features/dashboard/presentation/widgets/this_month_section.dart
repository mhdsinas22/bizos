import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/dashboard/presentation/widgets/card_wave_painter.dart';

/// "This Month" financial summary section.
/// Displays month selector and 3 financial cards: Income, Expense, Profit.
class ThisMonthSection extends StatefulWidget {
  final Map<String, Map<String, double>> monthlySummary;
  final bool hasFinancialAccess;

  const ThisMonthSection({
    super.key,
    required this.monthlySummary,
    this.hasFinancialAccess = true,
  });

  @override
  State<ThisMonthSection> createState() => _ThisMonthSectionState();
}

class _ThisMonthSectionState extends State<ThisMonthSection> {
  late String _selectedMonthKey;

  @override
  void initState() {
    super.initState();
    _initSelectedMonth();
  }

  @override
  void didUpdateWidget(covariant ThisMonthSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.monthlySummary.containsKey(_selectedMonthKey)) {
      _initSelectedMonth();
    }
  }

  void _initSelectedMonth() {
    final now = DateTime.now();
    final currentKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (widget.monthlySummary.containsKey(currentKey)) {
      _selectedMonthKey = currentKey;
    } else if (widget.monthlySummary.isNotEmpty) {
      final sortedKeys = widget.monthlySummary.keys.toList()..sort();
      _selectedMonthKey = sortedKeys.last;
    } else {
      _selectedMonthKey = currentKey;
    }
  }

  String _formatMonthLabel(String key) {
    try {
      final parts = key.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return key;
    }
  }

  void _showMonthPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = widget.monthlySummary.keys.toList()..sort();
    final reversedKeys = keys.reversed.toList();

    // If empty, allow current month
    final availableKeys = reversedKeys.isNotEmpty
        ? reversedKeys
        : [_selectedMonthKey];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Month',
                      style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableKeys.length,
                  itemBuilder: (_, index) {
                    final key = availableKeys[index];
                    final isSelected = key == _selectedMonthKey;
                    return ListTile(
                      title: Text(
                        _formatMonthLabel(key),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedMonthKey = key;
                        });
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentData = widget.monthlySummary[_selectedMonthKey] ??
        {'income': 0.0, 'expense': 0.0};
    final double income = currentData['income'] ?? 0.0;
    final double expense = currentData['expense'] ?? 0.0;
    final double profit = income - expense;

    // Previous month comparison
    double? incomeDiffPct;
    double? expenseDiffPct;
    double? profitDiffPct;

    try {
      final parts = _selectedMonthKey.split('-');
      final curYear = int.parse(parts[0]);
      final curMonth = int.parse(parts[1]);
      final prevDate = DateTime(curYear, curMonth - 1);
      final prevKey =
          '${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}';

      if (widget.monthlySummary.containsKey(prevKey)) {
        final prevData = widget.monthlySummary[prevKey]!;
        final prevIncome = prevData['income'] ?? 0.0;
        final prevExpense = prevData['expense'] ?? 0.0;
        final prevProfit = prevIncome - prevExpense;

        if (prevIncome > 0) {
          incomeDiffPct = ((income - prevIncome) / prevIncome) * 100;
        }
        if (prevExpense > 0) {
          expenseDiffPct = ((expense - prevExpense) / prevExpense) * 100;
        }
        if (prevProfit.abs() > 0) {
          profitDiffPct = ((profit - prevProfit) / prevProfit.abs()) * 100;
        }
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryColor.withValues(alpha: 0.22)
                    : AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 19,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Your business financial summary for this month.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Month Selector Button
            InkWell(
              onTap: () => _showMonthPicker(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161F30)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMonthLabel(_selectedMonthKey),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3 Financial Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardSpacing = 10.0;
            final isSmall = constraints.maxWidth < 340;

            final incomeCard = MonthlySummaryCard(
              title: 'This Month\nIncome',
              amount: widget.hasFinancialAccess
                  ? CurrencyFormatter.format(income)
                  : '••••',
              trendPct: widget.hasFinancialAccess ? incomeDiffPct : null,
              isIncome: true,
              icon: Icons.arrow_upward_rounded,
              themeColor: AppTheme.success,
              darkBg: const Color(0xFF0C241E),
              lightBg: const Color(0xFFF0FDF4),
              darkBorder: const Color(0xFF10B981).withValues(alpha: 0.28),
              lightBorder: const Color(0xFFBBF7D0),
            );

            final expenseCard = MonthlySummaryCard(
              title: 'This Month\nExpense',
              amount: widget.hasFinancialAccess
                  ? CurrencyFormatter.format(expense)
                  : '••••',
              trendPct: widget.hasFinancialAccess ? expenseDiffPct : null,
              isExpense: true,
              icon: Icons.arrow_downward_rounded,
              themeColor: AppTheme.error,
              darkBg: const Color(0xFF28131B),
              lightBg: const Color(0xFFFFF1F2),
              darkBorder: const Color(0xFFF43F5E).withValues(alpha: 0.28),
              lightBorder: const Color(0xFFFECDD3),
            );

            final profitCard = MonthlySummaryCard(
              title: 'This Month\nProfit',
              amount: widget.hasFinancialAccess
                  ? CurrencyFormatter.format(profit)
                  : '••••',
              trendPct: widget.hasFinancialAccess ? profitDiffPct : null,
              isProfit: true,
              icon: Icons.bar_chart_rounded,
              themeColor: const Color(0xFF818CF8),
              darkBg: const Color(0xFF181533),
              lightBg: const Color(0xFFF5F3FF),
              darkBorder: const Color(0xFF818CF8).withValues(alpha: 0.28),
              lightBorder: const Color(0xFFDDD6FE),
            );

            if (isSmall) {
              return Column(
                children: [
                  incomeCard,
                  SizedBox(height: cardSpacing),
                  expenseCard,
                  SizedBox(height: cardSpacing),
                  profitCard,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: incomeCard),
                SizedBox(width: cardSpacing),
                Expanded(child: expenseCard),
                SizedBox(width: cardSpacing),
                Expanded(child: profitCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class MonthlySummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final double? trendPct;
  final bool isIncome;
  final bool isExpense;
  final bool isProfit;
  final IconData icon;
  final Color themeColor;
  final Color darkBg;
  final Color lightBg;
  final Color darkBorder;
  final Color lightBorder;

  const MonthlySummaryCard({
    super.key,
    required this.title,
    required this.amount,
    this.trendPct,
    this.isIncome = false,
    this.isExpense = false,
    this.isProfit = false,
    required this.icon,
    required this.themeColor,
    required this.darkBg,
    required this.lightBg,
    required this.darkBorder,
    required this.lightBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : lightBg;
    final borderColor = isDark ? darkBorder : lightBorder;

    // Trend calculation
    final hasTrend = trendPct != null;
    final isPositive = (trendPct ?? 0) >= 0;

    // In business metrics: income/profit increase is good (green), expense increase is red
    final Color trendColor;
    if (isExpense) {
      trendColor = isPositive ? AppTheme.error : AppTheme.success;
    } else {
      trendColor = isPositive ? AppTheme.success : AppTheme.error;
    }

    final trendIcon =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final trendSign = isPositive ? '+' : '';
    final trendText = hasTrend ? '$trendSign${trendPct!.toStringAsFixed(0)}%' : '';

    return Container(
      height: 165,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Wave decoration at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 65,
            child: CustomPaint(
              painter: CardWavePainter(color: themeColor),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Icon + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(
                          alpha: isDark ? 0.22 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: themeColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Amount
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),

                // Bottom Trend & Comparison
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasTrend) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trendIcon, size: 12, color: trendColor),
                          const SizedBox(width: 2),
                          Text(
                            trendText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: trendColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'vs last month',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Current month',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
