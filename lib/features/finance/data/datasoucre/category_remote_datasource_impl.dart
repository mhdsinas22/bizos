import 'package:bizos/features/finance/data/datasoucre/category_remote_datasource.dart';
import 'package:bizos/features/finance/data/models/category_model.dart';
import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRemoteDatasourceImpl implements CategoryRemoteDatasource {
  final SupabaseClient supabaseClient;

  CategoryRemoteDatasourceImpl({required this.supabaseClient});

  String _getTableName(CategoryType type) {
    return type == CategoryType.income
        ? 'income_categories'
        : 'expense_categories';
  }

  @override
  Future<List<CategoryModel>> getCategories(
    String businessId,
    CategoryType type,
  ) async {
    if (businessId.trim().isEmpty) return [];

    final tableName = _getTableName(type);
    final response = await supabaseClient
        .from(tableName)
        .select()
        .eq('business_id', businessId)
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((row) => CategoryModel.fromJson(row as Map<String, dynamic>, type))
        .toList();
  }

  @override
  Future<CategoryModel> addCategory(CategoryModel category) async {
    final tableName = _getTableName(category.type);

    final existing = await supabaseClient
        .from(tableName)
        .select('id')
        .eq('business_id', category.businessId)
        .ilike('name', category.name.trim())
        .maybeSingle();

    if (existing != null) {
      throw Exception('Category with name "${category.name}" already exists');
    }

    final payload = category.toJson();
    final response = await supabaseClient
        .from(tableName)
        .insert(payload)
        .select()
        .single();

    return CategoryModel.fromJson(response, category.type);
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final tableName = _getTableName(category.type);

    // Check for duplicate names (excluding current category id)
    final existing = await supabaseClient
        .from(tableName)
        .select('id')
        .eq('business_id', category.businessId)
        .ilike('name', category.name.trim())
        .neq('id', category.id)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Category with name "${category.name}" already exists');
    }

    final response = await supabaseClient
        .from(tableName)
        .update({
          'name': category.name.trim(),
          'icon': category.icon,
          'color': category.color,
        })
        .eq('id', category.id)
        .select()
        .single();

    return CategoryModel.fromJson(response, category.type);
  }

  @override
  Future<void> deleteCategory({
    required String id,
    required CategoryType type,
    required String businessId,
    required String categoryName,
  }) async {
    final transactionTable =
        type == CategoryType.income ? 'incomes' : 'expenses';

    // Verify if category is used in transactions
    final usageCheck = await supabaseClient
        .from(transactionTable)
        .select('id')
        .eq('business_id', businessId)
        .eq('category', categoryName.trim())
        .limit(1);

    if ((usageCheck as List<dynamic>).isNotEmpty) {
      throw Exception(
        'This category is already used by existing transactions and cannot be deleted.',
      );
    }

    final tableName = _getTableName(type);
    await supabaseClient.from(tableName).delete().eq('id', id);
  }
}
