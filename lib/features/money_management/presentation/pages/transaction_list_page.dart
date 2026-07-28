import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';
import 'package:bizos/features/money_management/domain/usecases/add_adjustment_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_debt_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_payment_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_reminder_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/delete_history_item_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/get_transaction_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/share_transaction_statement_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/update_history_item_usecase.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_state.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/transaction_details_bloc.dart';
import 'package:bizos/features/money_management/presentation/pages/add_transaction_page.dart';
import 'package:bizos/features/money_management/presentation/pages/transaction_details_page.dart';
import 'package:bizos/features/money_management/presentation/utils/transaction_event_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class TransactionListPage extends StatefulWidget {
  final String transactionType; // 'pay' or 'receive'
  final String? businessId; // null for personal

  const TransactionListPage({
    super.key,
    required this.transactionType,
    this.businessId,
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Pending', 'Completed'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetails(BuildContext context, MoneyTransactionEntity tx) {
    final repository = context.read<MoneyManagementRepository>();
    final isPersonal = widget.businessId == null;

    final personalBloc = isPersonal
        ? context.read<PersonalMoneyManagementBloc>()
        : null;
    final businessBloc = !isPersonal
        ? context.read<BusinessMoneyManagementBloc>()
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            if (isPersonal && personalBloc != null)
              BlocProvider.value(value: personalBloc),
            if (!isPersonal && businessBloc != null)
              BlocProvider.value(value: businessBloc),
            BlocProvider(
              create: (context) => TransactionDetailsBloc(
                getTransactionHistoryUseCase: GetTransactionHistoryUseCase(
                  repository,
                ),
                getTransactionByIdUseCase: GetTransactionByIdUseCase(
                  repository,
                ),
                addPaymentHistoryUseCase: AddPaymentHistoryUseCase(repository),
                addAdjustmentHistoryUseCase: AddAdjustmentHistoryUseCase(
                  repository,
                ),
                addReminderHistoryUseCase: AddReminderHistoryUseCase(
                  repository,
                ),
                updateHistoryItemUseCase: UpdateHistoryItemUseCase(repository),
                deleteHistoryItemUseCase: DeleteHistoryItemUseCase(repository),
                addDebtUseCase: AddDebtUseCase(repository),
              ),
            ),
          ],
          child: TransactionDetailsPage(
            transaction: tx,
            isPersonal: isPersonal,
          ),
        ),
      ),
    );
  }

  Future<void> _shareStatement(
    BuildContext context,
    MoneyTransactionEntity tx,
  ) async {
    try {
      final repository = context.read<MoneyManagementRepository>();
      final useCase = ShareTransactionStatementUseCase(repository);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating statement...'),
          duration: Duration(seconds: 1),
        ),
      );

      final statementText = await useCase.generateStatementText(
        transaction: tx,
        isPersonal: widget.businessId == null,
        appName: 'VORYN',
      );

      await Share.share(statementText);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating statement: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    if (id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid transaction ID. Please pull to refresh.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account Record?'),
        content: const Text(
          'Are you sure you want to permanently delete this customer transaction record and all associated history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final isPersonal = widget.businessId == null;
              if (isPersonal) {
                context.read<PersonalMoneyManagementBloc>().add(
                  DeleteTransactionEvent(id, isPersonal: true),
                );
              } else {
                context.read<BusinessMoneyManagementBloc>().add(
                  DeleteTransactionEvent(id, isPersonal: false),
                );
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted successfully'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, MoneyManagementState state) {
    if (state is TransactionsLoading || state is TransactionsInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TransactionsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading transactions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(state.message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (state is TransactionsLoaded) {
      final isPay = widget.transactionType == 'pay';
      final allList = isPay ? state.payTransactions : state.receiveTransactions;

      // Apply Search Filter
      var filteredList = allList.where((tx) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            tx.personName.toLowerCase().contains(query) ||
            tx.phone.toLowerCase().contains(query) ||
            tx.notes.toLowerCase().contains(query);

        final matchesStatus =
            _statusFilter == 'All' ||
            tx.status.toLowerCase() == _statusFilter.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
      filteredList.sort((a, b) {
        final aIsPending = a.status.toLowerCase() == 'pending';
        final bIsPending = b.status.toLowerCase() == 'pending';

        if (aIsPending && !bIsPending) {
          return -1; // 'a' (Pending) primary aayi mukhalil varum
        } else if (!aIsPending && bIsPending) {
          return 1; // 'b' (Pending) primary aayi mukhalil varum
        }

        // Render order based on latest due dates if both have same status
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }

        return 0;
      });
      final typeLabel = isPay ? 'Money to Pay' : 'Money to Receive';

      return ResponsiveCenterBody(
        child: Column(
          children: [
            // Search & Filter header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _statusFilter,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.filter_list),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _statusFilter = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: filteredList.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Records Found',
                      message: _searchQuery.isNotEmpty || _statusFilter != 'All'
                          ? 'No records match your search or filter options.'
                          : 'Keep track of your pending $typeLabel transactions here.',
                      actionLabel:
                          _searchQuery.isNotEmpty || _statusFilter != 'All'
                          ? null
                          : 'Add Transaction',
                      onActionPressed:
                          _searchQuery.isNotEmpty || _statusFilter != 'All'
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionPage(
                                  transactionType: widget.transactionType,
                                  businessId: widget.businessId,
                                ),
                              ),
                            ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = filteredList[index];
                        final isPending = tx.status.toLowerCase() == 'pending';

                        return GlassCard(
                          onTap: () => _navigateToDetails(context, tx),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tx.personName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? AppTheme.warning.withOpacity(0.12)
                                          : AppTheme.success.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tx.status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isPending
                                            ? AppTheme.warning
                                            : AppTheme.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'details') {
                                        _navigateToDetails(context, tx);
                                      } else if (val == 'share') {
                                        _shareStatement(context, tx);
                                      } else if (val == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddTransactionPage(
                                              transactionType:
                                                  widget.transactionType,
                                              businessId: widget.businessId,
                                              editTransaction: tx,
                                            ),
                                          ),
                                        );
                                      } else if (val == 'delete') {
                                        _confirmDelete(context, tx.id);
                                      }
                                    },
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'details',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.timeline_outlined,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text('History & Details'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'share',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.share_outlined,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Share Statement'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 16),
                                            SizedBox(width: 8),
                                            Text('Edit Customer'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: AppTheme.error,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: AppTheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (tx.phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tx.phone,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 2.2,
                                children: [
                                  _buildDetailItem(
                                    TransactionEventMapper.getTotalAmountLabel(
                                      transactionType: widget.transactionType,
                                    ),
                                    CurrencyFormatter.format(tx.amount),
                                  ),
                                  _buildDetailItem(
                                    TransactionEventMapper.getPaidAmountLabel(
                                      transactionType: widget.transactionType,
                                    ),
                                    CurrencyFormatter.format(tx.paidAmount),
                                    color: AppTheme.success,
                                  ),
                                  _buildDetailItem(
                                    TransactionEventMapper.getBalanceAmountLabel(
                                      transactionType: widget.transactionType,
                                    ),
                                    CurrencyFormatter.format(tx.balanceAmount),
                                    color: isPending
                                        ? (isPay
                                              ? AppTheme.error
                                              : AppTheme.success)
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final dueDateText = tx.dueDate != null
                                      ? DateFormat('dd MMM yyyy • h:mm a')
                                          .format(tx.dueDate!)
                                      : 'N/A';

                                  final dueDateWidget = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Due: $dueDateText',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );

                                  final actionWidget = InkWell(
                                    onTap: () =>
                                        _navigateToDetails(context, tx),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View History Timeline',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color:
                                                      AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  if (constraints.maxWidth < 340) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        dueDateWidget,
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: actionWidget,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: dueDateWidget),
                                      const SizedBox(width: 8),
                                      actionWidget,
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.transactionType == 'pay'
        ? 'Money to Pay'
        : 'Money to Receive';

    return Scaffold(
      appBar: AppBar(title: Text(typeLabel)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionPage(
              transactionType: widget.transactionType,
              businessId: widget.businessId,
            ),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          TransactionEventMapper.getAddTransactionLabel(
            transactionType: widget.transactionType,
          ),
        ),
      ),
      body: widget.businessId != null
          ? BlocBuilder<BusinessMoneyManagementBloc, MoneyManagementState>(
              buildWhen: (previous, current) {
                if (previous.runtimeType != current.runtimeType) return true;
                if (previous is TransactionsLoaded && current is TransactionsLoaded) {
                  return previous.transactions != current.transactions;
                }
                return true;
              },
              builder: (context, state) => _buildBody(context, state),
            )
          : BlocBuilder<PersonalMoneyManagementBloc, MoneyManagementState>(
              buildWhen: (previous, current) {
                if (previous.runtimeType != current.runtimeType) return true;
                if (previous is TransactionsLoaded && current is TransactionsLoaded) {
                  return previous.transactions != current.transactions;
                }
                return true;
              },
              builder: (context, state) => _buildBody(context, state),
            ),
    );
  }
}
