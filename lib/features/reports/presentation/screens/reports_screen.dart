import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/pdf_generator.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/finance/presentation/widgets/date_filter_bottom_sheet.dart';
import 'package:bizos/features/reports/domain/repo/report_repository.dart';
import 'package:bizos/features/reports/domain/services/business_analytics_engine.dart';
import 'package:bizos/features/reports/presentation/widgets/recent_reports_section.dart';
import 'package:bizos/features/reports/presentation/widgets/report_configuration_card.dart';
import 'package:bizos/features/reports/presentation/widgets/report_details_card.dart';
import 'package:bizos/features/reports/presentation/widgets/reports_hero.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  BusinessModel? _selectedBusiness;
  String _reportType = 'Income Statement';
  bool _isExporting = false;
  DateFilterOption _activeFilterOption = DateFilterOption.allTime;
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterLabel = 'All Time';

  final List<RecentReportLog> _recentReports = [];

  static const List<String> _reportTypes = [
    'Complete Business Analytics',
    'Profit & Loss Statement',
    'Income Statement',
    'Expense Statement',
    'Task Management',
    'Staff Report',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _openDateFilterSheet() async {
    final result = await showModalBottomSheet<DateFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DateFilterBottomSheet(
        initialOption: _activeFilterOption,
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _activeFilterOption = result.selectedOption;
        _startDate = result.startDate;
        _endDate = result.endDate;
        _filterLabel = result.label;
      });
    }
  }

  Future<void> _handlePdfAction({required bool isShare}) async {
    if (_selectedBusiness == null) return;
    setState(() => _isExporting = true);

    try {
      final authState = context.read<AuthBloc>().state;
      final userName =
          authState is Authenticated ? authState.user.name : 'Business Owner';
      final reportRepo = context.read<ReportRepository>();

      final incomes = await reportRepo.getIncomeReportData(
        _selectedBusiness!.id,
        startDate: _startDate,
        endDate: _endDate,
      );
      final expenses = await reportRepo.getExpenseReportData(
        _selectedBusiness!.id,
        startDate: _startDate,
        endDate: _endDate,
      );
      final allTasks =
          await reportRepo.getTaskReportData(_selectedBusiness!.id);

      final filteredTasks = allTasks.where((t) {
        if (_startDate != null && t.dueDate.isBefore(_startDate!)) return false;
        if (_endDate != null && t.dueDate.isAfter(_endDate!)) return false;
        return true;
      }).toList();

      final now = DateTime.now();
      final start = _startDate ??
          (incomes.isNotEmpty || expenses.isNotEmpty
              ? (incomes
                  .map((i) => i.date)
                  .followedBy(expenses.map((e) => e.date))
                  .reduce((a, b) => a.isBefore(b) ? a : b))
              : DateTime(now.year, 1, 1));
      final end = _endDate ?? now;

      final allIncomes =
          await reportRepo.getIncomeReportData(_selectedBusiness!.id);
      final allExpenses =
          await reportRepo.getExpenseReportData(_selectedBusiness!.id);

      final analyticsData = await BusinessAnalyticsEngine.compute(
        incomes: incomes,
        expenses: expenses,
        tasks: filteredTasks,
        startDate: start,
        endDate: end,
        allIncomes: allIncomes,
        allExpenses: allExpenses,
      );

      final pdfBytes = await PdfGenerator.generateReport(
        business: _selectedBusiness!,
        incomes: incomes,
        expenses: expenses,
        tasks: filteredTasks,
        reportType: _reportType,
        ownerName: userName,
        startDate: start,
        endDate: end,
        filterLabel: _filterLabel,
        analyticsData: analyticsData,
      );

      final filename =
          '${_selectedBusiness!.name.replaceAll(' ', '_')}_${_reportType.replaceAll(' ', '_')}_Report.pdf';

      if (isShare) {
        await PdfGenerator.sharePdf(pdfBytes, filename);
      } else {
        await PdfGenerator.printPdf(pdfBytes, filename);
      }

      // Add to recent reports log for quick access
      if (mounted) {
        final formattedType = _reportType.endsWith('Statement') ||
                _reportType.endsWith('Report')
            ? _reportType
            : '$_reportType Statement';

        setState(() {
          _recentReports.removeWhere((r) =>
              r.reportType == formattedType &&
              r.businessName == _selectedBusiness!.name &&
              r.dateRange == _filterLabel);

          _recentReports.insert(
            0,
            RecentReportLog(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              reportType: formattedType,
              businessName: _selectedBusiness!.name,
              dateRange: _filterLabel == 'All Time'
                  ? 'All Time'
                  : _filterLabel,
              generatedAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();
    final user = authState.user;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      body: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, state) {
          List<BusinessModel> businesses = [];
          if (state is BusinessLoaded) {
            businesses = state.businesses;
          }

          if (businesses.isEmpty) {
            return const EmptyState(
              icon: Icons.analytics_outlined,
              title: 'No Businesses Available',
              message:
                  'You must configure at least one business to generate reports.',
            );
          }

          // Force select if current selected is null or not in current list
          if (_selectedBusiness == null ||
              !businesses.any((b) => b.id == _selectedBusiness!.id)) {
            _selectedBusiness = businesses.first;
          } else {
            _selectedBusiness = businesses.firstWhere(
              (b) => b.id == _selectedBusiness!.id,
            );
          }

          final hasReportAccess = user.hasPermission(
            _reportType.contains('Task') ? 'view_tasks' : 'view_accounts',
            businessId: _selectedBusiness?.id,
          );

          if (!hasReportAccess) {
            return const EmptyState(
              icon: Icons.lock_outline,
              title: 'Access Restricted',
              message:
                  'Your Staff account does not have access to this report.',
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal:
                  MediaQuery.sizeOf(context).width > 600 ? 24.0 : 16.0,
              vertical: 12.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Reporting Console Hero Banner
                    const ReportsHero(),

                    const SizedBox(height: 16),

                    // 2. Report Configuration Controls Card
                    ReportConfigurationCard(
                      selectedBusiness: _selectedBusiness,
                      businesses: businesses,
                      onBusinessChanged: (b) {
                        setState(() {
                          _selectedBusiness = b;
                        });
                      },
                      selectedReportType: _reportType,
                      reportTypes: _reportTypes,
                      onReportTypeChanged: (type) {
                        setState(() {
                          _reportType = type;
                        });
                      },
                      dateRangeLabel: _filterLabel,
                      onDateRangeTap: _openDateFilterSheet,
                    ),

                    const SizedBox(height: 16),

                    // 3. Report Details Card
                    ReportDetailsCard(
                      businessName: _selectedBusiness?.name ?? '',
                      reportType: _reportType.endsWith('Statement') ||
                              _reportType.endsWith('Report')
                          ? _reportType
                          : '$_reportType Statement',
                      dateRange: _filterLabel == 'All Time'
                          ? 'All Recorded Historical Transactions'
                          : _filterLabel,
                      generatedBy:
                          user.name.isNotEmpty ? user.name : 'Business Owner',
                      generatedAt: nowStr,
                      fileFormat: 'PDF',
                      isExporting: _isExporting,
                      onExportAndPrint: () => _handlePdfAction(isShare: false),
                      onShareReport: () => _handlePdfAction(isShare: true),
                    ),

                    const SizedBox(height: 20),

                    // 4. Recent Reports Section
                    RecentReportsSection(
                      recentReports: _recentReports,
                      onRePrint: (log) => _handlePdfAction(isShare: false),
                      onReShare: (log) => _handlePdfAction(isShare: true),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
