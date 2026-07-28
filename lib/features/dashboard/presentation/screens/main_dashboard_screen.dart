import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/dashboard/presentation/widgets/income_expense_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/core/widgets/error_state.dart';
import 'package:bizos/core/widgets/voryn_bottom_nav_bar.dart';
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
import 'package:bizos/features/activity/domain/entities/activity_entity.dart';
import 'package:bizos/features/activity/presentation/widgets/activity_card.dart';
import 'package:bizos/features/activity/presentation/pages/activity_history_page.dart';

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
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Define tabs based on role
    final List<Widget> pages = [
      DashboardView(user: user),
      const BusinessListScreen(),
      user.isOwner ? const OwnerTaskDashboardScreen() : const StaffTaskScreen(),
      if (user.isOwner) const StaffListView(),
      const ReportsScreen(),
      if (user.isOwner) const PersonalParentScreen(),
    ];

    final navDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: Text('Business'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: Text('Tasks'),
      ),
      if (user.isOwner)
        const NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Staff'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('Reports'),
      ),
      if (user.isOwner)
        const NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text('Personal'),
        ),
    ];

    Widget bodyContent = IndexedStack(
      index: _currentIndex,
      children: pages,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voryn ERP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  user.isOwner
                      ? 'Owner Console'
                      : '${user.name} (${user.role})',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AiChatScreen()));
            },
            tooltip: 'Voryn AI Assistant',
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
            icon: const Icon(Icons.account_circle_outlined, size: 22),
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
                    const SizedBox(width: 10),
                    const Text(
                      'Change Password',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppTheme.error),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isMobile
          ? bodyContent
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  extended: isDesktop,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: isDesktop
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  destinations: navDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: bodyContent),
              ],
            ),
      bottomNavigationBar: isMobile
          ? VorynBottomNavBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: [
                const VorynNavDestination(
                  label: 'Dashboard',
                  icon: Icons.grid_view_outlined,
                  selectedIcon: Icons.grid_view_rounded,
                ),
                const VorynNavDestination(
                  label: 'Business',
                  icon: Icons.storefront_outlined,
                  selectedIcon: Icons.storefront_rounded,
                ),
                const VorynNavDestination(
                  label: 'Tasks',
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment_rounded,
                ),
                if (user.isOwner)
                  const VorynNavDestination(
                    label: 'Staff',
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                  ),
                const VorynNavDestination(
                  label: 'Reports',
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics_rounded,
                ),
                if (user.isOwner)
                  const VorynNavDestination(
                    label: 'Personal',
                    icon: Icons.account_balance_wallet_outlined,
                    selectedIcon: Icons.account_balance_wallet_rounded,
                  ),
              ],
            )
          : null,
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
    // Fetch repository values directly for overall stats dashboard
    final dashboardRepo = context.read<DashboardRepository>();
    final businessRepo = context.read<BusinessRepository>();

    final dashboardFuture = dashboardRepo.getDashboardData(null, user.id);
    final businessesFuture = businessRepo.getBusinesses(user.userId);

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

        final gridCount = ResponsiveBreakpoints.getGridColumnCount(
          context,
          mobile: 2,
          tablet: 3,
          desktop: 5,
        );

        return RefreshIndicator(
          onRefresh: () async {
            (context as Element).markNeedsBuild();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: ResponsiveCenterBody(
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
                    crossAxisCount: gridCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
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
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActivityHistoryPage(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!user.hasPermission('view_accounts'))
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
                      itemCount: recentActivities.length > 5
                          ? 5
                          : recentActivities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final actMap = recentActivities[index];
                        final act = ActivityEntity(
                          id: actMap['id']?.toString() ?? '',
                          businessId: actMap['business_id']?.toString(),
                          title: actMap['title']?.toString() ?? '',
                          description:
                              actMap['description']?.toString() ??
                              actMap['subtitle']?.toString() ??
                              '',
                          createdBy:
                              actMap['created_by']?.toString() ?? 'system',
                          createdAt: actMap['date'] is DateTime
                              ? actMap['date'] as DateTime
                              : DateTime.tryParse(
                                      actMap['date']?.toString() ?? '',
                                    ) ??
                                    DateTime.now(),
                          module:
                              actMap['module']?.toString() ??
                              actMap['type']?.toString() ??
                              'Business',
                          action: actMap['action']?.toString() ?? '',
                        );

                        String? bName;
                        if (act.businessId != null && businesses.isNotEmpty) {
                          try {
                            final b = (businesses).firstWhere(
                              (biz) => biz.id == act.businessId,
                              orElse: () => null,
                            );
                            if (b != null) {
                              bName = b.name;
                            }
                          } catch (_) {}
                        }

                        return ActivityCard(activity: act, businessName: bName);
                      },
                    ),
                ],
              ),
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
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
