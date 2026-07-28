import 'dart:async';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/money_management/domain/entities/debt_entity.dart';
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
import 'package:bizos/features/money_management/presentation/utils/transaction_event_mapper.dart';
import 'package:bizos/features/money_management/presentation/widgets/add_debt_modal.dart';
import 'package:bizos/features/money_management/presentation/widgets/add_payment_modal.dart';
import 'package:bizos/features/money_management/presentation/widgets/history_skeleton_loader.dart';
import 'package:bizos/features/money_management/presentation/widgets/timeline_bottom_sheet_widget.dart';
import 'package:bizos/features/money_management/presentation/widgets/timeline_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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

  List<String> get _filters => TransactionEventMapper.getFilterOptions(
        transactionType: _currentTransaction.transactionType,
      );

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
        filterEventType: TransactionEventMapper.mapFilterToEventType(_selectedFilter),
        searchQuery: _searchController.text.trim(),
        ascending: _ascending,
      ),
    );
  }

  // Future<void> _makeCall() async {
  //   final cleanPhone = _currentTransaction.phone.replaceAll(
  //     RegExp(r'[^0-9+]'),
  //     '',
  //   );
  //   if (cleanPhone.isEmpty) return;
  //   final uri = Uri.parse('tel:$cleanPhone');
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri);
  //   }
  // }

  // Future<void> _sendWhatsApp() async {
  //   final cleanPhone = _currentTransaction.phone.replaceAll(
  //     RegExp(r'[^0-9+]'),
  //     '',
  //   );
  //   if (cleanPhone.isEmpty) return;
  //   final text =
  //       'Hi ${_currentTransaction.personName}, regarding account balance ₹${_currentTransaction.balanceAmount.toStringAsFixed(2)}. Thank you!';
  //   final uri = Uri.parse(
  //     'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}',
  //   );
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   }
  // }

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

  void _openAddDebt() {
    final detailsBloc = context.read<TransactionDetailsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddDebtModal(
        transactionId: _currentTransaction.id,
        personName: _currentTransaction.personName,
        phone: _currentTransaction.phone,
        transactionType: _currentTransaction.transactionType,
        isPersonal: widget.isPersonal,
        userId: _currentTransaction.userId,
        businessId: _currentTransaction.businessId,
        onSave: (amount, dueDate, notes) async {
          final now = DateTime.now();
          final debt = DebtEntity(
            transactionId: _currentTransaction.id,
            userId: _currentTransaction.userId,
            businessId: _currentTransaction.businessId,
            transactionType: _currentTransaction.transactionType,
            personName: _currentTransaction.personName,
            phone: _currentTransaction.phone,
            amount: amount,
            paidAmount: 0.0,
            balanceAmount: amount,
            dueDate: dueDate,
            notes: notes,
            status: 'Pending',
            createdAt: now,
            updatedAt: now,
          );

          final completer = Completer<void>();
          late StreamSubscription sub;

          sub = detailsBloc.stream.listen((state) {
            if (state is DebtAddedSuccess) {
              sub.cancel();
              completer.complete();
            } else if (state is TransactionDetailsError) {
              sub.cancel();
              completer.completeError(Exception(state.message));
            }
          });

          detailsBloc.add(
            AddDebtEvent(
              debt: debt,
              isPersonal: widget.isPersonal,
            ),
          );

          try {
            await completer.future;
            _loadHistory(isRefresh: true);
          } finally {
            sub.cancel();
          }
        },
      ),
    );
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
        transactionType: _currentTransaction.transactionType,
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
    List<MoneyTransactionHistoryEntity> items,
  ) {
    final Map<String, List<MoneyTransactionHistoryEntity>> grouped = {};
    for (final item in items) {
      final dateKey = DateFormat(
        'dd MMMM yyyy',
      ).format(item.createdAt.toLocal());
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isPay = _currentTransaction.transactionType == 'pay';
    final typeTitle = isPay ? 'Money to Pay' : 'Money to Receive';
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 10.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(typeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isPay ? 'Edit Customer/Debt' : 'Edit Customer/Receivable',
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
                final match = state.transactions
                    .where((t) => t.id == _currentTransaction.id)
                    .firstOrNull;
                if (match != null) {
                  setState(() => _currentTransaction = match);
                }
              }
            },
          ),
          BlocListener<BusinessMoneyManagementBloc, MoneyManagementState>(
            listener: (context, state) {
              if (!widget.isPersonal && state is TransactionsLoaded) {
                final match = state.transactions
                    .where((t) => t.id == _currentTransaction.id)
                    .firstOrNull;
                if (match != null) {
                  setState(() => _currentTransaction = match);
                }
              }
            },
          ),
          BlocListener<TransactionDetailsBloc, TransactionDetailsState>(
            listener: (context, state) {
              if (state is TransactionHistoryLoaded && state.parentTransaction != null) {
                setState(() {
                  _currentTransaction = state.parentTransaction!;
                });
              } else if (state is TransactionDetailsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
          ),
        ],
        child: RefreshIndicator(
          onRefresh: () async => _loadHistory(isRefresh: true),
          child: ResponsiveCenterBody(
            maxWidth: 1100,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Customer Name + Phone + Actions
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isPay
                      ? AppTheme.error.withOpacity(0.15)
                      : AppTheme.success.withOpacity(0.15),
                  child: Text(
                    _currentTransaction.personName.isNotEmpty
                        ? _currentTransaction.personName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPay ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTransaction.personName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentTransaction.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _currentTransaction.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _currentTransaction.status.toLowerCase() == 'completed'
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentTransaction.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          _currentTransaction.status.toLowerCase() == 'completed'
                              ? AppTheme.success
                              : AppTheme.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Hero Outstanding Balance / Amount to Receive
            Text(
              TransactionEventMapper.getHeroBalanceLabel(
                transactionType: _currentTransaction.transactionType,
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.format(_currentTransaction.balanceAmount),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: _currentTransaction.balanceAmount > 0
                      ? (isPay ? AppTheme.error : AppTheme.success)
                      : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stat Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    context,
                    TransactionEventMapper.getTotalAmountLabel(
                      transactionType: _currentTransaction.transactionType,
                    ),
                    CurrencyFormatter.format(_currentTransaction.amount),
                    Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatTile(
                    context,
                    TransactionEventMapper.getPaidAmountLabel(
                      transactionType: _currentTransaction.transactionType,
                    ),
                    CurrencyFormatter.format(_currentTransaction.paidAmount),
                    Icons.check_circle_outline,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatTile(
                    context,
                    'Due Date',
                    _currentTransaction.dueDate != null
                        ? DateFormat('dd MMM yyyy').format(_currentTransaction.dueDate!)
                        : 'No Due',
                    Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Quick Action Buttons
            LayoutBuilder(
              builder: (context, actionConstraints) {
                final primaryLabel = TransactionEventMapper.getAddTransactionLabel(
                  transactionType: _currentTransaction.transactionType,
                );
                final secondaryLabel = TransactionEventMapper.getPaymentActionLabel(
                  transactionType: _currentTransaction.transactionType,
                );

                // Stack vertically if container width is too narrow (< 340px)
                final shouldStack = actionConstraints.maxWidth < 340;

                Widget buildActionButton({
                  required VoidCallback onPressed,
                  required IconData icon,
                  required String label,
                  required Color color,
                }) {
                  return SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: onPressed,
                      icon: Icon(icon, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                }

                final btnPrimary = buildActionButton(
                  onPressed: _openAddDebt,
                  icon: Icons.receipt_long_outlined,
                  label: primaryLabel,
                  color: AppTheme.primaryColor,
                );

                final btnSecondary = buildActionButton(
                  onPressed: _openAddPayment,
                  icon: Icons.add_card,
                  label: secondaryLabel,
                  color: Colors.green,
                );

                if (shouldStack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      btnPrimary,
                      const SizedBox(height: 8),
                      btnSecondary,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: btnPrimary),
                    const SizedBox(width: 8),
                    Expanded(child: btnSecondary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
            Expanded(
              child: Text(
                'Transaction History Timeline',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
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
          physics: const BouncingScrollPhysics(),
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
                    color: isSelected
                        ? AppTheme.primaryColor
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
                message:
                    'No timeline records match your search or filter selection.',
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color ?? Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

