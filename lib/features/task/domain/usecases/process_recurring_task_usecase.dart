import 'package:bizos/core/utils/task_repeat_mapper.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class ProcessRecurringTaskUseCase {
  final TaskRepository repository;

  ProcessRecurringTaskUseCase(this.repository);

  /// Evaluates a task after a status change.
  /// If the task reached a final state ('Completed', 'Completed Late', 'Not Completed')
  /// and has an active recurring schedule (Daily, Weekly, Monthly, Yearly),
  /// calculates the next due date and generates the single next occurrence.
  Future<TaskModel?> execute(TaskModel task) async {
    final statusStr = task.status;
    final isFinalState = statusStr == 'Completed' ||
        statusStr == 'Completed Late' ||
        statusStr == 'Not Completed';

    if (!isFinalState) return null;

    final dbRepeat = TaskRepeatMapper.toDb(task.repeat);
    if (dbRepeat == TaskRepeatMapper.none) return null;

    final nextDueDate = calculateNextDueDate(task.dueDate, dbRepeat);

    final userId = task.createdBy.trim().isNotEmpty
        ? task.createdBy
        : task.assignedto;

    // Duplicate Prevention Check
    final exists = await repository.checkOccurrenceExists(
      title: task.title,
      repeat: dbRepeat,
      userId: userId,
      dueDate: nextDueDate,
    );

    if (exists) return null;

    final newTask = task.copyWith(
      id: const Uuid().v4(),
      dueDate: nextDueDate,
      status: 'Pending',
      isCompleted: false,
      completedAt: null,
      createdAt: DateTime.now(),
    );

    await repository.createTask(newTask);
    return newTask;
  }

  static DateTime calculateNextDueDate(DateTime currentDueDate, String repeatType) {
    final cleanRepeat = TaskRepeatMapper.toDb(repeatType);
    switch (cleanRepeat) {
      case TaskRepeatMapper.daily:
        return currentDueDate.add(const Duration(days: 1));
      case TaskRepeatMapper.weekly:
        return currentDueDate.add(const Duration(days: 7));
      case TaskRepeatMapper.monthly:
        var year = currentDueDate.year;
        var month = currentDueDate.month + 1;
        if (month > 12) {
          year += 1;
          month = 1;
        }
        final lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        final day = currentDueDate.day > lastDayOfNextMonth
            ? lastDayOfNextMonth
            : currentDueDate.day;
        return DateTime(
          year,
          month,
          day,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );
      case TaskRepeatMapper.yearly:
        final year = currentDueDate.year + 1;
        final month = currentDueDate.month;
        final lastDayOfMonth = DateTime(year, month + 1, 0).day;
        final day = currentDueDate.day > lastDayOfMonth
            ? lastDayOfMonth
            : currentDueDate.day;
        return DateTime(
          year,
          month,
          day,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );
      default:
        return currentDueDate;
    }
  }
}
