import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';
import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_event.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalExpenseCategoryBloc
    extends Bloc<PersonalExpenseCategoryEvent, PersonalExpenseCategoryState> {
  final PersonalExpenseRepository repository;

  PersonalExpenseCategoryBloc({required this.repository})
      : super(PersonalExpenseCategoryInitial()) {
    on<LoadPersonalCategoriesEvent>(_onLoadCategories);
    on<AddPersonalCategoryEvent>(_onAddCategory);
    on<UpdatePersonalCategoryEvent>(_onUpdateCategory);
    on<DeletePersonalCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
    LoadPersonalCategoriesEvent event,
    Emitter<PersonalExpenseCategoryState> emit,
  ) async {
    emit(PersonalExpenseCategoryLoading());
    try {
      final categories = await repository.getCategories(event.userId);
      emit(PersonalExpenseCategoryLoaded(categories: categories));
    } catch (e) {
      emit(PersonalExpenseCategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddCategory(
    AddPersonalCategoryEvent event,
    Emitter<PersonalExpenseCategoryState> emit,
  ) async {
    List<PersonalExpenseCategoryEntity> currentList = [];
    if (state is PersonalExpenseCategoryLoaded) {
      currentList = (state as PersonalExpenseCategoryLoaded).categories;
    }
    try {
      final newCategory = await repository.addCategory(event.category, event.userId);
      final updatedCategories = await repository.getCategories(event.userId);
      emit(PersonalExpenseCategoryLoaded(
        categories: updatedCategories,
        newlyAddedCategory: newCategory,
        message: 'Category added successfully',
      ));
    } catch (e) {
      emit(PersonalExpenseCategoryError(
        e.toString().replaceAll('Exception: ', ''),
        currentCategories: currentList,
      ));
    }
  }

  Future<void> _onUpdateCategory(
    UpdatePersonalCategoryEvent event,
    Emitter<PersonalExpenseCategoryState> emit,
  ) async {
    List<PersonalExpenseCategoryEntity> currentList = [];
    if (state is PersonalExpenseCategoryLoaded) {
      currentList = (state as PersonalExpenseCategoryLoaded).categories;
    }
    try {
      await repository.updateCategory(event.category, event.userId);
      final updatedCategories = await repository.getCategories(event.userId);
      emit(PersonalExpenseCategoryLoaded(
        categories: updatedCategories,
        message: 'Category updated successfully',
      ));
    } catch (e) {
      emit(PersonalExpenseCategoryError(
        e.toString().replaceAll('Exception: ', ''),
        currentCategories: currentList,
      ));
    }
  }

  Future<void> _onDeleteCategory(
    DeletePersonalCategoryEvent event,
    Emitter<PersonalExpenseCategoryState> emit,
  ) async {
    List<PersonalExpenseCategoryEntity> currentList = [];
    if (state is PersonalExpenseCategoryLoaded) {
      currentList = (state as PersonalExpenseCategoryLoaded).categories;
    }
    try {
      final isUsed = await repository.isCategoryUsed(
        event.category.name,
        event.userId,
      );

      if (isUsed) {
        emit(PersonalExpenseCategoryError(
          'This category is currently used by existing expenses and cannot be deleted.',
          currentCategories: currentList,
        ));
        return;
      }

      await repository.deleteCategory(event.category.id, event.userId);
      final updatedCategories = await repository.getCategories(event.userId);
      emit(PersonalExpenseCategoryLoaded(
        categories: updatedCategories,
        message: 'Category deleted successfully',
      ));
    } catch (e) {
      emit(PersonalExpenseCategoryError(
        e.toString().replaceAll('Exception: ', ''),
        currentCategories: currentList,
      ));
    }
  }
}
