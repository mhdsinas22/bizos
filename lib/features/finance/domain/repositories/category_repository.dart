import 'package:bizos/features/finance/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories(
    String businessId,
    CategoryType type,
  );
  Future<CategoryEntity> addCategory(CategoryEntity category);
  Future<CategoryEntity> updateCategory(CategoryEntity category);
  Future<void> deleteCategory({
    required String id,
    required CategoryType type,
    required String businessId,
    required String categoryName,
  });
}
