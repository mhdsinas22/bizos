import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/search_filter_bar.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/presentation/widgets/expense_details_sheet.dart';
import 'package:bizos/features/business/presentation/widgets/expense_form_sheet.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:bizos/features/finance/presentation/widgets/date_filter_bottom_sheet.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';

class ExpenseTab extends StatefulWidget {
  final String businessId;
  final UserModel user;
  final bool showAppBar;

  const ExpenseTab({
    super.key,
    required this.businessId,
    required this.user,
    this.showAppBar = true,
  });

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<ExpenseTab> {
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

  void _showExpenseForm({ExpenseModel? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ExpenseFormSheet(
        businessId: widget.businessId,
        expense: expense,
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

  void _showExpenseDetails(ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ExpenseDetailsSheet(expense: expense),
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

  void _confirmDelete(ExpenseModel exp) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense Entry?'),
        content: Text(
          'Are you sure you want to delete "${exp.category}: ${CurrencyFormatter.format(exp.amount)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FinanceBloc>().add(
                DeleteExpenseEvent(exp.id, widget.businessId),
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
              title: const Text('Expense Tracking'),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
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
                  var list = state.expenseList;

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    list = list
                        .where(
                          (e) =>
                              e.category.toLowerCase().contains(q) ||
                              e.paymentMethod.toLowerCase().contains(q) ||
                              e.description.toLowerCase().contains(q) ||
                              e.amount.toString().contains(q),
                        )
                        .toList();
                  }

                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Expenses Logged',
                      message:
                          'Record utilities, inventory purchases, or overhead expenses.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final exp = list[index];
                      final methodIcon = PaymentMethodHelper.getIcon(exp.paymentMethod);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () => _showExpenseDetails(exp),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    methodIcon,
                                    color: AppTheme.error,
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
                                              exp.category,
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
                                              color: AppTheme.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  methodIcon,
                                                  size: 11,
                                                  color: AppTheme.error,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  exp.paymentMethod,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (exp.description.isNotEmpty)
                                        Text(
                                          exp.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.disabledColor,
                                          ),
                                        ),
                                      Text(
                                        DateFormat.yMMMd().format(exp.date),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.disabledColor,
                                        ),
                                      ),
                                      Text(
                                        'Added By: ${(exp.createdByName != null && exp.createdByName!.trim().isNotEmpty) ? exp.createdByName : 'Unknown'}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.disabledColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-${CurrencyFormatter.format(exp.amount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showExpenseForm(expense: exp),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: () => _confirmDelete(exp),
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
