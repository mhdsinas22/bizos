import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:bizos/features/finance/presentation/widgets/date_filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProfitAndLossTab extends StatefulWidget {
  final String businessId;
  final UserModel user;
  final bool showAppBar;

  const ProfitAndLossTab({
    super.key,
    required this.businessId,
    required this.user,
    this.showAppBar = true,
  });

  @override
  State<ProfitAndLossTab> createState() => _ProfitAndLossTabState();
}

class _ProfitAndLossTabState extends State<ProfitAndLossTab> {
  DateFilterOption _activeFilterOption = DateFilterOption.allTime;
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterLabel = 'All Time';

  void _openDateFilterSheet() async {
    final result = await showModalBottomSheet<DateFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DateFilterBottomSheet(
        initialOption: _activeFilterOption,
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _activeFilterOption = result.selectedOption;
        _startDate = result.startDate;
        _endDate = result.endDate;
        _filterLabel = result.label;
      });

      context.read<FinanceBloc>().add(
        FetchFinanceDataEvent(
          widget.businessId,
          startDate: result.startDate,
          endDate: result.endDate,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFilterActive = _activeFilterOption != DateFilterOption.allTime;
    final hasFinanceAccess = widget.user.hasPermission(
      'view_accounts',
      businessId: widget.businessId,
    );

    if (!hasFinanceAccess) {
      const emptyWidget = EmptyState(
        icon: Icons.lock_outline,
        title: 'Access Restricted',
        message: 'Your Staff account does not have access to P&L summaries.',
      );
      return widget.showAppBar
          ? Scaffold(
              appBar: AppBar(title: const Text('P&L Reports')),
              body: emptyWidget,
            )
          : emptyWidget;
    }

    final content = BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        if (state is FinanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FinanceLoaded) {
          final double inc = state.incomeList.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );
          final double exp = state.expenseList.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );
          final double profit = inc - exp;

          final summaryMap = <String, Map<String, double>>{};
          for (var i in state.incomeList) {
            final key =
                '${i.date.year}-${i.date.month.toString().padLeft(2, '0')}';
            summaryMap.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
            summaryMap[key]!['income'] = summaryMap[key]!['income']! + i.amount;
          }
          for (var e in state.expenseList) {
            final key =
                '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
            summaryMap.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
            summaryMap[key]!['expense'] =
                summaryMap[key]!['expense']! + e.amount;
          }
          final sortedKeys = summaryMap.keys.toList()..sort();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profit & Loss Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: _openDateFilterSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isFilterActive
                              ? theme.primaryColor
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFilterActive
                                ? theme.primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 18,
                              color: isFilterActive
                                  ? Colors.white
                                  : theme.iconTheme.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isFilterActive ? _filterLabel : 'Filter Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isFilterActive
                                    ? Colors.white
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isFilterActive) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        avatar: const Icon(Icons.calendar_today, size: 14),
                        label: Text('Filter: $_filterLabel'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() {
                            _activeFilterOption = DateFilterOption.allTime;
                            _startDate = null;
                            _endDate = null;
                            _filterLabel = 'All Time';
                          });
                          context.read<FinanceBloc>().add(
                            FetchFinanceDataEvent(widget.businessId),
                          );
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Net Card
                GlassCard(
                  child: Column(
                    children: [
                      Text(
                        isFilterActive
                            ? 'Profit ($_filterLabel)'
                            : 'Cumulative Profit',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(profit),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: profit >= 0
                              ? AppTheme.success
                              : AppTheme.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Total Revenue',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                CurrencyFormatter.format(inc),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Total Cost',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                CurrencyFormatter.format(exp),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.error,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Monthly Progression Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (sortedKeys.isEmpty)
                  const GlassCard(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No income/expense records match the selected criteria.',
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedKeys.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final key = sortedKeys[index];
                      final mIncome = summaryMap[key]?['income'] ?? 0.0;
                      final mExpense = summaryMap[key]?['expense'] ?? 0.0;
                      final mProfit = mIncome - mExpense;

                      final parts = key.split('-');
                      final monthName = DateFormat('MMMM yyyy').format(
                        DateTime(int.parse(parts[0]), int.parse(parts[1])),
                      );

                      return GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_upward,
                                      color: AppTheme.success,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'In: ${CurrencyFormatter.format(mIncome, decimalDigits: 0)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_downward,
                                      color: AppTheme.error,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Out: ${CurrencyFormatter.format(mExpense, decimalDigits: 0)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on,
                                      color: AppTheme.primaryColor,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Net: ${CurrencyFormatter.format(mProfit, decimalDigits: 0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: mProfit >= 0
                                            ? AppTheme.success
                                            : AppTheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );

    return widget.showAppBar
        ? Scaffold(
            appBar: AppBar(title: const Text('P&L Reports')),
            body: content,
          )
        : content;
  }
}
