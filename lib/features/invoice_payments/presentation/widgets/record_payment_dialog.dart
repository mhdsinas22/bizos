import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/invoice_payments/domain/entities/invoice_payment_entity.dart';
import 'package:bizos/features/invoice_payments/presentation/bloc/invoice_payment_bloc.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';

class RecordPaymentDialog extends StatefulWidget {
  final InvoiceEntity invoice;

  const RecordPaymentDialog({super.key, required this.invoice});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;

  String _selectedPaymentMethod = 'Cash';
  DateTime _paymentDate = DateTime.now();

  final List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Credit Card',
    'Debit Card',
    'Cheque',
    'Wallet',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.balanceAmount > 0
          ? widget.invoice.balanceAmount.toStringAsFixed(2)
          : '',
    );
    _referenceController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    final payment = InvoicePaymentEntity(
      id: '',
      invoiceId: widget.invoice.id,
      businessId: widget.invoice.businessId,
      amount: amount,
      paymentDate: _paymentDate,
      paymentMethod: _selectedPaymentMethod,
      referenceNumber: _referenceController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    context.read<InvoicePaymentBloc>().add(RecordInvoicePaymentEvent(payment));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record Payment for #${widget.invoice.invoiceNumber}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Balance Due: ${CurrencyFormatter.format(widget.invoice.balanceAmount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount (₹) *',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Enter a valid positive amount';
                    }
                    if (numVal > (widget.invoice.balanceAmount + 0.01)) {
                      return 'Cannot exceed balance due (₹${widget.invoice.balanceAmount})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method *',
                    prefixIcon: const Icon(Icons.payment_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _paymentMethods.map((pm) {
                    return DropdownMenuItem(value: pm, child: Text(pm));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPaymentMethod = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Payment Date',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _paymentDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: 'Transaction / Reference No.',
                    hintText: 'e.g. UPI Ref, Cheque No, Bank Txn ID',
                    prefixIcon: const Icon(Icons.tag_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
}
