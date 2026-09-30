import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/error_state.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/dashboard/domain/repo/dashboard_repository.dart';
import 'package:bizos/features/dashboard/presentation/widgets/dashboard_hero_card.dart';
import 'package:bizos/features/dashboard/presentation/widgets/financial_chart_card.dart';
import 'package:bizos/features/dashboard/presentation/widgets/overall_performance_section.dart';
import 'package:bizos/features/dashboard/presentation/widgets/pending_tasks_card.dart';
import 'package:bizos/features/dashboard/presentation/widgets/this_month_section.dart';

/// The primary content view for the Dashboard tab.
/// Fetches real Supabase metrics and renders:
/// 1. Welcome Hero
/// 2. This Month Section
/// 3. Overall Performance Section
/// 4. Income vs Expense Flow
/// 5. Pending Tasks Summary
class DashboardView extends StatelessWidget {
  final UserModel user;
  final ValueChanged<int>? onNavigateToTab;

  const DashboardView({
    super.key,
    required this.user,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final dashboardRepo = context.read<DashboardRepository>();
    final businessRepo = context.read<BusinessRepository>();

    final dashboardFuture = dashboardRepo.getDashboardData(null, user.id);
    final businessesFuture = businessRepo.getBusinesses(user.userId);

    final hasFinancialAccess = user.hasPermission('view_accounts');

    return FutureBuilder(
      future: Future.wait([dashboardFuture, businessesFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: SkeletonListLoader(itemCount: 4, itemHeight: 90),
          );
        }
        if (snapshot.hasError) {
          return ErrorStateWidget(
            title: 'Failed to Load Dashboard',
            message: '${snapshot.error}',
            onRetry: () {
              (context as Element).markNeedsBuild();
            },
          );
        }

        final dashboardData = snapshot.data?[0] as DashboardData;

        final double totalIncome = hasFinancialAccess
            ? dashboardData.totalIncome
            : 0.0;
        final double totalExpenses = hasFinancialAccess
            ? dashboardData.totalExpense
            : 0.0;
        final double totalProfit = totalIncome - totalExpenses;
        final int pendingTasks = dashboardData.pendingTasks;
        final monthlySummary = dashboardData.monthlySummary;

        return RefreshIndicator(
          onRefresh: () async {
            (context as Element).markNeedsBuild();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            child: ResponsiveCenterBody(
              maxWidth: 1200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Welcome / Hero Section
                  DashboardHeroCard(userName: user.name),
                  const SizedBox(height: 22),

                  // B. This Month Section
                  ThisMonthSection(
                    monthlySummary: monthlySummary,
                    hasFinancialAccess: hasFinancialAccess,
                  ),
                  const SizedBox(height: 22),

                  // C. Overall Performance Section
                  OverallPerformanceSection(
                    totalIncome: totalIncome,
                    totalExpenses: totalExpenses,
                    totalProfit: totalProfit,
                    hasFinancialAccess: hasFinancialAccess,
                    // Navigate to Reports tab (index 4 for owner, index 3 for non-owner)
                    onTapIncome: () =>
                        onNavigateToTab?.call(user.isOwner ? 4 : 3),
                    onTapExpense: () =>
                        onNavigateToTab?.call(user.isOwner ? 4 : 3),
                    onTapProfit: () =>
                        onNavigateToTab?.call(user.isOwner ? 4 : 3),
                  ),
                  const SizedBox(height: 22),

                  // D. Income vs Expense Flow
                  if (hasFinancialAccess) ...[
                    FinancialChartCard(monthlySummary: monthlySummary),
                    const SizedBox(height: 20),
                  ] else ...[
                    const DashboardRestrictedAccessCard(),
                    const SizedBox(height: 20),
                  ],

                  // E. Pending Tasks Summary
                  PendingTasksCard(
                    pendingTasks: pendingTasks,
                    // Navigate to Tasks tab (index 2)
                    onTap: () => onNavigateToTab?.call(2),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fallback card shown when a user lacks financial access permissions.
class DashboardRestrictedAccessCard extends StatelessWidget {
  const DashboardRestrictedAccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101524) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 38,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 10),
            Text(
              'Financial Access Restricted',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Staff account does not have View Accounts permissions.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
