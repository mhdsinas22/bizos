import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_dropdown_field.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_event.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_state.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/add_custom_category_dialog.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/manage_personal_categories_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddExpenseDialog extends StatefulWidget {
  final PersonalExpenseEntity? expense;
  final Function(
    double amount,
    String category,
    String paymentMethod,
    String description,
    DateTime date,
  ) onSave;

  const AddExpenseDialog({
    super.key,
    this.expense,
    required this.onSave,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String? _selectedCategory;
  String _selectedPaymentMethod = PaymentMethodHelper.defaultMethod;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isCustomCategory = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final exp = widget.expense!;
      _amountController.text = exp.amount.toString();
      _descriptionController.text = exp.description;
      _selectedPaymentMethod = PaymentMethodHelper.sanitize(exp.paymentMethod);
      _selectedDate = exp.expenseDate;
      _selectedCategory = exp.category;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      if (userId.isNotEmpty) {
        context
            .read<PersonalExpenseCategoryBloc>()
            .add(LoadPersonalCategoriesEvent(userId));
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _openAddCustomCategoryDialog() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddCustomCategoryDialog(
        userId: userId,
        onCategorySaved: (newCat) {
          setState(() {
            _selectedCategory = newCat.name;
            _isCustomCategory = false;
          });
        },
      ),
    );
  }

  void _openManageCategoriesSheet() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ManagePersonalCategoriesSheet(
        userId: userId,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null ||
        _selectedCategory == 'custom' ||
        _selectedCategory == 'manage') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final String finalCategory = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _selectedCategory!;

    if (_isCustomCategory && finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter custom category name'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final double? parsedAmount = double.tryParse(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      widget.onSave(
        parsedAmount,
        finalCategory,
        _selectedPaymentMethod,
        _descriptionController.text.trim(),
        _selectedDate,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.expense != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                      isEdit ? 'Edit Personal Expense' : 'Add Personal Expense',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'This expense will not affect business accounts or profit calculations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Amount Text Field
                Text(
                  'Amount *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Category Dropdown
                Text(
                  'Category *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                BlocBuilder<PersonalExpenseCategoryBloc, PersonalExpenseCategoryState>(
                  builder: (context, catState) {
                    List<PersonalExpenseCategoryEntity> loadedCategories = [];
                    if (catState is PersonalExpenseCategoryLoaded) {
                      loadedCategories = catState.categories;
                    } else if (catState is PersonalExpenseCategoryError) {
                      loadedCategories = catState.currentCategories;
                    }

                    final categoryNames =
                        loadedCategories.map((c) => c.name).toList();

                    final items = <DropdownMenuItem<String>>[];

                    for (final cat in loadedCategories) {
                      items.add(
                        DropdownMenuItem<String>(
                          value: cat.name,
                          child: Text(cat.name),
                        ),
                      );
                    }

                    if (_selectedCategory != null &&
                        _selectedCategory!.isNotEmpty &&
                        _selectedCategory != 'custom' &&
                        _selectedCategory != 'manage' &&
                        !categoryNames.contains(_selectedCategory)) {
                      items.add(
                        DropdownMenuItem<String>(
                          value: _selectedCategory,
                          child: Text(_selectedCategory!),
                        ),
                      );
                    }

                    items.add(
                      const DropdownMenuItem<String>(
                        value: 'custom',
                        child: Text(
                          '+ Add Custom Category',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );

                    items.add(
                      const DropdownMenuItem<String>(
                        value: 'manage',
                        child: Text(
                          '⚙ Manage Categories',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );

                    final validValue =
                        items.any((i) => i.value == _selectedCategory)
                            ? _selectedCategory
                            : null;

                    return DropdownButtonFormField<String>(
                      initialValue: validValue,
                      hint: const Text('Select Category'),
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      dropdownColor:
                          isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      items: items,
                      onChanged: (value) {
                        if (value == 'custom') {
                          _openAddCustomCategoryDialog();
                        } else if (value == 'manage') {
                          _openManageCategoriesSheet();
                        } else if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                            _isCustomCategory = value == 'Other';
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null ||
                            value == 'custom' ||
                            value == 'manage') {
                          return 'Category is required';
                        }
                        return null;
                      },
                    );
                  },
                ),
                if (_isCustomCategory) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Custom Category Name *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      hintText: 'Enter category name...',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (value) {
                      if (_isCustomCategory &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Custom category name is required';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // 3. Payment Method Selector
                Text(
                  'Payment Method *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                PaymentMethodDropdownField(
                  initialValue: _selectedPaymentMethod,
                  onChanged: (val) {
                    setState(() {
                      _selectedPaymentMethod = val;
                    });
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Payment Method is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Description
                Text(
                  'Description',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Enter expense details...',
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Expense Date
                Text(
                  'Expense Date *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      border: Border.all(
                        color:
                            isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat.yMMMd().format(_selectedDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Save / Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        isSecondary: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: isEdit ? 'Update' : 'Save',
                        isLoading: _isSaving,
                        onPressed: _submitForm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
