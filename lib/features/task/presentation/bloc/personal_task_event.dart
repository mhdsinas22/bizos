import 'package:equatable/equatable.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

abstract class PersonalTaskEvent extends Equatable {
  const PersonalTaskEvent();

  @override
  List<Object?> get props => [];
}

class FetchPersonalTasksEvent extends PersonalTaskEvent {
  final String userId;

  const FetchPersonalTasksEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreatePersonalTaskEvent extends PersonalTaskEvent {
  final TaskModel task;

  const CreatePersonalTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdatePersonalTaskEvent extends PersonalTaskEvent {
  final TaskModel task;

  const UpdatePersonalTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class DuplicatePersonalTaskEvent extends PersonalTaskEvent {
  final TaskModel task;

  const DuplicatePersonalTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class TogglePersonalTaskStatusEvent extends PersonalTaskEvent {
  final TaskModel task;

  const TogglePersonalTaskStatusEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class ResolveMissedPersonalTaskEvent extends PersonalTaskEvent {
  final TaskModel task;
  final String outcomeStatus;

  const ResolveMissedPersonalTaskEvent(
    this.task, {
    required this.outcomeStatus,
  });

  @override
  List<Object?> get props => [task, outcomeStatus];
}

class DeletePersonalTaskEvent extends PersonalTaskEvent {
  final String id;
  final String userId;

  const DeletePersonalTaskEvent(this.id, this.userId);

  @override
  List<Object?> get props => [id, userId];
}
