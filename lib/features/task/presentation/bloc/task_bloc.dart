import 'package:bizos/features/task/domain/usecases/process_recurring_task_usecase.dart';
import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:bizos/features/task/presentation/bloc/task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;
  final AuthBloc authBloc;
  final ProcessRecurringTaskUseCase processRecurringTaskUseCase;

  TaskBloc(
    this.taskRepository,
    this.authBloc, {
    ProcessRecurringTaskUseCase? processRecurringTaskUseCase,
  }) : processRecurringTaskUseCase =
           processRecurringTaskUseCase ??
           ProcessRecurringTaskUseCase(taskRepository),
       super(TaskInitial()) {
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
        final businessNames = await taskRepository.getBusinessNames(
          businessIds,
        );
        emit(
          TaskLoaded(tasks, userNames: userNames, businessNames: businessNames),
        );
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
        final businessNames = await taskRepository.getBusinessNames(
          businessIds,
        );
        emit(
          TaskLoaded(tasks, userNames: userNames, businessNames: businessNames),
        );
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<FetchPersonalTasksEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        final tasks = await taskRepository.getPersonalTasks(event.userId);
        final userIds = tasks
            .expand((t) => [t.assignedto, t.createdBy])
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final userNames = await taskRepository.getUserNames(userIds);
        emit(TaskLoaded(tasks, userNames: userNames, businessNames: const {}));
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<CreateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        await taskRepository.createTask(event.task);
        if (event.task.isPersonal || event.task.taskType == 'personal') {
          add(FetchPersonalTasksEvent(event.task.createdBy));
        } else if (event.isGlobal) {
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
        await _handleRecurringTask(event.task);
        if (event.task.isPersonal || event.task.taskType == 'personal') {
          add(FetchPersonalTasksEvent(event.task.createdBy));
        } else if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else {
          add(FetchTasksEvent(event.task.businessId));
        }
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<DuplicateTaskEvent>((event, emit) async {
      try {
        final duplicated = event.task.copyWith(
          id: '',
          title: '${event.task.title} (Copy)',
          createdAt: DateTime.now(),
          status: 'Pending',
          completedAt: null,
        );
        await taskRepository.createTask(duplicated);
        if (event.isPersonal || event.task.isPersonal) {
          add(FetchPersonalTasksEvent(event.task.createdBy));
        } else if (event.task.businessId.isNotEmpty) {
          add(FetchTasksEvent(event.task.businessId));
        } else {
          add(FetchAllTasksEvent());
        }
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });

    on<ToggleTaskStatusEvent>((event, emit) async {
      final previousState = state;
      try {
        final willBeCompleted = !event.task.isCompleted;
        final wasMissed =
            event.task.isMissed ||
            event.task.status == 'Completed Late' ||
            DateTime.now().isAfter(
              event.task.dueDate.add(const Duration(minutes: 30)),
            );

        final newStatus = willBeCompleted
            ? (wasMissed ? 'Completed Late' : 'Completed')
            : 'Pending';

        final updated = event.task.copyWith(
          status: newStatus,
          isCompleted: willBeCompleted,
          completedAt: willBeCompleted ? DateTime.now() : null,
        );

        if (state is TaskLoaded) {
          final loaded = state as TaskLoaded;
          final updatedTasks = loaded.tasks
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit(
            TaskLoaded(
              updatedTasks,
              userNames: loaded.userNames,
              businessNames: loaded.businessNames,
            ),
          );
        }

        await taskRepository.updateTask(updated);
        await _handleRecurringTask(updated);
      } catch (e) {
        if (previousState is TaskLoaded) {
          emit(previousState);
        }
        emit(TaskError('Failed to update task: ${e.toString()}'));
      }
    });

    on<ResolveMissedTaskEvent>((event, emit) async {
      final previousState = state;
      try {
        final newStatus = event.outcomeStatus;
        final isComp =
            newStatus == 'Completed' || newStatus == 'Completed Late';
        final updated = event.task.copyWith(
          status: newStatus,
          isCompleted: isComp,
          completedAt: isComp ? DateTime.now() : null,
        );

        if (state is TaskLoaded) {
          final loaded = state as TaskLoaded;
          final updatedTasks = loaded.tasks
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit(
            TaskLoaded(
              updatedTasks,
              userNames: loaded.userNames,
              businessNames: loaded.businessNames,
            ),
          );
        }

        await taskRepository.updateTask(updated);
        await _handleRecurringTask(updated);
      } catch (e) {
        if (previousState is TaskLoaded) {
          emit(previousState);
        }
        emit(TaskError('Failed to update task: ${e.toString()}'));
      }
    });

    on<DeleteTaskEvent>((event, emit) async {
      emit(TaskLoading());
      try {
        await taskRepository.deleteTask(event.id);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else if (event.businessId.isEmpty) {
          add(FetchPersonalTasksEvent(event.userId));
        } else {
          add(FetchTasksEvent(event.businessId));
        }
      } catch (e) {
        emit(TaskError(e.toString()));
      }
    });
  }

  Future<void> _handleRecurringTask(TaskModel task) async {
    try {
      final nextTask = await processRecurringTaskUseCase.execute(task);
      if (nextTask != null) {
        final userId = nextTask.createdBy.isNotEmpty
            ? nextTask.createdBy
            : nextTask.assignedto;
        if (nextTask.isPersonal || nextTask.taskType == 'personal') {
          add(FetchPersonalTasksEvent(userId));
        } else if (nextTask.businessId.isNotEmpty) {
          add(FetchTasksEvent(nextTask.businessId));
        } else {
          add(FetchAllTasksEvent());
        }
      }
    } catch (e) {
      print("Error processing recurring task occurrence: $e");
    }
  }
}
