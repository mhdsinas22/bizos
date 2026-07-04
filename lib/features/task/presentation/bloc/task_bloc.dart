import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:bizos/features/task/presentation/bloc/task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;
  final AuthBloc authBloc;

  TaskBloc(this.taskRepository, this.authBloc) : super(TaskInitial()) {
    on<FetchTasksEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        final authState = authBloc.state;
        final user = authState.user;
        if (user == null) {
          emit(TaskError('User not authenticated'));
          return;
        }
        final tasks = await taskRepository.getTasks(
          event.businessId,
          user.id,
          user.isOwner,
        );
        final userIds = tasks
            .expand((t) => [t.assignedto, t.createdBy])
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final userNames = await taskRepository.getUserNames(userIds);
        final businessIds = tasks
            .map((t) => t.businessId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final businessNames = await taskRepository.getBusinessNames(businessIds);
        emit(TaskLoaded(tasks, userNames: userNames, businessNames: businessNames));
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<FetchAllTasksEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        final authState = authBloc.state;
        final user = authState.user;
        if (user == null) {
          emit(TaskError('User not authenticated'));
          return;
        }
        var tasks = await taskRepository.getAllTasks(
          userId: user.id,
          isOwner: user.isOwner,
        );
        if (user.isStaff) {
          // Staff can only see tasks assigned to them
          tasks = tasks.where((t) => t.assignedto == user.id).toList();
        }
        final userIds = tasks
            .expand((t) => [t.assignedto, t.createdBy])
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final userNames = await taskRepository.getUserNames(userIds);
        final businessIds = tasks
            .map((t) => t.businessId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final businessNames = await taskRepository.getBusinessNames(businessIds);
        emit(TaskLoaded(tasks, userNames: userNames, businessNames: businessNames));
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<CreateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        await taskRepository.createTask(event.task);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else {
          add(FetchTasksEvent(event.task.businessId));
        }
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<UpdateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        await taskRepository.updateTask(event.task);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else {
          add(FetchTasksEvent(event.task.businessId));
        }
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<ToggleTaskStatusEvent>((event, emit) async {
      try {
        final updated = event.task.copyWith(
          isCompleted: !event.task.isCompleted,
        );
        await taskRepository.updateTask(updated);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else {
          add(FetchTasksEvent(event.task.businessId));
        }
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<DeleteTaskEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        await taskRepository.deleteTask(event.id);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else {
          add(FetchTasksEvent(event.businessId));
        }
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });
  }
}

