import 'package:bizos/features/finance/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.icon,
    super.color,
    super.createdBy,
    super.createdAt,
    required super.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, CategoryType type) {
    return CategoryModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'business_id': businessId,
      'name': name,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    if (icon != null && icon!.isNotEmpty) {
      map['icon'] = icon;
    }
    if (color != null && color!.isNotEmpty) {
      map['color'] = color;
    }
    if (createdBy != null && createdBy!.isNotEmpty) {
      map['created_by'] = createdBy;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    return map;
  }
}
