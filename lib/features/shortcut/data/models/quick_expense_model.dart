import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';

class QuickExpenseModel extends QuickExpenseEntity {
  const QuickExpenseModel({
    required super.id,
    required super.ownerId,
    required super.amount,
    required super.category,
    super.paymentMethod = 'Cash',
    super.description = '',
    required super.expenseDate,
    required super.createdAt,
    super.currencySymbol = '₹',
  });

  factory QuickExpenseModel.fromJson(Map<String, dynamic> json) {
    return QuickExpenseModel(
      id: json['id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'Other',
      paymentMethod: json['payment_method']?.toString() ?? 'Cash',
      description: json['description']?.toString() ?? '',
      expenseDate: json['expense_date'] != null
          ? DateTime.tryParse(json['expense_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      currencySymbol: json['currency_symbol']?.toString() ?? '₹',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'description': description,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickExpenseModel.fromEntity(QuickExpenseEntity entity) {
    return QuickExpenseModel(
      id: entity.id,
      ownerId: entity.ownerId,
      amount: entity.amount,
      category: entity.category,
      paymentMethod: entity.paymentMethod,
      description: entity.description,
      expenseDate: entity.expenseDate,
      createdAt: entity.createdAt,
      currencySymbol: entity.currencySymbol,
    );
  }

  PersonalExpenseEntity toPersonalExpenseEntity() {
    return PersonalExpenseEntity(
      id: id,
      ownerId: ownerId,
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      description: description,
      expenseDate: expenseDate,
      createdAt: createdAt,
    );
  }

  factory QuickExpenseModel.fromPersonalExpenseEntity(
    PersonalExpenseEntity entity, {
    String currencySymbol = '₹',
  }) {
    return QuickExpenseModel(
      id: entity.id,
      ownerId: entity.ownerId,
      amount: entity.amount,
      category: entity.category,
      paymentMethod: entity.paymentMethod,
      description: entity.description,
      expenseDate: entity.expenseDate,
      createdAt: entity.createdAt,
      currencySymbol: currencySymbol,
    );
  }
}
