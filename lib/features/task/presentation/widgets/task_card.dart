import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final UserModel currentUser;
  final Map<String, String> userNames;
  final Map<String, String> businessNames;
  final bool isOwnerView;
  final ValueChanged<bool?>? onToggleCompleted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.currentUser,
    required this.userNames,
    required this.businessNames,
    required this.isOwnerView,
    this.onToggleCompleted,
    this.onEdit,
    this.onDelete,
    this.onMarkComplete,
  });

  String _resolveName(String? id, {String fallback = 'Unassigned'}) {
    if (id == null || id.isEmpty) return fallback;
    if (userNames.containsKey(id)) {
      return userNames[id]!;
    }
    // If it's the owner, fallback to "Owner" (useful for staff view under RLS)
    final ownerId = currentUser.isOwner ? currentUser.id : currentUser.ownerId;
    if (id == ownerId) {
      return 'Owner';
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Resolve names
    final assigneeName = _resolveName(task.assignedto);
    final creatorName = _resolveName(task.createdBy, fallback: 'Owner');
    final businessName = businessNames[task.businessId] ?? 'Business';
    print("Bussiname:-$businessName");

    // Priority color mapping
    Color priorityColor = Colors.grey;
    if (task.priority == 'High') priorityColor = AppTheme.error;
    if (task.priority == 'Medium') priorityColor = AppTheme.warning;
    if (task.priority == 'Low') priorityColor = AppTheme.info;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left checkbox (only in owner view or if staff is editing their own tasks)
          if (isOwnerView) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Checkbox(
                value: task.isCompleted,
                onChanged: onToggleCompleted,
                activeColor: AppTheme.success,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Task content details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Title (prominent)
                Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted ? theme.disabledColor : null,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Business Name Row
                Row(
                  children: [
                    Icon(
                      Icons.storefront,
                      size: 12,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      businessName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 2. Assigned Staff & Creators (with icon/avatar)
                if (isOwnerView) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned To: ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        assigneeName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: assigneeName == 'Unassigned'
                              ? theme.disabledColor
                              : null,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.create_outlined,
                          size: 12,
                          color: theme.disabledColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Created By: ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        creatorName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Staff should only see: Assigned By
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned By: ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        creatorName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],

                // 3. Description
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.3,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // 4. Priority + Due Date Row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${task.priority} Priority',
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    // Due Date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat.yMMMd().format(task.dueDate)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.disabledColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Actions Section
          if (isOwnerView) ...[
            Column(
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit task',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete task',
                  ),
              ],
            ),
          ] else ...[
            // Staff complete button / badge
            Center(
              child: task.isCompleted
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, size: 12, color: AppTheme.success),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onMarkComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 12),
                      label: const Text(
                        'Mark Complete',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
