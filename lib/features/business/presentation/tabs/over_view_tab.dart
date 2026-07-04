import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/dashboard/domain/repo/dashboard_repository.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';
import 'package:bizos/features/task/presentation/bloc/task_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_state.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/core/utils/currency_formatter.dart';

class OverviewTab extends StatelessWidget {
  final BusinessModel business;
  final String businessid;
  final UserModel user;

  const OverviewTab({
    super.key,
    required this.business,
    required this.user,
    required this.businessid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardRepo = context.read<DashboardRepository>();

    return FutureBuilder<DashboardData>(
      future: dashboardRepo.getSpecificBusinessData(businessid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading overview: ${snapshot.error}'),
          );
        }

        final dashboardData = snapshot.data!;

        final double totalIncome =
            user.hasPermission('view_accounts', businessId: business.id)
            ? dashboardData.totalIncome
            : 0.0;
        final double totalExpense =
            user.hasPermission('view_accounts', businessId: business.id)
            ? dashboardData.totalExpense
            : 0.0;
        final double profit = totalIncome - totalExpense;
        final recentActivities = dashboardData.recentActivities;

        return BlocBuilder<TaskBloc, TaskState>(
          builder: (context, taskState) {
            int pending = 0;
            int completed = 0;
            double completionPercent = 0.0;

            if (taskState is TaskLoaded) {
              completed = taskState.tasks.where((t) => t.isCompleted).length;
              pending = taskState.tasks.length - completed;
              final total = taskState.tasks.length;
              if (total > 0) {
                completionPercent = completed / total;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),

                            Text(
                              'Business Profile',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Industry Type: ${business.type}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('Phone: ${business.phone}'),
                        Text('Address: ${business.address}'),
                        if (business.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Notes: ${business.notes}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Responsive cards
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tasks Progress Card
                      Expanded(
                        flex: 1,
                        child: GlassCard(
                          child: Column(
                            children: [
                              const Text(
                                'Task Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 70,
                                width: 70,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: completionPercent,
                                      strokeWidth: 8,
                                      backgroundColor:
                                          theme.brightness == Brightness.dark
                                          ? AppTheme.darkBorder
                                          : AppTheme.lightBorder,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            AppTheme.primaryColor,
                                          ),
                                    ),
                                    Center(
                                      child: Text(
                                        '${(completionPercent * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '$completed Completed | $pending Pending',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Quick Financial Overview Card
                      Expanded(
                        flex: 1,
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Quick Net Balance',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  user.hasPermission('view_accounts')
                                      ? CurrencyFormatter.format(
                                          profit,
                                        )
                                      : '••••',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color:
                                            !user.hasPermission('view_accounts')
                                            ? null
                                            : profit >= 0
                                            ? AppTheme.success
                                            : AppTheme.error,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.hasPermission('view_accounts')
                                    ? 'Inflow: ${CurrencyFormatter.format(totalIncome, decimalDigits: 0)}'
                                    : 'Inflow: restricted',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  BlocBuilder<BusinessMoneyManagementBloc, MoneyManagementState>(
                    builder: (context, mmState) {
                      double pendingPay = 0.0;
                      double pendingReceive = 0.0;
                      if (mmState is TransactionsLoaded) {
                        pendingPay = mmState.totalPendingPay;
                        pendingReceive = mmState.totalPendingReceive;
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              color: AppTheme.error.withOpacity(0.06),
                              border: BorderSide(color: AppTheme.error.withOpacity(0.18), width: 1.5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Money to Pay',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      CurrencyFormatter.format(pendingPay),
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: AppTheme.error,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GlassCard(
                              color: AppTheme.success.withOpacity(0.06),
                              border: BorderSide(color: AppTheme.success.withOpacity(0.18), width: 1.5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Money to Receive',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      CurrencyFormatter.format(pendingReceive),
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Recent Activities specific to business
                  Text(
                    'Recent Activities',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!user.hasPermission('view_accounts'))
                    const GlassCard(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Financial activities restricted for Staff.',
                        ),
                      ),
                    )
                  else if (recentActivities.isEmpty)
                    const GlassCard(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No activities logged yet.')),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentActivities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final act = recentActivities[index];
                        final isIncome = act['type'] == 'income';
                        final amt = act['amount'] as double;
                        final date = act['date'] as DateTime;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                            ),
                          ),
                          tileColor: theme.cardColor,
                          leading: Icon(
                            isIncome
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isIncome ? AppTheme.success : AppTheme.error,
                            size: 16,
                          ),
                          title: Text(
                            act['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${act['subtitle']} • ${DateFormat.yMMMd().format(date)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${CurrencyFormatter.format(amt.abs())}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncome
                                  ? AppTheme.success
                                  : AppTheme.error,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
