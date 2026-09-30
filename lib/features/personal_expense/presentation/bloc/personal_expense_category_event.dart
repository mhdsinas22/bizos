import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';
import 'package:equatable/equatable.dart';

abstract class PersonalExpenseCategoryEvent extends Equatable {
  const PersonalExpenseCategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadPersonalCategoriesEvent extends PersonalExpenseCategoryEvent {
  final String userId;

  const LoadPersonalCategoriesEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddPersonalCategoryEvent extends PersonalExpenseCategoryEvent {
  final PersonalExpenseCategoryEntity category;
  final String userId;

  const AddPersonalCategoryEvent(this.category, this.userId);

  @override
  List<Object?> get props => [category, userId];
}

class UpdatePersonalCategoryEvent extends PersonalExpenseCategoryEvent {
  final PersonalExpenseCategoryEntity category;
  final String userId;

  const UpdatePersonalCategoryEvent(this.category, this.userId);

  @override
  List<Object?> get props => [category, userId];
}

class DeletePersonalCategoryEvent extends PersonalExpenseCategoryEvent {
  final PersonalExpenseCategoryEntity category;
  final String userId;

  const DeletePersonalCategoryEvent(this.category, this.userId);

  @override
  List<Object?> get props => [category, userId];
}
