import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';
import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:bizos/features/task/presentation/bloc/task_state.dart';
import 'package:bizos/features/task/presentation/widgets/task_card.dart';
import 'package:bizos/features/task/presentation/widgets/task_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ToDoTab extends StatefulWidget {
  final BusinessModel business;
  final String businessId;
  final UserModel user;

  const ToDoTab({
    super.key,
    required this.businessId,
    required this.user,
    required this.business,
  });

  @override
  State<ToDoTab> createState() => _ToDoTabState();
}

class _ToDoTabState extends State<ToDoTab> {
  String _filterPriority = 'All'; // 'All', 'High', 'Medium', 'Low'
  String _filterStatus = 'All'; // 'All', 'Pending', 'Completed'
  String _ownerViewTab = 'All'; // 'All', 'My', 'Staff'

  void _showTaskForm({TaskModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskFormSheet(
        businessList: [widget.business],
        businessId: widget.businessId,
        user: widget.user,
        task: task,
        onSave: () {
          context.read<TaskBloc>().add(FetchTasksEvent(widget.businessId));
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
                DeleteTaskEvent(task.id, widget.businessId),
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

  Widget _buildTabButton(String label, String value, ThemeData theme) {
    final isSelected = _ownerViewTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _ownerViewTab = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && theme.brightness != Brightness.dark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
                color: isSelected
                    ? (theme.brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.primaryColor)
                    : (theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canView = widget.user.hasPermission(
      'view_tasks',
      businessId: widget.businessId,
    );
    final canAdd = widget.user.hasPermission(
      'add_tasks',
      businessId: widget.businessId,
    );

    if (!canView) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Access Denied',
        message: 'Your staff account permissions restrict viewing tasks.',
      );
    }

    return Scaffold(
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _showTaskForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // Owner View Filter Tabs
          if (widget.user.isOwner)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? AppTheme.darkSurface
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabButton('All Tasks', 'All', theme),
                    _buildTabButton('My Tasks', 'My', theme),
                    _buildTabButton('Staff Tasks', 'Staff', theme),
                  ],
                ),
              ),
            ),

          // Filter Chips Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppTheme.darkSurface
                  : Colors.grey[100],
              border: Border(
                bottom: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? AppTheme.darkBorder
                      : AppTheme.lightBorder,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Priority: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  ...['All', 'High', 'Medium', 'Low'].map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                        selected: _filterPriority == p,
                        onSelected: (sel) {
                          if (sel) setState(() => _filterPriority = p);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  ...['All', 'Pending', 'Completed'].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        selected: _filterStatus == s,
                        onSelected: (sel) {
                          if (sel) setState(() => _filterStatus = s);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TaskError) {
                  return Center(
                    child: Text('Error loading tasks: ${state.message}'),
                  );
                }

                if (state is TaskLoaded) {
                  var filtered = state.tasks;

                  // 1. Owner-Staff Separation filtering
                  if (widget.user.isOwner) {
                    if (_ownerViewTab == 'My') {
                      filtered = filtered
                          .where((t) => t.assignedto == widget.user.id)
                          .toList();
                    } else if (_ownerViewTab == 'Staff') {
                      filtered = filtered
                          .where((t) => t.assignedto != widget.user.id)
                          .toList();
                    }
                  } else {
                    // Staff user: can ONLY see tasks assigned to them
                    filtered = filtered
                        .where((t) => t.assignedto == widget.user.id)
                        .toList();
                  }

                  // Priority filter
                  if (_filterPriority != 'All') {
                    filtered = filtered
                        .where((t) => t.priority == _filterPriority)
                        .toList();
                  }

                  // Status filter
                  if (_filterStatus == 'Pending') {
                    filtered = filtered.where((t) => !t.isCompleted).toList();
                  } else if (_filterStatus == 'Completed') {
                    filtered = filtered.where((t) => t.isCompleted).toList();
                  }

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.checklist,
                      title: 'No Tasks Found',
                      message: 'Add a task or change the filter criteria.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      final isOwner = widget.user.isOwner;
                      final canToggle =
                          isOwner ||
                          (widget.user.isStaff &&
                              t.assignedto == widget.user.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TaskCard(
                          task: t,
                          currentUser: widget.user,
                          userNames: state.userNames,
                          businessNames: state.businessNames,
                          isOwnerView: isOwner,
                          onToggleCompleted: isOwner && canToggle
                              ? (_) => context.read<TaskBloc>().add(
                                  ToggleTaskStatusEvent(t),
                                )
                              : null,
                          onEdit: isOwner && canAdd
                              ? () => _showTaskForm(task: t)
                              : null,
                          onDelete: isOwner && canAdd
                              ? () => _confirmDelete(t)
                              : null,
                          onMarkComplete: !isOwner && canToggle
                              ? () => context.read<TaskBloc>().add(
                                  ToggleTaskStatusEvent(t),
                                )
                              : null,
                        ),
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
    );
  }
}
