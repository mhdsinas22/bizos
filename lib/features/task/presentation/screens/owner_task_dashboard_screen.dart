import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';
import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:bizos/features/task/presentation/bloc/task_state.dart';
import 'package:bizos/features/task/presentation/widgets/task_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/task/presentation/widgets/task_card.dart';

class OwnerTaskDashboardScreen extends StatefulWidget {
  const OwnerTaskDashboardScreen({super.key});

  @override
  State<OwnerTaskDashboardScreen> createState() =>
      _OwnerTaskDashboardScreenState();
}

class _OwnerTaskDashboardScreenState extends State<OwnerTaskDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all tasks globally when dashboard loads
    context.read<TaskBloc>().add(FetchAllTasksEvent());
  }

  void _showTaskForm(UserModel user, {TaskModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskFormSheet(
        user: user,
        task: task,
        isGlobal: true,
        onSave: () {
          context.read<TaskBloc>().add(FetchAllTasksEvent());
        },
      ),
    );
  }

  void _confirmDelete(TaskModel task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TaskBloc>().add(
                DeleteTaskEvent(task.id, task.businessId, isGlobal: true),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return const Center(child: Text('User not authenticated'));
    }

    final ownerId = user.id;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showTaskForm(user),
          icon: const Icon(Icons.add),
          label: const Text('Create Task'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<TaskBloc, TaskState>(
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
              final allTasks = state.tasks;

              // Compute statistics (safely isolated to this owner)
              final totalCount = allTasks.length;
              final completedCount = allTasks.where((t) => t.isCompleted).length;
              final pendingCount = totalCount - completedCount;
              final assignedCount = allTasks.where((t) => t.assignedto != ownerId).length;

              // Filtered subsets for each tab
              final myTasks = allTasks.where((t) => t.assignedto == ownerId).toList();
              final staffTasks = allTasks.where((t) => t.assignedto != ownerId).toList();

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
                        child: _buildStatsGrid(
                          total: totalCount,
                          pending: pendingCount,
                          completed: completedCount,
                          assigned: assignedCount,
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverPersistentHeaderDelegate(
                        TabBar(
                          indicatorColor: AppTheme.primaryColor,
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'All Tasks'),
                            Tab(text: 'My Tasks'),
                            Tab(text: 'Staff Tasks'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _buildTabContent(allTasks, user, state.userNames, state.businessNames, 'All'),
                    _buildTabContent(myTasks, user, state.userNames, state.businessNames, 'My'),
                    _buildTabContent(staffTasks, user, state.userNames, state.businessNames, 'Staff'),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTabContent(
    List<TaskModel> tasks,
    UserModel user,
    Map<String, String> userNames,
    Map<String, String> businessNames,
    String tabType,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            tabType == 'My'
                ? 'No tasks assigned to you.'
                : tabType == 'Staff'
                    ? 'No tasks assigned to staff.'
                    : 'No tasks found.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskBloc>().add(FetchAllTasksEvent());
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 80.0),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = tasks[index];
          return TaskCard(
            task: t,
            currentUser: user,
            userNames: userNames,
            businessNames: businessNames,
            isOwnerView: true,
            onToggleCompleted: (val) {
              context.read<TaskBloc>().add(
                    ToggleTaskStatusEvent(t, isGlobal: true),
                  );
            },
            onEdit: () => _showTaskForm(user, task: t),
            onDelete: () => _confirmDelete(t),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid({
    required int total,
    required int pending,
    required int completed,
    required int assigned,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isTablet ? 1.5 : 1.6,
      children: [
        _buildStatCard(
          title: 'Total Tasks',
          value: '$total',
          icon: Icons.checklist_outlined,
          color: AppTheme.info,
        ),
        _buildStatCard(
          title: 'Pending Tasks',
          value: '$pending',
          icon: Icons.hourglass_empty_outlined,
          color: AppTheme.warning,
        ),
        _buildStatCard(
          title: 'Completed Tasks',
          value: '$completed',
          icon: Icons.task_alt_outlined,
          color: AppTheme.success,
        ),
        _buildStatCard(
          title: 'Assigned Tasks',
          value: '$assigned',
          icon: Icons.assignment_ind_outlined,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor.withOpacity(0.4) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.labelLarge?.color?.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverPersistentHeaderDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
