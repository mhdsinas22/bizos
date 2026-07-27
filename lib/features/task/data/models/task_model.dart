class TaskModel {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime dueDate;
  final bool isCompleted;
  final String ownerId;
  final String createdBy;
  final String assignedto;
  final DateTime createdAt;
  final bool isNotified;

  TaskModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    required this.assignedto,
    required this.createdAt,
    this.ownerId = '',
    this.createdBy = '',
    this.isNotified = false,
  });

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
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate.toUtc().toIso8601String(),
      'isCompleted': isCompleted,
      'ownerId': ownerId,
      'created_by': createdBy,
      "assigned_to": assignedto,
      "created_at": createdAt.toUtc().toIso8601String(),
      "is_notified": isNotified,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'Medium',
      dueDate: parseDueDate(map['due_date']),
      isCompleted: map['isCompleted'] ?? false,
      ownerId: map['ownerId'] ?? '',
      createdBy: map['created_by'] ?? '',
      assignedto: map["assigned_to"] ?? "",
      createdAt: map['created_at'] != null
          ? parseDueDate(map['created_at'])
          : DateTime.now(),
      isNotified: map["is_notified"] ?? false,
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
    String? ownerId,
    String? createdBy,
    String? assignedto,
    DateTime? createdAt,
    bool? isNotified,
  }) {
    return TaskModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      ownerId: ownerId ?? this.ownerId,
      createdBy: createdBy ?? this.createdBy,
      assignedto: assignedto ?? this.assignedto,
      createdAt: createdAt ?? this.createdAt,
      isNotified: isNotified ?? this.isNotified,
    );
  }
}
