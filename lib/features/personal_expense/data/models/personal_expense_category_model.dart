import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';

class PersonalExpenseCategoryModel extends PersonalExpenseCategoryEntity {
  const PersonalExpenseCategoryModel({
    required super.id,
    super.ownerId,
    required super.name,
    super.icon,
    super.color,
    super.isSystem = false,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_system': isSystem,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PersonalExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return PersonalExpenseCategoryModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String?,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  factory PersonalExpenseCategoryModel.fromEntity(
      PersonalExpenseCategoryEntity entity) {
    return PersonalExpenseCategoryModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
      isSystem: entity.isSystem,
      createdAt: entity.createdAt,
    );
  }

  PersonalExpenseCategoryModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? icon,
    String? color,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return PersonalExpenseCategoryModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
