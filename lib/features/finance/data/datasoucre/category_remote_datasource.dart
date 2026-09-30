import 'package:bizos/features/finance/data/models/category_model.dart';
import 'package:bizos/features/finance/domain/entities/category_entity.dart';

abstract class CategoryRemoteDatasource {
  Future<List<CategoryModel>> getCategories(
    String businessId,
    CategoryType type,
  );
  Future<CategoryModel> addCategory(CategoryModel category);
  Future<CategoryModel> updateCategory(CategoryModel category);
  Future<void> deleteCategory({
    required String id,
    required CategoryType type,
    required String businessId,
    required String categoryName,
  });
}
