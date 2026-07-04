import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/utils/currency_formatter.dart';

class ProfitAndLossTab extends StatelessWidget {
  final String businessId;
  final UserModel user;

  const ProfitAndLossTab({
    super.key,
    required this.businessId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFinanceAccess = user.hasPermission(
      'view_accounts',
      businessId: businessId,
    );

    if (!hasFinanceAccess) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Access Restricted',
        message: 'Your Staff account does not have access to P&L summaries.',
      );
    }

    return BlocBuilder<FinanceBloc, FinanceState>(
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
                Text(
                  'Profit & Loss Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Net Card
                GlassCard(
                  child: Column(
                    children: [
                      const Text(
                        'Cumulative Profit',
                        style: TextStyle(
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
                        'Add income/expenses to see monthly calculations.',
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
  }
}
