import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';

import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/presentation/widgets/income_form_sheet.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/utils/currency_formatter.dart';

class IncomeTab extends StatefulWidget {
  final String businessId;
  final UserModel user;

  const IncomeTab({super.key, required this.businessId, required this.user});

  @override
  State<IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<IncomeTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
            FetchFinanceDataEvent(widget.businessId),
          );
        },
      ),
    );
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
        onPressed: () => _showIncomeForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
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
              label: 'Search Income',
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
                                backgroundColor: AppTheme.success.withOpacity(
                                  0.1,
                                ),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  color: AppTheme.success,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inc.category,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
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
