import 'package:bizos/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatefulWidget {
  final Map<String, double> categoryAnalytics;

  const ExpensePieChart({super.key, required this.categoryAnalytics});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int _touchedIndex = -1;

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orangeAccent;
      case 'travel':
        return Colors.blueAccent;
      case 'fuel':
        return Colors.amber;
      case 'shopping':
        return Colors.pinkAccent;
      case 'medical':
        return Colors.redAccent;
      case 'family':
        return Colors.green;
      case 'education':
        return Colors.purpleAccent;
      case 'entertainment':
        return Colors.deepPurpleAccent;
      case 'bills':
        return Colors.teal;
      case 'investment':
        return Colors.cyan;
      case 'other':
        return Colors.grey;
      default:
        final hash = category.hashCode;
        final colors = [
          Colors.deepOrange,
          Colors.lightGreen,
          Colors.lime,
          Colors.indigo,
          Colors.brown,
          Colors.blueGrey,
          Colors.pink, // Fallback if custom colors aren't defined, we use standard colors
          Colors.amberAccent,
        ];
        return colors[hash.abs() % colors.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter out zero categories
    final data = widget.categoryAnalytics.entries
        .where((entry) => entry.value > 0.0)
        .toList();

    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              'No data for pie chart',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final double totalAmount = data.fold(0.0, (sum, entry) => sum + entry.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 450;
          final List<Widget> children = [
            // Pie Chart Widget
            Expanded(
              flex: isWide ? 5 : 0,
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(data.length, (i) {
                      final entry = data[i];
                      final isTouched = i == _touchedIndex;
                      final double fontSize = isTouched ? 16 : 12;
                      final double radius = isTouched ? 60 : 50;
                      final double percentage = (entry.value / totalAmount) * 100;
                      final color = _getCategoryColor(entry.key);

                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 2),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            if (!isWide) const SizedBox(height: 20),
            // Legend Widget
            Expanded(
              flex: isWide ? 6 : 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.map((entry) {
                  final color = _getCategoryColor(entry.key);
                  final percentage = (entry.value / totalAmount) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '\$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ];

          return isWide
              ? Row(children: children)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                );
        },
      ),
    );
  }
}
