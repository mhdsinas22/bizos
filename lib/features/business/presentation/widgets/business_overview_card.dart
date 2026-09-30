import 'package:flutter/material.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/business/presentation/widgets/business_metric_item.dart';

class BusinessOverviewCard extends StatelessWidget {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final int totalInvoices;
  final VoidCallback? onOverviewTap;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onExpensesTap;
  final VoidCallback? onProfitTap;
  final VoidCallback? onInvoicesTap;

  const BusinessOverviewCard({
    super.key,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalInvoices,
    this.onOverviewTap,
    this.onRevenueTap,
    this.onExpensesTap,
    this.onProfitTap,
    this.onInvoicesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF13192B),
                  Color(0xFF182038),
                  Color(0xFF0F1523),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F5FF),
                  Color(0xFFEBF1FF),
                  Color(0xFFF9FAFD),
                ],
              ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E3856)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Banner: Overview header with 3D illustration
          InkWell(
            onTap: onOverviewTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                children: [
                  // Squircle Bar Chart Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Overview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Business summary and insights',
                          style: TextStyle(
                            fontSize: 12,
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

                  // 3D Storefront Illustration (Adaptive sizing)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.sizeOf(context).width;
                      final isCompact = screenWidth < 360;
                      final imgWidth = isCompact ? 60.0 : 80.0;
                      final imgHeight = isCompact ? 54.0 : 72.0;

                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Image.asset(
                          'assets/icon/store_3d.png',
                          height: imgHeight,
                          width: imgWidth,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => SizedBox(
                            height: imgHeight,
                            width: imgWidth,
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 36,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Inner Metrics Container: 4 columns in 1 single row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0C101D).withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF26304D).withValues(alpha: 0.7)
                      : const Color(0xFFE5E7EB).withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 1. Total Revenue
                  Expanded(
                    child: BusinessMetricItem(
                      icon: Icons.attach_money_rounded,
                      iconColor: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF10B981),
                      iconBgColor: isDark
                          ? const Color(0xFF0D3322)
                          : const Color(0xFFE6F7ED),
                      label: 'Total Revenue',
                      value: CurrencyFormatter.format(totalRevenue),
                      trend: totalRevenue > 0 ? '+12%' : null,
                      isPositiveTrend: true,
                      trendColor: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669),
                      onTap: onRevenueTap,
                    ),
                  ),
                  _buildDivider(isDark),

                  // 2. Total Expenses
                  Expanded(
                    child: BusinessMetricItem(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: isDark
                          ? const Color(0xFFF87171)
                          : const Color(0xFFEF4444),
                      iconBgColor: isDark
                          ? const Color(0xFF3B1818)
                          : const Color(0xFFFEE2E2),
                      label: 'Total Expenses',
                      value: CurrencyFormatter.format(totalExpenses),
                      trend: totalExpenses > 0 ? '+8%' : null,
                      isPositiveTrend: true, // Upward arrow as in reference image
                      trendColor: isDark
                          ? const Color(0xFFF87171)
                          : const Color(0xFFEF4444),
                      onTap: onExpensesTap,
                    ),
                  ),
                  _buildDivider(isDark),

                  // 3. Net Profit
                  Expanded(
                    child: BusinessMetricItem(
                      icon: Icons.pie_chart_rounded,
                      iconColor: isDark
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFF8B5CF6),
                      iconBgColor: isDark
                          ? const Color(0xFF281B45)
                          : const Color(0xFFEDE9FE),
                      label: 'Net Profit',
                      value: CurrencyFormatter.format(netProfit),
                      trend: netProfit >= 0 ? '+18%' : '-5%',
                      isPositiveTrend: netProfit >= 0,
                      trendColor: netProfit >= 0
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                          : (isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444)),
                      onTap: onProfitTap,
                    ),
                  ),
                  _buildDivider(isDark),

                  // 4. Total Invoices
                  Expanded(
                    child: BusinessMetricItem(
                      icon: Icons.description_rounded,
                      iconColor: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF3B82F6),
                      iconBgColor: isDark
                          ? const Color(0xFF16274B)
                          : const Color(0xFFDBEAFE),
                      label: 'Total Invoices',
                      value: '$totalInvoices',
                      trend: totalInvoices > 0 ? '+2' : null,
                      isPositiveTrend: false, // Downward arrow as in reference image
                      trendColor: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB),
                      onTap: onInvoicesTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isDark
          ? const Color(0xFF26304D).withValues(alpha: 0.6)
          : const Color(0xFFE5E7EB),
    );
  }
}

