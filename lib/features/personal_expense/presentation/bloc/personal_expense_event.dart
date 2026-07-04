import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:equatable/equatable.dart';

abstract class PersonalExpenseEvent extends Equatable {
  const PersonalExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadPersonalExpenses extends PersonalExpenseEvent {
  final String userId;

  const LoadPersonalExpenses(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddPersonalExpense extends PersonalExpenseEvent {
  final PersonalExpenseEntity expense;
  final String userId;

  const AddPersonalExpense(this.expense, this.userId);

  @override
  List<Object?> get props => [expense, userId];
}

class UpdatePersonalExpense extends PersonalExpenseEvent {
  final PersonalExpenseEntity expense;
  final String userId;

  const UpdatePersonalExpense(this.expense, this.userId);

  @override
  List<Object?> get props => [expense, userId];
}

class DeletePersonalExpense extends PersonalExpenseEvent {
  final String expenseId;
  final String userId;

  const DeletePersonalExpense(this.expenseId, this.userId);

  @override
  List<Object?> get props => [expenseId, userId];
}

class FilterPersonalExpenses extends PersonalExpenseEvent {
  final String filterType; // 'today', 'week', 'month', 'year', 'custom', 'all'
  final DateTime? startDate;
  final DateTime? endDate;
  final String userId;

  const FilterPersonalExpenses({
    required this.filterType,
    this.startDate,
    this.endDate,
    required this.userId,
  });

  @override
  List<Object?> get props => [filterType, startDate, endDate, userId];
}

class SearchPersonalExpenses extends PersonalExpenseEvent {
  final String query;

  const SearchPersonalExpenses(this.query);

  @override
  List<Object?> get props => [query];
}

class SortPersonalExpenses extends PersonalExpenseEvent {
  final String sortBy; // 'newest', 'oldest', 'highest', 'lowest'

  const SortPersonalExpenses(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}

class LoadAnalytics extends PersonalExpenseEvent {
  final String userId;

  const LoadAnalytics(this.userId);

  @override
  List<Object?> get props => [userId];
}
