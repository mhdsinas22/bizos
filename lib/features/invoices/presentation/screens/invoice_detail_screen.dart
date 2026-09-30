import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/utils/invoice_pdf_generator.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/features/invoice_payments/presentation/bloc/invoice_payment_bloc.dart';
import 'package:bizos/features/invoice_payments/presentation/widgets/record_payment_dialog.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';
import 'package:bizos/features/invoice_settings/presentation/bloc/invoice_settings_bloc.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:bizos/features/invoices/presentation/screens/invoice_create_edit_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceEntity invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InvoicePaymentBloc>().add(
      FetchPaymentsForInvoiceEvent(widget.invoice.id),
    );
    context.read<InvoiceSettingsBloc>().add(
      FetchInvoiceSettingsEvent(widget.invoice.businessId),
    );
  }

  void _openRecordPaymentDialog(InvoiceEntity currentInvoice) {
    showDialog(
      context: context,
      builder: (_) => RecordPaymentDialog(invoice: currentInvoice),
    );
  }

  void _printOrDownloadPdf(
    InvoiceEntity invoice,
    InvoiceSettingsEntity settings,
  ) {
    InvoicePdfGenerator.printOrDownloadPdf(
      invoice: invoice,
      settings: settings,
    );
  }

  void _sharePdf(InvoiceEntity invoice, InvoiceSettingsEntity settings) {
    InvoicePdfGenerator.sharePdf(invoice: invoice, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        InvoiceEntity currentInvoice = widget.invoice;
        if (state is InvoiceDetailLoaded) {
          currentInvoice = state.invoice;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Invoice #${currentInvoice.invoiceNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Native Share PDF',
                onPressed: () {
                  final settingsState = context
                      .read<InvoiceSettingsBloc>()
                      .state;
                  InvoiceSettingsEntity settings = InvoiceSettingsEntity(
                    id: '',
                    businessId: currentInvoice.businessId,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  if (settingsState is InvoiceSettingsLoaded) {
                    settings = settingsState.settings;
                  }
                  _sharePdf(currentInvoice, settings);
                },
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Print / Save PDF',
                onPressed: () {
                  final settingsState = context
                      .read<InvoiceSettingsBloc>()
                      .state;
                  InvoiceSettingsEntity settings = InvoiceSettingsEntity(
                    id: '',
                    businessId: currentInvoice.businessId,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  if (settingsState is InvoiceSettingsLoaded) {
                    settings = settingsState.settings;
                  }
                  _printOrDownloadPdf(currentInvoice, settings);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Invoice',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InvoiceCreateEditScreen(
                        businessId: currentInvoice.businessId,
                        invoice: currentInvoice,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Banner Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice #${currentInvoice.invoiceNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Billed To: ${currentInvoice.customerNameSnapshot}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusChip(
                      currentInvoice.status,
                      currentInvoice.paymentStatus,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Key Totals KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildAmountTile(
                      'Total Amount',
                      CurrencyFormatter.format(currentInvoice.grandTotal),
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAmountTile(
                      'Amount Paid',
                      CurrencyFormatter.format(currentInvoice.paidAmount),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAmountTile(
                      'Balance Due',
                      CurrencyFormatter.format(currentInvoice.balanceAmount),
                      currentInvoice.balanceAmount > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons Row (Record Payment, Share, Download)
              Row(
                children: [
                  if (currentInvoice.balanceAmount > 0 &&
                      !currentInvoice.isCancelled)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _openRecordPaymentDialog(currentInvoice),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text(
                          'Record Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Line Items Section
              Text(
                'Line Items (${currentInvoice.items.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentInvoice.items.length,
                  separatorBuilder: (_, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = currentInvoice.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (item.description.isNotEmpty)
                                  Text(
                                    item.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              CurrencyFormatter.format(item.lineTotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Payment History Section
              Text(
                'Payment History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              BlocBuilder<InvoicePaymentBloc, InvoicePaymentState>(
                builder: (context, payState) {
                  if (payState is InvoicePaymentLoading) {
                    return const SkeletonListLoader(
                      itemCount: 2,
                      itemHeight: 60,
                    );
                  } else if (payState is InvoicePaymentLoaded) {
                    final payments = payState.payments;
                    if (payments.isEmpty) {
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: const Center(
                          child: Text(
                            'No payment records found for this invoice.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      );
                    }

                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        separatorBuilder: (_, e) => const Divider(),
                        itemBuilder: (context, index) {
                          final pay = payments[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 16,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              CurrencyFormatter.format(pay.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            subtitle: Text(
                              '${pay.paymentMethod} • ${pay.paymentDate.day}/${pay.paymentDate.month}/${pay.paymentDate.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.error,
                                size: 18,
                              ),
                              onPressed: () {
                                context.read<InvoicePaymentBloc>().add(
                                  DeleteInvoicePaymentEvent(
                                    paymentId: pay.id,
                                    invoiceId: currentInvoice.id,
                                    businessId: currentInvoice.businessId,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, String paymentStatus) {
    final s = status.toLowerCase();
    Color chipColor;
    String label;

    if (s == 'paid' || paymentStatus.toLowerCase() == 'paid') {
      chipColor = Colors.green;
      label = 'PAID';
    } else if (s == 'partially_paid' ||
        paymentStatus.toLowerCase() == 'partially_paid') {
      chipColor = Colors.orange;
      label = 'PARTIALLY PAID';
    } else if (s == 'cancelled') {
      chipColor = Colors.grey;
      label = 'CANCELLED';
    } else if (s == 'overdue') {
      chipColor = Colors.red;
      label = 'OVERDUE';
    } else {
      chipColor = Colors.blue;
      label = 'SENT';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildAmountTile(String title, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
