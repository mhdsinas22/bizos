import 'package:equatable/equatable.dart';

class PersonalExpenseCategoryEntity extends Equatable {
  final String id;
  final String? ownerId;
  final String name;
  final String? icon;
  final String? color;
  final bool isSystem;
  final DateTime createdAt;

  const PersonalExpenseCategoryEntity({
    required this.id,
    this.ownerId,
    required this.name,
    this.icon,
    this.color,
    this.isSystem = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        icon,
        color,
        isSystem,
        createdAt,
      ];
}
