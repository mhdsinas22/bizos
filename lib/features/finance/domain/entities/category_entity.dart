import 'package:equatable/equatable.dart';

enum CategoryType { income, expense }

class CategoryEntity extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String? icon;
  final String? color;
  final String? createdBy;
  final DateTime? createdAt;
  final CategoryType type;

  const CategoryEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.icon,
    this.color,
    this.createdBy,
    this.createdAt,
    required this.type,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        icon,
        color,
        createdBy,
        createdAt,
        type,
      ];
}
