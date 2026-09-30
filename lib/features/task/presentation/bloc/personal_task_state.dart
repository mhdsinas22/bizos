import 'package:equatable/equatable.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

abstract class PersonalTaskState extends Equatable {
  const PersonalTaskState();

  @override
  List<Object?> get props => [];
}

class PersonalTaskInitial extends PersonalTaskState {}

class PersonalTaskLoading extends PersonalTaskState {}

class PersonalTaskLoaded extends PersonalTaskState {
  final List<TaskModel> tasks;
  final Map<String, String> userNames;

  const PersonalTaskLoaded(
    this.tasks, {
    this.userNames = const {},
  });

  @override
  List<Object?> get props => [tasks, userNames];
}

class PersonalTaskError extends PersonalTaskState {
  final String message;

  const PersonalTaskError(this.message);

  @override
  List<Object?> get props => [message];
}
