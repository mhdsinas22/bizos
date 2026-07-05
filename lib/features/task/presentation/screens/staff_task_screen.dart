import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';
import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:bizos/features/task/presentation/bloc/task_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/task/presentation/widgets/task_card.dart';

class StaffTaskScreen extends StatefulWidget {
  const StaffTaskScreen({super.key});

  @override
  State<StaffTaskScreen> createState() => _StaffTaskScreenState();
}

class _StaffTaskScreenState extends State<StaffTaskScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch staff tasks globally on load
    context.read<TaskBloc>().add(FetchAllTasksEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return const Center(child: Text('User not authenticated'));
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? AppTheme.darkBorder
                      : AppTheme.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tasks',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep track of your assigned checklist items',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Task List View
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TaskError) {
                  return Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  );
                }

                if (state is TaskLoaded) {
                  // Filter defensively to only show tasks assigned to this staff member
                  final assignedTasks = state.tasks
                      .where((t) => t.assignedto == user.id)
                      .toList();

                  if (assignedTasks.isEmpty) {
                    return const EmptyState(
                      icon: Icons.checklist,
                      title: 'No Assigned Tasks',
                      message:
                          'You currently do not have any tasks assigned to you.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TaskBloc>().add(FetchAllTasksEvent());
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: assignedTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = assignedTasks[index];
                        return _buildStaffTaskCard(
                          t,
                          user,
                          state.userNames,
                          state.businessNames,
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTaskCard(
    TaskModel t,
    UserModel user,
    Map<String, String> userNames,
    Map<String, String> businessNames,
  ) {
    return TaskCard(
      task: t,
      currentUser: user,
      userNames: userNames,
      businessNames: businessNames,
      isOwnerView: false,
      onMarkComplete: () {
        context.read<TaskBloc>().add(ToggleTaskStatusEvent(t, isGlobal: true));
      },
    );
  }
}
