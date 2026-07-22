import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/contacts/presentation/bloc/contact_bloc.dart';
import 'package:bizos/features/contacts/presentation/bloc/contact_event.dart';
import 'package:bizos/features/contacts/presentation/bloc/contact_state.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';

class AddTransactionPage extends StatefulWidget {
  final String transactionType; // 'pay' or 'receive'
  final String? businessId; // null for personal
  final MoneyTransactionEntity? editTransaction;

  const AddTransactionPage({
    super.key,
    required this.transactionType,
    this.businessId,
    this.editTransaction,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _balanceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'Pending';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateBalance);
    _paidAmountController.addListener(_calculateBalance);

    if (widget.editTransaction != null) {
      final tx = widget.editTransaction!;
      _personNameController.text = tx.personName;
      _phoneController.text = tx.phone;
      _amountController.text = tx.amount.toString();
      _paidAmountController.text = tx.paidAmount.toString();
      _balanceController.text = tx.balanceAmount.toString();
      _notesController.text = tx.notes;
      _selectedStatus = tx.status;
      if (tx.dueDate != null) {
        _selectedDate = tx.dueDate!;
      }
    } else {
      _balanceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateBalance);
    _paidAmountController.removeListener(_calculateBalance);
    _personNameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _paidAmountController.dispose();
    _balanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateBalance() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
    final balance = amount - paidAmount;
    _balanceController.text = balance.toStringAsFixed(2);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.white,
                surface: Theme.of(context).cardColor,
                onSurface:
                    Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      setState(() {
        final time = pickedTime ?? TimeOfDay.fromDateTime(_selectedDate);
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;

    if (widget.businessId == null && userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session expired. Please log in again.'),
          backgroundColor: AppTheme.error,
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final amount = double.parse(_amountController.text);
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
    final balance = amount - paidAmount;

    final transaction = MoneyTransactionEntity(
      id: widget.editTransaction?.id ?? '',
      userId: widget.businessId == null ? userId : null,
      businessId: widget.businessId,
      transactionType: widget.transactionType,
      personName: _personNameController.text.trim(),
      phone: _phoneController.text.trim(),
      amount: amount,
      paidAmount: paidAmount,
      balanceAmount: balance,
      dueDate: _selectedDate,
      notes: _notesController.text.trim(),
      status: _selectedStatus,
      createdAt: widget.editTransaction?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final isPersonal = widget.businessId == null;
      if (isPersonal) {
        if (widget.editTransaction != null) {
          context.read<PersonalMoneyManagementBloc>().add(
            UpdateTransactionEvent(transaction, isPersonal: true),
          );
        } else {
          context.read<PersonalMoneyManagementBloc>().add(
            AddTransactionEvent(transaction, isPersonal: true),
          );
        }
      } else {
        if (widget.editTransaction != null) {
          context.read<BusinessMoneyManagementBloc>().add(
            UpdateTransactionEvent(transaction, isPersonal: false),
          );
        } else {
          context.read<BusinessMoneyManagementBloc>().add(
            AddTransactionEvent(transaction, isPersonal: false),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editTransaction != null
                ? 'Transaction updated successfully'
                : 'Transaction added successfully',
          ),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.editTransaction != null;
    final typeLabel = widget.transactionType == 'pay'
        ? 'Money to Pay'
        : 'Money to Receive';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit $typeLabel' : 'Add $typeLabel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ResponsiveCenterBody(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Person Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              BlocConsumer<ContactBloc, ContactState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        readOnly: true,
                        onTap: () {
                          context.read<ContactBloc>().add(SelectContactEvent());
                        },
                        controller: _personNameController,
                        decoration: const InputDecoration(
                          labelText: 'Person Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Person name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        readOnly: true,
                        onTap: () => context.read<ContactBloc>().add(
                          SelectContactEvent(),
                        ),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Phone number is required'
                            : null,
                      ),
                    ],
                  );
                },
                listener: (context, state) {
                  if (state.status == contactstatus.selected &&
                      state.contact != null) {
                    _personNameController.text = state.contact!.name;
                    _phoneController.text = state.contact!.phoneNumber;
                  }
                },
              ),

              const SizedBox(height: 24),
              Text(
                'Transaction Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total Amount *',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Total amount is required';
                  final numVal = double.tryParse(val);
                  if (numVal == null) return 'Please enter a valid number';
                  if (numVal <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Paid Amount *',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Paid amount is required (enter 0 if unpaid)';
                  final numVal = double.tryParse(val);
                  if (numVal == null) return 'Please enter a valid number';
                  if (numVal < 0) return 'Paid amount cannot be negative';
                  final totalAmt =
                      double.tryParse(_amountController.text) ?? 0.0;
                  if (numVal > totalAmt)
                    return 'Paid amount cannot exceed total amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Balance (Auto Calculated)',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  fillColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date & Time *',
                    prefixIcon: Icon(Icons.access_time_outlined),
                  ),
                  child: Text(
                    DateFormat.yMMMd().add_jm().format(_selectedDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: Icon(Icons.rule),
                ),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatus = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: isEdit ? 'Save Changes' : 'Save Transaction',
                isLoading: _isSaving,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
