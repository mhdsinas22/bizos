import 'package:bizos/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/utils/currency_formatter.dart';

class IncomeExpenseChart extends StatelessWidget {
  final Map<String, Map<String, double>> monthlySummary;
  const IncomeExpenseChart({super.key, required this.monthlySummary});

  @override
  Widget build(BuildContext context) {
    // Sort keys chronologically
    final sortedKeys = monthlySummary.keys.toList()..sort();
    final keysToShow = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    List<BarChartGroupData> barGroups = [];
    double maxY = 1000.0;

    for (int i = 0; i < keysToShow.length; i++) {
      final key = keysToShow[i];
      final inc = monthlySummary[key]?['income'] ?? 0.0;
      final exp = monthlySummary[key]?['expense'] ?? 0.0;

      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: inc,
              color: AppTheme.success,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: exp,
              color: AppTheme.error,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    // Round maxY up for padding
    maxY = (maxY * 1.15).ceilToDouble();
    if (maxY == 0) maxY = 100.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Theme.of(context).cardColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isInc = rodIndex == 0;
              final val = CurrencyFormatter.format(rod.toY);
              return BarTooltipItem(
                '${isInc ? "Income" : "Expense"}\n$val',
                TextStyle(
                  color: isInc ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int idx = value.toInt();
                if (idx >= 0 && idx < keysToShow.length) {
                  // Format key YYYY-MM into Month Abbr
                  final key = keysToShow[idx];
                  try {
                    final parts = key.split('-');
                    final dt = DateTime(
                      int.parse(parts[0]),
                      int.parse(parts[1]),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM').format(dt),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } catch (e) {
                    return Text(key);
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const Text('0');
                if (value >= 1000) {
                  return Text('${(value / 1000).toStringAsFixed(1)}k');
                }
                return Text(value.toStringAsFixed(0));
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkBorder
                  : AppTheme.lightBorder,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
