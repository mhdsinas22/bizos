import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDebtModal extends StatefulWidget {
  final String? transactionId;
  final String personName;
  final String phone;
  final String transactionType;
  final bool isPersonal;
  final String? userId;
  final String? businessId;
  final Future<void> Function(double amount, DateTime dueDate, String notes) onSave;

  const AddDebtModal({
    super.key,
    this.transactionId,
    required this.personName,
    required this.phone,
    required this.transactionType,
    required this.isPersonal,
    this.userId,
    this.businessId,
    required this.onSave,
  });

  @override
  State<AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends State<AddDebtModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDueDateTime;
  bool _isSubmitting = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    // Default: Today + 7 days at 11:59 PM (23:59:00)
    final now = DateTime.now();
    _selectedDueDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
    ).add(const Duration(days: 7));

    _amountController.addListener(_validateForm);
    _notesController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateForm);
    _notesController.removeListener(_validateForm);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final amountText = _amountController.text.trim();
    final parsedAmount = double.tryParse(amountText);
    final isValidAmount = parsedAmount != null && parsedAmount > 0;
    final isValidNotes = _notesController.text.length <= 500;
    final isNotPast = !_selectedDueDateTime.isBefore(DateTime.now());

    final isFormValid = isValidAmount && isValidNotes && isNotPast;
    if (_isValid != isFormValid) {
      setState(() {
        _isValid = isFormValid;
      });
    }
  }

  Future<void> _selectDueDateTime(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final firstAllowedDate = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDueDateTime.isBefore(firstAllowedDate)
        ? firstAllowedDate
        : DateTime(
            _selectedDueDateTime.year,
            _selectedDueDateTime.month,
            _selectedDueDateTime.day,
          );

    final dialogTheme = Theme.of(context);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: dialogTheme.copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: dialogTheme.cardColor,
              onSurface: dialogTheme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // Show Material Time Picker after Date Picker
    final initialTime = TimeOfDay(
      hour: _selectedDueDateTime.hour,
      minute: _selectedDueDateTime.minute,
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: dialogTheme.copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: dialogTheme.cardColor,
              onSurface: dialogTheme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    // If user cancels time picker, default to 11:59 PM (23:59:00) on selected date
    final finalTime = pickedTime ?? const TimeOfDay(hour: 23, minute: 59);

    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      finalTime.hour,
      finalTime.minute,
    );

    if (combinedDateTime.isBefore(now)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Due date and time cannot be in the past.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _selectedDueDateTime = combinedDateTime;
    });
    _validateForm();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

    final now = DateTime.now();
    if (_selectedDueDateTime.isBefore(now)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Due date and time cannot be in the past.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final notes = _notesController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSave(amount, _selectedDueDateTime, notes);
      if (mounted) {
        Navigator.pop(context);
        final successMsg = widget.transactionType == 'receive'
            ? 'Receivable added successfully.'
            : 'Debt added successfully.';
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isReceive = widget.transactionType == 'receive';

    final titleText = isReceive ? 'Add Receivable' : 'Add Debt';
    final amountLabelText = isReceive ? 'Receivable Amount (₹) *' : 'Debt Amount (₹) *';
    final buttonText = isReceive ? 'Create Receivable' : 'Add Debt';

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
              // Header with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titleText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Amount Field (Required)
              TextFormField(
                controller: _amountController,
                enabled: !_isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: amountLabelText,
                  hintText: 'Enter amount (e.g. 3000)',
                  prefixIcon: Icon(
                    Icons.currency_rupee,
                    color: isReceive ? AppTheme.primaryColor : AppTheme.error,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isReceive
                        ? 'Receivable amount is required'
                        : 'Debt amount is required';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Due Date & Time Field (Required)
              InkWell(
                onTap: _isSubmitting ? null : () => _selectDueDateTime(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date & Time *',
                    prefixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy • h:mm a').format(_selectedDueDateTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Notes Field (Optional, Max 500 characters)
              TextFormField(
                controller: _notesController,
                enabled: !_isSubmitting,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Example:\nLaptop Purchase\nOffice Rent\nBuilding Materials\nMedical Expense',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 13,
                  ),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val != null && val.length > 500) {
                    return 'Notes cannot exceed 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons: Primary & Secondary
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      isSecondary: true,
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: buttonText,
                      isLoading: _isSubmitting,
                      onPressed: _isValid && !_isSubmitting ? _submit : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
