import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/customers/domain/entities/customer_entity.dart';
import 'package:bizos/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:bizos/features/customers/presentation/widgets/customer_form_dialog.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerEntity customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(
      FetchCustomerSummaryEvent(widget.customer.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CustomerFormDialog(
                  businessId: widget.customer.businessId,
                  customer: widget.customer,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          double totalInvoiced = 0.0;
          double totalPaid = 0.0;
          double totalOutstanding = 0.0;
          int invoiceCount = 0;

          if (state is CustomerSummaryLoaded) {
            totalInvoiced =
                (state.summary['totalInvoiced'] as num?)?.toDouble() ?? 0.0;
            totalPaid = (state.summary['totalPaid'] as num?)?.toDouble() ?? 0.0;
            totalOutstanding =
                (state.summary['totalOutstanding'] as num?)?.toDouble() ?? 0.0;
            invoiceCount = (state.summary['invoiceCount'] as int?) ?? 0;
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CustomerBloc>().add(
                FetchCustomerSummaryEvent(widget.customer.id),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Info Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              widget.customer.name.isNotEmpty
                                  ? widget.customer.name[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontSize: 20,
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
                                  widget.customer.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (widget.customer.gstin.isNotEmpty)
                                  Text(
                                    'GSTIN: ${widget.customer.gstin}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (widget.customer.phone.isNotEmpty)
                        _buildContactRow(
                          Icons.phone_outlined,
                          widget.customer.phone,
                        ),
                      if (widget.customer.email.isNotEmpty)
                        _buildContactRow(
                          Icons.email_outlined,
                          widget.customer.email,
                        ),
                      if (widget.customer.address.isNotEmpty)
                        _buildContactRow(
                          Icons.location_on_outlined,
                          widget.customer.address,
                        ),
                      if (widget.customer.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes: ${widget.customer.notes}',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Financial Summary Cards
                Text(
                  'Financial Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  context,
                                  title: 'Total Invoiced',
                                  value: CurrencyFormatter.format(
                                    totalInvoiced,
                                  ),
                                  icon: Icons.receipt_long_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildKpiCard(
                                  context,
                                  title: 'Total Paid',
                                  value: CurrencyFormatter.format(totalPaid),
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildKpiCard(
                                  context,
                                  title: 'Total Outstanding',
                                  value: CurrencyFormatter.format(
                                    totalOutstanding,
                                  ),
                                  icon: Icons.pending_actions_outlined,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildKpiCard(
                                context,
                                title: 'Total Invoiced',
                                value: CurrencyFormatter.format(totalInvoiced),
                                icon: Icons.receipt_long_outlined,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 10),
                              _buildKpiCard(
                                context,
                                title: 'Total Paid',
                                value: CurrencyFormatter.format(totalPaid),
                                icon: Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 10),
                              _buildKpiCard(
                                context,
                                title: 'Total Outstanding',
                                value: CurrencyFormatter.format(
                                  totalOutstanding,
                                ),
                                icon: Icons.pending_actions_outlined,
                                color: Colors.orange,
                              ),
                            ],
                          );
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Invoice Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Invoices Issued',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Chip(
                        label: Text(
                          '$invoiceCount Invoices',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
