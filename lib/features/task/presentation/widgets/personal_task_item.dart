import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/utils/task_repeat_mapper.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/core/theme/app_theme.dart';

class PersonalTaskItem extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<bool?> onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final VoidCallback onResolveCompletedLate;
  final VoidCallback onResolveNotCompleted;

  const PersonalTaskItem({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
    required this.onResolveCompletedLate,
    required this.onResolveNotCompleted,
  });

  void _showMissedOutcomeSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Task Deadline Missed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select the final outcome for "${task.title}":',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Completed Late',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Mark this task as finished after deadline',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 350));
                  onResolveCompletedLate();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        content: Row(
                          children: const [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Task marked as Completed Late.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Not Completed',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Mark this task as unfulfilled',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 350));
                  onResolveNotCompleted();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        content: Row(
                          children: const [
                            Icon(
                              Icons.cancel_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '❌ Task marked as Not Completed.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color priorityColor = Colors.grey;
    if (task.priority == 'High') priorityColor = const Color(0xFFEF4444);
    if (task.priority == 'Medium') priorityColor = const Color(0xFFF59E0B);
    if (task.priority == 'Low') priorityColor = AppTheme.info;

    final isMissed = task.isMissed;
    final isNotCompleted = task.isNotCompleted;
    final isCompleted = task.isCompleted;
    final isFinalized = isCompleted || isNotCompleted;

    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
              ),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (isFinalized) return false;
        if (direction == DismissDirection.startToEnd) {
          onToggleComplete(!task.isCompleted);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return false;
        }
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          onTap: isMissed ? () => _showMissedOutcomeSheet(context) : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(minHeight: 64, maxHeight: 76),
            decoration: BoxDecoration(
              color: isNotCompleted
                  ? (isDark
                        ? const Color(0xFFEF4444).withValues(alpha: 0.04)
                        : const Color(0xFFEF4444).withValues(alpha: 0.03))
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMissed
                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                    : isNotCompleted
                    ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                    : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                width: (isMissed || isNotCompleted) ? 1.0 : 0.8,
              ),
            ),
            child: Row(
              children: [
                // Custom Sleek Checkbox
                GestureDetector(
                  onTap: isFinalized
                      ? null
                      : () => onToggleComplete(!task.isCompleted),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : isNotCompleted
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : isNotCompleted
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white38 : Colors.black38),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : isNotCompleted
                        ? const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFFEF4444),
                          )
                        : null,
                  ),
                ),

                // Title & Details Column
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompleted
                              ? theme.disabledColor
                              : isNotCompleted
                              ? (isDark ? Colors.white54 : Colors.black45)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Badges Row
                      Row(
                        children: [
                          // Time Badge
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isMissed
                                ? const Color(0xFFEF4444)
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat.jm().format(task.dueDate),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isMissed
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isMissed
                                  ? const Color(0xFFEF4444)
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),

                          // Missed Compact Badge
                          if (isMissed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Overdue',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],

                          // Not Completed Final Badge
                          if (isNotCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.cancel_rounded,
                                    size: 10,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Not Completed',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Repeat Badge
                          if (TaskRepeatMapper.isRepeating(task.repeat)) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.repeat_rounded,
                              size: 12,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              TaskRepeatMapper.toUi(task.repeat),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Priority Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),

                // Trailing Menu Button
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  onPressed: onLongPress,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Options',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
