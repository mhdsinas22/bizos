import 'dart:typed_data';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_state.dart';
import 'package:bizos/features/personal_expense/presentation/utils/personal_expense_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class ExportPersonalExpensePdfModal extends StatefulWidget {
  const ExportPersonalExpensePdfModal({super.key});

  @override
  State<ExportPersonalExpensePdfModal> createState() =>
      _ExportPersonalExpensePdfModalState();
}

class _ExportPersonalExpensePdfModalState
    extends State<ExportPersonalExpensePdfModal> {
  String _selectedFilterKey = 'this_month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isGenerating = false;

  final Map<String, String> _filterLabels = {
    'today': 'Today',
    'yesterday': 'Yesterday',
    'this_week': 'This Week',
    'last_week': 'Last Week',
    'this_month': 'This Month',
    'last_month': 'Last Month',
    'this_year': 'This Year',
    'custom': 'Custom Date Range',
  };

  (DateTime start, DateTime end) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilterKey) {
      case 'today':
        return (today, DateTime(now.year, now.month, now.day, 23, 59, 59));
      case 'yesterday':
        final y = today.subtract(const Duration(days: 1));
        return (y, DateTime(y.year, y.month, y.day, 23, 59, 59));
      case 'this_week':
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, DateTime(now.year, now.month, now.day, 23, 59, 59));
      case 'last_week':
        final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
        final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
        final lastWeekEnd = thisWeekStart.subtract(const Duration(seconds: 1));
        return (lastWeekStart, lastWeekEnd);
      case 'this_month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start, end);
      case 'last_month':
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (start, end);
      case 'this_year':
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return (start, end);
      case 'custom':
        final s = _customStartDate ?? DateTime(now.year, now.month, 1);
        final e = _customEndDate ?? now;
        return (
          DateTime(s.year, s.month, s.day),
          DateTime(e.year, e.month, e.day, 23, 59, 59)
        );
      default:
        return (DateTime(now.year, now.month, 1), now);
    }
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _customStartDate = range.start;
        _customEndDate = range.end;
        _selectedFilterKey = 'custom';
      });
    }
  }

  List<PersonalExpenseEntity> _filterExpenses(
    List<PersonalExpenseEntity> allExpenses,
    DateTime start,
    DateTime end,
  ) {
    return allExpenses.where((e) {
      return e.expenseDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.expenseDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Future<Uint8List?> _generatePdf(List<PersonalExpenseEntity> allExpenses) async {
    final (start, end) = _getDateRange();
    final filtered = _filterExpenses(allExpenses, start, end);
    final authState = context.read<AuthBloc>().state;
    final userName = authState.user?.name ?? 'Personal User';
    final filterLabel = _filterLabels[_selectedFilterKey] ?? 'Expense Report';
    final dateRangeStr =
        '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';

    return await PersonalExpensePdfGenerator.generatePdfReport(
      filteredExpenses: filtered,
      allExpenses: allExpenses,
      filterTitle: '$filterLabel ($dateRangeStr)',
      startDate: start,
      endDate: end,
      userName: userName,
    );
  }

  Future<void> _handleAction(
    String action,
    List<PersonalExpenseEntity> allExpenses,
  ) async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final pdfBytes = await _generatePdf(allExpenses);
      if (pdfBytes == null) return;

      if (!mounted) return;

      if (action == 'preview') {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'Personal_Expense_Report.pdf',
        );
      } else if (action == 'share') {
        await PersonalExpensePdfGenerator.sharePdf(
          pdfBytes,
          'Personal_Expense_Report.pdf',
        );
      } else if (action == 'print') {
        await PersonalExpensePdfGenerator.printPdf(pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: BlocBuilder<PersonalExpenseBloc, PersonalExpenseState>(
        builder: (context, state) {
          List<PersonalExpenseEntity> allExpenses = [];
          if (state is PersonalExpenseLoaded) {
            allExpenses = state.expenses;
          }

          final (start, end) = _getDateRange();
          final filtered = _filterExpenses(allExpenses, start, end);
          final double periodTotal = filtered.fold(
            0.0,
            (sum, e) => sum + e.amount,
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Export Expense PDF',
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

              // Filter Chips / Selection
              Text(
                'Select Date Range Filter',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filterLabels.entries.map((entry) {
                  final key = entry.key;
                  final label = entry.value;
                  final isSelected = _selectedFilterKey == key;

                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (key == 'custom') {
                        _pickCustomRange();
                      } else {
                        setState(() {
                          _selectedFilterKey = key;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Report Summary Box Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtered Period Total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${filtered.length} Transactions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(periodTotal),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_isGenerating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Generating PDF report...'),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _handleAction('preview', allExpenses),
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text('Preview PDF Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Share PDF',
                            icon: Icons.share,
                            isSecondary: true,
                            onPressed: () =>
                                _handleAction('share', allExpenses),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Print A4 PDF',
                            icon: Icons.print,
                            isSecondary: true,
                            onPressed: () =>
                                _handleAction('print', allExpenses),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
