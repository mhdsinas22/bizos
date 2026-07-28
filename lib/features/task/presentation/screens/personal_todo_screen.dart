import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/utils/task_repeat_mapper.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';
import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:bizos/features/task/presentation/bloc/task_state.dart';
import 'package:bizos/features/task/presentation/widgets/personal_task_item.dart';
import 'package:bizos/features/task/presentation/widgets/personal_task_form_sheet.dart';
import 'package:bizos/features/task/presentation/widgets/personal_task_options_sheet.dart';
import 'package:bizos/features/task/presentation/widgets/personal_filter_sheet.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/core/widgets/error_state.dart';

class PersonalToDoScreen extends StatefulWidget {
  const PersonalToDoScreen({super.key});

  @override
  State<PersonalToDoScreen> createState() => _PersonalToDoScreenState();
}

class _PersonalToDoScreenState extends State<PersonalToDoScreen> {
  late DateTime _selectedDate;
  late DateTime _weekStartDate;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _dateStripController = ScrollController();

  String _searchQuery = '';
  String _priorityFilter = 'All';
  String _statusFilter = 'All';
  String _repeatFilter = 'All';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Align week start date to Monday of current week
    _weekStartDate = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthBloc>().state.user;
      if (user != null) {
        context.read<TaskBloc>().add(FetchPersonalTasksEvent(user.id));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateStripController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.add(const Duration(days: 7));
    });
  }

  void _openCreateTaskSheet(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PersonalTaskFormSheet(
        userId: userId,
        initialDate: _selectedDate,
        onSave: (task) {
          context.read<TaskBloc>().add(CreateTaskEvent(task));
        },
      ),
    );
  }

  void _openEditTaskSheet(String userId, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PersonalTaskFormSheet(
        userId: userId,
        task: task,
        onSave: (updated) {
          context.read<TaskBloc>().add(UpdateTaskEvent(updated));
        },
      ),
    );
  }

  void _openTaskOptionsSheet(String userId, TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PersonalTaskOptionsSheet(
        task: task,
        onEdit: () => _openEditTaskSheet(userId, task),
        onDuplicate: () {
          context.read<TaskBloc>().add(
            DuplicateTaskEvent(task, isPersonal: true),
          );
        },
        onDelete: () {
          context.read<TaskBloc>().add(
            DeleteTaskEvent(task.id, '', userId, isGlobal: false),
          );
        },
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PersonalFilterSheet(
        currentPriority: _priorityFilter,
        currentStatus: _statusFilter,
        currentRepeat: _repeatFilter,
        onApplyFilters:
            ({required priority, required status, required repeat}) {
              setState(() {
                _priorityFilter = priority;
                _statusFilter = status;
                _repeatFilter = repeat;
              });
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTaskSheet(user.id),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header with Greeting, Progress & Search/Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),

                      // Filter Button
                      IconButton(
                        onPressed: _openFilterSheet,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (_priorityFilter != 'All' ||
                                    _statusFilter != 'All' ||
                                    _repeatFilter != 'All')
                                ? AppTheme.primaryColor.withOpacity(0.15)
                                : (isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.grey.withOpacity(0.12)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color:
                                (_priorityFilter != 'All' ||
                                    _statusFilter != 'All' ||
                                    _repeatFilter != 'All')
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Task Progress Bar & Counter
                  BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, state) {
                      List<TaskModel> allTasks = [];
                      if (state is TaskLoaded) {
                        allTasks = state.tasks;
                      }

                      final dayTasks = allTasks
                          .where((t) => _isSameDay(t.dueDate, _selectedDate))
                          .toList();
                      final completedCount = dayTasks
                          .where((t) => t.isCompleted)
                          .toList()
                          .length;
                      final totalCount = dayTasks.length;
                      final double progress = totalCount > 0
                          ? completedCount / totalCount
                          : 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completedCount of $totalCount tasks completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search personal tasks...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.42)
                              : Colors.black.withValues(alpha: 0.42),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Date Strip with Prev / Next Week Controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: theme.scaffoldBackgroundColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    onPressed: _previousWeek,
                    tooltip: 'Previous week',
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: ListView.builder(
                        controller: _dateStripController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final date = _weekStartDate.add(
                            Duration(days: index),
                          );
                          final isSelected = _isSameDay(date, _selectedDate);
                          final isToday = _isSameDay(date, DateTime.now());

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : (isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.withOpacity(0.08)),
                                borderRadius: BorderRadius.circular(16),
                                border: isToday && !isSelected
                                    ? Border.all(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E').format(date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white60
                                                : Colors.black54),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    onPressed: _nextWeek,
                    tooltip: 'Next week',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            // Task List View with BlocBuilder
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const SkeletonListLoader(
                      itemCount: 4,
                      itemHeight: 64,
                    );
                  }

                  if (state is TaskError) {
                    return ErrorStateWidget(
                      title: 'Failed to Load Tasks',
                      message: state.message,
                      onRetry: () {
                        final authState = context.read<AuthBloc>().state;
                        final user = authState.user;
                        if (user != null) {
                          context.read<TaskBloc>().add(
                            FetchPersonalTasksEvent(user.id),
                          );
                        }
                      },
                    );
                  }

                  if (state is TaskLoaded) {
                    // Filter tasks
                    final filteredTasks = state.tasks.where((task) {
                      // Date match
                      if (!_isSameDay(task.dueDate, _selectedDate))
                        return false;

                      // Search query
                      if (_searchQuery.isNotEmpty) {
                        final title = task.title.toLowerCase();
                        final desc = task.description.toLowerCase();
                        if (!title.contains(_searchQuery) &&
                            !desc.contains(_searchQuery)) {
                          return false;
                        }
                      }

                      // Priority filter
                      if (_priorityFilter != 'All' &&
                          task.priority != _priorityFilter) {
                        return false;
                      }

                      // Status filter
                      if (_statusFilter != 'All') {
                        if (_statusFilter == 'Completed' && !task.isCompleted)
                          return false;
                        if (_statusFilter == 'Pending' &&
                            (task.isCompleted || task.isMissed))
                          return false;
                        if (_statusFilter == 'Missed' && !task.isMissed)
                          return false;
                      }

                      // Repeat filter
                      if (_repeatFilter != 'All' &&
                          TaskRepeatMapper.toDb(task.repeat) !=
                              TaskRepeatMapper.toDb(_repeatFilter)) {
                        return false;
                      }

                      return true;
                    }).toList();
                    // Sort tasks by due time
                    filteredTasks.sort((a, b) {
                      final now = DateTime.now();

                      // Today aanenkil upcoming tasks first
                      if (_isSameDay(_selectedDate, now)) {
                        final aUpcoming = a.dueDate.isAfter(now);
                        final bUpcoming = b.dueDate.isAfter(now);

                        // Upcoming tasks first
                        if (aUpcoming != bUpcoming) {
                          return aUpcoming ? -1 : 1;
                        }
                      }

                      // Sort by due time (earliest first)
                      return a.dueDate.compareTo(b.dueDate);
                    });

                    if (filteredTasks.isEmpty) {
                      return EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No Tasks Found',
                        message:
                            'Enjoy your free time or tap + to create a task for ${DateFormat('MMM d').format(_selectedDate)}.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];

                        return PersonalTaskItem(
                          key: ValueKey(task.id),
                          task: task,
                          onToggleComplete: (val) {
                            final updated = task.copyWith(
                              isCompleted: val ?? false,
                              status: (val ?? false) ? 'Completed' : 'Pending',
                              completedAt: (val ?? false)
                                  ? DateTime.now()
                                  : null,
                            );
                            context.read<TaskBloc>().add(
                              UpdateTaskEvent(updated),
                            );
                          },
                          onEdit: () => _openEditTaskSheet(user.id, task),
                          onDelete: () {
                            context.read<TaskBloc>().add(
                              DeleteTaskEvent(
                                task.id,
                                '',
                                user.id,
                                isGlobal: false,
                              ),
                            );
                          },
                          onLongPress: () =>
                              _openTaskOptionsSheet(user.id, task),
                          onResolveCompletedLate: () {
                            context.read<TaskBloc>().add(
                              ResolveMissedTaskEvent(
                                task,
                                outcomeStatus: 'Completed Late',
                              ),
                            );
                          },
                          onResolveNotCompleted: () {
                            context.read<TaskBloc>().add(
                              ResolveMissedTaskEvent(
                                task,
                                outcomeStatus: 'Not Completed',
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
