import 'package:equatable/equatable.dart';

class ProductServiceEntity extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String type; // 'product' or 'service'
  final String description;
  final double price;
  final double taxRate;
  final String unit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductServiceEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.type = 'service',
    this.description = '',
    this.price = 0.0,
    this.taxRate = 0.0,
    this.unit = 'item',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isProduct => type.toLowerCase() == 'product';
  bool get isService => type.toLowerCase() == 'service';

  ProductServiceEntity copyWith({
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
    return ProductServiceEntity(
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

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        type,
        description,
        price,
        taxRate,
        unit,
        isActive,
        createdAt,
        updatedAt,
      ];
}

