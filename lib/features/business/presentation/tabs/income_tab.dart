import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/search_filter_bar.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/presentation/widgets/income_details_sheet.dart';
import 'package:bizos/features/business/presentation/widgets/income_form_sheet.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:bizos/features/finance/presentation/widgets/date_filter_bottom_sheet.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';

class IncomeTab extends StatefulWidget {
  final String businessId;
  final UserModel user;
  final bool showAppBar;

  const IncomeTab({
    super.key,
    required this.businessId,
    required this.user,
    this.showAppBar = true,
  });

  @override
  State<IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<IncomeTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateFilterOption _activeFilterOption = DateFilterOption.allTime;
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterLabel = 'All Time';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showIncomeForm({IncomeModel? income}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => IncomeFormSheet(
        businessId: widget.businessId,
        income: income,
        user: widget.user,
        onSave: () {
          context.read<FinanceBloc>().add(
            FetchFinanceDataEvent(
              widget.businessId,
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
        },
      ),
    );
  }

  void _showIncomeDetails(IncomeModel income) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => IncomeDetailsSheet(income: income),
    );
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

      context.read<FinanceBloc>().add(
        FetchFinanceDataEvent(
          widget.businessId,
          startDate: result.startDate,
          endDate: result.endDate,
        ),
      );
    }
  }

  void _confirmDelete(IncomeModel inc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Income Entry?'),
        content: Text(
          'Are you sure you want to delete "${inc.category}: ${CurrencyFormatter.format(inc.amount)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FinanceBloc>().add(
                DeleteIncomeEvent(inc.id, widget.businessId),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFilterActive = _activeFilterOption != DateFilterOption.allTime;
    final hasFinanceAccess = widget.user.hasPermission(
      'view_accounts',
      businessId: widget.businessId,
    );

    if (!hasFinanceAccess) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Access Restricted',
        message:
            'Your Staff account does not have access to Financial tracking.',
      );
    }

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Income Tracking'),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIncomeForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Cohesive Search & Filter Section
          SearchFilterBar(
            searchController: _searchController,
            searchHint: 'Search category, payment method or description...',
            searchQuery: _searchQuery,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            onClearSearch: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            onFilterTap: _openDateFilterSheet,
            isFilterActive: isFilterActive,
            filterLabel: _filterLabel,
            onClearFilter: () {
              setState(() {
                _activeFilterOption = DateFilterOption.allTime;
                _startDate = null;
                _endDate = null;
                _filterLabel = 'All Time';
              });
              context.read<FinanceBloc>().add(
                FetchFinanceDataEvent(widget.businessId),
              );
            },
          ),

          // Wire text change
          Builder(
            builder: (context) {
              _searchController.addListener(() {
                if (_searchController.text != _searchQuery) {
                  setState(() {
                    _searchQuery = _searchController.text;
                  });
                }
              });
              return const SizedBox.shrink();
            },
          ),

          Expanded(
            child: BlocBuilder<FinanceBloc, FinanceState>(
              builder: (context, state) {
                if (state is FinanceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is FinanceError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                if (state is FinanceLoaded) {
                  var list = state.incomeList;

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    list = list
                        .where(
                          (i) =>
                              i.category.toLowerCase().contains(q) ||
                              i.paymentMethod.toLowerCase().contains(q) ||
                              i.description.toLowerCase().contains(q) ||
                              i.amount.toString().contains(q),
                        )
                        .toList();
                  }

                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.monetization_on_outlined,
                      title: 'No Income Entries',
                      message:
                          'Record incoming invoices or cash flows for your business.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final inc = list[index];
                      final methodIcon = PaymentMethodHelper.getIcon(inc.paymentMethod);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () => _showIncomeDetails(inc),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    methodIcon,
                                    color: AppTheme.success,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              inc.category,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.success.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  methodIcon,
                                                  size: 11,
                                                  color: AppTheme.success,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  inc.paymentMethod,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (inc.description.isNotEmpty)
                                        Text(
                                          inc.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.disabledColor,
                                          ),
                                        ),
                                      Text(
                                        DateFormat.yMMMd().format(inc.date),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.disabledColor,
                                        ),
                                      ),
                                      Text(
                                        'Added By: ${(inc.createdByName != null && inc.createdByName!.trim().isNotEmpty) ? inc.createdByName : 'Unknown'}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.disabledColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(inc.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showIncomeForm(income: inc),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: () => _confirmDelete(inc),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
