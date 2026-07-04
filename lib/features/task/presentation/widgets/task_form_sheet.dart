import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_event.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_event.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_state.dart';
import 'package:bizos/features/task/presentation/bloc/task_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';

class TaskFormSheet extends StatefulWidget {
  final String? businessId;
  final List<BusinessModel>? businessList;
  final UserModel user;
  final TaskModel? task;
  final VoidCallback onSave;
  final bool isGlobal;

  const TaskFormSheet({
    super.key,
    this.businessId,
    this.businessList,
    required this.user,
    this.task,
    required this.onSave,
    this.isGlobal = false,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Medium';
  String? _selectedBusinessId;
  String? _selectedAssigneeId; // User ID of assignee (could be owner or staff)
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    
    final ownerId = widget.user.isOwner ? widget.user.id : widget.user.ownerId;
    
    // Fetch businesses and staff lists if needed
    context.read<BusinessBloc>().add(FetchBusinessesEvent(ownerId));
    context.read<StaffBloc>().add(FetchStaffEvent(ownerId));

    _selectedBusinessId = widget.task?.businessId ?? widget.businessId;

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _selectedAssigneeId = widget.task!.assignedto;
    } else {
      // Default assignee to owner ID if owner, else current user
      _selectedAssigneeId = widget.user.isOwner ? widget.user.id : widget.user.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBusinessId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a business')),
        );
        return;
      }

      final isEditing = widget.task != null;
      final String ownerId = widget.user.isOwner ? widget.user.id : widget.user.ownerId;
      final String createdBy = widget.user.id;

      final t = TaskModel(
        id: isEditing ? widget.task!.id : const Uuid().v4(),
        businessId: _selectedBusinessId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        isCompleted: isEditing ? widget.task!.isCompleted : false,
        ownerId: ownerId,
        createdBy: createdBy,
        assignedto: _selectedAssigneeId ?? widget.user.id,
        createdAt: isEditing ? widget.task!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        context.read<TaskBloc>().add(UpdateTaskEvent(t, isGlobal: widget.isGlobal));
      } else {
        context.read<TaskBloc>().add(CreateTaskEvent(t, isGlobal: widget.isGlobal));
      }
      
      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.task != null;
    final ownerId = widget.user.isOwner ? widget.user.id : widget.user.ownerId;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Task Details' : 'Add ToDo Task',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _titleController,
                label: 'Task Title',
                hint: 'e.g. Schedule meeting',
                prefixIcon: Icons.assignment_outlined,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Specific details about the task...',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Business Selection Dropdown
              BlocBuilder<BusinessBloc, BusinessState>(
                builder: (context, state) {
                  List<BusinessModel> list = [];
                  if (widget.businessList != null && widget.businessList!.isNotEmpty) {
                    list = widget.businessList!;
                  } else if (state is BusinessLoaded) {
                    list = state.businesses;
                  }

                  if (_selectedBusinessId == null && list.isNotEmpty) {
                    _selectedBusinessId = list.first.id;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedBusinessId,
                    decoration: const InputDecoration(
                      labelText: 'Business',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: list.map((biz) {
                      return DropdownMenuItem<String>(
                        value: biz.id,
                        child: Text(biz.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBusinessId = val;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Assign To Dropdown (Owner specific requirement)
              if (widget.user.isOwner)
                BlocBuilder<StaffBloc, StaffState>(
                  builder: (context, state) {
                    final List<DropdownMenuItem<String>> assigneeItems = [
                      DropdownMenuItem<String>(
                        value: ownerId,
                        child: const Text('Myself'),
                      ),
                    ];

                    if (state is StaffLoaded) {
                      assigneeItems.addAll(
                        state.staffList.map((staff) {
                          return DropdownMenuItem<String>(
                            value: staff.id,
                            child: Text(staff.name),
                          );
                        }),
                      );
                    }

                    // Safety check if the current value is not in items list
                    final currentValues = assigneeItems.map((item) => item.value).toList();
                    if (_selectedAssigneeId != null && !currentValues.contains(_selectedAssigneeId)) {
                      _selectedAssigneeId = ownerId;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedAssigneeId ?? ownerId,
                      decoration: const InputDecoration(
                        labelText: 'Assign To',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: assigneeItems,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedAssigneeId = val;
                          });
                        }
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: ['High', 'Medium', 'Low'].map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _priority = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'Due Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(DateFormat.yMMMd().format(_dueDate)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() {
                        _dueDate = picked;
                      });
                    }
                  },
                  child: const Text('Choose Date'),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Task',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
