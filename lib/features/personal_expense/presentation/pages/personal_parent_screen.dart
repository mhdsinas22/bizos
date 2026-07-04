import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/pages/personal_expense_page.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/pages/money_management_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalParentScreen extends StatefulWidget {
  const PersonalParentScreen({super.key});

  @override
  State<PersonalParentScreen> createState() => _PersonalParentScreenState();
}

class _PersonalParentScreenState extends State<PersonalParentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<PersonalMoneyManagementBloc>().add(
              WatchTransactionsEvent(userId: userId),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const TabBar(
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Expenses'),
                Tab(text: 'Money Mgmt'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                PersonalExpensePage(),
                MoneyManagementDashboard(businessId: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
