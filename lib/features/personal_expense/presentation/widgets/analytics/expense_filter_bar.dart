import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String filterType) onFilterChanged;
  final Function(DateTime start, DateTime end)? onCustomRangeSelected;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const ExpenseFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.onCustomRangeSelected,
    this.customStartDate,
    this.customEndDate,
  });

  Future<void> _selectCustomRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: customStartDate != null && customEndDate != null
          ? DateTimeRange(start: customStartDate!, end: customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && onCustomRangeSelected != null) {
      onCustomRangeSelected!(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = [
      {'label': 'All', 'type': 'all'},
      {'label': 'Today', 'type': 'today'},
      {'label': 'This Week', 'type': 'week'},
      {'label': 'This Month', 'type': 'month'},
      {'label': 'This Year', 'type': 'year'},
      {'label': 'Custom Range', 'type': 'custom'},
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final label = filter['label']!;
          final type = filter['type']!;
          final isSelected = selectedFilter == type;

          String displayLabel = label;
          if (type == 'custom' && customStartDate != null && customEndDate != null) {
            final format = DateFormat('MM/dd');
            displayLabel = '${format.format(customStartDate!)} - ${format.format(customEndDate!)}';
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                displayLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              onSelected: (selected) {
                if (type == 'custom') {
                  _selectCustomRange(context);
                } else {
                  onFilterChanged(type);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
