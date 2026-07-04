import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/presentation/screens/staff_list_view.dart';
import 'package:flutter/material.dart';

class StaffTab extends StatelessWidget {
  final UserModel user;
  final String? businessId;

  const StaffTab({super.key, required this.user, this.businessId});

  @override
  Widget build(BuildContext context) {
    if (user.isOwner) {
      // Owner gets the full staff panel directly within the business view
      return const StaffListView();
    }

    // Staff gets a nice card telling them what roles they have
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(
                    Icons.verified_user,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('Role: ${user.role}'),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Your System Permissions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildPermissionRow(
                  context,
                  'View Tasks',
                  user.hasPermission('view_tasks', businessId: businessId),
                ),
                const SizedBox(height: 8),
                _buildPermissionRow(
                  context,
                  'Create Tasks',
                  user.hasPermission('add_tasks', businessId: businessId),
                ),
                const SizedBox(height: 8),
                _buildPermissionRow(
                  context,
                  'View Accounts & Financials',
                  user.hasPermission('view_accounts', businessId: businessId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(BuildContext context, String title, bool active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Icon(
          active ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: active ? AppTheme.success : Theme.of(context).disabledColor,
        ),
      ],
    );
  }
}
