import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class BusinessFormSheet extends StatefulWidget {
  final BusinessModel? business;
  final VoidCallback onSave;

  const BusinessFormSheet({super.key, this.business, required this.onSave});

  @override
  State<BusinessFormSheet> createState() => _BusinessFormSheetState();
}

class _BusinessFormSheetState extends State<BusinessFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.business != null) {
      _nameController.text = widget.business!.name;
      _typeController.text = widget.business!.type;
      _phoneController.text = widget.business!.phone;
      _addressController.text = widget.business!.address;
      _notesController.text = widget.business!.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final isEditing = widget.business != null;

        final biz = BusinessModel(
          id: isEditing ? widget.business!.id : const Uuid().v4(),
          name: _nameController.text.trim(),
          type: _typeController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
          ownerId: authState.user.userId,
        );

        if (isEditing) {
          context.read<BusinessBloc>().add(UpdateBusinessEvent(biz));
        } else {
          context.read<BusinessBloc>().add(CreateBusinessEvent(biz));
        }

        widget.onSave();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.business != null;

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
                        ? 'Edit Business Details'
                        : 'Create Business Profile',
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
              const Divider(),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Business Name',
                hint: 'e.g. Acme Corp',
                prefixIcon: Icons.storefront,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _typeController,
                label: 'Business Type / Industry',
                hint: 'e.g. Retail, Consulting, Tech',
                prefixIcon: Icons.category_outlined,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter industry type'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+1 555-0100',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a phone number'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'Address',
                hint: '123 Main St, New York',
                prefixIcon: Icons.location_on_outlined,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter address'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'Notes / Description',
                hint: 'Optional notes...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Business',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
