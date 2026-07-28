import 'package:flutter/material.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/task_repeat_mapper.dart';

class PersonalFilterSheet extends StatefulWidget {
  final String currentPriority;
  final String currentStatus;
  final String currentRepeat;
  final void Function({
    required String priority,
    required String status,
    required String repeat,
  }) onApplyFilters;

  const PersonalFilterSheet({
    super.key,
    required this.currentPriority,
    required this.currentStatus,
    required this.currentRepeat,
    required this.onApplyFilters,
  });

  @override
  State<PersonalFilterSheet> createState() => _PersonalFilterSheetState();
}

class _PersonalFilterSheetState extends State<PersonalFilterSheet> {
  late String _priority;
  late String _status;
  late String _repeat;

  final List<String> _priorities = ['All', 'High', 'Medium', 'Low'];
  final List<String> _statuses = ['All', 'Pending', 'Completed', 'Missed'];
  final List<String> _repeats = ['All', ...TaskRepeatMapper.uiOptions];

  @override
  void initState() {
    super.initState();
    _priority = widget.currentPriority;
    _status = widget.currentStatus;
    _repeat = widget.currentRepeat == 'All'
        ? 'All'
        : TaskRepeatMapper.toUi(widget.currentRepeat);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priority = 'All';
                    _status = 'All';
                    _repeat = 'All';
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Priority Section
          Text(
            'Priority',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _priorities.map((p) {
              final isSelected = _priority == p;
              return ChoiceChip(
                label: Text(p),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _priority = p);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Status Section
          Text(
            'Status',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _statuses.map((s) {
              final isSelected = _status == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _status = s);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Repeat Section
          Text(
            'Repeat',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _repeats.map((r) {
              final isSelected = _repeat == r;
              return ChoiceChip(
                label: Text(r),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _repeat = r);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApplyFilters(
                  priority: _priority,
                  status: _status,
                  repeat: _repeat == 'All' ? 'All' : TaskRepeatMapper.toDb(_repeat),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
