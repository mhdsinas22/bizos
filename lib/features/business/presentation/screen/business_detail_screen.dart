import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/presentation/screen/business_reports_screen.dart';
import 'package:bizos/features/business/presentation/tabs/expense_tab.dart';
import 'package:bizos/features/business/presentation/tabs/income_tab.dart';
import 'package:bizos/features/business/presentation/tabs/profit_loss_tab.dart';
import 'package:bizos/features/business/presentation/tabs/staff_tab.dart';
import 'package:bizos/features/business/presentation/tabs/to_do_tab.dart';
import 'package:bizos/features/business/presentation/widgets/business_form_sheet.dart';
import 'package:bizos/features/business/presentation/widgets/business_header.dart';
import 'package:bizos/features/business/presentation/widgets/business_module_grid.dart';
import 'package:bizos/features/business/presentation/widgets/business_overview_card.dart';
import 'package:bizos/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:bizos/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:bizos/features/finance/presentation/screens/category_management_screen.dart';
import 'package:bizos/features/invoice_settings/presentation/screens/invoice_settings_screen.dart';
import 'package:bizos/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:bizos/features/invoices/presentation/screens/invoice_list_screen.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/pages/money_management_dashboard.dart';
import 'package:bizos/features/products_services/presentation/bloc/product_service_bloc.dart';
import 'package:bizos/features/products_services/presentation/screens/product_service_list_screen.dart';
import 'package:bizos/features/task/presentation/bloc/business_task_bloc.dart';
import 'package:bizos/features/task/presentation/bloc/business_task_event.dart';
import 'package:bizos/features/task/presentation/bloc/business_task_state.dart';

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

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial load for all business modules using existing BLoCs
    final bizId = widget.business.id;
    context.read<BusinessTaskBloc>().add(FetchTasksEvent(bizId));
    context.read<FinanceBloc>().add(FetchFinanceDataEvent(bizId));
    context.read<BusinessMoneyManagementBloc>().add(
      WatchTransactionsEvent(businessId: bizId),
    );
    context.read<InvoiceBloc>().add(FetchInvoicesEvent(businessId: bizId));
    context.read<CustomerBloc>().add(FetchCustomersEvent(businessId: bizId));
    context.read<ProductServiceBloc>().add(
      FetchProductsServicesEvent(businessId: bizId),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showEditBusinessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BusinessFormSheet(
        business: widget.business,
        onSave: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info(
      'Building business dashboard screen for business: ${widget.business.id}',
    );

    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();
    final user = authState.user;

    final isAssigned =
        user.isOwner ||
        user.businessPermissions.containsKey(widget.business.id);
    if (!isAssigned) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.business.name)),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Access Restricted',
          message: 'Your Staff account does not have access to this business.',
        ),
      );
    }

    final hasFinanceAccess = user.hasPermission(
      'view_accounts',
      businessId: widget.business.id,
    );
    final hasTaskAccess = user.hasPermission(
      'view_tasks',
      businessId: widget.business.id,
    );
    final canEditBusiness =
        user.isOwner ||
        user.hasPermission('edit_business', businessId: widget.business.id);

    // Watch states for real-time counts and metrics
    final financeState = context.watch<FinanceBloc>().state;
    final invoiceState = context.watch<InvoiceBloc>().state;
    final customerState = context.watch<CustomerBloc>().state;
    final productServiceState = context.watch<ProductServiceBloc>().state;
    final taskState = context.watch<BusinessTaskBloc>().state;

    // Financial Metrics
    double totalRevenue = 0.0;
    double totalExpenses = 0.0;
    int incomeCount = 0;
    int expenseCount = 0;
    if (hasFinanceAccess && financeState is FinanceLoaded) {
      incomeCount = financeState.incomeList.length;
      expenseCount = financeState.expenseList.length;
      totalRevenue = financeState.incomeList.fold(
        0.0,
        (sum, i) => sum + i.amount,
      );
      totalExpenses = financeState.expenseList.fold(
        0.0,
        (sum, e) => sum + e.amount,
      );
    }
    final double netProfit = totalRevenue - totalExpenses;

    // Invoices
    int totalInvoices = 0;
    double totalInvoiceAmount = 0.0;
    if (invoiceState is InvoiceLoaded) {
      totalInvoices = invoiceState.invoices.length;
      totalInvoiceAmount = invoiceState.invoices.fold(
        0.0,
        (sum, inv) => sum + inv.grandTotal,
      );
    }

    // Customers
    int totalCustomers = 0;
    if (customerState is CustomerLoaded) {
      totalCustomers = customerState.customers.length;
    }

    // Products & Services
    int totalProducts = 0;
    if (productServiceState is ProductServiceLoaded) {
      totalProducts = productServiceState.items.length;
    }

    // Tasks
    int pendingTasks = 0;
    int completedTasks = 0;
    if (taskState is BusinessTaskLoaded) {
      pendingTasks = taskState.tasks.where((t) => t.isPending).length;
      completedTasks = taskState.tasks.where((t) => t.isCompleted).length;
    }

    // Construct Module Items (8 primary modules matching reference UI)
    final List<BusinessModuleItemData> moduleItems = [
      // 1. Invoices
      BusinessModuleItemData(
        id: 'invoices',
        icon: Icons.description_rounded,
        accentColor: const Color(0xFF3B82F6),
        title: 'Invoices',
        description: 'Create and manage invoices',
        footerLeft: '$totalInvoices invoices',
        footerRight: CurrencyFormatter.format(totalInvoiceAmount),
        footerRightColor: const Color(0xFF10B981),
        onTap: () =>
            _navigateTo(InvoiceListScreen(businessId: widget.business.id)),
      ),

      // 2. Customers
      BusinessModuleItemData(
        id: 'customers',
        icon: Icons.people_alt_rounded,
        accentColor: const Color(0xFF10B981),
        title: 'Customers',
        description: 'Manage your customers',
        footerLeft: '$totalCustomers customers',
        onTap: () =>
            _navigateTo(CustomerListScreen(businessId: widget.business.id)),
      ),

      // 3. Products & Services
      BusinessModuleItemData(
        id: 'products_services',
        icon: Icons.inventory_2_rounded,
        accentColor: const Color(0xFFF59E0B),
        title: 'Products & Services',
        description: 'Manage products and services',
        footerLeft: '$totalProducts items',
        onTap: () => _navigateTo(
          ProductServiceListScreen(businessId: widget.business.id),
        ),
      ),

      // 4. ToDo Tasks
      BusinessModuleItemData(
        id: 'tasks',
        icon: Icons.event_note_rounded,
        accentColor: const Color(0xFFF43F5E),
        chevronColor: const Color(0xFFF43F5E),
        title: 'ToDo Tasks',
        description: 'Stay organized and productive',
        footerLeft: '$pendingTasks pending',
        footerRight: '$completedTasks completed',
        footerIsDivided: true,
        isEnabled: hasTaskAccess,
        onTap: () => _navigateTo(
          ToDoTab(
            businessId: widget.business.id,
            user: user,
            business: widget.business,
          ),
        ),
      ),

      // 5. Income
      BusinessModuleItemData(
        id: 'income',
        icon: Icons.arrow_downward_rounded,
        accentColor: const Color(0xFF10B981),
        title: 'Income',
        description: 'Track your income and receivables',
        footerLeft: hasFinanceAccess ? '$incomeCount records' : 'Restricted',
        footerRight: hasFinanceAccess
            ? CurrencyFormatter.format(totalRevenue)
            : '',
        footerRightColor: const Color(0xFF10B981),
        isEnabled: hasFinanceAccess,
        onTap: () =>
            _navigateTo(IncomeTab(businessId: widget.business.id, user: user)),
      ),

      // 6. Expenses
      BusinessModuleItemData(
        id: 'expenses',
        icon: Icons.arrow_upward_rounded,
        accentColor: const Color(0xFFEF4444),
        chevronColor: const Color(0xFFEF4444),
        title: 'Expenses',
        description: 'Track your expenses and payments',
        footerLeft: hasFinanceAccess ? '$expenseCount records' : 'Restricted',
        footerRight: hasFinanceAccess
            ? CurrencyFormatter.format(totalExpenses)
            : '',
        footerRightColor: const Color(0xFFEF4444),
        isEnabled: hasFinanceAccess,
        onTap: () =>
            _navigateTo(ExpenseTab(businessId: widget.business.id, user: user)),
      ),

      // 7. P&L Reports
      BusinessModuleItemData(
        id: 'p_and_l',
        icon: Icons.pie_chart_rounded,
        accentColor: const Color(0xFF8B5CF6),
        title: 'P&L Reports',
        description: 'View profit & loss reports and analytics',
        isEnabled: hasFinanceAccess,
        onTap: () => _navigateTo(
          ProfitAndLossTab(businessId: widget.business.id, user: user),
        ),
      ),

      // 8. Staff Management
      BusinessModuleItemData(
        id: 'staff',
        icon: Icons.manage_accounts_rounded,
        accentColor: const Color(0xFF0EA5E9),
        title: user.isOwner ? 'Staff Management' : 'Staff Overview',
        description: 'Manage your staff and access',
        onTap: () =>
            _navigateTo(StaffTab(user: user, businessId: widget.business.id)),
      ),
    ];

    // Invoice Settings (Full Width Bottom Card matching reference image)
    final BusinessModuleItemData invoiceSettingsModule = BusinessModuleItemData(
      id: 'invoice_settings',
      icon: Icons.settings_outlined,
      accentColor: const Color(0xFF64748B),
      title: 'Invoice Settings',
      description: 'Branding, templates and customization',
      isEnabled: canEditBusiness,
      onTap: () =>
          _navigateTo(InvoiceSettingsScreen(businessId: widget.business.id)),
    );

    return Scaffold(
      backgroundColor: isDark(context)
          ? const Color(0xFF0B0F19)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600
                      ? 24.0
                      : 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Business Header
                    BusinessHeader(
                      business: widget.business,
                      onBack: () => Navigator.pop(context),
                      onSettingsTap: canEditBusiness
                          ? () => _navigateTo(
                              InvoiceSettingsScreen(
                                businessId: widget.business.id,
                              ),
                            )
                          : null,
                      menuItemsBuilder: (menuContext) => [
                        if (hasFinanceAccess) ...[
                          const PopupMenuItem<String>(
                            value: 'money_mgmt',
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Money Management'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'categories',
                            child: Row(
                              children: [
                                Icon(Icons.category_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Manage Categories'),
                              ],
                            ),
                          ),
                        ],
                        if (user.isOwner)
                          const PopupMenuItem<String>(
                            value: 'reports',
                            child: Row(
                              children: [
                                Icon(Icons.analytics_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Business Reports'),
                              ],
                            ),
                          ),
                        if (user.isOwner)
                          const PopupMenuItem<String>(
                            value: 'edit_business',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Edit Business'),
                              ],
                            ),
                          ),
                      ],
                      onMenuItemSelected: (value) {
                        if (value == 'money_mgmt') {
                          _navigateTo(
                            MoneyManagementDashboard(
                              businessId: widget.business.id,
                              showAppBar: true,
                            ),
                          );
                        } else if (value == 'categories') {
                          _navigateTo(
                            CategoryManagementScreen(
                              businessId: widget.business.id,
                              userId: user.id,
                            ),
                          );
                        } else if (value == 'reports') {
                          _navigateTo(
                            BusinessReportsScreen(business: widget.business),
                          );
                        } else if (value == 'edit_business') {
                          _showEditBusinessSheet();
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Overview Card
                    BusinessOverviewCard(
                      totalRevenue: totalRevenue,
                      totalExpenses: totalExpenses,
                      netProfit: netProfit,
                      totalInvoices: totalInvoices,
                      onOverviewTap: () {
                        if (user.isOwner) {
                          _navigateTo(
                            BusinessReportsScreen(business: widget.business),
                          );
                        } else if (hasFinanceAccess) {
                          _navigateTo(
                            ProfitAndLossTab(
                              businessId: widget.business.id,
                              user: user,
                            ),
                          );
                        }
                      },
                      onRevenueTap: hasFinanceAccess
                          ? () => _navigateTo(
                              IncomeTab(
                                businessId: widget.business.id,
                                user: user,
                              ),
                            )
                          : null,
                      onExpensesTap: hasFinanceAccess
                          ? () => _navigateTo(
                              ExpenseTab(
                                businessId: widget.business.id,
                                user: user,
                              ),
                            )
                          : null,
                      onProfitTap: hasFinanceAccess
                          ? () => _navigateTo(
                              ProfitAndLossTab(
                                businessId: widget.business.id,
                                user: user,
                              ),
                            )
                          : null,
                      onInvoicesTap: () => _navigateTo(
                        InvoiceListScreen(businessId: widget.business.id),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Module Grid
                    BusinessModuleGrid(
                      modules: moduleItems,
                      fullWidthModule: invoiceSettingsModule,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

