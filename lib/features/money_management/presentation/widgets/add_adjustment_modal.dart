import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class AddAdjustmentModal extends StatefulWidget {
  final String transactionId;
  final bool isPersonal;
  final Function(double amount, String notes) onSave;

  const AddAdjustmentModal({
    super.key,
    required this.transactionId,
    required this.isPersonal,
    required this.onSave,
  });

  @override
  State<AddAdjustmentModal> createState() => _AddAdjustmentModalState();
}

class _AddAdjustmentModalState extends State<AddAdjustmentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isDiscountOrReduction = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (_isDiscountOrReduction) {
      amount = -amount.abs();
    }
    final notes = _notesController.text.trim();

    widget.onSave(amount, notes);
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
                    'Record Balance Adjustment',
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
              // Type Toggle: Add to debt vs Discount/Waiver
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Increase Debt (+)')),
                      selected: !_isDiscountOrReduction,
                      onSelected: (val) {
                        if (val) setState(() => _isDiscountOrReduction = false);
                      },
                      selectedColor: AppTheme.error.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: !_isDiscountOrReduction ? AppTheme.error : null,
                        fontWeight: !_isDiscountOrReduction ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Discount/Waiver (-)')),
                      selected: _isDiscountOrReduction,
                      onSelected: (val) {
                        if (val) setState(() => _isDiscountOrReduction = true);
                      },
                      selectedColor: AppTheme.success.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: _isDiscountOrReduction ? AppTheme.success : null,
                        fontWeight: _isDiscountOrReduction ? FontWeight.bold : null,
                      ),
                    ),
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
                  labelText: 'Adjustment Amount (₹)',
                  hintText: 'Enter amount',
                  prefixIcon: Icon(
                    Icons.tune,
                    color: _isDiscountOrReduction ? AppTheme.success : AppTheme.error,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter adjustment amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Notes Input
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason for Adjustment (Required)',
                  hintText: 'e.g. Additional service added / Given ₹500 discount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Reason for adjustment is required';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save Adjustment',
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
