import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/customers/domain/entities/customer_entity.dart';
import 'package:bizos/features/customers/presentation/bloc/customer_bloc.dart';

class CustomerFormDialog extends StatefulWidget {
  final String businessId;
  final CustomerEntity? customer;

  const CustomerFormDialog({
    super.key,
    required this.businessId,
    this.customer,
  });

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _gstinController = TextEditingController(text: widget.customer?.gstin ?? '');
    _notesController = TextEditingController(text: widget.customer?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.customer != null;
    final customer = CustomerEntity(
      id: isEdit ? widget.customer!.id : '',
      businessId: widget.businessId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      gstin: _gstinController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: isEdit ? widget.customer!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      context.read<CustomerBloc>().add(UpdateCustomerEvent(customer));
    } else {
      context.read<CustomerBloc>().add(AddCustomerEvent(customer));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = AppTheme.primaryColor;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Customer' : 'Add New Customer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit
                              ? 'Update customer details in your records'
                              : 'Add customer details to your records',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: subtextColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Body
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name *
                      _buildLabel('Customer Name', isRequired: true, textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter customer name',
                          icon: Icons.person_outline_rounded,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          subtextColor: subtextColor,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Customer name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Number & Email Address (2 Columns)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Phone Number', textColor: textColor),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: _buildInputDecoration(
                                    hintText: 'Enter phone number',
                                    icon: Icons.phone_outlined,
                                    inputBg: inputBg,
                                    borderColor: borderColor,
                                    subtextColor: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Email Address', textColor: textColor),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: _buildInputDecoration(
                                    hintText: 'Enter email address',
                                    icon: Icons.email_outlined,
                                    inputBg: inputBg,
                                    borderColor: borderColor,
                                    subtextColor: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _buildLabel('Address', textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter address',
                          icon: Icons.location_on_outlined,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          subtextColor: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // GSTIN (Optional)
                      _buildLabel('GSTIN (Optional)', textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _gstinController,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter GSTIN',
                          icon: Icons.receipt_long_outlined,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          subtextColor: subtextColor,
                          suffixWidget: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      _buildLabel('Notes', textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Add notes about this customer...',
                          icon: Icons.edit_note_rounded,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          subtextColor: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: subtextColor,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: Icon(
                      isEdit ? Icons.save_rounded : Icons.person_add_alt_1_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isEdit ? 'Save Changes' : 'Add Customer',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false, required Color textColor}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color subtextColor,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), fontSize: 13),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIcon: Icon(icon, color: subtextColor, size: 20),
      suffixIcon: suffixWidget != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [suffixWidget],
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }
}
