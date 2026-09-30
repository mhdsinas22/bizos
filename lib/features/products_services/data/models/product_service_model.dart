import 'package:bizos/features/products_services/domain/entities/product_service_entity.dart';

class ProductServiceModel extends ProductServiceEntity {
  const ProductServiceModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.type = 'service',
    super.description = '',
    super.price = 0.0,
    super.taxRate = 0.0,
    super.unit = 'item',
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductServiceModel.fromJson(Map<String, dynamic> json) {
    return ProductServiceModel(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'service',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'item',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'business_id': businessId,
      'name': name,
      'type': type,
      'description': description,
      'price': price,
      'tax_rate': taxRate,
      'unit': unit,
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id.trim().isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  ProductServiceModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? type,
    String? description,
    double? price,
    double? taxRate,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductServiceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductServiceModel.fromEntity(ProductServiceEntity entity) {
    return ProductServiceModel(
      id: entity.id,
      businessId: entity.businessId,
      name: entity.name,
      type: entity.type,
      description: entity.description,
      price: entity.price,
      taxRate: entity.taxRate,
      unit: entity.unit,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
