import 'package:flutter/material.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/dashboard/presentation/widgets/card_wave_painter.dart';

/// "Overall Performance" section showing total business financial records:
/// Total Income, Total Expenses, and Net Profit.
class OverallPerformanceSection extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double totalProfit;
  final bool hasFinancialAccess;
  final VoidCallback? onTapIncome;
  final VoidCallback? onTapExpense;
  final VoidCallback? onTapProfit;

  const OverallPerformanceSection({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalProfit,
    this.hasFinancialAccess = true,
    this.onTapIncome,
    this.onTapExpense,
    this.onTapProfit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                Icons.bar_chart_rounded,
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
                    'Overall Performance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Total business financial records.',
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
          ],
        ),
        const SizedBox(height: 14),

        // 3 Cards: Total Income, Total Expenses, Net Profit
        LayoutBuilder(
          builder: (context, constraints) {
            final cardSpacing = 10.0;
            final isSmall = constraints.maxWidth < 340;

            final incomeCard = PerformanceMetricCard(
              title: 'Total Income',
              amount: hasFinancialAccess
                  ? CurrencyFormatter.format(totalIncome)
                  : '••••',
              icon: Icons.savings_outlined,
              themeColor: const Color(0xFF38BDF8),
              darkBg: const Color(0xFF0F1E2C),
              lightBg: const Color(0xFFF0F9FF),
              darkBorder: const Color(0xFF38BDF8).withValues(alpha: 0.28),
              lightBorder: const Color(0xFFBAE6FD),
              onTap: onTapIncome,
            );

            final expenseCard = PerformanceMetricCard(
              title: 'Total Expenses',
              amount: hasFinancialAccess
                  ? CurrencyFormatter.format(totalExpenses)
                  : '••••',
              icon: Icons.account_balance_wallet_outlined,
              themeColor: AppTheme.error,
              darkBg: const Color(0xFF28131B),
              lightBg: const Color(0xFFFFF1F2),
              darkBorder: const Color(0xFFF43F5E).withValues(alpha: 0.28),
              lightBorder: const Color(0xFFFECDD3),
              onTap: onTapExpense,
            );

            final profitCard = PerformanceMetricCard(
              title: 'Net Profit',
              amount: hasFinancialAccess
                  ? CurrencyFormatter.format(totalProfit)
                  : '••••',
              icon: Icons.pie_chart_rounded,
              themeColor: const Color(0xFF818CF8),
              darkBg: const Color(0xFF181533),
              lightBg: const Color(0xFFF5F3FF),
              darkBorder: const Color(0xFF818CF8).withValues(alpha: 0.28),
              lightBorder: const Color(0xFFDDD6FE),
              onTap: onTapProfit,
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

class PerformanceMetricCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color themeColor;
  final Color darkBg;
  final Color lightBg;
  final Color darkBorder;
  final Color lightBorder;
  final VoidCallback? onTap;

  const PerformanceMetricCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.themeColor,
    required this.darkBg,
    required this.lightBg,
    required this.darkBorder,
    required this.lightBorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : lightBg;
    final borderColor = isDark ? darkBorder : lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Wave decoration at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 52,
              child: CustomPaint(
                painter: CardWavePainter(color: themeColor),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: Icon on left, chevron on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),

                  // Middle title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Bottom amount
                  FittedBox(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
