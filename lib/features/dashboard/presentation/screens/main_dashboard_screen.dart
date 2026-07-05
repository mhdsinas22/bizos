import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/dashboard/presentation/widgets/income_expense_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';
import 'package:bizos/features/dashboard/domain/repo/dashboard_repository.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/auth/presentation/screens/change_password_screen.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/business/presentation/screen/business_list_screen.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/reports/presentation/screens/reports_screen.dart';
import 'package:bizos/features/staff/presentation/screens/staff_list_view.dart';
import 'package:bizos/features/task/presentation/screens/owner_task_dashboard_screen.dart';
import 'package:bizos/features/task/presentation/screens/staff_task_screen.dart';
import 'package:bizos/features/personal_expense/presentation/pages/personal_parent_screen.dart';
import 'package:bizos/features/ai/presentation/screens/ai_chat_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState.user == null) {
      return const LoginScreen();
    }

    final user = authState.user!;

    // Define tabs based on role
    final List<Widget> pages = [
      DashboardView(user: user),
      const BusinessListScreen(),
      user.isOwner ? const OwnerTaskDashboardScreen() : const StaffTaskScreen(),
      if (user.isOwner) const StaffListView(),
      const ReportsScreen(),
      if (user.isOwner) const PersonalParentScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.business_center,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voryn ERP',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  user.isOwner
                      ? 'Owner Console'
                      : '${user.name} (${user.role})',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          // IconButton(
          //   icon: Icon(
          //     Theme.of(context).brightness == Brightness.dark
          //         ? Icons.light_mode_outlined
          //         : Icons.dark_mode_outlined,
          //   ),
          //   onPressed: () {
          //     context.read<ThemeBloc>().add(ToggleThemeEvent());
          //   },
          //   tooltip: 'Toggle Theme',
          // ),
          IconButton(
            icon: const Icon(Icons.psychology, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AiChatScreen()));
            },
            tooltip: 'Voryn AI Assistant',
          ),
          // User Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'password') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                context.read<AuthBloc>().add(LogoutEvent());
              }
            },
            icon: const Icon(Icons.account_circle_outlined),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'password',
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      size: 18,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    const Text('Change Password'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkBorder
                  : AppTheme.lightBorder,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Businesses',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Tasks',
            ),
            if (user.isOwner)
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Staff',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Reports',
            ),
            if (user.isOwner)
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Personal',
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------- DASHBOARD VIEW TAB -----------------
class DashboardView extends StatelessWidget {
  final UserModel user;
  const DashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    // Fetch repository values directly for overall stats dashboard
    final dashboardRepo = context.read<DashboardRepository>();
    final businessRepo = context.read<BusinessRepository>();

    final dashboardFuture = dashboardRepo.getDashboardData(null, user.id);
    final businessesFuture = businessRepo.getBusinesses(user.userId);

    return FutureBuilder(
      future: Future.wait([dashboardFuture, businessesFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading dashboard: ${snapshot.error}'),
          );
        }

        final dashboardData = snapshot.data?[0] as DashboardData;
        final businesses = snapshot.data?[1] as List<dynamic>? ?? [];

        final double totalIncome = user.hasPermission('view_accounts')
            ? dashboardData.totalIncome
            : 0.0;
        final double totalExpenses = user.hasPermission('view_accounts')
            ? dashboardData.totalExpense
            : 0.0;
        final double totalProfit = totalIncome - totalExpenses;
        final int pendingTasks = dashboardData.pendingTasks;
        final recentActivities = dashboardData.recentActivities;
        final monthlySummary = dashboardData.monthlySummary;

        return RefreshIndicator(
          onRefresh: () async {
            (context as Element).markNeedsBuild();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Text(
                  'Welcome back, ${user.name}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user.isOwner
                      ? 'Overall statistics across all entities.'
                      : 'Enterprise management console.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Metrics Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: isTablet ? 5 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isTablet ? 1.3 : 1.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Businesses',
                      value: '${businesses.length}',
                      icon: Icons.storefront,
                      color: AppTheme.info,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Income',
                      value: user.hasPermission('view_accounts')
                          ? CurrencyFormatter.format(totalIncome)
                          : '••••',
                      icon: Icons.arrow_upward,
                      color: AppTheme.success,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Expenses',
                      value: user.hasPermission('view_accounts')
                          ? CurrencyFormatter.format(totalExpenses)
                          : '••••',
                      icon: Icons.arrow_downward,
                      color: AppTheme.error,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Net Profit',
                      value: user.hasPermission('view_accounts')
                          ? CurrencyFormatter.format(totalProfit)
                          : '••••',
                      icon: Icons.monetization_on,
                      color: totalProfit >= 0
                          ? AppTheme.primaryColor
                          : AppTheme.error,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Pending Tasks',
                      value: '$pendingTasks',
                      icon: Icons.assignment_late_outlined,
                      color: AppTheme.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart & Summary split
                if (user.hasPermission('view_accounts') &&
                    monthlySummary.isNotEmpty) ...[
                  Text(
                    'Income vs Expense Flow',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: SizedBox(
                      height: 260,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 16.0,
                          right: 16.0,
                          left: 8.0,
                        ),
                        child: IncomeExpenseChart(
                          monthlySummary: monthlySummary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recent Activities Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activities',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (recentActivities.isNotEmpty)
                      Text(
                        'Last 15 records',
                        style: theme.textTheme.labelLarge,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!user.hasPermission('can_view_accounts'))
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 36,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Financial Access Restricted',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your Staff account does not have View Accounts permissions.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (recentActivities.isEmpty)
                  const GlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('No recent activities logged yet.'),
                    ),
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
                      final formattedAmt = CurrencyFormatter.format(amt.abs());

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
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
                        leading: CircleAvatar(
                          backgroundColor: isIncome
                              ? AppTheme.success.withOpacity(0.1)
                              : AppTheme.error.withOpacity(0.1),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isIncome ? AppTheme.success : AppTheme.error,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          act['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${act['subtitle']}\n${DateFormat.yMMMd().add_jm().format(date)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '${isIncome ? '+' : '-'}$formattedAmt',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? AppTheme.success : AppTheme.error,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 11),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
