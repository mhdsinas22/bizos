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
  final VoidCallback? onResolveCompletedLate;
  final VoidCallback? onResolveNotCompleted;

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
    this.onResolveCompletedLate,
    this.onResolveNotCompleted,
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

    // Status configuration
    const pendingColor = Color(0xFFF59E0B);
    const completedColor = Color(0xFF10B981);
    const missedColor = Color(0xFFEF4444);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (task.isCompleted) {
      if (task.isCompletedLate) {
        statusColor = completedColor;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Completed Late';
      } else {
        statusColor = completedColor;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Completed';
      }
    } else if (task.isNotCompleted) {
      statusColor = missedColor;
      statusIcon = Icons.cancel_outlined;
      statusLabel = 'Not Completed';
    } else if (task.isMissed) {
      statusColor = missedColor;
      statusIcon = Icons.cancel_outlined;
      statusLabel = 'Missed';
    } else {
      statusColor = pendingColor;
      statusIcon = Icons.access_time_outlined;
      statusLabel = 'Pending';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left checkbox (only shown in owner view when task can be marked complete)
          if (isOwnerView && task.canMarkComplete) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Checkbox(
                value: task.isCompleted,
                onChanged: onToggleCompleted,
                activeColor: completedColor,
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

                // 4. Status + Priority + Due Date Row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    // Due Date & Time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 12,
                          color: task.isMissed
                              ? missedColor
                              : theme.disabledColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat.yMMMd().add_jm().format(task.dueDate)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: task.isMissed
                                ? missedColor
                                : theme.disabledColor,
                            fontWeight: task.isMissed
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (task.isMissed) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.red.withOpacity(0.12)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: missedColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: missedColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'This task missed its deadline. What was the final outcome?',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: theme.brightness == Brightness.dark
                                      ? const Color(0xFFFCA5A5)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (onResolveCompletedLate != null ||
                            onResolveNotCompleted != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (onResolveCompletedLate != null)
                                ElevatedButton.icon(
                                  onPressed: onResolveCompletedLate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: completedColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 12,
                                  ),
                                  label: const Text(
                                    'Completed Late',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (onResolveNotCompleted != null)
                                OutlinedButton.icon(
                                  onPressed: onResolveNotCompleted,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        missedColor.withOpacity(0.08),
                                    foregroundColor: missedColor,
                                    side: const BorderSide(
                                      color: missedColor,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 12,
                                  ),
                                  label: const Text(
                                    'Not Completed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
            // Staff complete button (only shown when task can be marked complete)
            if (task.canMarkComplete && onMarkComplete != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: onMarkComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: completedColor,
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
