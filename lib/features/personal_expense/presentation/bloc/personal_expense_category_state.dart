import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';
import 'package:equatable/equatable.dart';

abstract class PersonalExpenseCategoryState extends Equatable {
  const PersonalExpenseCategoryState();

  @override
  List<Object?> get props => [];
}

class PersonalExpenseCategoryInitial extends PersonalExpenseCategoryState {}

class PersonalExpenseCategoryLoading extends PersonalExpenseCategoryState {}

class PersonalExpenseCategoryLoaded extends PersonalExpenseCategoryState {
  final List<PersonalExpenseCategoryEntity> categories;
  final PersonalExpenseCategoryEntity? newlyAddedCategory;
  final String? message;

  const PersonalExpenseCategoryLoaded({
    required this.categories,
    this.newlyAddedCategory,
    this.message,
  });

  @override
  List<Object?> get props => [categories, newlyAddedCategory, message];
}

class PersonalExpenseCategoryError extends PersonalExpenseCategoryState {
  final String message;
  final List<PersonalExpenseCategoryEntity> currentCategories;

  const PersonalExpenseCategoryError(
    this.message, {
    this.currentCategories = const [],
  });

  @override
  List<Object?> get props => [message, currentCategories];
}
