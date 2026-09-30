import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';

class PersonalExpenseModel extends PersonalExpenseEntity {
  const PersonalExpenseModel({
    required super.id,
    required super.ownerId,
    required super.amount,
    required super.category,
    super.paymentMethod = 'Cash',
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
      'payment_method': paymentMethod,
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
      paymentMethod: PaymentMethodHelper.sanitize(
        json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      ),
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
      paymentMethod: entity.paymentMethod,
      description: entity.description,
      expenseDate: entity.expenseDate,
      createdAt: entity.createdAt,
    );
  }

  PersonalExpenseModel copyWith({
    String? id,
    String? ownerId,
    double? amount,
    String? category,
    String? paymentMethod,
    String? description,
    DateTime? expenseDate,
    DateTime? createdAt,
  }) {
    return PersonalExpenseModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
