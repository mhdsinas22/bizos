import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_event.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_state.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/add_expense_dialog.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/expense_card.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/analytics/expense_filter_bar.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/analytics/expense_pie_chart.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/analytics/expense_search_bar.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/analytics/expense_summary_card.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_state.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalExpensePage extends StatefulWidget {
  const PersonalExpensePage({super.key});

  @override
  State<PersonalExpensePage> createState() => _PersonalExpensePageState();
}

class _PersonalExpensePageState extends State<PersonalExpensePage> {
  String? _pendingAction;
  PersonalExpenseLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      if (userId.isNotEmpty) {
        setState(() {
          _pendingAction = 'load';
        });
        context.read<PersonalExpenseBloc>().add(LoadPersonalExpenses(userId));
      }
    });
  }

  void _showAddExpenseDialog(BuildContext context, {PersonalExpenseEntity? expense}) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddExpenseDialog(
        expense: expense,
        onSave: (amount, category, description, date) {
          if (expense != null) {
            // Edit
            final updatedExpense = PersonalExpenseEntity(
              id: expense.id,
              ownerId: userId,
              amount: amount,
              category: category,
              description: description,
              expenseDate: date,
              createdAt: expense.createdAt,
            );
            setState(() {
              _pendingAction = 'update';
            });
            context.read<PersonalExpenseBloc>().add(
              UpdatePersonalExpense(updatedExpense, userId),
            );
          } else {
            // Add
            final newExpense = PersonalExpenseEntity(
              id: '',
              ownerId: userId,
              amount: amount,
              category: category,
              description: description,
              expenseDate: date,
              createdAt: DateTime.now(),
            );
            setState(() {
              _pendingAction = 'add';
            });
            context.read<PersonalExpenseBloc>().add(
              AddPersonalExpense(newExpense, userId),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<PersonalExpenseBloc, PersonalExpenseState>(
        listener: (context, state) {
          if (state is PersonalExpenseLoaded) {
            if (_pendingAction == 'add') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Personal expense saved successfully'),
                  backgroundColor: AppTheme.success,
                ),
              );
            } else if (_pendingAction == 'update') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Personal expense updated successfully'),
                  backgroundColor: AppTheme.success,
                ),
              );
            } else if (_pendingAction == 'delete') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted successfully'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
            _pendingAction = null;
          } else if (state is PersonalExpenseError) {
            if (_pendingAction != 'load') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
            _pendingAction = null;
          }
        },
        child: BlocBuilder<PersonalExpenseBloc, PersonalExpenseState>(
          builder: (context, state) {
            final authState = context.read<AuthBloc>().state;
            final userId = authState.user?.id ?? '';

            if (state is PersonalExpenseLoaded) {
              _lastLoadedState = state;
            }

            // Show error state only if we have no loaded expenses
            if (state is PersonalExpenseError && _lastLoadedState == null) {
              return RefreshIndicator(
                onRefresh: () async {
                  if (userId.isNotEmpty) {
                    setState(() {
                      _pendingAction = 'load';
                    });
                    context.read<PersonalExpenseBloc>().add(LoadPersonalExpenses(userId));
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load expenses',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (userId.isNotEmpty) {
                                    setState(() {
                                      _pendingAction = 'load';
                                    });
                                    context.read<PersonalExpenseBloc>().add(LoadPersonalExpenses(userId));
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show loading state if we have no cached data
            if ((state is PersonalExpenseLoading || state is PersonalExpenseInitial) && _lastLoadedState == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final displayState = _lastLoadedState;
            if (displayState == null) {
              return const SizedBox.shrink();
            }

            final expenses = displayState.filteredExpenses;

            return RefreshIndicator(
              onRefresh: () async {
                if (userId.isNotEmpty) {
                  setState(() {
                    _pendingAction = 'load';
                  });
                  context.read<PersonalExpenseBloc>().add(LoadPersonalExpenses(userId));
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Summary cards grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: BlocBuilder<PersonalMoneyManagementBloc, MoneyManagementState>(
                        builder: (context, mmState) {
                          double pendingPay = 0.0;
                          double pendingReceive = 0.0;
                          if (mmState is TransactionsLoaded) {
                            pendingPay = mmState.totalPendingPay;
                            pendingReceive = mmState.totalPendingReceive;
                          }

                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              ExpenseSummaryCard(
                                title: 'Total Expenses',
                                value: displayState.totalExpense,
                                icon: Icons.account_balance_wallet,
                                color: AppTheme.primaryColor,
                              ),
                              ExpenseSummaryCard(
                                title: 'This Month',
                                value: displayState.monthlyExpense,
                                icon: Icons.calendar_today,
                                color: AppTheme.accentColor,
                              ),
                              ExpenseSummaryCard(
                                title: 'Today Expenses',
                                value: displayState.todayExpense,
                                icon: Icons.today,
                                color: Colors.green,
                              ),
                              ExpenseSummaryCard(
                                title: 'Highest Category',
                                value: displayState.highestCategory,
                                icon: Icons.trending_up,
                                color: Colors.orange,
                                isCurrency: false,
                              ),
                              ExpenseSummaryCard(
                                title: 'Money to Pay',
                                value: pendingPay,
                                icon: Icons.outbox_outlined,
                                color: AppTheme.error,
                              ),
                              ExpenseSummaryCard(
                                title: 'Money to Receive',
                                value: pendingReceive,
                                icon: Icons.inbox_outlined,
                                color: AppTheme.accentColor,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Animated Pie Chart
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: ExpensePieChart(
                        categoryAnalytics: displayState.categoryAnalytics,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Filter Chips
                  SliverToBoxAdapter(
                    child: ExpenseFilterBar(
                      selectedFilter: displayState.currentFilter,
                      customStartDate: displayState.customStartDate,
                      customEndDate: displayState.customEndDate,
                      onFilterChanged: (filterType) {
                        if (userId.isNotEmpty) {
                          context.read<PersonalExpenseBloc>().add(
                            FilterPersonalExpenses(
                              filterType: filterType,
                              userId: userId,
                            ),
                          );
                        }
                      },
                      onCustomRangeSelected: (start, end) {
                        if (userId.isNotEmpty) {
                          context.read<PersonalExpenseBloc>().add(
                            FilterPersonalExpenses(
                              filterType: 'custom',
                              startDate: start,
                              endDate: end,
                              userId: userId,
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Search and Sort Row
                  SliverToBoxAdapter(
                    child: ExpenseSearchBar(
                      searchQuery: displayState.searchQuery,
                      selectedSort: displayState.currentSort,
                      onSearchChanged: (query) {
                        context.read<PersonalExpenseBloc>().add(SearchPersonalExpenses(query));
                      },
                      onSortChanged: (sortBy) {
                        context.read<PersonalExpenseBloc>().add(SortPersonalExpenses(sortBy));
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Expense List Header
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Recent Expenses (${expenses.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Expense List
                  if (expenses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Expenses Logged',
                        message:
                            'Keep track of your personal outlays separately from your business accounts.',
                        actionLabel: 'Log Your First Expense',
                        onActionPressed: () => _showAddExpenseDialog(context),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final expense = expenses[index];
                            return ExpenseCard(
                              expense: expense,
                              onEdit: () => _showAddExpenseDialog(context, expense: expense),
                              onDelete: () {
                                setState(() {
                                  _pendingAction = 'delete';
                                });
                                context.read<PersonalExpenseBloc>().add(
                                  DeletePersonalExpense(expense.id, userId),
                                );
                              },
                            );
                          },
                          childCount: expenses.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
