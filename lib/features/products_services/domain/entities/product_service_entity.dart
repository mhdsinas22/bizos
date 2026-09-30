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
