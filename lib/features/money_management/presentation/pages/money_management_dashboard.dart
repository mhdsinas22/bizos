import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_state.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/pages/transaction_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MoneyManagementDashboard extends StatelessWidget {
  final String? businessId; // null for personal

  const MoneyManagementDashboard({super.key, this.businessId});

  Widget _buildContent(BuildContext context, MoneyManagementState state) {
    if (state is TransactionsLoading || state is TransactionsInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TransactionsError) {
      return Center(child: Text('Error loading dashboard: ${state.message}'));
    }

    if (state is TransactionsLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          // Realtime automatically handles refreshing, but standard ERP pull-to-refresh marks it as interactive.
          (context as Element).markNeedsBuild();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildMetricCard(
                context: context,
                title: 'Money to Pay',
                amount: state.totalPendingPay,
                recordsCount: state.pendingPayCount,
                icon: Icons.outbox_outlined,
                color: AppTheme.error,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionListPage(
                      transactionType: 'pay',
                      businessId: businessId,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildMetricCard(
                context: context,
                title: 'Money to Receive',
                amount: state.totalPendingReceive,
                recordsCount: state.pendingReceiveCount,
                icon: Icons.inbox_outlined,
                color: AppTheme.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionListPage(
                      transactionType: 'receive',
                      businessId: businessId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required double amount,
    required int recordsCount,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24.0),
      color: color.withOpacity(0.06),
      border: BorderSide(color: color.withOpacity(0.18), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$recordsCount Pending Records',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (businessId != null) {
      return BlocBuilder<BusinessMoneyManagementBloc, MoneyManagementState>(
        builder: (context, state) => _buildContent(context, state),
      );
    } else {
      return BlocBuilder<PersonalMoneyManagementBloc, MoneyManagementState>(
        builder: (context, state) => _buildContent(context, state),
      );
    }
  }
}
