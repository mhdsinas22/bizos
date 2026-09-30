import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/core/utils/pdf_generator.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/presentation/screen/business_report_preview_screen.dart';
import 'package:bizos/features/business/presentation/widgets/business_report_loading_dialog.dart';
import 'package:bizos/features/reports/domain/services/business_analytics_engine.dart';
import 'package:bizos/features/reports/domain/repo/report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessReportsScreen extends StatefulWidget {
  final BusinessModel business;

  const BusinessReportsScreen({
    super.key,
    required this.business,
  });

  @override
  State<BusinessReportsScreen> createState() => _BusinessReportsScreenState();
}

class _BusinessReportsScreenState extends State<BusinessReportsScreen> {
  // 1. Report Type
  String _selectedReportType = 'Complete Business Analytics';

  final List<String> _reportTypes = [
    'Complete Business Analytics',
    'Profit & Loss Statement',
    'Income Statement',
    'Expense Statement',
    'Task Management',
    'Staff Report',
  ];

  // 2. Date Filter
  String _selectedDateFilter = 'This Month';

  final List<String> _dateFilters = [
    'Today',
    'Yesterday',
    'This Week',
    'Last Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'Last Quarter',
    'This Year',
    'Last Year',
    'Custom Date Range',
  ];

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // 3. Report Options Checkboxes
  final Map<String, bool> _reportOptions = {
    'Executive Summary': true,
    'KPI Dashboard': true,
    'Revenue Charts': true,
    'Expense Charts': true,
    'Profit Charts': true,
    'Cash Flow': true,
    'Customer Analytics': true,
    'Supplier Analytics': true,
    'Product Analytics': true,
    'Inventory Analytics': true,
    'Financial Health Score': true,
    'Business Insights': true,
    'Risk Analysis': true,
    'Transaction Details': true,
    'Payment Method Analysis': true,
  };

  // 4. Export Format Selection
  String _selectedExportFormat = 'PDF';

  final List<String> _exportFormats = ['PDF', 'Excel', 'Print', 'Share'];

  bool _isProcessing = false;

