import 'package:bizos/features/task/data/models/task_model.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final Map<String, String> userNames;
  final Map<String, String> businessNames;
  TaskLoaded(
    this.tasks, {
    this.userNames = const {},
    this.businessNames = const {},
  });
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}
