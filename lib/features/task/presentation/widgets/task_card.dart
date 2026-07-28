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
    final ownerId = currentUser.isOwner ? currentUser.id : currentUser.ownerId;
    if (id == ownerId) {
      return 'Owner';
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final assigneeName = _resolveName(task.assignedto);
    final creatorName = _resolveName(task.createdBy, fallback: 'Owner');
    final businessName = businessNames[task.businessId] ?? 'Business';

    Color priorityColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    if (task.priority == 'High') priorityColor = AppTheme.error;
    if (task.priority == 'Medium') priorityColor = AppTheme.warning;
    if (task.priority == 'Low') priorityColor = AppTheme.info;

    const pendingColor = AppTheme.warning;
    const completedColor = AppTheme.success;
    const missedColor = AppTheme.error;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (task.isCompleted) {
      statusColor = completedColor;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = task.isCompletedLate ? 'Completed Late' : 'Completed';
    } else if (task.isNotCompleted) {
      statusColor = missedColor;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Not Completed';
    } else if (task.isMissed) {
      statusColor = missedColor;
      statusIcon = Icons.error_outline_rounded;
      statusLabel = 'Missed';
    } else {
      statusColor = pendingColor;
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'Pending';
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOwnerView && task.canMarkComplete) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: SizedBox(
                height: 22,
                width: 22,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: onToggleCompleted,
                  activeColor: completedColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted
                              ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                              : null,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 11,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            businessName,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOwnerView ? 'Assigned: $assigneeName' : 'By: $creatorName',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      height: 1.3,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${task.priority} Priority',
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: task.isMissed ? missedColor : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat.yMMMd().add_jm().format(task.dueDate)}',
                          style: TextStyle(
                            color: task.isMissed ? missedColor : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            fontWeight: task.isMissed ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (task.isMissed && (onResolveCompletedLate != null || onResolveNotCompleted != null)) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: missedColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: missedColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deadline passed. Select resolution outcome:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (onResolveCompletedLate != null)
                              InkWell(
                                onTap: onResolveCompletedLate,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: completedColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Completed Late',
                                    style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (onResolveNotCompleted != null)
                              InkWell(
                                onTap: onResolveNotCompleted,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: missedColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: missedColor),
                                  ),
                                  child: const Text(
                                    'Not Completed',
                                    style: TextStyle(color: missedColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isOwnerView) ...[
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit' && onEdit != null) onEdit!();
                if (val == 'delete' && onDelete != null) onDelete!();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (task.canMarkComplete && onMarkComplete != null) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded, color: completedColor, size: 22),
              onPressed: onMarkComplete,
              tooltip: 'Mark Complete',
            ),
          ],
        ],
      ),
    );
  }
}

