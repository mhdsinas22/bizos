import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/utils/pdf_generator.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/reports/domain/repo/report_repository.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  BusinessModel? _selectedBusiness;
  String _reportType = 'Income'; // 'Income', 'Expense', 'Profit', 'Task'
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Pre-select first business if available
  }

  Future<void> _handlePdfAction({required bool isShare}) async {
    if (_selectedBusiness == null) return;
    setState(() => _isExporting = true);

    try {
      final reportRepo = context.read<ReportRepository>();

      final incomes = await reportRepo.getIncomeReportData(
        _selectedBusiness!.id,
      );
      final expenses = await reportRepo.getExpenseReportData(
        _selectedBusiness!.id,
      );
      final tasks = await reportRepo.getTaskReportData(_selectedBusiness!.id);

      final pdfBytes = await PdfGenerator.generateReport(
        business: _selectedBusiness!,
        incomes: incomes,
        expenses: expenses,
        tasks: tasks,
        reportType: _reportType,
      );

      final filename =
          '${_selectedBusiness!.name.replaceAll(' ', '_')}_${_reportType}_Report.pdf';

      if (isShare) {
        await PdfGenerator.sharePdf(pdfBytes, filename);
      } else {
        await PdfGenerator.printPdf(pdfBytes, filename);
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
    return Scaffold(
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
            // Keep it updated with the latest instance from the list to avoid reference mismatches
            _selectedBusiness = businesses.firstWhere(
              (b) => b.id == _selectedBusiness!.id,
            );
          }

          final hasReportAccess = user.hasPermission(
            _reportType == 'Task' ? 'view_tasks' : 'view_accounts',
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reporting Console',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Generate and share corporate PDF statements.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Selection card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<BusinessModel>(
                        // ignore: deprecated_member_use
                        value: _selectedBusiness,
                        decoration: InputDecoration(
                          labelText: 'Select Business Entity',
                          prefixIcon: const Icon(Icons.storefront),
                          fillColor: theme.brightness == Brightness.dark
                              ? AppTheme.darkBg
                              : AppTheme.lightBg,
                        ),
                        items: businesses.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(b.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBusiness = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Select Report Type
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _reportType,
                        decoration: InputDecoration(
                          labelText: 'Select Statement Type',
                          prefixIcon: const Icon(Icons.description_outlined),
                          fillColor: theme.brightness == Brightness.dark
                              ? AppTheme.darkBg
                              : AppTheme.lightBg,
                        ),
                        items: ['Income', 'Expense', 'Profit', 'Task'].map((
                          type,
                        ) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text('$type Statement'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _reportType = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Report Details Preview',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPreviewRow(
                        'Target Entity',
                        _selectedBusiness?.name ?? '',
                      ),
                      _buildPreviewRow(
                        'Report Category',
                        '$_reportType Statement',
                      ),
                      _buildPreviewRow('File Format', 'Adobe PDF (.pdf)'),
                      _buildPreviewRow(
                        'Scope',
                        'All recorded historical transactions',
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Export & Print',
                              icon: Icons.print_outlined,
                              isSecondary: true,
                              isLoading: _isExporting,
                              onPressed: () => _handlePdfAction(isShare: false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Share Report',
                              icon: Icons.share_outlined,
                              isLoading: _isExporting,
                              onPressed: () => _handlePdfAction(isShare: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
