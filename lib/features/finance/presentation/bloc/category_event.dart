import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchCategoriesEvent extends CategoryEvent {
  final String businessId;
  final CategoryType type;

  const FetchCategoriesEvent({
    required this.businessId,
    required this.type,
  });

  @override
  List<Object?> get props => [businessId, type];
}

class AddCategoryEvent extends CategoryEvent {
  final CategoryEntity category;

  const AddCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateCategoryEvent extends CategoryEvent {
  final CategoryEntity category;

  const UpdateCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class DeleteCategoryEvent extends CategoryEvent {
  final String id;
  final CategoryType type;
  final String businessId;
  final String categoryName;

  const DeleteCategoryEvent({
    required this.id,
    required this.type,
    required this.businessId,
    required this.categoryName,
  });

  @override
  List<Object?> get props => [id, type, businessId, categoryName];
}
