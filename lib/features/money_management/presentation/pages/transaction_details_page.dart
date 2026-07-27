import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';
import 'package:bizos/features/money_management/domain/usecases/share_transaction_statement_usecase.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_state.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/transaction_details_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/transaction_details_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/transaction_details_state.dart';
import 'package:bizos/features/money_management/presentation/pages/add_transaction_page.dart';
import 'package:bizos/features/money_management/presentation/widgets/add_adjustment_modal.dart';
import 'package:bizos/features/money_management/presentation/widgets/add_payment_modal.dart';
import 'package:bizos/features/money_management/presentation/widgets/add_reminder_modal.dart';
import 'package:bizos/features/money_management/presentation/widgets/history_skeleton_loader.dart';
import 'package:bizos/features/money_management/presentation/widgets/timeline_bottom_sheet_widget.dart';
import 'package:bizos/features/money_management/presentation/widgets/timeline_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionDetailsPage extends StatefulWidget {
  final MoneyTransactionEntity transaction;
  final bool isPersonal;

  const TransactionDetailsPage({
    super.key,
    required this.transaction,
    required this.isPersonal,
  });

  @override
  State<TransactionDetailsPage> createState() => _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _selectedFilter = 'All';
  bool _ascending = false;
  late MoneyTransactionEntity _currentTransaction;

  final List<String> _filters = [
    'All',
    'Payments',
    'Debt Created',
    'Adjustments',
    'Reminders',
    'Status',
  ];

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;

    _searchController.addListener(() {
      _loadHistory(isRefresh: true);
    });

    _scrollController.addListener(_onScroll);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory(isRefresh: false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionDetailsBloc>().add(
            LoadMoreHistoryEvent(
              transactionId: _currentTransaction.id,
              isPersonal: widget.isPersonal,
            ),
          );
    }
  }

  void _loadHistory({bool isRefresh = false}) {
    context.read<TransactionDetailsBloc>().add(
          LoadTransactionHistoryEvent(
            transactionId: _currentTransaction.id,
            isPersonal: widget.isPersonal,
            isRefresh: isRefresh,
            filterEventType: _selectedFilter,
            searchQuery: _searchController.text.trim(),
            ascending: _ascending,
          ),
        );
  }

  Future<void> _makeCall() async {
    final cleanPhone = _currentTransaction.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp() async {
    final cleanPhone = _currentTransaction.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final text = 'Hi ${_currentTransaction.personName}, regarding account balance ₹${_currentTransaction.balanceAmount.toStringAsFixed(2)}. Thank you!';
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareSummary() async {
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
        transaction: _currentTransaction,
        isPersonal: widget.isPersonal,
        appName: 'VORYN',
      );

      await Share.share(statementText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating statement: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _openAddPayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddPaymentModal(
        transactionId: _currentTransaction.id,
        isPersonal: widget.isPersonal,
        currentBalance: _currentTransaction.balanceAmount,
        onSave: (amount, method, notes) {
          context.read<TransactionDetailsBloc>().add(
                AddPaymentEvent(
                  transactionId: _currentTransaction.id,
                  amount: amount,
                  paymentMethod: method,
                  notes: notes,
                  isPersonal: widget.isPersonal,
                ),
              );
        },
      ),
    );
  }

  void _openAddAdjustment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddAdjustmentModal(
        transactionId: _currentTransaction.id,
        isPersonal: widget.isPersonal,
        onSave: (amount, notes) {
          context.read<TransactionDetailsBloc>().add(
                AddAdjustmentEvent(
                  transactionId: _currentTransaction.id,
                  amount: amount,
                  notes: notes,
                  isPersonal: widget.isPersonal,
                ),
              );
        },
      ),
    );
  }

  void _openAddReminder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddReminderModal(
        transactionId: _currentTransaction.id,
        personName: _currentTransaction.personName,
        phone: _currentTransaction.phone,
        balance: _currentTransaction.balanceAmount,
        transactionType: _currentTransaction.transactionType,
        isPersonal: widget.isPersonal,
        onSave: (notes) {
          context.read<TransactionDetailsBloc>().add(
                AddReminderEvent(
                  transactionId: _currentTransaction.id,
                  notes: notes,
                  isPersonal: widget.isPersonal,
                ),
              );
        },
      ),
    );
  }

  void _openTimelineItemDetails(MoneyTransactionHistoryEntity item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimelineBottomSheetWidget(
        historyItem: item,
        transactionType: _currentTransaction.transactionType,
        onEdit: (updated) {
          context.read<TransactionDetailsBloc>().add(
                UpdateHistoryItemEvent(
                  historyItem: updated,
                  isPersonal: widget.isPersonal,
                ),
              );
        },
        onDelete: () {
          context.read<TransactionDetailsBloc>().add(
                DeleteHistoryItemEvent(
                  historyId: item.id,
                  transactionId: _currentTransaction.id,
                  isPersonal: widget.isPersonal,
                ),
              );
        },
      ),
    );
  }

  Map<String, List<MoneyTransactionHistoryEntity>> _groupHistoryByDate(
      List<MoneyTransactionHistoryEntity> items) {
    final Map<String, List<MoneyTransactionHistoryEntity>> grouped = {};
    for (final item in items) {
      final dateKey = DateFormat('dd MMMM yyyy').format(item.createdAt.toLocal());
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isPay = _currentTransaction.transactionType == 'pay';
    final typeTitle = isPay ? 'Money to Pay' : 'Money to Receive';

    return Scaffold(
      appBar: AppBar(
        title: Text(typeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer/Debt',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionPage(
                    transactionType: _currentTransaction.transactionType,
                    businessId: _currentTransaction.businessId,
                    editTransaction: _currentTransaction,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Overview',
            onPressed: _shareSummary,
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PersonalMoneyManagementBloc, MoneyManagementState>(
            listener: (context, state) {
              if (widget.isPersonal && state is TransactionsLoaded) {
                final match = state.transactions.where((t) => t.id == _currentTransaction.id).firstOrNull;
                if (match != null) {
                  setState(() => _currentTransaction = match);
                }
              }
            },
          ),
          BlocListener<BusinessMoneyManagementBloc, MoneyManagementState>(
            listener: (context, state) {
              if (!widget.isPersonal && state is TransactionsLoaded) {
                final match = state.transactions.where((t) => t.id == _currentTransaction.id).firstOrNull;
                if (match != null) {
                  setState(() => _currentTransaction = match);
                }
              }
            },
          ),
        ],
        child: RefreshIndicator(
          onRefresh: () async => _loadHistory(isRefresh: true),
          child: ResponsiveCenterBody(
            maxWidth: 1100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;

                if (isWide) {
                  // Tablet/Desktop 2-Column Split Layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Customer Header Card, Stats & Actions
                      SizedBox(
                        width: 380,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCustomerHeaderCard(context),
                              const SizedBox(height: 16),
                              _buildActionStrip(context),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Column: Timeline Controls & List
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTimelineHeaderAndFilters(context),
                              const SizedBox(height: 16),
                              _buildTimelineContent(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Mobile Layout (Single Column Scroll)
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCustomerHeaderCard(context),
                      const SizedBox(height: 16),
                      _buildActionStrip(context),
                      const SizedBox(height: 20),
                      _buildTimelineHeaderAndFilters(context),
                      const SizedBox(height: 16),
                      _buildTimelineContent(context),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPay = _currentTransaction.transactionType == 'pay';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                child: Text(
                  _currentTransaction.personName.isNotEmpty
                      ? _currentTransaction.personName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTransaction.personName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentTransaction.phone.isNotEmpty)
                      Text(
                        _currentTransaction.phone,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentTransaction.status.toLowerCase() == 'completed'
                      ? AppTheme.success.withOpacity(0.15)
                      : AppTheme.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentTransaction.status,
                  style: TextStyle(
                    color: _currentTransaction.status.toLowerCase() == 'completed'
                        ? AppTheme.success
                        : AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          // Hero Outstanding Balance
          Text(
            'OUTSTANDING BALANCE',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(_currentTransaction.balanceAmount),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: _currentTransaction.balanceAmount > 0
                  ? (isPay ? AppTheme.error : AppTheme.success)
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          // Stat Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  context,
                  'Total Debt',
                  CurrencyFormatter.format(_currentTransaction.amount),
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  context,
                  'Paid Amount',
                  CurrencyFormatter.format(_currentTransaction.paidAmount),
                  Icons.check_circle_outline,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  context,
                  'Due Date',
                  _currentTransaction.dueDate != null
                      ? DateFormat('dd MMM').format(_currentTransaction.dueDate!)
                      : 'No Due',
                  Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Quick Action Buttons
          Row(
            children: [
              if (_currentTransaction.phone.isNotEmpty) ...[
                IconButton.filledTonal(
                  onPressed: _makeCall,
                  icon: const Icon(Icons.call),
                  tooltip: 'Call Customer',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _sendWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.green),
                  tooltip: 'WhatsApp',
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openAddPayment,
                  icon: const Icon(Icons.add_card),
                  label: const Text('Record Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionStrip(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openAddAdjustment,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Adjustment'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openAddReminder,
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: const Text('Log Reminder'),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHeaderAndFilters(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History Timeline',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
              tooltip: _ascending ? 'Oldest First' : 'Newest First',
              onPressed: () {
                setState(() => _ascending = !_ascending);
                _loadHistory(isRefresh: true);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search notes or payment details...',
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                      _loadHistory(isRefresh: true);
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<TransactionDetailsBloc, TransactionDetailsState>(
      builder: (context, state) {
        if (state is TransactionHistoryLoading) {
          return const HistorySkeletonLoader();
        }

        if (state is TransactionDetailsError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Error loading history: ${state.message}',
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          );
        }

        if (state is TransactionHistoryLoaded) {
          if (state.history.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: EmptyState(
                icon: Icons.history_toggle_off_outlined,
                title: 'No History Events Found',
                message: 'No timeline records match your search or filter selection.',
              ),
            );
          }

          final groupedMap = _groupHistoryByDate(state.history);

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groupedMap.keys.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == groupedMap.keys.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final dateKey = groupedMap.keys.elementAt(index);
              final itemsForDate = groupedMap[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                    child: Text(
                      dateKey,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  ...itemsForDate.map(
                    (item) => TimelineCardWidget(
                      historyItem: item,
                      transactionType: _currentTransaction.transactionType,
                      onTap: () => _openTimelineItemDetails(item),
                    ),
                  ),
                ],
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
