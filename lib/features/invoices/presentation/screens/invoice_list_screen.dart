import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/core/widgets/error_state.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:bizos/features/invoices/presentation/screens/invoice_create_edit_screen.dart';
import 'package:bizos/features/invoices/presentation/screens/invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  final String businessId;
  final bool showAppBar;

  const InvoiceListScreen({
    super.key,
    required this.businessId,
    this.showAppBar = true,
  });

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusTabs = [
    {'id': 'all', 'label': 'All'},
    {'id': 'draft', 'label': 'Draft'},
    {'id': 'sent', 'label': 'Sent'},
    {'id': 'partially_paid', 'label': 'Partially Paid'},
    {'id': 'paid', 'label': 'Paid'},
    {'id': 'overdue', 'label': 'Overdue'},
    {'id': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedStatus = _statusTabs[_tabController.index]['id']!;
      });
      _fetchInvoices();
    });
    _fetchInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchInvoices() {
    context.read<InvoiceBloc>().add(
          FetchInvoicesEvent(
            businessId: widget.businessId,
            statusFilter: _selectedStatus,
            searchQuery: _searchController.text.trim(),
          ),
        );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchInvoices();
    });
  }

  void _openCreateInvoiceScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceCreateEditScreen(businessId: widget.businessId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Invoices'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header & Create Invoice Action
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by invoice #, customer name, phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _fetchInvoices();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openCreateInvoiceScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.post_add_outlined, size: 18),
                  label: const Text(
                    'Create Invoice',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status Filter Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _statusTabs.map((t) => Tab(text: t['label'])).toList(),
            ),
            const SizedBox(height: 14),

            // Invoice List View
            Expanded(
              child: BlocConsumer<InvoiceBloc, InvoiceState>(
                listener: (context, state) {
                  if (state is InvoiceActionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is InvoiceLoading && state is! InvoiceLoaded) {
                    return const SkeletonListLoader(itemCount: 6, itemHeight: 80);
                  } else if (state is InvoiceError) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () => _fetchInvoices(),
                    );
                  } else if (state is InvoiceLoaded) {
                    final invoices = state.invoices;
                    if (invoices.isEmpty) {
                      return EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Invoices Found',
                        message: _searchController.text.isNotEmpty
                            ? 'No invoices match your search or filter criteria.'
                            : 'Create and issue your first invoice.',
                        actionLabel: 'Create Invoice',
                        onActionPressed: _openCreateInvoiceScreen,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _fetchInvoices(),
                      child: ListView.separated(
                        itemCount: invoices.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return _buildInvoiceTile(context, invoice);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceTile(BuildContext context, InvoiceEntity invoice) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(invoice.status).withValues(alpha: 0.12),
          child: Icon(
            Icons.receipt_outlined,
            color: _getStatusColor(invoice.status),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '#${invoice.invoiceNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              CurrencyFormatter.format(invoice.grandTotal),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.customerNameSnapshot,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    'Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              _buildStatusBadge(invoice.status, invoice.paymentStatus),
            ],
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildStatusBadge(String status, String paymentStatus) {
    final s = status.toLowerCase();
    final color = _getStatusColor(s);
    String label = status.toUpperCase();

    if (s == 'partially_paid') label = 'PARTIAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