  DateTimeRange _calculateDateRange() {
    final now = DateTime.now();
    switch (_selectedDateFilter) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case 'Yesterday':
        final y = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(y.year, y.month, y.day, 0, 0, 0),
          end: DateTime(y.year, y.month, y.day, 23, 59, 59, 999),
        );
      case 'This Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case 'Last Week':
        final lastWeekNow = now.subtract(const Duration(days: 7));
        final start = lastWeekNow.subtract(Duration(days: lastWeekNow.weekday - 1));
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        return DateTimeRange(start: DateTime(start.year, start.month, start.day, 0, 0, 0), end: end);
      case 'This Month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1, 0, 0, 0),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        return DateTimeRange(start: lastMonth, end: endLastMonth);
      case 'This Quarter':
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final qStartMonth = (currentQuarter - 1) * 3 + 1;
        final qEndMonth = qStartMonth + 2;
        return DateTimeRange(
          start: DateTime(now.year, qStartMonth, 1, 0, 0, 0),
          end: DateTime(now.year, qEndMonth + 1, 0, 23, 59, 59, 999),
        );
      case 'Last Quarter':
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final prevQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
        final prevYear = currentQuarter == 1 ? now.year - 1 : now.year;
        final qStartMonth = (prevQuarter - 1) * 3 + 1;
        final qEndMonth = qStartMonth + 2;
        final qEnd = DateTime(prevYear, qEndMonth + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: DateTime(prevYear, qStartMonth, 1, 0, 0, 0), end: qEnd);
      case 'This Year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1, 0, 0, 0),
          end: DateTime(now.year, 12, 31, 23, 59, 59, 999),
        );
      case 'Last Year':
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1, 0, 0, 0),
          end: DateTime(now.year - 1, 12, 31, 23, 59, 59, 999),
        );
      case 'Custom Date Range':
        if (_customStartDate != null && _customEndDate != null) {
          return DateTimeRange(
            start: DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day, 0, 0, 0),
            end: DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59, 999),
          );
        }
        return DateTimeRange(
          start: DateTime(now.year, 1, 1, 0, 0, 0),
          end: DateTime(now.year, 12, 31, 23, 59, 59, 999),
        );
      default:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1, 0, 0, 0),
          end: DateTime(now.year, 12, 31, 23, 59, 59, 999),
        );
    }
  }

  void _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedDateFilter = 'Custom Date Range';
      });
    }
  }

  Future<void> _generateReportFlow() async {
    setState(() => _isProcessing = true);
    final authState = context.read<AuthBloc>().state;
    final ownerName = authState.user?.name ?? 'Business Owner';
    final ownerId = authState.user?.id ?? '';
    final reportRepo = context.read<ReportRepository>();

    try {
      final range = _calculateDateRange();
      final allIncomes = await reportRepo.getIncomeReportData(widget.business.id);
      final allExpenses = await reportRepo.getExpenseReportData(widget.business.id);
      final allTasks = await reportRepo.getTaskReportData(widget.business.id);

      final tasks = allTasks.where((t) {
        if (t.dueDate.isBefore(range.start)) return false;
        if (t.dueDate.isAfter(range.end)) return false;
        return true;
      }).toList();

      final incomes = await reportRepo.getIncomeReportData(
        widget.business.id,
        startDate: range.start,
        endDate: range.end,
      );
      final expenses = await reportRepo.getExpenseReportData(
        widget.business.id,
        startDate: range.start,
        endDate: range.end,
      );

      // STEP 10 — DEBUG LOGGING
      final double pnlRevenue = incomes.fold(0.0, (sum, i) => sum + i.amount);
      final double pnlExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final double pnlProfit = pnlRevenue - pnlExpense;

      AppLogger.info("============== [FINANCIAL RECONCILIATION DEBUG] ==============");
      AppLogger.info("Business ID: ${widget.business.id}");
      AppLogger.info("Owner ID: $ownerId");
      AppLogger.info("Report Start Date: ${range.start}");
      AppLogger.info("Report End Date: ${range.end}");
      AppLogger.info("P&L Revenue: ₹$pnlRevenue");
      AppLogger.info("P&L Expense: ₹$pnlExpense");
      AppLogger.info("P&L Profit: ₹$pnlProfit");
      AppLogger.info("P&L Transactions Count: Incomes=${incomes.length}, Expenses=${expenses.length}");
      AppLogger.info("Income Transaction IDs: ${incomes.map((i) => i.id).toList()}");
      AppLogger.info("Expense Transaction IDs: ${expenses.map((e) => e.id).toList()}");

      final analyticsData = await BusinessAnalyticsEngine.compute(
        incomes: incomes,
        expenses: expenses,
        tasks: tasks,
        startDate: range.start,
        endDate: range.end,
        allIncomes: allIncomes,
        allExpenses: allExpenses,
      );

      AppLogger.info("Analytics Revenue: ₹${analyticsData.kpis.totalRevenue}");
      AppLogger.info("Analytics Expense: ₹${analyticsData.kpis.totalExpense}");
      AppLogger.info("Analytics Profit: ₹${analyticsData.kpis.netProfit}");
      AppLogger.info("Analytics Transactions Count: ${analyticsData.kpis.totalTransactions}");

      final mRevGrouped = analyticsData.monthly.monthlyItems.map((m) => "${m.monthName}: ₹${m.revenue}").toList();
      AppLogger.info("Revenue Grouped By Month: $mRevGrouped");
      final mExpGrouped = analyticsData.monthly.monthlyItems.map((m) => "${m.monthName}: ₹${m.expense}").toList();
      AppLogger.info("Expense Grouped By Month: $mExpGrouped");

      // STEP 9 — RECONCILIATION VALIDATION
      final double monthlyRevSum = analyticsData.monthly.monthlyItems.fold(0.0, (sum, item) => sum + item.revenue);
      final double monthlyExpSum = analyticsData.monthly.monthlyItems.fold(0.0, (sum, item) => sum + item.expense);

      final isRevReconciled = (pnlRevenue - analyticsData.kpis.totalRevenue).abs() < 0.01;
      final isExpReconciled = (pnlExpense - analyticsData.kpis.totalExpense).abs() < 0.01;
      final isProfitReconciled = (pnlProfit - analyticsData.kpis.netProfit).abs() < 0.01;
      final isMonthlyRevReconciled = (monthlyRevSum - analyticsData.kpis.totalRevenue).abs() < 0.01;
      final isMonthlyExpReconciled = (monthlyExpSum - analyticsData.kpis.totalExpense).abs() < 0.01;

      if (!isRevReconciled || !isExpReconciled || !isProfitReconciled || !isMonthlyRevReconciled || !isMonthlyExpReconciled) {
        AppLogger.error("❌ [RECONCILIATION FAILURE]");
        AppLogger.error("   P&L Rev: $pnlRevenue vs Analytics Rev: ${analyticsData.kpis.totalRevenue}");
        AppLogger.error("   P&L Exp: $pnlExpense vs Analytics Exp: ${analyticsData.kpis.totalExpense}");
        AppLogger.error("   P&L Profit: $pnlProfit vs Analytics Profit: ${analyticsData.kpis.netProfit}");
        AppLogger.error("   Monthly Rev Sum: $monthlyRevSum vs Total Rev: ${analyticsData.kpis.totalRevenue}");
        AppLogger.error("   Monthly Exp Sum: $monthlyExpSum vs Total Exp: ${analyticsData.kpis.totalExpense}");
        throw Exception("Financial Reconciliation Failed! P&L and Business Analytics totals mismatch.");
      } else {
        AppLogger.info("✅ [RECONCILIATION PASSED] P&L and Business Analytics PDF match 100%.");
      }
      AppLogger.info("==============================================================");

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BusinessReportLoadingDialog(
          onComplete: () async {
            Navigator.of(dialogContext).pop(); // Close loading dialog

            final pdfBytes = await PdfGenerator.generateReport(
              business: widget.business,
              incomes: incomes,
              expenses: expenses,
              tasks: tasks,
              reportType: _selectedReportType,
              ownerName: ownerName,
              startDate: range.start,
              endDate: range.end,
              filterLabel: _selectedDateFilter,
              analyticsData: analyticsData,
            );

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessReportPreviewScreen(
                    business: widget.business,
                    pdfBytes: pdfBytes,
                    reportTitle: _selectedReportType,
                    incomes: incomes,
                    expenses: expenses,
                  ),
                ),
              );
            }
          },
        ),
      );
    } catch (e) {
      AppLogger.error("Error analyzing report data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing data: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) return const SizedBox.shrink();
    final user = authState.user;

    // SECURITY GUARD: RESTRICT ACCESS TO OWNER ONLY
    if (!user.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Reports')),
        body: const EmptyState(
          icon: Icons.lock_rounded,
          title: 'Access Restricted',
          message: 'Business Reports are strictly reserved for Owner accounts. Staff users cannot view or access business reporting.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Reports Center'),
            Text(
              widget.business.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ERP Reporting & Analytics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generate executive business intelligence reports suitable for banks, auditors, and investors.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Report Type Section
            Text(
              '1. Select Report Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reportTypes.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final type = _reportTypes[index];
                  final isSelected = type == _selectedReportType;
                  return RadioListTile<String>(
                    value: type,
                    // ignore: deprecated_member_use
                    groupValue: _selectedReportType,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReportType = val);
                    },
                    title: Text(
                      type,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : null,
                        fontSize: 13,
                      ),
                    ),
                    activeColor: AppTheme.primaryColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    dense: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. Date Filter Section
            Text(
              '2. Select Period Filter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dateFilters.map((filter) {
                final isSelected = filter == _selectedDateFilter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      if (filter == 'Custom Date Range') {
                        _selectCustomDateRange();
                      } else {
                        setState(() => _selectedDateFilter = filter);
                      }
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 3. Report Options Checkboxes
            Text(
              '3. Include Analytics Sections',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reportOptions.keys.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final key = _reportOptions.keys.elementAt(index);
                  final val = _reportOptions[key]!;

                  return CheckboxListTile(
                    value: val,
                    onChanged: (checked) {
                      if (checked != null) {
                        setState(() => _reportOptions[key] = checked);
                      }
                    },
                    title: Text(
                      key,
                      style: const TextStyle(fontSize: 13),
                    ),
                    activeColor: AppTheme.primaryColor,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 4. Export Format Selection
            Text(
              '4. Select Primary Export Format',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _exportFormats.map((fmt) {
                final isSelected = fmt == _selectedExportFormat;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selectedExportFormat = fmt),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.12) : null,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        fmt,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _generateReportFlow,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text(
                  'Generate Business Report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
