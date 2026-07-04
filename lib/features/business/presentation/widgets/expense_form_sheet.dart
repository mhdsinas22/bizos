import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ExpenseFormSheet extends StatefulWidget {
  final String businessId;
  final ExpenseModel? expense;
  final UserModel user;
  final VoidCallback onSave;

  const ExpenseFormSheet({
    super.key,
    required this.businessId,
    this.expense,
    required this.user,
    required this.onSave,
  });

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _categoryController.text = widget.expense!.category;
      _descController.text = widget.expense!.description;
      _date = widget.expense!.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.expense != null;
      final amt = double.parse(_amountController.text.trim());

      final exp = ExpenseModel(
        id: isEditing ? widget.expense!.id : const Uuid().v4(),
        businessId: widget.businessId,
        amount: amt,
        category: _categoryController.text.trim(),
        description: _descController.text.trim(),
        date: _date,
        createdByUserId: isEditing
            ? widget.expense!.createdByUserId
            : widget.user.id,
        createdByName: isEditing
            ? widget.expense!.createdByName
            : widget.user.name,
      );

      if (isEditing) {
        context.read<FinanceBloc>().add(UpdateExpenseEvent(exp));
      } else {
        context.read<FinanceBloc>().add(AddExpenseEvent(exp));
      }
      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.expense != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing
                        ? 'Edit Expense Record'
                        : 'Record Outward Payment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                label: 'Outward Amount',
                hint: '0.00',
                prefixIcon: Icons.monetization_on_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Please enter an amount';
                  if (double.tryParse(val.trim()) == null)
                    return 'Please enter a valid numeric value';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _categoryController,
                label: 'Category',
                hint: 'e.g. rent, supplies, salaries, taxes',
                prefixIcon: Icons.tag,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please specify category'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descController,
                label: 'Description',
                hint:
                    'Detailed notes on supplier, invoice or receipt context...',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.error,
                ),
                title: const Text(
                  'Transaction Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 3650),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                      });
                    }
                  },
                  child: const Text('Change Date'),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Record Outflow',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
