import 'package:flutter/material.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/widgets/overdue_task_decision_sheet.dart';
import 'package:bizos/features/task/presentation/widgets/task_details_sheet.dart';

class TaskInteractionHandler {
  static void handleTaskTap(
    BuildContext context, {
    required TaskModel task,
    VoidCallback? onMarkComplete,
    VoidCallback? onResolveCompletedLate,
    VoidCallback? onResolveNotCompleted,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String? assigneeName,
    String? creatorName,
    String? businessName,
  }) {
    if (task.isMissed) {
      OverdueTaskDecisionSheet.show(
        context,
        task: task,
        onResolveCompletedLate: onResolveCompletedLate ?? onMarkComplete,
        onResolveNotCompleted: onResolveNotCompleted,
        onEdit: onEdit,
        onDelete: onDelete,
        assigneeName: assigneeName,
        creatorName: creatorName,
        businessName: businessName,
      );
    } else {
      TaskDetailsSheet.show(
        context,
        task: task,
        onMarkComplete: onMarkComplete,
        onEdit: onEdit,
        onDelete: onDelete,
        assigneeName: assigneeName,
        creatorName: creatorName,
        businessName: businessName,
      );
    }
  }
}
