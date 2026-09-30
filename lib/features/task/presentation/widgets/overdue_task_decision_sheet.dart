import 'package:flutter/material.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/widgets/task_details_sheet.dart';

class OverdueTaskDecisionSheet extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onResolveCompletedLate;
  final VoidCallback? onResolveNotCompleted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? assigneeName;
  final String? creatorName;
  final String? businessName;

  const OverdueTaskDecisionSheet({
    super.key,
    required this.task,
    this.onResolveCompletedLate,
    this.onResolveNotCompleted,
    this.onEdit,
    this.onDelete,
    this.assigneeName,
    this.creatorName,
    this.businessName,
  });

  static Future<void> show(
    BuildContext context, {
    required TaskModel task,
    VoidCallback? onResolveCompletedLate,
    VoidCallback? onResolveNotCompleted,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String? assigneeName,
    String? creatorName,
    String? businessName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => OverdueTaskDecisionSheet(
        task: task,
        onResolveCompletedLate: onResolveCompletedLate,
        onResolveNotCompleted: onResolveNotCompleted,
        onEdit: onEdit,
        onDelete: onDelete,
        assigneeName: assigneeName,
        creatorName: creatorName,
        businessName: businessName,
      ),
    );
  }

  void _openTaskDetails(BuildContext context) {
    Navigator.pop(context);
    TaskDetailsSheet.show(
      context,
      task: task,
      onMarkComplete: onResolveCompletedLate,
      onEdit: onEdit,
      onDelete: onDelete,
      assigneeName: assigneeName,
      creatorName: creatorName,
      businessName: businessName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: ResponsiveCenterBody(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Deadline Missed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose what happened with this task.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Option 1: Completed Late
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppTheme.success,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Completed Late',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  'Mark this task as completed after its deadline.',
                  style: TextStyle(fontSize: 12.5),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onResolveCompletedLate != null) {
                    onResolveCompletedLate!();
                  }
                },
              ),

              const Divider(height: 1),

              // Option 2: Not Completed
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: AppTheme.error,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Not Completed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  'Keep this task as missed.',
                  style: TextStyle(fontSize: 12.5),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (onResolveNotCompleted != null) {
                    onResolveNotCompleted!();
                  }
                },
              ),

              const Divider(height: 1),

              // Option 3: View Task
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'View Task',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  'Open full task details without changing status.',
                  style: TextStyle(fontSize: 12.5),
                ),
                onTap: () => _openTaskDetails(context),
              ),

              const SizedBox(height: 16),

              // Cancel Action
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
