import 'package:bizos/features/task/data/models/task_model.dart';

abstract class TaskEvent {}

class FetchTasksEvent extends TaskEvent {
  final String businessId;
  FetchTasksEvent(this.businessId);
}

class FetchAllTasksEvent extends TaskEvent {}

class CreateTaskEvent extends TaskEvent {
  final TaskModel task;
  final bool isGlobal;
  CreateTaskEvent(this.task, {this.isGlobal = false});
}

class UpdateTaskEvent extends TaskEvent {
  final TaskModel task;
  final bool isGlobal;
  UpdateTaskEvent(this.task, {this.isGlobal = false});
}

class ToggleTaskStatusEvent extends TaskEvent {
  final TaskModel task;
  final bool isGlobal;
  ToggleTaskStatusEvent(this.task, {this.isGlobal = false});
}

class DeleteTaskEvent extends TaskEvent {
  final String id;
  final String businessId;
  final bool isGlobal;
  DeleteTaskEvent(this.id, this.businessId, {this.isGlobal = false});
}

