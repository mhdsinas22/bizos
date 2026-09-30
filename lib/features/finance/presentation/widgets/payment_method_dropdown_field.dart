import 'package:flutter/material.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';

class PaymentMethodDropdownField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  const PaymentMethodDropdownField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  State<PaymentMethodDropdownField> createState() =>
      _PaymentMethodDropdownFieldState();
}

class _PaymentMethodDropdownFieldState
    extends State<PaymentMethodDropdownField> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = PaymentMethodHelper.sanitize(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant PaymentMethodDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedValue = PaymentMethodHelper.sanitize(widget.initialValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = PaymentMethodHelper.allowedMethods.map((method) {
      final icon = PaymentMethodHelper.getIcon(method);
      return DropdownMenuItem<String>(
        value: method,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(method),
          ],
        ),
      );
    }).toList();

    return DropdownButtonFormField<String>(
      initialValue: _selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        hintText: 'Select payment method',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items,
      validator: widget.validator ??
          (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please select a payment method';
            }
            return null;
          },
      onChanged: (val) {
        if (val != null) {
          final sanitized = PaymentMethodHelper.sanitize(val);
          setState(() {
            _selectedValue = sanitized;
          });
          widget.onChanged(sanitized);
        }
      },
    );
  }
}
