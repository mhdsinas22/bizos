import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/task_repeat_mapper.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

class TaskDetailsSheet extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? assigneeName;
  final String? creatorName;
  final String? businessName;

  const TaskDetailsSheet({
    super.key,
    required this.task,
    this.onMarkComplete,
    this.onEdit,
    this.onDelete,
    this.assigneeName,
    this.creatorName,
    this.businessName,
  });

  static Future<void> show(
    BuildContext context, {
    required TaskModel task,
    VoidCallback? onMarkComplete,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String? assigneeName,
    String? creatorName,
    String? businessName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskDetailsSheet(
        task: task,
        onMarkComplete: onMarkComplete,
        onEdit: onEdit,
        onDelete: onDelete,
        assigneeName: assigneeName,
        creatorName: creatorName,
        businessName: businessName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color priorityColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    if (task.priority == 'High') priorityColor = AppTheme.error;
    if (task.priority == 'Medium') priorityColor = AppTheme.warning;
    if (task.priority == 'Low') priorityColor = AppTheme.info;

    Color statusColor;
    IconData statusIcon;
    String statusLabel = task.status;

    if (task.isCompleted) {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (task.isNotCompleted) {
      statusColor = AppTheme.error;
      statusIcon = Icons.cancel_rounded;
    } else if (task.isMissed) {
      statusColor = AppTheme.error;
      statusIcon = Icons.error_outline_rounded;
    } else {
      statusColor = AppTheme.warning;
      statusIcon = Icons.schedule_rounded;
    }

    final formattedDueDate = DateFormat.yMMMMd().format(task.dueDate);
    final formattedDueTime = DateFormat.jm().format(task.dueDate);
    final formattedCreatedAt =
        DateFormat.yMMMd().add_jm().format(task.createdAt);
    final formattedLastUpdated = task.completedAt != null
        ? DateFormat.yMMMd().add_jm().format(task.completedAt!)
        : formattedCreatedAt;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: ResponsiveCenterBody(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Close Button Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status, Priority & Category Badges Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Priority Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${task.priority} Priority',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),

                  // Task Type / Business Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      businessName != null && businessName!.isNotEmpty
                          ? businessName!
                          : (task.isBusiness ? 'Business Task' : 'Personal To-Do'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Description Section
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                task.description.trim().isNotEmpty
                    ? task.description
                    : 'No description provided for this task.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontStyle: task.description.trim().isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: task.description.trim().isEmpty
                      ? theme.disabledColor
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // Metadata Details Cards
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Due Date',
                      value: '$formattedDueDate at $formattedDueTime',
                    ),
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.notifications_none_rounded,
                      label: 'Reminder Time',
                      value: task.isNotified
                          ? 'Reminder Sent ($formattedDueTime)'
                          : 'Set for $formattedDueTime',
                    ),
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.repeat_rounded,
                      label: 'Repeat Schedule',
                      value: TaskRepeatMapper.toUi(task.repeat),
                    ),
                    if (assigneeName != null && assigneeName!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Assigned To',
                        value: assigneeName!,
                      ),
                    ],
                    if (creatorName != null && creatorName!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _DetailRow(
                        icon: Icons.create_outlined,
                        label: 'Created By',
                        value: creatorName!,
                      ),
                    ],
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Created Date',
                      value: formattedCreatedAt,
                    ),
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.update_rounded,
                      label: 'Last Updated',
                      value: formattedLastUpdated,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Attachments Section (Future ready)
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attachment_rounded,
                      color: theme.disabledColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No attachments linked to this task',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.disabledColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (onMarkComplete != null && !task.isCompleted) ...[
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onMarkComplete!();
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (onEdit != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit!();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (onDelete != null) ...[
                    IconButton.outlined(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete!();
                      },
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      tooltip: 'Delete Task',
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.disabledColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: theme.disabledColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
