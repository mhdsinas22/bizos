import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:bizos/features/finance/domain/repositories/category_repository.dart';
import 'package:bizos/features/finance/presentation/bloc/category_event.dart';
import 'package:bizos/features/finance/presentation/bloc/category_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc({required this.repository}) : super(CategoryInitial()) {
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final categories = await repository.getCategories(
        event.businessId,
        event.type,
      );
      emit(CategoryLoaded(
        categories: categories,
        type: event.type,
      ));
    } catch (e) {
      emit(CategoryError(
        e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    List<CategoryEntity> currentList = [];
    if (state is CategoryLoaded) {
      currentList = (state as CategoryLoaded).categories;
    } else if (state is CategoryAdding) {
      currentList = (state as CategoryAdding).currentCategories;
    } else if (state is CategoryError) {
      currentList = (state as CategoryError).currentCategories;
    }

    emit(CategoryAdding(currentList));
    try {
      final newCat = await repository.addCategory(event.category);
      final updatedList = List<CategoryEntity>.from(currentList)..add(newCat);
      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      emit(CategoryLoaded(
        categories: updatedList,
        type: event.category.type,
        newlyAddedCategory: newCat,
        message: 'Category added successfully',
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(CategoryError(
        cleanMessage,
        currentCategories: currentList,
      ));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    List<CategoryEntity> currentList = [];
    if (state is CategoryLoaded) {
      currentList = (state as CategoryLoaded).categories;
    } else if (state is CategoryUpdating) {
      currentList = (state as CategoryUpdating).currentCategories;
    } else if (state is CategoryError) {
      currentList = (state as CategoryError).currentCategories;
    }

    emit(CategoryUpdating(currentList));
    try {
      final updatedCat = await repository.updateCategory(event.category);
      final updatedList = currentList.map((item) {
        return item.id == updatedCat.id ? updatedCat : item;
      }).toList();

      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      emit(CategoryLoaded(
        categories: updatedList,
        type: event.category.type,
        message: 'Category updated successfully',
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(CategoryError(
        cleanMessage,
        currentCategories: currentList,
      ));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    List<CategoryEntity> currentList = [];
    if (state is CategoryLoaded) {
      currentList = (state as CategoryLoaded).categories;
    } else if (state is CategoryDeleting) {
      currentList = (state as CategoryDeleting).currentCategories;
    } else if (state is CategoryError) {
      currentList = (state as CategoryError).currentCategories;
    }

    emit(CategoryDeleting(currentList));
    try {
      await repository.deleteCategory(
        id: event.id,
        type: event.type,
        businessId: event.businessId,
        categoryName: event.categoryName,
      );

      final updatedList = currentList.where((item) => item.id != event.id).toList();

      emit(CategoryLoaded(
        categories: updatedList,
        type: event.type,
        message: 'Category deleted successfully',
      ));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(CategoryError(
        cleanMessage,
        currentCategories: currentList,
      ));
    }
  }
}
