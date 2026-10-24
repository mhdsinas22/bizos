import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_event.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_event.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_state.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _canViewTasks = true;
  bool _canAddTasks = true;
  bool _canViewAccounts = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  OverlayEntry? _floatingSnackBarEntry;

  List<String> selectedBusinessIds = [];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id ?? '';
    context.read<BusinessBloc>().add(FetchBusinessesEvent(currentUserId));
    _nameController.addListener(_clearErrorIfAny);
    _emailController.addListener(_clearErrorIfAny);
    _phoneController.addListener(_clearErrorIfAny);
    _passwordController.addListener(_clearErrorIfAny);
    if (widget.staff != null) {
      _nameController.text = widget.staff!.name;
      _emailController.text = widget.staff!.email.isNotEmpty
          ? widget.staff!.email
          : widget.staff!.userId;
      _phoneController.text = widget.staff!.phone;
      _passwordController.text = widget.staff!.password;
      _canViewTasks = widget.staff!.hasPermission('view_tasks');
      _canAddTasks = widget.staff!.hasPermission('add_tasks');
      _canViewAccounts = widget.staff!.hasPermission('view_accounts');
      _loadAssignedBusinesses();
    }
  }

  void _clearErrorIfAny() {
    if (_errorMessage != null && mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _loadAssignedBusinesses() async {
    try {
      final repo = context.read<StaffRepository>();
      final list = await repo.getStaffBusinesses(widget.staff!.id);
      if (mounted) {
        setState(() {
          selectedBusinessIds = list.map((e) => e.businessId).toList();
        });
      }
    } catch (e) {
      AppLogger.error("Error loading assigned businesses: $e");
    }
  }

  @override
  void dispose() {
    _dismissFloatingSnackBar();
    _nameController.removeListener(_clearErrorIfAny);
    _emailController.removeListener(_clearErrorIfAny);
    _phoneController.removeListener(_clearErrorIfAny);
    _passwordController.removeListener(_clearErrorIfAny);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _dismissFloatingSnackBar() {
    _floatingSnackBarEntry?.remove();
    _floatingSnackBarEntry = null;
  }

  void _showFloatingSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    _dismissFloatingSnackBar();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final bgColor = isError ? AppTheme.error : AppTheme.success;

    _floatingSnackBarEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 250),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (ctx, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * -16),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismissFloatingSnackBar,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_floatingSnackBarEntry!);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismissFloatingSnackBar();
      }
    });
  }

  void _save() {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      final perms = <String>[];
      if (_canViewTasks) perms.add('view_tasks');
      if (_canAddTasks) perms.add('add_tasks');
      if (_canViewAccounts) perms.add('view_accounts');

      final isEditing = widget.staff != null;
      final authState = context.read<AuthBloc>().state;
      final currentUserId = authState.user?.id ?? '';
      final cleanEmail = _emailController.text.trim().toLowerCase();

      final staffMember = UserModel(
        id: isEditing ? widget.staff!.id : '',
        name: _nameController.text.trim(),
        email: cleanEmail,
        phone: _phoneController.text.trim(),
        userId: cleanEmail,
        password: _passwordController.text,
        role: 'Staff',
        ownerId: currentUserId,
        permissions: perms,
      );

      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      if (isEditing) {
        context.read<StaffBloc>().add(
          UpdateStaffEvent(staffMember, currentUserId, selectedBusinessIds),
        );
      } else {
        context.read<StaffBloc>().add(
          CreateStaffEvent(staffMember, currentUserId, selectedBusinessIds),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.staff != null;

    return BlocListener<StaffBloc, StaffState>(
      listener: (context, state) {
        if (!_isSubmitting) return;

        if (state is StaffLoaded) {
          _dismissFloatingSnackBar();
          setState(() {
            _isSubmitting = false;
            _errorMessage = null;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Staff member updated successfully'
                    : 'Staff account created successfully',
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onSave();
          Navigator.pop(context);
        } else if (state is StaffError) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = state.message;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _showFloatingSnackBar(context, state.message, isError: true);
        }
      },
      child: Container(
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
          child: ResponsiveCenterBody(
            maxWidth: ResponsiveBreakpoints.maxFormWidth,
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
                            : 'Create Staff Account',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                _dismissFloatingSnackBar();
                                Navigator.pop(context);
                              },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppTheme.error,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  CustomTextField(
                    controller: _nameController,
                    label: 'Staff Name',
                    hint: 'e.g. Sarah Connor',
                    prefixIcon: Icons.badge_outlined,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Staff Email',
                    hint: 'e.g. sarah@company.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly:
                        isEditing, // Cannot modify email once account is created
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter staff email address';
                      }
                      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(val.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number (Optional)',
                    hint: 'e.g. +1 555-0199',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimum 8 characters',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (val.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Assigned Businesses / Branches",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<BusinessBloc, BusinessState>(
                        builder: (context, state) {
                          AppLogger.debug(
                            "Current State = ${state.runtimeType}",
                          );
                          if (state is BusinessError) {
                            return Text(
                              state.message,
                              style: TextStyle(color: theme.colorScheme.error),
                            );
                          }
                          if (state is BusinessLoaded) {
                            if (state.businesses.isEmpty) {
                              return Text(
                                'No businesses created yet',
                                style: theme.textTheme.bodySmall,
                              );
                            }
                            return Column(
                              children: state.businesses.map((business) {
                                return CheckboxListTile(
                                  value: selectedBusinessIds.contains(
                                    business.id,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedBusinessIds.add(business.id);
                                      } else {
                                        selectedBusinessIds.remove(business.id);
                                      }
                                    });
                                  },
                                  title: Text(business.name),
                                  contentPadding: EdgeInsets.zero,
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
                    text: isEditing ? 'Save Changes' : 'Create Staff Account',
                    isLoading: _isSubmitting,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
