import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/presentation/tabs/expense_tab.dart';
import 'package:bizos/features/business/presentation/tabs/income_tab.dart';
import 'package:bizos/features/business/presentation/tabs/over_view_tab.dart';
import 'package:bizos/features/business/presentation/tabs/profit_loss_tab.dart';
import 'package:bizos/features/business/presentation/tabs/staff_tab.dart';
import 'package:bizos/features/business/presentation/tabs/to_do_tab.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/pages/money_management_dashboard.dart';

class BusinessDetailScreen extends StatefulWidget {
  final BusinessModel business;
  final String bussinessids;
  const BusinessDetailScreen({
    super.key,
    required this.business,
    required this.bussinessids,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // Trigger initial load for task and finance blocs for this business
    context.read<TaskBloc>().add(FetchTasksEvent(widget.business.id));
    context.read<FinanceBloc>().add(FetchFinanceDataEvent(widget.business.id));
    context.read<BusinessMoneyManagementBloc>().add(WatchTransactionsEvent(businessId: widget.business.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      'Building business detail screen for business: ${widget.business.id}',
    );
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();
    final user = authState.user;

    final isAssigned = user.isOwner || user.businessPermissions.containsKey(widget.business.id);
    if (!isAssigned) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.business.name),
        ),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Access Restricted',
          message: 'Your Staff account does not have access to this business.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'biz-${widget.business.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              widget.business.name,
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            const Tab(text: 'Overview'),
            const Tab(text: 'ToDo Tasks'),
            const Tab(text: 'Income'),
            const Tab(text: 'Expenses'),
            const Tab(text: 'P&L Reports'),
            Tab(text: user.isOwner ? 'Staff Mgmt' : 'Staff Overview'),
            const Tab(text: 'Money Mgmt'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(
            business: widget.business,
            user: user,
            businessid: widget.bussinessids,
          ),
          ToDoTab(
            businessId: widget.business.id,
            user: user,
            business: widget.business,
          ),
          IncomeTab(businessId: widget.business.id, user: user),
          ExpenseTab(businessId: widget.business.id, user: user),
          ProfitAndLossTab(businessId: widget.business.id, user: user),
          StaffTab(user: user, businessId: widget.business.id),
          MoneyManagementDashboard(businessId: widget.business.id),
        ],
      ),
    );
  }
}
