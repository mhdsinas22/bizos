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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'ownerId': ownerId,
      'created_by': createdBy,
      "assigned_to": assignedto,
      "created_at": createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'Medium',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
      ownerId: map['ownerId'] ?? '',
      createdBy: map['created_by'] ?? '',
      assignedto: map["assigned_to"] ?? "",
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
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
    );
  }
}
