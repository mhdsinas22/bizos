import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class IncomeFormSheet extends StatefulWidget {
  final String businessId;
  final IncomeModel? income;
  final UserModel user;
  final VoidCallback onSave;

  const IncomeFormSheet({
    super.key,
    required this.businessId,
    this.income,
    required this.user,
    required this.onSave,
  });

  @override
  State<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<IncomeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.income != null) {
      _amountController.text = widget.income!.amount.toString();
      _categoryController.text = widget.income!.category;
      _descController.text = widget.income!.description;
      _date = widget.income!.date;
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
      final isEditing = widget.income != null;
      final amt = double.parse(_amountController.text.trim());

      final inc = IncomeModel(
        id: isEditing ? widget.income!.id : const Uuid().v4(),
        businessId: widget.businessId,
        amount: amt,
        category: _categoryController.text.trim(),
        description: _descController.text.trim(),
        date: _date,
        createdByUserId: isEditing
            ? widget.income!.createdByUserId
            : widget.user.id,
        createdByName: isEditing
            ? widget.income!.createdByName
            : widget.user.name,
      );

      if (isEditing) {
        context.read<FinanceBloc>().add(UpdateIncomeEvent(inc));
      } else {
        context.read<FinanceBloc>().add(AddIncomeEvent(inc));
      }
      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.income != null;

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
                    isEditing ? 'Edit Income Record' : 'Record Inward Payment',
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
                label: 'Inward Amount',
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
                hint: 'e.g. consulting, sales, rent',
                prefixIcon: Icons.tag,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please specify category'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Detailed notes on the invoice or payment source...',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.success,
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
                text: isEditing ? 'Save Changes' : 'Record Inflow',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
