import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/task/presentation/bloc/business_task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';
import 'package:bizos/features/task/domain/usecases/process_recurring_task_usecase.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'business_task_event.dart';

class BusinessTaskBloc extends Bloc<BusinessTaskEvent, BusinessTaskState> {
  final TaskRepository taskRepository;
  final AuthBloc authBloc;
  final ProcessRecurringTaskUseCase processRecurringTaskUseCase;

  BusinessTaskBloc(
    this.taskRepository,
    this.authBloc, {
    ProcessRecurringTaskUseCase? processRecurringTaskUseCase,
  }) : processRecurringTaskUseCase =
           processRecurringTaskUseCase ??
           ProcessRecurringTaskUseCase(taskRepository),
       super(BusinessTaskInitial()) {
    on<FetchTasksEvent>((event, emit) async {
      emit(BusinessTaskLoading());
      try {
        final authState = authBloc.state;
        final user = authState.user;
        if (user == null) {
          emit(const BusinessTaskError('User not authenticated'));
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
          BusinessTaskLoaded(
            tasks,
            userNames: userNames,
            businessNames: businessNames,
          ),
        );
      } catch (e) {
        emit(BusinessTaskError(e.toString()));
      }
    });

    on<FetchAllTasksEvent>((event, emit) async {
      emit(BusinessTaskLoading());
      try {
        final authState = authBloc.state;
        final user = authState.user;
        if (user == null) {
          emit(const BusinessTaskError('User not authenticated'));
          return;
        }
        var tasks = await taskRepository.getAllTasks(
          userId: user.id,
          isOwner: user.isOwner,
        );
        if (user.isStaff) {
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
          BusinessTaskLoaded(
            tasks,
            userNames: userNames,
            businessNames: businessNames,
          ),
        );
      } catch (e) {
        emit(BusinessTaskError(e.toString()));
      }
    });

    on<CreateBusinessTaskEvent>((event, emit) async {
      emit(BusinessTaskLoading());
      try {
        await taskRepository.createTask(event.task);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else {
          add(FetchTasksEvent(event.task.businessId));
        }
      } catch (e) {
        emit(BusinessTaskError(e.toString()));
      }
    });

    on<UpdateBusinessTaskEvent>((event, emit) async {
      emit(BusinessTaskLoading());
      try {
        await taskRepository.updateTask(event.task);
        await _handleRecurringTask(event.task);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else {
          add(FetchTasksEvent(event.task.businessId));
        }
      } catch (e) {
        emit(BusinessTaskError(e.toString()));
      }
    });

    on<DuplicateBusinessTaskEvent>((event, emit) async {
      try {
        final duplicated = event.task.copyWith(
          id: '',
          title: '${event.task.title} (Copy)',
          createdAt: DateTime.now(),
          status: 'Pending',
          completedAt: null,
        );
        await taskRepository.createTask(duplicated);
        if (event.task.businessId.isNotEmpty) {
          add(FetchTasksEvent(event.task.businessId));
        } else {
          add(FetchAllTasksEvent());
        }
      } catch (e) {
        emit(BusinessTaskError(e.toString()));
      }
    });

    on<ToggleBusinessTaskStatusEvent>((event, emit) async {
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

        if (state is BusinessTaskLoaded) {
          final loaded = state as BusinessTaskLoaded;
          final updatedTasks = loaded.tasks
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit(
            BusinessTaskLoaded(
              updatedTasks,
              userNames: loaded.userNames,
              businessNames: loaded.businessNames,
            ),
          );
        }

        await taskRepository.updateTask(updated);
        await _handleRecurringTask(updated);
      } catch (e) {
        if (previousState is BusinessTaskLoaded) {
          emit(previousState);
        }
        emit(BusinessTaskError('Failed to update task: ${e.toString()}'));
      }
    });

    on<ResolveMissedBusinessTaskEvent>((event, emit) async {
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

        if (state is BusinessTaskLoaded) {
          final loaded = state as BusinessTaskLoaded;
          final updatedTasks = loaded.tasks
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit(
            BusinessTaskLoaded(
              updatedTasks,
              userNames: loaded.userNames,
              businessNames: loaded.businessNames,
            ),
          );
        }

        await taskRepository.updateTask(updated);
        await _handleRecurringTask(updated);
      } catch (e) {
        if (previousState is BusinessTaskLoaded) {
          emit(previousState);
        }
        emit(BusinessTaskError('Failed to update task: ${e.toString()}'));
      }
    });

    on<DeleteBusinessTaskEvent>((event, emit) async {
      emit(BusinessTaskLoading());
      try {
        await taskRepository.deleteTask(event.id);
        if (event.isGlobal) {
          add(FetchAllTasksEvent());
        } else if (event.businessId.isNotEmpty) {
          add(FetchTasksEvent(event.businessId));
        } else {
          add(FetchAllTasksEvent());
        }
      } catch (e) {
        emit(BusinessTaskError(e.toString()));
      }
    });
  }

  Future<void> _handleRecurringTask(TaskModel task) async {
    try {
      final nextTask = await processRecurringTaskUseCase.execute(task);
      if (nextTask != null) {
        if (nextTask.businessId.isNotEmpty) {
          add(FetchTasksEvent(nextTask.businessId));
        } else {
          add(FetchAllTasksEvent());
        }
      }
    } catch (e) {
      AppLogger.error("Error processing recurring business task occurrence: $e");
    }
  }
}
