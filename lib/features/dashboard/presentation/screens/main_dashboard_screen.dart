import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/voryn_bottom_nav_bar.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/business/presentation/screen/business_list_screen.dart';
import 'package:bizos/features/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:bizos/features/dashboard/presentation/widgets/dashboard_view.dart';
import 'package:bizos/features/personal_expense/presentation/pages/personal_parent_screen.dart';
import 'package:bizos/features/reports/presentation/screens/reports_screen.dart';
import 'package:bizos/features/staff/presentation/screens/staff_list_view.dart';
import 'package:bizos/features/task/presentation/screens/owner_task_dashboard_screen.dart';
import 'package:bizos/features/task/presentation/screens/staff_task_screen.dart';

/// The root dashboard scaffold for Voryn ERP.
/// Manages top-level navigation, platform-aware bottom navigation,
/// desktop navigation rail, and displays all 6 role-based destinations:
/// 1. Dashboard
/// 2. Business
/// 3. Tasks
/// 4. Staff
/// 5. Reports
/// 6. Personal
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

    // Navigation destinations based on role
    final List<Widget> pages = [
      DashboardView(
        user: user,
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const BusinessListScreen(),
      user.isOwner ? const OwnerTaskDashboardScreen() : const StaffTaskScreen(),
      if (user.isOwner) const StaffListView(),
      const ReportsScreen(),
      if (user.isOwner) const PersonalParentScreen(),
    ];

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    final navDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: Text('Business'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment_rounded),
        label: Text('Tasks'),
      ),
      if (user.isOwner)
        const NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Staff'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.bar_chart_rounded),
        selectedIcon: Icon(Icons.bar_chart),
        label: Text('Reports'),
      ),
      if (user.isOwner)
        const NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: Text('Personal'),
        ),
    ];

    final bottomNavDestinations = [
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
        icon: Icons.bar_chart_rounded,
        selectedIcon: Icons.bar_chart,
      ),
      if (user.isOwner)
        const VorynNavDestination(
          label: 'Personal',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
        ),
    ];

    final Widget bodyContent = IndexedStack(
      index: safeIndex,
      children: pages,
    );

    return Scaffold(
      appBar: DashboardAppBar(user: user),
      body: isMobile
          ? bodyContent
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: safeIndex,
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
              selectedIndex: safeIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: bottomNavDestinations,
            )
          : null,
    );
  }
}
