import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_event.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StaffFormSheet extends StatefulWidget {
  final UserModel? staff;
  final VoidCallback onSave;

  const StaffFormSheet({super.key, this.staff, required this.onSave});

  @override
  State<StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _canViewTasks = true;
  bool _canAddTasks = true;
  bool _canViewAccounts = true;

  @override
  void initState() {
    super.initState();
    print(context.read<BusinessBloc>().hashCode);
    final authstate = context.read<AuthBloc>().state;
    if (authstate is Authenticated) {
      print("Owner Id: ${authstate.user.id}");
      context.read<BusinessBloc>().add(
        FetchBusinessesEvent(authstate.user.userId),
      );
    }

    if (widget.staff != null) {
      _nameController.text = widget.staff!.name;
      _userIdController.text = widget.staff!.userId;
      _passwordController.text = '••••••••';
      _canViewTasks = widget.staff!.permissions.contains('view_tasks');
      _canAddTasks = widget.staff!.permissions.contains('add_tasks');
      _canViewAccounts = widget.staff!.permissions.contains('view_accounts');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final perms = <String>[];
      if (_canViewTasks) perms.add('view_tasks');
      if (_canAddTasks) perms.add('add_tasks');
      if (_canViewAccounts) perms.add('view_accounts');

      final isEditing = widget.staff != null;
      final authState = context.read<AuthBloc>().state;
      final currentUserId = authState.user?.id ?? '';

      final staffMember = UserModel(
        id: isEditing ? widget.staff!.id : '',
        name: _nameController.text.trim(),
        userId: _userIdController.text.trim().toLowerCase(),
        password: _passwordController.text,
        role: 'Staff',
        ownerId: currentUserId,
        permissions: perms,
      );

      if (isEditing) {
        context.read<StaffBloc>().add(
          UpdateStaffEvent(staffMember, currentUserId),
        );
      } else {
        context.read<StaffBloc>().add(
          CreateStaffEvent(staffMember, currentUserId, selectedBusinessIds),
        );
        print("Current userid" + currentUserId);
      }

      widget.onSave();
      Navigator.pop(context);
    }
  }

  List<String> selectedBusinessIds = [];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.staff != null;

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
                        ? 'Edit Staff Permissions'
                        : 'Create Staff Credentials',
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
                label: 'Name',
                hint: 'e.g. Sarah Connor',
                prefixIcon: Icons.badge_outlined,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _userIdController,
                label: 'User ID',
                hint: 'e.g. sarahc',
                prefixIcon: Icons.alternate_email,
                readOnly:
                    isEditing, // Cannot modify user ID username once created
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a unique user ID'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                readOnly: isEditing,
                validator: (val) {
                  if (isEditing) return null;
                  return val == null || val.isEmpty
                      ? 'Please enter a password'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Business",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  BlocBuilder<BusinessBloc, BusinessState>(
                    builder: (context, state) {
                      print("Current State = ${state.runtimeType}");
                      if (state is BusinessError) {
                        return Text(state.message);
                      }
                      if (state is BusinessLoaded) {
                        return Column(
                          children: state.businesses.map((businesses) {
                            return CheckboxListTile(
                              value: selectedBusinessIds.contains(
                                businesses.id,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedBusinessIds.add(businesses.id);
                                  } else {
                                    selectedBusinessIds.remove(businesses.id);
                                  }
                                });
                              },
                              title: Text(businesses.name),
                            );
                          }).toList(),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Permissions checkboxes
              Text(
                'Access Permissions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                title: const Text('View Tasks'),
                subtitle: const Text('Allows reading and viewing ToDos'),
                value: _canViewTasks,
                onChanged: (val) {
                  setState(() {
                    _canViewTasks = val ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Add/Edit Tasks'),
                subtitle: const Text(
                  'Allows adding, completing, and editing ToDos',
                ),
                value: _canAddTasks,
                onChanged: (val) {
                  setState(() {
                    _canAddTasks = val ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('View Accounts & Financials'),
                subtitle: const Text(
                  'Allows reading income, expenses, P&L reports',
                ),
                value: _canViewAccounts,
                onChanged: (val) {
                  setState(() {
                    _canViewAccounts = val ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Staff Member',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
