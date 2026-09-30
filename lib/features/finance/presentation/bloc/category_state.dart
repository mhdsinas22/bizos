import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:equatable/equatable.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryAdding extends CategoryState {
  final List<CategoryEntity> currentCategories;

  const CategoryAdding(this.currentCategories);

  @override
  List<Object?> get props => [currentCategories];
}

class CategoryUpdating extends CategoryState {
  final List<CategoryEntity> currentCategories;

  const CategoryUpdating(this.currentCategories);

  @override
  List<Object?> get props => [currentCategories];
}

class CategoryDeleting extends CategoryState {
  final List<CategoryEntity> currentCategories;

  const CategoryDeleting(this.currentCategories);

  @override
  List<Object?> get props => [currentCategories];
}

class CategoryLoaded extends CategoryState {
  final List<CategoryEntity> categories;
  final CategoryType type;
  final CategoryEntity? newlyAddedCategory;
  final String? message;

  const CategoryLoaded({
    required this.categories,
    required this.type,
    this.newlyAddedCategory,
    this.message,
  });

  @override
  List<Object?> get props => [categories, type, newlyAddedCategory, message];
}

class CategoryError extends CategoryState {
  final String message;
  final List<CategoryEntity> currentCategories;

  const CategoryError(this.message, {this.currentCategories = const []});

  @override
  List<Object?> get props => [message, currentCategories];
}
