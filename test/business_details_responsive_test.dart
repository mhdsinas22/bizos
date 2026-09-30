import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/presentation/widgets/business_header.dart';
import 'package:bizos/features/business/presentation/widgets/business_overview_card.dart';
import 'package:bizos/features/business/presentation/widgets/business_module_grid.dart';

void main() {
  final sampleBusiness = BusinessModel(
    id: 'biz-123',
    name: 'haptic fone',
    type: 'mobile phone sales',
    phone: '+91 9876543210',
    address: '123 Market Street, Tech Hub',
    notes: 'Premium mobile store',
    ownerId: 'owner-456',
  );

  Widget buildTestableWidget({
    required Widget child,
    required Size screenSize,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      themeAnimationDuration: Duration.zero,
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: screenSize.width, child: child),
          ),
        ),
      ),
    );
  }

  group('Business Header Tests', () {
    testWidgets('Renders business initial, name, type, and active pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          child: BusinessHeader(
            business: sampleBusiness,
            onBack: () {},
            onSettingsTap: () {},
          ),
        ),
      );

      expect(find.text('H'), findsOneWidget);
      expect(find.text('haptic fone'), findsOneWidget);
      expect(find.text('mobile phone sales'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });

  group('Business Overview Card Tests', () {
    testWidgets('Renders 4 metrics in a single row with no overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          child: const BusinessOverviewCard(
            totalRevenue: 7000.0,
            totalExpenses: 2000.0,
            netProfit: 5000.0,
            totalInvoices: 4,
          ),
        ),
      );

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Business summary and insights'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('Net Profit'), findsOneWidget);
      expect(find.text('Total Invoices'), findsOneWidget);
      expect(find.text('+12%'), findsOneWidget);
      expect(find.text('+8%'), findsOneWidget);
      expect(find.text('+18%'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Adapts safely to narrow 320px screen (iPhone SE)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final List<FlutterErrorDetails> errors = [];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
      };

      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(320, 568),
          child: const BusinessOverviewCard(
            totalRevenue: 125000.0,
            totalExpenses: 45000.0,
            netProfit: 80000.0,
            totalInvoices: 124,
          ),
        ),
      );

      for (var err in errors) {
        print('RENDERFLEX ERROR: ${err.toString()}');
      }

      FlutterError.onError = oldOnError;

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(errors, isEmpty);
    });

    testWidgets('Renders properly in dark mode', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(390, 844),
          theme: AppTheme.darkTheme,
          child: const BusinessOverviewCard(
            totalRevenue: 7000.0,
            totalExpenses: 2000.0,
            netProfit: 5000.0,
            totalInvoices: 4,
          ),
        ),
      );

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Business Module Card & Grid Tests', () {
    final testModules = [
      const BusinessModuleItemData(
        id: 'invoices',
        icon: Icons.description_rounded,
        accentColor: Color(0xFF3B82F6),
        title: 'Invoices',
        description: 'Create and manage invoices',
        footerLeft: '4 invoices',
        footerRight: '₹7,000.00',
        footerRightColor: Color(0xFF10B981),
      ),
      const BusinessModuleItemData(
        id: 'customers',
        icon: Icons.people_alt_rounded,
        accentColor: Color(0xFF10B981),
        title: 'Customers',
        description: 'Manage your customers',
        footerLeft: '4 customers',
      ),
      const BusinessModuleItemData(
        id: 'products_services',
        icon: Icons.inventory_2_rounded,
        accentColor: Color(0xFFF59E0B),
        title: 'Products & Services',
        description: 'Manage products and services',
        footerLeft: '12 items',
      ),
      const BusinessModuleItemData(
        id: 'tasks',
        icon: Icons.event_note_rounded,
        accentColor: Color(0xFFF43F5E),
        chevronColor: Color(0xFFF43F5E),
        title: 'ToDo Tasks',
        description: 'Stay organized and productive',
        footerLeft: '0 pending',
        footerRight: '0 completed',
        footerIsDivided: true,
      ),
      const BusinessModuleItemData(
        id: 'income',
        icon: Icons.arrow_downward_rounded,
        accentColor: Color(0xFF10B981),
        title: 'Income',
        description: 'Track your income and receivables',
        footerLeft: '2 records',
        footerRight: '₹2,000.00',
        footerRightColor: Color(0xFF10B981),
      ),
      const BusinessModuleItemData(
        id: 'expenses',
        icon: Icons.arrow_upward_rounded,
        accentColor: Color(0xFFEF4444),
        chevronColor: Color(0xFFEF4444),
        title: 'Expenses',
        description: 'Track your expenses and payments',
        footerLeft: '0 records',
        footerRight: '₹0.00',
        footerRightColor: Color(0xFFEF4444),
      ),
      const BusinessModuleItemData(
        id: 'p_and_l',
        icon: Icons.pie_chart_rounded,
        accentColor: Color(0xFF8B5CF6),
        title: 'P&L Reports',
        description: 'View profit & loss reports and analytics',
      ),
      const BusinessModuleItemData(
        id: 'staff',
        icon: Icons.manage_accounts_rounded,
        accentColor: Color(0xFF0EA5E9),
        title: 'Staff Management',
        description: 'Manage your staff and access',
      ),
    ];

    const fullWidthModule = BusinessModuleItemData(
      id: 'invoice_settings',
      icon: Icons.settings_outlined,
      accentColor: Color(0xFF64748B),
      title: 'Invoice Settings',
      description: 'Branding, templates and customization',
    );

    testWidgets(
      'Renders all 8 modules and full-width card with zero overflow on mobile',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildTestableWidget(
            screenSize: const Size(390, 844),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: BusinessModuleGrid(
                modules: testModules,
                fullWidthModule: fullWidthModule,
              ),
            ),
          ),
        );

        expect(find.text('Invoices'), findsOneWidget);
        expect(find.text('Customers'), findsOneWidget);
        expect(find.text('Products & Services'), findsOneWidget);
        expect(find.text('ToDo Tasks'), findsOneWidget);
        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Expenses'), findsOneWidget);
        expect(find.text('P&L Reports'), findsOneWidget);
        expect(find.text('Staff Management'), findsOneWidget);
        expect(find.text('Invoice Settings'), findsOneWidget);
        expect(find.text('0 pending'), findsOneWidget);
        expect(find.text('0 completed'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Adapts to Tablet (768px) and Desktop (1280px) widths cleanly',
      (tester) async {
        // Tablet test
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        await tester.pumpWidget(
          buildTestableWidget(
            screenSize: const Size(768, 1024),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BusinessModuleGrid(
                modules: testModules,
                fullWidthModule: fullWidthModule,
              ),
            ),
          ),
        );
        expect(find.text('Invoices'), findsOneWidget);
        expect(find.text('Invoice Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Desktop test
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        await tester.pumpWidget(
          buildTestableWidget(
            screenSize: const Size(1280, 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BusinessModuleGrid(
                modules: testModules,
                fullWidthModule: fullWidthModule,
              ),
            ),
          ),
        );
        expect(find.text('Invoices'), findsOneWidget);
        expect(find.text('Invoice Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() => tester.binding.setSurfaceSize(null));
      },
    );
  });
}
