import 'package:equatable/equatable.dart';

class PersonalExpenseEntity extends Equatable {
  final String id;
  final String ownerId;
  final double amount;
  final String category;
  final String description;
  final DateTime expenseDate;
  final DateTime createdAt;

  const PersonalExpenseEntity({
    required this.id,
    required this.ownerId,
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        amount,
        category,
        description,
        expenseDate,
        createdAt,
      ];
}
