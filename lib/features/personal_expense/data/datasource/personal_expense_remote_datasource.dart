import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';
import 'package:bizos/features/personal_expense/data/models/personal_expense_category_model.dart';
import 'package:bizos/features/personal_expense/data/models/personal_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PersonalExpenseRemoteDatasource {
  Future<List<PersonalExpenseModel>> getExpenses(String userId);
  Future<void> addExpense(PersonalExpenseModel expense, String userId);
  Future<void> updateExpense(PersonalExpenseModel expense, String userId);
  Future<void> deleteExpense(String expenseId, String userId);
  Future<List<PersonalExpenseModel>> getFilteredExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  // Category methods
  Future<List<PersonalExpenseCategoryModel>> getCategories(String userId);
  Future<PersonalExpenseCategoryModel> addCategory(
      PersonalExpenseCategoryModel category, String userId);
  Future<void> updateCategory(
      PersonalExpenseCategoryModel category, String userId);
  Future<void> deleteCategory(String categoryId, String userId);
  Future<bool> isCategoryUsed(String categoryName, String userId);
}

class PersonalExpenseRemoteDatasourceImpl
    implements PersonalExpenseRemoteDatasource {
  final SupabaseClient supabaseClient;

  PersonalExpenseRemoteDatasourceImpl({required this.supabaseClient});

  Future<void> _verifyOwnerOnlyAccess(String userId) async {
    try {
      final response = await supabaseClient
          .from('users')
          .select('role')
          .or('id.eq.$userId,userid.eq.$userId')
          .maybeSingle();

      if (response != null) {
        final role = response['role'] as String? ?? '';
        if (role.toLowerCase() != 'owner') {
          throw ServerException(
            'Access Denied: Personal Expense module is restricted to Owners only.',
          );
        }
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to verify user permissions. Access denied.',
      );
    }
  }

  @override
  Future<List<PersonalExpenseModel>> getExpenses(String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final response = await supabaseClient
          .from('personal_expenses')
          .select()
          .eq('owner_id', userId)
          .order('expense_date', ascending: false);

      final List<dynamic> list = response as List<dynamic>? ?? [];
      return list
          .map((item) =>
              PersonalExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load personal expenses: $e');
    }
  }

  @override
  Future<void> addExpense(PersonalExpenseModel expense, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final mapData = expense.toJson();
      mapData['owner_id'] = userId;
      if (expense.id.isEmpty) {
        mapData.remove('id');
      }

      await supabaseClient.from('personal_expenses').insert(mapData);
    } catch (e) {
      throw ServerException('Failed to save personal expense: $e');
    }
  }

  @override
  Future<void> updateExpense(
      PersonalExpenseModel expense, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final mapData = {
        'amount': expense.amount,
        'category': expense.category,
        'payment_method': PaymentMethodHelper.sanitize(expense.paymentMethod),
        'description': expense.description,
        'expense_date': expense.expenseDate.toIso8601String().split('T')[0],
      };
      await supabaseClient
          .from('personal_expenses')
          .update(mapData)
          .eq('id', expense.id)
          .eq('owner_id', userId);
    } catch (e) {
      throw ServerException('Failed to update personal expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      await supabaseClient
          .from('personal_expenses')
          .delete()
          .eq('id', expenseId)
          .eq('owner_id', userId);
    } catch (e) {
      throw ServerException('Failed to delete personal expense: $e');
    }
  }

  @override
  Future<List<PersonalExpenseModel>> getFilteredExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      var query = supabaseClient
          .from('personal_expenses')
          .select()
          .eq('owner_id', userId);

      if (startDate != null) {
        query = query.gte(
            'expense_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte(
            'expense_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('expense_date', ascending: false);
      final List<dynamic> list = response as List<dynamic>? ?? [];
      return list
          .map((item) =>
              PersonalExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load filtered personal expenses: $e');
    }
  }

  // --------------------------------------------------------------------------
  // CATEGORIES IMPLEMENTATION
  // --------------------------------------------------------------------------

  @override
  Future<List<PersonalExpenseCategoryModel>> getCategories(
      String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final response = await supabaseClient
          .from('personal_expense_categories')
          .select()
          .or('is_system.eq.true,owner_id.eq.$userId');

      final List<dynamic> list = response as List<dynamic>? ?? [];
      final categories = list
          .map((item) => PersonalExpenseCategoryModel.fromJson(
              item as Map<String, dynamic>))
          .toList();

      // Separate system categories and custom categories
      final systemCategories =
          categories.where((c) => c.isSystem).toList();
      final customCategories =
          categories.where((c) => !c.isSystem).toList();

      // Define default system categories order
      const systemOrder = [
        'Food',
        'Travel',
        'Fuel',
        'Shopping',
        'Medical',
        'Family',
        'Education',
        'Entertainment',
        'Bills',
        'Investment',
        'Other',
      ];

      // Ensure all 11 default system categories are guaranteed to exist in all environments
      for (final sysName in systemOrder) {
        final exists = systemCategories.any(
          (c) => c.name.toLowerCase() == sysName.toLowerCase(),
        );
        if (!exists) {
          systemCategories.add(
            PersonalExpenseCategoryModel(
              id: 'sys_${sysName.toLowerCase()}',
              name: sysName,
              isSystem: true,
              createdAt: DateTime(2026, 1, 1),
            ),
          );
        }
      }

      systemCategories.sort((a, b) {
        final indexA = systemOrder.indexOf(a.name);
        final indexB = systemOrder.indexOf(b.name);
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // Sort custom categories alphabetically by name
      customCategories.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return [...systemCategories, ...customCategories];
    } catch (e) {
      throw ServerException('Failed to load personal expense categories: $e');
    }
  }

  @override
  Future<PersonalExpenseCategoryModel> addCategory(
      PersonalExpenseCategoryModel category, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    final cleanName = category.name.trim();
    if (cleanName.isEmpty) {
      throw ServerException('Category name cannot be empty.');
    }

    try {
      // Check for duplicate names (case-insensitive)
      final existingCategories = await getCategories(userId);
      final isDuplicate = existingCategories.any(
        (c) => c.name.toLowerCase() == cleanName.toLowerCase(),
      );

      if (isDuplicate) {
        throw ServerException(
          'A category with the name "$cleanName" already exists.',
        );
      }

      final mapData = {
        'owner_id': userId,
        'name': cleanName,
        'icon': category.icon,
        'color': category.color,
        'is_system': false,
      };

      final response = await supabaseClient
          .from('personal_expense_categories')
          .insert(mapData)
          .select()
          .single();

      return PersonalExpenseCategoryModel.fromJson(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to add category: $e');
    }
  }

  @override
  Future<void> updateCategory(
      PersonalExpenseCategoryModel category, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    final cleanName = category.name.trim();
    if (cleanName.isEmpty) {
      throw ServerException('Category name cannot be empty.');
    }

    try {
      // Check for duplicate names excluding current category
      final existingCategories = await getCategories(userId);
      final isDuplicate = existingCategories.any(
        (c) =>
            c.id != category.id &&
            c.name.toLowerCase() == cleanName.toLowerCase(),
      );

      if (isDuplicate) {
        throw ServerException(
          'A category with the name "$cleanName" already exists.',
        );
      }

      final mapData = {
        'name': cleanName,
        'icon': category.icon,
        'color': category.color,
      };

      await supabaseClient
          .from('personal_expense_categories')
          .update(mapData)
          .eq('id', category.id)
          .eq('owner_id', userId)
          .eq('is_system', false);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      await supabaseClient
          .from('personal_expense_categories')
          .delete()
          .eq('id', categoryId)
          .eq('owner_id', userId)
          .eq('is_system', false);
    } catch (e) {
      throw ServerException('Failed to delete category: $e');
    }
  }

  @override
  Future<bool> isCategoryUsed(String categoryName, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final response = await supabaseClient
          .from('personal_expenses')
          .select('id')
          .eq('category', categoryName)
          .eq('owner_id', userId)
          .limit(1);

      final List<dynamic> list = response as List<dynamic>? ?? [];
      return list.isNotEmpty;
    } catch (e) {
      throw ServerException('Failed to check category usage: $e');
    }
  }
}
