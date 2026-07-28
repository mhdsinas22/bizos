import 'package:bizos/core/utils/task_repeat_mapper.dart';

class TaskModel {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime dueDate;
  final String ownerId;
  final String createdBy;
  final String assignedto;
  final DateTime createdAt;
  final bool isNotified;
  final DateTime? completedAt;
  final String _status;
  final String taskType; // 'personal' or 'business'
  final String repeat; // DB constraint values: 'none', 'daily', 'weekly', 'monthly', 'yearly'

  TaskModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.assignedto,
    required this.createdAt,
    bool isCompleted = false,
    String? status,
    this.ownerId = '',
    this.createdBy = '',
    this.isNotified = false,
    this.completedAt,
    String? taskType,
    String repeat = 'none',
  })  : repeat = TaskRepeatMapper.toDb(repeat),
        _status = status ?? (isCompleted ? 'Completed' : 'Pending'),
        taskType =
            taskType ?? (businessId.isNotEmpty ? 'business' : 'personal');

  bool get isPersonal => taskType == 'personal';
  bool get isBusiness => taskType == 'business';

  String get repeatDisplay => TaskRepeatMapper.toUi(repeat);

  String get status {
    if (_status.isNotEmpty && _status != 'Pending') {
      return _status;
    }
    final missedTime = dueDate.add(const Duration(minutes: 30));
    if (DateTime.now().isAfter(missedTime)) {
      return 'Missed';
    }
    return _status.isNotEmpty ? _status : 'Pending';
  }

  bool get isCompleted =>
      status == 'Completed' || status == 'Completed Late';

  bool get isCompletedLate => status == 'Completed Late';

  bool get isNotCompleted => status == 'Not Completed';

  bool get isPending => status == 'Pending';

  bool get isMissed => status == 'Missed';

  bool get canMarkComplete => status == 'Pending';

  bool get showCompleteAction => canMarkComplete;

  static DateTime parseDueDate(dynamic value) {
    if (value == null) return DateTime.now();
    final str = value.toString().trim();
    if (str.isEmpty) return DateTime.now();

    // Check for pure date format (YYYY-MM-DD) without time component
    final dateOnlyRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (dateOnlyRegex.hasMatch(str)) {
      final parts = str.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        0,
        0,
      );
    }

    final parsed = DateTime.tryParse(str);
    if (parsed == null) return DateTime.now();
    return parsed.toLocal();
  }

  Map<String, dynamic> toMap() {
    final isPers = isPersonal || businessId.trim().isEmpty;
    return {
      if (id.trim().isNotEmpty) 'id': id,
      'business_id': isPers ? null : (businessId.trim().isNotEmpty ? businessId : null),
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': status,
      'owner_id': ownerId.trim().isNotEmpty ? ownerId : null,
      'created_by': createdBy.trim().isNotEmpty ? createdBy : null,
      'assigned_to': assignedto.trim().isNotEmpty ? assignedto : null,
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_notified': isNotified,
      if (completedAt != null)
        'completed_at': completedAt!.toUtc().toIso8601String(),
      'task_type': isPers ? 'personal' : 'business',
      'repeat': TaskRepeatMapper.toDb(repeat),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['status'] as String?)?.trim() ?? '';
    final isComp = map['isCompleted'] == true ||
        rawStatus.toLowerCase() == 'completed' ||
        rawStatus.toLowerCase() == 'completed late' ||
        rawStatus.toLowerCase() == 'completed_late';

    final bizId = (map['businessId'] ?? map['business_id'] ?? '').toString();
    final tType = (map['task_type'] as String?) ??
        (bizId.isNotEmpty ? 'business' : 'personal');

    return TaskModel(
      id: map['id'] ?? '',
      businessId: bizId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'Medium',
      dueDate: parseDueDate(map['due_date']),
      isCompleted: isComp,
      status: rawStatus.isNotEmpty ? rawStatus : null,
      ownerId: map['ownerId'] ?? map['owner_id'] ?? '',
      createdBy: map['created_by'] ?? '',
      assignedto: map["assigned_to"] ?? "",
      createdAt: map['created_at'] != null
          ? parseDueDate(map['created_at'])
          : DateTime.now(),
      isNotified: map["is_notified"] ?? false,
      completedAt: map['completed_at'] != null
          ? parseDueDate(map['completed_at'])
          : null,
      taskType: tType,
      repeat: TaskRepeatMapper.toDb(map['repeat']?.toString()),
    );
  }

  TaskModel copyWith({
    String? id,
    String? businessId,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    String? status,
    String? ownerId,
    String? createdBy,
    String? assignedto,
    DateTime? createdAt,
    bool? isNotified,
    DateTime? completedAt,
    String? taskType,
    String? repeat,
  }) {
    return TaskModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? _status,
      ownerId: ownerId ?? this.ownerId,
      createdBy: createdBy ?? this.createdBy,
      assignedto: assignedto ?? this.assignedto,
      createdAt: createdAt ?? this.createdAt,
      isNotified: isNotified ?? this.isNotified,
      completedAt: completedAt ?? this.completedAt,
      taskType: taskType ?? this.taskType,
      repeat: repeat ?? this.repeat,
    );
  }
}
