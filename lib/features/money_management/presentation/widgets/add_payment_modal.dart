import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class AddPaymentModal extends StatefulWidget {
  final String transactionId;
  final bool isPersonal;
  final double currentBalance;
  final Function(double amount, String paymentMethod, String notes) onSave;

  const AddPaymentModal({
    super.key,
    required this.transactionId,
    required this.isPersonal,
    required this.currentBalance,
    required this.onSave,
  });

  @override
  State<AddPaymentModal> createState() => _AddPaymentModalState();
}

class _AddPaymentModalState extends State<AddPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'GPay';

  final List<String> _paymentMethods = [
    'GPay',
    'PhonePe',
    'Cash',
    'Bank Transfer',
    'UPI',
    'Cheque',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final notes = _notesController.text.trim();

    widget.onSave(amount, _selectedMethod, notes);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record Payment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Payment Amount (₹)',
                  hintText: 'Enter amount (e.g. 2000)',
                  prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.success),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: TextButton(
                    onPressed: () {
                      _amountController.text = widget.currentBalance.toStringAsFixed(2);
                    },
                    child: const Text('Full Amount'),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter payment amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Payment Method Chips
              Text(
                'Payment Method',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paymentMethods.map((method) {
                  final isSelected = _selectedMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedMethod = method);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Notes Input
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Payment Notes (Optional)',
                  hintText: 'e.g. Received via GPay for July invoice',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Record Payment',
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
