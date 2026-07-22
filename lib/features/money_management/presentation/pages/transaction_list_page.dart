import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_state.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/pages/add_transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to permanently delete this transaction records? This action cannot be undone.',
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
      final allList = widget.transactionType == 'pay'
          ? state.payTransactions
          : state.receiveTransactions;

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

      final typeLabel = widget.transactionType == 'pay'
          ? 'Money to Pay'
          : 'Money to Receive';

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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
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
                                      if (val == 'edit') {
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
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 16),
                                            SizedBox(width: 8),
                                            Text('Edit'),
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
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tx.phone,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
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
                                    'Total',
                                    CurrencyFormatter.format(tx.amount),
                                  ),
                                  _buildDetailItem(
                                    'Paid',
                                    CurrencyFormatter.format(tx.paidAmount),
                                    color: AppTheme.success,
                                  ),
                                  _buildDetailItem(
                                    'Balance',
                                    CurrencyFormatter.format(tx.balanceAmount),
                                    color: isPending
                                        ? AppTheme.error
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Due: ${tx.dueDate != null ? DateFormat.yMMMd().add_jm().format(tx.dueDate!) : 'N/A'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  if (tx.notes.isNotEmpty)
                                    Tooltip(
                                      message: tx.notes,
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.notes_outlined,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Notes',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
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
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
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
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
      body: widget.businessId != null
          ? BlocBuilder<BusinessMoneyManagementBloc, MoneyManagementState>(
              builder: (context, state) => _buildBody(context, state),
            )
          : BlocBuilder<PersonalMoneyManagementBloc, MoneyManagementState>(
              builder: (context, state) => _buildBody(context, state),
            ),
    );
  }
}
