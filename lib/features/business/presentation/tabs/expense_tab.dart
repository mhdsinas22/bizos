import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/presentation/widgets/expense_form_sheet.dart';
import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/utils/currency_formatter.dart';

class ExpenseTab extends StatefulWidget {
  final String businessId;
  final UserModel user;

  const ExpenseTab({super.key, required this.businessId, required this.user});

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<ExpenseTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
            FetchFinanceDataEvent(widget.businessId),
          );
        },
      ),
    );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search Expenses',
              hint: 'Search category or description...',
              prefixIcon: Icons.search,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              validator: null,
              onTap: null,
              readOnly: false,
              keyboardType: TextInputType.text,
              maxLines: 1,
            ),
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.error.withOpacity(
                                  0.1,
                                ),
                                child: const Icon(
                                  Icons.arrow_downward,
                                  color: AppTheme.error,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exp.category,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
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
