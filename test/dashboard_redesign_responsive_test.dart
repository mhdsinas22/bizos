import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/voryn_bottom_nav_bar.dart';
import 'package:bizos/features/dashboard/presentation/widgets/dashboard_hero_card.dart';
import 'package:bizos/features/dashboard/presentation/widgets/this_month_section.dart';
import 'package:bizos/features/dashboard/presentation/widgets/overall_performance_section.dart';
import 'package:bizos/features/dashboard/presentation/widgets/financial_chart_card.dart';
import 'package:bizos/features/dashboard/presentation/widgets/pending_tasks_card.dart';

void main() {
  final sampleMonthlySummary = {
    '2026-04': {'income': 10000.0, 'expense': 2000.0},
    '2026-05': {'income': 12000.0, 'expense': 2500.0},
    '2026-06': {'income': 11500.0, 'expense': 2200.0},
    '2026-07': {'income': 18000.0, 'expense': 3800.0},
    '2026-08': {'income': 22000.0, 'expense': 4500.0},
    '2026-09': {'income': 46100.0, 'expense': 550.0},
  };

  Widget buildTestableWidget({
    required Widget child,
    required Size screenSize,
    ThemeData? theme,
    TargetPlatform platform = TargetPlatform.iOS,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      themeAnimationDuration: Duration.zero,
      home: Theme(
        data: (theme ?? AppTheme.lightTheme).copyWith(platform: platform),
        child: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            padding: const EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('Dashboard UI Redesign Components', () {
    testWidgets('DashboardHeroCard renders properly in light and dark mode',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          child: const DashboardHeroCard(userName: 'sinas'),
        ),
      );

      expect(find.text('Welcome back, sinas'), findsOneWidget);
      expect(
        find.text('Here’s your business performance overview.'),
        findsOneWidget,
      );

      // Dark mode
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          theme: AppTheme.darkTheme,
          child: const DashboardHeroCard(userName: 'sinas'),
        ),
      );

      expect(find.text('Welcome back, sinas'), findsOneWidget);
    });

    testWidgets('ThisMonthSection renders financial cards and month selector',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          child: SingleChildScrollView(
            child: ThisMonthSection(
              monthlySummary: sampleMonthlySummary,
              hasFinancialAccess: true,
            ),
          ),
        ),
      );

      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('This Month\nIncome'), findsOneWidget);
      expect(find.text('This Month\nExpense'), findsOneWidget);
      expect(find.text('This Month\nProfit'), findsOneWidget);
      expect(find.text('vs last month'), findsWidgets);
    });

    testWidgets('OverallPerformanceSection renders 3 cards with real amounts',
        (tester) async {
      bool incomeTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          child: SingleChildScrollView(
            child: OverallPerformanceSection(
              totalIncome: 46100.0,
              totalExpenses: 550.0,
              totalProfit: 45550.0,
              hasFinancialAccess: true,
              onTapIncome: () => incomeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Overall Performance'), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('Net Profit'), findsOneWidget);

      await tester.tap(find.text('Total Income'));
      await tester.pump();
      expect(incomeTapped, isTrue);
    });

    testWidgets('FinancialChartCard renders with period selector and legend',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          child: SingleChildScrollView(
            child: FinancialChartCard(
              monthlySummary: sampleMonthlySummary,
            ),
          ),
        ),
      );

      expect(find.text('Income vs Expense Flow'), findsOneWidget);
      expect(find.text('Last 6 Months'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('PendingTasksCard renders with real count and triggers navigation',
        (tester) async {
      bool taskTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          child: PendingTasksCard(
            pendingTasks: 3,
            onTap: () => taskTapped = true,
          ),
        ),
      );

      expect(find.text('Pending Tasks'), findsOneWidget);
      expect(find.text('Tasks that need your attention.'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      await tester.tap(find.text('Pending Tasks'));
      await tester.pump();
      expect(taskTapped, isTrue);
    });

    testWidgets('VorynBottomNavBar renders all 6 destinations for iOS and Android',
        (tester) async {
      final destinations = [
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
        const VorynNavDestination(
          label: 'Personal',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
        ),
      ];

      // iOS
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          platform: TargetPlatform.iOS,
          child: VorynBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: destinations,
          ),
        ),
      );
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);

      // Android
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          platform: TargetPlatform.android,
          child: VorynBottomNavBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: destinations,
          ),
        ),
      );
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
    });

    testWidgets('Zero overflow across all responsive screen sizes',
        (tester) async {
      final screenSizes = [
        const Size(320, 568), // Small iPhone SE
        const Size(375, 667), // iPhone 8 / SE2
        const Size(390, 844), // iPhone 12/13/14/15/16
        const Size(430, 932), // iPhone Pro Max
        const Size(768, 1024), // iPad / Tablet
        const Size(1280, 800), // Desktop
      ];

      for (final size in screenSizes) {
        await tester.pumpWidget(
          buildTestableWidget(
            screenSize: size,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const DashboardHeroCard(userName: 'sinas'),
                  const SizedBox(height: 16),
                  ThisMonthSection(
                    monthlySummary: sampleMonthlySummary,
                    hasFinancialAccess: true,
                  ),
                  const SizedBox(height: 16),
                  const OverallPerformanceSection(
                    totalIncome: 46100.0,
                    totalExpenses: 550.0,
                    totalProfit: 45550.0,
                    hasFinancialAccess: true,
                  ),
                  const SizedBox(height: 16),
                  FinancialChartCard(
                    monthlySummary: sampleMonthlySummary,
                  ),
                  const SizedBox(height: 16),
                  const PendingTasksCard(
                    pendingTasks: 0,
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify no FlutterError was triggered during build/layout
        expect(tester.takeException(), isNull,
            reason: 'Failed layout at size $size');
      }
    });
  });
}
