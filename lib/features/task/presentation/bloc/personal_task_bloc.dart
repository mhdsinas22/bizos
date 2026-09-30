import 'package:bizos/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';
import 'package:bizos/features/task/domain/usecases/process_recurring_task_usecase.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'personal_task_event.dart';
import 'personal_task_state.dart';

class PersonalTaskBloc extends Bloc<PersonalTaskEvent, PersonalTaskState> {
  final TaskRepository taskRepository;
  final AuthBloc authBloc;
  final ProcessRecurringTaskUseCase processRecurringTaskUseCase;

  PersonalTaskBloc(
    this.taskRepository,
    this.authBloc, {
    ProcessRecurringTaskUseCase? processRecurringTaskUseCase,
  }) : processRecurringTaskUseCase =
           processRecurringTaskUseCase ??
           ProcessRecurringTaskUseCase(taskRepository),
       super(PersonalTaskInitial()) {
    on<FetchPersonalTasksEvent>((event, emit) async {
      emit(PersonalTaskLoading());
      try {
        final tasks = await taskRepository.getPersonalTasks(event.userId);
        final userIds = tasks
            .expand((t) => [t.assignedto, t.createdBy])
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final userNames = await taskRepository.getUserNames(userIds);
        emit(PersonalTaskLoaded(tasks, userNames: userNames));
      } catch (e) {
        emit(PersonalTaskError(e.toString()));
      }
    });

    on<CreatePersonalTaskEvent>((event, emit) async {
      emit(PersonalTaskLoading());
      try {
        await taskRepository.createTask(event.task);
        add(FetchPersonalTasksEvent(event.task.createdBy));
      } catch (e) {
        emit(PersonalTaskError(e.toString()));
      }
    });

    on<UpdatePersonalTaskEvent>((event, emit) async {
      emit(PersonalTaskLoading());
      try {
        await taskRepository.updateTask(event.task);
        await _handleRecurringTask(event.task);
        add(FetchPersonalTasksEvent(event.task.createdBy));
      } catch (e) {
        emit(PersonalTaskError(e.toString()));
      }
    });

    on<DuplicatePersonalTaskEvent>((event, emit) async {
      try {
        final duplicated = event.task.copyWith(
          id: '',
          title: '${event.task.title} (Copy)',
          createdAt: DateTime.now(),
          status: 'Pending',
          completedAt: null,
        );
        await taskRepository.createTask(duplicated);
        add(FetchPersonalTasksEvent(event.task.createdBy));
      } catch (e) {
        emit(PersonalTaskError(e.toString()));
      }
    });

    on<TogglePersonalTaskStatusEvent>((event, emit) async {
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

        if (state is PersonalTaskLoaded) {
          final loaded = state as PersonalTaskLoaded;
          final updatedTasks = loaded.tasks
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit(PersonalTaskLoaded(updatedTasks, userNames: loaded.userNames));
        }

        await taskRepository.updateTask(updated);
        await _handleRecurringTask(updated);
      } catch (e) {
        if (previousState is PersonalTaskLoaded) {
          emit(previousState);
        }
        emit(PersonalTaskError('Failed to update task: ${e.toString()}'));
      }
    });

    on<ResolveMissedPersonalTaskEvent>((event, emit) async {
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

        if (state is PersonalTaskLoaded) {
          final loaded = state as PersonalTaskLoaded;
          final updatedTasks = loaded.tasks
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit(PersonalTaskLoaded(updatedTasks, userNames: loaded.userNames));
        }

        await taskRepository.updateTask(updated);
        await _handleRecurringTask(updated);
      } catch (e) {
        if (previousState is PersonalTaskLoaded) {
          emit(previousState);
        }
        emit(PersonalTaskError('Failed to update task: ${e.toString()}'));
      }
    });

    on<DeletePersonalTaskEvent>((event, emit) async {
      emit(PersonalTaskLoading());
      try {
        await taskRepository.deleteTask(event.id);
        add(FetchPersonalTasksEvent(event.userId));
      } catch (e) {
        emit(PersonalTaskError(e.toString()));
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
        add(FetchPersonalTasksEvent(userId));
      }
    } catch (e) {
      AppLogger.error("Error processing recurring personal task occurrence: $e");
    }
  }
}
