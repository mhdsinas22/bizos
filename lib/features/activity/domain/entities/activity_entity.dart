class ActivityEntity {
  final String id;
  final String? businessId;
  final String title;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String module; // 'Income', 'Expense', 'Money', 'Task', 'Staff', 'Business'
  final String action; // 'Add' / 'Create', 'Update', 'Delete', 'Complete'
  final String? referenceId;

  ActivityEntity({
    required this.id,
    this.businessId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.module,
    required this.action,
    this.referenceId,
  });
}
