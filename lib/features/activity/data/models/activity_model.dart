import 'package:bizos/features/activity/domain/entities/activity_entity.dart';

class ActivityModel extends ActivityEntity {
  ActivityModel({
    required super.id,
    super.businessId,
    required super.title,
    required super.description,
    required super.createdBy,
    required super.createdAt,
    required super.module,
    required super.action,
    super.referenceId,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? 'system',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      module: json['module'] as String? ?? 'Business',
      action: json['action'] as String? ?? 'Log',
      referenceId: json['reference_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'module': module,
      'action': action,
      'reference_id': referenceId,
    };
  }
}
