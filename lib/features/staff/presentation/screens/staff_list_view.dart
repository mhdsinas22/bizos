import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_event.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_state.dart';
import 'package:bizos/features/staff/presentation/helpers/staff_sheet_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/error_state.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_bloc.dart';

class StaffListView extends StatefulWidget {
  final String? businessId;

  const StaffListView({super.key, this.businessId});

  @override
  State<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends State<StaffListView> {
  String _getOwnerId() {
    return context.read<AuthBloc>().state.user?.id ?? '';
  }

  @override
  void initState() {
    super.initState();
    print(context.read<BusinessBloc>().hashCode);
    context.read<StaffBloc>().add(FetchStaffEvent(_getOwnerId()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            StaffSheetHelper.showStaffForm(context: context, onSave: () {}),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<StaffBloc, StaffState>(
        builder: (context, state) {
          if (state is StaffLoading) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: SkeletonListLoader(itemCount: 4, itemHeight: 88),
            );
          }

          if (state is StaffError) {
            return ErrorStateWidget(
              title: 'Unable to Load Staff Members',
              message: state.message,
              onRetry: () {
                context.read<StaffBloc>().add(FetchStaffEvent(_getOwnerId()));
              },
            );
          }

          if (state is StaffLoaded) {
            final staffList = state.staffList;
            if (staffList.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No Staff Accounts Registered',
                message: 'Create credentialed sub-accounts to delegate tasks and operations.',
                actionLabel: 'Add Staff Member',
                onActionPressed: () => StaffSheetHelper.showStaffForm(
                  context: context,
                  onSave: () {},
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  key: ValueKey(staff.id),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${staff.userId}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildPermissionChip(
                                    context: context,
                                    label: 'View Tasks',
                                    active: staff.hasPermission('view_tasks'),
                                  ),
                                  _buildPermissionChip(
                                    context: context,
                                    label: 'Add Tasks',
                                    active: staff.hasPermission('add_tasks'),
                                  ),
                                  _buildPermissionChip(
                                    context: context,
                                    label: 'View Accounts',
                                    active: staff.hasPermission('view_accounts'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (val) {
                            if (val == 'edit') {
                              StaffSheetHelper.showStaffForm(
                                context: context,
                                staff: staff,
                                onSave: () {},
                              );
                            }
                            if (val == 'delete') {
                              _confirmDelete(context, staff);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit Permissions', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
                                  SizedBox(width: 8),
                                  Text('Delete Staff', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPermissionChip({
    required BuildContext context,
    required String label,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.success.withOpacity(0.08)
            : Theme.of(context).disabledColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? AppTheme.success.withOpacity(0.2)
              : Theme.of(context).disabledColor.withOpacity(0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active ? AppTheme.success : Theme.of(context).disabledColor,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel staff) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Staff Account?'),
        content: Text(
          'Are you sure you want to permanently delete the staff login for "${staff.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StaffBloc>().add(
                DeleteStaffEvent(staff.userId, _getOwnerId()),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

