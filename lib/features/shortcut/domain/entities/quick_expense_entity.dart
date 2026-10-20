import 'package:equatable/equatable.dart';

class QuickExpenseEntity extends Equatable {
  final String id;
  final String ownerId;
  final double amount;
  final String category;
  final String paymentMethod;
  final String description;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String currencySymbol;

  const QuickExpenseEntity({
    required this.id,
    required this.ownerId,
    required this.amount,
    required this.category,
    this.paymentMethod = 'Cash',
    this.description = '',
    required this.expenseDate,
    required this.createdAt,
    this.currencySymbol = '₹',
  });

  bool get isValidAmount => amount > 0 && amount.isFinite;
  bool get isValidCategory => category.trim().isNotEmpty;

  QuickExpenseEntity copyWith({
    String? id,
    String? ownerId,
    double? amount,
    String? category,
    String? paymentMethod,
    String? description,
    DateTime? expenseDate,
    DateTime? createdAt,
    String? currencySymbol,
  }) {
    return QuickExpenseEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        amount,
        category,
        paymentMethod,
        description,
        expenseDate,
        createdAt,
        currencySymbol,
      ];
}
