import 'package:bizos/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateFilterOption {
  allTime,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

class DateFilterResult {
  final DateTime? startDate;
  final DateTime? endDate;
  final String label;
  final DateFilterOption selectedOption;

  const DateFilterResult({
    this.startDate,
    this.endDate,
    required this.label,
    required this.selectedOption,
  });
}

class DateFilterBottomSheet extends StatefulWidget {
  final DateFilterOption initialOption;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const DateFilterBottomSheet({
    super.key,
    this.initialOption = DateFilterOption.allTime,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<DateFilterBottomSheet> createState() => _DateFilterBottomSheetState();
}

class _DateFilterBottomSheetState extends State<DateFilterBottomSheet> {
  late DateFilterOption _selectedOption;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      _customRange = DateTimeRange(
        start: widget.initialStartDate!,
        end: widget.initialEndDate!,
      );
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedOption = DateFilterOption.custom;
        _customRange = picked;
      });
    }
  }

  DateFilterResult _calculateResult() {
    final now = DateTime.now();

    switch (_selectedOption) {
      case DateFilterOption.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateFilterResult(
          startDate: start,
          endDate: end,
          label: 'Today',
          selectedOption: _selectedOption,
        );

      case DateFilterOption.yesterday:
        final y = now.subtract(const Duration(days: 1));
        final start = DateTime(y.year, y.month, y.day, 0, 0, 0);
        final end = DateTime(y.year, y.month, y.day, 23, 59, 59, 999);
        return DateFilterResult(
          startDate: start,
          endDate: end,
          label: 'Yesterday',
          selectedOption: _selectedOption,
        );

      case DateFilterOption.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
        return DateFilterResult(
          startDate: start,
          endDate: end,
          label: 'This Week',
          selectedOption: _selectedOption,
        );

      case DateFilterOption.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateFilterResult(
          startDate: start,
          endDate: end,
          label: 'This Month',
          selectedOption: _selectedOption,
        );

      case DateFilterOption.lastMonth:
        final lastMonthFirst = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(lastMonthFirst.year, lastMonthFirst.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        return DateFilterResult(
          startDate: start,
          endDate: end,
          label: 'Last Month',
          selectedOption: _selectedOption,
        );

      case DateFilterOption.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0);
        final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateFilterResult(
          startDate: start,
          endDate: end,
          label: 'This Year',
          selectedOption: _selectedOption,
        );

      case DateFilterOption.custom:
        if (_customRange != null) {
          final start = DateTime(
            _customRange!.start.year,
            _customRange!.start.month,
            _customRange!.start.day,
            0,
            0,
            0,
          );
          final end = DateTime(
            _customRange!.end.year,
            _customRange!.end.month,
            _customRange!.end.day,
            23,
            59,
            59,
            999,
          );
          final fmt = DateFormat('MMM d');
          return DateFilterResult(
            startDate: start,
            endDate: end,
            label: '${fmt.format(start)} - ${fmt.format(end)}',
            selectedOption: _selectedOption,
          );
        }
        return const DateFilterResult(
          label: 'All Time',
          selectedOption: DateFilterOption.allTime,
        );

      case DateFilterOption.allTime:
        return const DateFilterResult(
          label: 'All Time',
          selectedOption: DateFilterOption.allTime,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      {'option': DateFilterOption.today, 'title': 'Today'},
      {'option': DateFilterOption.yesterday, 'title': 'Yesterday'},
      {'option': DateFilterOption.thisWeek, 'title': 'This Week'},
      {'option': DateFilterOption.thisMonth, 'title': 'This Month'},
      {'option': DateFilterOption.lastMonth, 'title': 'Last Month'},
      {'option': DateFilterOption.thisYear, 'title': 'This Year'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter by Date Range',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          ...options.map((item) {
            final opt = item['option'] as DateFilterOption;
            final title = item['title'] as String;
            final isSelected = _selectedOption == opt;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: theme.primaryColor)
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
              onTap: () {
                setState(() {
                  _selectedOption = opt;
                });
              },
            );
          }),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _selectedOption == DateFilterOption.custom && _customRange != null
                  ? 'Custom Range (${DateFormat.yMMMd().format(_customRange!.start)} - ${DateFormat.yMMMd().format(_customRange!.end)})'
                  : 'Custom Date Range',
              style: TextStyle(
                fontWeight: _selectedOption == DateFilterOption.custom
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _selectedOption == DateFilterOption.custom
                    ? theme.primaryColor
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
            trailing: _selectedOption == DateFilterOption.custom
                ? Icon(Icons.check_circle, color: theme.primaryColor)
                : const Icon(Icons.date_range, color: Colors.grey),
            onTap: _pickCustomRange,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      const DateFilterResult(
                        label: 'All Time',
                        selectedOption: DateFilterOption.allTime,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Apply',
                  onPressed: () {
                    final result = _calculateResult();
                    Navigator.pop(context, result);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
