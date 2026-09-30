import 'package:equatable/equatable.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

abstract class BusinessTaskState extends Equatable {
  const BusinessTaskState();

  @override
  List<Object?> get props => [];
}

class BusinessTaskInitial extends BusinessTaskState {}

class BusinessTaskLoading extends BusinessTaskState {}

class BusinessTaskLoaded extends BusinessTaskState {
  final List<TaskModel> tasks;
  final Map<String, String> userNames;
  final Map<String, String> businessNames;

  const BusinessTaskLoaded(
    this.tasks, {
    this.userNames = const {},
    this.businessNames = const {},
  });

  @override
  List<Object?> get props => [tasks, userNames, businessNames];
}

class BusinessTaskError extends BusinessTaskState {
  final String message;

  const BusinessTaskError(this.message);

  @override
  List<Object?> get props => [message];
}
