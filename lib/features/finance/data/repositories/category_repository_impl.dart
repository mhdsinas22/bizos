import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/finance/data/datasoucre/category_remote_datasource.dart';
import 'package:bizos/features/finance/data/models/category_model.dart';
import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:bizos/features/finance/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDatasource remoteDatasource;
  final ActivityRepository? activityRepository;

  CategoryRepositoryImpl({
    required this.remoteDatasource,
    this.activityRepository,
  });

  @override
  Future<List<CategoryEntity>> getCategories(
    String businessId,
    CategoryType type,
  ) async {
    return await remoteDatasource.getCategories(businessId, type);
  }

  @override
  Future<CategoryEntity> addCategory(CategoryEntity category) async {
    final model = CategoryModel(
      id: category.id,
      businessId: category.businessId,
      name: category.name,
      icon: category.icon,
      color: category.color,
      createdBy: category.createdBy,
      createdAt: category.createdAt,
      type: category.type,
    );
    final result = await remoteDatasource.addCategory(model);

    await activityRepository?.logActivity(
      businessId: category.businessId,
      title: "${category.type == CategoryType.income ? 'Income' : 'Expense'} Category Added",
      description: "Category '${category.name}' was created",
      module: category.type == CategoryType.income ? "Income" : "Expense",
      action: "Add",
      referenceId: result.id,
      createdBy: category.createdBy,
    );

    return result;
  }

  @override
  Future<CategoryEntity> updateCategory(CategoryEntity category) async {
    final model = CategoryModel(
      id: category.id,
      businessId: category.businessId,
      name: category.name,
      icon: category.icon,
      color: category.color,
      createdBy: category.createdBy,
      createdAt: category.createdAt,
      type: category.type,
    );
    final result = await remoteDatasource.updateCategory(model);

    await activityRepository?.logActivity(
      businessId: category.businessId,
      title: "${category.type == CategoryType.income ? 'Income' : 'Expense'} Category Updated",
      description: "Category '${category.name}' was updated",
      module: category.type == CategoryType.income ? "Income" : "Expense",
      action: "Update",
      referenceId: result.id,
      createdBy: category.createdBy,
    );

    return result;
  }

  @override
  Future<void> deleteCategory({
    required String id,
    required CategoryType type,
    required String businessId,
    required String categoryName,
  }) async {
    await remoteDatasource.deleteCategory(
      id: id,
      type: type,
      businessId: businessId,
      categoryName: categoryName,
    );

    await activityRepository?.logActivity(
      businessId: businessId,
      title: "${type == CategoryType.income ? 'Income' : 'Expense'} Category Deleted",
      description: "Category '$categoryName' was deleted",
      module: type == CategoryType.income ? "Income" : "Expense",
      action: "Delete",
      referenceId: id,
    );
  }
}
