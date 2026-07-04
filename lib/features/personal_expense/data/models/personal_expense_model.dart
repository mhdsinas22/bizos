import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';

class PersonalExpenseModel extends PersonalExpenseEntity {
  const PersonalExpenseModel({
    required super.id,
    required super.ownerId,
    required super.amount,
    required super.category,
    required super.description,
    required super.expenseDate,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'amount': amount,
      'category': category,
      'description': description,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PersonalExpenseModel.fromJson(Map<String, dynamic> json) {
    return PersonalExpenseModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  factory PersonalExpenseModel.fromEntity(PersonalExpenseEntity entity) {
    return PersonalExpenseModel(
      id: entity.id,
      ownerId: entity.ownerId,
      amount: entity.amount,
      category: entity.category,
      description: entity.description,
      expenseDate: entity.expenseDate,
      createdAt: entity.createdAt,
    );
  }
}
