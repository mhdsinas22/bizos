import 'package:equatable/equatable.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

abstract class BusinessTaskEvent extends Equatable {
  const BusinessTaskEvent();

  @override
  List<Object?> get props => [];
}

class FetchTasksEvent extends BusinessTaskEvent {
  final String businessId;

  const FetchTasksEvent(this.businessId);

  @override
  List<Object?> get props => [businessId];
}

class FetchAllTasksEvent extends BusinessTaskEvent {}

class CreateBusinessTaskEvent extends BusinessTaskEvent {
  final TaskModel task;
  final bool isGlobal;

  const CreateBusinessTaskEvent(this.task, {this.isGlobal = false});

  @override
  List<Object?> get props => [task, isGlobal];
}

class UpdateBusinessTaskEvent extends BusinessTaskEvent {
  final TaskModel task;
  final bool isGlobal;

  const UpdateBusinessTaskEvent(this.task, {this.isGlobal = false});

  @override
  List<Object?> get props => [task, isGlobal];
}

class DuplicateBusinessTaskEvent extends BusinessTaskEvent {
  final TaskModel task;
  final bool isPersonal;

  const DuplicateBusinessTaskEvent(this.task, {this.isPersonal = false});

  @override
  List<Object?> get props => [task, isPersonal];
}

class ToggleBusinessTaskStatusEvent extends BusinessTaskEvent {
  final TaskModel task;

  const ToggleBusinessTaskStatusEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class ResolveMissedBusinessTaskEvent extends BusinessTaskEvent {
  final TaskModel task;
  final String outcomeStatus;

  const ResolveMissedBusinessTaskEvent(
    this.task, {
    required this.outcomeStatus,
  });

  @override
  List<Object?> get props => [task, outcomeStatus];
}

class DeleteBusinessTaskEvent extends BusinessTaskEvent {
  final String id;
  final String businessId;
  final String userId;
  final bool isGlobal;

  const DeleteBusinessTaskEvent(
    this.id,
    this.businessId,
    this.userId, {
    this.isGlobal = false,
  });

  @override
  List<Object?> get props => [id, businessId, userId, isGlobal];
}
