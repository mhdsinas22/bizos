import 'package:bizos/features/activity/domain/entities/activity_entity.dart';

class ActivityModel extends ActivityEntity {
  ActivityModel({
    required super.id,
    super.businessId,
    required super.title,
    required super.description,
    required super.createdBy,
    super.createdByName = 'Unknown User',
    required super.createdAt,
    required super.module,
    required super.action,
    super.referenceId,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    String actorName = 'Unknown User';

    if (json['users'] != null) {
      if (json['users'] is Map) {
        actorName = (json['users']['name'] as String?)?.trim() ?? 'Unknown User';
      } else if (json['users'] is List && (json['users'] as List).isNotEmpty) {
        actorName = ((json['users'] as List).first['name'] as String?)?.trim() ?? 'Unknown User';
      }
    } else if (json['created_by_name'] != null &&
        (json['created_by_name'] as String).trim().isNotEmpty) {
      actorName = (json['created_by_name'] as String).trim();
    }

    if (actorName.isEmpty) {
      actorName = 'Unknown User';
    }

    return ActivityModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      createdByName: actorName,
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
      if (id.trim().isNotEmpty) 'id': id,
      'business_id': (businessId != null && businessId!.trim().isNotEmpty) ? businessId : null,
      'title': title,
      'description': description,
      'created_by': createdBy.trim().isNotEmpty ? createdBy : null,
      'created_at': createdAt.toIso8601String(),
      'module': module,
      'action': action,
      'reference_id': (referenceId != null && referenceId!.trim().isNotEmpty) ? referenceId : null,
    };
  }
}
